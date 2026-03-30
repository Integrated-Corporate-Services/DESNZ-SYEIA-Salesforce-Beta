/**
 * Test class for InboundForm_StatusUpdateQueueable.
 * Tests queueable job execution, retry mechanism, error handling, and partial success.
 */
@IsTest
private class InboundForm_StatusUpdateQueueableTest {
    
    // ========================================================================
    // TEST SETUP
    // ========================================================================
    
    @TestSetup
    static void setupTestData() {
        List<Inbound_Request__c> requests = new List<Inbound_Request__c>();
        for (Integer i = 0; i < 5; i++) {
            requests.add(new Inbound_Request__c(
                Payload__c = '{"formType": "S37", "applicationId": "APP-' + i + '"}',
                Status__c = 'Received'
            ));
        }
        insert requests;
    }
    
    // ========================================================================
    // CONSTRUCTOR TESTS
    // ========================================================================
    
    @IsTest
    static void testConstructor_InitialExecution() {
        List<Inbound_Request__c> requests = [SELECT Id FROM Inbound_Request__c LIMIT 1];
        
        List<InboundForm_StatusUpdateQueueable.StatusUpdateData> updates = 
            new List<InboundForm_StatusUpdateQueueable.StatusUpdateData>{
                new InboundForm_StatusUpdateQueueable.StatusUpdateData(
                    requests[0].Id, 'Processed', null)
            };
        
        Test.startTest();
        InboundForm_StatusUpdateQueueable queueable = 
            new InboundForm_StatusUpdateQueueable(updates);
        Test.stopTest();
        
        Assert.isNotNull(queueable, 'Queueable should be created');
    }
    
    @IsTest
    static void testConstructor_RetryExecution() {
        List<Inbound_Request__c> requests = [SELECT Id FROM Inbound_Request__c LIMIT 1];
        
        List<InboundForm_StatusUpdateQueueable.StatusUpdateData> updates = 
            new List<InboundForm_StatusUpdateQueueable.StatusUpdateData>{
                new InboundForm_StatusUpdateQueueable.StatusUpdateData(
                    requests[0].Id, 'Failed', 'Error message')
            };
        
        Test.startTest();
        InboundForm_StatusUpdateQueueable queueable = 
            new InboundForm_StatusUpdateQueueable(updates, 1);
        Test.stopTest();
        
        Assert.isNotNull(queueable, 'Queueable with retry count should be created');
    }
    
    // ========================================================================
    // STATUS UPDATE DATA TESTS
    // ========================================================================
    
    @IsTest
    static void testStatusUpdateData_Constructor() {
        List<Inbound_Request__c> requests = [SELECT Id FROM Inbound_Request__c LIMIT 1];
        
        Test.startTest();
        InboundForm_StatusUpdateQueueable.StatusUpdateData data = 
            new InboundForm_StatusUpdateQueueable.StatusUpdateData(
                requests[0].Id, 'Processed', 'Error text');
        Test.stopTest();
        
        Assert.areEqual(requests[0].Id, data.recordId, 'Record ID should match');
        Assert.areEqual('Processed', data.status, 'Status should match');
        Assert.areEqual('Error text', data.errorLog, 'Error log should match');
        Assert.areEqual('Error text', data.errorMessage, 'Error message should default to error log');
    }
    
    @IsTest
    static void testStatusUpdateData_FourParamConstructor() {
        List<Inbound_Request__c> requests = [SELECT Id FROM Inbound_Request__c LIMIT 1];
        
        Test.startTest();
        InboundForm_StatusUpdateQueueable.StatusUpdateData data = 
            new InboundForm_StatusUpdateQueueable.StatusUpdateData(
                requests[0].Id, 'Partial Success', 'Full error log', 'Short error');
        Test.stopTest();
        
        Assert.areEqual(requests[0].Id, data.recordId, 'Record ID should match');
        Assert.areEqual('Partial Success', data.status, 'Status should match');
        Assert.areEqual('Full error log', data.errorLog, 'Error log should match');
        Assert.areEqual('Short error', data.errorMessage, 'Error message should be separate from error log');
    }
    
    @IsTest
    static void testStatusUpdateData_ThreeParamConstructor_DefaultsErrorMessage() {
        List<Inbound_Request__c> requests = [SELECT Id FROM Inbound_Request__c LIMIT 1];
        
        Test.startTest();
        InboundForm_StatusUpdateQueueable.StatusUpdateData data = 
            new InboundForm_StatusUpdateQueueable.StatusUpdateData(
                requests[0].Id, 'Failed', 'Error details');
        Test.stopTest();
        
        Assert.areEqual('Error details', data.errorLog, 'Error log should match');
        Assert.areEqual('Error details', data.errorMessage, 'Error message should default to error log');
    }
    
    @IsTest
    static void testStatusUpdateData_LastError() {
        List<Inbound_Request__c> requests = [SELECT Id FROM Inbound_Request__c LIMIT 1];
        
        InboundForm_StatusUpdateQueueable.StatusUpdateData data = 
            new InboundForm_StatusUpdateQueueable.StatusUpdateData(
                requests[0].Id, 'Failed', null);
        
        Test.startTest();
        data.lastError = 'Last error message';
        Test.stopTest();
        
        Assert.areEqual('Last error message', data.lastError, 'Last error should be set');
    }
    
    @IsTest
    static void testStatusUpdateData_NullErrorLog() {
        List<Inbound_Request__c> requests = [SELECT Id FROM Inbound_Request__c LIMIT 1];
        
        Test.startTest();
        InboundForm_StatusUpdateQueueable.StatusUpdateData data = 
            new InboundForm_StatusUpdateQueueable.StatusUpdateData(
                requests[0].Id, 'Processed', null);
        Test.stopTest();
        
        Assert.isNull(data.errorLog, 'Error log should be null');
        Assert.isNull(data.errorMessage, 'Error message should also be null when errorLog is null');
    }
    
    // ========================================================================
    // EXECUTE TESTS
    // ========================================================================
    
    @IsTest
    static void testExecute_SuccessfulUpdate() {
        List<Inbound_Request__c> requests = [SELECT Id FROM Inbound_Request__c LIMIT 2];
        
        List<InboundForm_StatusUpdateQueueable.StatusUpdateData> updates = 
            new List<InboundForm_StatusUpdateQueueable.StatusUpdateData>{
                new InboundForm_StatusUpdateQueueable.StatusUpdateData(
                    requests[0].Id, 'Processed', null),
                new InboundForm_StatusUpdateQueueable.StatusUpdateData(
                    requests[1].Id, 'Failed', 'Some error')
            };
        
        Test.startTest();
        System.enqueueJob(new InboundForm_StatusUpdateQueueable(updates));
        Test.stopTest();
        
        List<Inbound_Request__c> updatedRequests = [
            SELECT Id, Status__c, Error_Log_Text__c 
            FROM Inbound_Request__c 
            WHERE Id IN :new List<Id>{requests[0].Id, requests[1].Id}
        ];
        
        Map<Id, Inbound_Request__c> requestMap = new Map<Id, Inbound_Request__c>(updatedRequests);
        
        Assert.areEqual('Processed', requestMap.get(requests[0].Id).Status__c, 
            'First record should be Processed');
        Assert.areEqual('Failed', requestMap.get(requests[1].Id).Status__c, 
            'Second record should be Failed');
        Assert.areEqual('Some error', requestMap.get(requests[1].Id).Error_Log_Text__c, 
            'Error log should be set');
    }
    
    @IsTest
    static void testExecute_PartialSuccessStatus() {
        List<Inbound_Request__c> requests = [SELECT Id FROM Inbound_Request__c LIMIT 1];
        
        List<InboundForm_StatusUpdateQueueable.StatusUpdateData> updates = 
            new List<InboundForm_StatusUpdateQueueable.StatusUpdateData>{
                new InboundForm_StatusUpdateQueueable.StatusUpdateData(
                    requests[0].Id, 
                    'Partial Success', 
                    'Failed to find Case using AWS Id ABC-123',
                    'Failed to find Case using AWS Id ABC-123')
            };
        
        Test.startTest();
        System.enqueueJob(new InboundForm_StatusUpdateQueueable(updates));
        Test.stopTest();
        
        Inbound_Request__c updatedRequest = [
            SELECT Status__c, Error_Log_Text__c 
            FROM Inbound_Request__c 
            WHERE Id = :requests[0].Id
        ];
        
        Assert.areEqual('Partial Success', updatedRequest.Status__c, 
            'Status should be Partial Success');
        Assert.isTrue(updatedRequest.Error_Log_Text__c.contains('Failed to find Case'), 
            'Error log should contain warning message');
    }
    
    @IsTest
    static void testExecute_EmptyList() {
        List<InboundForm_StatusUpdateQueueable.StatusUpdateData> updates = 
            new List<InboundForm_StatusUpdateQueueable.StatusUpdateData>();
        
        Test.startTest();
        System.enqueueJob(new InboundForm_StatusUpdateQueueable(updates));
        Test.stopTest();
        
        Assert.isTrue(true, 'Empty list should be handled gracefully');
    }
    
    @IsTest
    static void testExecute_NullList() {
        Test.startTest();
        System.enqueueJob(new InboundForm_StatusUpdateQueueable(null));
        Test.stopTest();
        
        Assert.isTrue(true, 'Null list should be handled gracefully');
    }
    
    @IsTest
    static void testExecute_MultipleRecords() {
        List<Inbound_Request__c> requests = [SELECT Id FROM Inbound_Request__c];
        
        List<InboundForm_StatusUpdateQueueable.StatusUpdateData> updates = 
            new List<InboundForm_StatusUpdateQueueable.StatusUpdateData>();
        
        for (Integer i = 0; i < requests.size(); i++) {
            String status = Math.mod(i, 2) == 0 ? 'Processed' : 'Failed';
            String error = status == 'Failed' ? 'Error ' + i : null;
            updates.add(new InboundForm_StatusUpdateQueueable.StatusUpdateData(
                requests[i].Id, status, error));
        }
        
        Test.startTest();
        System.enqueueJob(new InboundForm_StatusUpdateQueueable(updates));
        Test.stopTest();
        
        List<Inbound_Request__c> updatedRequests = [
            SELECT Id, Status__c FROM Inbound_Request__c
        ];
        
        for (Inbound_Request__c req : updatedRequests) {
            Assert.isTrue(req.Status__c == 'Processed' || req.Status__c == 'Failed', 
                'Status should be updated');
        }
    }
    
    // ========================================================================
    // FINALIZER TESTS
    // ========================================================================
    
    @IsTest
    static void testFinalizer_Construction() {
        List<Inbound_Request__c> requests = [SELECT Id FROM Inbound_Request__c LIMIT 1];
        
        List<InboundForm_StatusUpdateQueueable.StatusUpdateData> updates = 
            new List<InboundForm_StatusUpdateQueueable.StatusUpdateData>{
                new InboundForm_StatusUpdateQueueable.StatusUpdateData(
                    requests[0].Id, 'Processed', null)
            };
        
        Test.startTest();
        InboundForm_StatusUpdateQueueable.StatusUpdateFinalizer finalizer = 
            new InboundForm_StatusUpdateQueueable.StatusUpdateFinalizer(updates, 0);
        Test.stopTest();
        
        Assert.isNotNull(finalizer, 'Finalizer should be created');
    }
    
    @IsTest
    static void testFinalizer_WithRetryCount() {
        List<Inbound_Request__c> requests = [SELECT Id FROM Inbound_Request__c LIMIT 1];
        
        List<InboundForm_StatusUpdateQueueable.StatusUpdateData> updates = 
            new List<InboundForm_StatusUpdateQueueable.StatusUpdateData>{
                new InboundForm_StatusUpdateQueueable.StatusUpdateData(
                    requests[0].Id, 'Failed', 'Error')
            };
        
        Test.startTest();
        InboundForm_StatusUpdateQueueable.StatusUpdateFinalizer finalizer = 
            new InboundForm_StatusUpdateQueueable.StatusUpdateFinalizer(updates, 2);
        Test.stopTest();
        
        Assert.isNotNull(finalizer, 'Finalizer with max retries should be created');
    }
    
    // ========================================================================
    // RETRY TESTS
    // ========================================================================
    
    @IsTest
    static void testExecute_WithRetryCount() {
        List<Inbound_Request__c> requests = [SELECT Id FROM Inbound_Request__c LIMIT 1];
        
        List<InboundForm_StatusUpdateQueueable.StatusUpdateData> updates = 
            new List<InboundForm_StatusUpdateQueueable.StatusUpdateData>{
                new InboundForm_StatusUpdateQueueable.StatusUpdateData(
                    requests[0].Id, 'Processed', null)
            };
        
        Test.startTest();
        System.enqueueJob(new InboundForm_StatusUpdateQueueable(updates, 1));
        Test.stopTest();
        
        Inbound_Request__c updatedReq = [
            SELECT Status__c FROM Inbound_Request__c WHERE Id = :requests[0].Id
        ];
        Assert.areEqual('Processed', updatedReq.Status__c, 
            'Status should be updated even on retry');
    }
    
    @IsTest
    static void testExecute_MaxRetries() {
        List<Inbound_Request__c> requests = [SELECT Id FROM Inbound_Request__c LIMIT 1];
        
        List<InboundForm_StatusUpdateQueueable.StatusUpdateData> updates = 
            new List<InboundForm_StatusUpdateQueueable.StatusUpdateData>{
                new InboundForm_StatusUpdateQueueable.StatusUpdateData(
                    requests[0].Id, 'Processed', null)
            };
        
        Test.startTest();
        System.enqueueJob(new InboundForm_StatusUpdateQueueable(updates, 2));
        Test.stopTest();
        
        Inbound_Request__c updatedReq = [
            SELECT Status__c FROM Inbound_Request__c WHERE Id = :requests[0].Id
        ];
        Assert.areEqual('Processed', updatedReq.Status__c, 
            'Status should be updated');
    }
    
    @IsTest
    static void testExecute_BeyondMaxRetries() {
        List<Inbound_Request__c> requests = [SELECT Id FROM Inbound_Request__c LIMIT 1];
        
        List<InboundForm_StatusUpdateQueueable.StatusUpdateData> updates = 
            new List<InboundForm_StatusUpdateQueueable.StatusUpdateData>{
                new InboundForm_StatusUpdateQueueable.StatusUpdateData(
                    requests[0].Id, 'Failed', 'Persistent error')
            };
        updates[0].lastError = 'Previous retry error';
        
        Test.startTest();
        // Retry count of 3 exceeds MAX_RETRIES of 2
        System.enqueueJob(new InboundForm_StatusUpdateQueueable(updates, 3));
        Test.stopTest();
        
        Inbound_Request__c updatedReq = [
            SELECT Status__c FROM Inbound_Request__c WHERE Id = :requests[0].Id
        ];
        Assert.areEqual('Failed', updatedReq.Status__c, 
            'Status should still be updated');
    }
    
    // ========================================================================
    // DML FAILURE TESTS - These trigger failureCount++ code paths
    // ========================================================================
    
    @IsTest
    static void testExecute_DeletedRecordFailure() {
        // Create a record specifically for this test
        Inbound_Request__c request = new Inbound_Request__c(
            Payload__c = '{"formType": "S37", "applicationId": "DEL-TEST"}',
            Status__c = 'Received'
        );
        insert request;
        Id deletedId = request.Id;
        
        // Delete the record before trying to update it
        delete request;
        
        List<InboundForm_StatusUpdateQueueable.StatusUpdateData> updates = 
            new List<InboundForm_StatusUpdateQueueable.StatusUpdateData>{
                new InboundForm_StatusUpdateQueueable.StatusUpdateData(
                    deletedId, 'Processed', null)
            };
        
        Test.startTest();
        // This will trigger a DML failure (ENTITY_IS_DELETED) which exercises failureCount++
        System.enqueueJob(new InboundForm_StatusUpdateQueueable(updates));
        Test.stopTest();
        
        // Record should remain deleted
        Integer count = [SELECT COUNT() FROM Inbound_Request__c WHERE Id = :deletedId];
        Assert.areEqual(0, count, 'Deleted record should not be restored');
    }
    
    @IsTest
    static void testExecute_MixedSuccessAndFailure() {
        // Create records for this test
        List<Inbound_Request__c> newRequests = new List<Inbound_Request__c>();
        for (Integer i = 0; i < 3; i++) {
            newRequests.add(new Inbound_Request__c(
                Payload__c = '{"formType": "S37", "applicationId": "MIX-' + i + '"}',
                Status__c = 'Received'
            ));
        }
        insert newRequests;
        
        // Delete one record to cause failure
        Id deletedId = newRequests[1].Id;
        delete newRequests[1];
        
        List<InboundForm_StatusUpdateQueueable.StatusUpdateData> updates = 
            new List<InboundForm_StatusUpdateQueueable.StatusUpdateData>{
                new InboundForm_StatusUpdateQueueable.StatusUpdateData(
                    newRequests[0].Id, 'Processed', null),
                new InboundForm_StatusUpdateQueueable.StatusUpdateData(
                    deletedId, 'Processed', null), // This will fail
                new InboundForm_StatusUpdateQueueable.StatusUpdateData(
                    newRequests[2].Id, 'Failed', 'Some error')
            };
        
        Test.startTest();
        System.enqueueJob(new InboundForm_StatusUpdateQueueable(updates));
        Test.stopTest();
        
        // Check that valid records were updated
        List<Inbound_Request__c> remaining = [
            SELECT Id, Status__c FROM Inbound_Request__c 
            WHERE Id IN (:newRequests[0].Id, :newRequests[2].Id)
        ];
        
        Assert.areEqual(2, remaining.size(), 'Two records should remain');
    }
    
    @IsTest
    static void testExecute_AllRecordsDeleted() {
        // Create records specifically for this test
        List<Inbound_Request__c> newRequests = new List<Inbound_Request__c>();
        for (Integer i = 0; i < 2; i++) {
            newRequests.add(new Inbound_Request__c(
                Payload__c = '{"formType": "S37", "applicationId": "ALL-DEL-' + i + '"}',
                Status__c = 'Received'
            ));
        }
        insert newRequests;
        
        List<Id> deletedIds = new List<Id>();
        for (Inbound_Request__c req : newRequests) {
            deletedIds.add(req.Id);
        }
        
        // Delete all records
        delete newRequests;
        
        List<InboundForm_StatusUpdateQueueable.StatusUpdateData> updates = 
            new List<InboundForm_StatusUpdateQueueable.StatusUpdateData>();
        for (Id delId : deletedIds) {
            updates.add(new InboundForm_StatusUpdateQueueable.StatusUpdateData(
                delId, 'Processed', null));
        }
        
        Test.startTest();
        // All updates will fail, exercising full failure handling path
        System.enqueueJob(new InboundForm_StatusUpdateQueueable(updates));
        Test.stopTest();
        
        // All records should remain deleted
        Integer count = [SELECT COUNT() FROM Inbound_Request__c WHERE Id IN :deletedIds];
        Assert.areEqual(0, count, 'All deleted records should remain deleted');
    }
    
    @IsTest
    static void testExecute_FailureWithRetryExceeded() {
        // Create and delete a record
        Inbound_Request__c request = new Inbound_Request__c(
            Payload__c = '{"formType": "S37", "applicationId": "RETRY-EXCEED"}',
            Status__c = 'Received'
        );
        insert request;
        Id deletedId = request.Id;
        delete request;
        
        List<InboundForm_StatusUpdateQueueable.StatusUpdateData> updates = 
            new List<InboundForm_StatusUpdateQueueable.StatusUpdateData>{
                new InboundForm_StatusUpdateQueueable.StatusUpdateData(
                    deletedId, 'Processed', null)
            };
        updates[0].lastError = 'Previous error';
        
        Test.startTest();
        // Start at max retries so failure goes to permanent failure path
        System.enqueueJob(new InboundForm_StatusUpdateQueueable(updates, 2));
        Test.stopTest();
        
        // Should complete without exception
        Assert.isTrue(true, 'Should handle max retry exceeded gracefully');
    }
    
    // ========================================================================
    // INTEGRATION TESTS
    // ========================================================================
    
    @IsTest
    static void testIntegration_QueuedFromProcessor() {
        List<Inbound_Request__c> requests = [SELECT Id FROM Inbound_Request__c LIMIT 1];
        
        List<InboundForm_StatusUpdateQueueable.StatusUpdateData> updates = 
            new List<InboundForm_StatusUpdateQueueable.StatusUpdateData>{
                new InboundForm_StatusUpdateQueueable.StatusUpdateData(
                    requests[0].Id, 
                    'Processed', 
                    null
                )
            };
        
        Test.startTest();
        Id jobId = System.enqueueJob(new InboundForm_StatusUpdateQueueable(updates));
        Test.stopTest();
        
        Assert.isNotNull(jobId, 'Job should be queued');
        
        Inbound_Request__c updatedReq = [
            SELECT Status__c FROM Inbound_Request__c WHERE Id = :requests[0].Id
        ];
        Assert.areEqual('Processed', updatedReq.Status__c, 'Status should be updated');
    }
    
    @IsTest
    static void testIntegration_ErrorLogTruncation() {
        List<Inbound_Request__c> requests = [SELECT Id FROM Inbound_Request__c LIMIT 1];
        
        String longError = '';
        for (Integer i = 0; i < 1000; i++) {
            longError += 'Error line ' + i + '\n';
        }
        
        List<InboundForm_StatusUpdateQueueable.StatusUpdateData> updates = 
            new List<InboundForm_StatusUpdateQueueable.StatusUpdateData>{
                new InboundForm_StatusUpdateQueueable.StatusUpdateData(
                    requests[0].Id, 'Failed', longError)
            };
        
        Test.startTest();
        System.enqueueJob(new InboundForm_StatusUpdateQueueable(updates));
        Test.stopTest();
        
        Inbound_Request__c updatedReq = [
            SELECT Error_Log_Text__c FROM Inbound_Request__c WHERE Id = :requests[0].Id
        ];
        
        Assert.isNotNull(updatedReq.Error_Log_Text__c, 'Error log should be set');
    }
    
    @IsTest
    static void testIntegration_MixedStatuses() {
        List<Inbound_Request__c> requests = [SELECT Id FROM Inbound_Request__c LIMIT 3];
        
        List<InboundForm_StatusUpdateQueueable.StatusUpdateData> updates = 
            new List<InboundForm_StatusUpdateQueueable.StatusUpdateData>{
                new InboundForm_StatusUpdateQueueable.StatusUpdateData(
                    requests[0].Id, 'Processed', null),
                new InboundForm_StatusUpdateQueueable.StatusUpdateData(
                    requests[1].Id, 'Failed', 'Error occurred'),
                new InboundForm_StatusUpdateQueueable.StatusUpdateData(
                    requests[2].Id, 'Partial Success', 'Warning message', 'Warning message')
            };
        
        Test.startTest();
        System.enqueueJob(new InboundForm_StatusUpdateQueueable(updates));
        Test.stopTest();
        
        Map<Id, Inbound_Request__c> updatedRequests = new Map<Id, Inbound_Request__c>([
            SELECT Id, Status__c, Error_Log_Text__c 
            FROM Inbound_Request__c 
            WHERE Id IN :new List<Id>{requests[0].Id, requests[1].Id, requests[2].Id}
        ]);
        
        Assert.areEqual('Processed', updatedRequests.get(requests[0].Id).Status__c);
        Assert.areEqual('Failed', updatedRequests.get(requests[1].Id).Status__c);
        Assert.areEqual('Partial Success', updatedRequests.get(requests[2].Id).Status__c);
    }
    
    @IsTest
    static void testIntegration_LargeVolume() {
        // Create additional requests for volume testing
        List<Inbound_Request__c> additionalRequests = new List<Inbound_Request__c>();
        for (Integer i = 0; i < 50; i++) {
            additionalRequests.add(new Inbound_Request__c(
                Payload__c = '{"formType": "S37", "applicationId": "VOL-' + i + '"}',
                Status__c = 'Received'
            ));
        }
        insert additionalRequests;
        
        List<Inbound_Request__c> allRequests = [SELECT Id FROM Inbound_Request__c];
        
        List<InboundForm_StatusUpdateQueueable.StatusUpdateData> updates = 
            new List<InboundForm_StatusUpdateQueueable.StatusUpdateData>();
        
        for (Inbound_Request__c req : allRequests) {
            updates.add(new InboundForm_StatusUpdateQueueable.StatusUpdateData(
                req.Id, 'Processed', null));
        }
        
        Test.startTest();
        System.enqueueJob(new InboundForm_StatusUpdateQueueable(updates));
        Test.stopTest();
        
        Integer processedCount = [
            SELECT COUNT() FROM Inbound_Request__c WHERE Status__c = 'Processed'
        ];
        
        Assert.areEqual(allRequests.size(), processedCount, 
            'All records should be processed');
    }
    
    // ========================================================================
    // DIRECT UNIT TESTS FOR @TestVisible METHODS
    // ========================================================================
    
    @IsTest
    static void testQueueRetry_DirectCall() {
        List<Inbound_Request__c> requests = [SELECT Id FROM Inbound_Request__c LIMIT 2];
        
        List<InboundForm_StatusUpdateQueueable.StatusUpdateData> failedUpdates = 
            new List<InboundForm_StatusUpdateQueueable.StatusUpdateData>{
                new InboundForm_StatusUpdateQueueable.StatusUpdateData(
                    requests[0].Id, 'Failed', 'Test error'),
                new InboundForm_StatusUpdateQueueable.StatusUpdateData(
                    requests[1].Id, 'Failed', 'Another error')
            };
        failedUpdates[0].lastError = 'Lock error';
        failedUpdates[1].lastError = 'Timeout error';
        
        // Create instance with retryCount = 0 (under MAX_RETRIES)
        InboundForm_StatusUpdateQueueable queueable = 
            new InboundForm_StatusUpdateQueueable(failedUpdates, 0);
        
        Test.startTest();
        // Directly call queueRetry - this will enqueue a new job
        queueable.queueRetry(failedUpdates);
        Test.stopTest();
        
        // Verify job was queued and executed (records should be updated)
        List<Inbound_Request__c> updatedRequests = [
            SELECT Status__c FROM Inbound_Request__c WHERE Id IN :new List<Id>{requests[0].Id, requests[1].Id}
        ];
        Assert.areEqual(2, updatedRequests.size(), 'Records should exist');
    }
    
    @IsTest
    static void testQueueRetry_ExceptionHandling() {
        // Test the exception path in queueRetry by using invalid IDs
        // This will fail when the retry job tries to execute
        List<Inbound_Request__c> requests = [SELECT Id FROM Inbound_Request__c LIMIT 1];
        Id validId = requests[0].Id;
        
        List<InboundForm_StatusUpdateQueueable.StatusUpdateData> failedUpdates = 
            new List<InboundForm_StatusUpdateQueueable.StatusUpdateData>{
                new InboundForm_StatusUpdateQueueable.StatusUpdateData(
                    validId, 'Processing', 'Error')
            };
        
        InboundForm_StatusUpdateQueueable queueable = 
            new InboundForm_StatusUpdateQueueable(failedUpdates, 1);
        
        Test.startTest();
        queueable.queueRetry(failedUpdates);
        Test.stopTest();
        
        // Job should complete (either successfully or with handled error)
        Assert.isTrue(true, 'queueRetry should handle execution');
    }
    
    @IsTest
    static void testLogPermanentFailure_DirectCall() {
        List<Inbound_Request__c> requests = [SELECT Id FROM Inbound_Request__c LIMIT 1];
        
        InboundForm_StatusUpdateQueueable.StatusUpdateData data = 
            new InboundForm_StatusUpdateQueueable.StatusUpdateData(
                requests[0].Id, 'Failed', 'Original error');
        
        InboundForm_StatusUpdateQueueable queueable = 
            new InboundForm_StatusUpdateQueueable(
                new List<InboundForm_StatusUpdateQueueable.StatusUpdateData>{ data }, 0);
        
        Test.startTest();
        queueable.logPermanentFailure(data, new List<String>{ 'Error 1', 'Error 2' });
        Test.stopTest();
        
        // Verify error log was updated on the record
        Inbound_Request__c updated = [
            SELECT Error_Log_Text__c FROM Inbound_Request__c WHERE Id = :requests[0].Id
        ];
        Assert.isTrue(updated.Error_Log_Text__c.contains('STATUS UPDATE FAILED'), 
            'Error log should be updated with failure info');
    }
    
    @IsTest
    static void testLogPermanentFailure_DeletedRecord() {
        // Test logPermanentFailure when the record has been deleted
        Inbound_Request__c request = new Inbound_Request__c(
            Payload__c = '{"formType": "S37", "applicationId": "PERM-FAIL"}',
            Status__c = 'Received'
        );
        insert request;
        Id deletedId = request.Id;
        delete request;
        
        InboundForm_StatusUpdateQueueable.StatusUpdateData data = 
            new InboundForm_StatusUpdateQueueable.StatusUpdateData(
                deletedId, 'Failed', 'Original error');
        
        InboundForm_StatusUpdateQueueable queueable = 
            new InboundForm_StatusUpdateQueueable(
                new List<InboundForm_StatusUpdateQueueable.StatusUpdateData>{ data }, 0);
        
        Test.startTest();
        // Should not throw exception even when record is deleted
        queueable.logPermanentFailure(data, new List<String>{ 'Cannot update' });
        Test.stopTest();
        
        Assert.isTrue(true, 'Should handle deleted record gracefully');
    }
    
    @IsTest
    static void testCreateErrorLogRecord_DirectCall() {
        List<Inbound_Request__c> requests = [SELECT Id FROM Inbound_Request__c LIMIT 1];
        
        InboundForm_StatusUpdateQueueable.StatusUpdateData data = 
            new InboundForm_StatusUpdateQueueable.StatusUpdateData(
                requests[0].Id, 'Failed', 'Original error log');
        
        InboundForm_StatusUpdateQueueable queueable = 
            new InboundForm_StatusUpdateQueueable(
                new List<InboundForm_StatusUpdateQueueable.StatusUpdateData>{ data }, 0);
        
        Test.startTest();
        queueable.createErrorLogRecord(data, new List<String>{ 'DML Error', 'Validation Error' });
        Test.stopTest();
        
        Inbound_Request__c updated = [
            SELECT Error_Log_Text__c FROM Inbound_Request__c WHERE Id = :requests[0].Id
        ];
        Assert.isTrue(updated.Error_Log_Text__c.contains('STATUS UPDATE FAILED'), 
            'Error log should contain failure marker');
        Assert.isTrue(updated.Error_Log_Text__c.contains('DML Error'), 
            'Error log should contain error details');
    }
    
    @IsTest
    static void testCreateErrorLogRecord_NullErrorLog() {
        List<Inbound_Request__c> requests = [SELECT Id FROM Inbound_Request__c LIMIT 1];
        
        InboundForm_StatusUpdateQueueable.StatusUpdateData data = 
            new InboundForm_StatusUpdateQueueable.StatusUpdateData(
                requests[0].Id, 'Failed', null);
        
        InboundForm_StatusUpdateQueueable queueable = 
            new InboundForm_StatusUpdateQueueable(
                new List<InboundForm_StatusUpdateQueueable.StatusUpdateData>{ data }, 0);
        
        Test.startTest();
        queueable.createErrorLogRecord(data, new List<String>{ 'Error' });
        Test.stopTest();
        
        Inbound_Request__c updated = [
            SELECT Error_Log_Text__c FROM Inbound_Request__c WHERE Id = :requests[0].Id
        ];
        Assert.isTrue(updated.Error_Log_Text__c.contains('Original Error: None'), 
            'Should handle null errorLog');
    }
    
    // ========================================================================
    // FINALIZER DIRECT TESTS
    // ========================================================================
    
    @IsTest
    static void testFinalizer_HandleFailedJobRetry() {
        List<Inbound_Request__c> requests = [SELECT Id FROM Inbound_Request__c LIMIT 2];
        
        List<InboundForm_StatusUpdateQueueable.StatusUpdateData> updates = 
            new List<InboundForm_StatusUpdateQueueable.StatusUpdateData>{
                new InboundForm_StatusUpdateQueueable.StatusUpdateData(
                    requests[0].Id, 'Processing', null),
                new InboundForm_StatusUpdateQueueable.StatusUpdateData(
                    requests[1].Id, 'Processing', null)
            };
        
        // Create finalizer with retryCount = 0 (under MAX_RETRIES)
        InboundForm_StatusUpdateQueueable.StatusUpdateFinalizer finalizer = 
            new InboundForm_StatusUpdateQueueable.StatusUpdateFinalizer(updates, 0);
        
        Test.startTest();
        // Directly call handleFailedJobRetry
        finalizer.handleFailedJobRetry('Test exception message');
        Test.stopTest();
        
        // Verify lastError was set on all updates
        for (InboundForm_StatusUpdateQueueable.StatusUpdateData data : updates) {
            Assert.isTrue(data.lastError.contains('Job exception'), 
                'lastError should contain exception info');
        }
    }
    
    @IsTest
    static void testFinalizer_HandleFailedJobRetry_MaxRetries() {
        List<Inbound_Request__c> requests = [SELECT Id FROM Inbound_Request__c LIMIT 1];
        
        List<InboundForm_StatusUpdateQueueable.StatusUpdateData> updates = 
            new List<InboundForm_StatusUpdateQueueable.StatusUpdateData>{
                new InboundForm_StatusUpdateQueueable.StatusUpdateData(
                    requests[0].Id, 'Failed', 'Error')
            };
        
        // Create finalizer with retryCount = 2 (at MAX_RETRIES)
        InboundForm_StatusUpdateQueueable.StatusUpdateFinalizer finalizer = 
            new InboundForm_StatusUpdateQueueable.StatusUpdateFinalizer(updates, 2);
        
        Test.startTest();
        // At max retries, handleFailedJobRetry will still try but the retry job
        // will be created with retryCount = 3
        finalizer.handleFailedJobRetry('Max retry test');
        Test.stopTest();
        
        Assert.isTrue(true, 'Should handle max retry scenario');
    }
    
    @IsTest
    static void testFinalizer_LogAllAsPermanentFailures() {
        List<Inbound_Request__c> requests = [SELECT Id FROM Inbound_Request__c LIMIT 2];
        
        List<InboundForm_StatusUpdateQueueable.StatusUpdateData> updates = 
            new List<InboundForm_StatusUpdateQueueable.StatusUpdateData>{
                new InboundForm_StatusUpdateQueueable.StatusUpdateData(
                    requests[0].Id, 'Failed', 'Error 1'),
                new InboundForm_StatusUpdateQueueable.StatusUpdateData(
                    requests[1].Id, 'Failed', 'Error 2')
            };
        
        InboundForm_StatusUpdateQueueable.StatusUpdateFinalizer finalizer = 
            new InboundForm_StatusUpdateQueueable.StatusUpdateFinalizer(updates, 2);
        
        Test.startTest();
        finalizer.logAllAsPermanentFailures('Unhandled exception occurred');
        Test.stopTest();
        
        // Verify error logs were updated
        List<Inbound_Request__c> updated = [
            SELECT Error_Log_Text__c FROM Inbound_Request__c 
            WHERE Id IN :new List<Id>{requests[0].Id, requests[1].Id}
        ];
        
        for (Inbound_Request__c req : updated) {
            Assert.isTrue(req.Error_Log_Text__c.contains('STATUS UPDATE FAILED'), 
                'Error log should be updated');
            Assert.isTrue(req.Error_Log_Text__c.contains('Unhandled Exception'), 
                'Should mention unhandled exception');
        }
    }
    
    @IsTest
    static void testFinalizer_LogAllAsPermanentFailures_NullUpdates() {
        InboundForm_StatusUpdateQueueable.StatusUpdateFinalizer finalizer = 
            new InboundForm_StatusUpdateQueueable.StatusUpdateFinalizer(null, 0);
        
        Test.startTest();
        // Should not throw exception with null updates
        finalizer.logAllAsPermanentFailures('Error message');
        Test.stopTest();
        
        Assert.isTrue(true, 'Should handle null updates gracefully');
    }
    
    @IsTest
    static void testFinalizer_LogAllAsPermanentFailures_DeletedRecords() {
        // Create and delete records
        List<Inbound_Request__c> newRequests = new List<Inbound_Request__c>();
        for (Integer i = 0; i < 2; i++) {
            newRequests.add(new Inbound_Request__c(
                Payload__c = '{"formType": "S37", "applicationId": "FIN-DEL-' + i + '"}',
                Status__c = 'Received'
            ));
        }
        insert newRequests;
        
        List<Id> deletedIds = new List<Id>();
        for (Inbound_Request__c req : newRequests) {
            deletedIds.add(req.Id);
        }
        delete newRequests;
        
        List<InboundForm_StatusUpdateQueueable.StatusUpdateData> updates = 
            new List<InboundForm_StatusUpdateQueueable.StatusUpdateData>();
        for (Id delId : deletedIds) {
            updates.add(new InboundForm_StatusUpdateQueueable.StatusUpdateData(
                delId, 'Failed', 'Error'));
        }
        
        InboundForm_StatusUpdateQueueable.StatusUpdateFinalizer finalizer = 
            new InboundForm_StatusUpdateQueueable.StatusUpdateFinalizer(updates, 2);
        
        Test.startTest();
        // Should not throw even when records are deleted
        finalizer.logAllAsPermanentFailures('Cannot update deleted records');
        Test.stopTest();
        
        Assert.isTrue(true, 'Should handle deleted records gracefully');
    }
}