public class Application_StatusUpdateQueueable implements Queueable, Database.AllowsCallouts { 
    
    private List<Id> applicationIds;
    
    @TestVisible
    private static final Integer BATCH_SIZE = 100;
    
    public Application_StatusUpdateQueueable(List<Id> applicationIds) {
        this.applicationIds = applicationIds;
    }
    
    public void execute(QueueableContext ctx) {
        
        System.debug(LoggingLevel.INFO, 'Application_StatusUpdateQueueable applicationIds: ' + applicationIds);
        
        if (applicationIds == null || applicationIds.isEmpty()) {
            return;
        }
        
        Id jobId = ctx.getJobId();
        System.debug(LoggingLevel.INFO,
            'StatusUpdateQueueable executing: JobId=' + jobId +
            ', Records=' + applicationIds.size());
            
        Logger.info(
            'StatusUpdateQueueable executing: JobId=' + jobId +
            ', Records=' + applicationIds.size()
        );
        
        String accessToken = OAuthTokenService.getBearerToken();
        
        // Key = RecordTypeDeveloperName|SalesforceStatus
        Map<String, String> salesforceAWSStatusMap = new Map<String, String>();
        
        for (Application_Status_Mapping__mdt asm : [
            SELECT Salesforce_Status__c,
                   AWS_Status__c,
                   RecordType_Dev_Name__c
            FROM Application_Status_Mapping__mdt
        ]) {
            String key = asm.RecordType_Dev_Name__c + '|' + asm.Salesforce_Status__c;
            salesforceAWSStatusMap.put(key, asm.AWS_Status__c);
        }
        
        List<Case__c> applications = [
            SELECT Id,
                   AWS_Application_Id__c,
                   Status__c,
                   RecordType.DeveloperName
            FROM Case__c
            WHERE Id IN :applicationIds
        ];
        
        for (Case__c application : applications) {
            
            String key = application.RecordType.DeveloperName + '|' + application.Status__c;
            
            System.debug('Application Key >> ' + key);
            
            if (salesforceAWSStatusMap.containsKey(key)) {
                
                HttpResponse response = ApplicationStatusService.updateApplicationStatus(
                    application.AWS_Application_Id__c,
                    salesforceAWSStatusMap.get(key),
                    application.Status__c,
                    accessToken
                );
                
                System.debug('execute response >> ' + response);
            } else {
                System.debug('No status mapping found for key: ' + key);
            }
        }
    }
}