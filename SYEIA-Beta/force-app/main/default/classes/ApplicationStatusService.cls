public with sharing class ApplicationStatusService {

    public static HttpResponse updateApplicationStatus() {
        String bearerToken = '00DVd000005O3eb!AQEAQJ7ZsjNcnxO9OSqG5I1vb._Pwa.f7W5l855GJ63R7Zr4orIna2W5jSa3AgnJNqoL0lBfdVowJvnNoYLhFEdbhnPJbbvA';
        String applicationId = 'a79322f2-51c5-4391-ac57-21745bf5ac72';
        String targetStatus = 'in_abeyance';
        String reason = 'Application approved by caseworker';
        return updateApplicationStatus(applicationId, targetStatus, reason, bearerToken);
    }
    public static HttpResponse updateApplicationStatus(
        String applicationId,
        String targetStatus,
        String reason,
        String bearerToken
    ) {

        HttpRequest req = new HttpRequest();

        req.setEndpoint(
            'https://api.dev.syeia.energysecurity.gov.uk/backend/api/v1/internal/applications/' 
            + applicationId + '/status'
        );

        req.setMethod('PATCH');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + bearerToken);
        req.setHeader('Idempotency-Key', String.valueOf(Crypto.getRandomLong()));
        req.setHeader('X-Acting-User-Email', UserInfo.getUserEmail());
        req.setHeader('X-Acting-User-Id', UserInfo.getUserId());
        req.setHeader('X-Acting-User-Role', 'desnz_caseworker');
        req.setHeader('X-Correlation-ID', String.valueOf(Crypto.getRandomLong()));
        

        Map<String,String> payload = new Map<String,String>{
            'targetStatus' => targetStatus,
            'reason' => reason
        };

        req.setBody(JSON.serialize(payload));
        Logger.info('Updating application status with payload: ' + req.getBody());
        Http http = new Http();
        try{
            Logger.info('Sending request to update application status for applicationId: ' + applicationId);
            HttpResponse res = http.send(req);
            Logger.info('Received response: ' + res.getBody());
            Logger.saveLog();
            return res;
        } catch (Exception e) {
            Logger.error('Error updating application status: ' + e.getMessage());
            Logger.saveLog();
            throw e;
        }
    }
}