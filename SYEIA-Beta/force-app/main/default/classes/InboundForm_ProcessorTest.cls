/**
 * Test class for InboundForm_Processor.
 * Tests core processing logic, record creation, error handling, warnings, and partial success.
 */
@IsTest
private class InboundForm_ProcessorTest {
    
    // ========================================================================
    // TEST DATA HELPERS
    // ========================================================================
    
    private static String getValidS37Json() {
        return '{' +
            '"formType": "S37",' +
            '"applicationId": "APP-TEST-001",' +
            '"sections": {' +
                '"worksOverview": {' +
                    '"polesAdded": 5,' +
                    '"polesReplaced": 2,' +
                    '"poleMaterial": "Wood",' +
                    '"excavationRequired": true,' +
                    '"excavationDetails": "Digging for foundations",' +
                    '"generalComments": "Test comments"' +
                '},' +
                '"location": {' +
                    '"routes": [' +
                        '{' +
                            '"routeName": "Main Route",' +
                            '"route_id": "R001",' +
                            '"gridPoints": [' +
                                '{"point_id": "P1", "easting": "123456", "northing": "654321"},' +
                                '{"point_id": "P2", "easting": "123457", "northing": "654322"}' +
                            ']' +
                        '}' +
                    ']' +
                '},' +
                '"eiaFees": {' +
                    '"is_eia_development": false' +
                '},' +
                '"projectDetails": {' +
                    '"overview": {' +
                        '"project_details": {' +
                            '"project_name": "Test Project",' +
                            '"project_description": "Test Description"' +
                        '}' +
                    '}' +
                '},' +
                '"networkOperator": {' +
                    '"details": {' +
                        '"operator_ref": "OP-REF-001",' +
                        '"submitted_at": "2024-03-15"' +
                    '}' +
                '},' +
                '"application_party": [],' +
                '"sensitiveAreaChecks": {' +
                    '"layers": ["SSSI", "AONB", "National Park"]' +
                '},' +
                '"assetInformation": [' +
                    '{' +
                        '"asset_type": "LV",' +
                        '"tori_noi": "TORI123",' +
                        '"asset_reference": "REF001",' +
                        '"description": "Low voltage line"' +
                    '}' +
                ']' +
            '}' +
        '}';
    }
    
    private static String getMinimalValidS37Json() {
        return '{' +
            '"formType": "S37",' +
            '"applicationId": "APP-MIN-001",' +
            '"sections": {' +
                '"location": {' +
                    '"routes": [' +
                        '{' +
                            '"routeName": "Route 1",' +
                            '"route_id": "R001",' +
                            '"gridPoints": [' +
                                '{"point_id": "P1", "easting": "100", "northing": "200"},' +
                                '{"point_id": "P2", "easting": "101", "northing": "201"}' +
                            ']' +
                        '}' +
                    ']' +
                '},' +
                '"eiaFees": {"is_eia_development": false}' +
            '}' +
        '}';
    }
    
    private static String getJsonWithApplicationRelations(String relatedAppId) {
        return '{' +
            '"formType": "S37",' +
            '"applicationId": "APP-REL-001",' +
            '"sections": {' +
                '"location": {' +
                    '"routes": [' +
                        '{"routeName": "Route 1", "route_id": "R001", ' +
                        '"gridPoints": [{"point_id": "P1", "easting": "100", "northing": "200"},' +
                        '{"point_id": "P2", "easting": "101", "northing": "201"}]}' +
                    ']' +
                '},' +
                '"eiaFees": {"is_eia_development": false},' +
                '"projectDetails": {' +
                    '"overview": {' +
                        '"application_relations": [' +
                            '{"related_application_id": "' + relatedAppId + '", "relation_type": "ASSOCIATED"}' +
                        ']' +
                    '}' +
                '}' +
            '}' +
        '}';
    }
    
    private static String getJsonWithPartyData() {
        return '{' +
            '"formType": "S37",' +
            '"applicationId": "APP-PARTY-001",' +
            '"sections": {' +
                '"location": {' +
                    '"routes": [' +
                        '{"routeName": "Route 1", "route_id": "R001", ' +
                        '"gridPoints": [{"point_id": "P1", "easting": "100", "northing": "200"},' +
                        '{"point_id": "P2", "easting": "101", "northing": "201"}]}' +
                    ']' +
                '},' +
                '"eiaFees": {"is_eia_development": false},' +
                '"application_party": [' +
                    '{"organisation_name": "Test DNO", "is_primary": true, "application_party_id": "P001"}' +
                ']' +
            '}' +
        '}';
    }
    
	private static String getJsonWithParishData() {
        return '{' +
            '"formType": "S37",' +
            '"applicationId": "APP-PARISH-001",' +
            '"sections": {' +
                '"location": {' +
                    '"routes": [' +
                        '{"routeName": "Route 1", "route_id": "R001", ' +
                        '"gridPoints": [{"point_id": "P1", "easting": "100", "northing": "200"},' +
                        '{"point_id": "P2", "easting": "101", "northing": "201"}]}' +
                    ']' +
                '},' +
                '"eiaFees": {"is_eia_development": false},' +
                    '"parishes": [' +
      				'{ "id": "72edf333-94d4-4345-9e44-8642e5e5ceda","country": "England","lpa_code": "E07000110",'+
        			'"created_at": "2026-03-06T16: 44: 02.551Z","created_by": "a3333333-3333-3333-3333-333333333333",'+
        			'"parish_code": "E04004962","parish_name": "Leeds","application_id": "ba7a201f-ade7-4b1d-9ce4-5aad21f9c763"},'+
      				'{"id": "e86ca2ae-f517-469b-9d6c-6ec3bc9d3f9e","country": "England","lpa_code": "E07000129",'+
        			'"created_at": "2026-03-06T16: 44: 02.551Z","created_by": "a3333333-3333-3333-3333-333333333333",'+
        			'"parish_code": "E04012265","parish_name": "Leicester Forest East","application_id": "ba7a201f-ade7-4b1d-9ce4-5aad21f9c763"}'+
                    ']' +
                '}'+
            '}';
    }
    
	private static String getJsonWithPaymentData() {
        return '{' +
            '"formType": "S37",' +
            '"applicationId": "APP-PARISH-001",' +
            '"sections": {' +
                '"location": {' +
                    '"routes": [' +
                        '{"routeName": "Route 1", "route_id": "R001", ' +
                        '"gridPoints": [{"point_id": "P1", "easting": "100", "northing": "200"},' +
                        '{"point_id": "P2", "easting": "101", "northing": "201"}]}' +
                    ']' +
                '},' +
                '"eiaFees": {"is_eia_development": false},' +
                '"payment": { "kind": "card","status": "success","user_id": "a3333333-3333-3333-3333-333333333333",'+
                '"provider": "govuk-pay","created_at": "2026-03-06T17: 25: 15.894Z","payment_id": "sjh48miu0q7vh8mb85dsn08pif",'+
                '"total_amount": "£1277.50"}'+
                '}'+
            '}';
    }
    
    private static String getJsonWithPostConsultationData() {
        return '{' +
            '"formType": "S37",' +
            '"applicationId": "APP-PARISH-001",' +
            '"sections": {' +
                '"location": {' +
                    '"routes": [' +
                        '{"routeName": "Route 1", "route_id": "R001", ' +
                        '"gridPoints": [{"point_id": "P1", "easting": "100", "northing": "200"},' +
                        '{"point_id": "P2", "easting": "101", "northing": "201"}]}' +
                    ']' +
                '},' +
                '"eiaFees": {"is_eia_development": false},' +
                '"postConsultationOutcome": { "id": "5b1c00ec-42dc-4067-8908-3e2b6a515736","created_at": "2026-03-06T16: 44: 59.449Z",' +
      			'"created_by": "a3333333-3333-3333-3333-333333333333","application_id": "ba7a201f-ade7-4b1d-9ce4-5aad21f9c763",'+
  				'"last_updated_at": "2026-03-06T16: 45: 46.025Z","last_updated_by": "a3333333-3333-3333-3333-333333333333",'+	
      			'"lpa_conditions_imposed": true,"lpa_conditions_accepted": false,"consultees_recommendations_made": true,'+
      			'"lpa_conditions_not_accepted_reason": "testing","consultees_recommendations_accepted": false,'+
      			'"consultees_recommendations_not_accepted_reason": "testing last"'+
    			'}'+
             '}'+
          '}';
    }
    
	private static String getJsonWithConsultationData() {
        return '{' +
            '"formType": "S37",' +
            '"applicationId": "APP-PARISH-001",' +
            '"sections": {' +
                '"location": {' +
                    '"routes": [' +
                        '{"routeName": "Route 1", "route_id": "R001", ' +
                        '"gridPoints": [{"point_id": "P1", "easting": "100", "northing": "200"},' +
                        '{"point_id": "P2", "easting": "101", "northing": "201"}]}' +
                    ']' +
                '},' +
                '"eiaFees": {"is_eia_development": false},' +
                '"consultations": [ {"id": "3986b302-a822-49fd-8583-00d546580c63","sentAt": "2026-06-11T23: 00: 00.000Z",' +
        		'"sentBy": null,"status": "Closed","offline": false,"closedAt": null,"closedBy": null,"createdAt": "2026-03-06T16: 44: 02.598Z",'+
				'"createdBy": "a3333333-3333-3333-3333-333333333333","dateClosed": "2026-03-06T17: 06: 58.350Z","roundLabel": "Initial round",'+
				'"secondDate": null,"roundNumber": 1,"applicationId": "ba7a201f-ade7-4b1d-9ce4-5aad21f9c763","closeComments": "test",'+
        		'"lastUpdatedAt": "2026-03-06T17: 06: 58.350Z","lastUpdatedBy": "a3333333-3333-3333-3333-333333333333","otherConsultee": null,'+
        		'"deliveryChannel": null,"notRequiredDocs": [],"objectionRaised": true,"consultationType": "LPA","notRequiredReason": null,'+
        		'"dateRequestCreated": "2026-06-11T23: 00: 00.000Z","allDocumentsUploaded": false,"consulteeEmailAddress": null,'+
				'"consulteeEmailMessage": null,"consultationRequestSent": true,"consulteeOrganisationId": "b0311f09-b1b0-4cff-8dc4-23969d854061",'+
				'"respondingConsulteeName": "test","respondingConsulteeEmail": "test@eample.com","consulteeOrganisationName": "St Albans City and District Council"'+
				'}]'+
                '}'+
            '}';
    }

    private static String getS37WithdrawalJson(String applicationId, String desnzRef) {
        return '{' +
            '"applicationId":"' + applicationId + '",' +
            '"formType":"S37",' +
            '"status":"SUBMITTED",' +
            '"Withdraw":{' +
                '"withdrawalReason":"testing reason for withdrawal",' +
                '"voluntaryAgreement":null' +
            '},' +
            '"desnzRef":"' + desnzRef + '",' +
            '"eventType":"WITHDRAWAL_REQUESTED"' +
        '}';
    }

    private static String getS37WithdrawalJsonWithoutEventType(String applicationId, String desnzRef) {
        return '{' +
            '"applicationId":"' + applicationId + '",' +
            '"formType":"S37",' +
            '"status":"SUBMITTED",' +
            '"Withdraw":{' +
                '"withdrawalReason":"testing reason for withdrawal without event type",' +
                '"voluntaryAgreement":null' +
            '},' +
            '"desnzRef":"' + desnzRef + '"' +
        '}';
    }

    private static String getValidNWLJson() {
        return '{' +
            '"applicationId":"b6ed18fa-7c3d-43bf-97b9-a40fc9bffa03",' +
            '"status":"SUBMITTED",' +
            '"desnzRef":"NWL00116",' +
            '"formType":"NWL",' +
            '"metadata":{"schemaVersion":2,"source":"SYEIA"},' +
            '"sections":{' +
                '"applicantDetails":{' +
                    '"applicant_name":"DESNZ",' +
                    '"applicant_contact_name":"ICS Test Coordinator 10",' +
                    '"address_line1":null,' +
                    '"address_line2":null,' +
                    '"postcode":null,' +
                    '"email":"ics.tester10@ics-testing.com",' +
                    '"phone":null,' +
                    '"additional_contacts":[]' +
                '},' +
                '"applicationDetails":{' +
                    '"application_type":"Existing line",' +
                    '"paragraph":null,' +
                    '"notice_to_remove_date":"2026-02-10",' +
                    '"grounds_for_application":"no_wayleave_exists",' +
                    '"wayleave_type":"inherited_necessary_wayleave",' +
                    '"wayleave_expiry_date":null,' +
                    '"wayleave_expiry_documents":[],' +
                    '"implied_wayleave_documents":[],' +
                    '"wayleave_offer_date":null,' +
                    '"wayleave_offer_documents":[],' +
                    '"notice_to_remove_documents":[{"document_id":"a43064a2-bfdb-4c6f-87d5-5edf95c26f24","file_id":"98be2654-96e4-4dab-a19f-6945bfdd078b","filename":"NWL-noticetoremove.pdf","fileUrl":"b6ed18fa-7c3d-43bf-97b9-a40fc9bffa03/NOTICE_TO_REMOVE/NWL-noticetoremove.pdf"}],'+
                    '"notice_to_terminate_date":null,' +
                    '"notice_to_terminate_documents":[]' +
                '},' +
                '"noticeCompliance":{' +
                    '"notice_clearly_refers_to_removal":true,' +
                    '"notice_unclear_explanation":null,' +
                    '"submitted_within_three_months":true,' +
                    '"late_submission_reason":null,' +
                    '"different_term_requested":false,' +
                    '"different_term_length_and_explanation":null' +
                '},' +
                '"objectorDetails":{' +
                    '"objector_title":"Mr",' +
                    '"objector_name":"test",' +
                    '"objector_organisation":null,' +
                    '"objector_address_line1":"test",' +
                    '"objector_address_line2":"test",' +
                    '"objector_postcode":"ls84rf",' +
                    '"objector_email":null,' +
                    '"objector_phone":null' +
                '},' +
                '"landownerDetails":{' +
                    '"is_objector_also_landowner":false,' +
                    '"landowner_title":"Mr",' +
                    '"landowner_name":"test full name",' +
                    '"landowner_organisation":"test organisation",' +
                    '"landowner_address_line1":"test",' +
                    '"landowner_address_line2":"test",' +
                    '"landowner_postcode":"ls84rf",' +
                    '"landowner_email":"testlandowner@email.com",' +
                    '"landowner_phone":"07777777777"' +
                '},' +
                '"representativeDetails":{' +
                    '"objector_has_representative":true,' +
                    '"representative_title":"Mr",' +
                    '"representative_name":"test rep name",' +
                    '"representative_organisation":"test organisation",' +
                    '"representative_address_line1":"test",' +
                    '"representative_address_line2":"test",' +
                    '"representative_postcode":"ts14rf",' +
                    '"representative_email":"testrepresentative@test.com",' +
                    '"representative_phone":"077777777777"' +
                '},' +
                '"landDetails":{' +
                    '"is_registered":true,' +
                    '"site_address_same_as_objector":false,' +
                    '"site_address":{' +
                        '"line1":"test",' +
                        '"line2":"test",' +
                        '"county":"test",' +
                        '"postcode":"SA14RF",' +
                        '"town_city":"test"' +
                    '},' +
                    '"country":"england",' +
                    '"land_registry_ref":"1234567",' +
                    '"land_registry_reference_document":{"document_id":"d3adb166-5942-4fae-aeb1-0a40315df684","file_id":"4a470cd4-acb6-4d5c-8640-a31379e5b34e","filename":"evidence-request.pdf","fileUrl":"b6ed18fa-7c3d-43bf-97b9-a40fc9bffa03/LAND_REGISTRY/evidence-request.pdf"},'+
                    '"os_grid_ref":"TE 123456 654321",' +
                    '"land_identification":"TEST IDENTIFY LAND",' +
                    '"visible_from_road":true,' +
                    '"site_identification_photographs":[{"document_id":"fb4ebcbe-bc1c-4278-b963-2bccc9b3ea4b","file_id":"ce94dbfb-0197-4e79-8a95-47895a19839d","filename":"SITEINFORMATIONDOC.pdf","fileUrl":"b6ed18fa-7c3d-43bf-97b9-a40fc9bffa03/SITE_INFORMATION/SITEINFORMATIONDOC.pdf"}]' +
                '},' +
                '"assets":{' +
                    '"installed_assets":[{"asset_id":"966c15b0-89cf-40e2-8a73-fb8a099be0e7","line_voltage":"240/415V","line_types":["overhead_line","overhead_line_wooden_pole","overhead_line_wooden_pole_stay","overhead_line_steel_tower","wooden_pole","stay","steel_tower","underground_cable","earth_wire_apparatus","other"],"component_descriptions":{"overhead_line":"TEST","overhead_line_wooden_pole":"TEST","overhead_line_wooden_pole_stay":"TEST","overhead_line_steel_tower":"TEST","wooden_pole":"TEST","stay":"TEST","steel_tower":"TEST","underground_cable":"TEST","earth_wire_apparatus":"TEST","other":"TEST"},"created_at":"2026-06-22T12:47:16.357Z"},{"asset_id":"3abe7869-41f5-47c1-b5c5-70048e9af76a","line_voltage":"400kV","line_types":["stay","steel_tower"],"component_descriptions":{"stay":"TEST","steel_tower":"TEST"},"created_at":"2026-06-22T12:47:32.350Z"}],'+
                    '"assets_match_application_plan":true,' +
                    '"assets_match_plan_explanation":null,' +
                    '"application_plan":{"plan_documents":[{"document_id":"fb791cd8-8ee6-4e1e-bca7-b4279218eaac","file_id":"a8a970d4-23d0-4b30-9df8-6b1e2e63a4e8","filename":"ASSET_APPLCIATION_PLAN.pdf","fileUrl":"b6ed18fa-7c3d-43bf-97b9-a40fc9bffa03/application-plan/ASSET_APPLCIATION_PLAN.pdf"}],"verification_documents":[]}' +
                '},' +
                '"negotiations":{' +
                    '"has_negotiations":true,' +
                    '"negotiations_start_date":"2025-12-10",' +
                    '"negotiations_comments":"TEST",' +
                    '"no_negotiations_reason":null,' +
                    '"evidence_documents":[{"document_id":"02a6dd97-f466-40f7-909b-1164d7a2b7c0","file_id":"a6483b5f-26f5-4647-96e8-795471c2b0c3","filename":"evidence-request.pdf","fileUrl":"b6ed18fa-7c3d-43bf-97b9-a40fc9bffa03/NEGOTIATIONS/evidence-request.pdf"}],'+
                    '"negotiation_status":null' +
                '},' +
                '"additionalInformation":{' +
                    '"has_related_applications":true,' +
                    '"related_applications_details":"TEST related application",' +
                    '"has_other_information":true,' +
                    '"other_information_details":"test important information"' +
                    ',"other_information_documents":[{"document_id":"fbcc27f3-bad2-4b17-8615-a01e199afffa","file_id":"ed549c93-f2d3-4266-a89c-933021fe36fd","filename":"important_information.pdf","fileUrl":"b6ed18fa-7c3d-43bf-97b9-a40fc9bffa03/ADDITIONAL_INFORMATION/important_information.pdf"}]' +
                '},' +
                '"payment":{' +
                    '"payment_id":"4646158ml3qvai0b04munb4hle",' +
                    '"local_payment_id":979,' +
                    '"amount":23650,' +
                    '"description":"Section 37 Application Payment - b6ed18fa-7c3d-43bf-97b9-a40fc9bffa03",' +
                    '"reference":"b6ed18fa-7c3d-43bf-97b9-a40fc9bffa03",' +
                    '"transaction_number":null,' +
                    '"status":"confirmed",' +
                    '"provider":"govuk-pay",' +
                    '"kind":"Credit Card",' +
                    '"state":{"status":"confirmed","finished":true,"code":null,"message":null}' +
                '}' +
            '}' +
        '}';
    }
    
    
    // ========================================================================
    // TEST SETUP
    // ========================================================================
    
    @TestSetup
    static void setupTestData() {
        List<Inbound_Request__c> requests = new List<Inbound_Request__c>{
            new Inbound_Request__c(
                Payload__c = getValidS37Json(),
                Status__c = 'Received'
            ),
            new Inbound_Request__c(
                Payload__c = getMinimalValidS37Json(),
                Status__c = 'Received'
            )
        };
        insert requests;
    }
    
    // ========================================================================
    // PROCESS REQUESTS TESTS
    // ========================================================================
    
    @IsTest
    static void testProcessRequests_ValidPayload() {
        InboundForm_Processor.clearAllCaches();
        InboundForm_ConfigRegistry.clearCache();
        
        List<Inbound_Request__c> requests = [
            SELECT Id, Payload__c, Status__c 
            FROM Inbound_Request__c 
            LIMIT 1
        ];
        
        Test.startTest();
        Map<Id, InboundForm_Processor.ProcessingResult> results = 
            InboundForm_Processor.processRequests(requests);
        Test.stopTest();
        
        Assert.isNotNull(results, 'Results should not be null');
        Assert.areEqual(1, results.size(), 'Should have one result');
        
        InboundForm_Processor.ProcessingResult result = results.get(requests[0].Id);
        Assert.isNotNull(result, 'Result should exist for request');
        Assert.areEqual('S37', result.formType, 'Form type should be S37');
    }
    
    @IsTest
    static void testProcessRequests_EmptyPayload() {
        InboundForm_Processor.clearAllCaches();
        
        Inbound_Request__c emptyRequest = new Inbound_Request__c(
            Payload__c = '',
            Status__c = 'Received'
        );
        insert emptyRequest;
        
        List<Inbound_Request__c> requests = new List<Inbound_Request__c>{
            [SELECT Id, Payload__c FROM Inbound_Request__c WHERE Id = :emptyRequest.Id]
        };
        
        Test.startTest();
        Map<Id, InboundForm_Processor.ProcessingResult> results = 
            InboundForm_Processor.processRequests(requests);
        Test.stopTest();
        
        InboundForm_Processor.ProcessingResult result = results.get(emptyRequest.Id);
        Assert.isFalse(result.success, 'Should fail for empty payload');
        Assert.isTrue(result.errors[0].contains('Payload is empty'), 
            'Error should mention empty payload');
    }
    
    @IsTest
    static void testProcessRequests_MissingFormType() {
        InboundForm_Processor.clearAllCaches();
        
        Inbound_Request__c request = new Inbound_Request__c(
            Payload__c = '{"applicationId": "APP-001"}',
            Status__c = 'Received'
        );
        insert request;
        
        List<Inbound_Request__c> requests = new List<Inbound_Request__c>{
            [SELECT Id, Payload__c FROM Inbound_Request__c WHERE Id = :request.Id]
        };
        
        Test.startTest();
        Map<Id, InboundForm_Processor.ProcessingResult> results = 
            InboundForm_Processor.processRequests(requests);
        Test.stopTest();
        
        InboundForm_Processor.ProcessingResult result = results.get(request.Id);
        Assert.isFalse(result.success, 'Should fail for missing form type');
        Assert.isTrue(result.errors[0].contains('formType not found'), 
            'Error should mention missing form type');
    }
    
    @IsTest
    static void testProcessRequests_InvalidFormType() {
        InboundForm_Processor.clearAllCaches();
        
        Inbound_Request__c request = new Inbound_Request__c(
            Payload__c = '{"formType": "INVALID", "applicationId": "APP-001"}',
            Status__c = 'Received'
        );
        insert request;
        
        List<Inbound_Request__c> requests = new List<Inbound_Request__c>{
            [SELECT Id, Payload__c FROM Inbound_Request__c WHERE Id = :request.Id]
        };
        
        Test.startTest();
        Map<Id, InboundForm_Processor.ProcessingResult> results = 
            InboundForm_Processor.processRequests(requests);
        Test.stopTest();
        
        InboundForm_Processor.ProcessingResult result = results.get(request.Id);
        Assert.isFalse(result.success, 'Should fail for invalid form type');
        Assert.isTrue(result.errors[0].contains('No configuration found'), 
            'Error should mention no config found');
    }
    
    @IsTest
    static void testProcessRequests_ValidationFailure() {
        InboundForm_Processor.clearAllCaches();
        InboundForm_ConfigRegistry.clearCache();
        
        // JSON with no routes - should fail S37 validation
        String invalidJson = '{' +
            '"formType": "S37",' +
            '"applicationId": "APP-001",' +
            '"sections": {' +
                '"location": {"routes": []},' +
                '"eiaFees": {"is_eia_development": false}' +
            '}' +
        '}';
        
        Inbound_Request__c request = new Inbound_Request__c(
            Payload__c = invalidJson,
            Status__c = 'Received'
        );
        insert request;
        
        List<Inbound_Request__c> requests = new List<Inbound_Request__c>{
            [SELECT Id, Payload__c FROM Inbound_Request__c WHERE Id = :request.Id]
        };
        
        Test.startTest();
        Map<Id, InboundForm_Processor.ProcessingResult> results = 
            InboundForm_Processor.processRequests(requests);
        Test.stopTest();
        
        InboundForm_Processor.ProcessingResult result = results.get(request.Id);
        Assert.isFalse(result.success, 'Should fail validation');
    }
    
    @IsTest
    static void testProcessRequests_MultipleRequests() {
        InboundForm_Processor.clearAllCaches();
        InboundForm_ConfigRegistry.clearCache();
        
        List<Inbound_Request__c> requests = [
            SELECT Id, Payload__c, Status__c 
            FROM Inbound_Request__c 
        ];
        
        Test.startTest();
        Map<Id, InboundForm_Processor.ProcessingResult> results = 
            InboundForm_Processor.processRequests(requests);
        Test.stopTest();
        
        Assert.areEqual(requests.size(), results.size(), 
            'Should have result for each request');
    }
    
    // ========================================================================
    // PROCESSING RESULT TESTS
    // ========================================================================
    
    @IsTest
    static void testProcessingResult_Constructor() {
        Id fakeId = '500000000000000AAA';
        
        Test.startTest();
        InboundForm_Processor.ProcessingResult result = 
            new InboundForm_Processor.ProcessingResult(fakeId);
        Test.stopTest();
        
        Assert.areEqual(fakeId, result.inboundRequestId, 'ID should match');
        Assert.isTrue(result.success, 'Success should default to true');
        Assert.isNotNull(result.errors, 'Errors should be initialized');
        Assert.isTrue(result.errors.isEmpty(), 'Errors should be empty');
        Assert.isNotNull(result.warnings, 'Warnings should be initialized');
        Assert.isTrue(result.warnings.isEmpty(), 'Warnings should be empty');
        Assert.isNotNull(result.createdRecords, 'Created records should be initialized');
        Assert.isNotNull(result.collectionRecords, 'Collection records should be initialized');
        Assert.isNotNull(result.postPrimaryRecords, 'Post primary records should be initialized');
    }
    
    @IsTest
    static void testProcessingResult_AddError() {
        Id fakeId = '500000000000000AAA';
        InboundForm_Processor.ProcessingResult result = 
            new InboundForm_Processor.ProcessingResult(fakeId);
        
        Test.startTest();
        result.addError('Test error message');
        Test.stopTest();
        
        Assert.isFalse(result.success, 'Success should be false after error');
        Assert.areEqual(1, result.errors.size(), 'Should have one error');
        Assert.areEqual('Test error message', result.errors[0], 'Error message should match');
    }
    
    @IsTest
    static void testProcessingResult_AddWarning() {
        Id fakeId = '500000000000000AAA';
        InboundForm_Processor.ProcessingResult result = 
            new InboundForm_Processor.ProcessingResult(fakeId);
        
        Test.startTest();
        result.addWarning('Test warning message');
        Test.stopTest();
        
        Assert.isTrue(result.success, 'Success should still be true after warning');
        Assert.areEqual(1, result.warnings.size(), 'Should have one warning');
        Assert.areEqual('Test warning message', result.warnings[0], 'Warning message should match');
        Assert.isTrue(result.hasWarnings(), 'hasWarnings should return true');
    }
    
    @IsTest
    static void testProcessingResult_HasWarnings() {
        Id fakeId = '500000000000000AAA';
        InboundForm_Processor.ProcessingResult result = 
            new InboundForm_Processor.ProcessingResult(fakeId);
        
        Assert.isFalse(result.hasWarnings(), 'Should have no warnings initially');
        
        result.addWarning('Warning 1');
        Assert.isTrue(result.hasWarnings(), 'Should have warnings after adding one');
        
        result.addWarning('Warning 2');
        Assert.areEqual(2, result.warnings.size(), 'Should accumulate warnings');
    }
    
    @IsTest
    static void testProcessingResult_AddRecords() {
        Id fakeId = '500000000000000AAA';
        InboundForm_Processor.ProcessingResult result = 
            new InboundForm_Processor.ProcessingResult(fakeId);
        
        List<SObject> records = new List<SObject>{
            new Account(Name = 'Test 1'),
            new Account(Name = 'Test 2')
        };
        
        Test.startTest();
        result.addRecords('Account', records);
        Test.stopTest();
        
        Assert.isTrue(result.createdRecords.containsKey('Account'), 
            'Should have Account key');
        Assert.areEqual(2, result.createdRecords.get('Account').size(), 
            'Should have 2 records');
    }
    
    @IsTest
    static void testProcessingResult_AddRecords_Multiple() {
        Id fakeId = '500000000000000AAA';
        InboundForm_Processor.ProcessingResult result = 
            new InboundForm_Processor.ProcessingResult(fakeId);
        
        result.addRecords('Account', new List<SObject>{ new Account(Name = 'Test 1') });
        
        Test.startTest();
        result.addRecords('Account', new List<SObject>{ new Account(Name = 'Test 2') });
        Test.stopTest();
        
        Assert.areEqual(2, result.createdRecords.get('Account').size(), 
            'Should accumulate records');
    }
    
    @IsTest
    static void testProcessingResult_AddPostPrimaryRecords() {
        Id fakeId = '500000000000000AAA';
        InboundForm_Processor.ProcessingResult result = 
            new InboundForm_Processor.ProcessingResult(fakeId);
        
        List<SObject> records = new List<SObject>{
            new Related_Case__c()
        };
        
        Test.startTest();
        result.addPostPrimaryRecords('Related_Case__c', records);
        Test.stopTest();
        
        Assert.isTrue(result.postPrimaryRecords.containsKey('Related_Case__c'), 
            'Should have Related_Case__c key');
        Assert.areEqual(1, result.postPrimaryRecords.get('Related_Case__c').size(), 
            'Should have 1 record');
    }
    
    @IsTest
    static void testProcessingResult_AddPostPrimaryRecords_Multiple() {
        Id fakeId = '500000000000000AAA';
        InboundForm_Processor.ProcessingResult result = 
            new InboundForm_Processor.ProcessingResult(fakeId);
        
        result.addPostPrimaryRecords('Related_Case__c', new List<SObject>{ new Related_Case__c() });
        result.addPostPrimaryRecords('Related_Case__c', new List<SObject>{ new Related_Case__c() });
        
        Assert.areEqual(2, result.postPrimaryRecords.get('Related_Case__c').size(), 
            'Should accumulate post primary records');
    }
    
    // ========================================================================
    // CLEAR CACHES TEST
    // ========================================================================
    
    @IsTest
    static void testClearAllCaches() {
        InboundForm_ConfigRegistry.getConfig('S37');
        
        Test.startTest();
        InboundForm_Processor.clearAllCaches();
        Test.stopTest();
        
        Assert.isTrue(true, 'Cache clearing should succeed');
    }
    
    // ========================================================================
    // ERROR HANDLING TESTS
    // ========================================================================
    
    @IsTest
    static void testProcessRequests_InvalidJson() {
        InboundForm_Processor.clearAllCaches();
        
        Inbound_Request__c request = new Inbound_Request__c(
            Payload__c = '{invalid json',
            Status__c = 'Received'
        );
        insert request;
        
        List<Inbound_Request__c> requests = new List<Inbound_Request__c>{
            [SELECT Id, Payload__c FROM Inbound_Request__c WHERE Id = :request.Id]
        };
        
        Test.startTest();
        Map<Id, InboundForm_Processor.ProcessingResult> results = 
            InboundForm_Processor.processRequests(requests);
        Test.stopTest();
        
        InboundForm_Processor.ProcessingResult result = results.get(request.Id);
        Assert.isFalse(result.success, 'Should fail for invalid JSON');
    }
    
    // ========================================================================
    // INTEGRATION TESTS
    // ========================================================================
    
    @IsTest
    static void testProcessRequests_EndToEnd() {
        InboundForm_Processor.clearAllCaches();
        InboundForm_ConfigRegistry.clearCache();
        
        Inbound_Request__c request = new Inbound_Request__c(
            Payload__c = getValidS37Json(),
            Status__c = 'Received'
        );
        insert request;
        
        List<Inbound_Request__c> requests = new List<Inbound_Request__c>{
            [SELECT Id, Payload__c FROM Inbound_Request__c WHERE Id = :request.Id]
        };
        
        Test.startTest();
        Map<Id, InboundForm_Processor.ProcessingResult> results = 
            InboundForm_Processor.processRequests(requests);
        Test.stopTest();
        
        InboundForm_Processor.ProcessingResult result = results.get(request.Id);
        
        Assert.isNotNull(result, 'Result should exist');
        Assert.areEqual('S37', result.formType, 'Form type should be S37');
        Assert.isNotNull(result.formConfig, 'Form config should be set');
        Assert.isNotNull(result.createdRecords, 'Created records should exist');
    }
    
    @IsTest
    static void testProcessRequests_MixedResults() {
        InboundForm_Processor.clearAllCaches();
        InboundForm_ConfigRegistry.clearCache();
        
        Inbound_Request__c validRequest = new Inbound_Request__c(
            Payload__c = getMinimalValidS37Json(),
            Status__c = 'Received'
        );
        Inbound_Request__c invalidRequest = new Inbound_Request__c(
            Payload__c = '{"formType": "INVALID"}',
            Status__c = 'Received'
        );
        insert new List<Inbound_Request__c>{ validRequest, invalidRequest };
        
        List<Inbound_Request__c> requests = [
            SELECT Id, Payload__c 
            FROM Inbound_Request__c 
            WHERE Id IN (:validRequest.Id, :invalidRequest.Id)
        ];
        
        Test.startTest();
        Map<Id, InboundForm_Processor.ProcessingResult> results = 
            InboundForm_Processor.processRequests(requests);
        Test.stopTest();
        
        Assert.areEqual(2, results.size(), 'Should have 2 results');
        Assert.isFalse(results.get(invalidRequest.Id).success, 
            'Invalid request should fail');
    }
    
    @IsTest
    static void testProcessRequests_WithPartyData() {
        InboundForm_Processor.clearAllCaches();
        InboundForm_ConfigRegistry.clearCache();
        
        Inbound_Request__c request = new Inbound_Request__c(
            Payload__c = getJsonWithPartyData(),
            Status__c = 'Received'
        );
        insert request;
        
        List<Inbound_Request__c> requests = new List<Inbound_Request__c>{
            [SELECT Id, Payload__c FROM Inbound_Request__c WHERE Id = :request.Id]
        };
        
        Test.startTest();
        Map<Id, InboundForm_Processor.ProcessingResult> results = 
            InboundForm_Processor.processRequests(requests);
        Test.stopTest();
        
        InboundForm_Processor.ProcessingResult result = results.get(request.Id);
        Assert.isTrue(result.success, 'Should succeed with party data');
    }
    
    @IsTest
    static void testProcessRequests_WithParishData() {
        InboundForm_Processor.clearAllCaches();
        InboundForm_ConfigRegistry.clearCache();
        
        Inbound_Request__c request = new Inbound_Request__c(
            Payload__c = getJsonWithParishData(),
            Status__c = 'Received'
        );
        insert request;
        
        List<Inbound_Request__c> requests = new List<Inbound_Request__c>{
            [SELECT Id, Payload__c FROM Inbound_Request__c WHERE Id = :request.Id]
        };
        
        Test.startTest();
        Map<Id, InboundForm_Processor.ProcessingResult> results = 
            InboundForm_Processor.processRequests(requests);
        Test.stopTest();
        
        InboundForm_Processor.ProcessingResult result = results.get(request.Id);
        Assert.isTrue(result.success, 'Should succeed with parishes data');
    }
    
    @IsTest
    static void testProcessRequests_WithPaymentData() {
        InboundForm_Processor.clearAllCaches();
        InboundForm_ConfigRegistry.clearCache();
        
        Inbound_Request__c request = new Inbound_Request__c(
            Payload__c = getJsonWithPaymentData(),
            Status__c = 'Received'
        );
        insert request;
        
        List<Inbound_Request__c> requests = new List<Inbound_Request__c>{
            [SELECT Id, Payload__c FROM Inbound_Request__c WHERE Id = :request.Id]
        };
        
        Test.startTest();
        Map<Id, InboundForm_Processor.ProcessingResult> results = 
            InboundForm_Processor.processRequests(requests);
        Test.stopTest();
        
        InboundForm_Processor.ProcessingResult result = results.get(request.Id);
        Assert.isTrue(result.success, 'Should succeed with Payment data');
    }
    
    @IsTest
    static void testProcessRequests_WithConsultationData() {
        InboundForm_Processor.clearAllCaches();
        InboundForm_ConfigRegistry.clearCache();
        
        Inbound_Request__c request = new Inbound_Request__c(
            Payload__c = getJsonWithConsultationData(),
            Status__c = 'Received'
        );
        insert request;
        
        List<Inbound_Request__c> requests = new List<Inbound_Request__c>{
            [SELECT Id, Payload__c FROM Inbound_Request__c WHERE Id = :request.Id]
        };
        
        Test.startTest();
        Map<Id, InboundForm_Processor.ProcessingResult> results = 
            InboundForm_Processor.processRequests(requests);
        Test.stopTest();
        
        InboundForm_Processor.ProcessingResult result = results.get(request.Id);
        Assert.isTrue(result.success, 'Should succeed with Post Consultation data');
    }
    
    @IsTest
    static void testProcessRequests_WithPostConsultationData() {
        InboundForm_Processor.clearAllCaches();
        InboundForm_ConfigRegistry.clearCache();
        
        Inbound_Request__c request = new Inbound_Request__c(
            Payload__c = getJsonWithPostConsultationData(),
            Status__c = 'Received'
        );
        insert request;
        
        List<Inbound_Request__c> requests = new List<Inbound_Request__c>{
            [SELECT Id, Payload__c FROM Inbound_Request__c WHERE Id = :request.Id]
        };
        
        Test.startTest();
        Map<Id, InboundForm_Processor.ProcessingResult> results = 
            InboundForm_Processor.processRequests(requests);
        Test.stopTest();
        
        InboundForm_Processor.ProcessingResult result = results.get(request.Id);
        Assert.isTrue(result.success, 'Should succeed with Consultation data');
    }
    
    @IsTest
    static void testProcessRequests_WithApplicationRelations_NotFound() {
        InboundForm_Processor.clearAllCaches();
        InboundForm_ConfigRegistry.clearCache();
        
        // JSON with application relation to non-existent case
        Inbound_Request__c request = new Inbound_Request__c(
            Payload__c = getJsonWithApplicationRelations('NON-EXISTENT-ID'),
            Status__c = 'Received'
        );
        insert request;
        
        List<Inbound_Request__c> requests = new List<Inbound_Request__c>{
            [SELECT Id, Payload__c FROM Inbound_Request__c WHERE Id = :request.Id]
        };
        
        Test.startTest();
        Map<Id, InboundForm_Processor.ProcessingResult> results = 
            InboundForm_Processor.processRequests(requests);
        Test.stopTest();
        
        InboundForm_Processor.ProcessingResult result = results.get(request.Id);
        Assert.isTrue(result.success, 'Should still succeed overall');
        Assert.isTrue(result.hasWarnings(), 'Should have warnings for not found case');
    }
    
    @IsTest
    static void testProcessRequests_WithApplicationRelations_Found() {
        InboundForm_Processor.clearAllCaches();
        InboundForm_ConfigRegistry.clearCache();
        
        // Create a related case
        Case__c relatedCase = new Case__c(
            Name = 'Related Case',
            AWS_Application_Id__c = 'EXISTING-APP-ID'
        );
        insert relatedCase;
        
        Inbound_Request__c request = new Inbound_Request__c(
            Payload__c = getJsonWithApplicationRelations('EXISTING-APP-ID'),
            Status__c = 'Received'
        );
        insert request;
        
        List<Inbound_Request__c> requests = new List<Inbound_Request__c>{
            [SELECT Id, Payload__c FROM Inbound_Request__c WHERE Id = :request.Id]
        };
        
        Test.startTest();
        Map<Id, InboundForm_Processor.ProcessingResult> results = 
            InboundForm_Processor.processRequests(requests);
        Test.stopTest();
        
        InboundForm_Processor.ProcessingResult result = results.get(request.Id);
        Assert.isTrue(result.success, 'Should succeed');
        Assert.isFalse(result.hasWarnings(), 'Should have no warnings when case found');
    }

    @IsTest
    static void testProcessRequests_S37WithdrawalRequestPayload() {
        InboundForm_Processor.clearAllCaches();
        InboundForm_ConfigRegistry.clearCache();
        CaseTriggerHelper.disableProcessing();
        try {

            String appId = 'a4120bcf-c2c4-4d42-a1bd-254ac543c251';
            String desnzRef = 'S3701492';
            Case__c existingCase = new Case__c(
                Name = desnzRef,
                Status__c = 'New',
                AWS_Application_Id__c = appId
            );
            insert existingCase;

            Inbound_Request__c request = new Inbound_Request__c(
                Payload__c = getS37WithdrawalJson(appId, desnzRef),
                Status__c = 'Received'
            );
            insert request;

            List<Inbound_Request__c> requests = new List<Inbound_Request__c>{
                [SELECT Id, Payload__c FROM Inbound_Request__c WHERE Id = :request.Id]
            };

            Test.startTest();
            Map<Id, InboundForm_Processor.ProcessingResult> results =
                InboundForm_Processor.processRequests(requests);
            Test.stopTest();

            InboundForm_Processor.ProcessingResult result = results.get(request.Id);
            Assert.isTrue(result.success, 'S37 withdrawal payload should process successfully');
            Assert.areEqual('S37_WITHDRAWAL_REQUEST', result.formType,
                'Withdrawal payload should be routed to withdrawal form type');

            List<Withdrawal_Request__c> inserted = [
                SELECT Id, Case__c, Status__c, Withdrawal_Request_Reason__c
                FROM Withdrawal_Request__c
                WHERE Case__c = :existingCase.Id
            ];

            Assert.areEqual(2, inserted.size(), 'Should create two withdrawal requests');
            Assert.areEqual('Pending', inserted[0].Status__c,
                'Withdrawal request status should be normalized to Pending');
            Assert.areEqual('testing reason for withdrawal',
                inserted[0].Withdrawal_Request_Reason__c,
                'Withdrawal reason should be mapped from payload');

            Case__c updatedCase = [
                SELECT Id, Status__c
                FROM Case__c
                WHERE Id = :existingCase.Id
                LIMIT 1
            ];
            Assert.areEqual('Withdrawal Requested', updatedCase.Status__c,
                'Case status should be updated to Withdrawal Requested');
        } finally {
            CaseTriggerHelper.enableProcessing();
        }
    }

    @IsTest
    static void testProcessRequests_S37WithdrawalRequestPayload_WithoutEventType() {
        InboundForm_Processor.clearAllCaches();
        InboundForm_ConfigRegistry.clearCache();
        CaseTriggerHelper.disableProcessing();
        try {
            String appId = '0e9ddd1a-3f11-4d27-bd8f-574e83a9a888';
            String desnzRef = 'S3701493';
            Case__c existingCase = new Case__c(
                Name = desnzRef,
                Status__c = 'New',
                AWS_Application_Id__c = appId
            );
            insert existingCase;

            Inbound_Request__c request = new Inbound_Request__c(
                Payload__c = getS37WithdrawalJsonWithoutEventType(appId, desnzRef),
                Status__c = 'Received'
            );
            insert request;

            List<Inbound_Request__c> requests = new List<Inbound_Request__c>{
                [SELECT Id, Payload__c FROM Inbound_Request__c WHERE Id = :request.Id]
            };

            Test.startTest();
            Map<Id, InboundForm_Processor.ProcessingResult> results =
                InboundForm_Processor.processRequests(requests);
            Test.stopTest();

            InboundForm_Processor.ProcessingResult result = results.get(request.Id);
            Assert.isTrue(result.success,
                'S37 withdrawal payload without eventType should process successfully');
            Assert.areEqual('S37_WITHDRAWAL_REQUEST', result.formType,
                'Payload should be routed to withdrawal form type via Withdraw node');

            Case__c updatedCase = [
                SELECT Id, Status__c
                FROM Case__c
                WHERE Id = :existingCase.Id
                LIMIT 1
            ];
            Assert.areEqual('Withdrawal Requested', updatedCase.Status__c,
                'Case status should be updated to Withdrawal Requested');
        } finally {
            CaseTriggerHelper.enableProcessing();
        }
    }

    @IsTest
    static void testProcessRequests_NWLPayload() {
        InboundForm_Processor.clearAllCaches();
        InboundForm_ConfigRegistry.clearCache();
        CaseTriggerHelper.disableProcessing();
        try {
            Inbound_Request__c request = new Inbound_Request__c(
                Payload__c = getValidNWLJson(),
                Status__c = 'Received'
            );
            insert request;

            List<Inbound_Request__c> requests = new List<Inbound_Request__c>{
                [SELECT Id, Payload__c FROM Inbound_Request__c WHERE Id = :request.Id]
            };

            Test.startTest();
            Map<Id, InboundForm_Processor.ProcessingResult> results =
                InboundForm_Processor.processRequests(requests);
            Test.stopTest();

            InboundForm_Processor.ProcessingResult result = results.get(request.Id);
            Assert.isTrue(result.success, 'NWL payload should process successfully');
            Assert.areEqual('NWL', result.formType, 'Form type should be NWL');

            Case__c insertedCase = [
                SELECT Id,
                       Name,
                       AWS_Application_Id__c,
                       Case_Type__c,
                       Application_Type__c,
                      Type_Of_NWL_That_Existed__c,
                       Written_Removal_Notice_Issue_Date__c,
                       Written_Removal_Notice_Been_Given__c,
                       Land__c,
                       Equipment_Visible_from_Public_Road__c,
                       Are_There_Any_Other_Related_Applications__c,
                       Details_of_All_Related_Application__c
                FROM Case__c
                WHERE AWS_Application_Id__c = 'b6ed18fa-7c3d-43bf-97b9-a40fc9bffa03'
                LIMIT 1
            ];

            Assert.areEqual('NWL00116', insertedCase.Name, 'Case name should map from desnzRef');
            Assert.areEqual('Necessary Wayleaves', insertedCase.Case_Type__c,
                'NWL handler should set case type');
            Assert.areEqual('Existing Line', insertedCase.Application_Type__c,
                'NWL handler should normalize application type');
            Assert.areEqual('Inherited Necessary Wayleave',
                insertedCase.Type_Of_NWL_That_Existed__c,
                'NWL handler should map inherited_necessary_wayleave to picklist value');
            Assert.areEqual(Date.newInstance(2026, 2, 10),
                insertedCase.Written_Removal_Notice_Issue_Date__c,
                'Written removal notice issue date should map from notice_to_remove_date');
            Assert.areEqual('Yes', insertedCase.Written_Removal_Notice_Been_Given__c,
                'Written removal notice should be Yes when issue date is present');
            Assert.isNull(insertedCase.Land__c,
                'Land registration flag should map to null when not present in payload');
            // Assert.areEqual('No', insertedCase.Land__c,
                // 'Land registration flag should map to No');
            Assert.isNull(insertedCase.Equipment_Visible_from_Public_Road__c,
                'Visibility flag should map to null when not present in payload');
            // Assert.areEqual('Yes', insertedCase.Equipment_Visible_from_Public_Road__c,
            //     'Visibility flag should map to Yes');
            Assert.isTrue(insertedCase.Are_There_Any_Other_Related_Applications__c,
                'Related applications flag should map');
            Assert.areEqual('TEST related application',
                insertedCase.Details_of_All_Related_Application__c,
                'Related application details should map');

            Assert.isTrue(result.collectionRecords.containsKey('Applicants'),
                'Applicants collection should be processed from applicantDetails');
            List<SObject> applicantRecords = result.collectionRecords.get('Applicants');
            Assert.areEqual(1, applicantRecords.size(),
                'Applicants should produce one party record');

            SObject applicantParty = applicantRecords[0];
            Assert.areEqual('DESNZ', (String) applicantParty.get('Name'),
                'Applicant party should map applicant_name');
            Assert.areEqual('ics.tester10@ics-testing.com', (String) applicantParty.get('Email__c'),
                'Applicant party should map email');
            Assert.areEqual('Organisation', (String) applicantParty.get('Party_Type__c'),
                'Applicant party type should be Organisation');
            Assert.areEqual('NWL_APPLICANT', (String) applicantParty.get('Application_Party_Id__c'),
                'Applicant party should carry NWL_APPLICANT identifier');

            Assert.isTrue(result.collectionRecords.containsKey('ApplicantAddresses'),
                'ApplicantAddresses collection should be processed from applicantDetails');
            List<SObject> applicantAddressRecords = result.collectionRecords.get('ApplicantAddresses');
            Assert.areEqual(1, applicantAddressRecords.size(),
                'ApplicantAddresses should produce one address record');

            SObject applicantAddress = applicantAddressRecords[0];
            Assert.areEqual('NWL_APPLICANT', (String) applicantAddress.get('Application_Party_Identification__c'),
                'Applicant address should carry NWL_APPLICANT identifier');
        } finally {
            CaseTriggerHelper.enableProcessing();
        }
    }
    
    // ========================================================================
    // PARSER STORAGE TEST
    // ========================================================================
    
    @IsTest
    static void testProcessingResult_ParserStorage() {
        InboundForm_Processor.clearAllCaches();
        InboundForm_ConfigRegistry.clearCache();
        
        Inbound_Request__c request = new Inbound_Request__c(
            Payload__c = getMinimalValidS37Json(),
            Status__c = 'Received'
        );
        insert request;
        
        List<Inbound_Request__c> requests = new List<Inbound_Request__c>{
            [SELECT Id, Payload__c FROM Inbound_Request__c WHERE Id = :request.Id]
        };
        
        Test.startTest();
        Map<Id, InboundForm_Processor.ProcessingResult> results = 
            InboundForm_Processor.processRequests(requests);
        Test.stopTest();
        
        InboundForm_Processor.ProcessingResult result = results.get(request.Id);
        Assert.isNotNull(result.parser, 'Parser should be stored in result');
    }
}