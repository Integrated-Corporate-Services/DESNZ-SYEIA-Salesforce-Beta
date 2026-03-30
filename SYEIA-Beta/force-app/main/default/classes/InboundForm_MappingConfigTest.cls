/**
 * Test class for InboundForm_MappingConfig.
 * Tests configuration classes, fluent builders, and factory methods.
 */
@IsTest
private class InboundForm_MappingConfigTest {
    
    // ========================================================================
    // FORM TYPE CONFIG TESTS
    // ========================================================================
    
    @IsTest
    static void testFormTypeConfig_DefaultValues() {
        Test.startTest();
        InboundForm_MappingConfig.FormTypeConfig config = 
            new InboundForm_MappingConfig.FormTypeConfig();
        Test.stopTest();
        
        Assert.isTrue(config.active, 'Active should default to true');
        Assert.isNotNull(config.fieldMappings, 'Field mappings should be initialized');
        Assert.isTrue(config.fieldMappings.isEmpty(), 'Field mappings should be empty');
        Assert.isNotNull(config.collections, 'Collections should be initialized');
        Assert.isTrue(config.collections.isEmpty(), 'Collections should be empty');
        Assert.areEqual('Inbound_Request__c', config.inboundRequestLookupField, 
            'Default inbound request lookup field');
        Assert.areEqual('applicationId', config.applicationIdJsonPath, 
            'Default application ID JSON path');
        Assert.areEqual('Name', config.nameField, 'Default name field');
    }
    
    @IsTest
    static void testFormTypeConfig_FluentBuilders() {
        Test.startTest();
        InboundForm_MappingConfig.FormTypeConfig config = 
            new InboundForm_MappingConfig.FormTypeConfig()
                .setFormType('TEST')
                .setDescription('Test Form')
                .setPrimaryObject('Account')
                .setPrimaryRecordType('TestRT')
                .setApplicationIdField('External_Id__c')
                .setApplicationIdJsonPath('externalId')
                .setNameJsonPath('name')
                .setStatusField('Status__c')
                .setDefaultStatus('New')
                .setActive(false);
        Test.stopTest();
        
        Assert.areEqual('TEST', config.formType, 'Form type should be set');
        Assert.areEqual('Test Form', config.description, 'Description should be set');
        Assert.areEqual('Account', config.primaryObject, 'Primary object should be set');
        Assert.areEqual('TestRT', config.primaryRecordType, 'Primary record type should be set');
        Assert.areEqual('External_Id__c', config.applicationIdField, 'App ID field should be set');
        Assert.areEqual('externalId', config.applicationIdJsonPath, 'App ID JSON path should be set');
        Assert.areEqual('name', config.nameJsonPath, 'Name JSON path should be set');
        Assert.areEqual('Status__c', config.statusField, 'Status field should be set');
        Assert.areEqual('New', config.defaultStatus, 'Default status should be set');
        Assert.isFalse(config.active, 'Active should be false');
    }
    
    @IsTest
    static void testFormTypeConfig_SetHandlerClass() {
        Test.startTest();
        InboundForm_MappingConfig.FormTypeConfig config = 
            new InboundForm_MappingConfig.FormTypeConfig()
                .setHandlerClass(InboundForm_S37Handler.class);
        Test.stopTest();
        
        Assert.areEqual(InboundForm_S37Handler.class, config.handlerClass, 
            'Handler class should be set');
    }
    
    @IsTest
    static void testFormTypeConfig_AddFieldMapping() {
        InboundForm_MappingConfig.FormTypeConfig config = 
            new InboundForm_MappingConfig.FormTypeConfig();
        InboundForm_MappingConfig.FieldMapping mapping = 
            new InboundForm_MappingConfig.FieldMapping('json.path', 'Sf_Field__c');
        
        Test.startTest();
        config.addFieldMapping(mapping);
        Test.stopTest();
        
        Assert.areEqual(1, config.fieldMappings.size(), 'Should have one field mapping');
        Assert.areEqual('json.path', config.fieldMappings[0].jsonPath, 'JSON path should match');
    }
    
    @IsTest
    static void testFormTypeConfig_AddCollection() {
        InboundForm_MappingConfig.FormTypeConfig config = 
            new InboundForm_MappingConfig.FormTypeConfig();
        InboundForm_MappingConfig.CollectionConfig collection = 
            new InboundForm_MappingConfig.CollectionConfig()
                .setCollectionName('TestCollection');
        
        Test.startTest();
        config.addCollection(collection);
        Test.stopTest();
        
        Assert.areEqual(1, config.collections.size(), 'Should have one collection');
        Assert.areEqual('TestCollection', config.collections[0].collectionName, 
            'Collection name should match');
    }
    
    // ========================================================================
    // COLLECTION CONFIG TESTS
    // ========================================================================
    
    @IsTest
    static void testCollectionConfig_DefaultValues() {
        Test.startTest();
        InboundForm_MappingConfig.CollectionConfig config = 
            new InboundForm_MappingConfig.CollectionConfig();
        Test.stopTest();
        
        Assert.isFalse(config.isNestedArray, 'isNestedArray should default to false');
        Assert.isFalse(config.isSimpleArray, 'isSimpleArray should default to false');
        Assert.areEqual(100, config.processingOrder, 'Processing order should default to 100');
        Assert.isNotNull(config.fieldMappings, 'Field mappings should be initialized');
    }
    
    @IsTest
    static void testCollectionConfig_FluentBuilders() {
        Test.startTest();
        InboundForm_MappingConfig.CollectionConfig config = 
            new InboundForm_MappingConfig.CollectionConfig()
                .setCollectionName('Routes')
                .setJsonPath('sections.routes')
                .setTargetObject('Route__c')
                .setTargetRecordType('Standard')
                .setParentLookupField('Case__c')
                .setParentCollection('ParentColl')
                .setParentLinkJsonField('parent_id')
                .setParentLinkSfField('Parent_Id__c')
                .setChildLinkSfField('Child_Id__c')
                .setIsNestedArray(true)
                .setNestedArrayPath('items')
                .setIsSimpleArray(false)
                .setSimpleArrayTargetField('Name')
                .setProcessingOrder(50);
        Test.stopTest();
        
        Assert.areEqual('Routes', config.collectionName, 'Collection name should be set');
        Assert.areEqual('sections.routes', config.jsonPath, 'JSON path should be set');
        Assert.areEqual('Route__c', config.targetObject, 'Target object should be set');
        Assert.areEqual('Standard', config.targetRecordType, 'Target record type should be set');
        Assert.areEqual('Case__c', config.parentLookupField, 'Parent lookup field should be set');
        Assert.areEqual('ParentColl', config.parentCollection, 'Parent collection should be set');
        Assert.areEqual('parent_id', config.parentLinkJsonField, 'Parent link JSON field should be set');
        Assert.areEqual('Parent_Id__c', config.parentLinkSfField, 'Parent link SF field should be set');
        Assert.areEqual('Child_Id__c', config.childLinkSfField, 'Child link SF field should be set');
        Assert.isTrue(config.isNestedArray, 'isNestedArray should be true');
        Assert.areEqual('items', config.nestedArrayPath, 'Nested array path should be set');
        Assert.isFalse(config.isSimpleArray, 'isSimpleArray should be false');
        Assert.areEqual('Name', config.simpleArrayTargetField, 'Simple array target field should be set');
        Assert.areEqual(50, config.processingOrder, 'Processing order should be 50');
    }
    
    @IsTest
    static void testCollectionConfig_AddFieldMapping() {
        InboundForm_MappingConfig.CollectionConfig config = 
            new InboundForm_MappingConfig.CollectionConfig();
        InboundForm_MappingConfig.FieldMapping mapping = 
            new InboundForm_MappingConfig.FieldMapping('name', 'Name');
        
        Test.startTest();
        config.addFieldMapping(mapping);
        Test.stopTest();
        
        Assert.areEqual(1, config.fieldMappings.size(), 'Should have one field mapping');
    }
    
    @IsTest
    static void testCollectionConfig_CompareTo() {
        InboundForm_MappingConfig.CollectionConfig config1 = 
            new InboundForm_MappingConfig.CollectionConfig().setProcessingOrder(10);
        InboundForm_MappingConfig.CollectionConfig config2 = 
            new InboundForm_MappingConfig.CollectionConfig().setProcessingOrder(50);
        InboundForm_MappingConfig.CollectionConfig config3 = 
            new InboundForm_MappingConfig.CollectionConfig().setProcessingOrder(10);
        
        Test.startTest();
        Integer result1 = config1.compareTo(config2);
        Integer result2 = config2.compareTo(config1);
        Integer result3 = config1.compareTo(config3);
        Test.stopTest();
        
        Assert.isTrue(result1 < 0, 'Config1 (10) should be less than config2 (50)');
        Assert.isTrue(result2 > 0, 'Config2 (50) should be greater than config1 (10)');
        Assert.areEqual(0, result3, 'Config1 (10) should equal config3 (10)');
    }
    
    @IsTest
    static void testCollectionConfig_CompareTo_NullProcessingOrder() {
        InboundForm_MappingConfig.CollectionConfig config1 = 
            new InboundForm_MappingConfig.CollectionConfig();
        config1.processingOrder = null;
        InboundForm_MappingConfig.CollectionConfig config2 = 
            new InboundForm_MappingConfig.CollectionConfig().setProcessingOrder(50);
        
        Test.startTest();
        Integer result = config1.compareTo(config2);
        Test.stopTest();
        
        Assert.isTrue(result > 0, 'Null processing order should default to 100');
    }
    
    @IsTest
    static void testCollectionConfig_Sorting() {
        List<InboundForm_MappingConfig.CollectionConfig> configs = 
            new List<InboundForm_MappingConfig.CollectionConfig>{
                new InboundForm_MappingConfig.CollectionConfig().setProcessingOrder(30),
                new InboundForm_MappingConfig.CollectionConfig().setProcessingOrder(10),
                new InboundForm_MappingConfig.CollectionConfig().setProcessingOrder(20)
            };
        
        Test.startTest();
        configs.sort();
        Test.stopTest();
        
        Assert.areEqual(10, configs[0].processingOrder, 'First should be 10');
        Assert.areEqual(20, configs[1].processingOrder, 'Second should be 20');
        Assert.areEqual(30, configs[2].processingOrder, 'Third should be 30');
    }
    
    // ========================================================================
    // FIELD MAPPING TESTS
    // ========================================================================
    
    @IsTest
    static void testFieldMapping_DefaultConstructor() {
        Test.startTest();
        InboundForm_MappingConfig.FieldMapping mapping = 
            new InboundForm_MappingConfig.FieldMapping();
        Test.stopTest();
        
        Assert.areEqual(InboundForm_MappingConfig.DataType.STRING_TYPE, mapping.dataType, 
            'Default data type should be STRING_TYPE');
        Assert.isFalse(mapping.isRequired, 'isRequired should default to false');
        Assert.areEqual('Yes', mapping.booleanTrueValue, 'Default true value');
        Assert.areEqual('No', mapping.booleanFalseValue, 'Default false value');
    }
    
    @IsTest
    static void testFieldMapping_TwoArgConstructor() {
        Test.startTest();
        InboundForm_MappingConfig.FieldMapping mapping = 
            new InboundForm_MappingConfig.FieldMapping('json.path', 'Target_Field__c');
        Test.stopTest();
        
        Assert.areEqual('json.path', mapping.jsonPath, 'JSON path should be set');
        Assert.areEqual('Target_Field__c', mapping.targetField, 'Target field should be set');
        Assert.areEqual(InboundForm_MappingConfig.DataType.STRING_TYPE, mapping.dataType, 
            'Data type should default to STRING_TYPE');
    }
    
    @IsTest
    static void testFieldMapping_ThreeArgConstructor() {
        Test.startTest();
        InboundForm_MappingConfig.FieldMapping mapping = 
            new InboundForm_MappingConfig.FieldMapping(
                'json.path', 
                'Target_Field__c',
                InboundForm_MappingConfig.DataType.INTEGER_TYPE
            );
        Test.stopTest();
        
        Assert.areEqual('json.path', mapping.jsonPath, 'JSON path should be set');
        Assert.areEqual('Target_Field__c', mapping.targetField, 'Target field should be set');
        Assert.areEqual(InboundForm_MappingConfig.DataType.INTEGER_TYPE, mapping.dataType, 
            'Data type should be INTEGER_TYPE');
    }
    
    @IsTest
    static void testFieldMapping_FluentBuilders() {
        Test.startTest();
        InboundForm_MappingConfig.FieldMapping mapping = 
            new InboundForm_MappingConfig.FieldMapping()
                .setJsonPath('some.path')
                .setTargetField('Some_Field__c')
                .setDataType(InboundForm_MappingConfig.DataType.BOOLEAN_YES_NO)
                .setBooleanTrueValue('Active')
                .setBooleanFalseValue('Inactive')
                .setIsRequired(true)
                .setDefaultValue('default');
        Test.stopTest();
        
        Assert.areEqual('some.path', mapping.jsonPath, 'JSON path should be set');
        Assert.areEqual('Some_Field__c', mapping.targetField, 'Target field should be set');
        Assert.areEqual(InboundForm_MappingConfig.DataType.BOOLEAN_YES_NO, mapping.dataType, 
            'Data type should be BOOLEAN_YES_NO');
        Assert.areEqual('Active', mapping.booleanTrueValue, 'Boolean true value should be set');
        Assert.areEqual('Inactive', mapping.booleanFalseValue, 'Boolean false value should be set');
        Assert.isTrue(mapping.isRequired, 'isRequired should be true');
        Assert.areEqual('default', mapping.defaultValue, 'Default value should be set');
    }
    
    // ========================================================================
    // FACTORY METHOD TESTS
    // ========================================================================
    
    @IsTest
    static void testStringField() {
        Test.startTest();
        InboundForm_MappingConfig.FieldMapping mapping = 
            InboundForm_MappingConfig.stringField('json.path', 'Target__c');
        Test.stopTest();
        
        Assert.areEqual('json.path', mapping.jsonPath, 'JSON path should be set');
        Assert.areEqual('Target__c', mapping.targetField, 'Target field should be set');
        Assert.areEqual(InboundForm_MappingConfig.DataType.STRING_TYPE, mapping.dataType, 
            'Data type should be STRING_TYPE');
    }
    
    @IsTest
    static void testIntegerField() {
        Test.startTest();
        InboundForm_MappingConfig.FieldMapping mapping = 
            InboundForm_MappingConfig.integerField('count', 'Count__c');
        Test.stopTest();
        
        Assert.areEqual(InboundForm_MappingConfig.DataType.INTEGER_TYPE, mapping.dataType, 
            'Data type should be INTEGER_TYPE');
    }
    
    @IsTest
    static void testDecimalField() {
        Test.startTest();
        InboundForm_MappingConfig.FieldMapping mapping = 
            InboundForm_MappingConfig.decimalField('amount', 'Amount__c');
        Test.stopTest();
        
        Assert.areEqual(InboundForm_MappingConfig.DataType.DECIMAL_TYPE, mapping.dataType, 
            'Data type should be DECIMAL_TYPE');
    }
    
    @IsTest
    static void testBooleanField() {
        Test.startTest();
        InboundForm_MappingConfig.FieldMapping mapping = 
            InboundForm_MappingConfig.booleanField('active', 'Is_Active__c');
        Test.stopTest();
        
        Assert.areEqual(InboundForm_MappingConfig.DataType.BOOLEAN_TYPE, mapping.dataType, 
            'Data type should be BOOLEAN_TYPE');
    }
    
    @IsTest
    static void testYesNoField() {
        Test.startTest();
        InboundForm_MappingConfig.FieldMapping mapping = 
            InboundForm_MappingConfig.yesNoField('confirmed', 'Confirmed__c');
        Test.stopTest();
        
        Assert.areEqual(InboundForm_MappingConfig.DataType.BOOLEAN_YES_NO, mapping.dataType, 
            'Data type should be BOOLEAN_YES_NO');
    }
    
    @IsTest
    static void testDateField() {
        Test.startTest();
        InboundForm_MappingConfig.FieldMapping mapping = 
            InboundForm_MappingConfig.dateField('startDate', 'Start_Date__c');
        Test.stopTest();
        
        Assert.areEqual(InboundForm_MappingConfig.DataType.DATE_TYPE, mapping.dataType, 
            'Data type should be DATE_TYPE');
    }
    
    @IsTest
    static void testDatetimeField() {
        Test.startTest();
        InboundForm_MappingConfig.FieldMapping mapping = 
            InboundForm_MappingConfig.datetimeField('createdAt', 'Created_At__c');
        Test.stopTest();
        
        Assert.areEqual(InboundForm_MappingConfig.DataType.DATETIME_TYPE, mapping.dataType, 
            'Data type should be DATETIME_TYPE');
    }
    
    @IsTest
    static void testRequiredString() {
        Test.startTest();
        InboundForm_MappingConfig.FieldMapping mapping = 
            InboundForm_MappingConfig.requiredString('name', 'Name');
        Test.stopTest();
        
        Assert.areEqual(InboundForm_MappingConfig.DataType.STRING_TYPE, mapping.dataType, 
            'Data type should be STRING_TYPE');
        Assert.isTrue(mapping.isRequired, 'isRequired should be true');
    }
    
    // ========================================================================
    // DATA TYPE ENUM TESTS
    // ========================================================================
    
    @IsTest
    static void testDataTypeEnum_AllValues() {
        Test.startTest();
        InboundForm_MappingConfig.DataType stringType = 
            InboundForm_MappingConfig.DataType.STRING_TYPE;
        InboundForm_MappingConfig.DataType intType = 
            InboundForm_MappingConfig.DataType.INTEGER_TYPE;
        InboundForm_MappingConfig.DataType decType = 
            InboundForm_MappingConfig.DataType.DECIMAL_TYPE;
        InboundForm_MappingConfig.DataType boolType = 
            InboundForm_MappingConfig.DataType.BOOLEAN_TYPE;
        InboundForm_MappingConfig.DataType yesNoType = 
            InboundForm_MappingConfig.DataType.BOOLEAN_YES_NO;
        InboundForm_MappingConfig.DataType currencyType = 
            InboundForm_MappingConfig.DataType.CURRENCY_TYPE;
        InboundForm_MappingConfig.DataType dateType = 
            InboundForm_MappingConfig.DataType.DATE_TYPE;
        InboundForm_MappingConfig.DataType dtType = 
            InboundForm_MappingConfig.DataType.DATETIME_TYPE;
        Test.stopTest();
        
        Assert.isNotNull(stringType, 'STRING_TYPE should exist');
        Assert.isNotNull(intType, 'INTEGER_TYPE should exist');
        Assert.isNotNull(decType, 'DECIMAL_TYPE should exist');
        Assert.isNotNull(boolType, 'BOOLEAN_TYPE should exist');
        Assert.isNotNull(yesNoType, 'BOOLEAN_YES_NO should exist');
        Assert.isNotNull(currencyType, 'CURRENCY_TYPE should exist');
        Assert.isNotNull(dateType, 'DATE_TYPE should exist');
        Assert.isNotNull(dtType, 'DATETIME_TYPE should exist');
    }
}