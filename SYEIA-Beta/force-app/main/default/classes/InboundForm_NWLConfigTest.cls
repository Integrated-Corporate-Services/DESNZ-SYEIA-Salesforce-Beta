/**
 * Test class for InboundForm_NWLConfig.
 */
@IsTest
private class InboundForm_NWLConfigTest {

    @IsTest
    static void testGetConfig_ReturnsValidConfig() {
        Test.startTest();
        InboundForm_MappingConfig.FormTypeConfig config = InboundForm_NWLConfig.getConfig();
        Test.stopTest();

        Assert.isNotNull(config, 'Config should not be null');
        Assert.areEqual('NWL', config.formType, 'Form type should be NWL');
        Assert.areEqual('Case__c', config.primaryObject, 'Primary object should be Case__c');
        Assert.areEqual('Necessary_Wayleaves', config.primaryRecordType,
            'Primary record type should be Necessary_Wayleaves');
        Assert.areEqual(InboundForm_NWLHandler.class, config.handlerClass,
            'Handler class should be InboundForm_NWLHandler');
    }

    @IsTest
    static void testGetConfig_HasKeyFieldMappings() {
        InboundForm_MappingConfig.FormTypeConfig config = InboundForm_NWLConfig.getConfig();

        Map<String, InboundForm_MappingConfig.FieldMapping> mappingsByTarget =
            new Map<String, InboundForm_MappingConfig.FieldMapping>();

        for (InboundForm_MappingConfig.FieldMapping mapping : config.fieldMappings) {
            mappingsByTarget.put(mapping.targetField, mapping);
        }

        Assert.isTrue(mappingsByTarget.containsKey('Application_Type__c'),
            'Should map application type');
        Assert.areEqual(
            'sections.applicationDetails.application_type',
            mappingsByTarget.get('Application_Type__c').jsonPath,
            'Application type path should match'
        );

        Assert.isTrue(mappingsByTarget.containsKey('Written_Removal_Notice_Issue_Date__c'),
            'Should map written removal notice date');
        Assert.areEqual(
            InboundForm_MappingConfig.DataType.DATE_TYPE,
            mappingsByTarget.get('Written_Removal_Notice_Issue_Date__c').dataType,
            'Written removal notice date should be DATE_TYPE'
        );

        Assert.isTrue(mappingsByTarget.containsKey('Land__c'),
            'Should map land registry answer');
        Assert.areEqual(
            InboundForm_MappingConfig.DataType.BOOLEAN_YES_NO,
            mappingsByTarget.get('Land__c').dataType,
            'Land__c should be BOOLEAN_YES_NO'
        );
    }

    @IsTest
    static void testGetConfig_HasCollections() {
        InboundForm_MappingConfig.FormTypeConfig config = InboundForm_NWLConfig.getConfig();

        Set<String> collectionNames = new Set<String>();
        for (InboundForm_MappingConfig.CollectionConfig coll : config.collections) {
            collectionNames.add(coll.collectionName);
        }

        Assert.isTrue(collectionNames.contains('Objectors'), 'Objectors collection should exist');
        Assert.isTrue(collectionNames.contains('Landowners'), 'Landowners collection should exist');
        Assert.isTrue(collectionNames.contains('LandownerRepresentatives'),
            'LandownerRepresentatives collection should exist');
        Assert.isTrue(collectionNames.contains('payments'), 'payments collection should exist');
    }
}
