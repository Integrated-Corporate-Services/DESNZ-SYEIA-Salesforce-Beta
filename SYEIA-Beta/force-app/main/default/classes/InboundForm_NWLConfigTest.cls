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

        Assert.isTrue(mappingsByTarget.containsKey('Notice_to_Remove_Date__c'),
            'Should map notice to remove date');
        Assert.areEqual(
            InboundForm_MappingConfig.DataType.DATE_TYPE,
            mappingsByTarget.get('Notice_to_Remove_Date__c').dataType,
            'Notice to remove date should be DATE_TYPE'
        );

        Assert.isTrue(mappingsByTarget.containsKey('Written_Removal_Notice_Issue_Date__c'),
            'Should map legacy written removal notice issue date for downstream automation');
        Assert.areEqual(
            'sections.applicationDetails.notice_to_remove_date',
            mappingsByTarget.get('Written_Removal_Notice_Issue_Date__c').jsonPath,
            'Written removal notice issue date should come from notice_to_remove_date'
        );

        Assert.isTrue(mappingsByTarget.containsKey('Notice_Clearly_Refers_to_Line_Removal__c'),
            'Should map notice clarity answer');
        Assert.areEqual(
            InboundForm_MappingConfig.DataType.BOOLEAN_YES_NO,
            mappingsByTarget.get('Notice_Clearly_Refers_to_Line_Removal__c').dataType,
            'Notice clarity should be BOOLEAN_YES_NO'
        );

        Assert.isTrue(mappingsByTarget.containsKey('Standard_15_Year_Term__c'),
            'Should map standard 15 year term answer');
        Assert.areEqual(
            'No',
            mappingsByTarget.get('Standard_15_Year_Term__c').booleanTrueValue,
            'different_term_requested=true should map to No'
        );
        Assert.areEqual(
            'Yes',
            mappingsByTarget.get('Standard_15_Year_Term__c').booleanFalseValue,
            'different_term_requested=false should map to Yes'
        );

        Assert.isTrue(mappingsByTarget.containsKey('Any_Other_Important_Information__c'),
            'Should map has other important information flag'
        );

        Assert.isTrue(mappingsByTarget.containsKey('Description_of_Important_Information__c'),
            'Should map other information details text'
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
        Assert.isTrue(collectionNames.contains('Applicants'),
            'Applicants collection should exist');
        Assert.isTrue(collectionNames.contains('ApplicantAddresses'),
            'ApplicantAddresses collection should exist');
        Assert.isTrue(collectionNames.contains('LandDetails'),
            'LandDetails collection should exist');
        Assert.isTrue(collectionNames.contains('SiteAddress'),
            'SiteAddress collection should exist');
        Assert.isTrue(collectionNames.contains('payments'), 'payments collection should exist');

        InboundForm_MappingConfig.CollectionConfig siteAddressConfig;
        for (InboundForm_MappingConfig.CollectionConfig coll : config.collections) {
            if (coll.collectionName == 'SiteAddress') {
                siteAddressConfig = coll;
                break;
            }
        }

        Assert.isNotNull(siteAddressConfig, 'SiteAddress config should be present');

        Map<String, InboundForm_MappingConfig.FieldMapping> siteAddressMappingsByTarget =
            new Map<String, InboundForm_MappingConfig.FieldMapping>();

        for (InboundForm_MappingConfig.FieldMapping mapping : siteAddressConfig.fieldMappings) {
            siteAddressMappingsByTarget.put(mapping.targetField, mapping);
        }

        Assert.isTrue(siteAddressMappingsByTarget.containsKey('Address_Line1__c'),
            'Site address line should be mapped for NWL payload site_address');
        Assert.areEqual(
            'site_address.line1',
            siteAddressMappingsByTarget.get('Address_Line1__c').jsonPath,
            'Site address line mapping should come from site_address'
        );

        Assert.isTrue(siteAddressMappingsByTarget.containsKey('Address_Line_2__c'),
            'Site address line 2 should be mapped for NWL payload site_address');
        Assert.areEqual(
            'site_address.line2',
            siteAddressMappingsByTarget.get('Address_Line_2__c').jsonPath,
            'Site address line 2 mapping should come from site_address.line2'
        );

        Assert.isTrue(siteAddressMappingsByTarget.containsKey('County__c'),
            'Site address county should be mapped for NWL payload site_address');
        Assert.areEqual(
            'site_address.county',
            siteAddressMappingsByTarget.get('County__c').jsonPath,
            'Site address county mapping should come from site_address.county'
        );

        Assert.isTrue(siteAddressMappingsByTarget.containsKey('Postcode__c'),
            'Site address postcode should be mapped for NWL payload site_address');
        Assert.areEqual(
            'site_address.postcode',
            siteAddressMappingsByTarget.get('Postcode__c').jsonPath,
            'Site address postcode mapping should come from site_address.postcode'
        );

        Assert.isTrue(siteAddressMappingsByTarget.containsKey('Town_City__c'),
            'Site address town city should be mapped for NWL payload site_address');
        Assert.areEqual(
            'site_address.town_city',
            siteAddressMappingsByTarget.get('Town_City__c').jsonPath,
            'Site address town city mapping should come from site_address.town_city'
        );

        Assert.isTrue(siteAddressMappingsByTarget.containsKey('Country__c'),
            'Site address country should be mapped from landDetails.country');
        Assert.areEqual(
            'country',
            siteAddressMappingsByTarget.get('Country__c').jsonPath,
            'Site address country mapping should come from country'
        );

        InboundForm_MappingConfig.CollectionConfig applicantConfig;
        for (InboundForm_MappingConfig.CollectionConfig coll : config.collections) {
            if (coll.collectionName == 'Applicants') {
                applicantConfig = coll;
                break;
            }
        }

        Assert.isNotNull(applicantConfig, 'Applicants config should be present');

        Map<String, InboundForm_MappingConfig.FieldMapping> applicantMappingsByTarget =
            new Map<String, InboundForm_MappingConfig.FieldMapping>();
        for (InboundForm_MappingConfig.FieldMapping mapping : applicantConfig.fieldMappings) {
            applicantMappingsByTarget.put(mapping.targetField, mapping);
        }

        Assert.areEqual(
            'sections.applicantDetails',
            applicantConfig.jsonPath,
            'Applicants should map from sections.applicantDetails'
        );
        Assert.areEqual(
            'Organisation',
            applicantConfig.targetRecordType,
            'Applicants should use Organisation record type'
        );
        Assert.isTrue(applicantMappingsByTarget.containsKey('Name'),
            'Applicant name should be mapped');
        Assert.areEqual(
            'applicant_name',
            applicantMappingsByTarget.get('Name').jsonPath,
            'Applicant name should map from applicant_name'
        );
        Assert.isTrue(applicantMappingsByTarget.containsKey('Email__c'),
            'Applicant email should be mapped');
        Assert.areEqual(
            'email',
            applicantMappingsByTarget.get('Email__c').jsonPath,
            'Applicant email should map from email'
        );

        InboundForm_MappingConfig.CollectionConfig applicantAddressConfig;
        for (InboundForm_MappingConfig.CollectionConfig coll : config.collections) {
            if (coll.collectionName == 'ApplicantAddresses') {
                applicantAddressConfig = coll;
                break;
            }
        }

        Assert.isNotNull(applicantAddressConfig, 'ApplicantAddresses config should be present');
        Assert.areEqual(
            'sections.applicantDetails',
            applicantAddressConfig.jsonPath,
            'ApplicantAddresses should map from sections.applicantDetails'
        );
    }
}
