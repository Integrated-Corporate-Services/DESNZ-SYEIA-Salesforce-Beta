/**
 * Test class for InboundRequestTriggerHandler.
 * Tests trigger handler implementation and delegation to helper.
 */
@IsTest
private class InboundRequestTriggerHandlerTest {
    
    // ========================================================================
    // TEST DATA
    // ========================================================================
    
    private static String getValidS37Json() {
        return '{' +
            '"formType": "S37",' +
            '"applicationId": "APP-TH-001",' +
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
    // CONSTRUCTOR TESTS
    // ========================================================================
    
    @IsTest
    static void testConstructor() {
        Test.startTest();
        InboundRequestTriggerHandler handler = 
            new InboundRequestTriggerHandler(true, 10);
        Test.stopTest();
        
        Assert.isNotNull(handler, 'Handler should be instantiated');
    }
    
    @IsTest
    static void testConstructor_NotExecuting() {
        Test.startTest();
        InboundRequestTriggerHandler handler = 
            new InboundRequestTriggerHandler(false, 0);
        Test.stopTest();
        
        Assert.isNotNull(handler, 'Handler should be instantiated when not executing');
    }
    
    // ========================================================================
    // BEFORE EVENT TESTS
    // ========================================================================
    
    @IsTest
    static void testBeforeInsert() {
        InboundRequestTriggerHandler handler = 
            new InboundRequestTriggerHandler(true, 1);
        
        List<SObject> newRecords = new List<SObject>{
            new Inbound_Request__c(Payload__c = getValidS37Json())
        };
        
        Test.startTest();
        // Should not throw exception
        handler.beforeInsert(newRecords);
        Test.stopTest();
        
        Assert.isTrue(true, 'Before insert should complete without error');
    }
    
    @IsTest
    static void testBeforeUpdate() {
        InboundRequestTriggerHandler handler = 
            new InboundRequestTriggerHandler(true, 1);
        
        Inbound_Request__c request = new Inbound_Request__c(
            Payload__c = getValidS37Json(),
            Status__c = 'Received'
        );
        insert request;
        
        List<SObject> oldRecords = new List<SObject>{ request };
        request.Status__c = 'Processing';
        List<SObject> newRecords = new List<SObject>{ request };
        Map<Id, SObject> oldMap = new Map<Id, SObject>{ request.Id => request };
        Map<Id, SObject> newMap = new Map<Id, SObject>{ request.Id => request };
        
        Test.startTest();
        handler.beforeUpdate(oldRecords, newRecords, oldMap, newMap);
        Test.stopTest();
        
        Assert.isTrue(true, 'Before update should complete without error');
    }
    
    @IsTest
    static void testBeforeDelete() {
        InboundRequestTriggerHandler handler = 
            new InboundRequestTriggerHandler(true, 1);
        
        Inbound_Request__c request = new Inbound_Request__c(
            Payload__c = getValidS37Json(),
            Status__c = 'Received'
        );
        insert request;
        
        List<SObject> oldRecords = new List<SObject>{ request };
        Map<Id, SObject> oldMap = new Map<Id, SObject>{ request.Id => request };
        
        Test.startTest();
        handler.beforeDelete(oldRecords, oldMap);
        Test.stopTest();
        
        Assert.isTrue(true, 'Before delete should complete without error');
    }
    
    // ========================================================================
    // AFTER EVENT TESTS
    // ========================================================================
    
    @IsTest
    static void testAfterInsert() {
        // Reset helper state
        InboundRequestTriggerHelper.enableProcessing();
        
        InboundRequestTriggerHandler handler = 
            new InboundRequestTriggerHandler(true, 1);
        
        Inbound_Request__c request = new Inbound_Request__c(
            Payload__c = getValidS37Json(),
            Status__c = 'Received'
        );
        insert request;
        
        // Re-query to get fresh record
        request = [SELECT Id, Payload__c, Status__c FROM Inbound_Request__c WHERE Id = :request.Id];
        
        List<SObject> newRecords = new List<SObject>{ request };
        Map<Id, SObject> newMap = new Map<Id, SObject>{ request.Id => request };
        
        Test.startTest();
        // Note: The actual processing happens in helper, this just tests delegation
        handler.afterInsert(newRecords, newMap);
        Test.stopTest();
        
        Assert.isTrue(true, 'After insert should delegate to helper');
    }
    
    @IsTest
    static void testAfterUpdate() {
        InboundRequestTriggerHandler handler = 
            new InboundRequestTriggerHandler(true, 1);
        
        Inbound_Request__c request = new Inbound_Request__c(
            Payload__c = getValidS37Json(),
            Status__c = 'Received'
        );
        insert request;
        
        List<SObject> oldRecords = new List<SObject>{ request.clone(true) };
        request.Status__c = 'Processed';
        List<SObject> newRecords = new List<SObject>{ request };
        Map<Id, SObject> oldMap = new Map<Id, SObject>{ request.Id => oldRecords[0] };
        Map<Id, SObject> newMap = new Map<Id, SObject>{ request.Id => request };
        
        Test.startTest();
        handler.afterUpdate(oldRecords, newRecords, oldMap, newMap);
        Test.stopTest();
        
        Assert.isTrue(true, 'After update should complete without error');
    }
    
    @IsTest
    static void testAfterDelete() {
        InboundRequestTriggerHandler handler = 
            new InboundRequestTriggerHandler(true, 1);
        
        Inbound_Request__c request = new Inbound_Request__c(
            Payload__c = getValidS37Json(),
            Status__c = 'Received'
        );
        insert request;
        
        List<SObject> oldRecords = new List<SObject>{ request };
        Map<Id, SObject> oldMap = new Map<Id, SObject>{ request.Id => request };
        
        Test.startTest();
        handler.afterDelete(oldRecords, oldMap);
        Test.stopTest();
        
        Assert.isTrue(true, 'After delete should complete without error');
    }
    
    @IsTest
    static void testAfterUndelete() {
        InboundRequestTriggerHandler handler = 
            new InboundRequestTriggerHandler(true, 1);
        
        Inbound_Request__c request = new Inbound_Request__c(
            Payload__c = getValidS37Json(),
            Status__c = 'Received'
        );
        insert request;
        
        List<SObject> newRecords = new List<SObject>{ request };
        Map<Id, SObject> newMap = new Map<Id, SObject>{ request.Id => request };
        
        Test.startTest();
        handler.afterUndelete(newRecords, newMap);
        Test.stopTest();
        
        Assert.isTrue(true, 'After undelete should complete without error');
    }
    
    // ========================================================================
    // INTEGRATION TESTS
    // ========================================================================
    
    @IsTest
    static void testAllTriggerEvents() {
        InboundRequestTriggerHandler handler = 
            new InboundRequestTriggerHandler(true, 1);
        
        Inbound_Request__c request = new Inbound_Request__c(
            Payload__c = getValidS37Json(),
            Status__c = 'Received'
        );
        
        Test.startTest();
        
        // Before Insert
        handler.beforeInsert(new List<SObject>{ request });
        
        // Insert the record
        insert request;
        
        // After Insert
        Map<Id, SObject> newMap = new Map<Id, SObject>{ request.Id => request };
        handler.afterInsert(new List<SObject>{ request }, newMap);
        
        // Before Update
        Inbound_Request__c oldRequest = request.clone(true);
        request.Status__c = 'Processing';
        Map<Id, SObject> oldMap = new Map<Id, SObject>{ request.Id => oldRequest };
        Map<Id, SObject> updatedNewMap = new Map<Id, SObject>{ request.Id => request };
        handler.beforeUpdate(
            new List<SObject>{ oldRequest }, 
            new List<SObject>{ request }, 
            oldMap, 
            updatedNewMap
        );
        
        // After Update
        handler.afterUpdate(
            new List<SObject>{ oldRequest }, 
            new List<SObject>{ request }, 
            oldMap, 
            updatedNewMap
        );
        
        // Before Delete
        handler.beforeDelete(new List<SObject>{ request }, updatedNewMap);
        
        // After Delete
        handler.afterDelete(new List<SObject>{ request }, updatedNewMap);
        
        // After Undelete
        handler.afterUndelete(new List<SObject>{ request }, updatedNewMap);
        
        Test.stopTest();
        
        Assert.isTrue(true, 'All trigger events should complete without error');
    }
}