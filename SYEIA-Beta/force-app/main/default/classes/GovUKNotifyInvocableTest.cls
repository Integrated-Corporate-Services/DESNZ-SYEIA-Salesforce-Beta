@IsTest
private class GovUKNotifyInvocableTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test API settings
        NotifyApiSettings__c settings = new NotifyApiSettings__c(
            Issuer_UUID__c = 'test-issuer-uuid-1234',
            Secret_Key__c = 'test-secret-key-5678'
        );
        insert settings;
        
        // Create test Case
        Case__c testCase = new Case__c();
        insert testCase;
    }
    
    @IsTest
    static void testSendNotifyEmail_Success() {
        Case__c testCase = [SELECT Id FROM Case__c LIMIT 1];
        
        // Setup mock callout
        Test.setMock(HttpCalloutMock.class, new MockSuccess());
        
        // Prepare request
        GovUKNotifyInvocable.Request req = new GovUKNotifyInvocable.Request();
        req.caseId = testCase.Id;
        req.recipientEmail = 'test@example.com';
        req.templateId = 'template-123';
        req.personalisationJson = '{"case_reference":"REF123","applicant_name":"John Doe"}';
        
        Test.startTest();
        List<GovUKNotifyInvocable.Result> results = 
            GovUKNotifyInvocable.sendNotifyEmail(new List<GovUKNotifyInvocable.Request>{req});
        Test.stopTest();
        
        Assert.areEqual(1, results.size(), 'Should return one result');
        Assert.isTrue(results[0].success, 'Request should be successful');
        Assert.isNull(results[0].errorMessage, 'Should not have error message');
    }
    
    @IsTest
    static void testSendNotifyEmail_MissingRecipientEmail() {
        // Prepare request without recipient email
        GovUKNotifyInvocable.Request req = new GovUKNotifyInvocable.Request();
        req.templateId = 'template-123';
        req.personalisationJson = '{"case_reference":"REF123"}';
        
        Test.startTest();
        List<GovUKNotifyInvocable.Result> results = 
            GovUKNotifyInvocable.sendNotifyEmail(new List<GovUKNotifyInvocable.Request>{req});
        Test.stopTest();
        
        Assert.areEqual(1, results.size(), 'Should return one result');
        Assert.isFalse(results[0].success, 'Request should fail');
        Assert.isNotNull(results[0].errorMessage, 'Should have error message');
        Assert.isTrue(
            results[0].errorMessage.contains('Recipient email is required'),
            'Error message should mention missing recipient email'
        );
    }
    
    @IsTest
    static void testSendNotifyEmail_MissingTemplateId() {
        // Prepare request without template ID
        GovUKNotifyInvocable.Request req = new GovUKNotifyInvocable.Request();
        req.recipientEmail = 'test@example.com';
        req.personalisationJson = '{"case_reference":"REF123"}';
        
        Test.startTest();
        List<GovUKNotifyInvocable.Result> results = 
            GovUKNotifyInvocable.sendNotifyEmail(new List<GovUKNotifyInvocable.Request>{req});
        Test.stopTest();
        
        Assert.areEqual(1, results.size(), 'Should return one result');
        Assert.isFalse(results[0].success, 'Request should fail');
        Assert.isTrue(
            results[0].errorMessage.contains('Template ID is required'),
            'Error message should mention missing template ID'
        );
    }
    
    @IsTest
    static void testSendNotifyEmail_ValidPersonalisationJson() {
        Case__c testCase = [SELECT Id FROM Case__c LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new MockSuccess());
        
        // Valid JSON with multiple fields
        GovUKNotifyInvocable.Request req = new GovUKNotifyInvocable.Request();
        req.caseId = testCase.Id;
        req.recipientEmail = 'test@example.com';
        req.templateId = 'template-123';
        req.personalisationJson = '{"case_reference":"REF123","case_url":"https://example.com","applicant_name":"John Doe"}';
        
        Test.startTest();
        List<GovUKNotifyInvocable.Result> results = 
            GovUKNotifyInvocable.sendNotifyEmail(new List<GovUKNotifyInvocable.Request>{req});
        Test.stopTest();
        
        Assert.isTrue(results[0].success, 'Request should be successful with valid JSON');
        Assert.isNull(results[0].errorMessage, 'Should not have error message');
    }
    
    @IsTest
    static void testSendNotifyEmail_MalformedJsonWithRepair() {
        Test.setMock(HttpCalloutMock.class, new MockSuccess());
        
        // Malformed JSON that needs repair (unescaped line breaks)
        GovUKNotifyInvocable.Request req = new GovUKNotifyInvocable.Request();
        req.recipientEmail = 'test@example.com';
        req.templateId = 'template-123';
        req.personalisationJson = '{"case_reference":"REF123","description":"Line one\nLine two"}';
        
        Test.startTest();
        List<GovUKNotifyInvocable.Result> results = 
            GovUKNotifyInvocable.sendNotifyEmail(new List<GovUKNotifyInvocable.Request>{req});
        Test.stopTest();
        
        Assert.isTrue(results[0].success, 'Request should succeed after JSON repair');
    }
    
    @IsTest
    static void testSendNotifyEmail_InvalidJsonAfterRepair() {
        // Completely invalid JSON that cannot be repaired
        GovUKNotifyInvocable.Request req = new GovUKNotifyInvocable.Request();
        req.recipientEmail = 'test@example.com';
        req.templateId = 'template-123';
        req.personalisationJson = 'not valid json at all';
        
        Test.startTest();
        List<GovUKNotifyInvocable.Result> results = 
            GovUKNotifyInvocable.sendNotifyEmail(new List<GovUKNotifyInvocable.Request>{req});
        Test.stopTest();
        
        Assert.isFalse(results[0].success, 'Request should fail with invalid JSON');
        Assert.isTrue(
            results[0].errorMessage.contains('JSON'),
            'Error message should mention JSON issue'
        );
    }
    
    @IsTest
    static void testSendNotifyEmail_BulkRequests() {
        Test.setMock(HttpCalloutMock.class, new MockSuccess());
        
        List<GovUKNotifyInvocable.Request> requests = new List<GovUKNotifyInvocable.Request>();
        
        // Create 5 requests
        for (Integer i = 0; i < 5; i++) {
            GovUKNotifyInvocable.Request req = new GovUKNotifyInvocable.Request();
            req.recipientEmail = 'test' + i + '@example.com';
            req.templateId = 'template-123';
            req.personalisationJson = '{"reference":"REF' + i + '"}';
            requests.add(req);
        }
        
        Test.startTest();
        List<GovUKNotifyInvocable.Result> results = 
            GovUKNotifyInvocable.sendNotifyEmail(requests);
        Test.stopTest();
        
        Assert.areEqual(5, results.size(), 'Should return 5 results');
        for (GovUKNotifyInvocable.Result result : results) {
            Assert.isTrue(result.success, 'All bulk requests should succeed');
        }
    }
    
    @IsTest
    static void testSendNotifyEmail_EmptyPersonalisation() {
        Test.setMock(HttpCalloutMock.class, new MockSuccess());
        
        GovUKNotifyInvocable.Request req = new GovUKNotifyInvocable.Request();
        req.recipientEmail = 'test@example.com';
        req.templateId = 'template-123';
        req.personalisationJson = null;
        
        Test.startTest();
        List<GovUKNotifyInvocable.Result> results = 
            GovUKNotifyInvocable.sendNotifyEmail(new List<GovUKNotifyInvocable.Request>{req});
        Test.stopTest();
        
        Assert.isTrue(results[0].success, 'Request should succeed without personalisation');
    }
    
    @IsTest
    static void testQueueable_UpdatesCaseFlag() {
        Case__c testCase = [SELECT Id, Overdue_Email_Sent__c FROM Case__c LIMIT 1];
        Assert.isFalse(testCase.Overdue_Email_Sent__c, 'Flag should be false initially');
        
        Test.setMock(HttpCalloutMock.class, new MockSuccess());
        
        GovUKNotifyInvocable.Request req = new GovUKNotifyInvocable.Request();
        req.caseId = testCase.Id;
        req.recipientEmail = 'test@example.com';
        req.templateId = 'template-123';
        
        Test.startTest();
        System.enqueueJob(new GovUKNotifyInvocable.GovUKNotifyQueueable(req));
        Test.stopTest();
        
        Case__c updatedCase = [SELECT Id, Overdue_Email_Sent__c FROM Case__c WHERE Id = :testCase.Id];
        Assert.isTrue(updatedCase.Overdue_Email_Sent__c, 'Case flag should be updated after email sent');
    }
    
    @IsTest
    static void testQueueable_WithoutCaseId() {
        Test.setMock(HttpCalloutMock.class, new MockSuccess());
        
        GovUKNotifyInvocable.Request req = new GovUKNotifyInvocable.Request();
        req.recipientEmail = 'test@example.com';
        req.templateId = 'template-123';
        
        Test.startTest();
        System.enqueueJob(new GovUKNotifyInvocable.GovUKNotifyQueueable(req));
        Test.stopTest();
        
        // Should complete without errors
        Assert.isTrue(true, 'Queueable should handle missing case ID gracefully');
    }
    
    @IsTest
    static void testQueueable_CalloutFailure() {
        Test.setMock(HttpCalloutMock.class, new MockFailure());
        
        GovUKNotifyInvocable.Request req = new GovUKNotifyInvocable.Request();
        req.recipientEmail = 'test@example.com';
        req.templateId = 'template-123';
        
        Test.startTest();
        System.enqueueJob(new GovUKNotifyInvocable.GovUKNotifyQueueable(req));
        Test.stopTest();
        
        // Should handle failure gracefully without throwing exception
        Assert.isTrue(true, 'Queueable should handle callout failure gracefully');
    }
    
    @IsTest
    static void testRepairFlowJson_ComplexScenario() {
        Test.setMock(HttpCalloutMock.class, new MockSuccess());
        
        // Complex JSON with nested values and special characters
        GovUKNotifyInvocable.Request req = new GovUKNotifyInvocable.Request();
        req.recipientEmail = 'test@example.com';
        req.templateId = 'template-123';
        req.personalisationJson = '{"name":"John Doe","message":"Hello\nWorld","url":"https://example.com?param=value"}';
        
        Test.startTest();
        List<GovUKNotifyInvocable.Result> results = 
            GovUKNotifyInvocable.sendNotifyEmail(new List<GovUKNotifyInvocable.Request>{req});
        Test.stopTest();
        
        Assert.isTrue(results[0].success, 'Should handle complex JSON scenarios');
    }
    
    // Inner Mock Classes
    private class MockSuccess implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"id":"notification-id-123","reference":"ref-123"}');
            res.setStatusCode(200);
            return res;
        }
    }
    
    private class MockFailure implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"errors":[{"error":"ServiceError","message":"Service unavailable"}]}');
            res.setStatusCode(500);
            return res;
        }
    }
}