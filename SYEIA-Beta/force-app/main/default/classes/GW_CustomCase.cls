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
            caseRecordAndRelatedRecords.putAll(routes);
            caseRecordAndRelatedRecords.putAll(s37_PopulateCaseFieldsFromParty(newCase, s37AppDTO.sections.application_party));

            Sensitive_Area_Check__c sensitiveAreaReviewRecord = S37_PopulateSensitiveAreaCheckDetails(newCase, s37AppDTO.sections.sensitiveAreaReview);
            caseRecordAndRelatedRecords.put('Sensitive_Area_Check__c', new List<SObject>{sensitiveAreaReviewRecord});
            
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

	@future
	public static void updateInboundRequestStatus(Id inboundReqId, String errorMessages) {
        Utilities.logMethodEntry('updateInboundRequestStatus');
        try{
            Inbound_Request__c inboundReq = [SELECT Id, Status__c FROM Inbound_Request__c WHERE Id = :inboundReqId];
            if (errorMessages != '') {
                inboundReq.Status__c = 'Failed';
                inboundReq.Error_Log_Text__c = errorMessages;
            } else {
                inboundReq.Status__c = 'Processed';
            }
            update inboundReq;
        } catch(Exception e){
            Utilities.log(Utilities.formatException(e));
        }
        Utilities.logMethodExit('updateInboundRequestStatus');
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
            caseRecord.Number_Of_Poles_Being_Added__c = appWorksOverview.polesAdded;
            caseRecord.Comments_to_Support_Application__c = appWorksOverview.poleComments;
            caseRecord.Materials_For_New_Poles_Pylons__c = appWorksOverview.poleMaterial != null ? String.valueOf(appWorksOverview.poleMaterial) : null;
            caseRecord.Number_Of_Poles_Being_Replaced__c = appWorksOverview.polesReplaced != null ? Integer.valueOf(appWorksOverview.polesReplaced) : null;
            caseRecord.General_Comments__c = appWorksOverview.generalComments;
            caseRecord.Vehicles_Required_On_Site__c = appWorksOverview.vehiclesRequired;
            caseRecord.Estimated_Duration_Of_Works__c = appWorksOverview.estimatedDuration != null ? String.valueOf(appWorksOverview.estimatedDuration) : null;
            caseRecord.Excavation_Works_Required__c = appWorksOverview.excavationRequired != null && appWorksOverview.excavationRequired == true ? 'Yes' : 'No';
            caseRecord.Details_Of_Excavation_Works__c = appWorksOverview.excavationDetails;
            caseRecord.Any_Chemical_Treatments_Proposed__c = appWorksOverview.chemicalTreatments != null ? String.valueOf(appWorksOverview.chemicalTreatments) : null;
            caseRecord.Details_Of_Equipment_Removal__c = appWorksOverview.removalDescription;
            caseRecord.Details_Of_Access_Storage_Sites__c = appWorksOverview.accessRoutesDetails;
            caseRecord.Road_Closures_Or_Traffic_Calming__c = appWorksOverview.roadClosuresRequired != null && appWorksOverview.roadClosuresRequired == true ? 'Yes' : 'No';
            caseRecord.Adding_Or_Replacing_Any_Overhead_Lines__c = appWorksOverview.addingOrReplacingLines != null && appWorksOverview.addingOrReplacingLines == true ? 'Yes' : 'No';
            caseRecord.Adding_Or_Replacing_Any_Overhead_Poles__c = appWorksOverview.addingOrReplacingPoles != null && appWorksOverview.addingOrReplacingPoles == true ? 'Yes' : 'No';
            caseRecord.Description_Of_Overhead_Lines__c = appWorksOverview.overheadLineDescription;
            caseRecord.Is_Any_Existing_Equipment_Being_Removed__c = appWorksOverview.removingExistingEquipment != null && appWorksOverview.removingExistingEquipment == true ? 'Yes' : 'No';
            caseRecord.Pre_existing_Routes_Storage_Used__c = appWorksOverview.usingExistingAccessRoutes != null && appWorksOverview.usingExistingAccessRoutes == true ? 'Yes' : 'No';
            caseRecord.Details_Of_Vegetation_Clearance__c = appWorksOverview.vegetationClearanceDetails;
            caseRecord.Vegetation_Clearance_Required__c = appWorksOverview.vegetationClearanceRequired != null && appWorksOverview.vegetationClearanceRequired == true ? 'Yes' : 'No';
        } catch (Exception ex) {
            Utilities.log(Utilities.formatException(ex));
        }
        
        Utilities.logMethodExit('s37_populateWorksOverview');
    }

    private static void s37_populateEiaDetails(Case__c caseRecord, S37ApplicationDTO.EiaFees appEiaDetails) {
        Utilities.logMethodEntry('s37_populateEiaDetails');
        if (appEiaDetails == null) {
            Utilities.log('appEiaDetails is empty');
            Utilities.logMethodExit('s37_populateEiaDetails');
            return;
        }

        try {
                
            // Populate fields based on appEiaDetails
            if (appEiaDetails != null) {
                if (appEiaDetails.requires_full_eia != null && appEiaDetails.requires_full_eia == true) {
                    caseRecord.Full_EIA_Process_or_Screening_Opinion__c = 'Full EIA Process';
                } else if (appEiaDetails.screening_only != null && appEiaDetails.screening_only == true) {
                    caseRecord.Full_EIA_Process_or_Screening_Opinion__c = 'Screening Opinion';
                } else {
                    caseRecord.Full_EIA_Process_or_Screening_Opinion__c = null;
                }
                
                // caseRecord.EIA_Screening_Opinion_Date__c = appEiaDetails.eia_screening_opinion_date != null ? Date.valueOf(appEiaDetails.eia_screening_opinion_date.substring(0,10)) : null;
            }
        } catch (Exception ex) {
            Utilities.log(Utilities.formatException(ex));
        }
        Utilities.logMethodExit('s37_populateEiaDetails');
    }

    private static void s37_populateNetworkOperatorDetails(Case__c caseRecord, S37ApplicationDTO.NetworkOperator appNetworkOperator) {
        Utilities.logMethodEntry('s37_populateNetworkOperatorDetails');
        if (appNetworkOperator == null) {
            Utilities.log('appNetworkOperator is empty');
            Utilities.logMethodExit('s37_populateNetworkOperatorDetails');
            return;
        }

        try {
                
            // Populate fields based on appNetworkOperator
            if (appNetworkOperator != null) {
                caseRecord.Applicant_Reference__c = appNetworkOperator.details.operator_ref;
                caseRecord.Date_of_Application__c = appNetworkOperator.details.submitted_at != null ? Date.valueOf(appNetworkOperator.details.submitted_at.substring(0,10)) : null;
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
        if (appProjectDetails == null) {
            Utilities.log('appProjectDetails is empty');
            Utilities.logMethodExit('s37_PopulateProjectDetails');
            return;
        }

        try {
            // Populate fields based on appProjectDetails
            // project details
            if (appProjectDetails != null) {
                // core project details
                caseRecord.Project_Name__c = appProjectDetails.overview.project_details.project_name;
                caseRecord.Project_Description__c = appProjectDetails.overview.project_details.project_description;
                // caseRecord.Related_CPO_Details__c = appProjectDetails.overview.application_project_overview.;
                // caseRecord.Plan_Reference__c = appProjectDetails.overview.application_project_overview.plan_reference;

                // project overview
                caseRecord.Tallest_Pole_Height__c = appProjectDetails.overview.application_project_overview.max_structure_height_m;
                // caseRecord.Applicant_Reference__c = appProjectDetails.overview.application_project_overview.plan_reference;
                caseRecord.Earliest_Expected_Start_Date__c = Date.newInstance(
                    appProjectDetails.overview.application_project_overview.earliest_work_start_date_year,
                    appProjectDetails.overview.application_project_overview.earliest_work_start_date_month,
                    1
                );
                caseRecord.Latest_Expected_Start_Date__c = Date.newInstance(
                    appProjectDetails.overview.application_project_overview.latest_work_start_date_year,
                    appProjectDetails.overview.application_project_overview.latest_work_start_date_month,
                    1
                );
            }
        } catch (Exception ex) {
            Utilities.log(Utilities.formatException(ex));
        }

        Utilities.logMethodExit('s37_PopulateProjectDetails');
    }

    private static Map<String, List<SObject>> s37_PopulateRoutes(Case__c caseRecord, List<S37ApplicationDTO.Route> appRouteList) {
        Utilities.logMethodEntry('s37_PopulateRoutes');
        if (appRouteList == null) {
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
                routeRecord.Name = appRoute.routeName;
                routeRecord.Disconnected_Route_Justification__c = appRoute.disconnectedroute_justification;
                routeRecord.Case__c = caseRecord.Id;
                routeRecord.Route_Id__c = appRoute.route_id;
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
        if (appGridPointList == null) {
            Utilities.log('appGridPointList is empty');
            Utilities.logMethodExit('s37_PopulateRoutePoints');
            return null;
        }

        try {
                
            List<Route_Point__c> routePointRecords = new List<Route_Point__c>();
            for (S37ApplicationDTO.GridPoint appGridPoint : appGridPointList) {
                Route_Point__c routePointRecord = new Route_Point__c();
                routePointRecord.Northing__c = String.valueOf(appGridPoint.northing);
                routePointRecord.Easting__c = String.valueOf(appGridPoint.easting);
                routePointRecord.Route__c = routeRecord.Id;
                routePointRecord.Route_Id__c = routeRecord.Route_Id__c;
                routePointRecord.Route_Point_Id__c = appGridPoint.point_id;
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

        try {
            List<Party__c> partyRecords = new List<Party__c>();
            List<Case_Party__c> casePartyRecords = new List<Case_Party__c>();

            Map<String, List<SObject>> casePartyMap = new Map<String, List<SObject>>();
            // Populate fields based on appParty
            for (S37ApplicationDTO.ApplicationParty record: appPartyList) {
                
                Party__c partyRecord = new Party__c();
                Case_Party__c appParty = new Case_Party__c();
                partyRecord.RecordTypeId = Schema.SObjectType.Party__c.getRecordTypeInfosByDeveloperName().get('Organisation').getRecordTypeId();

                partyRecord.Party_Type__c = record.role == 'Applicant' ? 'DNO' : 'Organisation';
                partyRecord.Name = record.organisation_name ?? record.person_name;
                partyRecord.Email__c = record.email;
                partyRecord.Phone__c = record.phone;
                partyRecord.Is_Primary__c = record.is_primary;
                partyRecord.Application_Party_Id__c = record.application_party_id;

                Address__c addressRecord = new Address__c();
                addressRecord.Address_Line1__c = record.line1 != null ? record.line1 : null;
                addressRecord.Address_Line_2__c = record.line2 != null ? record.line2 : null;
                addressRecord.Town_City__c = record.town_city != null ? record.town_city : null;
                addressRecord.Postcode__c = record.postcode != null ? record.postcode : null;
                addressRecord.Country__c = record.country != null ? record.country : null;
                if (record.is_primary) {
                    caseRecord.DNO__c = partyRecord.Id;
                }

                // 
                Case_Party__c caseParty = new Case_Party__c();
                caseParty.Case__c = caseRecord.Id;
                caseParty.Party__c = partyRecord.Id;
                caseParty.Application_Party_Id__c = record.application_party_id;
                caseParty.Name = '' + caseRecord.Name + ' - ' + partyRecord.Name;

                //Representative Details
                // Party__c representativeParty = new Party__c();
                // representativeParty.Name = record.person_name;
                // representativeParty.Email__c = record.email;
                // representativeParty.Phone__c = record.phone;
                // representativeParty.Party_Type__c = representativeParty.Id;
                // representativeParty.RecordTypeId = Schema.SObjectType.Party__c.getRecordTypeInfosByDeveloperName().get('Representative').getRecordTypeId();

                
                casePartyRecords.add(caseParty);
                partyRecords.add(partyRecord);
                // partyRecords.add(representativeParty);
            }
            casePartyMap.put('Party__c', partyRecords);
            casePartyMap.put('Case_Party__c', casePartyRecords);

            Utilities.logMethodExit('s37_PopulateCaseFieldsFromParty');
            return casePartyMap;
        } catch (Exception ex) {
            Utilities.log(Utilities.formatException(ex));
        }
        Utilities.logMethodExit('s37_PopulateCaseFieldsFromParty');
        return null;
    }

    public static Sensitive_Area_Check__c S37_PopulateSensitiveAreaCheckDetails(Case__c caseRecord, S37ApplicationDTO.SensitiveAreaReview sensitiveAreaReview) {
        Utilities.logMethodEntry('S37_PopulateSensitiveAreaCheckDetails');
        if (sensitiveAreaReview == null) {
            Utilities.log('sensitiveAreaReview is empty');
            Utilities.logMethodExit('S37_PopulateSensitiveAreaCheckDetails');
            return null;
        }
        
        try {
            // Populate fields based on sensitiveAreaCheck
            Sensitive_Area_Check__c sensitiveAreaCheckRecord = new Sensitive_Area_Check__c();
            sensitiveAreaCheckRecord.Case__c = caseRecord.Id;

            Utilities.logMethodExit('S37_PopulateSensitiveAreaCheckDetails');
            return sensitiveAreaCheckRecord;
            
        } catch (Exception ex) {
            Utilities.log(Utilities.formatException(ex));
        }
        Utilities.logMethodExit('S37_PopulateSensitiveAreaCheckDetails');
        return null;
    }

}