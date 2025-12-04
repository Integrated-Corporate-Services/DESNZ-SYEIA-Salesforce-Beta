public with sharing class GW_CustomCase {
    public GW_CustomCase() {}

    public static Map<String, List<SObject>> createS37CaseFromAWS(S37ApplicationDTO s37AppDTO, Inbound_Request__c inboundReq) {
        Utilities.logMethodEntry('createS37CaseFromAWS');
        // Implementation for creating S37 case from AWS data
        System.debug('Received S37 Application DTO: ' + s37AppDTO);
        Map<String, List<SObject>> caseRecordAndRelatedRecords = new Map<String, List<SObject>>();
        try {
            Case__c newCase = new Case__c();
			newCase.Overdue_Email_Sent__c = false;
            newCase.Inbound_Request__c = inboundReq.Id;
            // sections from s37AppDTO
            s37_PopulateCaseFields(newCase, s37AppDTO);
            Map<String, List<SObject>> routes = s37_PopulateRoutes(newCase, s37AppDTO.sections.location.routes);

            caseRecordAndRelatedRecords.put('Case__c', new List<SObject>{newCase});
            if (routes != null) {
                caseRecordAndRelatedRecords.putAll(routes);
            }
            // application parties
            caseRecordAndRelatedRecords.putAll(s37_PopulateCaseFieldsFromParty(newCase, s37AppDTO.sections.application_party));
            // sensitive area checks
            caseRecordAndRelatedRecords.put('Sensitive_Area_Check__c', S37_PopulateSensitiveAreaCheckDetails(newCase, s37AppDTO.sections.sensitiveAreaChecks));
            // asset information
            caseRecordAndRelatedRecords.put('Asset_Information__c', s37_populateAssetInformation(newCase, s37AppDTO.sections.assetInformation));
            
            Utilities.logMethodExit('createS37CaseFromAWS');
            return caseRecordAndRelatedRecords;

        } catch (Exception ex) {
            Utilities.log(Utilities.formatException(ex));
            System.debug('Error inserting Case: ' + ex.getMessage());
            System.debug('Stack Trace ' + ex.getStackTraceString());
        }

        Utilities.logMethodExit('createS37CaseFromAWS');
        return null;
    }

    // helper methods
    private static Case__c s37_PopulateCaseFields(Case__c caseRecord, S37ApplicationDTO s37AppDTO) {
        Utilities.logMethodEntry('s37_PopulateCaseFields');
        // Check if s37AppDTO is null
        if (s37AppDTO == null) {
            return caseRecord;
        }

        // Populate fields based on s37AppDTO
        caseRecord.Name = s37AppDTO.applicationId;
        caseRecord.Case_Type__c = s37AppDTO.formType == 'S37' ? 'Section 37' : 'Unknown';
        caseRecord.DNO_Name__c = s37AppDTO.applicationId;
        caseRecord.Application_Fee_Paid__c = 'Yes';
        caseRecord.AWS_Application_Id__c = s37AppDTO.applicationId;

        // works overview
        s37_populateWorksOverview(caseRecord, s37AppDTO.sections.worksOverview);
        
        // project details
        s37_PopulateProjectDetails(caseRecord, s37AppDTO.sections.projectDetails);

        // network operator details
        s37_populateNetworkOperatorDetails(caseRecord, s37AppDTO.sections.networkOperator);

        // eia details
        s37_populateEiaDetails(caseRecord, s37AppDTO.sections.eiaFees);

        // supporting information
        s37_populateSupportingInformation(caseRecord, s37AppDTO.sections.supportingInformation);

        Utilities.logMethodExit('s37_PopulateCaseFields');
        return caseRecord;
    }

    private static void s37_populateWorksOverview(Case__c caseRecord, S37ApplicationDTO.WorksOverview appWorksOverview) {
        Utilities.logMethodEntry('s37_populateWorksOverview');
        // Populate fields based on appWorksOverview
        if (appWorksOverview == null) {
            Utilities.log('appWorksOverview is empty');
            Utilities.logMethodExit('s37_populateWorksOverview');
            return;
        }

        try {

            caseRecord.Number_Of_Poles_Being_Added__c = Utilities.isNullOrBlank(appWorksOverview.polesAdded) ? null : Integer.valueOf(appWorksOverview.polesAdded);
            caseRecord.Comments_to_Support_Application__c = String.isBlank(appWorksOverview.poleComments) ? null : String.valueOf(appWorksOverview.poleComments);
            caseRecord.Materials_For_New_Poles_Pylons__c = Utilities.isNullOrBlank(appWorksOverview.poleMaterial) ? null : String.valueOf(appWorksOverview.poleMaterial);
            caseRecord.Number_Of_Poles_Being_Replaced__c = Utilities.isNullOrBlank(appWorksOverview.polesReplaced) ? null : Integer.valueOf(appWorksOverview.polesReplaced);
            caseRecord.General_Comments__c = Utilities.isNullOrBlank(appWorksOverview.generalComments) ? null : String.valueOf(appWorksOverview.generalComments);
            caseRecord.Vehicles_Required_On_Site__c = Utilities.isNullOrBlank(appWorksOverview.vehiclesRequired) ? null : String.valueOf(appWorksOverview.vehiclesRequired);
            caseRecord.Estimated_Duration_Of_Works__c = Utilities.isNullOrBlank(appWorksOverview.estimatedDuration) ? null : String.valueOf(appWorksOverview.estimatedDuration);
            caseRecord.Excavation_Works_Required__c = Utilities.isNullOrBlank(appWorksOverview.excavationRequired) ? null : (appWorksOverview.excavationRequired == true ? 'Yes' : 'No');
            caseRecord.Details_Of_Excavation_Works__c = Utilities.isNullOrBlank(appWorksOverview.excavationDetails) ? null : String.valueOf(appWorksOverview.excavationDetails);
            caseRecord.Any_Chemical_Treatments_Proposed__c = Utilities.isNullOrBlank(appWorksOverview.chemicalTreatments) ? null : String.valueOf(appWorksOverview.chemicalTreatments);
            caseRecord.Details_Of_Equipment_Removal__c = Utilities.isNullOrBlank(appWorksOverview.removalDescription) ? null : String.valueOf(appWorksOverview.removalDescription);
            caseRecord.Details_Of_Access_Storage_Sites__c = Utilities.isNullOrBlank(appWorksOverview.accessRoutesDetails) ? null : String.valueOf(appWorksOverview.accessRoutesDetails);
            caseRecord.Road_Closures_Or_Traffic_Calming__c = Utilities.isNullOrBlank(appWorksOverview.roadClosuresRequired) ? null : (appWorksOverview.roadClosuresRequired == true ? 'Yes' : 'No');
            caseRecord.Adding_Or_Replacing_Any_Overhead_Lines__c = Utilities.isNullOrBlank(appWorksOverview.addingOrReplacingLines) ? null : (appWorksOverview.addingOrReplacingLines == true ? 'Yes' : 'No');
            caseRecord.Adding_Or_Replacing_Any_Overhead_Poles__c = Utilities.isNullOrBlank(appWorksOverview.addingOrReplacingPoles) ? null : (appWorksOverview.addingOrReplacingPoles == true ? 'Yes' : 'No');
            caseRecord.Description_Of_Overhead_Lines__c = Utilities.isNullOrBlank(appWorksOverview.overheadLineDescription) ? null : String.valueOf(appWorksOverview.overheadLineDescription);
            caseRecord.Is_Any_Existing_Equipment_Being_Removed__c = Utilities.isNullOrBlank(appWorksOverview.removingExistingEquipment) ? null : (appWorksOverview.removingExistingEquipment == true ? 'Yes' : 'No');
            caseRecord.Pre_existing_Routes_Storage_Used__c = Utilities.isNullOrBlank(appWorksOverview.usingExistingAccessRoutes) ? null : (appWorksOverview.usingExistingAccessRoutes == true ? 'Yes' : 'No');
            caseRecord.Details_Of_Vegetation_Clearance__c = Utilities.isNullOrBlank(appWorksOverview.vegetationClearanceDetails) ? null : String.valueOf(appWorksOverview.vegetationClearanceDetails);
            caseRecord.Vegetation_Clearance_Required__c = Utilities.isNullOrBlank(appWorksOverview.vegetationClearanceRequired) ? null : (appWorksOverview.vegetationClearanceRequired == true ? 'Yes' : 'No');
        } catch (Exception ex) {
            Utilities.log(Utilities.formatException(ex));
        }
        
        Utilities.logMethodExit('s37_populateWorksOverview');
    }

    private static void s37_populateEiaDetails(Case__c caseRecord, S37ApplicationDTO.EiaFees appEiaDetails) {
        Utilities.logMethodEntry('s37_populateEiaDetails');
        if (appEiaDetails == null || Utilities.isNullOrBlank(appEiaDetails)) {
            Utilities.log('appEiaDetails is empty');
            Utilities.logMethodExit('s37_populateEiaDetails');
            return;
        }

        try {
                
            // Populate fields based on appEiaDetails
            if (appEiaDetails != null) {
                if (Utilities.isNullOrBlank(appEiaDetails.requires_full_eia) == false 
                    && appEiaDetails.requires_full_eia == true
                ) {
                    caseRecord.Full_EIA_Process_or_Screening_Opinion__c = 'Full EIA Process';
                } else if (Utilities.isNullOrBlank(appEiaDetails.screening_only) == false 
                && appEiaDetails.screening_only == true) {
                    caseRecord.Full_EIA_Process_or_Screening_Opinion__c = 'Screening Opinion';
                } else {
                    caseRecord.Full_EIA_Process_or_Screening_Opinion__c = null;
                }

                // subject to EIA
                caseRecord.Subject_To_An_EIA__c = Utilities.isNullOrBlank(appEiaDetails.is_eia_development) ? null : (appEiaDetails.is_eia_development == true ? 'Yes' : 'No');
            }
        } catch (Exception ex) {
            Utilities.log(Utilities.formatException(ex));
        }
        Utilities.logMethodExit('s37_populateEiaDetails');
    }

    private static void s37_populateNetworkOperatorDetails(Case__c caseRecord, S37ApplicationDTO.NetworkOperator appNetworkOperator) {
        Utilities.logMethodEntry('s37_populateNetworkOperatorDetails');
        if (appNetworkOperator == null || Utilities.isNullOrBlank(appNetworkOperator)) {
            Utilities.log('appNetworkOperator is empty');
            Utilities.logMethodExit('s37_populateNetworkOperatorDetails');
            return;
        }

        try {
                
            // Populate fields based on appNetworkOperator
            if (appNetworkOperator != null) {
                caseRecord.Applicant_Reference__c = Utilities.isNullOrBlank(appNetworkOperator.details.operator_ref) ? null : appNetworkOperator.details.operator_ref;
                caseRecord.Date_of_Application__c = Utilities.isNullOrBlank(appNetworkOperator.details.submitted_at) ? null : Date.valueOf(appNetworkOperator.details.submitted_at.substring(0,10));
                // caseRecord.Network_Operator_Phone__c = appNetworkOperator.contact_phone;
                // caseRecord.Network_Operator_Email__c = appNetworkOperator.contact_email;
            }
        } catch (Exception ex) {
            Utilities.log(Utilities.formatException(ex));
        }
        Utilities.logMethodExit('s37_populateNetworkOperatorDetails');
    }

    private static void s37_PopulateProjectDetails(Case__c caseRecord, S37ApplicationDTO.ProjectDetails appProjectDetails) {
        Utilities.logMethodEntry('s37_PopulateProjectDetails');
        if (appProjectDetails == null || Utilities.isNullOrBlank(appProjectDetails)) {
            Utilities.log('appProjectDetails is empty');
            Utilities.logMethodExit('s37_PopulateProjectDetails');
            return;
        }

        try {
            // Populate fields based on appProjectDetails
            // project details
            if (appProjectDetails != null) {
                // core project details
                caseRecord.Project_Name__c = Utilities.isNullOrBlank(appProjectDetails.overview.project_details.project_name) ? null : appProjectDetails.overview.project_details.project_name;
                caseRecord.Project_Description__c = Utilities.isNullOrBlank(appProjectDetails.overview.project_details.project_description) ? null : appProjectDetails.overview.project_details.project_description;
                // caseRecord.Related_CPO_Details__c = appProjectDetails.overview.application_project_overview.;
                // caseRecord.Plan_Reference__c = appProjectDetails.overview.application_project_overview.plan_reference;

                // project overview
                caseRecord.Tallest_Pole_Height__c = Utilities.isNullOrBlank(appProjectDetails.overview.application_project_overview.max_structure_height_m) ? null : appProjectDetails.overview.application_project_overview.max_structure_height_m;
                // caseRecord.Applicant_Reference__c = appProjectDetails.overview.application_project_overview.plan_reference;
                if (Utilities.isNullOrBlank(appProjectDetails.overview.application_project_overview.earliest_work_start_date_year) == false &&
                    Utilities.isNullOrBlank(appProjectDetails.overview.application_project_overview.earliest_work_start_date_month) == false) {
                    caseRecord.Earliest_Expected_Start_Date__c = Date.newInstance(
                        Integer.valueOf(appProjectDetails.overview.application_project_overview.earliest_work_start_date_year),
                        Integer.valueOf(appProjectDetails.overview.application_project_overview.earliest_work_start_date_month),
                        1
                    );
                }
                
                if (Utilities.isNullOrBlank(appProjectDetails.overview.application_project_overview.latest_work_start_date_year) == false &&
                    Utilities.isNullOrBlank(appProjectDetails.overview.application_project_overview.latest_work_start_date_month) == false) {
                    caseRecord.Latest_Expected_Start_Date__c = Date.newInstance(
                        Integer.valueOf(appProjectDetails.overview.application_project_overview.latest_work_start_date_year),
                        Integer.valueOf(appProjectDetails.overview.application_project_overview.latest_work_start_date_month),
                        1
                    );
                }
            }
        } catch (Exception ex) {
            Utilities.log(Utilities.formatException(ex));
        }

        Utilities.logMethodExit('s37_PopulateProjectDetails');
    }

    private static Map<String, List<SObject>> s37_PopulateRoutes(Case__c caseRecord, List<S37ApplicationDTO.Route> appRouteList) {
        Utilities.logMethodEntry('s37_PopulateRoutes');
        if (appRouteList == null || Utilities.isNullOrBlank(appRouteList) || appRouteList.isEmpty()) {
            Utilities.log('appRouteList is empty');
            Utilities.logMethodExit('s37_PopulateRoutes');
            return new Map<String, List<SObject>>();
        }
        try {
                
            Map<String, List<SObject>> routePointsMap = new Map<String, List<SObject>>();
            routePointsMap.put('Route__c', new List<Route__c>());
            routePointsMap.put('Route_Point__c', new List<Route_Point__c>());

            for (S37ApplicationDTO.Route appRoute : appRouteList) {
                Route__c routeRecord = new Route__c();
                routeRecord.Name = Utilities.isNullOrBlank(appRoute.routeName) ? null : appRoute.routeName;
                routeRecord.Disconnected_Route_Justification__c = Utilities.isNullOrBlank(appRoute.disconnectedroute_justification) ? null : appRoute.disconnectedroute_justification;
                routeRecord.Case__c = caseRecord.Id;
                routeRecord.Route_Id__c = Utilities.isNullOrBlank(appRoute.route_id) ? null : appRoute.route_id;
                routePointsMap.get('Route_Point__c').addAll(s37_PopulateRoutePoints(routeRecord, appRoute.gridPoints));
                routePointsMap.get('Route__c').add(routeRecord);
            }
            System.debug('Populated Route Records and Route Point Records: ' + routePointsMap);
            
            Utilities.logMethodExit('s37_PopulateRoutes');
            return routePointsMap;
        } catch (Exception ex) {
            Utilities.log(Utilities.formatException(ex));
        }
        Utilities.logMethodExit('s37_PopulateRoutes');
        return null;
    }

    private static List<Route_Point__c> s37_PopulateRoutePoints(Route__c routeRecord, List<S37ApplicationDTO.GridPoint> appGridPointList) {
        Utilities.logMethodEntry('s37_PopulateRoutePoints');
        if (appGridPointList == null || Utilities.isNullOrBlank(appGridPointList) || appGridPointList.isEmpty()) {
            Utilities.log('appGridPointList is empty');
            Utilities.logMethodExit('s37_PopulateRoutePoints');
            return null;
        }

        try {
                
            List<Route_Point__c> routePointRecords = new List<Route_Point__c>();
            for (S37ApplicationDTO.GridPoint appGridPoint : appGridPointList) {
                Route_Point__c routePointRecord = new Route_Point__c();
                routePointRecord.Northing__c = Utilities.isNullOrBlank(appGridPoint.northing) ? null : String.valueOf(appGridPoint.northing);
                routePointRecord.Easting__c = Utilities.isNullOrBlank(appGridPoint.easting) ? null : String.valueOf(appGridPoint.easting);
                routePointRecord.Route__c = routeRecord.Id;
                routePointRecord.Route_Id__c = routeRecord.Route_Id__c;
                routePointRecord.Route_Point_Id__c = Utilities.isNullOrBlank(appGridPoint.point_id) ? null : appGridPoint.point_id;
                routePointRecords.add(routePointRecord);
            }
            Utilities.logMethodExit('s37_PopulateRoutePoints');
            return routePointRecords;
        } catch (Exception ex) {
            Utilities.log(Utilities.formatException(ex));
        }
        Utilities.logMethodExit('s37_PopulateRoutePoints');
        return null;
    }

    public static  Map<String, List<SObject>> s37_PopulateCaseFieldsFromParty(Case__c caseRecord, List<S37ApplicationDTO.ApplicationParty> appPartyList) {
        
        Utilities.logMethodEntry('s37_PopulateCaseFieldsFromParty');
        if (appPartyList == null || Utilities.isNullOrBlank(appPartyList) || appPartyList.isEmpty()) {
            Utilities.log('appPartyList is empty');
            Utilities.logMethodExit('s37_PopulateCaseFieldsFromParty');
            return new Map<String, List<SObject>>();
        }

        try {
            List<Party__c> partyRecords = new List<Party__c>();
            List<Case_Party__c> casePartyRecords = new List<Case_Party__c>();
            List<Address__c> addressRecords = new List<Address__c>();

            Map<String, List<SObject>> casePartyMap = new Map<String, List<SObject>>();
            // Populate fields based on appParty
            for (S37ApplicationDTO.ApplicationParty record: appPartyList) {
                
                Party__c partyRecord = new Party__c();
                Case_Party__c appParty = new Case_Party__c();
                partyRecord.RecordTypeId = Schema.SObjectType.Party__c.getRecordTypeInfosByDeveloperName().get('Organisation').getRecordTypeId();

                partyRecord.Party_Type__c = record.role == 'Applicant' ? 'DNO' : 'Organisation';
                partyRecord.Name = Utilities.isNullOrBlank(record.organisation_name) ? (Utilities.isNullOrBlank(record.person_name) ? null : record.person_name) : record.organisation_name;
                partyRecord.Email__c = Utilities.isNullOrBlank(record.email) ? null : record.email;
                partyRecord.Phone__c = Utilities.isNullOrBlank(record.phone) ? null : record.phone;
                partyRecord.Is_Primary__c = Utilities.isNullOrBlank(record.is_primary) ? false : record.is_primary;
                partyRecord.Application_Party_Id__c = Utilities.isNullOrBlank(record.application_party_id) ? null : record.application_party_id;
                partyRecord.Person_Identification__c = Utilities.isNullOrBlank(record.person_id) ? null : record.person_id;

                Address__c addressRecord = new Address__c();
                addressRecord.Address_Line1__c = Utilities.isNullOrBlank(record.line1) ? null : record.line1;
                addressRecord.Address_Line_2__c = Utilities.isNullOrBlank(record.line2) ? null : record.line2;
                addressRecord.Town_City__c = Utilities.isNullOrBlank(record.town_city) ? null : record.town_city;
                addressRecord.Postcode__c = Utilities.isNullOrBlank(record.postcode) ? null : record.postcode;
                addressRecord.Country__c = Utilities.isNullOrBlank(record.country) ? null : record.country;
                addressRecord.Application_Party_Identification__c = Utilities.isNullOrBlank(record.application_party_id) ? null : record.application_party_id;
                if (record.is_primary) {
                    caseRecord.DNO__c = partyRecord.Id;
                }

                // 
                Case_Party__c caseParty = new Case_Party__c();
                caseParty.Case__c = caseRecord.Id;
                caseParty.Party__c = partyRecord.Id;
                caseParty.Application_Party_Id__c = Utilities.isNullOrBlank(record.application_party_id) ? null : record.application_party_id;
                caseParty.Name = '' + caseRecord.Name + ' - ' + partyRecord.Name;

                //Representative Details
                Party__c representativeParty = new Party__c();
                representativeParty.Name = Utilities.isNullOrBlank(record.person_name) ? null : record.person_name;
                representativeParty.Email__c = Utilities.isNullOrBlank(record.email) ? null : record.email;
                representativeParty.Phone__c = Utilities.isNullOrBlank(record.phone) ? null : record.phone;
                representativeParty.Party_Type__c = 'Individual';
                representativeParty.RecordTypeId = Schema.SObjectType.Party__c.getRecordTypeInfosByDeveloperName().get('Individual').getRecordTypeId();
                representativeParty.Person_Identification__c = Utilities.isNullOrBlank(record.person_id) ? null : record.person_id;

                
                casePartyRecords.add(caseParty);
                partyRecords.add(partyRecord);
                addressRecords.add(addressRecord);
                partyRecords.add(representativeParty);
            }
            casePartyMap.put('Party__c', partyRecords);
            casePartyMap.put('Case_Party__c', casePartyRecords);
            casePartyMap.put('Address__c', addressRecords);

            Utilities.logMethodExit('s37_PopulateCaseFieldsFromParty');
            return casePartyMap;
        } catch (Exception ex) {
            Utilities.log(Utilities.formatException(ex));
        }
        Utilities.logMethodExit('s37_PopulateCaseFieldsFromParty');
        return null;
    }

    public static List<Sensitive_Area_Check__c> S37_PopulateSensitiveAreaCheckDetails(Case__c caseRecord, S37ApplicationDTO.SensitiveAreaChecks sensitiveAreaChecks) {
        Utilities.logMethodEntry('S37_PopulateSensitiveAreaCheckDetails');
        if (sensitiveAreaChecks == null 
            || Utilities.isNullOrBlank(sensitiveAreaChecks) 
            || sensitiveAreaChecks.layers == null 
            || sensitiveAreaChecks.layers.isEmpty()
        ) {
            Utilities.log('sensitiveAreaChecks is empty');
            Utilities.logMethodExit('S37_PopulateSensitiveAreaCheckDetails');
            return null;
        }
        
        List<Sensitive_Area_Check__c> sensitiveAreaCheckRecordList = new List<Sensitive_Area_Check__c>();
        try {
            for (String layer : sensitiveAreaChecks.layers) {
                System.debug('Sensitive Area Layer: ' + layer);
                // Populate fields based on sensitiveAreaCheck
                Sensitive_Area_Check__c sensitiveAreaCheckRecord = new Sensitive_Area_Check__c();
                sensitiveAreaCheckRecord.Case__c = caseRecord.Id;
                sensitiveAreaCheckRecord.Name = layer;

                sensitiveAreaCheckRecordList.add(sensitiveAreaCheckRecord);
            }
            Utilities.logMethodExit('S37_PopulateSensitiveAreaCheckDetails');
            return sensitiveAreaCheckRecordList;
            
        } catch (Exception ex) {
            Utilities.log(Utilities.formatException(ex));
        }
        Utilities.logMethodExit('S37_PopulateSensitiveAreaCheckDetails');
        return null;
    }

    public static void s37_populateSupportingInformation(Case__c caseRecord, S37ApplicationDTO.SupportingInformation appSupportingInfo) {
        Utilities.logMethodEntry('s37_populateSupportingInformation');
        if (appSupportingInfo == null || Utilities.isNullOrBlank(appSupportingInfo)) {
            Utilities.log('appSupportingInfo is empty');
            Utilities.logMethodExit('s37_populateSupportingInformation');
            return;
        }

        try {
            // Populate fields based on appSupportingInfo
            if (appSupportingInfo != null) {
                caseRecord.Have_All_Wayleaves_Been_Obtained__c = Utilities.isNullOrBlank(appSupportingInfo.supportingQuestions.wayleaves_obtained) ? null : ( appSupportingInfo.supportingQuestions.wayleaves_obtained == true ? 'Yes' : 'No' );
                caseRecord.Comments_to_Support_Application__c = Utilities.isNullOrBlank(appSupportingInfo.supportingQuestions.applicant_supporting_comments) ? null : appSupportingInfo.supportingQuestions.applicant_supporting_comments;
                caseRecord.Why_Have_All_Wayleaves_Not_Been_Obtained__c = Utilities.isNullOrBlank(appSupportingInfo.supportingQuestions.wayleaves_not_obtained_reason) ? null : appSupportingInfo.supportingQuestions.wayleaves_not_obtained_reason;
                caseRecord.Works_Comply_With_ESQCR__c = Utilities.isNullOrBlank(appSupportingInfo.supportingQuestions.esqcr_2002_compliance_confirmed) ? null : (appSupportingInfo.supportingQuestions.esqcr_2002_compliance_confirmed == true ? 'Yes' : 'No');
            }
        } catch (Exception ex) {
            Utilities.log(Utilities.formatException(ex));
        }
        Utilities.logMethodExit('s37_populateSupportingInformation');
    }

    public static List<Asset_Information__c> s37_populateAssetInformation(Case__c caseRecord, List<S37ApplicationDTO.AssetInformation> appAssetInfoList) {
        Utilities.logMethodEntry('s37_populateAssetInformation');
        if (appAssetInfoList == null || Utilities.isNullOrBlank(appAssetInfoList)) {
            Utilities.log('appAssetInfoList is empty');
            Utilities.logMethodExit('s37_populateAssetInformation');
            return null;
        }

        try {
            List<Asset_Information__c> assetInfoRecords = new List<Asset_Information__c>();

            for( S37ApplicationDTO.AssetInformation asset : appAssetInfoList ) {
                System.debug('Existing Asset Details: ' + asset);
                // Populate fields based on asset

                Asset_Information__c assetInfoRecord = new Asset_Information__c();
                assetInfoRecord.Case__c = caseRecord.Id;
                assetInfoRecord.TORI_NOI_Code__c = Utilities.isNullOrBlank(asset.tori_noi) ? null : asset.tori_noi;
                assetInfoRecord.Line_Type__c = Utilities.isNullOrBlank(asset.asset_type) ? null : asset.asset_type;
                assetInfoRecord.Description__c = Utilities.isNullOrBlank(asset.description) ? null : asset.description;
                assetInfoRecord.Standard_Specification_Reference_Number__c = Utilities.isNullOrBlank(asset.asset_reference) ? null : asset.asset_reference;
                assetInfoRecords.add( assetInfoRecord );
            }

            Utilities.logMethodExit('s37_populateAssetInformation');
            return assetInfoRecords;

        } catch (Exception ex) {
            Utilities.log(Utilities.formatException(ex));
        }
        Utilities.logMethodExit('s37_populateAssetInformation');
        return null;
    }

}