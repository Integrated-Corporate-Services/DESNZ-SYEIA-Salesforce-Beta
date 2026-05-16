@IsTest
global class DynamicPathControllerTest {
    
    @TestSetup
    static void setupTestData() {
        // Get a valid picklist value dynamically
        Schema.DescribeFieldResult fieldResult = Case__c.Status__c.getDescribe();
        String validStatus = fieldResult.getPicklistValues()[0].getValue();
        
        Case__c testCase = new Case__c(
            Name = 'Test Case',
            Status__c = validStatus
        );
        insert testCase;
        
        AWS_EndPoints__c settings = new AWS_EndPoints__c(
            SetupOwnerId = UserInfo.getOrganizationId(), // KEY LINE
			Update_Status_Endpoint__c = 'https://test.com/backend/api/v1/internal/applications/{0}/status'
        );
        insert settings;
    }
    
    @IsTest
    static void testGetPicklistValuesByRecord_Positive() {
        Case__c c = [SELECT Id FROM Case__c LIMIT 1];
        
        List<String> picklistValues =
            DynamicPathController.getPicklistValuesByRecord(c.Id, 'Status__c');
        
        System.assert(!picklistValues.isEmpty(), 'Picklist should not be empty');
    }
    
    @IsTest
    static void testGetPicklistValuesByRecord_NullId() {
        Boolean exceptionThrown = false;
        
        try {
            DynamicPathController.getPicklistValuesByRecord(null, 'Status__c');
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        
        System.assert(exceptionThrown, 'Expected AuraHandledException to be thrown');
    }
    
    @IsTest
    static void testGetPicklistValuesByRecord_InvalidField() {
        Case__c c = [SELECT Id FROM Case__c LIMIT 1];        
        Boolean exceptionThrown = false;
        
        try {
            DynamicPathController.getPicklistValuesByRecord(c.Id, 'Invalid__c');
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        System.assert(exceptionThrown);
    }
    
   /* @IsTest
    static void testUpdateRecordStatus_Valid() {
        Case__c c = [SELECT Id FROM Case__c LIMIT 1];
        
        List<String> picklist =
            DynamicPathController.getPicklistValuesByRecord(c.Id, 'Status__c');
        
        String newStatus = picklist.size() > 1 ? picklist[1] : picklist[0];
        
        Test.startTest();
        DynamicPathController.updateRecordStatus(c.Id, 'Status__c', newStatus);
        Test.stopTest();
        
        Case__c updated = [SELECT Status__c FROM Case__c WHERE Id = :c.Id];
        System.assertEquals(newStatus, updated.Status__c);
    }*/
    
    @IsTest
    static void testUpdateRecordStatus_BlankStatus() {
        Case__c c = [SELECT Id FROM Case__c LIMIT 1];
        
        SalesforceSettings__c settings = SalesforceSettings__c.getOrgDefaults();
        settings.client_id__c = 'Some Value';
        settings.client_secret__c = 'Some Value';
        settings.Endpoint_Url__c = 'Some Value';
        settings.grant_type__c = 'client_credentials';
        insert settings;
        
        Test.startTest();
        DynamicPathController.updateRecordStatus(c.Id, 'Status__c', '');
        Test.stopTest();
        
        List<String> picklist =
            DynamicPathController.getPicklistValuesByRecord(c.Id, 'Status__c');
        
        Case__c updated = [SELECT Status__c FROM Case__c WHERE Id = :c.Id];
        System.assertEquals(picklist[0], updated.Status__c);
    }
    
    @IsTest
    static void testUpdateRecordStatus_InvalidStatus() {
        Case__c c = [SELECT Id FROM Case__c LIMIT 1];
        Boolean exceptionThrown = false;
        
        try {
            DynamicPathController.updateRecordStatus(c.Id, 'Status__c', 'INVALID_TEST');
            System.assert(false);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
    }
    
    @IsTest
    static void testGetStatusByCurrentStatus() {
        Test.startTest();
        List<String> statuses =
            DynamicPathController.getStatusByCurrentStatus('Anything');
        Test.stopTest();
        
        System.assertNotEquals(null, statuses);
    }
    
    @IsTest
    static void testGetStatusByCurrentStatus_Blank() {
        Boolean exceptionThrown = false;
        
        try {
            DynamicPathController.getStatusByCurrentStatus('');
            System.assert(false);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        
        System.assert(exceptionThrown);
    }
    
    @IsTest
    static void testGetHideStatuses() {
        Test.startTest();
        List<String> result = DynamicPathController.getHideStatuses();
        Test.stopTest();
        
        System.assertNotEquals(null, result);
    }
    
    @IsTest
    static void testUpdateRecordStatus_NoId() {
        Boolean exceptionThrown = false;
        
        try {
            DynamicPathController.updateRecordStatus(null, '', '');
            System.assert(false);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
    }
    
    @IsTest
    static void testUpdateRecordStatus_NofieldApiName() {
        Boolean exceptionThrown = false;
        Case__c c = [SELECT Id FROM Case__c LIMIT 1];
        
        try {
            DynamicPathController.updateRecordStatus(c.Id, '', '');
            System.assert(false);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
    }
    
    @IsTest
    static void testUpdateRecordStatus_PriorApplicationStatus() {
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        Case__c c = [SELECT Id, Prior_Application_Status__c, Status__c FROM Case__c LIMIT 1];
        String appStatus = c.Status__c;
        
        c.Status__c = 'Further Information Requested';
        c.Prior_Application_Status__c = 'Under Review';
        Update c;
        
        SalesforceSettings__c settings = SalesforceSettings__c.getOrgDefaults();
        settings.client_id__c = 'Some Value';
        settings.client_secret__c = 'Some Value';
        settings.Endpoint_Url__c = 'Some Value';
        settings.grant_type__c = 'client_credentials';
        insert settings;
        
        Test.startTest();
        DynamicPathController.updateRecordStatus(c.Id, 'Status__c', 'Further Information Requested');
        Test.stopTest();
        
        List<String> picklist =
            DynamicPathController.getPicklistValuesByRecord(c.Id, 'Status__c');
        
        Case__c updated = [SELECT Prior_Application_Status__c, Status__c FROM Case__c WHERE Id = :c.Id];
        System.assertEquals(appStatus, updated.Status__c);
        System.assertEquals('Further Information Requested', updated.Prior_Application_Status__c);
    }
    
    global class MockHttpResponseGenerator implements HttpCalloutMock {
        global HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"message":"success"}');
            return res;
        }
    }
}