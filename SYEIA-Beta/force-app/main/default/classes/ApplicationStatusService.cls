public with sharing class ApplicationStatusService {

    public static HttpResponse updateApplicationStatus(
        String applicationId,
        String targetStatus,
        String reason,
        String bearerToken
    ) {

        AWS_EndPoints__c settings = AWS_EndPoints__c.getOrgDefaults();
        String endpointUrl = settings.Update_Status_Endpoint__c;         
        String awsStatusEndpoint = String.format(endpointUrl, new List<String>{applicationId});

        HttpRequest req = new HttpRequest();

        req.setEndpoint(awsStatusEndpoint);

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