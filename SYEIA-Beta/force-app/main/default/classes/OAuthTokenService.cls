public with sharing class OAuthTokenService {
    public class TokenResponse {
        public String access_token;
        public String token_type;
        public Integer expires_in;
    }

    public static String getBearerToken() {

        SalesforceSettings__c settings = SalesforceSettings__c.getOrgDefaults();

        String secret;
        String clientId;
        if (settings != null) {
            secret = settings.client_secret__c;
            clientId = settings.client_id__c;
        }

        if (String.isBlank(secret) || String.isBlank(clientId)) {
            throw new CalloutException('Missing Salesforce settings');
        }
        HttpRequest req = new HttpRequest();
        req.setEndpoint(settings.Endpoint_Url__c);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        
        String body =
            'grant_type=client_credentials' +
            '&client_id=' + EncodingUtil.urlEncode(clientId, 'UTF-8') +
            '&client_secret=' + EncodingUtil.urlEncode(secret, 'UTF-8');

        req.setBody(body);

        try {
            
            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() != 200) {
                Logger.error('Token request failed: ' + res.getStatusCode() + ' ' + res.getBody());
                throw new CalloutException('Token request failed: ' + res.getStatusCode() + ' ' + res.getBody());
            }

            TokenResponse tokenRes = (TokenResponse) JSON.deserialize(res.getBody(), TokenResponse.class);
            
            return tokenRes.access_token;
        } catch (Exception e) {
            Logger.error('Error obtaining OAuth token: ' + e.getStackTraceString());
            Logger.error('Error logging OAuth token request: ' + e.getMessage());
            Logger.saveLog();
        }
        return null;
    }
}