public class GovUKNotifyService {

    // Constants
    private static final String NAMED_CREDENTIAL = 'callout:GOV_UK_Notify';
    private static final String EMAIL_ENDPOINT = '/v2/notifications/email';
    private static final Integer TIMEOUT_SECONDS = 120;

    public static NotifyResponse sendEmail(String emailAddress, String templateId) {
        return sendEmail(emailAddress, templateId, null);
    }

    public static NotifyResponse sendEmail(String emailAddress, String templateId, Map<String, String> personalisation) {
        // Validate required parameters
        if (String.isBlank(emailAddress)) {
            throw new NotifyException('Email address is required.');
        }
        if (String.isBlank(templateId)) {
            throw new NotifyException('Template ID is required.');
        }

        try {
            // Prepare request body
            Map<String, Object> requestBody = new Map<String, Object>{
                'email_address' => emailAddress,
                'template_id' => templateId
            };

            // Add personalisation if provided
            if (personalisation != null && !personalisation.isEmpty()) {
                requestBody.put('personalisation', personalisation);
            }

            System.debug('Sending email to: ' + emailAddress + ' with template: ' + templateId);
            System.debug('Personalisation fields: ' + personalisation);

            // Make the callout
            HttpResponse response = makeCallout(EMAIL_ENDPOINT, 'POST', JSON.serialize(requestBody));

            // Parse and return the response
            return parseResponse(response);
        } catch (NotifyException e) {
            // Re-throw NotifyException as-is
            throw e;
        } catch (Exception e) {
            // Wrap other exceptions
            throw new NotifyException('Failed to send email via GOV.UK Notify: ' + e.getMessage(), e);
        }
    }

    @TestVisible
    private static HttpResponse makeCallout(String endpoint, String method, String body) {
        // Retrieve settings for JWT generation from Custom Settings
        NotifyApiSettings__c settings = NotifyApiSettings__c.getInstance();

        System.debug('Notify API Settings retrieved: ' + (settings != null ? 'Found' : 'Not Found'));

        // Validate settings exist and contain required fields
        if (settings == null || String.isBlank(settings.Issuer_UUID__c) || String.isBlank(settings.Secret_Key__c)) {
            throw new NotifyException('Notify API settings are not configured properly. Please check NotifyApiSettings__c custom setting.');
        }

        // Generate JWT token for authentication
        String jwtToken = JWTGenerator.generateToken(settings.Issuer_UUID__c, settings.Secret_Key__c);

        // Prepare HTTP request
        HttpRequest request = new HttpRequest();
        request.setEndpoint(NAMED_CREDENTIAL + endpoint);
        request.setMethod(method);
        request.setHeader('Authorization', 'Bearer ' + jwtToken);
        request.setHeader('Content-Type', 'application/json');
        request.setTimeout(TIMEOUT_SECONDS * 1000); // Convert to milliseconds

        // Add body if provided
        if (String.isNotBlank(body)) {
            request.setBody(body);
        }

        System.debug('Making callout to: ' + NAMED_CREDENTIAL + endpoint);

        // Send the request
        Http http = new Http();
        HttpResponse response = http.send(request);

        System.debug('GOV.UK Notify Response Status: ' + response.getStatusCode());
        System.debug('GOV.UK Notify Response Body: ' + response.getBody());

        // Handle HTTP errors (4xx and 5xx status codes)
        if (response.getStatusCode() >= 400) {
            String errorMessage = 'HTTP Error ' + response.getStatusCode();
            try {
                // Try to extract error details from response body
                Map<String, Object> errorBody = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                if (errorBody.containsKey('errors')) {
                    errorMessage += ': ' + JSON.serialize(errorBody.get('errors'));
                } else {
                    errorMessage += ': ' + response.getBody();
                }
            } catch (Exception e) {
                errorMessage += ': ' + response.getBody();
            }
            throw new NotifyException(errorMessage);
        }

        return response;
    }

    private static NotifyResponse parseResponse(HttpResponse response) {
        NotifyResponse result = new NotifyResponse();
        result.statusCode = response.getStatusCode();
        result.success = response.getStatusCode() >= 200 && response.getStatusCode() < 300;
        result.rawResponse = response.getBody();

        // Parse response body if present
        if (String.isNotBlank(response.getBody())) {
            try {
                Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                
                // Extract notification ID
                if (responseBody.containsKey('id')) {
                    result.notificationId = (String) responseBody.get('id');
                }
                
                // Extract reference if provided
                if (responseBody.containsKey('reference')) {
                    result.reference = (String) responseBody.get('reference');
                }
                
                System.debug('Notification ID: ' + result.notificationId);
            } catch (Exception e) {
                System.debug('Warning: Could not parse response body: ' + e.getMessage());
                // Continue anyway - we have the status code
            }
        }

        return result;
    }

    public class NotifyResponse {
        public Boolean success {get; set;}
        
        public Integer statusCode {get; set;}
        
        public String notificationId {get; set;}
        
        public String reference {get; set;}
        
        public String rawResponse {get; set;}

        public NotifyResponse() {
            this.success = false;
        }
    }

    public class NotifyException extends Exception {}
}