/**
 * Trigger helper for processing ContentVersion.
 *              Includes improved recursion guard and delegates to the processor.
 */
public class ContentVersionTriggerHelper {
    
    // Recursion guard - tracks processed record IDs instead of boolean flag
    // This allows new records to be processed while preventing reprocessing of same records
    private static Set<Id> processedRequestIds = new Set<Id>();
    
    // Optional: Track records currently being processed (for nested trigger detection)
    private static Set<Id> currentlyProcessingIds = new Set<Id>();
    
    // Flag to completely disable processing (for data loads, etc.)
    private static Boolean processingDisabled = false;

    // add more extensions as needed (e.g., for different trigger contexts)
    private static final Set<String> BLOCKED_EXTENSIONS = new Set<String>{
        'exe'
    };
    
    public ContentVersionTriggerHelper() {
        System.debug(LoggingLevel.DEBUG, 'ContentVersionTriggerHelper instantiated');
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
    
    public void processBeforeInsert(List<ContentVersion> newRecords) {
        try { 
            enforceBlockedExtensions(newRecords);
        } catch (Exception ex) {
            Utilities.logMethodExit('ContentVersionTriggerHelper.processBeforeInsert');
            throw ex; // Re-throw to ensure transaction awareness
        }
    }
    
    public void processBeforeUpdate(List<ContentVersion> oldRecords, List<ContentVersion> newRecords, 
                                   Map<Id, SObject> oldRecordMap, Map<Id, SObject> newRecordMap) {
        try { 
            enforceBlockedExtensions(newRecords);
        } catch (Exception ex) {
            Utilities.logMethodExit('ContentVersionTriggerHelper.processBeforeUpdate');
            throw ex; // Re-throw to ensure transaction awareness
        }
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
     * Main entry point for processing ContentVersion records (after insert)
     */
    public void processAfterInsert() {
        // No processing needed after insert in current requirements
    }
    
    // Helper methods for other trigger contexts can be added here (e.g., processAfterUpdate, etc.)

    /**
     * Process records that have been inserted before it is committed to the database, allowing us to enforce validation rules like blocked file extensions.
     * Returns void but adds errors to records that fail validation, preventing them from being saved.
     * Param contentVersions List of ContentVersion records being inserted (Trigger.new)
     */
    public static void enforceBlockedExtensions(List<ContentVersion> contentVersions) {
        Utilities.logMethodEntry('ContentVersionTriggerHelper.enforceBlockedExtensions');
        
        if (contentVersions == null || contentVersions.isEmpty()) {
            return;
        }
        for (ContentVersion cv : contentVersions) {
            String fileExtension = cv.PathOnClient != null ? 
                cv.PathOnClient.substringAfterLast('.').toLowerCase() : '';
            if (BLOCKED_EXTENSIONS.contains(fileExtension)) {
                cv.addError('Files with .' + fileExtension + ' extension are not allowed.');
            }
        }
        Utilities.logMethodExit('ContentVersionTriggerHelper.enforceBlockedExtensions');
    }

    /**
     * Process records that may need reprocessing (explicit retry)
     * This bypasses the processed check for intentional retries
     */
    // public void reprocessRequests(Set<Id> requestIds) {
    //     if (requestIds == null || requestIds.isEmpty()) {
    //         return;
    //     }
        
    //     System.debug(LoggingLevel.INFO, 
    //         'Reprocessing ' + requestIds.size() + ' ContentVersion records. IDs: ' + String.join(new List<Id>(requestIds), ','));
        
    //     // Remove from processed set to allow reprocessing
    //     processedRequestIds.removeAll(requestIds);
        
    //     // Query fresh records
    //     List<ContentVersion> requests = [
    //         SELECT Id
    //         FROM ContentVersion
    //         WHERE Id IN :requestIds
    //     ];
        
    //     if (requests.isEmpty()) {
    //         System.debug(LoggingLevel.WARN, 'No records found for reprocessing');
    //         return;
    //     }
        
    //     // Build map for processing
    //     Map<Id, SObject> requestMap = new Map<Id, SObject>();
    //     for (ContentVersion req : requests) {
    //         requestMap.put(req.Id, req);
    //     }
        
    //     // Process
    //     processAfterInsert(requests, requestMap);
    // }
}