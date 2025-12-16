/**
 * Test class for InboundForm_Processor.
 * Tests core processing logic, record creation, error handling, warnings, and partial success.
 */
@IsTest
private class InboundForm_ProcessorTest {
    
    // ========================================================================
    // TEST DATA HELPERS
    // ========================================================================
    
    private static String getValidS37Json() {
        return '{' +
            '"formType": "S37",' +
            '"applicationId": "APP-TEST-001",' +
            '"sections": {' +
                '"worksOverview": {' +
                    '"polesAdded": 5,' +
                    '"polesReplaced": 2,' +
                    '"poleMaterial": "Wood",' +
                    '"excavationRequired": true,' +
                    '"excavationDetails": "Digging for foundations",' +
                    '"generalComments": "Test comments"' +
                '},' +
                '"location": {' +
                    '"routes": [' +
                        '{' +
                            '"routeName": "Main Route",' +
                            '"route_id": "R001",' +
                            '"gridPoints": [' +
                                '{"point_id": "P1", "easting": "123456", "northing": "654321"},' +
                                '{"point_id": "P2", "easting": "123457", "northing": "654322"}' +
                            ']' +
                        '}' +
                    ']' +
                '},' +
                '"eiaFees": {' +
                    '"is_eia_development": false' +
                '},' +
                '"projectDetails": {' +
                    '"overview": {' +
                        '"project_details": {' +
                            '"project_name": "Test Project",' +
                            '"project_description": "Test Description"' +
                        '}' +
                    '}' +
                '},' +
                '"networkOperator": {' +
                    '"details": {' +
                        '"operator_ref": "OP-REF-001",' +
                        '"submitted_at": "2024-03-15"' +
                    '}' +
                '},' +
                '"application_party": [],' +
                '"sensitiveAreaChecks": {' +
                    '"layers": ["SSSI", "AONB", "National Park"]' +
                '},' +
                '"assetInformation": [' +
                    '{' +
                        '"asset_type": "LV",' +
                        '"tori_noi": "TORI123",' +
                        '"asset_reference": "REF001",' +
                        '"description": "Low voltage line"' +
                    '}' +
                ']' +
            '}' +
        '}';
    }
    
    private static String getMinimalValidS37Json() {
        return '{' +
            '"formType": "S37",' +
            '"applicationId": "APP-MIN-001",' +
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
    
    private static String getJsonWithApplicationRelations(String relatedAppId) {
        return '{' +
            '"formType": "S37",' +
            '"applicationId": "APP-REL-001",' +
            '"sections": {' +
                '"location": {' +
                    '"routes": [' +
                        '{"routeName": "Route 1", "route_id": "R001", ' +
                        '"gridPoints": [{"point_id": "P1", "easting": "100", "northing": "200"},' +
                        '{"point_id": "P2", "easting": "101", "northing": "201"}]}' +
                    ']' +
                '},' +
                '"eiaFees": {"is_eia_development": false},' +
                '"projectDetails": {' +
                    '"overview": {' +
                        '"application_relations": [' +
                            '{"related_application_id": "' + relatedAppId + '", "relation_type": "ASSOCIATED"}' +
                        ']' +
                    '}' +
                '}' +
            '}' +
        '}';
    }
    
    private static String getJsonWithPartyData() {
        return '{' +
            '"formType": "S37",' +
            '"applicationId": "APP-PARTY-001",' +
            '"sections": {' +
                '"location": {' +
                    '"routes": [' +
                        '{"routeName": "Route 1", "route_id": "R001", ' +
                        '"gridPoints": [{"point_id": "P1", "easting": "100", "northing": "200"},' +
                        '{"point_id": "P2", "easting": "101", "northing": "201"}]}' +
                    ']' +
                '},' +
                '"eiaFees": {"is_eia_development": false},' +
                '"application_party": [' +
                    '{"organisation_name": "Test DNO", "is_primary": true, "application_party_id": "P001"}' +
                ']' +
            '}' +
        '}';
    }
    
    // ========================================================================
    // TEST SETUP
    // ========================================================================
    
    @TestSetup
    static void setupTestData() {
        List<Inbound_Request__c> requests = new List<Inbound_Request__c>{
            new Inbound_Request__c(
                Payload__c = getValidS37Json(),
                Status__c = 'Received'
            ),
            new Inbound_Request__c(
                Payload__c = getMinimalValidS37Json(),
                Status__c = 'Received'
            )
        };
        insert requests;
    }
    
    // ========================================================================
    // PROCESS REQUESTS TESTS
    // ========================================================================
    
    @IsTest
    static void testProcessRequests_ValidPayload() {
        InboundForm_Processor.clearAllCaches();
        InboundForm_ConfigRegistry.clearCache();
        
        List<Inbound_Request__c> requests = [
            SELECT Id, Payload__c, Status__c 
            FROM Inbound_Request__c 
            LIMIT 1
        ];
        
        Test.startTest();
        Map<Id, InboundForm_Processor.ProcessingResult> results = 
            InboundForm_Processor.processRequests(requests);
        Test.stopTest();
        
        Assert.isNotNull(results, 'Results should not be null');
        Assert.areEqual(1, results.size(), 'Should have one result');
        
        InboundForm_Processor.ProcessingResult result = results.get(requests[0].Id);
        Assert.isNotNull(result, 'Result should exist for request');
        Assert.areEqual('S37', result.formType, 'Form type should be S37');
    }
    
    @IsTest
    static void testProcessRequests_EmptyPayload() {
        InboundForm_Processor.clearAllCaches();
        
        Inbound_Request__c emptyRequest = new Inbound_Request__c(
            Payload__c = '',
            Status__c = 'Received'
        );
        insert emptyRequest;
        
        List<Inbound_Request__c> requests = new List<Inbound_Request__c>{
            [SELECT Id, Payload__c FROM Inbound_Request__c WHERE Id = :emptyRequest.Id]
        };
        
        Test.startTest();
        Map<Id, InboundForm_Processor.ProcessingResult> results = 
            InboundForm_Processor.processRequests(requests);
        Test.stopTest();
        
        InboundForm_Processor.ProcessingResult result = results.get(emptyRequest.Id);
        Assert.isFalse(result.success, 'Should fail for empty payload');
        Assert.isTrue(result.errors[0].contains('Payload is empty'), 
            'Error should mention empty payload');
    }
    
    @IsTest
    static void testProcessRequests_MissingFormType() {
        InboundForm_Processor.clearAllCaches();
        
        Inbound_Request__c request = new Inbound_Request__c(
            Payload__c = '{"applicationId": "APP-001"}',
            Status__c = 'Received'
        );
        insert request;
        
        List<Inbound_Request__c> requests = new List<Inbound_Request__c>{
            [SELECT Id, Payload__c FROM Inbound_Request__c WHERE Id = :request.Id]
        };
        
        Test.startTest();
        Map<Id, InboundForm_Processor.ProcessingResult> results = 
            InboundForm_Processor.processRequests(requests);
        Test.stopTest();
        
        InboundForm_Processor.ProcessingResult result = results.get(request.Id);
        Assert.isFalse(result.success, 'Should fail for missing form type');
        Assert.isTrue(result.errors[0].contains('formType not found'), 
            'Error should mention missing form type');
    }
    
    @IsTest
    static void testProcessRequests_InvalidFormType() {
        InboundForm_Processor.clearAllCaches();
        
        Inbound_Request__c request = new Inbound_Request__c(
            Payload__c = '{"formType": "INVALID", "applicationId": "APP-001"}',
            Status__c = 'Received'
        );
        insert request;
        
        List<Inbound_Request__c> requests = new List<Inbound_Request__c>{
            [SELECT Id, Payload__c FROM Inbound_Request__c WHERE Id = :request.Id]
        };
        
        Test.startTest();
        Map<Id, InboundForm_Processor.ProcessingResult> results = 
            InboundForm_Processor.processRequests(requests);
        Test.stopTest();
        
        InboundForm_Processor.ProcessingResult result = results.get(request.Id);
        Assert.isFalse(result.success, 'Should fail for invalid form type');
        Assert.isTrue(result.errors[0].contains('No configuration found'), 
            'Error should mention no config found');
    }
    
    @IsTest
    static void testProcessRequests_ValidationFailure() {
        InboundForm_Processor.clearAllCaches();
        InboundForm_ConfigRegistry.clearCache();
        
        // JSON with no routes - should fail S37 validation
        String invalidJson = '{' +
            '"formType": "S37",' +
            '"applicationId": "APP-001",' +
            '"sections": {' +
                '"location": {"routes": []},' +
                '"eiaFees": {"is_eia_development": false}' +
            '}' +
        '}';
        
        Inbound_Request__c request = new Inbound_Request__c(
            Payload__c = invalidJson,
            Status__c = 'Received'
        );
        insert request;
        
        List<Inbound_Request__c> requests = new List<Inbound_Request__c>{
            [SELECT Id, Payload__c FROM Inbound_Request__c WHERE Id = :request.Id]
        };
        
        Test.startTest();
        Map<Id, InboundForm_Processor.ProcessingResult> results = 
            InboundForm_Processor.processRequests(requests);
        Test.stopTest();
        
        InboundForm_Processor.ProcessingResult result = results.get(request.Id);
        Assert.isFalse(result.success, 'Should fail validation');
    }
    
    @IsTest
    static void testProcessRequests_MultipleRequests() {
        InboundForm_Processor.clearAllCaches();
        InboundForm_ConfigRegistry.clearCache();
        
        List<Inbound_Request__c> requests = [
            SELECT Id, Payload__c, Status__c 
            FROM Inbound_Request__c 
        ];
        
        Test.startTest();
        Map<Id, InboundForm_Processor.ProcessingResult> results = 
            InboundForm_Processor.processRequests(requests);
        Test.stopTest();
        
        Assert.areEqual(requests.size(), results.size(), 
            'Should have result for each request');
    }
    
    // ========================================================================
    // PROCESSING RESULT TESTS
    // ========================================================================
    
    @IsTest
    static void testProcessingResult_Constructor() {
        Id fakeId = '500000000000000AAA';
        
        Test.startTest();
        InboundForm_Processor.ProcessingResult result = 
            new InboundForm_Processor.ProcessingResult(fakeId);
        Test.stopTest();
        
        Assert.areEqual(fakeId, result.inboundRequestId, 'ID should match');
        Assert.isTrue(result.success, 'Success should default to true');
        Assert.isNotNull(result.errors, 'Errors should be initialized');
        Assert.isTrue(result.errors.isEmpty(), 'Errors should be empty');
        Assert.isNotNull(result.warnings, 'Warnings should be initialized');
        Assert.isTrue(result.warnings.isEmpty(), 'Warnings should be empty');
        Assert.isNotNull(result.createdRecords, 'Created records should be initialized');
        Assert.isNotNull(result.collectionRecords, 'Collection records should be initialized');
        Assert.isNotNull(result.postPrimaryRecords, 'Post primary records should be initialized');
    }
    
    @IsTest
    static void testProcessingResult_AddError() {
        Id fakeId = '500000000000000AAA';
        InboundForm_Processor.ProcessingResult result = 
            new InboundForm_Processor.ProcessingResult(fakeId);
        
        Test.startTest();
        result.addError('Test error message');
        Test.stopTest();
        
        Assert.isFalse(result.success, 'Success should be false after error');
        Assert.areEqual(1, result.errors.size(), 'Should have one error');
        Assert.areEqual('Test error message', result.errors[0], 'Error message should match');
    }
    
    @IsTest
    static void testProcessingResult_AddWarning() {
        Id fakeId = '500000000000000AAA';
        InboundForm_Processor.ProcessingResult result = 
            new InboundForm_Processor.ProcessingResult(fakeId);
        
        Test.startTest();
        result.addWarning('Test warning message');
        Test.stopTest();
        
        Assert.isTrue(result.success, 'Success should still be true after warning');
        Assert.areEqual(1, result.warnings.size(), 'Should have one warning');
        Assert.areEqual('Test warning message', result.warnings[0], 'Warning message should match');
        Assert.isTrue(result.hasWarnings(), 'hasWarnings should return true');
    }
    
    @IsTest
    static void testProcessingResult_HasWarnings() {
        Id fakeId = '500000000000000AAA';
        InboundForm_Processor.ProcessingResult result = 
            new InboundForm_Processor.ProcessingResult(fakeId);
        
        Assert.isFalse(result.hasWarnings(), 'Should have no warnings initially');
        
        result.addWarning('Warning 1');
        Assert.isTrue(result.hasWarnings(), 'Should have warnings after adding one');
        
        result.addWarning('Warning 2');
        Assert.areEqual(2, result.warnings.size(), 'Should accumulate warnings');
    }
    
    @IsTest
    static void testProcessingResult_AddRecords() {
        Id fakeId = '500000000000000AAA';
        InboundForm_Processor.ProcessingResult result = 
            new InboundForm_Processor.ProcessingResult(fakeId);
        
        List<SObject> records = new List<SObject>{
            new Account(Name = 'Test 1'),
            new Account(Name = 'Test 2')
        };
        
        Test.startTest();
        result.addRecords('Account', records);
        Test.stopTest();
        
        Assert.isTrue(result.createdRecords.containsKey('Account'), 
            'Should have Account key');
        Assert.areEqual(2, result.createdRecords.get('Account').size(), 
            'Should have 2 records');
    }
    
    @IsTest
    static void testProcessingResult_AddRecords_Multiple() {
        Id fakeId = '500000000000000AAA';
        InboundForm_Processor.ProcessingResult result = 
            new InboundForm_Processor.ProcessingResult(fakeId);
        
        result.addRecords('Account', new List<SObject>{ new Account(Name = 'Test 1') });
        
        Test.startTest();
        result.addRecords('Account', new List<SObject>{ new Account(Name = 'Test 2') });
        Test.stopTest();
        
        Assert.areEqual(2, result.createdRecords.get('Account').size(), 
            'Should accumulate records');
    }
    
    @IsTest
    static void testProcessingResult_AddPostPrimaryRecords() {
        Id fakeId = '500000000000000AAA';
        InboundForm_Processor.ProcessingResult result = 
            new InboundForm_Processor.ProcessingResult(fakeId);
        
        List<SObject> records = new List<SObject>{
            new Related_Case__c()
        };
        
        Test.startTest();
        result.addPostPrimaryRecords('Related_Case__c', records);
        Test.stopTest();
        
        Assert.isTrue(result.postPrimaryRecords.containsKey('Related_Case__c'), 
            'Should have Related_Case__c key');
        Assert.areEqual(1, result.postPrimaryRecords.get('Related_Case__c').size(), 
            'Should have 1 record');
    }
    
    @IsTest
    static void testProcessingResult_AddPostPrimaryRecords_Multiple() {
        Id fakeId = '500000000000000AAA';
        InboundForm_Processor.ProcessingResult result = 
            new InboundForm_Processor.ProcessingResult(fakeId);
        
        result.addPostPrimaryRecords('Related_Case__c', new List<SObject>{ new Related_Case__c() });
        result.addPostPrimaryRecords('Related_Case__c', new List<SObject>{ new Related_Case__c() });
        
        Assert.areEqual(2, result.postPrimaryRecords.get('Related_Case__c').size(), 
            'Should accumulate post primary records');
    }
    
    // ========================================================================
    // CLEAR CACHES TEST
    // ========================================================================
    
    @IsTest
    static void testClearAllCaches() {
        InboundForm_ConfigRegistry.getConfig('S37');
        
        Test.startTest();
        InboundForm_Processor.clearAllCaches();
        Test.stopTest();
        
        Assert.isTrue(true, 'Cache clearing should succeed');
    }
    
    // ========================================================================
    // ERROR HANDLING TESTS
    // ========================================================================
    
    @IsTest
    static void testProcessRequests_InvalidJson() {
        InboundForm_Processor.clearAllCaches();
        
        Inbound_Request__c request = new Inbound_Request__c(
            Payload__c = '{invalid json',
            Status__c = 'Received'
        );
        insert request;
        
        List<Inbound_Request__c> requests = new List<Inbound_Request__c>{
            [SELECT Id, Payload__c FROM Inbound_Request__c WHERE Id = :request.Id]
        };
        
        Test.startTest();
        Map<Id, InboundForm_Processor.ProcessingResult> results = 
            InboundForm_Processor.processRequests(requests);
        Test.stopTest();
        
        InboundForm_Processor.ProcessingResult result = results.get(request.Id);
        Assert.isFalse(result.success, 'Should fail for invalid JSON');
    }
    
    // ========================================================================
    // INTEGRATION TESTS
    // ========================================================================
    
    @IsTest
    static void testProcessRequests_EndToEnd() {
        InboundForm_Processor.clearAllCaches();
        InboundForm_ConfigRegistry.clearCache();
        
        Inbound_Request__c request = new Inbound_Request__c(
            Payload__c = getValidS37Json(),
            Status__c = 'Received'
        );
        insert request;
        
        List<Inbound_Request__c> requests = new List<Inbound_Request__c>{
            [SELECT Id, Payload__c FROM Inbound_Request__c WHERE Id = :request.Id]
        };
        
        Test.startTest();
        Map<Id, InboundForm_Processor.ProcessingResult> results = 
            InboundForm_Processor.processRequests(requests);
        Test.stopTest();
        
        InboundForm_Processor.ProcessingResult result = results.get(request.Id);
        
        Assert.isNotNull(result, 'Result should exist');
        Assert.areEqual('S37', result.formType, 'Form type should be S37');
        Assert.isNotNull(result.formConfig, 'Form config should be set');
        Assert.isNotNull(result.createdRecords, 'Created records should exist');
    }
    
    @IsTest
    static void testProcessRequests_MixedResults() {
        InboundForm_Processor.clearAllCaches();
        InboundForm_ConfigRegistry.clearCache();
        
        Inbound_Request__c validRequest = new Inbound_Request__c(
            Payload__c = getMinimalValidS37Json(),
            Status__c = 'Received'
        );
        Inbound_Request__c invalidRequest = new Inbound_Request__c(
            Payload__c = '{"formType": "INVALID"}',
            Status__c = 'Received'
        );
        insert new List<Inbound_Request__c>{ validRequest, invalidRequest };
        
        List<Inbound_Request__c> requests = [
            SELECT Id, Payload__c 
            FROM Inbound_Request__c 
            WHERE Id IN (:validRequest.Id, :invalidRequest.Id)
        ];
        
        Test.startTest();
        Map<Id, InboundForm_Processor.ProcessingResult> results = 
            InboundForm_Processor.processRequests(requests);
        Test.stopTest();
        
        Assert.areEqual(2, results.size(), 'Should have 2 results');
        Assert.isFalse(results.get(invalidRequest.Id).success, 
            'Invalid request should fail');
    }
    
    @IsTest
    static void testProcessRequests_WithPartyData() {
        InboundForm_Processor.clearAllCaches();
        InboundForm_ConfigRegistry.clearCache();
        
        Inbound_Request__c request = new Inbound_Request__c(
            Payload__c = getJsonWithPartyData(),
            Status__c = 'Received'
        );
        insert request;
        
        List<Inbound_Request__c> requests = new List<Inbound_Request__c>{
            [SELECT Id, Payload__c FROM Inbound_Request__c WHERE Id = :request.Id]
        };
        
        Test.startTest();
        Map<Id, InboundForm_Processor.ProcessingResult> results = 
            InboundForm_Processor.processRequests(requests);
        Test.stopTest();
        
        InboundForm_Processor.ProcessingResult result = results.get(request.Id);
        Assert.isTrue(result.success, 'Should succeed with party data');
    }
    
    @IsTest
    static void testProcessRequests_WithApplicationRelations_NotFound() {
        InboundForm_Processor.clearAllCaches();
        InboundForm_ConfigRegistry.clearCache();
        
        // JSON with application relation to non-existent case
        Inbound_Request__c request = new Inbound_Request__c(
            Payload__c = getJsonWithApplicationRelations('NON-EXISTENT-ID'),
            Status__c = 'Received'
        );
        insert request;
        
        List<Inbound_Request__c> requests = new List<Inbound_Request__c>{
            [SELECT Id, Payload__c FROM Inbound_Request__c WHERE Id = :request.Id]
        };
        
        Test.startTest();
        Map<Id, InboundForm_Processor.ProcessingResult> results = 
            InboundForm_Processor.processRequests(requests);
        Test.stopTest();
        
        InboundForm_Processor.ProcessingResult result = results.get(request.Id);
        Assert.isTrue(result.success, 'Should still succeed overall');
        Assert.isTrue(result.hasWarnings(), 'Should have warnings for not found case');
    }
    
    @IsTest
    static void testProcessRequests_WithApplicationRelations_Found() {
        InboundForm_Processor.clearAllCaches();
        InboundForm_ConfigRegistry.clearCache();
        
        // Create a related case
        Case__c relatedCase = new Case__c(
            Name = 'Related Case',
            AWS_Application_Id__c = 'EXISTING-APP-ID'
        );
        insert relatedCase;
        
        Inbound_Request__c request = new Inbound_Request__c(
            Payload__c = getJsonWithApplicationRelations('EXISTING-APP-ID'),
            Status__c = 'Received'
        );
        insert request;
        
        List<Inbound_Request__c> requests = new List<Inbound_Request__c>{
            [SELECT Id, Payload__c FROM Inbound_Request__c WHERE Id = :request.Id]
        };
        
        Test.startTest();
        Map<Id, InboundForm_Processor.ProcessingResult> results = 
            InboundForm_Processor.processRequests(requests);
        Test.stopTest();
        
        InboundForm_Processor.ProcessingResult result = results.get(request.Id);
        Assert.isTrue(result.success, 'Should succeed');
        Assert.isFalse(result.hasWarnings(), 'Should have no warnings when case found');
    }
    
    // ========================================================================
    // PARSER STORAGE TEST
    // ========================================================================
    
    @IsTest
    static void testProcessingResult_ParserStorage() {
        InboundForm_Processor.clearAllCaches();
        InboundForm_ConfigRegistry.clearCache();
        
        Inbound_Request__c request = new Inbound_Request__c(
            Payload__c = getMinimalValidS37Json(),
            Status__c = 'Received'
        );
        insert request;
        
        List<Inbound_Request__c> requests = new List<Inbound_Request__c>{
            [SELECT Id, Payload__c FROM Inbound_Request__c WHERE Id = :request.Id]
        };
        
        Test.startTest();
        Map<Id, InboundForm_Processor.ProcessingResult> results = 
            InboundForm_Processor.processRequests(requests);
        Test.stopTest();
        
        InboundForm_Processor.ProcessingResult result = results.get(request.Id);
        Assert.isNotNull(result.parser, 'Parser should be stored in result');
    }
}