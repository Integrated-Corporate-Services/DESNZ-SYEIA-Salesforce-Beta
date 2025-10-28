public with sharing class GovUKNotifyInvocable {
    @InvocableMethod(
        callout=true
        label='Send GOV.UK Notify Notification'
        description='Sends a notification via the GOV.UK Notify service'
        category='GOV.UK Notify'
    )
    public static List<Result> sendNotifyEmail(List<Request> requests) {
        List<Result> results = new List<Result>();

        for (Request req : requests) {
            Result result = new Result();

            try {
                if (String.isBlank(req.recipientEmail)) {
                    throw new NotifyException('Recipient email is required.');
                }

                if (String.isBlank(req.templateId)) {
                    throw new NotifyException('Template ID is required.');
                }

                // Validate and repair personalisation JSON if provided
                if (String.isNotBlank(req.personalisationJson)) {
                    try {
                        // Try parsing as-is first
                        Map<String, Object> testParse = (Map<String, Object>)JSON.deserializeUntyped(req.personalisationJson);
                    } catch (Exception e) {
                        // If it fails, attempt to repair it
                        System.debug(LoggingLevel.WARN, 'Malformed JSON detected, attempting repair. Error: ' + e.getMessage());
                        System.debug(LoggingLevel.WARN, 'Original JSON: ' + req.personalisationJson);
                        
                        req.personalisationJson = repairFlowJson(req.personalisationJson);
                        
                        System.debug(LoggingLevel.INFO, 'Repaired JSON: ' + req.personalisationJson);
                        
                        // Validate repaired JSON
                        try {
                            Map<String, Object> testParse = (Map<String, Object>)JSON.deserializeUntyped(req.personalisationJson);
                        } catch (Exception ex) {
                            throw new NotifyException('Invalid personalisation JSON format even after repair: ' + ex.getMessage());
                        }
                    }
                }

                System.enqueueJob(new GovUKNotifyQueueable(req));

                result.success = true;
                result.errorMessage = null;

            } catch (Exception e) {
                result.success = false;
                result.errorMessage = 'Exception: ' + e.getMessage();
                System.debug(LoggingLevel.ERROR, 'Error sending GOV.UK Notify email: ' + e.getMessage());
            }

            results.add(result);
        }

        return results;
    }

    /**
     * Repairs JSON built in Flow that contains unescaped line breaks and special characters
     * Extracts key-value pairs and rebuilds JSON using proper serialization
     * 
     * @param brokenJson The malformed JSON string from Flow
     * @return Properly formatted JSON string
     */
    private static String repairFlowJson(String brokenJson) {
        Map<String, String> extractedValues = new Map<String, String>();
        
        String workingJson = brokenJson.trim();
        
        // Basic validation
        if (!workingJson.startsWith('{') || !workingJson.endsWith('}')) {
            throw new NotifyException('JSON must start with { and end with }');
        }
        
        // Remove outer braces
        workingJson = workingJson.substring(1, workingJson.length() - 1);
        
        // Split by JSON pairs (handles commas within values)
        List<String> pairs = splitJsonPairs(workingJson);
        
        for (String pair : pairs) {
            if (String.isBlank(pair)) {
                continue;
            }
            
            // Find the colon that separates key from value
            Integer colonIndex = pair.indexOf('":');
            
            if (colonIndex > 0) {
                // Extract key (remove quotes and whitespace)
                String key = pair.substring(0, colonIndex);
                key = key.trim();
                if (key.startsWith('"')) {
                    key = key.substring(1);
                }
                
                // Extract value (everything after ":")
                String valueWithQuotes = pair.substring(colonIndex + 2).trim();
                
                // Remove surrounding quotes from value
                String value = valueWithQuotes;
                if (value.startsWith('"') && value.endsWith('"')) {
                    value = value.substring(1, value.length() - 1);
                } else if (value.startsWith('"')) {
                    // Handle case where closing quote is missing or on new line
                    value = value.substring(1);
                    if (value.endsWith('"')) {
                        value = value.substring(0, value.length() - 1);
                    }
                }
                
                extractedValues.put(key, value);
            }
        }
        
        // Rebuild JSON properly using Salesforce's JSON serializer
        // This automatically escapes all special characters including line breaks
        return JSON.serialize(extractedValues);
    }
    
    /**
     * Splits JSON content into key-value pairs, accounting for commas within string values
     * 
     * @param jsonContent The JSON content without outer braces
     * @return List of key-value pair strings
     */
    private static List<String> splitJsonPairs(String jsonContent) {
        List<String> pairs = new List<String>();
        Integer depth = 0;
        Integer lastSplit = 0;
        Boolean inString = false;
        Boolean escaped = false;
        
        for (Integer i = 0; i < jsonContent.length(); i++) {
            String currentChar = jsonContent.substring(i, i + 1);
            
            // Handle escape sequences
            if (escaped) {
                escaped = false;
                continue;
            }
            
            if (currentChar == '\\') {
                escaped = true;
                continue;
            }
            
            // Track if we're inside a string
            if (currentChar == '"') {
                inString = !inString;
            }
            
            // Only process structural characters when not in a string
            if (!inString) {
                if (currentChar == '{' || currentChar == '[') {
                    depth++;
                } else if (currentChar == '}' || currentChar == ']') {
                    depth--;
                } else if (currentChar == ',' && depth == 0) {
                    // Found a top-level comma - this separates pairs
                    pairs.add(jsonContent.substring(lastSplit, i).trim());
                    lastSplit = i + 1;
                }
            }
        }
        
        // Add the last pair
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
    public class GovUKNotifyQueueable implements Queueable, Database.AllowsCallouts {
        private Request request;

        public GovUKNotifyQueueable(Request req) {
            this.request = req;
        }

        public void execute(QueueableContext context) {
            try {
                Map<String, String> personalisation = new Map<String, String>();

                // Deserialize personalisation JSON if provided
                // JSON.deserializeUntyped automatically handles all unescaping
                if (String.isNotBlank(request.personalisationJson)) {
                    Map<String, Object> personalisationMap = (Map<String, Object>)JSON.deserializeUntyped(request.personalisationJson);
                    
                    for (String key : personalisationMap.keySet()) {
                        Object value = personalisationMap.get(key);
                        personalisation.put(key, value != null ? String.valueOf(value) : '');
                    }
                }

                GovUKNotifyService.NotifyResponse response = GovUKNotifyService.sendEmail(
                    request.recipientEmail,
                    request.templateId,
                    personalisation
                );

                if (response.success) {
                    if (String.isNotBlank(request.caseId)) {
                        updateCaseEmailSent(request.caseId);
                    }
                    System.debug(LoggingLevel.INFO, 'GOV.UK Notify email sent successfully. Notification ID: ' + response.notificationId);
                } else {
                    System.debug(LoggingLevel.ERROR, 'Failed to send GOV.UK Notify email. Status Code: ' + response.statusCode);
                }
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Error in Queueable sending GOV.UK Notify email: ' + e.getMessage());
                System.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
            }
        }

        private void updateCaseEmailSent(String caseId) {
            try {
                Case__c caseToUpdate = new Case__c(Id = caseId, Overdue_Email_Sent__c = true);
                update caseToUpdate;
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Error updating Case with GOV.UK Notify email sent flag: ' + e.getMessage());
            }
        }
    }

    /**
     * Request wrapper for invocable method
     */
    public class Request {
        @InvocableVariable(label='Case Id' description='The Salesforce Case Id associated with the notification' required=false)
        public String caseId;

        @InvocableVariable(label='Recipient Email' description='The email address of the recipient' required=true)
        public String recipientEmail;

        @InvocableVariable(label='Template ID' description='The ID of the GOV.UK Notify template to use' required=true)
        public String templateId;

        @InvocableVariable(label='Personalisation JSON' description='JSON string containing personalisation key-value pairs, e.g. {"case_reference":"12345","case_url":"https://...","applicant_name":"John Doe"}' required=false)
        public String personalisationJson;
    }

    /**
     * Result wrapper for invocable method
     */
    public class Result {
        @InvocableVariable(label='Success' description='Indicates if the notification was queued successfully')
        public Boolean success;

        @InvocableVariable(label='Notification ID' description='The ID of the sent notification (populated after queueable executes)')
        public String notificationId;

        @InvocableVariable(label='Error Message' description='Error message if the notification failed to queue')
        public String errorMessage;

        public Result(){
            this.success = false;
        }
    }

    /**
     * Custom exception for Notify-specific errors
     */
    public class NotifyException extends Exception {}
}