/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an org are executed whenever Apex code is deployed
 * to a production org to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production org. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the org size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class InboundRequestTriggerHelperTest {

    private static string payload = '{\n  \"formType\": \"S37\",\n  \"metadata\": {\n    \"source\": \"SYEIA\",\n    \"schemaVersion\": 1\n  },\n  \"applicationId\": \"11111111-aaaa-4aaa-aaaa-aaaaaaaaaaaa1111\",\n \n  \"sections\": {\n    \"location\": {\n      \"routes\": [\n        {\n          \"route_id\": \"a6916835-4c6e-47dd-9efd-217c5f7170e0\",\n          \"routeName\": \"Route A\",\n          \"gridPoints\": [\n            { \"point_id\": \"cfb8a907-304f-4ebc-93d3-5b98467a9354\", \"easting\": 500000, \"northing\": 200000 },\n            { \"point_id\": \"14084975-3fa2-4e08-9d49-32158118a442\", \"easting\": 400000, \"northing\": 200000 }\n          ],\n          \"disconnectedroute_justification\": null\n        },\n        {\n          \"route_id\": \"f5fdd625-c40f-4c25-af08-b1f1f75f4b25\",\n          \"routeName\": \"Route B\",\n          \"gridPoints\": [\n            { \"point_id\": \"d1a03736-1e2a-428c-ab85-5b8b554b002a\", \"easting\": 250000, \"northing\": 200001 },\n            { \"point_id\": \"d842e027-0590-48b0-87be-530e1fc812f6\", \"easting\": 200000, \"northing\": 200000 }\n          ],\n          \"disconnectedroute_justification\": \"underground line\"\n        }\n      ]\n    },\n    \"parishes\": [],\n    \"worksOverview\": {\n      \"createdBy\": \"system\",\n      \"lastUpdatedBy\": null,\n      \"applicationId\": \"111113111-aaaa-4aaa-aaaa-aaaaaaaaaaaa\",\n      \"polesAdded\": 122,\n      \"polesReplaced\": 123,\n      \"poleMaterial\": 2312,\n      \"poleComments\": null,\n      \"vehiclesRequired\": null,\n      \"estimatedDuration\": 1231,\n      \"excavationRequired\": true,\n      \"excavationDetails\": \"vbnvb\",\n      \"chemicalTreatments\": 12312,\n      \"removalDescription\": \"tyjyuj\",\n      \"accessRoutesDetails\": \"qweq\",\n      \"roadClosuresRequired\": true,\n      \"addingOrReplacingLines\": true,\n      \"addingOrReplacingPoles\": true,\n      \"overheadLineDescription\": \"Desc\",\n      \"removingExistingEquipment\": true,\n      \"usingExistingAccessRoutes\": true,\n      \"vegetationClearanceRequired\": true,\n      \"vegetationClearanceDetails\": \"zxcz\",\n      \"generalComments\": null\n    },\n \n    \"sensitiveAreaChecks\": {\n      \"application_id\": \"11111111-aaaa-4aaa-aaaa-aaaaaaaaaaaa\",\n      \"layers\": [\n        \"Ancient Woodland (England)\",\n        \"Areas of Outstanding Natural Beauty (England) (National Landscape)\",\n        \"National Nature Reserves (England)\",\n        \"Ramsar Sites (England)\",\n        \"Registered Parks and Gardens (England)\",\n        \"Sites of Special Scientific Interest (England)\",\n        \"SSSI Impact Risk Zones (England)\"\n      ]\n    },\n \n    \"sensitiveAreaReview\": {\n      \"id\": \"47f3eb33-209f-4032-91f5-a058c5514224\",\n      \"route_id\": \"a6916835-4c6e-47dd-9efd-217c5f7170e0\",\n      \"created_at\": \"2025-11-03T11:33:05.767Z\",\n      \"updated_at\": \"2025-11-03T11:33:05.767Z\",\n      \"reviewed_at\": null,\n      \"reviewed_by\": null,\n      \"settings_id\": \"513a2d25-056e-4b66-9973-2fac018663e5\",\n      \"asset_presence_option_id\": 3,\n      \"other_sensitive_areas_note\": \"qwe\"\n    },\n \n    \"projectDetails\": {\n      \"overview\": {\n        \"project_details\": {\n          \"project_id\": \"aaaa1111-aaaa-aaaa-aaaa-aaaaaaaaaaaa\",\n          \"project_name\": \"Project Alpha\",\n          \"project_description\": \"Alpha project description\",\n          \"created_at\": \"2025-11-03T11:27:11.182Z\",\n          \"created_by\": \"44444444-4444-4444-4444-444444444444\",\n          \"updated_at\": \"2025-11-03T11:27:11.182Z\"\n        },\n        \"application_project_overview\": {\n          \"plan_reference\": \"PlanRef-001\",\n          \"max_structure_height_m\": 45.50,\n          \"earliest_work_start_date_year\": 2025,\n          \"earliest_work_start_date_month\": 1,\n          \"latest_work_start_date_year\": 2025,\n          \"latest_work_start_date_month\": 12\n        },\n        \"planDocuments\": [\n          {\n            \"title\": \"Plan Document\",\n            \"description\": \"Test plan document\",\n            \"file_id\": \"11111111-aaaa-aaaa-aaaa-aaaaaaaaaaaa\",\n            \"document_id\": \"66666666-ffff-4fff-ffff-ffffffffffff\",\n            \"virtual_folder\": \"plans\",\n            \"added_at\": \"2025-11-03T11:27:11.182Z\",\n            \"added_by\": \"44444444-4444-4444-4444-444444444444\",\n            \"category\": \"PLAN_INFO\",\n            \"subcategory\": null\n          }\n        ],\n        \"application_relations\": [\n          {\n            \"application_relation_id\": \"44444444-dddd-4ddd-dddd-dddddddddddd\",\n            \"project_name\": \"Project Beta\",\n            \"relation_type\": \"ASSOCIATED\",\n            \"related_application_id\": \"22222222-bbbb-4bbb-bbbb-bbbbbbbbbbbb\",\n            \"details\": \"Related to Beta\",\n            \"created_at\": \"2025-11-03T11:27:11.182Z\"\n          }\n        ]\n      }\n    },\n \n    \"assetInformation\": [\n      {\n        \"asset_id\": \"11111111-1111-4111-8111-111111111111\",\n        \"asset_type\": \"OHL\",\n        \"tori_noi\": null,\n        \"asset_reference\": \"REF-001\",\n        \"description\": \"Install 5 new poles, add a new OHL span, and remove 1 tower.\",\n        \"is_existing\": true,\n        \"created_at\": \"2025-11-03T11:27:11.192Z\",\n        \"created_by\": \"system\",\n        \"last_updated_at\": \"2025-11-03T11:27:11.192Z\",\n        \"last_updated_by\": \"system\"\n      },\n      {\n        \"asset_id\": \"55555555-5555-4555-8555-555555555555\",\n        \"asset_type\": \"OHL\",\n        \"tori_noi\": null,\n        \"asset_reference\": \"REF-004\",\n        \"description\": \"add 2 new spans, and remove 4 poles.\",\n        \"is_existing\": false,\n        \"created_at\": \"2025-11-03T11:27:11.192Z\",\n        \"created_by\": \"admin\",\n        \"last_updated_at\": \"2025-11-03T11:27:11.192Z\",\n        \"last_updated_by\": \"admin\"\n      }\n    ],\n \n    \"networkOperator\": {\n      \"details\": {\n        \"operator_ref\": \"OP-REF-001\",\n        \"created_at\": \"2025-11-03T11:27:11.172Z\",\n        \"created_by\": \"44444444-4444-4444-4444-444444444444\",\n        \"submitted_at\": null\n      }\n    },\n \n    \"application_party\": [\n      {\n        \"application_party_id\": \"aaaaaaa1-aaaa-aaaa-aaaa-aaaaaaaaaaa1\",\n        \"role\": \"Applicant\",\n        \"is_primary\": true,\n        \"person_id\": \"44444444-4444-4444-4444-444444444444\",\n        \"person_name\": \"Jane Doe\",\n        \"email\": \"jane.doe@nationalgrid.co.uk\",\n        \"phone\": \"04567 890123\",\n        \"line1\": \"1 Alpha Street\",\n        \"line2\": null,\n        \"town_city\": \"London\",\n        \"country\": \"UK\",\n        \"postcode\": \"A1 1AA\",\n        \"contact_id\": \"ccccccc5-cccc-cccc-cccc-ccccccccccc5\",\n        \"contact_isconfirmed\": true,\n        \"organisation_id\": \"11111111-1111-1111-1111-111111111111\",\n        \"organisation_name\": \"National Grid Electricity Distribution (NGED)\",\n        \"application_id\": \"11111111-aaaa-4aaa-aaaa-aaaaaaaaaaaa\"\n      }\n    ],\n \n    \"supportingInformation\": {\n      \"supportingDocuments\": [\n        {\n          \"title\": \"checkboxes.png\",\n          \"file_id\": \"484ddd70-ed7d-4145-b7d4-dedda823cad1\",\n          \"category\": \"SUPPORT_INFO\",\n          \"virtual_folder\": \"11111111-aaaa-4aaa-aaaa-aaaaaaaaaaaa/SUPPORT_INFO/\",\n          \"description\": null,\n          \"document_id\": \"b1bdcc49-f087-4c73-913b-326b1e8e469f\",\n          \"added_at\": \"2025-11-02T13:15:03.230Z\",\n          \"added_by\": \"44444444-4444-4444-4444-444444444444\",\n          \"subcategory\": null\n        },\n        {\n          \"title\": \"checkboxes.png\",\n          \"file_id\": \"a2e8a528-dedb-4f12-9440-a315e8abdc84\",\n          \"category\": \"SUPPORT_INFO\",\n          \"virtual_folder\": \"11111111-aaaa-4aaa-aaaa-aaaaaaaaaaaa/SUPPORT_INFO/\",\n          \"description\": null,\n          \"document_id\": \"73bfd5d7-2e85-434d-bcd5-4b236c9f08bb\",\n          \"added_at\": \"2025-11-03T11:28:04.850Z\",\n          \"added_by\": \"44444444-4444-4444-4444-444444444444\",\n          \"subcategory\": null\n        }\n      ],\n      \"supportingQuestions\": {\n        \"id\": \"c6ddf932-db5f-41ea-9616-b77e577c84b5\",\n        \"wayleaves_obtained\": false,\n        \"wayleaves_not_obtained_reason\": \"reason 1\",\n        \"esqcr_2002_compliance_confirmed\": true,\n        \"has_additional_supporting_documents\": true,\n        \"applicant_supporting_comments\": \"Qwq\",\n        \"applicationId\": \"11111111-aaaa-4aaa-aaaa-aaaaaaaaaaaa\"\n      }\n    },\n    \"eiaFees\": {\n        \"eia_id\": \"789de2a2-8f6c-44b4-a713-c458c04f3c0d\",\n        \"screening_only\": true,\n        \"requires_full_eia\": true,\n        \"is_eia_development\": false,\n        \"created_at\": \"2025-11-03T11:28:15.372Z\",\n        \"created_by\": \"7c873599-b20a-4786-b499-7cef60b8c904\",\n        \"updated_at\": \"2025-11-03T11:28:15.372Z\",\n        \"updated_by\": \"4be6703d-0772-43de-9805-7717bed19a2f\"\n    }\n  }\n}';

    @TestSetup
    static void setupTestData() {}

    @isTest 
    private static void testProcessInboundRequests() {
        Integer testRecordsCount = 1;
        List<Inbound_Request__c> inboundRequests = new List<Inbound_Request__c>();
        // Create test Inbound_Request__c records
        for (Integer i = 0; i < testRecordsCount; i++) {
            Inbound_Request__c inboundReq = new Inbound_Request__c(
                Payload__c = payload
            );
            inboundRequests.add(inboundReq);
        }
        // Test the processInboundRequests method
        Map<Id, String> errorMap = new Map<Id, String>();

        Test.startTest();
        insert inboundRequests;
        Test.stopTest(); 

        // Add assertions to verify expected outcomes
        // System.assert(!errorMap.isEmpty(), 'Error map should not be empty after processing.');
    }

    @IsTest
    private static void testUpdateInboundRequestStatus() {
        // Create a test Inbound_Request__c record
        Inbound_Request__c inboundReq = new Inbound_Request__c(
            Payload__c = payload,
            Status__c = 'Received'
        );
        insert inboundReq;

        // Test updating status to 'Processed'
        // InboundRequestTriggerHelper.updateInboundRequestStatus(inboundReq.Id, '');
        Inbound_Request__c updatedReq = [SELECT Status__c, Error_Log_Text__c FROM Inbound_Request__c WHERE Id = :inboundReq.Id];
        // System.assertEquals('Processed', updatedReq.Status__c, 'Status should be updated to Processed.');
        // System.assertEquals(null, updatedReq.Error_Log_Text__c, 'Error log should be null for processed requests.');

        // Test updating status to 'Failed' with error messages
        String errorMessages = 'Sample error message.';
        Map<Id, String> errorMap = new Map<Id, String>();
        errorMap.put(inboundReq.Id, errorMessages);
        Test.startTest();
        InboundRequestTriggerHelper.updateInboundRequestStatus(errorMap);
        Test.stopTest();
        updatedReq = [SELECT Status__c, Error_Log_Text__c FROM Inbound_Request__c WHERE Id = :inboundReq.Id];
        System.assertEquals('Failed', updatedReq.Status__c, 'Status should be updated to Failed.');
    }

    @IsTest
    private static void testInboundRequestBeforeInsert() {
        // Create a test Inbound_Request__c record
        InboundRequestTriggerHelper helper = new InboundRequestTriggerHelper();
        helper.processBeforeInsert();
    }

    @IsTest
    private static void testInboundRequestBeforeDelete() {
        // Create a test Inbound_Request__c record
        InboundRequestTriggerHelper helper = new InboundRequestTriggerHelper();
        helper.processBeforeDelete();
    }

    @IsTest
    private static void testInboundRequestBeforeUpdate() {
        // Create a test Inbound_Request__c record
        
        // Create a test Inbound_Request__c record
        Inbound_Request__c inboundReq = new Inbound_Request__c(
            Payload__c = payload,
            Status__c = 'Received'
        );
        insert inboundReq;

        Test.startTest();
        update inboundReq;
        Test.stopTest();
        InboundRequestTriggerHelper helper = new InboundRequestTriggerHelper();
        helper.processBeforeUpdate();
    }

    @IsTest
    private static void testInboundRequestAfterUpdate() {
        // Create a test Inbound_Request__c record
        InboundRequestTriggerHelper helper = new InboundRequestTriggerHelper();
        helper.processAfterUpdate();
    }

    @IsTest
    private static void testInboundRequestAfterDelete() {
        // Create a test Inbound_Request__c record
        InboundRequestTriggerHelper helper = new InboundRequestTriggerHelper();
        helper.processAfterDelete();
    }

}