/**
* Trigger helper for processing inbound form requests.
*              Includes improved recursion guard and delegates to the processor.
*/
public with sharing class CaseTriggerHelper {
    
    // Recursion guard - tracks processed record IDs instead of boolean flag
    // This allows new records to be processed while preventing reprocessing of same records
    private static Set<Id> processedApplicatonIds = new Set<Id>();
    
    // Optional: Track records currently being processed (for nested trigger detection)
    private static Set<Id> currentlyProcessingIds = new Set<Id>();
    
    // Flag to completely disable processing (for data loads, etc.)
    private static Boolean processingDisabled = false;
    
    public CaseTriggerHelper() {
        System.debug(LoggingLevel.DEBUG, 'CaseTriggerHelper instantiated');
    }
    
    // ========================================================================
    // STATIC CONTROL METHODS
    // ========================================================================
    
    
    /**
* Disable all processing (useful for data migrations)
*/
    public static void disableProcessing() {
        processingDisabled = true;
    }
    
    /**
* Enable processing
*/
    public static void enableProcessing() {
        processingDisabled = false;
    }
    
    /**
* Check if a specific record has been processed
*/
    public static Boolean isRecordProcessed(Id recordId) {
        return processedApplicatonIds.contains(recordId);
    }
    
    /**
* Manually mark a record as processed (useful for external integrations)
*/
    public static void markAsProcessed(Id recordId) {
        processedApplicatonIds.add(recordId);
    }
    
    /**
* Manually mark multiple records as processed
*/
    public static void markAsProcessed(Set<Id> recordIds) {
        processedApplicatonIds.addAll(recordIds);
    }
    
    /**
* Get count of processed records in this transaction
*/
    public static Integer getProcessedCount() {
        return processedApplicatonIds.size();
    }
    
    // ========================================================================
    // TRIGGER EVENT METHODS (for framework compatibility)
    // ========================================================================
    
    public void processBeforeInsert() {
        // No processing needed before insert
    }
    
    public void processAfterInsert() {
        // No processing needed before insert
    }
    
    public void processBeforeUpdate() {
        // No processing needed before update
    }
    
    public void processBeforeDelete() {
        // No processing needed before delete
    }
    
    public void processAfterDelete() {
        // No processing needed after delete
    }
    
    public void processAfterUndelete() {
        // No processing needed after undelete
    }
    
    /**
* Main entry point for processing Inbound Requests (after insert)
*/
    public void processAfterUpdate(List<Case__c> applications,  Map<Id, SObject> applicationsMap) {
        Utilities.logMethodEntry('CaseTriggerHelper.processAfterUpdate');
        
        // Check if processing is globally disabled
        if (processingDisabled) {
            System.debug(LoggingLevel.INFO, 
                         'CaseTriggerHelper: Processing is disabled, skipping ' + 
                         applications.size() + ' records');
            Utilities.logMethodExit('CaseTriggerHelper.processAfterInsert');
            return;
        }
        
         System.debug(LoggingLevel.INFO, 'updateStatusCallout started');
        //Update Application Satatus Callout
        updateStatusCallout(applications, applicationsMap);
        
    }
    
    @TestVisible
    private void updateStatusCallout(List<Case__c> applications,  Map<Id, SObject> applicationsMap){

        Utilities.logMethodEntry('CaseTriggerHelper.updateStatusCallout');

        // Filter records: exclude already processed and currently processing
        List<Id> applicationIds = new List<Id>();
        
        for (Case__c app : applications) {
            if(app.Status__c != ((Case__c)applicationsMap.get(app.Id)).Status__c){                
                applicationIds.add(app.Id);
            }
        }
        
        Integer count = 0;
        List<Id> chunk = new List<Id>();
        
        for (Id recId : applicationIds) {
            
            chunk.add(recId);
            count++;
            
            if (count == 100) {
                
                System.debug(LoggingLevel.INFO, 'chunk size 100');
                System.debug(LoggingLevel.INFO, 'Started enqueueJob Application_StatusUpdateQueueable');
                
                System.enqueueJob(new Application_StatusUpdateQueueable(chunk));
                chunk = new List<Id>();
                count = 0;
            }
        }
        
        System.debug(LoggingLevel.INFO, chunk.size());

        // enqueue remaining records
        if (chunk.size() > 0) {
                System.debug(LoggingLevel.INFO, 'chunk size > 0');
                System.debug(LoggingLevel.INFO, 'Started enqueueJob Application_StatusUpdateQueueable');
            Logger.info('Started enqueueJob Application_StatusUpdateQueueable for remaining records');
            Logger.saveLog();
            System.enqueueJob(new Application_StatusUpdateQueueable(chunk));
        }
        
    }
    
}