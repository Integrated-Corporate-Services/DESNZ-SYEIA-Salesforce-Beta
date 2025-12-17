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
            'Adding_Or_Replacing_Any_Overhead_Poles__c'
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
        
        // ----- Network Operator Section -----
        config.addFieldMapping(InboundForm_MappingConfig.stringField(
            'sections.networkOperator.details.operator_ref', 
            'Applicant_Reference__c'
        ));
        
        config.addFieldMapping(InboundForm_MappingConfig.dateField(
            'sections.networkOperator.details.submitted_at', 
            'Date_of_Application__c'
        ));
        
        // ----- EIA Section -----
        config.addFieldMapping(InboundForm_MappingConfig.yesNoField(
            'sections.eiaFees.is_eia_development', 
            'Subject_To_An_EIA__c'
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
}