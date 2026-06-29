/**
 * NWL form type configuration. Defines JSON paths and field mappings for Necessary Wayleaves.
 */
public class InboundForm_NWLConfig {

    /**
     * Get the complete NWL configuration.
     */
    public static InboundForm_MappingConfig.FormTypeConfig getConfig() {
        InboundForm_MappingConfig.FormTypeConfig config =
            new InboundForm_MappingConfig.FormTypeConfig()
                .setFormType('NWL')
                .setDescription('Necessary Wayleaves')
                .setPrimaryObject('Case__c')
                .setPrimaryRecordType('Necessary_Wayleaves')
                .setApplicationIdField('AWS_Application_Id__c')
                .setApplicationIdJsonPath('applicationId')
                .setNameJsonPath('desnzRef')
                .setStatusField('Status__c')
                .setDefaultStatus('New')
                .setHandlerClass(InboundForm_NWLHandler.class);

        addCaseFieldMappings(config);
        addCollectionConfigs(config);

        return config;
    }

    private static void addCaseFieldMappings(InboundForm_MappingConfig.FormTypeConfig config) {
        config.addFieldMapping(InboundForm_MappingConfig.stringField(
            'desnzRef',
            'Name'
        ));

        config.addFieldMapping(InboundForm_MappingConfig.stringField(
            'sections.applicationDetails.application_type',
            'Application_Type__c'
        ));

        config.addFieldMapping(InboundForm_MappingConfig.dateField(
            'sections.applicationDetails.notice_to_remove_date',
            'Written_Removal_Notice_Issue_Date__c'
        ));

        config.addFieldMapping(InboundForm_MappingConfig.dateField(
            'sections.applicationDetails.notice_to_terminate_date',
            'Written_Termination_Notice_Issue_Date__c'
        ));

        config.addFieldMapping(InboundForm_MappingConfig.yesNoField(
            'sections.landDetails.is_registered',
            'Land__c'
        ));

        config.addFieldMapping(InboundForm_MappingConfig.yesNoField(
            'sections.landDetails.visible_from_road',
            'Equipment_Visible_from_Public_Road__c'
        ));

        config.addFieldMapping(InboundForm_MappingConfig.booleanField(
            'sections.additionalInformation.has_related_applications',
            'Are_There_Any_Other_Related_Applications__c'
        ));

        config.addFieldMapping(InboundForm_MappingConfig.stringField(
            'sections.additionalInformation.related_applications_details',
            'Details_of_All_Related_Application__c'
        ));

        config.addFieldMapping(InboundForm_MappingConfig.stringField(
            'sections.additionalInformation.other_information_details',
            'Application_Statement__c'
        ));

        config.addFieldMapping(InboundForm_MappingConfig.stringField(
            'sections.applicationDetails.grounds_for_application',
            'Description__c'
        ));
    }

    private static void addCollectionConfigs(InboundForm_MappingConfig.FormTypeConfig config) {
        config.addCollection(getObjectorConfig());
        config.addCollection(getLandownerConfig());
        config.addCollection(getRepresentativeConfig());
        config.addCollection(getObjectorAddressConfig());
        config.addCollection(getLandownerAddressConfig());
        config.addCollection(getRepresentativeAddressConfig());
        config.addCollection(getPaymentConfig());
    }

    private static InboundForm_MappingConfig.CollectionConfig getObjectorConfig() {
        InboundForm_MappingConfig.CollectionConfig objectors =
            new InboundForm_MappingConfig.CollectionConfig()
                .setCollectionName('Objectors')
                .setJsonPath('sections.objectorDetails')
                .setTargetObject('Party__c')
                .setTargetRecordType('Individual')
                .setParentLookupField('Case__c')
                .setParentLinkSfField('Application_Party_Id__c')
                .setProcessingOrder(20);

        objectors.addFieldMapping(InboundForm_MappingConfig.stringField('objector_name', 'Name'));
        objectors.addFieldMapping(InboundForm_MappingConfig.stringField('objector_title', 'Salutation__c'));
        objectors.addFieldMapping(InboundForm_MappingConfig.stringField('objector_email', 'Email__c'));
        objectors.addFieldMapping(InboundForm_MappingConfig.stringField('objector_phone', 'Phone__c'));
        objectors.addFieldMapping(InboundForm_MappingConfig.defaultValue('Individual', 'Party_Type__c'));
        objectors.addFieldMapping(InboundForm_MappingConfig.defaultValue(
            'NWL_OBJECTOR',
            'Application_Party_Id__c'
        ));

        return objectors;
    }

    private static InboundForm_MappingConfig.CollectionConfig getLandownerConfig() {
        InboundForm_MappingConfig.CollectionConfig landowners =
            new InboundForm_MappingConfig.CollectionConfig()
                .setCollectionName('Landowners')
                .setJsonPath('sections.landownerDetails')
                .setTargetObject('Party__c')
                .setTargetRecordType('Individual')
                .setParentLookupField('Case__c')
                .setParentLinkSfField('Application_Party_Id__c')
                .setProcessingOrder(21);

        landowners.addFieldMapping(InboundForm_MappingConfig.stringField('landowner_name', 'Name'));
        landowners.addFieldMapping(InboundForm_MappingConfig.stringField('landowner_title', 'Salutation__c'));
        landowners.addFieldMapping(InboundForm_MappingConfig.stringField('landowner_email', 'Email__c'));
        landowners.addFieldMapping(InboundForm_MappingConfig.stringField('landowner_phone', 'Phone__c'));
        landowners.addFieldMapping(InboundForm_MappingConfig.defaultValue('Landowner', 'Party_Type__c'));
        landowners.addFieldMapping(InboundForm_MappingConfig.defaultValue(
            'NWL_LANDOWNER',
            'Application_Party_Id__c'
        ));

        return landowners;
    }

    private static InboundForm_MappingConfig.CollectionConfig getRepresentativeConfig() {
        InboundForm_MappingConfig.CollectionConfig reps =
            new InboundForm_MappingConfig.CollectionConfig()
                .setCollectionName('LandownerRepresentatives')
                .setJsonPath('sections.representativeDetails')
                .setTargetObject('Party__c')
                .setTargetRecordType('Individual')
                .setParentLookupField('Case__c')
                .setParentLinkSfField('Application_Party_Id__c')
                .setProcessingOrder(22);

        reps.addFieldMapping(InboundForm_MappingConfig.stringField('representative_name', 'Name'));
        reps.addFieldMapping(InboundForm_MappingConfig.stringField('representative_title', 'Salutation__c'));
        reps.addFieldMapping(InboundForm_MappingConfig.stringField('representative_email', 'Email__c'));
        reps.addFieldMapping(InboundForm_MappingConfig.stringField('representative_phone', 'Phone__c'));
        reps.addFieldMapping(InboundForm_MappingConfig.defaultValue(
            'Landowner Representative',
            'Party_Type__c'
        ));
        reps.addFieldMapping(InboundForm_MappingConfig.defaultValue(
            'NWL_REPRESENTATIVE',
            'Application_Party_Id__c'
        ));

        return reps;
    }

    private static InboundForm_MappingConfig.CollectionConfig getObjectorAddressConfig() {
        InboundForm_MappingConfig.CollectionConfig addresses =
            new InboundForm_MappingConfig.CollectionConfig()
                .setCollectionName('ObjectorAddresses')
                .setJsonPath('sections.objectorDetails')
                .setTargetObject('Address__c')
                .setParentLookupField('Party__c')
                .setParentCollection('Objectors')
                .setParentLinkJsonField('application_party_id')
                .setParentLinkSfField('Application_Party_Id__c')
                .setChildLinkSfField('Application_Party_Identification__c')
                .setProcessingOrder(30);

        addresses.addFieldMapping(InboundForm_MappingConfig.stringField(
            'objector_address_line1',
            'Address_Line1__c'
        ));
        addresses.addFieldMapping(InboundForm_MappingConfig.stringField(
            'objector_address_line2',
            'Address_Line_2__c'
        ));
        addresses.addFieldMapping(InboundForm_MappingConfig.stringField(
            'objector_postcode',
            'Postcode__c'
        ));
        addresses.addFieldMapping(InboundForm_MappingConfig.defaultValue(
            'NWL_OBJECTOR',
            'Application_Party_Identification__c'
        ));

        return addresses;
    }

    private static InboundForm_MappingConfig.CollectionConfig getLandownerAddressConfig() {
        InboundForm_MappingConfig.CollectionConfig addresses =
            new InboundForm_MappingConfig.CollectionConfig()
                .setCollectionName('LandownerAddresses')
                .setJsonPath('sections.landownerDetails')
                .setTargetObject('Address__c')
                .setParentLookupField('Party__c')
                .setParentCollection('Landowners')
                .setParentLinkJsonField('application_party_id')
                .setParentLinkSfField('Application_Party_Identification__c')
                .setChildLinkSfField('Application_Party_Identification__c')
                .setProcessingOrder(31);

        addresses.addFieldMapping(InboundForm_MappingConfig.stringField(
            'landowner_address_line1',
            'Address_Line1__c'
        ));
        addresses.addFieldMapping(InboundForm_MappingConfig.stringField(
            'landowner_address_line2',
            'Address_Line_2__c'
        ));
        addresses.addFieldMapping(InboundForm_MappingConfig.stringField(
            'landowner_postcode',
            'Postcode__c'
        ));
        addresses.addFieldMapping(InboundForm_MappingConfig.defaultValue(
            'NWL_LANDOWNER',
            'Application_Party_Identification__c'
        ));

        return addresses;
    }

    private static InboundForm_MappingConfig.CollectionConfig getRepresentativeAddressConfig() {
        InboundForm_MappingConfig.CollectionConfig addresses =
            new InboundForm_MappingConfig.CollectionConfig()
                .setCollectionName('LandownerRepresentativeAddresses')
                .setJsonPath('sections.representativeDetails')
                .setTargetObject('Address__c')
                .setParentLookupField('Party__c')
                .setParentCollection('LandownerRepresentatives')
                .setParentLinkJsonField('application_party_id')
                .setParentLinkSfField('Application_Party_Identification__c')
                .setChildLinkSfField('Application_Party_Identification__c')
                .setProcessingOrder(32);

        addresses.addFieldMapping(InboundForm_MappingConfig.stringField(
            'representative_address_line1',
            'Address_Line1__c'
        ));
        addresses.addFieldMapping(InboundForm_MappingConfig.stringField(
            'representative_address_line2',
            'Address_Line_2__c'
        ));
        addresses.addFieldMapping(InboundForm_MappingConfig.stringField(
            'representative_postcode',
            'Postcode__c'
        ));
        addresses.addFieldMapping(InboundForm_MappingConfig.defaultValue(
            'NWL_REPRESENTATIVE',
            'Application_Party_Identification__c'
        ));

        return addresses;
    }

    private static InboundForm_MappingConfig.CollectionConfig getPaymentConfig() {
        InboundForm_MappingConfig.CollectionConfig payments =
            new InboundForm_MappingConfig.CollectionConfig()
                .setCollectionName('payments')
                .setJsonPath('sections.payment')
                .setTargetObject('Payment__c')
                .setParentLookupField('Case__c')
                .setParentLinkSfField('Payment_Id__c')
                .setProcessingOrder(60);

        payments.addFieldMapping(InboundForm_MappingConfig.stringField('payment_id', 'Payment_Id__c'));
        payments.addFieldMapping(InboundForm_MappingConfig.stringField('kind', 'Payment_Method__c'));
        payments.addFieldMapping(InboundForm_MappingConfig.currencyField('amount', 'Total_Amount__c'));
        payments.addFieldMapping(InboundForm_MappingConfig.stringField('status', 'Status__c'));
        payments.addFieldMapping(InboundForm_MappingConfig.stringField('provider', 'Provider__c'));
        payments.addFieldMapping(InboundForm_MappingConfig.stringField('description', 'Description__c'));

        return payments;
    }
}