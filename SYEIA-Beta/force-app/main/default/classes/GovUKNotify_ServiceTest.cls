/**
 * Test class for GovUKNotify_Service
 */
@IsTest
private class GovUKNotify_ServiceTest {
    
    // ========================================================================
    // TEST CONSTANTS
    // ========================================================================
    
    private static final String VALID_EMAIL = 'test@example.gov.uk';
    private static final String VALID_TEMPLATE_ID = 'template-uuid-12345';
    private static final String SUCCESS_NOTIFICATION_ID = 'notification-uuid-67890';
    
    // ========================================================================
    // MOCK HTTP CALLOUT CLASS
    // ========================================================================
    
    /**
     * Mock class for successful HTTP responses
     */
    private class MockHttpResponseSuccess implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(201);
            res.setHeader('Content-Type', 'application/json');
            res.setBody(JSON.serialize(new Map<String, Object>{
                'id' => SUCCESS_NOTIFICATION_ID,
                'reference' => 'ref-12345',
                'content' => new Map<String, Object>{
                    'subject' => 'Test Subject',
                    'body' => 'Test Body'
                },
                'uri' => 'https://api.notifications.service.gov.uk/v2/notifications/' + SUCCESS_NOTIFICATION_ID,
                'template' => new Map<String, Object>{
                    'id' => VALID_TEMPLATE_ID,
                    'version' => 1
                }
            }));
            return res;
        }
    }
    
    /**
     * Mock class for HTTP error responses
     */
    private class MockHttpResponseError implements HttpCalloutMock {
        private Integer statusCode;
        private String errorMessage;
        
        public MockHttpResponseError(Integer statusCode, String errorMessage) {
            this.statusCode = statusCode;
            this.errorMessage = errorMessage;
        }
        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            res.setHeader('Content-Type', 'application/json');
            res.setBody(JSON.serialize(new Map<String, Object>{
                'errors' => new List<Object>{
                    new Map<String, Object>{
                        'error' => 'ValidationError',
                        'message' => errorMessage
                    }
                },
                'status_code' => statusCode
            }));
            return res;
        }
    }
    
    /**
     * Mock class for HTTP error with multiple errors
     */
    private class MockHttpResponseMultipleErrors implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(400);
            res.setHeader('Content-Type', 'application/json');
            res.setBody(JSON.serialize(new Map<String, Object>{
                'errors' => new List<Object>{
                    new Map<String, Object>{
                        'error' => 'ValidationError',
                        'message' => 'email_address is required'
                    },
                    new Map<String, Object>{
                        'error' => 'ValidationError',
                        'message' => 'template_id is invalid'
                    }
                },
                'status_code' => 400
            }));
            return res;
        }
    }
    
    /**
     * Mock class for non-JSON error response
     */
    private class MockHttpResponseNonJsonError implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setHeader('Content-Type', 'text/html');
            res.setBody('<html><body>Internal Server Error</body></html>');
            return res;
        }
    }
    
    /**
     * Mock class for empty body response
     */
    private class MockHttpResponseEmptyBody implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(201);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('');
            return res;
        }
    }
    
    /**
     * Mock class that validates request structure
     */
    private class MockHttpResponseValidatingRequest implements HttpCalloutMock {
        private String expectedEmail;
        private String expectedTemplateId;
        private Map<String, String> expectedPersonalisation;
        
        public MockHttpResponseValidatingRequest(String email, String templateId, 
                                                   Map<String, String> personalisation) {
            this.expectedEmail = email;
            this.expectedTemplateId = templateId;
            this.expectedPersonalisation = personalisation;
        }
        
        public HTTPResponse respond(HTTPRequest req) {
            // Validate request headers
            System.assert(req.getHeader('Authorization').startsWith('Bearer '), 
                'Should have Bearer token');
            System.assertEquals('application/json', req.getHeader('Content-Type'), 
                'Content-Type should be JSON');
            
            // Validate request body
            Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(req.getBody());
            System.assertEquals(expectedEmail, body.get('email_address'), 
                'Email should match');
            System.assertEquals(expectedTemplateId, body.get('template_id'), 
                'Template ID should match');
            
            if (expectedPersonalisation != null && !expectedPersonalisation.isEmpty()) {
                System.assert(body.containsKey('personalisation'), 
                    'Should include personalisation');
            }
            
            HttpResponse res = new HttpResponse();
            res.setStatusCode(201);
            res.setBody(JSON.serialize(new Map<String, Object>{
                'id' => SUCCESS_NOTIFICATION_ID,
                'reference' => null
            }));
            return res;
        }
    }
    
    // ========================================================================
    // SEND EMAIL TESTS - WITHOUT PERSONALISATION
    // ========================================================================
    
    @IsTest
    static void testSendEmail_SuccessWithoutPersonalisation() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseSuccess());
        
        Test.startTest();
        GovUKNotify_Service.NotifyResponse response = 
            GovUKNotify_Service.sendEmail(VALID_EMAIL, VALID_TEMPLATE_ID);
        Test.stopTest();
        
        Assert.isTrue(response.success, 'Response should be successful');
        Assert.areEqual(201, response.statusCode, 'Status code should be 201');
        Assert.areEqual(SUCCESS_NOTIFICATION_ID, response.notificationId, 
            'Notification ID should match');
    }
    
    @IsTest
    static void testSendEmail_RequestStructure() {
        Test.setMock(HttpCalloutMock.class, 
            new MockHttpResponseValidatingRequest(VALID_EMAIL, VALID_TEMPLATE_ID, null));
        
        Test.startTest();
        GovUKNotify_Service.NotifyResponse response = 
            GovUKNotify_Service.sendEmail(VALID_EMAIL, VALID_TEMPLATE_ID);
        Test.stopTest();
        
        Assert.isTrue(response.success, 'Request validation should pass');
    }
    
    // ========================================================================
    // SEND EMAIL TESTS - WITH PERSONALISATION
    // ========================================================================
    
    @IsTest
    static void testSendEmail_SuccessWithPersonalisation() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseSuccess());
        
        Map<String, String> personalisation = new Map<String, String>{
            'first_name' => 'John',
            'reference_number' => 'REF-001'
        };
        
        Test.startTest();
        GovUKNotify_Service.NotifyResponse response = 
            GovUKNotify_Service.sendEmail(VALID_EMAIL, VALID_TEMPLATE_ID, personalisation);
        Test.stopTest();
        
        Assert.isTrue(response.success, 'Response should be successful');
        Assert.areEqual(SUCCESS_NOTIFICATION_ID, response.notificationId, 
            'Notification ID should match');
    }
    
    @IsTest
    static void testSendEmail_WithEmptyPersonalisation() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseSuccess());
        
        Map<String, String> personalisation = new Map<String, String>();
        
        Test.startTest();
        GovUKNotify_Service.NotifyResponse response = 
            GovUKNotify_Service.sendEmail(VALID_EMAIL, VALID_TEMPLATE_ID, personalisation);
        Test.stopTest();
        
        Assert.isTrue(response.success, 'Should succeed with empty personalisation');
    }
    
    @IsTest
    static void testSendEmail_WithNullPersonalisation() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseSuccess());
        
        Test.startTest();
        GovUKNotify_Service.NotifyResponse response = 
            GovUKNotify_Service.sendEmail(VALID_EMAIL, VALID_TEMPLATE_ID, null);
        Test.stopTest();
        
        Assert.isTrue(response.success, 'Should succeed with null personalisation');
    }
    
    // ========================================================================
    // INPUT VALIDATION TESTS
    // ========================================================================
    
    @IsTest
    static void testSendEmail_BlankEmailAddress() {
        Test.startTest();
        Boolean exceptionThrown = false;
        String exceptionMessage = '';
        
        try {
            GovUKNotify_Service.sendEmail('', VALID_TEMPLATE_ID);
        } catch (GovUKNotify_Service.NotifyException e) {
            exceptionThrown = true;
            exceptionMessage = e.getMessage();
        }
        Test.stopTest();
        
        Assert.isTrue(exceptionThrown, 'Should throw exception for blank email');
        Assert.isTrue(exceptionMessage.contains('Email address is required'), 
            'Exception should mention email address');
    }
    
    @IsTest
    static void testSendEmail_NullEmailAddress() {
        Test.startTest();
        Boolean exceptionThrown = false;
        String exceptionMessage = '';
        
        try {
            GovUKNotify_Service.sendEmail(null, VALID_TEMPLATE_ID);
        } catch (GovUKNotify_Service.NotifyException e) {
            exceptionThrown = true;
            exceptionMessage = e.getMessage();
        }
        Test.stopTest();
        
        Assert.isTrue(exceptionThrown, 'Should throw exception for null email');
        Assert.isTrue(exceptionMessage.contains('Email address is required'), 
            'Exception should mention email address');
    }
    
    @IsTest
    static void testSendEmail_BlankTemplateId() {
        Test.startTest();
        Boolean exceptionThrown = false;
        String exceptionMessage = '';
        
        try {
            GovUKNotify_Service.sendEmail(VALID_EMAIL, '');
        } catch (GovUKNotify_Service.NotifyException e) {
            exceptionThrown = true;
            exceptionMessage = e.getMessage();
        }
        Test.stopTest();
        
        Assert.isTrue(exceptionThrown, 'Should throw exception for blank template ID');
        Assert.isTrue(exceptionMessage.contains('Template ID is required'), 
            'Exception should mention template ID');
    }
    
    @IsTest
    static void testSendEmail_NullTemplateId() {
        Test.startTest();
        Boolean exceptionThrown = false;
        String exceptionMessage = '';
        
        try {
            GovUKNotify_Service.sendEmail(VALID_EMAIL, null);
        } catch (GovUKNotify_Service.NotifyException e) {
            exceptionThrown = true;
            exceptionMessage = e.getMessage();
        }
        Test.stopTest();
        
        Assert.isTrue(exceptionThrown, 'Should throw exception for null template ID');
        Assert.isTrue(exceptionMessage.contains('Template ID is required'), 
            'Exception should mention template ID');
    }
    
    @IsTest
    static void testSendEmail_InvalidEmailFormat() {
        Test.startTest();
        Boolean exceptionThrown = false;
        String exceptionMessage = '';
        
        try {
            GovUKNotify_Service.sendEmail('not-an-email', VALID_TEMPLATE_ID);
        } catch (GovUKNotify_Service.NotifyException e) {
            exceptionThrown = true;
            exceptionMessage = e.getMessage();
        }
        Test.stopTest();
        
        Assert.isTrue(exceptionThrown, 'Should throw exception for invalid email format');
        Assert.isTrue(exceptionMessage.contains('Invalid email address format'), 
            'Exception should mention invalid format');
    }
    
    @IsTest
    static void testSendEmail_InvalidEmailFormat_MissingDomain() {
        Test.startTest();
        Boolean exceptionThrown = false;
        
        try {
            GovUKNotify_Service.sendEmail('test@', VALID_TEMPLATE_ID);
        } catch (GovUKNotify_Service.NotifyException e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        
        Assert.isTrue(exceptionThrown, 'Should throw exception for email without domain');
    }
    
    @IsTest
    static void testSendEmail_InvalidEmailFormat_MissingLocalPart() {
        Test.startTest();
        Boolean exceptionThrown = false;
        
        try {
            GovUKNotify_Service.sendEmail('@example.com', VALID_TEMPLATE_ID);
        } catch (GovUKNotify_Service.NotifyException e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        
        Assert.isTrue(exceptionThrown, 'Should throw exception for email without local part');
    }
    
    @IsTest
    static void testSendEmail_ValidEmailFormats() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseSuccess());
        
        List<String> validEmails = new List<String>{
            'simple@example.com',
            'very.common@example.com',
            'disposable.style.email.with+symbol@example.com',
            'other.email-with-hyphen@example.com',
            'fully-qualified-domain@example.com',
            'user.name+tag+sorting@example.com',
            'x@example.com',
            'example-indeed@strange-example.com',
            'example@s.example'
        };
        
        Test.startTest();
        for (String email : validEmails) {
            GovUKNotify_Service.NotifyResponse response = 
                GovUKNotify_Service.sendEmail(email, VALID_TEMPLATE_ID);
            Assert.isTrue(response.success, 'Should accept valid email: ' + email);
        }
        Test.stopTest();
    }
    
    // ========================================================================
    // HTTP ERROR HANDLING TESTS
    // ========================================================================
    
    @IsTest
    static void testSendEmail_Http400Error() {
        Test.setMock(HttpCalloutMock.class, 
            new MockHttpResponseError(400, 'Bad Request - Invalid template ID'));
        
        Test.startTest();
        Boolean exceptionThrown = false;
        String exceptionMessage = '';
        
        try {
            GovUKNotify_Service.sendEmail(VALID_EMAIL, VALID_TEMPLATE_ID);
        } catch (GovUKNotify_Service.NotifyException e) {
            exceptionThrown = true;
            exceptionMessage = e.getMessage();
        }
        Test.stopTest();
        
        Assert.isTrue(exceptionThrown, 'Should throw exception for 400 error');
        Assert.isTrue(exceptionMessage.contains('HTTP Error 400'), 
            'Exception should contain status code');
        Assert.isTrue(exceptionMessage.contains('Bad Request'), 
            'Exception should contain error message');
    }
    
    @IsTest
    static void testSendEmail_Http401Error() {
        Test.setMock(HttpCalloutMock.class, 
            new MockHttpResponseError(401, 'Unauthorized - Invalid API key'));
        
        Test.startTest();
        Boolean exceptionThrown = false;
        String exceptionMessage = '';
        
        try {
            GovUKNotify_Service.sendEmail(VALID_EMAIL, VALID_TEMPLATE_ID);
        } catch (GovUKNotify_Service.NotifyException e) {
            exceptionThrown = true;
            exceptionMessage = e.getMessage();
        }
        Test.stopTest();
        
        Assert.isTrue(exceptionThrown, 'Should throw exception for 401 error');
        Assert.isTrue(exceptionMessage.contains('HTTP Error 401'), 
            'Exception should contain status code');
    }
    
    @IsTest
    static void testSendEmail_Http403Error() {
        Test.setMock(HttpCalloutMock.class, 
            new MockHttpResponseError(403, 'Forbidden - Insufficient permissions'));
        
        Test.startTest();
        Boolean exceptionThrown = false;
        
        try {
            GovUKNotify_Service.sendEmail(VALID_EMAIL, VALID_TEMPLATE_ID);
        } catch (GovUKNotify_Service.NotifyException e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        
        Assert.isTrue(exceptionThrown, 'Should throw exception for 403 error');
    }
    
    @IsTest
    static void testSendEmail_Http429Error() {
        Test.setMock(HttpCalloutMock.class, 
            new MockHttpResponseError(429, 'Rate limit exceeded'));
        
        Test.startTest();
        Boolean exceptionThrown = false;
        String exceptionMessage = '';
        
        try {
            GovUKNotify_Service.sendEmail(VALID_EMAIL, VALID_TEMPLATE_ID);
        } catch (GovUKNotify_Service.NotifyException e) {
            exceptionThrown = true;
            exceptionMessage = e.getMessage();
        }
        Test.stopTest();
        
        Assert.isTrue(exceptionThrown, 'Should throw exception for 429 error');
        Assert.isTrue(exceptionMessage.contains('Rate limit'), 
            'Exception should contain rate limit message');
    }
    
    @IsTest
    static void testSendEmail_Http500Error() {
        Test.setMock(HttpCalloutMock.class, 
            new MockHttpResponseError(500, 'Internal server error'));
        
        Test.startTest();
        Boolean exceptionThrown = false;
        String exceptionMessage = '';
        
        try {
            GovUKNotify_Service.sendEmail(VALID_EMAIL, VALID_TEMPLATE_ID);
        } catch (GovUKNotify_Service.NotifyException e) {
            exceptionThrown = true;
            exceptionMessage = e.getMessage();
        }
        Test.stopTest();
        
        Assert.isTrue(exceptionThrown, 'Should throw exception for 500 error');
        Assert.isTrue(exceptionMessage.contains('HTTP Error 500'), 
            'Exception should contain status code');
    }
    
    @IsTest
    static void testSendEmail_MultipleErrors() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseMultipleErrors());
        
        Test.startTest();
        Boolean exceptionThrown = false;
        String exceptionMessage = '';
        
        try {
            GovUKNotify_Service.sendEmail(VALID_EMAIL, VALID_TEMPLATE_ID);
        } catch (GovUKNotify_Service.NotifyException e) {
            exceptionThrown = true;
            exceptionMessage = e.getMessage();
        }
        Test.stopTest();
        
        Assert.isTrue(exceptionThrown, 'Should throw exception for multiple errors');
        Assert.isTrue(exceptionMessage.contains('email_address is required'), 
            'Exception should contain first error');
        Assert.isTrue(exceptionMessage.contains('template_id is invalid'), 
            'Exception should contain second error');
    }
    
    @IsTest
    static void testSendEmail_NonJsonErrorResponse() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseNonJsonError());
        
        Test.startTest();
        Boolean exceptionThrown = false;
        String exceptionMessage = '';
        
        try {
            GovUKNotify_Service.sendEmail(VALID_EMAIL, VALID_TEMPLATE_ID);
        } catch (GovUKNotify_Service.NotifyException e) {
            exceptionThrown = true;
            exceptionMessage = e.getMessage();
        }
        Test.stopTest();
        
        Assert.isTrue(exceptionThrown, 'Should throw exception for non-JSON error');
        Assert.isTrue(exceptionMessage.contains('HTTP Error 500'), 
            'Exception should contain status code');
    }
    
    // ========================================================================
    // RESPONSE PARSING TESTS
    // ========================================================================
    
    @IsTest
    static void testSendEmail_ParseResponseWithReference() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseSuccess());
        
        Test.startTest();
        GovUKNotify_Service.NotifyResponse response = 
            GovUKNotify_Service.sendEmail(VALID_EMAIL, VALID_TEMPLATE_ID);
        Test.stopTest();
        
        Assert.areEqual('ref-12345', response.reference, 'Reference should be parsed');
        Assert.isNotNull(response.rawResponse, 'Raw response should be captured');
    }
    
    @IsTest
    static void testSendEmail_ParseEmptyBodyResponse() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseEmptyBody());
        
        Test.startTest();
        GovUKNotify_Service.NotifyResponse response = 
            GovUKNotify_Service.sendEmail(VALID_EMAIL, VALID_TEMPLATE_ID);
        Test.stopTest();
        
        Assert.isTrue(response.success, 'Should succeed with empty body');
        Assert.isNull(response.notificationId, 'Notification ID should be null for empty body');
    }
    
    // ========================================================================
    // NOTIFY RESPONSE CLASS TESTS
    // ========================================================================
    
    @IsTest
    static void testNotifyResponse_DefaultConstructor() {
        Test.startTest();
        GovUKNotify_Service.NotifyResponse response = new GovUKNotify_Service.NotifyResponse();
        Test.stopTest();
        
        Assert.isFalse(response.success, 'Default success should be false');
        Assert.isNull(response.statusCode, 'Default statusCode should be null');
        Assert.isNull(response.notificationId, 'Default notificationId should be null');
        Assert.isNull(response.reference, 'Default reference should be null');
        Assert.isNull(response.rawResponse, 'Default rawResponse should be null');
    }
    
    @IsTest
    static void testNotifyResponse_Properties() {
        Test.startTest();
        GovUKNotify_Service.NotifyResponse response = new GovUKNotify_Service.NotifyResponse();
        response.success = true;
        response.statusCode = 201;
        response.notificationId = 'test-id';
        response.reference = 'test-ref';
        response.rawResponse = '{"test": "response"}';
        Test.stopTest();
        
        Assert.isTrue(response.success, 'Success should be true');
        Assert.areEqual(201, response.statusCode, 'Status code should match');
        Assert.areEqual('test-id', response.notificationId, 'Notification ID should match');
        Assert.areEqual('test-ref', response.reference, 'Reference should match');
        Assert.areEqual('{"test": "response"}', response.rawResponse, 'Raw response should match');
    }
    
    // ========================================================================
    // NOTIFY EXCEPTION TESTS
    // ========================================================================
    
    @IsTest
    static void testNotifyException_Creation() {
        Test.startTest();
        GovUKNotify_Service.NotifyException ex = 
            new GovUKNotify_Service.NotifyException('Test error message');
        Test.stopTest();
        
        Assert.areEqual('Test error message', ex.getMessage(), 'Message should match');
    }
    
    // ========================================================================
    // CONFIG CACHE TESTS
    // ========================================================================
    
    @IsTest
    static void testClearConfigCache() {
        Test.startTest();
        GovUKNotify_Service.clearConfigCache();
        Test.stopTest();
        
        Assert.isTrue(true, 'Cache clear should complete without error');
    }
    
    // ========================================================================
    // STATUS CODE BOUNDARY TESTS
    // ========================================================================
    
    @IsTest
    static void testSendEmail_StatusCode200() {
        Test.setMock(HttpCalloutMock.class, new MockHttp200Response());
        
        Test.startTest();
        GovUKNotify_Service.NotifyResponse response = 
            GovUKNotify_Service.sendEmail(VALID_EMAIL, VALID_TEMPLATE_ID);
        Test.stopTest();
        
        Assert.isTrue(response.success, '200 should be successful');
    }
    
    @IsTest
    static void testSendEmail_StatusCode299() {
        Test.setMock(HttpCalloutMock.class, new MockHttp299Response());
        
        Test.startTest();
        GovUKNotify_Service.NotifyResponse response = 
            GovUKNotify_Service.sendEmail(VALID_EMAIL, VALID_TEMPLATE_ID);
        Test.stopTest();
        
        Assert.isTrue(response.success, '299 should be successful');
    }
    
    // Helper mock classes for boundary tests
    private class MockHttp200Response implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"id": "test-id"}');
            return res;
        }
    }
    
    private class MockHttp299Response implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(299);
            res.setBody('{"id": "test-id"}');
            return res;
        }
    }
}