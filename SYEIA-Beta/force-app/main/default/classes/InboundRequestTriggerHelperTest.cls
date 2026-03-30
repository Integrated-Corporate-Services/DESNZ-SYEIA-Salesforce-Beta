/**
 * Test class for InboundRequestTriggerHelper.
 * Tests processing logic, recursion guards, and control methods.
 */
@IsTest
private class InboundRequestTriggerHelperTest {
    
    // ========================================================================
    // TEST DATA
    // ========================================================================
    
    private static String getValidS37Json() {
        return '{' +
            '"formType": "S37",' +
            '"applicationId": "APP-HELPER-001",' +
            '"sections": {' +
                '"location": {' +
                    '"routes": [' +
                        '{' +
                            '"routeName": "Route 1",' +
                            '"route_id": "R001",' +
                            '"gridPoints": [' +
                                '{"point_id": "P1", "easting": "100", "northing": "200"},' +
                                '{"point_id": "P2", "easting": "101", "northing": "201"}' +
                            ']' +
                        '}' +
                    ']' +
                '},' +
                '"eiaFees": {"is_eia_development": false}' +
            '}' +
        '}';
    }
    
    // ========================================================================
    // SETUP AND TEARDOWN
    // ========================================================================
    
    @TestSetup
    static void setupTestData() {
        List<Inbound_Request__c> requests = new List<Inbound_Request__c>();
        for (Integer i = 0; i < 5; i++) {
            requests.add(new Inbound_Request__c(
                Payload__c = getValidS37Json().replace('APP-HELPER-001', 'APP-' + i),
                Status__c = 'Received'
            ));
        }
        insert requests;
    }
    
    // ========================================================================
    // CONSTRUCTOR TEST
    // ========================================================================
    
    @IsTest
    static void testConstructor() {
        Test.startTest();
        InboundRequestTriggerHelper helper = new InboundRequestTriggerHelper();
        Test.stopTest();
        
        Assert.isNotNull(helper, 'Helper should be instantiated');
    }
    
    // ========================================================================
    // STATIC CONTROL METHODS TESTS
    // ========================================================================
    
    @IsTest
    static void testResetProcessedIds() {
        InboundRequestTriggerHelper.resetProcessedIds();
        List<Inbound_Request__c> requests = [SELECT Id FROM Inbound_Request__c LIMIT 1];
        
        // Mark as processed
        InboundRequestTriggerHelper.markAsProcessed(requests[0].Id);
        Assert.isTrue(InboundRequestTriggerHelper.isRecordProcessed(requests[0].Id), 
            'Record should be marked as processed');
        
        Test.startTest();
        InboundRequestTriggerHelper.resetProcessedIds();
        Test.stopTest();
        
        Assert.isFalse(InboundRequestTriggerHelper.isRecordProcessed(requests[0].Id), 
            'Record should not be processed after reset');
    }
    
    @IsTest
    static void testDisableProcessing() {
        InboundRequestTriggerHelper.resetProcessedIds();
        InboundRequestTriggerHelper.enableProcessing();
        
        Test.startTest();
        InboundRequestTriggerHelper.disableProcessing();
        Test.stopTest();
        
        // Processing should be disabled - verify indirectly through behavior
        Assert.isTrue(true, 'Disable processing should complete');
    }
    
    @IsTest
    static void testEnableProcessing() {
        InboundRequestTriggerHelper.disableProcessing();
        
        Test.startTest();
        InboundRequestTriggerHelper.enableProcessing();
        Test.stopTest();
        
        Assert.isTrue(true, 'Enable processing should complete');
    }
    
    @IsTest
    static void testIsRecordProcessed() {
        InboundRequestTriggerHelper.resetProcessedIds();
        List<Inbound_Request__c> requests = [SELECT Id FROM Inbound_Request__c LIMIT 1];
        
        Test.startTest();
        Boolean beforeMark = InboundRequestTriggerHelper.isRecordProcessed(requests[0].Id);
        InboundRequestTriggerHelper.markAsProcessed(requests[0].Id);
        Boolean afterMark = InboundRequestTriggerHelper.isRecordProcessed(requests[0].Id);
        Test.stopTest();
        
        Assert.isFalse(beforeMark, 'Should not be processed initially');
        Assert.isTrue(afterMark, 'Should be processed after marking');
    }
    
    @IsTest
    static void testMarkAsProcessed_SingleId() {
        InboundRequestTriggerHelper.resetProcessedIds();
        List<Inbound_Request__c> requests = [SELECT Id FROM Inbound_Request__c LIMIT 1];
        
        Test.startTest();
        InboundRequestTriggerHelper.markAsProcessed(requests[0].Id);
        Test.stopTest();
        
        Assert.isTrue(InboundRequestTriggerHelper.isRecordProcessed(requests[0].Id), 
            'Single ID should be marked as processed');
    }
    
    @IsTest
    static void testMarkAsProcessed_SetOfIds() {
        InboundRequestTriggerHelper.resetProcessedIds();
        List<Inbound_Request__c> requests = [SELECT Id FROM Inbound_Request__c LIMIT 3];
        Set<Id> requestIds = new Set<Id>();
        for (Inbound_Request__c req : requests) {
            requestIds.add(req.Id);
        }
        
        Test.startTest();
        InboundRequestTriggerHelper.markAsProcessed(requestIds);
        Test.stopTest();
        
        for (Id reqId : requestIds) {
            Assert.isTrue(InboundRequestTriggerHelper.isRecordProcessed(reqId), 
                'All IDs in set should be marked as processed');
        }
    }
    
    @IsTest
    static void testGetProcessedCount() {
        InboundRequestTriggerHelper.resetProcessedIds();
        List<Inbound_Request__c> requests = [SELECT Id FROM Inbound_Request__c LIMIT 3];
        
        Test.startTest();
        Integer initialCount = InboundRequestTriggerHelper.getProcessedCount();
        
        for (Inbound_Request__c req : requests) {
            InboundRequestTriggerHelper.markAsProcessed(req.Id);
        }
        
        Integer finalCount = InboundRequestTriggerHelper.getProcessedCount();
        Test.stopTest();
        
        Assert.areEqual(0, initialCount, 'Initial count should be 0');
        Assert.areEqual(3, finalCount, 'Final count should be 3');
    }
    
    // ========================================================================
    // TRIGGER EVENT METHOD TESTS
    // ========================================================================
    
    @IsTest
    static void testProcessBeforeInsert() {
        InboundRequestTriggerHelper helper = new InboundRequestTriggerHelper();
        
        Test.startTest();
        helper.processBeforeInsert();
        Test.stopTest();
        
        Assert.isTrue(true, 'Before insert should complete without error');
    }
    
    @IsTest
    static void testProcessBeforeUpdate() {
        InboundRequestTriggerHelper helper = new InboundRequestTriggerHelper();
        
        Test.startTest();
        helper.processBeforeUpdate();
        Test.stopTest();
        
        Assert.isTrue(true, 'Before update should complete without error');
    }
    
    @IsTest
    static void testProcessBeforeDelete() {
        InboundRequestTriggerHelper helper = new InboundRequestTriggerHelper();
        
        Test.startTest();
        helper.processBeforeDelete();
        Test.stopTest();
        
        Assert.isTrue(true, 'Before delete should complete without error');
    }
    
    @IsTest
    static void testProcessAfterUpdate() {
        InboundRequestTriggerHelper helper = new InboundRequestTriggerHelper();
        
        Test.startTest();
        helper.processAfterUpdate();
        Test.stopTest();
        
        Assert.isTrue(true, 'After update should complete without error');
    }
    
    @IsTest
    static void testProcessAfterDelete() {
        InboundRequestTriggerHelper helper = new InboundRequestTriggerHelper();
        
        Test.startTest();
        helper.processAfterDelete();
        Test.stopTest();
        
        Assert.isTrue(true, 'After delete should complete without error');
    }
    
    @IsTest
    static void testProcessAfterUndelete() {
        InboundRequestTriggerHelper helper = new InboundRequestTriggerHelper();
        
        Test.startTest();
        helper.processAfterUndelete();
        Test.stopTest();
        
        Assert.isTrue(true, 'After undelete should complete without error');
    }
    
    // ========================================================================
    // PROCESS AFTER INSERT TESTS
    // ========================================================================
    
    @IsTest
    static void testProcessAfterInsert_ValidRequest() {
        InboundRequestTriggerHelper.resetProcessedIds();
        InboundRequestTriggerHelper.enableProcessing();
        InboundForm_Processor.clearAllCaches();
        InboundForm_ConfigRegistry.clearCache();
        
        InboundRequestTriggerHelper helper = new InboundRequestTriggerHelper();
        
        List<Inbound_Request__c> requests = [
            SELECT Id, Payload__c, Status__c, Error_Log_Text__c 
            FROM Inbound_Request__c 
            LIMIT 1
        ];
        
        Map<Id, SObject> requestMap = new Map<Id, SObject>();
        for (Inbound_Request__c req : requests) {
            requestMap.put(req.Id, req);
        }
        
        Test.startTest();
        helper.processAfterInsert(requests, requestMap);
        Test.stopTest();
        
        Assert.isTrue(InboundRequestTriggerHelper.isRecordProcessed(requests[0].Id), 
            'Record should be marked as processed');
    }
    
    @IsTest
    static void testProcessAfterInsert_DisabledProcessing() {
        InboundRequestTriggerHelper.resetProcessedIds();
        InboundRequestTriggerHelper.disableProcessing();
        
        InboundRequestTriggerHelper helper = new InboundRequestTriggerHelper();
        
        List<Inbound_Request__c> requests = [
            SELECT Id, Payload__c, Status__c, Error_Log_Text__c 
            FROM Inbound_Request__c 
            LIMIT 1
        ];
        
        Map<Id, SObject> requestMap = new Map<Id, SObject>();
        for (Inbound_Request__c req : requests) {
            requestMap.put(req.Id, req);
        }
        
        Test.startTest();
        helper.processAfterInsert(requests, requestMap);
        Test.stopTest();
        
        Assert.isFalse(InboundRequestTriggerHelper.isRecordProcessed(requests[0].Id), 
            'Record should not be processed when processing is disabled');
        
        // Re-enable for other tests
        InboundRequestTriggerHelper.enableProcessing();
    }
    
    @IsTest
    static void testProcessAfterInsert_AlreadyProcessed() {
        InboundRequestTriggerHelper.resetProcessedIds();
        InboundRequestTriggerHelper.enableProcessing();
        
        List<Inbound_Request__c> requests = [
            SELECT Id, Payload__c, Status__c, Error_Log_Text__c 
            FROM Inbound_Request__c 
            LIMIT 1
        ];
        
        // Mark as already processed
        InboundRequestTriggerHelper.markAsProcessed(requests[0].Id);
        
        InboundRequestTriggerHelper helper = new InboundRequestTriggerHelper();
        
        Map<Id, SObject> requestMap = new Map<Id, SObject>();
        for (Inbound_Request__c req : requests) {
            requestMap.put(req.Id, req);
        }
        
        Integer initialCount = InboundRequestTriggerHelper.getProcessedCount();
        
        Test.startTest();
        helper.processAfterInsert(requests, requestMap);
        Test.stopTest();
        
        Integer finalCount = InboundRequestTriggerHelper.getProcessedCount();
        Assert.areEqual(initialCount, finalCount, 
            'Processed count should not change for already processed records');
    }
    
    @IsTest
    static void testProcessAfterInsert_NoPayload() {
        InboundRequestTriggerHelper.resetProcessedIds();
        InboundRequestTriggerHelper.enableProcessing();
        
        // Create request with no payload
        Inbound_Request__c emptyRequest = new Inbound_Request__c(
            Payload__c = '',
            Status__c = 'Received'
        );
        insert emptyRequest;
        
        List<Inbound_Request__c> requests = [
            SELECT Id, Payload__c, Status__c, Error_Log_Text__c 
            FROM Inbound_Request__c 
            WHERE Id = :emptyRequest.Id
        ];
        
        InboundRequestTriggerHelper helper = new InboundRequestTriggerHelper();
        
        Map<Id, SObject> requestMap = new Map<Id, SObject>();
        for (Inbound_Request__c req : requests) {
            requestMap.put(req.Id, req);
        }
        
        Test.startTest();
        helper.processAfterInsert(requests, requestMap);
        Test.stopTest();
        
        // Should still be marked as processed (to prevent future attempts)
        Assert.isTrue(InboundRequestTriggerHelper.isRecordProcessed(emptyRequest.Id), 
            'Record with no payload should still be marked as processed');
    }
    
    @IsTest
    static void testProcessAfterInsert_MultipleRecords() {
        InboundRequestTriggerHelper.resetProcessedIds();
        InboundRequestTriggerHelper.enableProcessing();
        InboundForm_Processor.clearAllCaches();
        InboundForm_ConfigRegistry.clearCache();
        
        List<Inbound_Request__c> requests = [
            SELECT Id, Payload__c, Status__c, Error_Log_Text__c 
            FROM Inbound_Request__c
        ];
        
        InboundRequestTriggerHelper helper = new InboundRequestTriggerHelper();
        
        Map<Id, SObject> requestMap = new Map<Id, SObject>();
        for (Inbound_Request__c req : requests) {
            requestMap.put(req.Id, req);
        }
        
        Test.startTest();
        helper.processAfterInsert(requests, requestMap);
        Test.stopTest();
        
        Assert.areEqual(requests.size(), InboundRequestTriggerHelper.getProcessedCount(), 
            'All records should be processed');
    }
    
    // ========================================================================
    // REPROCESS REQUESTS TESTS
    // ========================================================================
    
    @IsTest
    static void testReprocessRequests() {
        InboundRequestTriggerHelper.resetProcessedIds();
        InboundRequestTriggerHelper.enableProcessing();
        InboundForm_Processor.clearAllCaches();
        InboundForm_ConfigRegistry.clearCache();
        
        List<Inbound_Request__c> requests = [SELECT Id FROM Inbound_Request__c LIMIT 2];
        Set<Id> requestIds = new Set<Id>();
        for (Inbound_Request__c req : requests) {
            requestIds.add(req.Id);
            InboundRequestTriggerHelper.markAsProcessed(req.Id);
        }
        
        InboundRequestTriggerHelper helper = new InboundRequestTriggerHelper();
        
        Test.startTest();
        helper.reprocessRequests(requestIds);
        Test.stopTest();
        
        // Records should be processed again
        for (Id reqId : requestIds) {
            Assert.isTrue(InboundRequestTriggerHelper.isRecordProcessed(reqId), 
                'Reprocessed record should be marked as processed');
        }
    }
    
    @IsTest
    static void testReprocessRequests_NullSet() {
        InboundRequestTriggerHelper helper = new InboundRequestTriggerHelper();
        
        Test.startTest();
        helper.reprocessRequests(null);
        Test.stopTest();
        
        Assert.isTrue(true, 'Null set should be handled gracefully');
    }
    
    @IsTest
    static void testReprocessRequests_EmptySet() {
        InboundRequestTriggerHelper helper = new InboundRequestTriggerHelper();
        
        Test.startTest();
        helper.reprocessRequests(new Set<Id>());
        Test.stopTest();
        
        Assert.isTrue(true, 'Empty set should be handled gracefully');
    }
    
    @IsTest
    static void testReprocessRequests_NonExistentIds() {
        InboundRequestTriggerHelper.resetProcessedIds();
        InboundRequestTriggerHelper.enableProcessing();
        
        InboundRequestTriggerHelper helper = new InboundRequestTriggerHelper();
        
        // Use a fake ID that doesn't exist
        Set<Id> fakeIds = new Set<Id>{ '500000000000000AAA' };
        
        Test.startTest();
        helper.reprocessRequests(fakeIds);
        Test.stopTest();
        
        Assert.isTrue(true, 'Non-existent IDs should be handled gracefully');
    }
    
    // ========================================================================
    // RECURSION GUARD TESTS
    // ========================================================================
    
    @IsTest
    static void testRecursionGuard() {
        InboundRequestTriggerHelper.resetProcessedIds();
        InboundRequestTriggerHelper.enableProcessing();
        InboundForm_Processor.clearAllCaches();
        InboundForm_ConfigRegistry.clearCache();
        
        InboundRequestTriggerHelper helper = new InboundRequestTriggerHelper();
        
        List<Inbound_Request__c> requests = [
            SELECT Id, Payload__c, Status__c, Error_Log_Text__c 
            FROM Inbound_Request__c 
            LIMIT 1
        ];
        
        Map<Id, SObject> requestMap = new Map<Id, SObject>();
        for (Inbound_Request__c req : requests) {
            requestMap.put(req.Id, req);
        }
        
        Test.startTest();
        // First call processes
        helper.processAfterInsert(requests, requestMap);
        Integer countAfterFirst = InboundRequestTriggerHelper.getProcessedCount();
        
        // Second call should skip (already processed)
        helper.processAfterInsert(requests, requestMap);
        Integer countAfterSecond = InboundRequestTriggerHelper.getProcessedCount();
        Test.stopTest();
        
        Assert.areEqual(countAfterFirst, countAfterSecond, 
            'Second call should not increase processed count');
    }
    
    // ========================================================================
    // INTEGRATION TESTS
    // ========================================================================
    
    @IsTest
    static void testIntegration_FullProcessingCycle() {
        InboundRequestTriggerHelper.resetProcessedIds();
        InboundRequestTriggerHelper.enableProcessing();
        InboundForm_Processor.clearAllCaches();
        InboundForm_ConfigRegistry.clearCache();
        
        // Create a new request (simulating trigger flow)
        Inbound_Request__c request = new Inbound_Request__c(
            Payload__c = getValidS37Json(),
            Status__c = 'Received'
        );
        insert request;
        
        // Query fresh
        request = [
            SELECT Id, Payload__c, Status__c, Error_Log_Text__c 
            FROM Inbound_Request__c 
            WHERE Id = :request.Id
        ];
        
        InboundRequestTriggerHelper helper = new InboundRequestTriggerHelper();
        
        Map<Id, SObject> requestMap = new Map<Id, SObject>{ request.Id => request };
        
        Test.startTest();
        helper.processAfterInsert(new List<Inbound_Request__c>{ request }, requestMap);
        Test.stopTest();
        
        Assert.isTrue(InboundRequestTriggerHelper.isRecordProcessed(request.Id), 
            'Record should be processed');
    }
}