@IsTest
private class GovUKNotifyServiceTest {
    
    @TestSetup
    static void setupTestData() {
        NotifyApiSettings__c settings = new NotifyApiSettings__c(
            Issuer_UUID__c = 'test-issuer-uuid-1234',
            Secret_Key__c = 'test-secret-key-5678'
        );
        insert settings;
    }
    
    @IsTest
    static void testSendEmail_Success() {
        Test.setMock(HttpCalloutMock.class, new MockSuccess());
        
        Test.startTest();
        GovUKNotifyService.NotifyResponse response = 
            GovUKNotifyService.sendEmail('test@example.com', 'template-123');
        Test.stopTest();
        
        Assert.isTrue(response.success, 'Email should be sent successfully');
        Assert.areEqual(200, response.statusCode, 'Status code should be 200');
        Assert.isNotNull(response.notificationId, 'Should have notification ID');
    }
    
    @IsTest
    static void testSendEmail_WithPersonalisation() {
        Test.setMock(HttpCalloutMock.class, new MockSuccess());
        
        Map<String, String> personalisation = new Map<String, String>{
            'case_reference' => 'REF123',
            'applicant_name' => 'John Doe',
            'case_url' => 'https://example.com'
        };
        
        Test.startTest();
        GovUKNotifyService.NotifyResponse response = 
            GovUKNotifyService.sendEmail('test@example.com', 'template-123', personalisation);
        Test.stopTest();
        
        Assert.isTrue(response.success, 'Email with personalisation should succeed');
        Assert.isNotNull(response.notificationId, 'Should have notification ID');
    }
    
    @IsTest
    static void testSendEmail_MissingEmailAddress() {
        try {
            Test.startTest();
            GovUKNotifyService.sendEmail('', 'template-123');
            Test.stopTest();
            
            Assert.fail('Should throw NotifyException for missing email address');
        } catch (GovUKNotifyService.NotifyException ex) {
            Assert.isTrue(
                ex.getMessage().contains('Email address is required'),
                'Exception message should mention missing email address'
            );
        }
    }
    
    @IsTest
    static void testSendEmail_MissingTemplateId() {
        try {
            Test.startTest();
            GovUKNotifyService.sendEmail('test@example.com', null);
            Test.stopTest();
            
            Assert.fail('Should throw NotifyException for missing template ID');
        } catch (GovUKNotifyService.NotifyException ex) {
            Assert.isTrue(
                ex.getMessage().contains('Template ID is required'),
                'Exception message should mention missing template ID'
            );
        }
    }
    
    @IsTest
    static void testSendEmail_HTTPError400() {
        Test.setMock(HttpCalloutMock.class, new MockBadRequest());
        
        try {
            Test.startTest();
            GovUKNotifyService.sendEmail('test@example.com', 'template-123');
            Test.stopTest();
            
            Assert.fail('Should throw NotifyException for HTTP 400 error');
        } catch (GovUKNotifyService.NotifyException ex) {
            Assert.isTrue(
                ex.getMessage().contains('400'),
                'Exception message should contain HTTP status code'
            );
        }
    }
    
    @IsTest
    static void testSendEmail_HTTPError500() {
        Test.setMock(HttpCalloutMock.class, new MockServerError());
        
        try {
            Test.startTest();
            GovUKNotifyService.sendEmail('test@example.com', 'template-123');
            Test.stopTest();
            
            Assert.fail('Should throw NotifyException for HTTP 500 error');
        } catch (GovUKNotifyService.NotifyException ex) {
            Assert.isTrue(
                ex.getMessage().contains('500'),
                'Exception message should contain HTTP status code'
            );
        }
    }
    
    @IsTest
    static void testSendEmail_MissingApiSettings() {
        delete [SELECT Id FROM NotifyApiSettings__c];
        
        try {
            Test.startTest();
            GovUKNotifyService.sendEmail('test@example.com', 'template-123');
            Test.stopTest();
            
            Assert.fail('Should throw exception for missing API settings');
        } catch (GovUKNotifyService.NotifyException ex) {
            Assert.isTrue(
                ex.getMessage().contains('not configured properly'),
                'Exception should mention missing configuration'
            );
        }
    }
    
    @IsTest
    static void testSendEmail_EmptyPersonalisationMap() {
        Test.setMock(HttpCalloutMock.class, new MockSuccess());
        
        Map<String, String> personalisation = new Map<String, String>();
        
        Test.startTest();
        GovUKNotifyService.NotifyResponse response = 
            GovUKNotifyService.sendEmail('test@example.com', 'template-123', personalisation);
        Test.stopTest();
        
        Assert.isTrue(response.success, 'Should succeed with empty personalisation map');
    }
    
    @IsTest
    static void testParseResponse_WithReference() {
        Test.setMock(HttpCalloutMock.class, new MockWithReference());
        
        Test.startTest();
        GovUKNotifyService.NotifyResponse response = 
            GovUKNotifyService.sendEmail('test@example.com', 'template-123');
        Test.stopTest();
        
        Assert.isTrue(response.success, 'Response should be successful');
        Assert.isNotNull(response.reference, 'Response should contain reference');
        Assert.areEqual('custom-ref-123', response.reference, 'Reference should match expected value');
    }
    
    @IsTest
    static void testSendEmail_HTTPError401Unauthorized() {
        Test.setMock(HttpCalloutMock.class, new MockUnauthorized());
        
        try {
            Test.startTest();
            GovUKNotifyService.sendEmail('test@example.com', 'template-123');
            Test.stopTest();
            
            Assert.fail('Should throw NotifyException for HTTP 401 error');
        } catch (GovUKNotifyService.NotifyException ex) {
            Assert.isTrue(
                ex.getMessage().contains('401'),
                'Exception message should contain 401 status code'
            );
        }
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
    
    private class MockBadRequest implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"errors":[{"error":"BadRequestError","message":"Invalid template"}]}');
            res.setStatusCode(400);
            return res;
        }
    }
    
    private class MockServerError implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"errors":[{"error":"InternalServerError","message":"Internal error"}]}');
            res.setStatusCode(500);
            return res;
        }
    }
    
    private class MockUnauthorized implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"errors":[{"error":"AuthError","message":"Invalid token"}]}');
            res.setStatusCode(401);
            return res;
        }
    }
    
    private class MockWithReference implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"id":"notification-id-456","reference":"custom-ref-123"}');
            res.setStatusCode(200);
            return res;
        }
    }
}