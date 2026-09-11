/**
 * NWL form type configuration. Defines JSON paths and field mappings for Necessary Wayleaves.
 */
public class InboundForm_NWLConfig {

    /**
     * Get the complete NWL configuration.
     */
    public static InboundForm_MappingConfig.FormTypeConfig getConfig() {
        try {
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
                    .setDefaultStatus('Application Received')
                    .setHandlerClass(InboundForm_NWLHandler.class);

            addCaseFieldMappings(config);
            addCollectionConfigs(config);

            return config;
        } catch (Exception e) {
            Logger.error('Error building NWL form configuration: ' + e.getMessage());
            Logger.setScenario('InboundForm_NWLConfig.getConfig');
            Logger.saveLog();
            throw e;
        }
    }

    private static void addCaseFieldMappings(InboundForm_MappingConfig.FormTypeConfig config) {
        config.addFieldMapping(InboundForm_MappingConfig.stringField(
            'desnzRef',
            'Name'
        ));

        config.addFieldMapping(InboundForm_MappingConfig.dateField(
            'submittedAt', 
            'Date_of_Application__c'
        ));

        // Sections
        // Application Details
        config.addFieldMapping(InboundForm_MappingConfig.stringField(
            'sections.applicationDetails.application_type',
            'Application_Type__c'
        ));
        
        config.addFieldMapping(InboundForm_MappingConfig.stringField(
            'sections.applicationDetails.grounds_for_application',
            'Legislation_Applicable__c'
        ));

        config.addFieldMapping(InboundForm_MappingConfig.stringField(
            'sections.applicationDetails.wayleave_type',
            'Type_Of_NWL_That_Existed__c'
        ));

        config.addFieldMapping(InboundForm_MappingConfig.dateField(
            'sections.applicationDetails.wayleave_expiry_date',
            'Wayleave_Expiry_Date__c'
        ));

        config.addFieldMapping(InboundForm_MappingConfig.dateField(
            'sections.applicationDetails.notice_to_remove_date',
            'Notice_to_Remove_Date__c'
        ));
        
        config.addFieldMapping(InboundForm_MappingConfig.yesNoField(
            'sections.applicationDetails.termination_period_expired',
            'Termination_Period_Expired__c'
        ).setBooleanTrueValue('Yes').setBooleanFalseValue('No'));

        // Keep legacy NWL automation populated until all downstream flows use Notice_to_Remove_Date__c.
        config.addFieldMapping(InboundForm_MappingConfig.dateField(
            'sections.applicationDetails.notice_to_remove_date',
            'Written_Removal_Notice_Issue_Date__c'
        ));

        config.addFieldMapping(InboundForm_MappingConfig.dateField(
            'sections.applicationDetails.notice_to_terminate_date',
            'Written_Termination_Notice_Issue_Date__c'
        ));

        config.addFieldMapping(InboundForm_MappingConfig.dateField(
            'sections.applicationDetails.wayleave_offer_date',
            'Wayleave_Notice_Date__c'
        ));

        config.addFieldMapping(InboundForm_MappingConfig.stringField(
            'sections.applicantDetails.applicant_name',
            'DNO_Name__c'
        ));

        config.addFieldMapping(InboundForm_MappingConfig.stringField(
            'sections.applicantDetails.operator_ref',
            'Applicant_Reference__c'
        ));

        // Notice Compliance
        config.addFieldMapping(InboundForm_MappingConfig.yesNoField(
            'sections.noticeCompliance.notice_clearly_refers_to_removal',
            'Notice_Clearly_Refers_to_Line_Removal__c'
        ));

        config.addFieldMapping(InboundForm_MappingConfig.stringField(
            'sections.noticeCompliance.notice_unclear_explanation',
            'Explanation_Notice_Omits_Line_Removal__c'
        ));

        config.addFieldMapping(InboundForm_MappingConfig.yesNoField(
            'sections.noticeCompliance.submitted_within_three_months',
            'Submitted_Within_3_Months_Of_Notice__c'
        ));

        config.addFieldMapping(InboundForm_MappingConfig.stringField(
            'sections.noticeCompliance.late_submission_reason',
            'Explanation_Submitted_Beyond_3_Months__c'
        ));

        config.addFieldMapping(InboundForm_MappingConfig.yesNoField(
            'sections.noticeCompliance.different_term_requested',
            'Standard_15_Year_Term__c'
        ).setBooleanTrueValue('No').setBooleanFalseValue('Yes'));

        config.addFieldMapping(InboundForm_MappingConfig.stringField(
            'sections.noticeCompliance.different_term_length_and_explanation',
            'Term_Length_Requested_with_Explanation__c'
        ));

        // Objector / Landowner / Representative Details
        config.addFieldMapping(InboundForm_MappingConfig.yesNoField(
            'sections.landownerDetails.is_objector_also_landowner',
            'Is_Objector_also_Landowner__c'
        ));

        config.addFieldMapping(InboundForm_MappingConfig.yesNoField(
            'sections.representativeDetails.objector_has_representative',
            'Does_Objector_Have_Representative__c'
        ));

        // Land Details
        config.addFieldMapping(InboundForm_MappingConfig.yesNoField(
            'sections.landDetails.site_address_same_as_objector',
            'Site_Address_Same_as_Objector_Address__c'
        ));

        // Assets
        config.addFieldMapping(InboundForm_MappingConfig.yesNoField(
            'sections.assets.assets_match_application_plan',
            'Assets_Match_Application_Plan__c'
        ));

        config.addFieldMapping(InboundForm_MappingConfig.stringField(
            'sections.assets.assets_match_plan_explanation',
            'Explanation_Assets_Do_Not_Match_Plan__c'
        ));

        // Negotiations
        config.addFieldMapping(InboundForm_MappingConfig.yesNoField(
            'sections.negotiations.has_negotiations',
            'Negotiations_in_Progress__c'
        ));

        config.addFieldMapping(InboundForm_MappingConfig.dateField(
            'sections.negotiations.negotiations_start_date',
            'Start_Date_of_Negotiations__c'
        ));

        config.addFieldMapping(InboundForm_MappingConfig.stringField(
            'sections.negotiations.negotiations_comments',
            'Evidence_of_Negotiations__c'
        ));

        config.addFieldMapping(InboundForm_MappingConfig.stringField(
            'sections.negotiations.no_negotiations_reason',
            'Explanation_No_Negotiations__c'
        ));

        config.addFieldMapping(InboundForm_MappingConfig.yesNoField(
            'sections.additionalInformation.has_related_applications',
            'Related_Applications__c'
        ));

        config.addFieldMapping(InboundForm_MappingConfig.stringField(
            'sections.additionalInformation.related_applications_details',
            'Details_of_All_Related_Application__c'
        ));

        config.addFieldMapping(InboundForm_MappingConfig.yesNoField(
            'sections.additionalInformation.has_other_information',
            'Any_Other_Important_Information__c'
        ));

        config.addFieldMapping(InboundForm_MappingConfig.stringField(
            'sections.additionalInformation.other_information_details',
            'Description_of_Important_Information__c'
        ));

    }

    private static void addCollectionConfigs(InboundForm_MappingConfig.FormTypeConfig config) {
        config.addCollection(getApplicantConfig());
        config.addCollection(getApplicantContactConfig());
        config.addCollection(getObjectorConfig());
        config.addCollection(getLandownerConfig());
        config.addCollection(getRepresentativeConfig());
        config.addCollection(getApplicantAddressConfig());
        config.addCollection(getObjectorAddressConfig());
        config.addCollection(getLandownerAddressConfig());
        config.addCollection(getRepresentativeAddressConfig());
        config.addCollection(getInstalledAssetsConfig());
        config.addCollection(getLandDetailsConfig());
        config.addCollection(getSiteAddressConfig());
        config.addCollection(getPaymentConfig());
    }

    private static InboundForm_MappingConfig.CollectionConfig getApplicantConfig() {
        InboundForm_MappingConfig.CollectionConfig applicants =
            new InboundForm_MappingConfig.CollectionConfig()
                .setCollectionName('Applicants')
                .setJsonPath('sections.applicantDetails')
                .setTargetObject('Party__c')
                .setTargetRecordType('Organisation')
                .setParentLookupField('Case__c')
                .setParentLinkSfField('Application_Party_Id__c')
                .setProcessingOrder(19);

        applicants.addFieldMapping(InboundForm_MappingConfig.stringField('applicant_name', 'Name'));
        applicants.addFieldMapping(InboundForm_MappingConfig.stringField('email', 'Email__c'));
        applicants.addFieldMapping(InboundForm_MappingConfig.stringField('applicant_name', 'Organisation__c'));
        applicants.addFieldMapping(InboundForm_MappingConfig.csvStringListField(
            'additional_contacts',
            'Additional_Contact_Email_Addresses__c'
        ));
        applicants.addFieldMapping(InboundForm_MappingConfig.stringField('phone', 'Phone__c'));
        applicants.addFieldMapping(InboundForm_MappingConfig.defaultValue('DNO', 'Party_Type__c'));
        applicants.addFieldMapping(InboundForm_MappingConfig.defaultValue(
            'NWL_ORGANISATION',
            'Application_Party_Id__c'
        ));

        return applicants;
    }

    private static InboundForm_MappingConfig.CollectionConfig getApplicantContactConfig() {
        InboundForm_MappingConfig.CollectionConfig applicantContacts =
            new InboundForm_MappingConfig.CollectionConfig()
                .setCollectionName('ApplicantContacts')
                .setJsonPath('sections.applicantDetails')
                .setTargetObject('Party__c')
                .setTargetRecordType('Individual')
                .setParentLookupField('Case__c')
                .setProcessingOrder(23);

        applicantContacts.addFieldMapping(InboundForm_MappingConfig.stringField(
            'applicant_contact_name',
            'Name'
        ));
        applicantContacts.addFieldMapping(InboundForm_MappingConfig.stringField('email', 'Email__c'));
        applicantContacts.addFieldMapping(InboundForm_MappingConfig.stringField('phone', 'Phone__c'));
        applicantContacts.addFieldMapping(InboundForm_MappingConfig.defaultValue(
            'Representative',
            'Party_Type__c'
        ));
        applicantContacts.addFieldMapping(InboundForm_MappingConfig.defaultValue(
            'NWL_ORGANISATION',
            'Application_Party_Id__c'
        ));
        
        applicantContacts.addFieldMapping(InboundForm_MappingConfig.stringField('phone', 'Phone__c'));

        return applicantContacts;
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
        objectors.addFieldMapping(InboundForm_MappingConfig.stringField('objector_organisation', 'Organisation__c'));
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
        landowners.addFieldMapping(InboundForm_MappingConfig.stringField('landowner_organisation', 'Organisation__c'));
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
        reps.addFieldMapping(InboundForm_MappingConfig.stringField('representative_organisation', 'Organisation__c'));
        reps.addFieldMapping(InboundForm_MappingConfig.stringField('representative_phone', 'Phone__c'));
        reps.addFieldMapping(InboundForm_MappingConfig.defaultValue(
            'Representative',
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

    private static InboundForm_MappingConfig.CollectionConfig getApplicantAddressConfig() {
        InboundForm_MappingConfig.CollectionConfig addresses =
            new InboundForm_MappingConfig.CollectionConfig()
                .setCollectionName('ApplicantAddresses')
                .setJsonPath('sections.applicantDetails')
                .setTargetObject('Address__c')
                .setParentLookupField('Party__c')
                .setParentCollection('Applicants')
                .setParentLinkJsonField('application_party_id')
                .setParentLinkSfField('Application_Party_Id__c')
                .setChildLinkSfField('Application_Party_Identification__c')
                .setProcessingOrder(29);

        addresses.addFieldMapping(InboundForm_MappingConfig.stringField(
            'address_line1',
            'Address_Line1__c'
        ));
        addresses.addFieldMapping(InboundForm_MappingConfig.stringField(
            'address_line2',
            'Address_Line_2__c'
        ));
        addresses.addFieldMapping(InboundForm_MappingConfig.stringField(
            'postcode',
            'Postcode__c'
        ));
        addresses.addFieldMapping(InboundForm_MappingConfig.defaultValue(
            'NWL_ORGANISATION',
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
        payments.addFieldMapping(InboundForm_MappingConfig.stringField('payment_id', 'Item_Reference__c'));
        payments.addFieldMapping(InboundForm_MappingConfig.stringField('payment_id', 'Invoice_Reference__c'));
        payments.addFieldMapping(InboundForm_MappingConfig.stringField('kind', 'Payment_Method__c'));
        payments.addFieldMapping(InboundForm_MappingConfig.integerField('1', 'Quantity__c'));
        payments.addFieldMapping(InboundForm_MappingConfig.currencyField('total_amount', 'Total_Amount__c'));
        payments.addFieldMapping(InboundForm_MappingConfig.currencyField('subtotal', 'Subtotal__c'));
        payments.addFieldMapping(InboundForm_MappingConfig.stringField('status', 'Status__c'));
        payments.addFieldMapping(InboundForm_MappingConfig.stringField('provider', 'Provider__c'));
        payments.addFieldMapping(InboundForm_MappingConfig.stringField('description', 'Description__c'));

        return payments;
    }

    private static InboundForm_MappingConfig.CollectionConfig getInstalledAssetsConfig() {
        InboundForm_MappingConfig.CollectionConfig installedAssets =
            new InboundForm_MappingConfig.CollectionConfig()
                .setCollectionName('InstalledAssets')
                .setJsonPath('sections.assets.installed_assets')
                .setTargetObject('Asset_Information__c')
                .setParentLookupField('Case__c')
                .setProcessingOrder(42);

        installedAssets.addFieldMapping(InboundForm_MappingConfig.stringField(
            'line_voltage',
            'Line_Voltage__c'
        ));
        installedAssets.addFieldMapping(InboundForm_MappingConfig.stringField(
            'asset_id',
            'TORI_NOI_Code__c'
        ));

        return installedAssets;
    }

    private static InboundForm_MappingConfig.CollectionConfig getLandDetailsConfig() {
        InboundForm_MappingConfig.CollectionConfig landDetails =
            new InboundForm_MappingConfig.CollectionConfig()
                .setCollectionName('LandDetails')
                .setJsonPath('sections.landDetails')
                .setTargetObject('Land__c')
                .setParentLookupField('Case__c')
                .setParentLinkSfField('Land_Identification__c')
                .setProcessingOrder(40);

        landDetails.addFieldMapping(InboundForm_MappingConfig.yesNoField(
            'is_registered',
            'Land_Registered_with_Land_Registry__c'
        ));
        landDetails.addFieldMapping(InboundForm_MappingConfig.stringField(
            'land_registry_ref',
            'Land_Registry_Reference_Number__c'
        ));
        landDetails.addFieldMapping(InboundForm_MappingConfig.stringField(
            'land_ownership_unknown_reason',
            'Explanation_Land_not_Registered__c'
        ));
        landDetails.addFieldMapping(InboundForm_MappingConfig.stringField(
            'os_grid_reference.grid_letter',
            'Grid_Letter__c'
        ));
        landDetails.addFieldMapping(InboundForm_MappingConfig.stringField(
            'os_grid_reference.easting',
            'Easting__c'
        ));
        landDetails.addFieldMapping(InboundForm_MappingConfig.stringField(
            'os_grid_reference.northing',
            'Northing__c'
        ));
        landDetails.addFieldMapping(InboundForm_MappingConfig.stringField(
            'land_identification',
            'Other_Info_To_Identify_Land__c'
        ));
        landDetails.addFieldMapping(InboundForm_MappingConfig.stringField(
            'land_identification',
            'Land_Identification__c'
        ));
        landDetails.addFieldMapping(InboundForm_MappingConfig.yesNoField(
            'visible_from_road',
            'Equipment_Visible_from_Public_Road__c'
        ));
        landDetails.addFieldMapping(InboundForm_MappingConfig.stringField(
            'country',
            'Land_Location__c'
        ));

        return landDetails;
    }

    private static InboundForm_MappingConfig.CollectionConfig getSiteAddressConfig() {
        InboundForm_MappingConfig.CollectionConfig siteAddress =
            new InboundForm_MappingConfig.CollectionConfig()
                .setCollectionName('SiteAddress')
                .setJsonPath('sections.landDetails')
                .setTargetObject('Address__c')
                .setParentLookupField('Case__c')
                .setParentLinkSfField('Application_Party_Identification__c')
                .setProcessingOrder(41);

        siteAddress.addFieldMapping(InboundForm_MappingConfig.stringField(
            'site_address.line1',
            'Address_Line1__c'
        ));
        siteAddress.addFieldMapping(InboundForm_MappingConfig.stringField(
            'site_address.line2',
            'Address_Line_2__c'
        ));
        siteAddress.addFieldMapping(InboundForm_MappingConfig.stringField(
            'site_address.county',
            'County__c'
        ));
        siteAddress.addFieldMapping(InboundForm_MappingConfig.stringField(
            'site_address.postcode',
            'Postcode__c'
        ));
        siteAddress.addFieldMapping(InboundForm_MappingConfig.stringField(
            'site_address.town_city',
            'Town_City__c'
        ));
        siteAddress.addFieldMapping(InboundForm_MappingConfig.stringField(
            'country',
            'Country__c'
        ));
        siteAddress.addFieldMapping(InboundForm_MappingConfig.defaultValue(
            'NWL_SITE_ADDRESS',
            'Application_Party_Identification__c'
        ));

        return siteAddress;
    }
}