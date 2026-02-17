/**
 * Invocable action for sending emails via GOV.UK Notify from Flows. Queues email requests asynchronously using Queueable.
 */
public with sharing class GovUKNotify_Invocable {
    
    @InvocableMethod(
        callout=true
        label='Send GOV.UK Notify Email'
        description='Queues an email notification via the GOV.UK Notify service'
        category='GOV.UK Notify'
    )
    public static List<SendEmailResult> sendNotifyEmail(List<SendEmailRequest> requests) {
        List<SendEmailResult> results = new List<SendEmailResult>();

        for (SendEmailRequest req : requests) {
            SendEmailResult result = new SendEmailResult();

            try {
                validateRequest(req);
                
                // Sanitise JSON if provided
                if (String.isNotBlank(req.personalisationJson)) {
                    req.personalisationJson = sanitiseJson(req.personalisationJson);
                }

                System.enqueueJob(new GovUkNotifyQueueable(req));

                result.success = true;
                result.message = 'Email queued successfully';

            } catch (Exception e) {
                result.success = false;
                result.errorMessage = e.getMessage();
                Logger.error('Error queuing GOV.UK Notify email: ' + e.getMessage());
                Logger.setScenario('GovUKNotify_Invocable.sendNotifyEmail');
                Logger.saveLog();
            }

            results.add(result);
        }

        return results;
    }
    
    private static void validateRequest(SendEmailRequest req) {
        if (String.isBlank(req.recipientEmail)) {
            throw new NotifyException('Recipient email is required.');
        }
        if (String.isBlank(req.templateId)) {
            throw new NotifyException('Template ID is required.');
        }
    }
    
    /**
     * Sanitises JSON input, attempting to repair malformed JSON from Flow
     * @param jsonString The JSON string to sanitise (renamed from 'json' to avoid class name conflict)
     */
    @TestVisible
    private static String sanitiseJson(String jsonString) {
        if (String.isBlank(jsonString)) {
            return null;
        }
        
        // Try parsing first - if valid, return as-is
        try {
            JSON.deserializeUntyped(jsonString);
            return jsonString;
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'Malformed JSON detected, attempting repair');
        }
        
        // Attempt repair for Flow-generated JSON with unescaped characters
        String repaired = repairFlowJson(jsonString);
        
        // Validate repaired JSON
        try {
            JSON.deserializeUntyped(repaired);
            System.debug(LoggingLevel.INFO, 'JSON repair successful');
            return repaired;
        } catch (Exception e) {
            Logger.error('JSON repair failed: ' + e.getMessage());
            Logger.setScenario('GovUKNotify_Invocable.sanitiseJson');
            Logger.saveLog();
            throw new NotifyException('Invalid personalisation JSON format: ' + e.getMessage());
        }
    }

    /**
     * Repairs JSON built in Flow that contains unescaped line breaks and special characters
     */
    private static String repairFlowJson(String brokenJson) {
        Map<String, String> extractedValues = new Map<String, String>();
        
        String workingJson = brokenJson.trim();
        
        if (!workingJson.startsWith('{') || !workingJson.endsWith('}')) {
            throw new NotifyException('JSON must start with { and end with }');
        }
        
        workingJson = workingJson.substring(1, workingJson.length() - 1);
        List<String> pairs = splitJsonPairs(workingJson);
        
        for (String pair : pairs) {
            if (String.isBlank(pair)) {
                continue;
            }
            
            Integer colonIndex = pair.indexOf('":');
            
            if (colonIndex > 0) {
                String key = pair.substring(0, colonIndex).trim();
                if (key.startsWith('"')) {
                    key = key.substring(1);
                }
                
                String valueWithQuotes = pair.substring(colonIndex + 2).trim();
                String value = valueWithQuotes;
                
                if (value.startsWith('"') && value.endsWith('"')) {
                    value = value.substring(1, value.length() - 1);
                } else if (value.startsWith('"')) {
                    value = value.substring(1);
                    if (value.endsWith('"')) {
                        value = value.substring(0, value.length() - 1);
                    }
                }
                
                extractedValues.put(key, value);
            }
        }
        
        return JSON.serialize(extractedValues);
    }
    
    /**
     * Splits JSON content into key-value pairs, accounting for commas within string values
     */
    private static List<String> splitJsonPairs(String jsonContent) {
        List<String> pairs = new List<String>();
        Integer depth = 0;
        Integer lastSplit = 0;
        Boolean inString = false;
        Boolean escaped = false;
        
        for (Integer i = 0; i < jsonContent.length(); i++) {
            String currentChar = jsonContent.substring(i, i + 1);
            
            if (escaped) {
                escaped = false;
                continue;
            }
            
            if (currentChar == '\\') {
                escaped = true;
                continue;
            }
            
            if (currentChar == '"') {
                inString = !inString;
            }
            
            if (!inString) {
                if (currentChar == '{' || currentChar == '[') {
                    depth++;
                } else if (currentChar == '}' || currentChar == ']') {
                    depth--;
                } else if (currentChar == ',' && depth == 0) {
                    pairs.add(jsonContent.substring(lastSplit, i).trim());
                    lastSplit = i + 1;
                }
            }
        }
        
        if (lastSplit < jsonContent.length()) {
            String lastPair = jsonContent.substring(lastSplit).trim();
            if (String.isNotBlank(lastPair)) {
                pairs.add(lastPair);
            }
        }
        
        return pairs;
    }

    /**
     * Queueable class to handle async callouts to GOV.UK Notify service
     */
    public class GovUkNotifyQueueable implements Queueable, Database.AllowsCallouts {
        private SendEmailRequest request;

        public GovUkNotifyQueueable(SendEmailRequest req) {
            this.request = req;
        }

        public void execute(QueueableContext context) {
            try {
                Map<String, String> personalisation = parsePersonalisation(request.personalisationJson);

                GovUKNotify_Service.NotifyResponse response = GovUKNotify_Service.sendEmail(
                    request.recipientEmail,
                    request.templateId,
                    personalisation
                );

                if (response.success) {
                    handleSuccess(response);
                } else {
                    System.debug(LoggingLevel.ERROR, 'GOV.UK Notify failed. Status: ' + response.statusCode);
                }
            } catch (Exception e) {
                Logger.error('Error sending GOV.UK Notify email: ' + e.getMessage());
                Logger.setScenario('GovUKNotify_Invocable.GovUkNotifyQueueable.execute');
                Logger.saveLog();
            }
        }
        
        /**
         * Parses personalisation JSON string into a Map
         * @param jsonString The JSON string to parse (renamed from 'json' to avoid class name conflict)
         */
        private Map<String, String> parsePersonalisation(String jsonString) {
            Map<String, String> personalisation = new Map<String, String>();
            
            if (String.isNotBlank(jsonString)) {
                Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(jsonString);
                for (String key : parsed.keySet()) {
                    Object value = parsed.get(key);
                    personalisation.put(key, value != null ? String.valueOf(value) : '');
                }
            }
            
            return personalisation;
        }
        
        private void handleSuccess(GovUKNotify_Service.NotifyResponse response) {
            System.debug(LoggingLevel.INFO, 'Email sent successfully. Notification ID: ' + response.notificationId);
            
            if (String.isNotBlank(request.caseId)) {
                updateCaseEmailSent(request.caseId);
            }
        }

        private void updateCaseEmailSent(String caseId) {
            try {
                Case__c caseToUpdate = new Case__c(
                    Id = caseId, 
                    Overdue_Email_Sent__c = true
                );
                update caseToUpdate;
                System.debug(LoggingLevel.INFO, 'Updated Case: ' + caseId);
            } catch (Exception e) {
                Logger.error('Error updating Case: ' + e.getMessage());
                Logger.setScenario('GovUKNotify_Invocable.GovUkNotifyQueueable.updateCaseEmailSent');
                Logger.saveLog();
                System.debug(LoggingLevel.ERROR, 'Error updating Case: ' + e.getMessage());
            }
        }
    }

    /**
     * Request wrapper for invocable method
     */
    public class SendEmailRequest {
        @InvocableVariable(
            label='Case Id' 
            description='The Salesforce Case Id associated with the notification' 
            required=false
        )
        public String caseId;

        @InvocableVariable(
            label='Recipient Email' 
            description='The email address of the recipient' 
            required=true
        )
        public String recipientEmail;

        @InvocableVariable(
            label='Template ID' 
            description='The ID of the GOV.UK Notify template to use' 
            required=true
        )
        public String templateId;

        @InvocableVariable(
            label='Personalisation JSON' 
            description='JSON string containing personalisation key-value pairs' 
            required=false
        )
        public String personalisationJson;
    }

    /**
     * Result wrapper for invocable method
     */
    public class SendEmailResult {
        @InvocableVariable(label='Success' description='Indicates if the notification was queued successfully')
        public Boolean success;

        @InvocableVariable(label='Message' description='Success or status message')
        public String message;

        @InvocableVariable(label='Error Message' description='Error message if the notification failed to queue')
        public String errorMessage;

        public SendEmailResult() {
            this.success = false;
        }
    }

    /**
     * Custom exception for Notify-specific errors
     */
    public class NotifyException extends Exception {}
}