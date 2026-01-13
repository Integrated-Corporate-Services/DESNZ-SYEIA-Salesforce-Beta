/**
 * Test class for InboundForm_S37Handler.
 * Tests S37-specific validation, post-processing logic, application relations, and DNO handling.
 */
@IsTest
private class InboundForm_S37HandlerTest {
    
    // ========================================================================
    // TEST DATA HELPERS
    // ========================================================================
    
    private static String getValidS37Json() {
        return '{' +
            '"formType": "S37",' +
            '"applicationId": "APP-12345",' +
            '"sections": {' +
                '"worksOverview": {' +
                    '"polesAdded": 5,' +
                    '"excavationRequired": false' +
                '},' +
                '"location": {' +
                    '"routes": [' +
                        '{' +
                            '"routeName": "Route 1",' +
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
                        '"application_project_overview": {' +
                            '"earliest_work_start_date_year": "2024",' +
                            '"earliest_work_start_date_month": "6",' +
                            '"latest_work_start_date_year": "2024",' +
                            '"latest_work_start_date_month": "12"' +
                        '}' +
                    '}' +
                '}' +
            '}' +
        '}';
    }
    
    private static String getJsonWithNoRoutes() {
        return '{' +
            '"formType": "S37",' +
            '"applicationId": "APP-12345",' +
            '"sections": {' +
                '"location": {' +
                    '"routes": []' +
                '},' +
                '"eiaFees": {' +
                    '"is_eia_development": false' +
                '}' +
            '}' +
        '}';
    }
    
    private static String getJsonWithInsufficientGridPoints() {
        return '{' +
            '"formType": "S37",' +
            '"applicationId": "APP-12345",' +
            '"sections": {' +
                '"location": {' +
                    '"routes": [' +
                        '{' +
                            '"routeName": "Short Route",' +
                            '"route_id": "R001",' +
                            '"gridPoints": [' +
                                '{"point_id": "P1", "easting": "123456", "northing": "654321"}' +
                            ']' +
                        '}' +
                    ']' +
                '},' +
                '"eiaFees": {' +
                    '"is_eia_development": false' +
                '}' +
            '}' +
        '}';
    }
    
    private static String getJsonWithExcavationButNoDetails() {
        return '{' +
            '"formType": "S37",' +
            '"applicationId": "APP-12345",' +
            '"sections": {' +
                '"worksOverview": {' +
                    '"excavationRequired": true' +
                '},' +
                '"location": {' +
                    '"routes": [' +
                        '{' +
                            '"routeName": "Route 1",' +
                            '"route_id": "R001",' +
                            '"gridPoints": [' +
                                '{"point_id": "P1"},' +
                                '{"point_id": "P2"}' +
                            ']' +
                        '}' +
                    ']' +
                '},' +
                '"eiaFees": {' +
                    '"is_eia_development": false' +
                '}' +
            '}' +
        '}';
    }
    
    private static String getJsonWithEiaButNoSelection() {
        return '{' +
            '"formType": "S37",' +
            '"applicationId": "APP-12345",' +
            '"sections": {' +
                '"location": {' +
                    '"routes": [' +
                        '{' +
                            '"routeName": "Route 1",' +
                            '"gridPoints": [{"point_id": "P1"}, {"point_id": "P2"}]' +
                        '}' +
                    ']' +
                '},' +
                '"eiaFees": {' +
                    '"is_eia_development": true,' +
                    '"requires_full_eia": false,' +
                    '"screening_only": false' +
                '}' +
            '}' +
        '}';
    }
    
    private static String getJsonWithFullEia() {
        return '{' +
            '"formType": "S37",' +
            '"applicationId": "APP-12345",' +
            '"sections": {' +
                '"location": {' +
                    '"routes": [' +
                        '{' +
                            '"routeName": "Route 1",' +
                            '"gridPoints": [{"point_id": "P1"}, {"point_id": "P2"}]' +
                        '}' +
                    ']' +
                '},' +
                '"eiaFees": {' +
                    '"is_eia_development": true,' +
                    '"requires_full_eia": true,' +
                    '"screening_only": false' +
                '}' +
            '}' +
        '}';
    }
    
    private static String getJsonWithScreeningOnly() {
        return '{' +
            '"formType": "S37",' +
            '"applicationId": "APP-12345",' +
            '"sections": {' +
                '"location": {' +
                    '"routes": [' +
                        '{' +
                            '"routeName": "Route 1",' +
                            '"gridPoints": [{"point_id": "P1"}, {"point_id": "P2"}]' +
                        '}' +
                    ']' +
                '},' +
                '"eiaFees": {' +
                    '"is_eia_development": true,' +
                    '"requires_full_eia": false,' +
                    '"screening_only": true' +
                '}' +
            '}' +
        '}';
    }
    
    private static String getJsonWithApplicationRelations(String relatedAppId) {
        return '{' +
            '"formType": "S37",' +
            '"applicationId": "APP-12345",' +
            '"sections": {' +
                '"location": {' +
                    '"routes": [' +
                        '{' +
                            '"routeName": "Route 1",' +
                            '"gridPoints": [{"point_id": "P1"}, {"point_id": "P2"}]' +
                        '}' +
                    ']' +
                '},' +
                '"eiaFees": {"is_eia_development": false},' +
                '"projectDetails": {' +
                    '"overview": {' +
                        '"application_relations": [' +
                            '{' +
                                '"details": "Related project",' +
                                '"relation_type": "ASSOCIATED",' +
                                '"application_id": "APP-12345",' +
                                '"related_application_id": "' + relatedAppId + '",' +
                                '"application_relation_id": "REL-001"' +
                            '}' +
                        ']' +
                    '}' +
                '}' +
            '}' +
        '}';
    }
    
    private static String getJsonWithMultipleApplicationRelations(List<String> relatedAppIds) {
        String relationsJson = '';
        for (Integer i = 0; i < relatedAppIds.size(); i++) {
            if (i > 0) relationsJson += ',';
            relationsJson += '{' +
                '"details": "Relation ' + i + '",' +
                '"relation_type": "ASSOCIATED",' +
                '"related_application_id": "' + relatedAppIds[i] + '",' +
                '"application_relation_id": "REL-00' + i + '"' +
            '}';
        }
        
        return '{' +
            '"formType": "S37",' +
            '"applicationId": "APP-12345",' +
            '"sections": {' +
                '"location": {' +
                    '"routes": [' +
                        '{"routeName": "Route 1", "gridPoints": [{"point_id": "P1"}, {"point_id": "P2"}]}' +
                    ']' +
                '},' +
                '"eiaFees": {"is_eia_development": false},' +
                '"projectDetails": {' +
                    '"overview": {' +
                        '"application_relations": [' + relationsJson + ']' +
                    '}' +
                '}' +
            '}' +
        '}';
    }
    
    // ========================================================================
    // VALIDATION TESTS
    // ========================================================================
    
    @IsTest
    static void testValidate_ValidPayload() {
        InboundForm_S37Handler handler = new InboundForm_S37Handler();
        InboundForm_JSONParser parser = new InboundForm_JSONParser(getValidS37Json());
        
        Test.startTest();
        List<String> errors = handler.validate(parser);
        Test.stopTest();
        
        Assert.isTrue(errors.isEmpty(), 'Should have no validation errors');
    }
    
    @IsTest
    static void testValidate_NoRoutes() {
        InboundForm_S37Handler handler = new InboundForm_S37Handler();
        InboundForm_JSONParser parser = new InboundForm_JSONParser(getJsonWithNoRoutes());
        
        Test.startTest();
        List<String> errors = handler.validate(parser);
        Test.stopTest();
        
        Assert.isFalse(errors.isEmpty(), 'Should have validation errors');
        Assert.isTrue(errors[0].contains('at least one route'), 
            'Error should mention routes requirement');
    }
    
    @IsTest
    static void testValidate_InsufficientGridPoints() {
        InboundForm_S37Handler handler = new InboundForm_S37Handler();
        InboundForm_JSONParser parser = new InboundForm_JSONParser(getJsonWithInsufficientGridPoints());
        
        Test.startTest();
        List<String> errors = handler.validate(parser);
        Test.stopTest();
        
        Assert.isFalse(errors.isEmpty(), 'Should have validation errors');
        Assert.isTrue(errors[0].contains('at least 2 grid points'), 
            'Error should mention grid points requirement');
    }
    
    @IsTest
    static void testValidate_RouteWithNoGridPoints() {
        String json = '{' +
            '"formType": "S37",' +
            '"sections": {' +
                '"location": {' +
                    '"routes": [' +
                        '{"routeName": "Empty Route", "route_id": "R001"}' +
                    ']' +
                '},' +
                '"eiaFees": {"is_eia_development": false}' +
            '}' +
        '}';
        
        InboundForm_S37Handler handler = new InboundForm_S37Handler();
        InboundForm_JSONParser parser = new InboundForm_JSONParser(json);
        
        Test.startTest();
        List<String> errors = handler.validate(parser);
        Test.stopTest();
        
        Assert.isFalse(errors.isEmpty(), 'Should have validation errors');
        Assert.isTrue(errors[0].contains('no grid points'), 
            'Error should mention missing grid points');
    }
    
    @IsTest
    static void testValidate_RouteWithoutName() {
        String json = '{' +
            '"formType": "S37",' +
            '"sections": {' +
                '"location": {' +
                    '"routes": [' +
                        '{"route_id": "R001", "gridPoints": [{"point_id": "P1"}]}' +
                    ']' +
                '},' +
                '"eiaFees": {"is_eia_development": false}' +
            '}' +
        '}';
        
        InboundForm_S37Handler handler = new InboundForm_S37Handler();
        InboundForm_JSONParser parser = new InboundForm_JSONParser(json);
        
        Test.startTest();
        List<String> errors = handler.validate(parser);
        Test.stopTest();
        
        Assert.isFalse(errors.isEmpty(), 'Should have validation errors');
        Assert.isTrue(errors[0].contains('Route 1'), 
            'Error should use default route name');
    }
    
    @IsTest
    static void testValidate_ExcavationWithDetails() {
        String json = '{' +
            '"formType": "S37",' +
            '"sections": {' +
                '"worksOverview": {' +
                    '"excavationRequired": true,' +
                    '"excavationDetails": "Digging for pole foundations"' +
                '},' +
                '"location": {' +
                    '"routes": [' +
                        '{"routeName": "Route 1", "gridPoints": [{"point_id": "P1"}, {"point_id": "P2"}]}' +
                    ']' +
                '},' +
                '"eiaFees": {"is_eia_development": false}' +
            '}' +
        '}';
        
        InboundForm_S37Handler handler = new InboundForm_S37Handler();
        InboundForm_JSONParser parser = new InboundForm_JSONParser(json);
        
        Test.startTest();
        List<String> errors = handler.validate(parser);
        Test.stopTest();
        
        Assert.isTrue(errors.isEmpty(), 'Should have no excavation errors when details provided');
    }
    
    @IsTest
    static void testValidate_ValidFullEia() {
        InboundForm_S37Handler handler = new InboundForm_S37Handler();
        InboundForm_JSONParser parser = new InboundForm_JSONParser(getJsonWithFullEia());
        
        Test.startTest();
        List<String> errors = handler.validate(parser);
        Test.stopTest();
        
        Assert.isTrue(errors.isEmpty(), 'Should have no EIA validation errors');
    }
    
    @IsTest
    static void testValidate_ValidScreeningOnly() {
        InboundForm_S37Handler handler = new InboundForm_S37Handler();
        InboundForm_JSONParser parser = new InboundForm_JSONParser(getJsonWithScreeningOnly());
        
        Test.startTest();
        List<String> errors = handler.validate(parser);
        Test.stopTest();
        
        Assert.isTrue(errors.isEmpty(), 'Should have no EIA validation errors');
    }
    
    // ========================================================================
    // AFTER BUILD TESTS
    // ========================================================================
    
    @IsTest
    static void testAfterBuild_CaseRecordProcessing() {
        InboundForm_S37Handler handler = new InboundForm_S37Handler();
        InboundForm_JSONParser parser = new InboundForm_JSONParser(getValidS37Json());
        
        Case__c testCase = new Case__c();
        
        Map<String, List<SObject>> records = new Map<String, List<SObject>>{
            'Case__c' => new List<SObject>{ testCase }
        };
        
        Test.startTest();
        handler.afterBuild(parser, records);
        Test.stopTest();
        
        Assert.areEqual('Section 37', testCase.Case_Type__c, 
            'Case type should be set to Section 37');
        Assert.areEqual('Yes', testCase.Application_Fee_Paid__c, 
            'Application fee paid should be Yes');
        Assert.isFalse(testCase.Overdue_Email_Sent__c, 
            'Overdue email sent should be false');
    }
    
    @IsTest
    static void testAfterBuild_DateFields() {
        InboundForm_S37Handler handler = new InboundForm_S37Handler();
        InboundForm_JSONParser parser = new InboundForm_JSONParser(getValidS37Json());
        
        Case__c testCase = new Case__c();
        
        Map<String, List<SObject>> records = new Map<String, List<SObject>>{
            'Case__c' => new List<SObject>{ testCase }
        };
        
        Test.startTest();
        handler.afterBuild(parser, records);
        Test.stopTest();
        
        Assert.areEqual(Date.newInstance(2024, 6, 1), testCase.Earliest_Expected_Start_Date__c, 
            'Earliest start date should be set');
        Assert.areEqual(Date.newInstance(2024, 12, 1), testCase.Latest_Expected_Start_Date__c, 
            'Latest start date should be set');
    }
    
    @IsTest
    static void testAfterBuild_EiaFieldsFullEia() {
        InboundForm_S37Handler handler = new InboundForm_S37Handler();
        InboundForm_JSONParser parser = new InboundForm_JSONParser(getJsonWithFullEia());
        
        Case__c testCase = new Case__c();
        
        Map<String, List<SObject>> records = new Map<String, List<SObject>>{
            'Case__c' => new List<SObject>{ testCase }
        };
        
        Test.startTest();
        handler.afterBuild(parser, records);
        Test.stopTest();
        
        Assert.areEqual('Full EIA Process', testCase.Full_EIA_Process_or_Screening_Opinion__c, 
            'EIA field should be Full EIA Process');
    }
    
    @IsTest
    static void testAfterBuild_EiaFieldsScreeningOnly() {
        InboundForm_S37Handler handler = new InboundForm_S37Handler();
        InboundForm_JSONParser parser = new InboundForm_JSONParser(getJsonWithScreeningOnly());
        
        Case__c testCase = new Case__c();
        
        Map<String, List<SObject>> records = new Map<String, List<SObject>>{
            'Case__c' => new List<SObject>{ testCase }
        };
        
        Test.startTest();
        handler.afterBuild(parser, records);
        Test.stopTest();
        
        Assert.areEqual('Screening Opinion', testCase.Full_EIA_Process_or_Screening_Opinion__c, 
            'EIA field should be Screening Opinion');
    }
    
    @IsTest
    static void testAfterBuild_PartyRecordProcessing() {
        InboundForm_S37Handler handler = new InboundForm_S37Handler();
        InboundForm_JSONParser parser = new InboundForm_JSONParser(getValidS37Json());
        
        Party__c primaryParty = new Party__c(Is_Primary__c = true);
        Party__c secondaryParty = new Party__c(Is_Primary__c = false);
        
        Map<String, List<SObject>> records = new Map<String, List<SObject>>{
            'Party__c' => new List<SObject>{ primaryParty, secondaryParty }
        };
        
        Test.startTest();
        handler.afterBuild(parser, records);
        Test.stopTest();
        
        Assert.areEqual('DNO', primaryParty.Party_Type__c, 
            'Primary party should have DNO type');
        Assert.isNull(secondaryParty.Party_Type__c, 
            'Secondary party should not have party type set');
    }
    
    @IsTest
    static void testAfterBuild_NoCaseRecords() {
        InboundForm_S37Handler handler = new InboundForm_S37Handler();
        InboundForm_JSONParser parser = new InboundForm_JSONParser(getValidS37Json());
        
        Map<String, List<SObject>> records = new Map<String, List<SObject>>();
        
        Test.startTest();
        handler.afterBuild(parser, records);
        Test.stopTest();
        
        Assert.isTrue(true, 'Should complete without error');
    }
    
    @IsTest
    static void testAfterBuild_NoPartyRecords() {
        InboundForm_S37Handler handler = new InboundForm_S37Handler();
        InboundForm_JSONParser parser = new InboundForm_JSONParser(getValidS37Json());
        
        Case__c testCase = new Case__c();
        Map<String, List<SObject>> records = new Map<String, List<SObject>>{
            'Case__c' => new List<SObject>{ testCase }
        };
        
        Test.startTest();
        handler.afterBuild(parser, records);
        Test.stopTest();
        
        Assert.areEqual('Section 37', testCase.Case_Type__c, 
            'Case should still be processed');
    }
    
    @IsTest
    static void testAfterBuild_InvalidDateFields() {
        String json = '{' +
            '"formType": "S37",' +
            '"sections": {' +
                '"location": {' +
                    '"routes": [' +
                        '{"routeName": "Route 1", "gridPoints": [{"point_id": "P1"}, {"point_id": "P2"}]}' +
                    ']' +
                '},' +
                '"eiaFees": {"is_eia_development": false},' +
                '"projectDetails": {' +
                    '"overview": {' +
                        '"application_project_overview": {' +
                            '"earliest_work_start_date_year": "invalid",' +
                            '"earliest_work_start_date_month": "not_a_number"' +
                        '}' +
                    '}' +
                '}' +
            '}' +
        '}';
        
        InboundForm_S37Handler handler = new InboundForm_S37Handler();
        InboundForm_JSONParser parser = new InboundForm_JSONParser(json);
        
        Case__c testCase = new Case__c();
        Map<String, List<SObject>> records = new Map<String, List<SObject>>{
            'Case__c' => new List<SObject>{ testCase }
        };
        
        Test.startTest();
        handler.afterBuild(parser, records);
        Test.stopTest();
        
        Assert.isNull(testCase.Earliest_Expected_Start_Date__c, 
            'Invalid date should result in null');
    }
    
    @IsTest
    static void testAfterBuild_MissingDateFields() {
        String json = '{' +
            '"formType": "S37",' +
            '"sections": {' +
                '"location": {' +
                    '"routes": [' +
                        '{"routeName": "Route 1", "gridPoints": [{"point_id": "P1"}, {"point_id": "P2"}]}' +
                    ']' +
                '},' +
                '"eiaFees": {"is_eia_development": false},' +
                '"projectDetails": {' +
                    '"overview": {' +
                        '"application_project_overview": {}' +
                    '}' +
                '}' +
            '}' +
        '}';
        
        InboundForm_S37Handler handler = new InboundForm_S37Handler();
        InboundForm_JSONParser parser = new InboundForm_JSONParser(json);
        
        Case__c testCase = new Case__c();
        Map<String, List<SObject>> records = new Map<String, List<SObject>>{
            'Case__c' => new List<SObject>{ testCase }
        };
        
        Test.startTest();
        handler.afterBuild(parser, records);
        Test.stopTest();
        
        Assert.isNull(testCase.Earliest_Expected_Start_Date__c, 
            'Missing date fields should result in null');
    }
    
    // ========================================================================
    // AFTER PRIMARY INSERT TESTS - Application Relations
    // ========================================================================
    
    @IsTest
    static void testAfterPrimaryInsert_NoApplicationRelations() {
        InboundForm_S37Handler handler = new InboundForm_S37Handler();
        InboundForm_JSONParser parser = new InboundForm_JSONParser(getValidS37Json());
        
        Case__c testCase = new Case__c(Name = 'Test Case');
        insert testCase;
        
        InboundForm_Processor.ProcessingResult result = 
            new InboundForm_Processor.ProcessingResult(testCase.Id);
        
        Test.startTest();
        handler.afterPrimaryInsert(parser, testCase.Id, result);
        Test.stopTest();
        
        Assert.isTrue(result.postPrimaryRecords.isEmpty() || 
            !result.postPrimaryRecords.containsKey('Related_Case__c'),
            'Should have no Related_Case__c records');
        Assert.isTrue(result.warnings.isEmpty(), 'Should have no warnings');
    }
    
    @IsTest
    static void testAfterPrimaryInsert_ApplicationRelationsFound() {
        Case__c relatedCase = new Case__c(
            Name = 'Related Case',
            AWS_Application_Id__c = 'RELATED-APP-001'
        );
        insert relatedCase;
        
        InboundForm_S37Handler handler = new InboundForm_S37Handler();
        String json = getJsonWithApplicationRelations('RELATED-APP-001');
        InboundForm_JSONParser parser = new InboundForm_JSONParser(json);
        
        Case__c parentCase = new Case__c(Name = 'Parent Case');
        insert parentCase;
        
        InboundForm_Processor.ProcessingResult result = 
            new InboundForm_Processor.ProcessingResult(parentCase.Id);
        
        Test.startTest();
        handler.afterPrimaryInsert(parser, parentCase.Id, result);
        Test.stopTest();
        
        Assert.isTrue(result.postPrimaryRecords.containsKey('Related_Case__c'),
            'Should have Related_Case__c records');
        
        List<SObject> relatedCases = result.postPrimaryRecords.get('Related_Case__c');
        Assert.areEqual(1, relatedCases.size(), 'Should have 1 Related_Case__c record');
        
        Related_Case__c relatedCaseRecord = (Related_Case__c) relatedCases[0];
        Assert.areEqual(parentCase.Id, relatedCaseRecord.Parent_Case__c,
            'Parent_Case__c should be set to parent case Id');
        Assert.areEqual(relatedCase.Id, relatedCaseRecord.Child_Case__c,
            'Child_Case__c should be set to found case Id');
        
        Assert.isTrue(result.warnings.isEmpty(), 'Should have no warnings when case found');
    }
    
    @IsTest
    static void testAfterPrimaryInsert_ApplicationRelationsNotFound() {
        InboundForm_S37Handler handler = new InboundForm_S37Handler();
        String json = getJsonWithApplicationRelations('NON-EXISTENT-APP-ID');
        InboundForm_JSONParser parser = new InboundForm_JSONParser(json);
        
        Case__c parentCase = new Case__c(Name = 'Parent Case');
        insert parentCase;
        
        InboundForm_Processor.ProcessingResult result = 
            new InboundForm_Processor.ProcessingResult(parentCase.Id);
        
        Test.startTest();
        handler.afterPrimaryInsert(parser, parentCase.Id, result);
        Test.stopTest();
        
        Assert.isTrue(result.postPrimaryRecords.isEmpty() ||
            !result.postPrimaryRecords.containsKey('Related_Case__c') ||
            result.postPrimaryRecords.get('Related_Case__c').isEmpty(),
            'Should have no Related_Case__c records');
        
        Assert.isFalse(result.warnings.isEmpty(), 'Should have warnings');
        Assert.isTrue(result.warnings[0].contains('Failed to find Case using AWS Id'),
            'Warning should mention failed to find case');
        Assert.isTrue(result.warnings[0].contains('NON-EXISTENT-APP-ID'),
            'Warning should include the AWS Id');
    }
    
    @IsTest
    static void testAfterPrimaryInsert_MixedApplicationRelations() {
        Case__c relatedCase = new Case__c(
            Name = 'Found Case',
            AWS_Application_Id__c = 'FOUND-APP-001'
        );
        insert relatedCase;
        
        InboundForm_S37Handler handler = new InboundForm_S37Handler();
        String json = getJsonWithMultipleApplicationRelations(
            new List<String>{'FOUND-APP-001', 'NOT-FOUND-APP-002'}
        );
        InboundForm_JSONParser parser = new InboundForm_JSONParser(json);
        
        Case__c parentCase = new Case__c(Name = 'Parent Case');
        insert parentCase;
        
        InboundForm_Processor.ProcessingResult result = 
            new InboundForm_Processor.ProcessingResult(parentCase.Id);
        
        Test.startTest();
        handler.afterPrimaryInsert(parser, parentCase.Id, result);
        Test.stopTest();
        
        Assert.isTrue(result.postPrimaryRecords.containsKey('Related_Case__c'),
            'Should have Related_Case__c records');
        Assert.areEqual(1, result.postPrimaryRecords.get('Related_Case__c').size(),
            'Should have 1 Related_Case__c record');
        
        Assert.areEqual(1, result.warnings.size(), 'Should have 1 warning');
        Assert.isTrue(result.warnings[0].contains('NOT-FOUND-APP-002'),
            'Warning should mention the not found AWS Id');
    }
    
    @IsTest
    static void testAfterPrimaryInsert_EmptyRelatedApplicationId() {
        String json = '{' +
            '"formType": "S37",' +
            '"applicationId": "APP-12345",' +
            '"sections": {' +
                '"location": {' +
                    '"routes": [{"routeName": "Route 1", "gridPoints": [{"point_id": "P1"}, {"point_id": "P2"}]}]' +
                '},' +
                '"eiaFees": {"is_eia_development": false},' +
                '"projectDetails": {' +
                    '"overview": {' +
                        '"application_relations": [' +
                            '{"details": "Empty relation", "related_application_id": ""}' +
                        ']' +
                    '}' +
                '}' +
            '}' +
        '}';
        
        InboundForm_S37Handler handler = new InboundForm_S37Handler();
        InboundForm_JSONParser parser = new InboundForm_JSONParser(json);
        
        Case__c parentCase = new Case__c(Name = 'Parent Case');
        insert parentCase;
        
        InboundForm_Processor.ProcessingResult result = 
            new InboundForm_Processor.ProcessingResult(parentCase.Id);
        
        Test.startTest();
        handler.afterPrimaryInsert(parser, parentCase.Id, result);
        Test.stopTest();
        
        Assert.isTrue(result.warnings.isEmpty(), 'Should have no warnings for empty id');
    }
    
    // ========================================================================
    // AFTER ALL INSERTS TESTS - DNO Processing
    // ========================================================================
    
    @IsTest
    static void testAfterAllInserts_NoPrimaryParty() {
        InboundForm_S37Handler handler = new InboundForm_S37Handler();
        
        Case__c testCase = new Case__c(Name = 'Test Case');
        insert testCase;
        
        Party__c secondaryParty = new Party__c(
            Name = 'Secondary Party',
            Case__c = testCase.Id,
            Is_Primary__c = false
        );
        insert secondaryParty;
        
        Map<String, List<SObject>> insertedRecords = new Map<String, List<SObject>>{
            'Party__c' => new List<SObject>{ secondaryParty }
        };
        
        Test.startTest();
        handler.afterAllInserts(testCase.Id, insertedRecords);
        Test.stopTest();
        
        Case__c updatedCase = [SELECT DNO__c FROM Case__c WHERE Id = :testCase.Id];
        Assert.isNull(updatedCase.DNO__c, 'DNO__c should not be set when no primary party');
    }
    
    @IsTest
    static void testAfterAllInserts_NoPartyRecords() {
        InboundForm_S37Handler handler = new InboundForm_S37Handler();
        
        Case__c testCase = new Case__c(Name = 'Test Case');
        insert testCase;
        
        Map<String, List<SObject>> insertedRecords = new Map<String, List<SObject>>();
        
        Test.startTest();
        handler.afterAllInserts(testCase.Id, insertedRecords);
        Test.stopTest();
        
        Assert.isTrue(true, 'Should complete without error');
    }
    
    @IsTest
    static void testAfterAllInserts_PartyWithoutId() {
        InboundForm_S37Handler handler = new InboundForm_S37Handler();
        
        Case__c testCase = new Case__c(Name = 'Test Case');
        insert testCase;
        
        Party__c primaryParty = new Party__c(
            Name = 'Test DNO',
            Is_Primary__c = true
        );
        
        Map<String, List<SObject>> insertedRecords = new Map<String, List<SObject>>{
            'Party__c' => new List<SObject>{ primaryParty }
        };
        
        Test.startTest();
        handler.afterAllInserts(testCase.Id, insertedRecords);
        Test.stopTest();
        
        Case__c updatedCase = [SELECT DNO__c FROM Case__c WHERE Id = :testCase.Id];
        Assert.isNull(updatedCase.DNO__c, 'DNO__c should not be set when party has no Id');
    }
}