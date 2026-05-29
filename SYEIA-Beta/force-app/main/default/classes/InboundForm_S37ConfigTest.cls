/**
 * Test class for InboundForm_S37Config.
 * Tests S37-specific configuration and mapping definitions.
 */
@IsTest
private class InboundForm_S37ConfigTest {
    
    // ========================================================================
    // GET CONFIG TESTS
    // ========================================================================
    
    @IsTest
    static void testGetConfig_ReturnsValidConfig() {
        Test.startTest();
        InboundForm_MappingConfig.FormTypeConfig config = InboundForm_S37Config.getConfig();
        Test.stopTest();
        
        Assert.isNotNull(config, 'Config should not be null');
        Assert.areEqual('S37', config.formType, 'Form type should be S37');
        Assert.areEqual('Section 37 - Overhead Electric Lines', config.description, 
            'Description should match');
    }
    
    @IsTest
    static void testGetConfig_PrimaryObjectSettings() {
        Test.startTest();
        InboundForm_MappingConfig.FormTypeConfig config = InboundForm_S37Config.getConfig();
        Test.stopTest();
        
        Assert.areEqual('Case__c', config.primaryObject, 'Primary object should be Case__c');
        Assert.areEqual('Section_37', config.primaryRecordType, 
            'Primary record type should be Section_37');
        Assert.areEqual('AWS_Application_Id__c', config.applicationIdField, 
            'Application ID field should match');
        Assert.areEqual('applicationId', config.applicationIdJsonPath, 
            'Application ID JSON path should match');
        Assert.areEqual('applicationId', config.nameJsonPath, 
            'Name JSON path should match');
    }
    
    @IsTest
    static void testGetConfig_StatusSettings() {
        Test.startTest();
        InboundForm_MappingConfig.FormTypeConfig config = InboundForm_S37Config.getConfig();
        Test.stopTest();
        
        Assert.areEqual('Status__c', config.statusField, 'Status field should match');
        Assert.areEqual('New', config.defaultStatus, 'Default status should be New');
    }
    
    @IsTest
    static void testGetConfig_HandlerClass() {
        Test.startTest();
        InboundForm_MappingConfig.FormTypeConfig config = InboundForm_S37Config.getConfig();
        Test.stopTest();
        
        Assert.areEqual(InboundForm_S37Handler.class, config.handlerClass, 
            'Handler class should be InboundForm_S37Handler');
    }
    
    @IsTest
    static void testGetConfig_IsActive() {
        Test.startTest();
        InboundForm_MappingConfig.FormTypeConfig config = InboundForm_S37Config.getConfig();
        Test.stopTest();
        
        Assert.isTrue(config.active, 'Config should be active');
    }
    
    // ========================================================================
    // FIELD MAPPINGS TESTS
    // ========================================================================
    
    @IsTest
    static void testGetConfig_HasFieldMappings() {
        Test.startTest();
        InboundForm_MappingConfig.FormTypeConfig config = InboundForm_S37Config.getConfig();
        Test.stopTest();
        
        Assert.isNotNull(config.fieldMappings, 'Field mappings should not be null');
        Assert.isFalse(config.fieldMappings.isEmpty(), 'Should have field mappings');
    }
    
    @IsTest
    static void testGetConfig_WorksOverviewMappings() {
        InboundForm_MappingConfig.FormTypeConfig config = InboundForm_S37Config.getConfig();
        
        // Find specific mappings
        Map<String, InboundForm_MappingConfig.FieldMapping> mappingsByTarget = 
            new Map<String, InboundForm_MappingConfig.FieldMapping>();
        
        for (InboundForm_MappingConfig.FieldMapping mapping : config.fieldMappings) {
            mappingsByTarget.put(mapping.targetField, mapping);
        }
        
        Test.startTest();
        // Test poles added mapping
        Assert.isTrue(mappingsByTarget.containsKey('Number_Of_Poles_Being_Added__c'), 
            'Should have poles added mapping');
        Assert.areEqual('sections.worksOverview.polesAdded', 
            mappingsByTarget.get('Number_Of_Poles_Being_Added__c').jsonPath, 
            'Poles added JSON path should match');
        Assert.areEqual(InboundForm_MappingConfig.DataType.INTEGER_TYPE, 
            mappingsByTarget.get('Number_Of_Poles_Being_Added__c').dataType, 
            'Poles added should be integer type');
        
        // Test excavation required mapping
        Assert.isTrue(mappingsByTarget.containsKey('Excavation_Works_Required__c'), 
            'Should have excavation required mapping');
        Assert.areEqual(InboundForm_MappingConfig.DataType.BOOLEAN_YES_NO, 
            mappingsByTarget.get('Excavation_Works_Required__c').dataType, 
            'Excavation required should be yes/no type');
        Test.stopTest();
    }
    
    @IsTest
    static void testGetConfig_ProjectDetailsMappings() {
        InboundForm_MappingConfig.FormTypeConfig config = InboundForm_S37Config.getConfig();
        
        Map<String, InboundForm_MappingConfig.FieldMapping> mappingsByTarget = 
            new Map<String, InboundForm_MappingConfig.FieldMapping>();
        
        for (InboundForm_MappingConfig.FieldMapping mapping : config.fieldMappings) {
            mappingsByTarget.put(mapping.targetField, mapping);
        }
        
        Test.startTest();
        Assert.isTrue(mappingsByTarget.containsKey('Project_Name__c'), 
            'Should have project name mapping');
        Assert.isTrue(mappingsByTarget.containsKey('Tallest_Pole_Height__c'), 
            'Should have tallest pole height mapping');
        Assert.areEqual(InboundForm_MappingConfig.DataType.DECIMAL_TYPE, 
            mappingsByTarget.get('Tallest_Pole_Height__c').dataType, 
            'Tallest pole height should be decimal type');
        Test.stopTest();
    }
    
    // ========================================================================
    // COLLECTIONS TESTS
    // ========================================================================
    
    @IsTest
    static void testGetConfig_HasCollections() {
        Test.startTest();
        InboundForm_MappingConfig.FormTypeConfig config = InboundForm_S37Config.getConfig();
        Test.stopTest();
        
        Assert.isNotNull(config.collections, 'Collections should not be null');
        Assert.isFalse(config.collections.isEmpty(), 'Should have collections');
    }
    
    @IsTest
    static void testGetConfig_RoutesCollection() {
        InboundForm_MappingConfig.FormTypeConfig config = InboundForm_S37Config.getConfig();
        
        InboundForm_MappingConfig.CollectionConfig routesConfig = null;
        for (InboundForm_MappingConfig.CollectionConfig coll : config.collections) {
            if (coll.collectionName == 'Routes') {
                routesConfig = coll;
                break;
            }
        }
        
        Test.startTest();
        Assert.isNotNull(routesConfig, 'Routes collection should exist');
        Assert.areEqual('sections.location.routes', routesConfig.jsonPath, 
            'Routes JSON path should match');
        Assert.areEqual('Route__c', routesConfig.targetObject, 
            'Routes target object should be Route__c');
        Assert.areEqual('Case__c', routesConfig.parentLookupField, 
            'Routes parent lookup should be Case__c');
        Assert.areEqual(10, routesConfig.processingOrder, 
            'Routes processing order should be 10');
        Test.stopTest();
    }
    
    @IsTest
    static void testGetConfig_RoutePointsCollection() {
        InboundForm_MappingConfig.FormTypeConfig config = InboundForm_S37Config.getConfig();
        
        InboundForm_MappingConfig.CollectionConfig rpConfig = null;
        for (InboundForm_MappingConfig.CollectionConfig coll : config.collections) {
            if (coll.collectionName == 'RoutePoints') {
                rpConfig = coll;
                break;
            }
        }
        
        Test.startTest();
        Assert.isNotNull(rpConfig, 'RoutePoints collection should exist');
        Assert.isTrue(rpConfig.isNestedArray, 'RoutePoints should be nested array');
        Assert.areEqual('gridPoints', rpConfig.nestedArrayPath, 
            'Nested array path should be gridPoints');
        Assert.areEqual('Routes', rpConfig.parentCollection, 
            'Parent collection should be Routes');
        Assert.areEqual('route_id', rpConfig.parentLinkJsonField, 
            'Parent link JSON field should match');
        Assert.areEqual('Route__c', rpConfig.parentLookupField, 
            'Parent lookup field should match');
        Test.stopTest();
    }
    
    @IsTest
    static void testGetConfig_PartiesCollection() {
        InboundForm_MappingConfig.FormTypeConfig config = InboundForm_S37Config.getConfig();
        
        InboundForm_MappingConfig.CollectionConfig partiesConfig = null;
        for (InboundForm_MappingConfig.CollectionConfig coll : config.collections) {
            if (coll.collectionName == 'Parties') {
                partiesConfig = coll;
                break;
            }
        }
        
        Test.startTest();
        Assert.isNotNull(partiesConfig, 'Parties collection should exist');
        Assert.areEqual('sections.networkOperator.details.application_party', partiesConfig.jsonPath, 
            'Parties JSON path should match');
        Assert.areEqual('Party__c', partiesConfig.targetObject, 
            'Parties target object should be Party__c');
        Assert.areEqual('Organisation', partiesConfig.targetRecordType, 
            'Parties record type should be Organisation');
        Test.stopTest();
    }
    
    @IsTest
    static void testGetConfig_AddressesCollection() {
        InboundForm_MappingConfig.FormTypeConfig config = InboundForm_S37Config.getConfig();
        
        InboundForm_MappingConfig.CollectionConfig addressConfig = null;
        for (InboundForm_MappingConfig.CollectionConfig coll : config.collections) {
            if (coll.collectionName == 'Addresses') {
                addressConfig = coll;
                break;
            }
        }
        
        Test.startTest();
        Assert.isNotNull(addressConfig, 'Addresses collection should exist');
        Assert.areEqual('Parties', addressConfig.parentCollection, 
            'Parent collection should be Parties');
        Assert.areEqual('application_party_id', addressConfig.parentLinkJsonField, 
            'Parent link JSON field should match');
        Test.stopTest();
    }
    
    @IsTest
    static void testGetConfig_SensitiveAreaChecksCollection() {
        InboundForm_MappingConfig.FormTypeConfig config = InboundForm_S37Config.getConfig();
        
        InboundForm_MappingConfig.CollectionConfig sacConfig = null;
        for (InboundForm_MappingConfig.CollectionConfig coll : config.collections) {
            if (coll.collectionName == 'SensitiveAreaChecks') {
                sacConfig = coll;
                break;
            }
        }
        
        Test.startTest();
        Assert.isNotNull(sacConfig, 'SensitiveAreaChecks collection should exist');
        Assert.isTrue(sacConfig.isSimpleArray, 
            'SensitiveAreaChecks should be simple array');
        Assert.areEqual('Name', sacConfig.simpleArrayTargetField, 
            'Simple array target field should be Name');
        Test.stopTest();
    }
    
    @IsTest
    static void testGetConfig_AssetInformationCollection() {
        InboundForm_MappingConfig.FormTypeConfig config = InboundForm_S37Config.getConfig();
        
        InboundForm_MappingConfig.CollectionConfig assetConfig = null;
        for (InboundForm_MappingConfig.CollectionConfig coll : config.collections) {
            if (coll.collectionName == 'Assets') {
                assetConfig = coll;
                break;
            }
        }
        
        Test.startTest();
        Assert.isNotNull(assetConfig, 'Assets collection should exist');
        Assert.areEqual('Asset_Information__c', assetConfig.targetObject, 
            'Assets target object should match');
        Assert.isFalse(assetConfig.fieldMappings.isEmpty(), 
            'Assets should have field mappings');
        Test.stopTest();
    }
    
    // ========================================================================
    // COLLECTION ORDERING TESTS
    // ========================================================================
    
    @IsTest
    static void testGetConfig_CollectionProcessingOrder() {
        InboundForm_MappingConfig.FormTypeConfig config = InboundForm_S37Config.getConfig();
        
        Map<String, Integer> orderMap = new Map<String, Integer>();
        for (InboundForm_MappingConfig.CollectionConfig coll : config.collections) {
            orderMap.put(coll.collectionName, coll.processingOrder);
        }
        
        Test.startTest();
        // Routes should come before RoutePoints
        Assert.isTrue(orderMap.get('Routes') < orderMap.get('RoutePoints'), 
            'Routes should be processed before RoutePoints');
        
        // Parties should come before Addresses
        Assert.isTrue(orderMap.get('Parties') < orderMap.get('Addresses'), 
            'Parties should be processed before Addresses');
        Test.stopTest();
    }
    
    @IsTest
    static void testGetConfig_PaymentCollection() {
        InboundForm_MappingConfig.FormTypeConfig config = InboundForm_S37Config.getConfig();
        
        InboundForm_MappingConfig.CollectionConfig paymentsConfig = null;
        for (InboundForm_MappingConfig.CollectionConfig coll : config.collections) {
            if (coll.collectionName == 'Payments') {
                paymentsConfig = coll;
                break;
            }
        }
        
        Test.startTest();
        Assert.isNotNull(paymentsConfig, 'Payments collection should exist');
        Assert.areEqual('sections.payment', paymentsConfig.jsonPath, 
            'Payment JSON path should match');
        Assert.areEqual('Payment__c', paymentsConfig.targetObject, 
            'Parties target object should be Payment__c');
        Test.stopTest();
    }
    
    @IsTest
    static void testGetConfig_ParishCollection() {
        InboundForm_MappingConfig.FormTypeConfig config = InboundForm_S37Config.getConfig();
        
        InboundForm_MappingConfig.CollectionConfig parishesConfig = null;
        for (InboundForm_MappingConfig.CollectionConfig coll : config.collections) {
            if (coll.collectionName == 'parishes') {
                parishesConfig = coll;
                break;
            }
        }
        
        Test.startTest();
        Assert.isNotNull(parishesConfig, 'parishes collection should exist');
        Assert.areEqual('sections.parishes', parishesConfig.jsonPath, 
            'Payment JSON path should match');
        Assert.areEqual('Parish__c', parishesConfig.targetObject, 
            'parishes target object should be Parish__c');
        Test.stopTest();
    }
    
    @IsTest
    static void testGetConfig_SensitiveAreaLayerCollection() {
        InboundForm_MappingConfig.FormTypeConfig config = InboundForm_S37Config.getConfig();
        
        InboundForm_MappingConfig.CollectionConfig saclConfig = null;
        for (InboundForm_MappingConfig.CollectionConfig coll : config.collections) {
            if (coll.collectionName == 'sensitiveAreaReviewsSelected') {
                saclConfig = coll;
                break;
            }
        }
        Test.startTest();
        Assert.isNotNull(saclConfig, 'SensitiveAreaReviewSelected collection should exist');
        Assert.areEqual('Sensitive_Area_Review__c', saclConfig.targetObject, 
            'parishes target object should be Sensitive_Area_Review__c');
        Test.stopTest();
    }
    
}