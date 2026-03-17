public class Application_StatusUpdateQueueable implements Queueable, Database.AllowsCallouts { 
    
    private List<Id> applicationIds;
    @TestVisible
    private static final Integer BATCH_SIZE = 100; // Process in batches if large
    
    public Application_StatusUpdateQueueable(List<Id> applicationIds) {
        this.applicationIds = applicationIds;
    }
    
    public void execute(QueueableContext ctx) {
		
        System.debug(LoggingLevel.INFO, 'Application_StatusUpdateQueueable applicationIds' + applicationIds );
        
        if (applicationIds == null || applicationIds.isEmpty()) {
            return;
        }
        
        Id jobId = ctx.getJobId();
        System.debug(LoggingLevel.INFO, 'StatusUpdateQueueable executing: JobId=' + jobId + 
                     ', Records=' + applicationIds.size());
        Logger.info('StatusUpdateQueueable executing: JobId=' + jobId + 
                    ', Records=' + applicationIds.size());
        
        String accessToken = OAuthTokenService.getBearerToken();
        
		Map<String,String> salesforceAWSStatusMap = new Map<String,String>();
        for( Application_Status_Mapping__mdt asm : [Select Salesforce_Status__c, AWS_Status__c From Application_Status_Mapping__mdt]){
			salesforceAWSStatusMap.put(asm.Salesforce_Status__c, asm.AWS_Status__c);            
        }
        
        List<Case__c> applications = [Select Id, AWS_Application_Id__c, Status__c From Case__c Where Id IN:applicationIds];

        for(Case__c application : applications){
            System.debug('application >>' + application.Status__c);
            if(salesforceAWSStatusMap.containsKey(application.Status__c)){
                HttpResponse response = ApplicationStatusService.updateApplicationStatus(
                    application.AWS_Application_Id__c,
                    salesforceAWSStatusMap.get(application.Status__c),
                    application.Status__c,
                    accessToken
                );
            System.debug('execute response >>' + response);
            }
            System.debug('out side execute response >>');
        }
    }
    
    
    private static String getAccessToken() {
        
        SalesforceSettings__c settings = SalesforceSettings__c.getInstance();
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(settings.Endpoint_Url__c);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        
        String body =  'grant_type=client_credentials'
            + '&client_id=' + settings.client_id__c
            + '&client_secret=' + settings.client_secret__c;
        
        req.setBody(body);
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        
        if (res.getStatusCode() == 200) {
            Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            return (String) result.get('access_token');
        } else {
            System.debug('Error: ' + res.getBody());
            return null;
        }
    }
        
}