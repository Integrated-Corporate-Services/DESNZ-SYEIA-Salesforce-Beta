public class Application_StatusUpdateQueueable implements Queueable, Database.AllowsCallouts { 
    
    private List<Id> applicationIds;
    private Map<Id, String> previousStatusById;
    
    @TestVisible
    private static final Integer BATCH_SIZE = 100;
    
    public Application_StatusUpdateQueueable(List<Id> applicationIds) {
        this(applicationIds, new Map<Id, String>());
    }
    
    public Application_StatusUpdateQueueable(List<Id> applicationIds, Map<Id, String> previousStatusById) {
        this.applicationIds = applicationIds;
        this.previousStatusById = previousStatusById != null ? previousStatusById : new Map<Id, String>();
    }
    
    public void execute(QueueableContext ctx) {
        
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
                   Status__c,Sub_Status__c,
                   Payment__r.Payment_Method__c,
                   RecordType.DeveloperName
            FROM Case__c
            WHERE Id IN :applicationIds
        ];
        
        for (Case__c application : applications) {
            
            String key = application.RecordType.DeveloperName + '|' + application.Status__c;
			String previousStatus = previousStatusById.get(application.Id);
           
            if (salesforceAWSStatusMap.containsKey(key)) {
                string setAWSStatus = salesforceAWSStatusMap.get(key);
                String reasonCode;
                
                if (previousStatus == 'Withdrawal Requested'
                    && application.Status__c != 'Withdrawn') {
                    
                    String paymentMethod = application.Payment__r?.Payment_Method__c;
                    if (application.Status__c == 'Application Received' 
                        && paymentMethod == 'BACS' ){
                            setAWSStatus = 'Processing Payment';
                    }
                    
                     reasonCode = 'WITHDRAWAL_REJECTED';
                }

                HttpResponse response = ApplicationStatusService.updateApplicationStatus(
                    application.AWS_Application_Id__c,
                    setAWSStatus,
                    reasonCode,
                    accessToken
                );

            } else {
                System.debug('No status mapping found for key: ' + key);
            }
        }
    }
}