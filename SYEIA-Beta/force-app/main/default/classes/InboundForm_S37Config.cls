/**
 * S37 form type configuration. Defines all JSON paths and field mappings for S37 applications.
 */
public class InboundForm_S37Config {
    
    /**
     * Get the complete S37 configuration
     */
    public static InboundForm_MappingConfig.FormTypeConfig getConfig() {
        InboundForm_MappingConfig.FormTypeConfig config = 
            new InboundForm_MappingConfig.FormTypeConfig()
                .setFormType('S37')
                .setDescription('Section 37 - Overhead Electric Lines')
                .setPrimaryObject('Case__c')
                .setPrimaryRecordType('Section_37')
                .setApplicationIdField('AWS_Application_Id__c')
                .setApplicationIdJsonPath('applicationId')
                .setNameJsonPath('applicationId')
                .setStatusField('Status__c')
                .setDefaultStatus('New')
                .setHandlerClass(InboundForm_S37Handler.class);
        
        addCaseFieldMappings(config);
        addCollectionConfigs(config);
        
        return config;
    }
    
    // ========================================================================
    // CASE FIELD MAPPINGS
    // ========================================================================
    
    private static void addCaseFieldMappings(InboundForm_MappingConfig.FormTypeConfig config) {
        
        // ----- Works Overview Section -----
        config.addFieldMapping(InboundForm_MappingConfig.integerField(
            'sections.worksOverview.polesAdded', 
            'Number_Of_Poles_Being_Added__c'
        ));
        
        config.addFieldMapping(InboundForm_MappingConfig.integerField(
            'sections.worksOverview.polesReplaced', 
            'Number_Of_Poles_Being_Replaced__c'
        ));
        
        config.addFieldMapping(InboundForm_MappingConfig.stringField(
            'sections.worksOverview.poleMaterial', 
            'Materials_For_New_Poles_Pylons__c'
        ));
        
        config.addFieldMapping(InboundForm_MappingConfig.stringField(
            'sections.worksOverview.poleComments', 
            'Comments_On_Added_Replaced_Poles__c'
        ));
        
        config.addFieldMapping(InboundForm_MappingConfig.stringField(
            'sections.worksOverview.generalComments', 
            'General_Comments__c'
        ));
        
        config.addFieldMapping(InboundForm_MappingConfig.stringField(
            'sections.worksOverview.vehiclesRequired', 
            'Vehicles_Required_On_Site__c'
        ));
        
        config.addFieldMapping(InboundForm_MappingConfig.stringField(
            'sections.worksOverview.estimatedDuration', 
            'Estimated_Duration_Of_Works__c'
        ));
        
        config.addFieldMapping(InboundForm_MappingConfig.yesNoField(
            'sections.worksOverview.excavationRequired', 
            'Excavation_Works_Required__c'
        ));
        
        config.addFieldMapping(InboundForm_MappingConfig.stringField(
            'sections.worksOverview.excavationDetails', 
            'Details_Of_Excavation_Works__c'
        ));
        
        config.addFieldMapping(InboundForm_MappingConfig.stringField(
            'sections.worksOverview.chemicalTreatments', 
            'Any_Chemical_Treatments_Proposed__c'
        ));
        
        config.addFieldMapping(InboundForm_MappingConfig.stringField(
            'sections.worksOverview.removalDescription', 
            'Details_Of_Equipment_Removal__c'
        ));
        
        config.addFieldMapping(InboundForm_MappingConfig.stringField(
            'sections.worksOverview.accessRoutesDetails', 
            'Details_Of_Access_Storage_Sites__c'
        ));
        
        config.addFieldMapping(InboundForm_MappingConfig.yesNoField(
            'sections.worksOverview.roadClosuresRequired', 
            'Road_Closures_Or_Traffic_Calming__c'
        ));
        
        config.addFieldMapping(InboundForm_MappingConfig.yesNoField(
            'sections.worksOverview.addingOrReplacingLines', 
            'Adding_Or_Replacing_Any_Overhead_Lines__c'
        ));
        
        config.addFieldMapping(InboundForm_MappingConfig.yesNoField(
            'sections.worksOverview.addingOrReplacingPoles', 
            'Adding_or_Replacing_Any_Poles__c'
        ));
        
        config.addFieldMapping(InboundForm_MappingConfig.stringField(
            'sections.worksOverview.overheadLineDescription', 
            'Description_Of_Overhead_Lines__c'
        ));
        
        config.addFieldMapping(InboundForm_MappingConfig.yesNoField(
            'sections.worksOverview.removingExistingEquipment', 
            'Is_Any_Existing_Equipment_Being_Removed__c'
        ));
        
        config.addFieldMapping(InboundForm_MappingConfig.yesNoField(
            'sections.worksOverview.usingExistingAccessRoutes', 
            'Pre_existing_Routes_Storage_Used__c'
        ));
        
        config.addFieldMapping(InboundForm_MappingConfig.yesNoField(
            'sections.worksOverview.vegetationClearanceRequired', 
            'Vegetation_Clearance_Required__c'
        ));
        
        config.addFieldMapping(InboundForm_MappingConfig.stringField(
            'sections.worksOverview.vegetationClearanceDetails', 
            'Details_Of_Vegetation_Clearance__c'
        ));
        
        // ----- Project Details Section -----
        config.addFieldMapping(InboundForm_MappingConfig.stringField(
            'sections.projectDetails.overview.project_details.project_name', 
            'Project_Name__c'
        ));
        
        config.addFieldMapping(InboundForm_MappingConfig.stringField(
            'sections.projectDetails.overview.project_details.project_description', 
            'Project_Description__c'
        ));
        
        config.addFieldMapping(InboundForm_MappingConfig.decimalField(
            'sections.projectDetails.overview.application_project_overview.max_structure_height_m', 
            'Tallest_Pole_Height__c'
        ));
        
        config.addFieldMapping(InboundForm_MappingConfig.stringField(
            'sections.projectDetails.overview.application_project_overview.plan_reference', 
            'Plan_Reference__c'
        ));
        
        config.addFieldMapping(InboundForm_MappingConfig.yesNoField(
            'sections.projectDetails.overview.hasRelatedCpo', 
            'CPO_Submitted__c'
        ));
        
        config.addFieldMapping(InboundForm_MappingConfig.stringField(
            'sections.projectDetails.overview.relatedCpoDetails', 
            'Related_CPO_Details__c'
        ));
        
        // ----- Network Operator Section -----
        config.addFieldMapping(InboundForm_MappingConfig.stringField(
            'sections.networkOperator.details.operator_ref', 
            'Applicant_Reference__c'
        ));
        
        config.addFieldMapping(InboundForm_MappingConfig.dateField(
            'sections.networkOperator.details.submitted_at', 
            'Date_of_Application__c'
        ));
        
        // ----- Supporting Information Section -----
        config.addFieldMapping(InboundForm_MappingConfig.yesNoField(
            'sections.supportingInformation.supportingQuestions.wayleaves_obtained', 
            'Have_All_Wayleaves_Been_Obtained__c'
        ));
        
        config.addFieldMapping(InboundForm_MappingConfig.stringField(
            'sections.supportingInformation.supportingQuestions.wayleaves_not_obtained_reason', 
            'Why_Have_All_Wayleaves_Not_Been_Obtained__c'
        ));
        
        config.addFieldMapping(InboundForm_MappingConfig.stringField(
            'sections.supportingInformation.supportingQuestions.applicant_supporting_comments', 
            'Comments_to_Support_Application__c'
        ));
        
        config.addFieldMapping(InboundForm_MappingConfig.yesNoField(
            'sections.supportingInformation.supportingQuestions.esqcr_2002_compliance_confirmed', 
            'Works_Comply_With_ESQCR__c'
        ));
    }
    
    // ========================================================================
    // COLLECTION CONFIGURATIONS
    // ========================================================================
    
    private static void addCollectionConfigs(InboundForm_MappingConfig.FormTypeConfig config) {
        config.addCollection(getRoutesConfig());
        config.addCollection(getRoutePointsConfig());
        config.addCollection(getPartiesConfig());
        config.addCollection(getAddressesConfig());
        config.addCollection(getSensitiveAreaChecksConfig());
        config.addCollection(getAssetInformationConfig());
        config.addCollection(getConsultationConfig());
        config.addCollection(getConsultationResponseConfig());
        config.addCollection(getParishConfig());
        config.addCollection(getPaymentConfig());
        config.addCollection(getPostConsultationOutcomeConfig());
        config.addCollection(getSensitiveAreaReviewConfig());
    }
    
    // ----- Routes Collection -----
    private static InboundForm_MappingConfig.CollectionConfig getRoutesConfig() {
        InboundForm_MappingConfig.CollectionConfig routes = 
            new InboundForm_MappingConfig.CollectionConfig()
                .setCollectionName('Routes')
                .setJsonPath('sections.location.routes')
                .setTargetObject('Route__c')
                .setParentLookupField('Case__c')
                .setParentLinkSfField('Route_Id__c')
                .setProcessingOrder(10);
        
        routes.addFieldMapping(InboundForm_MappingConfig.stringField('routeName', 'Name'));
        routes.addFieldMapping(InboundForm_MappingConfig.stringField('route_id', 'Route_Id__c'));
        routes.addFieldMapping(InboundForm_MappingConfig.stringField(
            'disconnectedroute_justification', 
            'Disconnected_Route_Justification__c'
        ));
        
        return routes;
    }
    
    // ----- Route Points Collection (Nested) -----
    private static InboundForm_MappingConfig.CollectionConfig getRoutePointsConfig() {
        InboundForm_MappingConfig.CollectionConfig routePoints = 
            new InboundForm_MappingConfig.CollectionConfig()
                .setCollectionName('RoutePoints')
                .setJsonPath('sections.location.routes')
                .setTargetObject('Route_Point__c')
                .setParentLookupField('Route__c')
                .setParentCollection('Routes')
                .setParentLinkJsonField('route_id')
                .setParentLinkSfField('Route_Id__c')
                .setChildLinkSfField('Route_Id__c')
                .setIsNestedArray(true)
                .setNestedArrayPath('gridPoints')
                .setProcessingOrder(20);
        
        routePoints.addFieldMapping(
            InboundForm_MappingConfig.stringField('point_id', 'Route_Point_Id__c'));
        routePoints.addFieldMapping(
            InboundForm_MappingConfig.stringField('easting', 'Easting__c'));
        routePoints.addFieldMapping(
            InboundForm_MappingConfig.stringField('northing', 'Northing__c'));
        
        return routePoints;
    }
    
    // ----- Parties Collection (DNO from Network Operator) -----
    private static InboundForm_MappingConfig.CollectionConfig getPartiesConfig() {
        InboundForm_MappingConfig.CollectionConfig parties = 
            new InboundForm_MappingConfig.CollectionConfig()
                .setCollectionName('Parties')
                .setJsonPath('sections.networkOperator.details.application_party')
                .setTargetObject('Party__c')
                .setTargetRecordType('Organisation')
                .setParentLookupField('Case__c')
                .setProcessingOrder(30);
        
        parties.addFieldMapping(
            InboundForm_MappingConfig.stringField('organisation_name', 'Name'));
        parties.addFieldMapping(
            InboundForm_MappingConfig.booleanField('is_primary', 'Is_Primary__c'));
        parties.addFieldMapping(
            InboundForm_MappingConfig.stringField('application_party_id', 'Application_Party_Id__c'));
        parties.addFieldMapping(
            InboundForm_MappingConfig.stringField('person_id', 'Person_Identification__c'));
        
        return parties;
    }
    
    // ----- Addresses Collection (DNO Address from Network Operator) -----
    private static InboundForm_MappingConfig.CollectionConfig getAddressesConfig() {
        InboundForm_MappingConfig.CollectionConfig addresses = 
            new InboundForm_MappingConfig.CollectionConfig()
                .setCollectionName('Addresses')
                .setJsonPath('sections.networkOperator.details.application_party')
                .setTargetObject('Address__c')
                .setParentLookupField('Party__c')
                .setParentCollection('Parties')
                .setParentLinkJsonField('application_party_id')
                .setParentLinkSfField('Application_Party_Identification__c')
                .setChildLinkSfField('Application_Party_Identification__c')
                .setProcessingOrder(40);
        
        addresses.addFieldMapping(
            InboundForm_MappingConfig.stringField('line1', 'Address_Line1__c'));
        addresses.addFieldMapping(
            InboundForm_MappingConfig.stringField('line2', 'Address_Line_2__c'));
        addresses.addFieldMapping(
            InboundForm_MappingConfig.stringField('town_city', 'Town_City__c'));
        addresses.addFieldMapping(
            InboundForm_MappingConfig.stringField('postcode', 'Postcode__c'));
        addresses.addFieldMapping(
            InboundForm_MappingConfig.stringField('country', 'Country__c'));
        addresses.addFieldMapping(
            InboundForm_MappingConfig.stringField(
                'application_party_id', 
                'Application_Party_Identification__c'
            ));
        
        return addresses;
    }
    
    // ----- Sensitive Area Checks (Simple Array) -----
    private static InboundForm_MappingConfig.CollectionConfig getSensitiveAreaChecksConfig() {
        return new InboundForm_MappingConfig.CollectionConfig()
            .setCollectionName('SensitiveAreaChecks')
            .setJsonPath('sections.sensitiveAreaChecks.layers')
            .setTargetObject('Sensitive_Area_Check__c')
            .setParentLookupField('Case__c')
            .setIsSimpleArray(true)
            .setSimpleArrayTargetField('Name')
            .setProcessingOrder(50);
    }
    
    // ----- Asset Information -----
    private static InboundForm_MappingConfig.CollectionConfig getAssetInformationConfig() {
        InboundForm_MappingConfig.CollectionConfig assets = 
            new InboundForm_MappingConfig.CollectionConfig()
                .setCollectionName('Assets')
                .setJsonPath('sections.assetInformation')
                .setTargetObject('Asset_Information__c')
                .setParentLookupField('Case__c')
                .setProcessingOrder(60);
        
        assets.addFieldMapping(
            InboundForm_MappingConfig.decimalField('line_length', 'Line_Length__c'));
        assets.addFieldMapping(
            InboundForm_MappingConfig.stringField('line_voltage', 'Line_Voltage__c'));
        assets.addFieldMapping(
            InboundForm_MappingConfig.stringField('type_of_line', 'Line_Type__c'));
        assets.addFieldMapping(
            InboundForm_MappingConfig.stringField('tori_noi_code', 'TORI_NOI_Code__c'));
        assets.addFieldMapping(
            InboundForm_MappingConfig.stringField(
                'standard_specification_reference_number', 
                'Standard_Specification_Reference_Number__c'
            ));
        assets.addFieldMapping(
            InboundForm_MappingConfig.stringField('description', 'Description__c'));
        
        return assets;
    }

    // ----- Consultations Collection -----
    private static InboundForm_MappingConfig.CollectionConfig getConsultationConfig() {
        InboundForm_MappingConfig.CollectionConfig consultations = 
            new InboundForm_MappingConfig.CollectionConfig()
                .setCollectionName('consultations')
                .setJsonPath('sections.consultations')
                .setTargetObject('Consultation__c')
                .setParentLookupField('Case__c')
                .setParentLinkSfField('Consultation_Id__c')
                .setProcessingOrder(70);
        
        consultations.addFieldMapping(InboundForm_MappingConfig.stringField('consulteeOrganisationName', 'Name'));
        consultations.addFieldMapping(InboundForm_MappingConfig.stringField('id', 'Consultation_Id__c'));
        consultations.addFieldMapping(InboundForm_MappingConfig.dateField('dateClosed', 'Completed_On__c'));
        consultations.addFieldMapping(InboundForm_MappingConfig.stringField('offline', 'Consultation_Completed_Offline__c'));
        consultations.addFieldMapping(InboundForm_MappingConfig.stringField('consultationType', 'Consultation_Type__c'));
        consultations.addFieldMapping(InboundForm_MappingConfig.stringField('consulteeEmailAddress', 'Contact_Email_Address__c'));
        consultations.addFieldMapping(InboundForm_MappingConfig.dateTimeField('createdAt', 'Created_At__c'));
        consultations.addFieldMapping(InboundForm_MappingConfig.stringField('status', 'Status__c'));
        consultations.addFieldMapping(InboundForm_MappingConfig.dateTimeField('sentAt', 'Sent_At__c'));
        consultations.addFieldMapping(InboundForm_MappingConfig.booleanField('objectionRaised', 'Status__c'));
        consultations.addFieldMapping(InboundForm_MappingConfig.stringField('consulteeContactName   ', 'Consultee_Contact_Name__c'));
        consultations.addFieldMapping(InboundForm_MappingConfig.stringField('consulteeOrganisationName', 'Consultee_Organisation_Name__c'));
        consultations.addFieldMapping(InboundForm_MappingConfig.stringField('notRequiredReason', 'Not_Required_Reason__c'));
        return consultations;
    }

// ----- Consultation Response Collection (Nested) -----
    private static InboundForm_MappingConfig.CollectionConfig getConsultationResponseConfig() {
        InboundForm_MappingConfig.CollectionConfig consultationResponses = 
            new InboundForm_MappingConfig.CollectionConfig()
                .setCollectionName('consultationResponses')
                .setJsonPath('sections.consultations')
                .setTargetObject('Consultation_Response__c')
                .setParentLookupField('Consultation__c')
                .setParentCollection('consultations')
                .setParentLinkJsonField('id')
                .setParentLinkSfField('Consultation_Response_Id__c')
                .setChildLinkSfField('Consultation_Response_Id__c')
                .setIsNestedArray(false)
                .setProcessingOrder(80);
        
        consultationResponses.addFieldMapping(
            InboundForm_MappingConfig.stringField('id', 'Consultation_Response_Id__c'));
        consultationResponses.addFieldMapping(
            InboundForm_MappingConfig.stringField('respondingConsulteeName', 'Full_Name_of_Responder__c'));
        consultationResponses.addFieldMapping(
            InboundForm_MappingConfig.stringField('respondingConsulteeEmail', 'Email_of_Responder__c'));
        
        return consultationResponses;
    }

    // ----- Parish Collection -----
    private static InboundForm_MappingConfig.CollectionConfig getParishConfig() {
        InboundForm_MappingConfig.CollectionConfig parishes = 
            new InboundForm_MappingConfig.CollectionConfig()
                .setCollectionName('parishes')
                .setJsonPath('sections.parishes')
                .setTargetObject('Parish__c')
                .setParentLookupField('Case__c')
                .setParentLinkSfField('Parish_Id__c')
                .setProcessingOrder(90);
        
        parishes.addFieldMapping(InboundForm_MappingConfig.stringField('id', 'Parish_Id__c'));
        parishes.addFieldMapping(InboundForm_MappingConfig.stringField('country', 'Country__c'));
        parishes.addFieldMapping(InboundForm_MappingConfig.stringField('lpa_code', 'LPA_Code__c'));
        parishes.addFieldMapping(InboundForm_MappingConfig.dateTimeField('created_at', 'Created_at__c'));
        parishes.addFieldMapping(InboundForm_MappingConfig.stringField('created_by', 'Created_by__c'));
        parishes.addFieldMapping(InboundForm_MappingConfig.stringField('parish_code', 'Parish_Code__c'));
        parishes.addFieldMapping(InboundForm_MappingConfig.stringField('parish_name', 'Name'));

        return parishes;
    }

    // ----- Payment Collection -----
    private static InboundForm_MappingConfig.CollectionConfig getPaymentConfig() {
        InboundForm_MappingConfig.CollectionConfig payments = 
            new InboundForm_MappingConfig.CollectionConfig()
                .setCollectionName('payments')
                .setJsonPath('sections.payment')
                .setTargetObject('Payment__c')
                .setParentLookupField('Case__c')
                .setParentLinkSfField('Payment_Id__c')
                .setProcessingOrder(100);
        
        payments.addFieldMapping(InboundForm_MappingConfig.stringField('payment_id', 'Payment_Id__c'));
        payments.addFieldMapping(InboundForm_MappingConfig.stringField('kind', 'Payment_Method__c'));
        payments.addFieldMapping(InboundForm_MappingConfig.currencyField('total_amount', 'Total_Amount__c'));
        payments.addFieldMapping(InboundForm_MappingConfig.stringField('status', 'Status__c'));
        payments.addFieldMapping(InboundForm_MappingConfig.stringField('user_id', 'User_Id__c'));
        payments.addFieldMapping(InboundForm_MappingConfig.stringField('provider', 'Provider__c'));
        payments.addFieldMapping(InboundForm_MappingConfig.dateTimeField('created_at', 'Created_at__c'));

        return payments;
    }

    // ----- Post Consultation Outcome Collection -----
    private static InboundForm_MappingConfig.CollectionConfig getPostConsultationOutcomeConfig() {
        InboundForm_MappingConfig.CollectionConfig postConOutcomes = 
            new InboundForm_MappingConfig.CollectionConfig()
                .setCollectionName('postConsultationOutcomes')
                .setJsonPath('sections.postConsultationOutcome')
                .setTargetObject('Post_Consultation__c')
                .setParentLookupField('Case__c')
                .setParentLinkSfField('Post_Consultation_Id__c')
                .setProcessingOrder(110);
        
        postConOutcomes.addFieldMapping(InboundForm_MappingConfig.stringField(
            'id', 'Post_Consultation_Id__c'));
        postConOutcomes.addFieldMapping(InboundForm_MappingConfig.stringField(
            'consultees_recommendations_not_accepted_reason', 'CON_Recommendations_Not_Accepted_Reason__c'));
        postConOutcomes.addFieldMapping(InboundForm_MappingConfig.booleanField(
            'consultees_recommendations_accepted','Consultees_Recommendations_Accepted__c'));
        postConOutcomes.addFieldMapping(InboundForm_MappingConfig.booleanField(
            'consultees_recommendations_made','Consultees_Recommendations_Made__c'));
        postConOutcomes.addFieldMapping(InboundForm_MappingConfig.dateTimeField(
            'created_at', 'Created_At__c'));
        postConOutcomes.addFieldMapping(InboundForm_MappingConfig.stringField(
            'created_by', 'Created_By__c'));
        postConOutcomes.addFieldMapping(InboundForm_MappingConfig.booleanField(
            'lpa_conditions_accepted', 'IPA_Conditions_Accepted__c'));
        postConOutcomes.addFieldMapping(InboundForm_MappingConfig.booleanField(
            'lpa_conditions_imposed', 'IPA_Conditions_Imposed__c'));
        postConOutcomes.addFieldMapping(InboundForm_MappingConfig.stringField(
            'lpa_conditions_not_accepted_reason', 'IPA_Conditions_Not_Accepted_Reason__c'));
        postConOutcomes.addFieldMapping(InboundForm_MappingConfig.dateTimeField(
            'last_updated_at', 'Last_Updated_At__c'));
        postConOutcomes.addFieldMapping(InboundForm_MappingConfig.stringField(
            'last_updated_by', 'Last_Updated_By__c'));

        return postConOutcomes;
    }

    // ----- Sensitive Area Review Collection -----
    private static InboundForm_MappingConfig.CollectionConfig getSensitiveAreaReviewConfig() {
        InboundForm_MappingConfig.CollectionConfig sars = 
            new InboundForm_MappingConfig.CollectionConfig()
                .setCollectionName('sensitiveAreaReviews')
                .setJsonPath('sections.sensitiveAreaReview')
                .setTargetObject('Sensitive_Area_Review__c')
                .setParentLookupField('Case__c')
                .setParentLinkSfField('Sensitive_Area_Review_Id__c')
                .setProcessingOrder(120);
        
        sars.addFieldMapping(InboundForm_MappingConfig.stringField('id', 'Sensitive_Area_Review_Id__c'));
        sars.addFieldMapping(InboundForm_MappingConfig.stringField('route_id','Route_Id__c'));
        sars.addFieldMapping(InboundForm_MappingConfig.dateTimeField('created_at', 'Created_at__c'));
        sars.addFieldMapping(InboundForm_MappingConfig.dateTimeField('updated_at', 'Updated_at__c'));
        sars.addFieldMapping(InboundForm_MappingConfig.stringField( 'reviewed_at', 'Reviewed_at__c'));
        sars.addFieldMapping(InboundForm_MappingConfig.stringField('reviewed_by', 'Reviewed_by__c'));
        sars.addFieldMapping(InboundForm_MappingConfig.stringField('settings_id', 'Settings_Id__c'));
        sars.addFieldMapping(InboundForm_MappingConfig.stringField('application_id', 'Application_Id__c'));
        sars.addFieldMapping(InboundForm_MappingConfig.stringField('add_other_areas_choice', 'Add_Other_Areas_Choice__c'));
        sars.addFieldMapping(InboundForm_MappingConfig.integerField('asset_presence_option_id', 'Asset_Presence_Option_Id__c'));
        sars.addFieldMapping(InboundForm_MappingConfig.stringField('other_sensitive_areas_note', 'Other_Sensitive_Areas_Not__c'));
        return sars;
    }
}