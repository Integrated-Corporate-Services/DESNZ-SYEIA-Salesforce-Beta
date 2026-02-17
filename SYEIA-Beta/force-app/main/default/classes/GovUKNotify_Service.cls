/**
 * Service class for sending notifications via GOV.UK Notify API.
 *              Handles email notifications with JWT authentication.
 */
public class GovUKNotify_Service {

    private static final String NAMED_CREDENTIAL = 'callout:GOV_UK_Notify';
    private static final String EMAIL_ENDPOINT = '/v2/notifications/email';
    private static final Integer TIMEOUT_MS = 120000;
    private static final String CONFIG_NAME = 'Production';
    private static final Pattern EMAIL_PATTERN = Pattern.compile('^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$');
    
    // Cache config to avoid repeated queries
    private static GOV_UK_Notify_Config__mdt cachedConfig;

    /**
     * Sends an email via GOV.UK Notify without personalisation
     */
    public static NotifyResponse sendEmail(String emailAddress, String templateId) {
        return sendEmail(emailAddress, templateId, null);
    }

    /**
     * Sends an email via GOV.UK Notify with personalisation
     */
    public static NotifyResponse sendEmail(String emailAddress, String templateId, Map<String, String> personalisation) {
        validateInputs(emailAddress, templateId);

        try {
            Map<String, Object> requestBody = buildRequestBody(emailAddress, templateId, personalisation);
            
            System.debug(LoggingLevel.INFO, 'Sending GOV.UK Notify email to: ' + maskEmail(emailAddress) + 
                        ' with template: ' + templateId);
            
            HttpResponse response = makeCallout(EMAIL_ENDPOINT, 'POST', JSON.serialize(requestBody));
            return parseResponse(response);
            
        } catch (NotifyException e) {
            Logger.error('NotifyException: ' + e.getMessage());
            Logger.setScenario('GovUKNotify_Service.sendEmail');
            throw e;
        } catch (Exception e) {
            Logger.error('Failed to send email via GOV.UK Notify: ' + e.getMessage());
            Logger.setScenario('GovUKNotify_Service.sendEmail');
            throw new NotifyException('Failed to send email via GOV.UK Notify: ' + e.getMessage(), e);
        } finally{
            Logger.saveLog();
        }
    }
    
    private static void validateInputs(String emailAddress, String templateId) {
        if (String.isBlank(emailAddress)) {
            throw new NotifyException('Email address is required.');
        }
        if (String.isBlank(templateId)) {
            throw new NotifyException('Template ID is required.');
        }
        if (!EMAIL_PATTERN.matcher(emailAddress).matches()) {
            throw new NotifyException('Invalid email address format: ' + maskEmail(emailAddress));
        }
    }
    
    private static Map<String, Object> buildRequestBody(String emailAddress, String templateId, Map<String, String> personalisation) {
        Map<String, Object> body = new Map<String, Object>{
            'email_address' => emailAddress,
            'template_id' => templateId
        };
        if (personalisation != null && !personalisation.isEmpty()) {
            body.put('personalisation', personalisation);
        }
        return body;
    }

    @TestVisible
    private static HttpResponse makeCallout(String endpoint, String method, String body) {
        GOV_UK_Notify_Config__mdt config = getConfig();
        
        String jwtToken = GovUKNotify_JWTGenerator.generateToken(
            config.Issuer_UUID__c,
            config.Secret_Key__c
        );

        HttpRequest request = new HttpRequest();
        request.setEndpoint(NAMED_CREDENTIAL + endpoint);
        request.setMethod(method);
        request.setHeader('Authorization', 'Bearer ' + jwtToken);
        request.setHeader('Content-Type', 'application/json');
        request.setTimeout(TIMEOUT_MS);

        if (String.isNotBlank(body)) {
            request.setBody(body);
        }

        Http http = new Http();
        HttpResponse response = http.send(request);

        System.debug(LoggingLevel.INFO, 'GOV.UK Notify Response Status: ' + response.getStatusCode());
        
        if (response.getStatusCode() >= 400) {
            handleHttpError(response);
        }

        return response;
    }
    
    private static void handleHttpError(HttpResponse response) {
        String errorMessage = 'HTTP Error ' + response.getStatusCode();
        try {
            Map<String, Object> errorBody = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            if (errorBody.containsKey('errors')) {
                List<Object> errors = (List<Object>) errorBody.get('errors');
                List<String> errorMessages = new List<String>();
                for (Object err : errors) {
                    Map<String, Object> errorMap = (Map<String, Object>) err;
                    errorMessages.add((String) errorMap.get('message'));
                }
                errorMessage += ': ' + String.join(errorMessages, '; ');
            }
        } catch (Exception e) {
            errorMessage += ': ' + response.getBody();
            Logger.error('Failed to parse error response: ' + e.getMessage());
            Logger.setScenario('GovUKNotify_Service.handleHttpError');
            Logger.saveLog();
        }
        throw new NotifyException(errorMessage);
    }
    
    @TestVisible
    private static GOV_UK_Notify_Config__mdt getConfig() {
        if (cachedConfig == null) {
            cachedConfig = GOV_UK_Notify_Config__mdt.getInstance(CONFIG_NAME);
            if (cachedConfig == null) {
                throw new NotifyException('GOV.UK Notify config "' + CONFIG_NAME + '" not found in Custom Metadata');
            }
        }
        return cachedConfig;
    }
    
    @TestVisible
    private static void clearConfigCache() {
        cachedConfig = null;
    }
    
    /**
     * Masks an email address for safe logging
     */
    private static String maskEmail(String email) {
        if (String.isBlank(email) || !email.contains('@')) {
            return '[invalid]';
        }
        Integer atIndex = email.indexOf('@');
        String localPart = email.substring(0, atIndex);
        String domain = email.substring(atIndex);
        if (localPart.length() <= 2) {
            return '**' + domain;
        }
        return localPart.substring(0, 2) + '***' + domain;
    }

    private static NotifyResponse parseResponse(HttpResponse response) {
        NotifyResponse result = new NotifyResponse();
        result.statusCode = response.getStatusCode();
        result.success = response.getStatusCode() >= 200 && response.getStatusCode() < 300;
        result.rawResponse = response.getBody();

        if (String.isNotBlank(response.getBody())) {
            try {
                Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                result.notificationId = (String) responseBody.get('id');
                result.reference = (String) responseBody.get('reference');
                
                System.debug(LoggingLevel.INFO, 'GOV.UK Notify - Notification ID: ' + result.notificationId);
            } catch (Exception e) {
                System.debug(LoggingLevel.WARN, 'Could not parse response body: ' + e.getMessage());
                Logger.error('Failed to parse GOV.UK Notify response: ' + e.getMessage());
                Logger.setScenario('GovUKNotify_Service.parseResponse');
                Logger.saveLog();
            }
        }

        return result;
    }

    /**
     * Response wrapper for GOV.UK Notify API responses
     */
    public class NotifyResponse {
        @AuraEnabled public Boolean success { get; set; }
        @AuraEnabled public Integer statusCode { get; set; }
        @AuraEnabled public String notificationId { get; set; }
        @AuraEnabled public String reference { get; set; }
        @AuraEnabled public String rawResponse { get; set; }

        public NotifyResponse() {
            this.success = false;
        }
    }

    /**
     * Custom exception for GOV.UK Notify specific errors
     */
    public class NotifyException extends Exception {}
}