/**
 * Trigger helper for processing inbound form requests.
 *              Includes improved recursion guard and delegates to the processor.
 */
public with sharing class InboundRequestTriggerHelper {
    
    // Recursion guard - tracks processed record IDs instead of boolean flag
    // This allows new records to be processed while preventing reprocessing of same records
    private static Set<Id> processedRequestIds = new Set<Id>();
    
    // Optional: Track records currently being processed (for nested trigger detection)
    private static Set<Id> currentlyProcessingIds = new Set<Id>();
    
    // Flag to completely disable processing (for data loads, etc.)
    private static Boolean processingDisabled = false;
    
    public InboundRequestTriggerHelper() {
        System.debug(LoggingLevel.DEBUG, 'InboundRequestTriggerHelper instantiated');
    }
    
    // ========================================================================
    // STATIC CONTROL METHODS
    // ========================================================================
    
    /**
     * Reset processed IDs - useful for testing
     */
    @TestVisible
    private static void resetProcessedIds() {
        processedRequestIds.clear();
        currentlyProcessingIds.clear();
    }
    
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
        return processedRequestIds.contains(recordId);
    }
    
    /**
     * Manually mark a record as processed (useful for external integrations)
     */
    public static void markAsProcessed(Id recordId) {
        processedRequestIds.add(recordId);
    }
    
    /**
     * Manually mark multiple records as processed
     */
    public static void markAsProcessed(Set<Id> recordIds) {
        processedRequestIds.addAll(recordIds);
    }
    
    /**
     * Get count of processed records in this transaction
     */
    public static Integer getProcessedCount() {
        return processedRequestIds.size();
    }
    
    // ========================================================================
    // TRIGGER EVENT METHODS (for framework compatibility)
    // ========================================================================
    
    public void processBeforeInsert() {
        // No processing needed before insert
    }
    
    public void processBeforeUpdate() {
        // No processing needed before update
    }
    
    public void processBeforeDelete() {
        // No processing needed before delete
    }
    
    public void processAfterUpdate() {
        // No processing needed after update
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
    public void processAfterInsert(List<Inbound_Request__c> newInboundRequests, 
                                       Map<Id, SObject> newInboundRequestMap) {
        Utilities.logMethodEntry('InboundRequestTriggerHelper.processAfterInsert');
        
        // Check if processing is globally disabled
        if (processingDisabled) {
            System.debug(LoggingLevel.INFO, 
                'InboundRequestTriggerHelper: Processing is disabled, skipping ' + 
                newInboundRequests.size() + ' records');
            Utilities.logMethodExit('InboundRequestTriggerHelper.processAfterInsert');
            return;
        }
        
        // Filter records: exclude already processed and currently processing
        List<Inbound_Request__c> requestsToProcess = new List<Inbound_Request__c>();
        Set<Id> newIdsToProcess = new Set<Id>();
        
        for (Inbound_Request__c req : newInboundRequests) {
            // Skip if already processed in this transaction
            if (processedRequestIds.contains(req.Id)) {
                System.debug(LoggingLevel.DEBUG, 
                    'Skipping already processed record: ' + req.Id);
                continue;
            }
            
            // Skip if currently being processed (nested trigger scenario)
            if (currentlyProcessingIds.contains(req.Id)) {
                System.debug(LoggingLevel.WARN, 
                    'Skipping record currently being processed (nested trigger): ' + req.Id);
                continue;
            }
            
            // Skip if no payload
            if (String.isBlank(req.Payload__c)) {
                System.debug(LoggingLevel.WARN, 
                    'No payload found for Inbound Request: ' + req.Id);
                // Still mark as processed to prevent future attempts
                processedRequestIds.add(req.Id);
                continue;
            }
            
            requestsToProcess.add(req);
            newIdsToProcess.add(req.Id);
        }
        
        // Exit early if nothing to process
        if (requestsToProcess.isEmpty()) {
            System.debug(LoggingLevel.INFO, 
                'No new Inbound Requests to process. Total in trigger: ' + 
                newInboundRequests.size() + ', Already processed: ' + 
                (newInboundRequests.size() - requestsToProcess.size()));
            Utilities.logMethodExit('InboundRequestTriggerHelper.processAfterInsert');
            return;
        }
        
        // Mark records as currently processing (for nested trigger detection)
        currentlyProcessingIds.addAll(newIdsToProcess);
        
        try {
            System.debug(LoggingLevel.INFO, 
                'Processing ' + requestsToProcess.size() + ' inbound requests. ' +
                'Registered form types: ' + InboundForm_ConfigRegistry.getRegisteredFormTypes());
            
            // Delegate to processor
            Map<Id, InboundForm_Processor.ProcessingResult> results = 
                InboundForm_Processor.processRequests(requestsToProcess);
            
            // Mark all as processed (whether successful or not - prevents retry loops)
            processedRequestIds.addAll(newIdsToProcess);
            
            // Log results
            logResults(results);
            
        } catch (Exception e) {
            // Even on exception, mark as processed to prevent infinite retry
            processedRequestIds.addAll(newIdsToProcess);
            
            System.debug(LoggingLevel.ERROR, 
                'Exception in processAfterInsert: ' + e.getMessage() + 
                '\nStack Trace: ' + e.getStackTraceString());
            
            // Re-throw to ensure transaction awareness
            throw e;
            
        } finally {
            // Remove from currently processing set
            currentlyProcessingIds.removeAll(newIdsToProcess);
            Utilities.logMethodExit('InboundRequestTriggerHelper.processAfterInsert');
        }
    }
    
    /**
     * Process records that may need reprocessing (explicit retry)
     * This bypasses the processed check for intentional retries
     */
    public void reprocessRequests(Set<Id> requestIds) {
        if (requestIds == null || requestIds.isEmpty()) {
            return;
        }
        
        Logger.info('Reprocessing ' + requestIds.size() + ' inbound requests');
        System.debug(LoggingLevel.INFO, 
            'Reprocessing ' + requestIds.size() + ' inbound requests');
        
        // Remove from processed set to allow reprocessing
        processedRequestIds.removeAll(requestIds);
        
        // Query fresh records
        List<Inbound_Request__c> requests = [
            SELECT Id, Payload__c, Status__c, Error_Log_Text__c
            FROM Inbound_Request__c
            WHERE Id IN :requestIds
        ];
        
        if (requests.isEmpty()) {
            Logger.warn('No Inbound Requests found for reprocessing');
            System.debug(LoggingLevel.WARN, 'No records found for reprocessing');
            return;
        }
        
        // Build map for processing
        Map<Id, SObject> requestMap = new Map<Id, SObject>();
        for (Inbound_Request__c req : requests) {
            requestMap.put(req.Id, req);
        }
        
        // Process
        processAfterInsert(requests, requestMap);
    }
    
    /**
     * Log processing results
     */
    private void logResults(Map<Id, InboundForm_Processor.ProcessingResult> results) {
        Integer successCount = 0;
        Integer failureCount = 0;
        List<String> failureDetails = new List<String>();
        
        for (Id reqId : results.keySet()) {
            InboundForm_Processor.ProcessingResult result = results.get(reqId);
            
            if (result.success) {
                successCount++;
                Logger.info('Successfully processed Inbound Request: ' + reqId + 
                    ' (Form Type: ' + result.formType + ')');
                System.debug(LoggingLevel.INFO, 
                    'Successfully processed Inbound Request: ' + reqId + 
                    ' (Form Type: ' + result.formType + ')');
            } else {
                failureCount++;
                String errorSummary = 'Request ' + reqId + ': ' + String.join(result.errors, '; ');
                failureDetails.add(errorSummary);
                System.debug(LoggingLevel.ERROR, 
                    'Failed to process Inbound Request ' + reqId + ': ' + 
                    String.join(result.errors, '; '));
                Logger.error('Failed to process Inbound Request ' + reqId + ': ' + String.join(result.errors, '; '));
            }
        }
        
        // Summary log
        System.debug(LoggingLevel.INFO, 
            '=== Processing Summary ===' +
            '\nTotal Processed: ' + results.size() +
            '\nSuccessful: ' + successCount +
            '\nFailed: ' + failureCount +
            '\nTotal Processed This Transaction: ' + processedRequestIds.size() +
            '\n========================');
        
        // Log failure details if any
        if (!failureDetails.isEmpty()) {
            System.debug(LoggingLevel.ERROR, 
                '=== Failure Details ===' +
                '\n' + String.join(failureDetails, '\n') +
                '\n=======================');
            Logger.error('=== Failure Details ===' +
                '\n' + String.join(failureDetails, '\n') +
                '\n=======================');
        }
    }
}