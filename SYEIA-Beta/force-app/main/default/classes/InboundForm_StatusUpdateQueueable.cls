/**
 * Queueable job to update Inbound_Request__c status asynchronously. 
 * Handles partial failures gracefully with retry mechanism.
 */
public class InboundForm_StatusUpdateQueueable implements Queueable, Database.AllowsCallouts {
    
    private List<StatusUpdateData> statusUpdates;
    @TestVisible
    private Integer retryCount;
    private static final Integer MAX_RETRIES = 2;
    private static final Integer BATCH_SIZE = 200; // Process in batches if large
    
    /**
     * Constructor for initial execution
     */
    public InboundForm_StatusUpdateQueueable(List<StatusUpdateData> statusUpdates) {
        this.statusUpdates = statusUpdates;
        this.retryCount = 0;
    }
    
    /**
     * Constructor for retry execution
     */
    public InboundForm_StatusUpdateQueueable(List<StatusUpdateData> statusUpdates, Integer retryCount) {
        this.statusUpdates = statusUpdates;
        this.retryCount = retryCount;
    }
    
    public void execute(QueueableContext ctx) {
        if (statusUpdates == null || statusUpdates.isEmpty()) {
            return;
        }
        
        Id jobId = ctx.getJobId();
        System.debug(LoggingLevel.INFO, 'StatusUpdateQueueable executing: JobId=' + jobId + 
            ', Records=' + statusUpdates.size() + ', RetryCount=' + retryCount);
        Logger.info('StatusUpdateQueueable executing: JobId=' + jobId + 
            ', Records=' + statusUpdates.size() + ', RetryCount=' + retryCount);
        
        // Attach finalizer for error handling
        System.attachFinalizer(new StatusUpdateFinalizer(statusUpdates, retryCount));
        
        List<Inbound_Request__c> recordsToUpdate = new List<Inbound_Request__c>();
        List<StatusUpdateData> failedUpdates = new List<StatusUpdateData>();
        
        // Build records to update
        for (StatusUpdateData data : statusUpdates) {
            Inbound_Request__c record = new Inbound_Request__c(
                Id = data.recordId,
                Status__c = data.status
            );
            
            if (String.isNotBlank(data.errorLog)) {
                record.Error_Log_Text__c = data.errorLog;
            }
            
            if (String.isNotBlank(data.errorMessage)) {
                record.Error_Log_Text__c = data.errorMessage;
            }
            
            recordsToUpdate.add(record);
        }
        
        // Perform update with partial success
        Database.SaveResult[] results = Database.update(recordsToUpdate, false);
        
        // Process results and collect failures
        Integer successCount = 0;
        Integer failureCount = 0;
        
        for (Integer i = 0; i < results.size(); i++) {
            if (results[i].isSuccess()) {
                successCount++;
            } else {
                failureCount++;
                
                // Log the error
                StatusUpdateData failedData = statusUpdates[i];
                List<String> errorMessages = new List<String>();
                
                for (Database.Error err : results[i].getErrors()) {
                    String errorMsg = err.getStatusCode() + ': ' + err.getMessage();
                    errorMessages.add(errorMsg);
                    Logger.error('Failed to update Inbound_Request__c ' + recordsToUpdate[i].Id + ': ' + errorMsg);
                    Logger.setScenario('InboundForm_StatusUpdateQueueable.execute');
                    System.debug(LoggingLevel.ERROR, 
                        'Failed to update Inbound_Request__c ' + recordsToUpdate[i].Id + ': ' + errorMsg);
                }
                
                // Track for potential retry (only retryable errors)
                if (isRetryableError(results[i].getErrors())) {
                    failedData.lastError = String.join(errorMessages, '; ');
                    failedUpdates.add(failedData);
                } else {
                    // Log non-retryable failure permanently
                    logPermanentFailure(failedData, errorMessages);
                }
            }
        }
        
        Logger.info('StatusUpdateQueueable complete: Success=' + successCount + 
            ', Failed=' + failureCount + ', Retryable=' + failedUpdates.size());
        Logger.setScenario('InboundForm_StatusUpdateQueueable.execute');
        System.debug(LoggingLevel.INFO, 'StatusUpdateQueueable complete: Success=' + successCount + 
            ', Failed=' + failureCount + ', Retryable=' + failedUpdates.size());

        
        // Queue retry for retryable failures if within retry limit
        if (!failedUpdates.isEmpty() && retryCount < MAX_RETRIES) {
            queueRetry(failedUpdates);
        } else if (!failedUpdates.isEmpty()) {
            // Max retries exceeded, log permanent failures
            for (StatusUpdateData failed : failedUpdates) {
                logPermanentFailure(failed, new List<String>{ 'Max retries exceeded: ' + failed.lastError });
                Logger.error('Max retries exceeded for Inbound_Request__c ' + failed.recordId + ': ' + failed.lastError);
                Logger.setScenario('InboundForm_StatusUpdateQueueable.execute');
            }
        }
        
        // save all logs
        Logger.saveLog();
    }
    
    /**
     * Determine if an error is retryable (transient vs permanent)
     */
    @TestVisible
    private Boolean isRetryableError(List<Database.Error> errors) {
        for (Database.Error err : errors) {
            StatusCode code = err.getStatusCode();
            
            // Retryable errors (transient)
            if (code == StatusCode.UNABLE_TO_LOCK_ROW ||
                code == StatusCode.QUERY_TIMEOUT ||
                code == StatusCode.REQUEST_RUNNING_TOO_LONG) {
                return true;
            }
            
            // Non-retryable errors (permanent)
            if (code == StatusCode.INVALID_CROSS_REFERENCE_KEY ||
                code == StatusCode.ENTITY_IS_DELETED ||
                code == StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION ||
                code == StatusCode.REQUIRED_FIELD_MISSING) {
                return false;
            }
        }
        
        // Default to retryable for unknown errors
        return true;
    }
    
    /**
     * Queue a retry job with exponential backoff simulation
     */
    @TestVisible
    private void queueRetry(List<StatusUpdateData> failedUpdates) {
        try {
            // In Salesforce, we can't delay queueable execution directly,
            // but we can chain the retry
            Id retryJobId = System.enqueueJob(
                new InboundForm_StatusUpdateQueueable(failedUpdates, retryCount + 1)
            );
            Logger.info('Queued retry job: ' + retryJobId + 
                ' for ' + failedUpdates.size() + ' records (attempt ' + (retryCount + 2) + ')');
            System.debug(LoggingLevel.INFO, 'Queued retry job: ' + retryJobId + 
                ' for ' + failedUpdates.size() + ' records (attempt ' + (retryCount + 2) + ')');
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to queue retry: ' + e.getMessage());
            Logger.error('Failed to queue retry: ' + e.getMessage());
            Logger.setScenario('InboundForm_StatusUpdateQueueable.queueRetry');
            // Log all as permanent failures
            for (StatusUpdateData failed : failedUpdates) {
                Logger.error('Retry failed for Inbound_Request__c ' + failed.recordId + ': ' + e.getMessage());
                logPermanentFailure(failed, new List<String>{ 'Retry queue failed: ' + e.getMessage() });
            }
        }
        Logger.saveLog();
    }
    
    /**
     * Log permanent failure for monitoring/alerting
     */
    @TestVisible
    private void logPermanentFailure(StatusUpdateData data, List<String> errorMessages) {
        System.debug(LoggingLevel.ERROR, 
            '=== PERMANENT STATUS UPDATE FAILURE ===' +
            '\nInbound_Request__c Id: ' + data.recordId +
            '\nIntended Status: ' + data.status +
            '\nErrors: ' + String.join(errorMessages, '; ') +
            '\n=========================================');
        
        // Optional: Create error log record for visibility
        try {
            createErrorLogRecord(data, errorMessages);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to create error log record: ' + e.getMessage());
        }
    }
    
    /**
     * Create an error log record for permanent failures
     * This allows admins to see and address failed status updates
     */
    @TestVisible
    private void createErrorLogRecord(StatusUpdateData data, List<String> errorMessages) {
        // Check if the Inbound_Request__c record still exists and update its error field
        try {
            Inbound_Request__c req = new Inbound_Request__c(
                Id = data.recordId,
                Error_Log_Text__c = 'STATUS UPDATE FAILED\n' +
                    'Intended Status: ' + data.status + '\n' +
                    'Errors: ' + String.join(errorMessages, '\n') + '\n' +
                    'Original Error: ' + (data.errorLog != null ? data.errorLog : 'None') + '\n' +
                    'Timestamp: ' + DateTime.now().format()
            );
            
            // Try to update just the error log field
            Database.SaveResult sr = Database.update(req, false);
            if (!sr.isSuccess()) {
                System.debug(LoggingLevel.ERROR, 'Could not update error log on record');
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error logging failed: ' + e.getMessage());
        }
    }
    
    /**
     * Data transfer object for status updates
     */
    public class StatusUpdateData {
        public Id recordId { get; set; }
        public String status { get; set; }
        public String errorLog { get; set; }
        public String errorMessage { get; set; } // Short error message for Error_Log_Text__c field
        public String lastError { get; set; } // Tracks last error for retry scenarios
        
        public StatusUpdateData(Id recordId, String status, String errorLog) {
            this.recordId = recordId;
            this.status = status;
            this.errorLog = errorLog;
            this.errorMessage = errorLog; // Default errorMessage to errorLog
        }
        
        public StatusUpdateData(Id recordId, String status, String errorLog, String errorMessage) {
            this.recordId = recordId;
            this.status = status;
            this.errorLog = errorLog;
            this.errorMessage = errorMessage;
        }
    }
    
    /**
     * Finalizer class to handle job failures and unexpected exceptions
     */
    public class StatusUpdateFinalizer implements Finalizer {
        
        private List<StatusUpdateData> statusUpdates;
        private Integer retryCount;
        
        public StatusUpdateFinalizer(List<StatusUpdateData> statusUpdates, Integer retryCount) {
            this.statusUpdates = statusUpdates;
            this.retryCount = retryCount;
        }
        
        public void execute(FinalizerContext ctx) {
            Id parentJobId = ctx.getAsyncApexJobId();
            
            switch on ctx.getResult() {
                when SUCCESS {
                    System.debug(LoggingLevel.DEBUG, 
                        'StatusUpdateQueueable completed successfully: ' + parentJobId);
                }
                when UNHANDLED_EXCEPTION {
                    // Job failed with unhandled exception
                    String exceptionMessage = ctx.getException() != null 
                        ? ctx.getException().getMessage() 
                        : 'Unknown exception';
                    
                    System.debug(LoggingLevel.ERROR, 
                        'StatusUpdateQueueable FAILED with unhandled exception: ' + parentJobId +
                        '\nException: ' + exceptionMessage);
                    
                    // Attempt retry if within limits
                    if (retryCount < MAX_RETRIES && statusUpdates != null && !statusUpdates.isEmpty()) {
                        handleFailedJobRetry(exceptionMessage);
                    } else {
                        // Log all as permanent failures
                        logAllAsPermanentFailures(exceptionMessage);
                    }
                }
            }
        }
        
        /**
         * Handle retry after job failure
         */
        @TestVisible
        private void handleFailedJobRetry(String exceptionMessage) {
            try {
                // Mark all with the exception error
                for (StatusUpdateData data : statusUpdates) {
                    data.lastError = 'Job exception: ' + exceptionMessage;
                }
                
                Id retryJobId = System.enqueueJob(
                    new InboundForm_StatusUpdateQueueable(statusUpdates, retryCount + 1)
                );
                
                System.debug(LoggingLevel.WARN, 
                    'Finalizer queued retry job after failure: ' + retryJobId +
                    ' (attempt ' + (retryCount + 2) + ')');
                    
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 
                    'Finalizer failed to queue retry: ' + e.getMessage());
                logAllAsPermanentFailures(exceptionMessage + ' | Retry failed: ' + e.getMessage());
            }
        }
        
        /**
         * Log all updates as permanent failures
         */
        @TestVisible
        private void logAllAsPermanentFailures(String errorMessage) {
            if (statusUpdates == null) return;
            
            for (StatusUpdateData data : statusUpdates) {
                System.debug(LoggingLevel.ERROR, 
                    '=== PERMANENT FAILURE (from Finalizer) ===' +
                    '\nInbound_Request__c Id: ' + data.recordId +
                    '\nIntended Status: ' + data.status +
                    '\nError: ' + errorMessage +
                    '\n==========================================');
            }
            
            // Try to update records with error information
            List<Inbound_Request__c> errorUpdates = new List<Inbound_Request__c>();
            for (StatusUpdateData data : statusUpdates) {
                errorUpdates.add(new Inbound_Request__c(
                    Id = data.recordId,
                    Error_Log_Text__c = 'STATUS UPDATE FAILED (Unhandled Exception)\n' +
                        'Error: ' + errorMessage + '\n' +
                        'Timestamp: ' + DateTime.now().format()
                ));
            }
            
            if (!errorUpdates.isEmpty()) {
                Database.update(errorUpdates, false); // Best effort
            }
        }
    }
}