public with sharing class GW_CustomCase {
    public GW_CustomCase() {}

    public static void createS37CaseFromAWS(S37ApplicationDTO s37AppDTO) {
        // Implementation for creating S37 case from AWS data
        Case__c newCase = new Case__c();
        // sections from s37AppDTO
        s37_PopulateCaseFields(newCase, s37AppDTO);
        s37_PopulateRoutes(newCase, s37AppDTO.sections.location.routes);
        s37_PopulateCaseFieldsFromParty(newCase, s37AppDTO.sections.application_party);
        
        insert newCase;

    }

    // helper methods
    private static Case__c s37_PopulateCaseFields(Case__c caseRecord, S37ApplicationDTO s37AppDTO) {
        // Populate fields based on s37AppDTO
        caseRecord.Name = s37AppDTO.applicationId;
        caseRecord.Case_Type__c = s37AppDTO.formType == 'S37' ? 'Section 37' : 'Unknown';
        caseRecord.DNO_Name__c = s37AppDTO.applicationId;
        caseRecord.Application_Fee_Paid__c = 'Yes';

        // project details
        s37_PopulateProjectDetails(caseRecord, s37AppDTO.sections.projectDetails);

        return caseRecord;
    }

    private static void s37_PopulateProjectDetails(Case__c caseRecord, S37ApplicationDTO.ProjectDetails appProjectDetails) {
        // Populate fields based on appProjectDetails
        // project details
        if (appProjectDetails != null) {
            // core project details
            caseRecord.Project_Name__c = appProjectDetails.overview.project_details.project_name;
            caseRecord.Project_Description__c = appProjectDetails.overview.project_details.project_description;

            // project overview
            caseRecord.Tallest_Pole_Height__c = appProjectDetails.overview.application_project_overview.max_structure_height_m;
            caseRecord.Applicant_Reference__c = appProjectDetails.overview.application_project_overview.plan_reference;
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
    }

    private static List<Route__c> s37_PopulateRoutes(Case__c caseRecord, List<S37ApplicationDTO.Route> appRouteList) {
        List<Route__c> routeRecords = new List<Route__c>();
        for (S37ApplicationDTO.Route appRoute : appRouteList) {
            Route__c routeRecord = new Route__c();
            routeRecord.Name = appRoute.routeName;
            routeRecord.Case__c = caseRecord.Id;
            s37_PopulateRoutePoints(routeRecord, appRoute.gridPoints);
            routeRecords.add(routeRecord);
        }
        return routeRecords;
    }

    private static List<Route_Point__c> s37_PopulateRoutePoints(Route__c routeRecord, List<S37ApplicationDTO.GridPoint> appGridPointList) {
        List<Route_Point__c> routePointRecords = new List<Route_Point__c>();
        for (S37ApplicationDTO.GridPoint appGridPoint : appGridPointList) {
            Route_Point__c routePointRecord = new Route_Point__c();
            routePointRecord.Northing__c = String.valueOf(appGridPoint.northing);
            routePointRecord.Easting__c = String.valueOf(appGridPoint.easting);
            routePointRecord.Route__c = routeRecord.Id;
            routePointRecords.add(routePointRecord);
        }
        return routePointRecords;
    }

    private static	Party__c s37_PopulateCaseFieldsFromParty(Case__c caseRecord, List<S37ApplicationDTO.ApplicationParty> appPartyList) {
        // Populate fields based on appParty
        Party__c partyRecord = new Party__c();
        // for (S37ApplicationDTO.ApplicationParty record: appPartyList) {
            
        //     Party__c partyRecord = new Party__c();
        //     Case_Party__c appParty = new Case_Party__c();
        //     appParty.Case__c = caseRecord.Id;
        //     appParty.ParType__cty_Type__c = record.role;

        //     partyRecord.Party_Type__c = record.party_type;
        //     partyRecord.person_name__c = record.person_name;
        //     partyRecord.email__c = record.email;
        //     partyRecord.phone__c = record.phone;
        //     partyRecord.address_line_1__c = record.address_line_1;
        //     partyRecord.address_line_2__c = record.address_line_2;
        //     partyRecord.town__c = record.town;
        //     partyRecord.county__c = record.county;
        //     partyRecord.postcode__c = record.postcode;
        //     partyRecord.country__c = record.country;

        // }
        // appParty = appPartyList[0];

        // caseRecord.Contact_Email__c = appParty.email;
        // caseRecord.Contact_Phone__c = appParty.phone;
        // // caseRecord.Applicant_Name__c = appParty.person_name;

        return partyRecord;
    }
}