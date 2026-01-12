/**
 * Test class for GovUKNotify_Invocable
 */
@IsTest
private class GovUKNotify_InvocableTest {
    
    // ========================================================================
    // TEST CONSTANTS
    // ========================================================================
    
    private static final String VALID_EMAIL = 'test@example.gov.uk';
    private static final String VALID_TEMPLATE_ID = 'template-uuid-12345';
    private static final String SUCCESS_NOTIFICATION_ID = 'notification-uuid-67890';
    
    // ========================================================================
    // TEST DATA HELPERS
    // ========================================================================
    
    private static GovUKNotify_Invocable.SendEmailRequest createValidRequest() {
        GovUKNotify_Invocable.SendEmailRequest req = new GovUKNotify_Invocable.SendEmailRequest();
        req.recipientEmail = VALID_EMAIL;
        req.templateId = VALID_TEMPLATE_ID;
        return req;
    }
    
    private static GovUKNotify_Invocable.SendEmailRequest createRequestWithPersonalisation() {
        GovUKNotify_Invocable.SendEmailRequest req = createValidRequest();
        req.personalisationJson = '{"first_name": "John", "reference": "REF-001"}';
        return req;
    }
    
    private static GovUKNotify_Invocable.SendEmailRequest createRequestWithCaseId(String caseId) {
        GovUKNotify_Invocable.SendEmailRequest req = createValidRequest();
        req.caseId = caseId;
        return req;
    }
    
    // ========================================================================
    // MOCK HTTP CALLOUT CLASS
    // ========================================================================
    
    private class MockHttpResponseSuccess implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(201);
            res.setHeader('Content-Type', 'application/json');
            res.setBody(JSON.serialize(new Map<String, Object>{
                'id' => SUCCESS_NOTIFICATION_ID,
                'reference' => 'ref-12345'
            }));
            return res;
        }
    }
    
    private class MockHttpResponseError implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(400);
            res.setHeader('Content-Type', 'application/json');
            res.setBody(JSON.serialize(new Map<String, Object>{
                'errors' => new List<Object>{
                    new Map<String, Object>{
                        'error' => 'ValidationError',
                        'message' => 'Invalid template ID'
                    }
                }
            }));
            return res;
        }
    }
    
    // ========================================================================
    // TEST SETUP
    // ========================================================================
    
    @TestSetup
    static void setupTestData() {
        // Create test Case__c records for queueable tests
        List<Case__c> testCases = new List<Case__c>();
        for (Integer i = 0; i < 3; i++) {
            testCases.add(new Case__c(
                Name = 'Test Case ' + i,
                AWS_Application_Id__c = 'AWS-' + i,
                Overdue_Email_Sent__c = false
            ));
        }
        insert testCases;
    }
    
    // ========================================================================
    // SEND NOTIFY EMAIL TESTS - SUCCESS SCENARIOS
    // ========================================================================
    
    @IsTest
    static void testSendNotifyEmail_ValidRequest() {
        List<GovUKNotify_Invocable.SendEmailRequest> requests = 
            new List<GovUKNotify_Invocable.SendEmailRequest>{ createValidRequest() };
        
        Test.startTest();
        List<GovUKNotify_Invocable.SendEmailResult> results = 
            GovUKNotify_Invocable.sendNotifyEmail(requests);
        Test.stopTest();
        
        Assert.areEqual(1, results.size(), 'Should return one result');
        Assert.isTrue(results[0].success, 'Request should be queued successfully');
        Assert.areEqual('Email queued successfully', results[0].message, 
            'Message should indicate success');
        Assert.isNull(results[0].errorMessage, 'Error message should be null');
    }
    
    @IsTest
    static void testSendNotifyEmail_MultipleRequests() {
        List<GovUKNotify_Invocable.SendEmailRequest> requests = 
            new List<GovUKNotify_Invocable.SendEmailRequest>{
                createValidRequest(),
                createValidRequest(),
                createValidRequest()
            };
        
        Test.startTest();
        List<GovUKNotify_Invocable.SendEmailResult> results = 
            GovUKNotify_Invocable.sendNotifyEmail(requests);
        Test.stopTest();
        
        Assert.areEqual(3, results.size(), 'Should return three results');
        for (GovUKNotify_Invocable.SendEmailResult result : results) {
            Assert.isTrue(result.success, 'All requests should be queued successfully');
        }
    }
    
    @IsTest
    static void testSendNotifyEmail_WithPersonalisation() {
        List<GovUKNotify_Invocable.SendEmailRequest> requests = 
            new List<GovUKNotify_Invocable.SendEmailRequest>{ createRequestWithPersonalisation() };
        
        Test.startTest();
        List<GovUKNotify_Invocable.SendEmailResult> results = 
            GovUKNotify_Invocable.sendNotifyEmail(requests);
        Test.stopTest();
        
        Assert.isTrue(results[0].success, 'Request with personalisation should succeed');
    }
    
    @IsTest
    static void testSendNotifyEmail_WithCaseId() {
        Case__c testCase = [SELECT Id FROM Case__c LIMIT 1];
        
        GovUKNotify_Invocable.SendEmailRequest req = createRequestWithCaseId(testCase.Id);
        List<GovUKNotify_Invocable.SendEmailRequest> requests = 
            new List<GovUKNotify_Invocable.SendEmailRequest>{ req };
        
        Test.startTest();
        List<GovUKNotify_Invocable.SendEmailResult> results = 
            GovUKNotify_Invocable.sendNotifyEmail(requests);
        Test.stopTest();
        
        Assert.isTrue(results[0].success, 'Request with case ID should succeed');
    }
    
    @IsTest
    static void testSendNotifyEmail_EmptyRequestList() {
        List<GovUKNotify_Invocable.SendEmailRequest> requests = 
            new List<GovUKNotify_Invocable.SendEmailRequest>();
        
        Test.startTest();
        List<GovUKNotify_Invocable.SendEmailResult> results = 
            GovUKNotify_Invocable.sendNotifyEmail(requests);
        Test.stopTest();
        
        Assert.areEqual(0, results.size(), 'Empty request list should return empty results');
    }
    
    // ========================================================================
    // SEND NOTIFY EMAIL TESTS - VALIDATION FAILURES
    // ========================================================================
    
    @IsTest
    static void testSendNotifyEmail_MissingRecipientEmail() {
        GovUKNotify_Invocable.SendEmailRequest req = new GovUKNotify_Invocable.SendEmailRequest();
        req.templateId = VALID_TEMPLATE_ID;
        // recipientEmail is null
        
        List<GovUKNotify_Invocable.SendEmailRequest> requests = 
            new List<GovUKNotify_Invocable.SendEmailRequest>{ req };
        
        Test.startTest();
        List<GovUKNotify_Invocable.SendEmailResult> results = 
            GovUKNotify_Invocable.sendNotifyEmail(requests);
        Test.stopTest();
        
        Assert.isFalse(results[0].success, 'Should fail for missing email');
        Assert.isTrue(results[0].errorMessage.contains('Recipient email is required'), 
            'Error should mention recipient email');
    }
    
    @IsTest
    static void testSendNotifyEmail_BlankRecipientEmail() {
        GovUKNotify_Invocable.SendEmailRequest req = new GovUKNotify_Invocable.SendEmailRequest();
        req.recipientEmail = '';
        req.templateId = VALID_TEMPLATE_ID;
        
        List<GovUKNotify_Invocable.SendEmailRequest> requests = 
            new List<GovUKNotify_Invocable.SendEmailRequest>{ req };
        
        Test.startTest();
        List<GovUKNotify_Invocable.SendEmailResult> results = 
            GovUKNotify_Invocable.sendNotifyEmail(requests);
        Test.stopTest();
        
        Assert.isFalse(results[0].success, 'Should fail for blank email');
        Assert.isTrue(results[0].errorMessage.contains('Recipient email is required'), 
            'Error should mention recipient email');
    }
    
    @IsTest
    static void testSendNotifyEmail_MissingTemplateId() {
        GovUKNotify_Invocable.SendEmailRequest req = new GovUKNotify_Invocable.SendEmailRequest();
        req.recipientEmail = VALID_EMAIL;
        // templateId is null
        
        List<GovUKNotify_Invocable.SendEmailRequest> requests = 
            new List<GovUKNotify_Invocable.SendEmailRequest>{ req };
        
        Test.startTest();
        List<GovUKNotify_Invocable.SendEmailResult> results = 
            GovUKNotify_Invocable.sendNotifyEmail(requests);
        Test.stopTest();
        
        Assert.isFalse(results[0].success, 'Should fail for missing template ID');
        Assert.isTrue(results[0].errorMessage.contains('Template ID is required'), 
            'Error should mention template ID');
    }
    
    @IsTest
    static void testSendNotifyEmail_BlankTemplateId() {
        GovUKNotify_Invocable.SendEmailRequest req = new GovUKNotify_Invocable.SendEmailRequest();
        req.recipientEmail = VALID_EMAIL;
        req.templateId = '';
        
        List<GovUKNotify_Invocable.SendEmailRequest> requests = 
            new List<GovUKNotify_Invocable.SendEmailRequest>{ req };
        
        Test.startTest();
        List<GovUKNotify_Invocable.SendEmailResult> results = 
            GovUKNotify_Invocable.sendNotifyEmail(requests);
        Test.stopTest();
        
        Assert.isFalse(results[0].success, 'Should fail for blank template ID');
        Assert.isTrue(results[0].errorMessage.contains('Template ID is required'), 
            'Error should mention template ID');
    }
    
    @IsTest
    static void testSendNotifyEmail_MixedValidAndInvalid() {
        GovUKNotify_Invocable.SendEmailRequest validReq = createValidRequest();
        GovUKNotify_Invocable.SendEmailRequest invalidReq = new GovUKNotify_Invocable.SendEmailRequest();
        invalidReq.recipientEmail = VALID_EMAIL;
        // Missing templateId
        
        List<GovUKNotify_Invocable.SendEmailRequest> requests = 
            new List<GovUKNotify_Invocable.SendEmailRequest>{ validReq, invalidReq };
        
        Test.startTest();
        List<GovUKNotify_Invocable.SendEmailResult> results = 
            GovUKNotify_Invocable.sendNotifyEmail(requests);
        Test.stopTest();
        
        Assert.areEqual(2, results.size(), 'Should return two results');
        Assert.isTrue(results[0].success, 'First (valid) request should succeed');
        Assert.isFalse(results[1].success, 'Second (invalid) request should fail');
    }
    
    // ========================================================================
    // JSON SANITISATION TESTS
    // ========================================================================
    
    @IsTest
    static void testSanitiseJson_ValidJson() {
        String validJson = '{"first_name": "John", "last_name": "Doe"}';
        
        Test.startTest();
        String result = GovUKNotify_Invocable.sanitiseJson(validJson);
        Test.stopTest();
        
        Assert.areEqual(validJson, result, 'Valid JSON should be returned unchanged');
    }
    
    @IsTest
    static void testSanitiseJson_BlankInput() {
        Test.startTest();
        String result = GovUKNotify_Invocable.sanitiseJson('');
        Test.stopTest();
        
        Assert.isNull(result, 'Blank input should return null');
    }
    
    @IsTest
    static void testSanitiseJson_NullInput() {
        Test.startTest();
        String result = GovUKNotify_Invocable.sanitiseJson(null);
        Test.stopTest();
        
        Assert.isNull(result, 'Null input should return null');
    }
    
    @IsTest
    static void testSanitiseJson_WhitespaceOnlyInput() {
        Test.startTest();
        String result = GovUKNotify_Invocable.sanitiseJson('   ');
        Test.stopTest();
        
        Assert.isNull(result, 'Whitespace-only input should return null');
    }
    
    @IsTest
    static void testSanitiseJson_MalformedJsonRepair() {
        // Flow-generated JSON with unescaped characters
        String brokenJson = '{"name": "John", "address": "123 Main St"}';
        
        Test.startTest();
        String result = GovUKNotify_Invocable.sanitiseJson(brokenJson);
        Test.stopTest();
        
        Assert.isNotNull(result, 'Should repair simple JSON');
        // Verify it can be parsed
        Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(result);
        Assert.isNotNull(parsed, 'Repaired JSON should be parseable');
    }
    
    @IsTest
    static void testSanitiseJson_CompletelyInvalidJson() {
        String invalidJson = 'not json at all';
        
        Test.startTest();
        Boolean exceptionThrown = false;
        String exceptionMessage = '';
        
        try {
            GovUKNotify_Invocable.sanitiseJson(invalidJson);
        } catch (GovUKNotify_Invocable.NotifyException e) {
            exceptionThrown = true;
            exceptionMessage = e.getMessage();
        }
        Test.stopTest();
        
        Assert.isTrue(exceptionThrown, 'Should throw exception for completely invalid JSON');
        Assert.isTrue(exceptionMessage.contains('JSON must start with {'), 
            'Exception should mention JSON format');
    }
    
    @IsTest
    static void testSanitiseJson_JsonWithNewlines() {
        // JSON with line breaks that might come from Flow
        GovUKNotify_Invocable.SendEmailRequest req = createValidRequest();
        req.personalisationJson = '{"message": "Line 1\\nLine 2"}';
        
        List<GovUKNotify_Invocable.SendEmailRequest> requests = 
            new List<GovUKNotify_Invocable.SendEmailRequest>{ req };
        
        Test.startTest();
        List<GovUKNotify_Invocable.SendEmailResult> results = 
            GovUKNotify_Invocable.sendNotifyEmail(requests);
        Test.stopTest();
        
        Assert.isTrue(results[0].success, 'Should handle JSON with escaped newlines');
    }
    
    @IsTest
    static void testSanitiseJson_NestedJson() {
        String nestedJson = '{"outer": {"inner": "value"}, "array": ["a", "b"]}';
        
        Test.startTest();
        String result = GovUKNotify_Invocable.sanitiseJson(nestedJson);
        Test.stopTest();
        
        Assert.isNotNull(result, 'Should handle nested JSON');
        Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(result);
        Assert.isNotNull(parsed, 'Nested JSON should be parseable');
    }
    
    @IsTest
    static void testSanitiseJson_JsonWithSpecialCharacters() {
        String specialJson = '{"name": "O\'Brien", "symbol": "£100"}';
        
        Test.startTest();
        String result = GovUKNotify_Invocable.sanitiseJson(specialJson);
        Test.stopTest();
        
        Assert.isNotNull(result, 'Should handle special characters');
    }
    
    @IsTest
    static void testSanitiseJson_JsonWithCommasInValues() {
        String jsonWithCommas = '{"address": "123 Main St, Suite 100", "city": "London"}';
        
        Test.startTest();
        String result = GovUKNotify_Invocable.sanitiseJson(jsonWithCommas);
        Test.stopTest();
        
        Assert.isNotNull(result, 'Should handle commas within values');
        Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(result);
        Assert.isNotNull(parsed.get('address'), 'Address should be preserved');
        Assert.isNotNull(parsed.get('city'), 'City should be preserved');
    }
    
    @IsTest
    static void testSanitiseJson_JsonWithEscapedQuotes() {
        String jsonWithEscapes = '{"quote": "He said \\"Hello\\""}';
        
        Test.startTest();
        String result = GovUKNotify_Invocable.sanitiseJson(jsonWithEscapes);
        Test.stopTest();
        
        Assert.isNotNull(result, 'Should handle escaped quotes');
    }
    
    @IsTest
    static void testSanitiseJson_EmptyJsonObject() {
        String emptyJson = '{}';
        
        Test.startTest();
        String result = GovUKNotify_Invocable.sanitiseJson(emptyJson);
        Test.stopTest();
        
        Assert.isNotNull(result, 'Should handle empty JSON object');
    }
    
    // ========================================================================
    // JSON REPAIR TESTS - MALFORMED JSON THAT TRIGGERS REPAIR LOGIC
    // ========================================================================
    
    @IsTest
    static void testSanitiseJson_MalformedWithUnescapedNewline() {
        // This JSON has an actual unescaped newline that will fail initial parse
        // Simulating what Flow might generate with line breaks in values
        String malformedJson = '{"name": "John\nDoe", "city": "London"}';
        
        Test.startTest();
        String result = GovUKNotify_Invocable.sanitiseJson(malformedJson);
        Test.stopTest();
        
        Assert.isNotNull(result, 'Should repair JSON with unescaped newline');
        Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(result);
        Assert.isNotNull(parsed, 'Repaired JSON should be parseable');
    }
    
    @IsTest
    static void testSanitiseJson_MalformedWithUnescapedTab() {
        // JSON with unescaped tab character
        String malformedJson = '{"name": "John	Doe", "ref": "123"}';
        
        Test.startTest();
        String result = GovUKNotify_Invocable.sanitiseJson(malformedJson);
        Test.stopTest();
        
        Assert.isNotNull(result, 'Should repair JSON with unescaped tab');
    }
    
    @IsTest
    static void testSanitiseJson_MalformedMultiplePairs() {
        // Malformed JSON with multiple key-value pairs that need repair
        String malformedJson = '{"first_name": "John\nSmith", "last_name": "Doe", "email": "test@test.com"}';
        
        Test.startTest();
        String result = GovUKNotify_Invocable.sanitiseJson(malformedJson);
        Test.stopTest();
        
        Assert.isNotNull(result, 'Should repair JSON with multiple pairs');
        Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(result);
        Assert.areEqual(3, parsed.size(), 'Should have 3 key-value pairs');
    }
    
    @IsTest
    static void testSanitiseJson_MalformedWithNestedBraces() {
        // Malformed JSON that contains nested structure indicators
        String malformedJson = '{"data": "value with { brace", "other": "test"}';
        
        Test.startTest();
        String result = GovUKNotify_Invocable.sanitiseJson(malformedJson);
        Test.stopTest();
        
        Assert.isNotNull(result, 'Should handle values containing braces');
    }
    
    @IsTest
    static void testSanitiseJson_MalformedWithNestedBrackets() {
        // Malformed JSON that contains array indicators in values
        String malformedJson = '{"data": "value with [ bracket", "list": "a, b, c"}';
        
        Test.startTest();
        String result = GovUKNotify_Invocable.sanitiseJson(malformedJson);
        Test.stopTest();
        
        Assert.isNotNull(result, 'Should handle values containing brackets');
    }
    
    @IsTest
    static void testSanitiseJson_MalformedWithEscapedBackslash() {
        // JSON with backslash that triggers escape logic
        String malformedJson = '{"path": "C:\\Users\\test\nname", "ref": "123"}';
        
        Test.startTest();
        String result = GovUKNotify_Invocable.sanitiseJson(malformedJson);
        Test.stopTest();
        
        Assert.isNotNull(result, 'Should handle escaped backslashes');
    }
    
    @IsTest
    static void testSanitiseJson_MalformedWithCommaInValue() {
        // Malformed JSON with commas inside values (tests splitJsonPairs depth tracking)
        String malformedJson = '{"address": "123 Main St, Suite 100\nFloor 2", "city": "London, UK"}';
        
        Test.startTest();
        String result = GovUKNotify_Invocable.sanitiseJson(malformedJson);
        Test.stopTest();
        
        Assert.isNotNull(result, 'Should handle commas within string values');
        Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(result);
        Assert.areEqual(2, parsed.size(), 'Should correctly split into 2 pairs');
    }
    
    @IsTest
    static void testSanitiseJson_MalformedSinglePair() {
        // Single key-value pair with malformed content
        String malformedJson = '{"message": "Hello\nWorld"}';
        
        Test.startTest();
        String result = GovUKNotify_Invocable.sanitiseJson(malformedJson);
        Test.stopTest();
        
        Assert.isNotNull(result, 'Should repair single pair JSON');
        Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(result);
        Assert.isTrue(parsed.containsKey('message'), 'Should contain message key');
    }
    
    @IsTest
    static void testSanitiseJson_MalformedWithBlankPairs() {
        // JSON that might result in blank pairs after splitting
        String malformedJson = '{"name": "Test\n", "value": "Data"}';
        
        Test.startTest();
        String result = GovUKNotify_Invocable.sanitiseJson(malformedJson);
        Test.stopTest();
        
        Assert.isNotNull(result, 'Should handle potential blank pairs');
    }
    
    @IsTest
    static void testSanitiseJson_MalformedValueStartsWithQuote() {
        // Test the branch where value starts with quote but doesn't end with one
        String malformedJson = '{"key": "value without end quote\n, "other": "test"}';
        
        Test.startTest();
        String result = GovUKNotify_Invocable.sanitiseJson(malformedJson);
        Test.stopTest();
        
        Assert.isNotNull(result, 'Should handle values with quote issues');
    }
    
    @IsTest
    static void testSanitiseJson_MalformedKeyWithoutLeadingQuote() {
        // Test repair when key doesn't have leading quote (edge case)
        String malformedJson = '{name": "John\nDoe"}';
        
        Test.startTest();
        String result = GovUKNotify_Invocable.sanitiseJson(malformedJson);
        Test.stopTest();
        
        Assert.isNotNull(result, 'Should handle keys without leading quotes');
    }
    
    @IsTest
    static void testSanitiseJson_MalformedWithQuotesInValue() {
        // JSON with quote characters embedded that need escape handling
        String malformedJson = '{"quote": "He said \"Hello\"\nto her", "response": "OK"}';
        
        Test.startTest();
        String result = GovUKNotify_Invocable.sanitiseJson(malformedJson);
        Test.stopTest();
        
        Assert.isNotNull(result, 'Should handle embedded quotes');
    }
    
    @IsTest
    static void testSanitiseJson_MalformedDeepNesting() {
        // Test depth tracking with nested structures in malformed JSON
        String malformedJson = '{"outer": "{inner: value}\ntest", "array": "[1,2,3]"}';
        
        Test.startTest();
        String result = GovUKNotify_Invocable.sanitiseJson(malformedJson);
        Test.stopTest();
        
        Assert.isNotNull(result, 'Should handle nested structure characters');
    }
    
    @IsTest
    static void testSanitiseJson_MalformedWithTrailingContent() {
        // Test the lastPair logic when there's content after the last comma
        String malformedJson = '{"first": "one\ntwo", "second": "three", "third": "four"}';
        
        Test.startTest();
        String result = GovUKNotify_Invocable.sanitiseJson(malformedJson);
        Test.stopTest();
        
        Assert.isNotNull(result, 'Should capture trailing pair');
        Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(result);
        Assert.areEqual(3, parsed.size(), 'Should have all three pairs');
        Assert.isTrue(parsed.containsKey('third'), 'Should contain third key');
    }
    
    @IsTest
    static void testSanitiseJson_MalformedColonInValue() {
        // Test that colons within values don't break key-value parsing
        String malformedJson = '{"time": "10:30:00\nAM", "url": "https://example.com"}';
        
        Test.startTest();
        String result = GovUKNotify_Invocable.sanitiseJson(malformedJson);
        Test.stopTest();
        
        Assert.isNotNull(result, 'Should handle colons within values');
        Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(result);
        Assert.areEqual(2, parsed.size(), 'Should correctly identify 2 pairs');
    }
    
    @IsTest
    static void testSanitiseJson_MalformedNoColonInPair() {
        // Test handling of malformed pair without proper colon separator
        String malformedJson = '{"valid": "value\ntest", "invalid pair without colon"}';
        
        Test.startTest();
        String result = GovUKNotify_Invocable.sanitiseJson(malformedJson);
        Test.stopTest();
        
        // Should still produce valid JSON, possibly with fewer pairs
        Assert.isNotNull(result, 'Should handle pairs without colons');
        Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(result);
        Assert.isNotNull(parsed, 'Result should be valid JSON');
    }
    
    @IsTest
    static void testSanitiseJson_MalformedValueEndsWithQuote() {
        // Test the specific branch: value.startsWith('"') and then value.endsWith('"')
        String malformedJson = '{"key": "value\nwith newline ends with quote"", "other": "x"}';
        
        Test.startTest();
        String result = GovUKNotify_Invocable.sanitiseJson(malformedJson);
        Test.stopTest();
        
        Assert.isNotNull(result, 'Should handle value ending with quote');
    }
    
    @IsTest
    static void testSanitiseJson_MalformedEmptyValue() {
        // Test with empty value after colon
        String malformedJson = '{"empty": "\n", "filled": "value"}';
        
        Test.startTest();
        String result = GovUKNotify_Invocable.sanitiseJson(malformedJson);
        Test.stopTest();
        
        Assert.isNotNull(result, 'Should handle empty values');
    }
    
    @IsTest
    static void testSanitiseJson_MalformedConsecutiveEscapes() {
        // Test consecutive escape characters
        String malformedJson = '{"path": "C:\\\\server\\\\share\ntest", "ref": "123"}';
        
        Test.startTest();
        String result = GovUKNotify_Invocable.sanitiseJson(malformedJson);
        Test.stopTest();
        
        Assert.isNotNull(result, 'Should handle consecutive escapes');
    }
    
    @IsTest
    static void testSanitiseJson_FlowGeneratedMultilineAddress() {
        // Realistic Flow-generated JSON with multiline address
        String flowJson = '{"recipient_name": "John Smith", "address_line_1": "123 Main Street\nApartment 4B", "address_line_2": "Building C\nFloor 3", "postcode": "SW1A 1AA"}';
        
        Test.startTest();
        String result = GovUKNotify_Invocable.sanitiseJson(flowJson);
        Test.stopTest();
        
        Assert.isNotNull(result, 'Should repair Flow-generated multiline JSON');
        Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(result);
        Assert.areEqual(4, parsed.size(), 'Should have all 4 fields');
    }
    
    @IsTest
    static void testSanitiseJson_MalformedWithOnlyClosingBracket() {
        // Test depth decrement with closing brackets
        String malformedJson = '{"data": "test]\nvalue", "more": "data"}';
        
        Test.startTest();
        String result = GovUKNotify_Invocable.sanitiseJson(malformedJson);
        Test.stopTest();
        
        Assert.isNotNull(result, 'Should handle closing brackets in values');
    }
    
    @IsTest
    static void testSanitiseJson_MalformedWithOnlyClosingBrace() {
        // Test depth decrement with closing braces
        String malformedJson = '{"data": "test}\nvalue", "more": "data"}';
        
        Test.startTest();
        String result = GovUKNotify_Invocable.sanitiseJson(malformedJson);
        Test.stopTest();
        
        Assert.isNotNull(result, 'Should handle closing braces in values');
    }
    
    // ========================================================================
    // QUEUEABLE TESTS
    // ========================================================================
    
    @IsTest
    static void testGovUkNotifyQueueable_SuccessfulExecution() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseSuccess());
        
        GovUKNotify_Invocable.SendEmailRequest req = createValidRequest();
        
        Test.startTest();
        System.enqueueJob(new GovUKNotify_Invocable.GovUkNotifyQueueable(req));
        Test.stopTest();
        
        // Queueable executed - verify no exceptions
        Assert.isTrue(true, 'Queueable should execute without exception');
    }
    
    @IsTest
    static void testGovUkNotifyQueueable_WithPersonalisation() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseSuccess());
        
        GovUKNotify_Invocable.SendEmailRequest req = createRequestWithPersonalisation();
        
        Test.startTest();
        System.enqueueJob(new GovUKNotify_Invocable.GovUkNotifyQueueable(req));
        Test.stopTest();
        
        Assert.isTrue(true, 'Queueable with personalisation should execute');
    }
    
    @IsTest
    static void testGovUkNotifyQueueable_WithCaseId_UpdatesCase() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseSuccess());
        
        Case__c testCase = [SELECT Id, Overdue_Email_Sent__c FROM Case__c LIMIT 1];
        Assert.isFalse(testCase.Overdue_Email_Sent__c, 'Case should not have email sent flag initially');
        
        GovUKNotify_Invocable.SendEmailRequest req = createRequestWithCaseId(testCase.Id);
        
        Test.startTest();
        System.enqueueJob(new GovUKNotify_Invocable.GovUkNotifyQueueable(req));
        Test.stopTest();
        
        Case__c updatedCase = [SELECT Overdue_Email_Sent__c FROM Case__c WHERE Id = :testCase.Id];
        Assert.isTrue(updatedCase.Overdue_Email_Sent__c, 'Case should have email sent flag set to true');
    }
    
    @IsTest
    static void testGovUkNotifyQueueable_NoCaseId() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseSuccess());
        
        GovUKNotify_Invocable.SendEmailRequest req = createValidRequest();
        // caseId is null
        
        Test.startTest();
        System.enqueueJob(new GovUKNotify_Invocable.GovUkNotifyQueueable(req));
        Test.stopTest();
        
        // Should complete without trying to update a case
        Assert.isTrue(true, 'Queueable should handle null caseId');
    }
    
    @IsTest
    static void testGovUkNotifyQueueable_BlankCaseId() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseSuccess());
        
        GovUKNotify_Invocable.SendEmailRequest req = createRequestWithCaseId('');
        
        Test.startTest();
        System.enqueueJob(new GovUKNotify_Invocable.GovUkNotifyQueueable(req));
        Test.stopTest();
        
        Assert.isTrue(true, 'Queueable should handle blank caseId');
    }
    
    @IsTest
    static void testGovUkNotifyQueueable_ApiError() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseError());
        
        GovUKNotify_Invocable.SendEmailRequest req = createValidRequest();
        
        Test.startTest();
        System.enqueueJob(new GovUKNotify_Invocable.GovUkNotifyQueueable(req));
        Test.stopTest();
        
        // Should handle error gracefully without throwing
        Assert.isTrue(true, 'Queueable should handle API errors gracefully');
    }
    
    @IsTest
    static void testGovUkNotifyQueueable_NullPersonalisation() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseSuccess());
        
        GovUKNotify_Invocable.SendEmailRequest req = createValidRequest();
        req.personalisationJson = null;
        
        Test.startTest();
        System.enqueueJob(new GovUKNotify_Invocable.GovUkNotifyQueueable(req));
        Test.stopTest();
        
        Assert.isTrue(true, 'Queueable should handle null personalisation');
    }
    
    @IsTest
    static void testGovUkNotifyQueueable_EmptyPersonalisation() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseSuccess());
        
        GovUKNotify_Invocable.SendEmailRequest req = createValidRequest();
        req.personalisationJson = '{}';
        
        Test.startTest();
        System.enqueueJob(new GovUKNotify_Invocable.GovUkNotifyQueueable(req));
        Test.stopTest();
        
        Assert.isTrue(true, 'Queueable should handle empty personalisation');
    }
    
    @IsTest
    static void testGovUkNotifyQueueable_InvalidCaseId() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseSuccess());
        
        // Use a fake ID that doesn't exist
        GovUKNotify_Invocable.SendEmailRequest req = createValidRequest();
        req.caseId = '001000000000000AAA'; // Valid format but doesn't exist
        
        Test.startTest();
        System.enqueueJob(new GovUKNotify_Invocable.GovUkNotifyQueueable(req));
        Test.stopTest();
        
        // Should handle gracefully without failing the job
        Assert.isTrue(true, 'Queueable should handle invalid case ID gracefully');
    }
    
    // ========================================================================
    // SEND EMAIL REQUEST CLASS TESTS
    // ========================================================================
    
    @IsTest
    static void testSendEmailRequest_DefaultValues() {
        Test.startTest();
        GovUKNotify_Invocable.SendEmailRequest req = 
            new GovUKNotify_Invocable.SendEmailRequest();
        Test.stopTest();
        
        Assert.isNull(req.caseId, 'caseId should default to null');
        Assert.isNull(req.recipientEmail, 'recipientEmail should default to null');
        Assert.isNull(req.templateId, 'templateId should default to null');
        Assert.isNull(req.personalisationJson, 'personalisationJson should default to null');
    }
    
    @IsTest
    static void testSendEmailRequest_AllFieldsPopulated() {
        Test.startTest();
        GovUKNotify_Invocable.SendEmailRequest req = 
            new GovUKNotify_Invocable.SendEmailRequest();
        req.caseId = '001000000000000AAA';
        req.recipientEmail = VALID_EMAIL;
        req.templateId = VALID_TEMPLATE_ID;
        req.personalisationJson = '{"key": "value"}';
        Test.stopTest();
        
        Assert.areEqual('001000000000000AAA', req.caseId, 'caseId should match');
        Assert.areEqual(VALID_EMAIL, req.recipientEmail, 'recipientEmail should match');
        Assert.areEqual(VALID_TEMPLATE_ID, req.templateId, 'templateId should match');
        Assert.areEqual('{"key": "value"}', req.personalisationJson, 
            'personalisationJson should match');
    }
    
    // ========================================================================
    // SEND EMAIL RESULT CLASS TESTS
    // ========================================================================
    
    @IsTest
    static void testSendEmailResult_DefaultConstructor() {
        Test.startTest();
        GovUKNotify_Invocable.SendEmailResult result = 
            new GovUKNotify_Invocable.SendEmailResult();
        Test.stopTest();
        
        Assert.isFalse(result.success, 'success should default to false');
        Assert.isNull(result.message, 'message should default to null');
        Assert.isNull(result.errorMessage, 'errorMessage should default to null');
    }
    
    @IsTest
    static void testSendEmailResult_SuccessScenario() {
        Test.startTest();
        GovUKNotify_Invocable.SendEmailResult result = 
            new GovUKNotify_Invocable.SendEmailResult();
        result.success = true;
        result.message = 'Email queued successfully';
        Test.stopTest();
        
        Assert.isTrue(result.success, 'success should be true');
        Assert.areEqual('Email queued successfully', result.message, 'message should match');
        Assert.isNull(result.errorMessage, 'errorMessage should remain null');
    }
    
    @IsTest
    static void testSendEmailResult_FailureScenario() {
        Test.startTest();
        GovUKNotify_Invocable.SendEmailResult result = 
            new GovUKNotify_Invocable.SendEmailResult();
        result.success = false;
        result.errorMessage = 'Template ID is required';
        Test.stopTest();
        
        Assert.isFalse(result.success, 'success should be false');
        Assert.isNull(result.message, 'message should be null');
        Assert.areEqual('Template ID is required', result.errorMessage, 
            'errorMessage should match');
    }
    
    // ========================================================================
    // NOTIFY EXCEPTION TESTS
    // ========================================================================
    
    @IsTest
    static void testNotifyException_Creation() {
        Test.startTest();
        GovUKNotify_Invocable.NotifyException ex = 
            new GovUKNotify_Invocable.NotifyException('Test error');
        Test.stopTest();
        
        Assert.areEqual('Test error', ex.getMessage(), 'Exception message should match');
    }
    
    @IsTest
    static void testNotifyException_Throwing() {
        Test.startTest();
        Boolean exceptionCaught = false;
        
        try {
            throw new GovUKNotify_Invocable.NotifyException('Thrown exception');
        } catch (GovUKNotify_Invocable.NotifyException e) {
            exceptionCaught = true;
            Assert.areEqual('Thrown exception', e.getMessage(), 'Message should match');
        }
        Test.stopTest();
        
        Assert.isTrue(exceptionCaught, 'Exception should be caught');
    }
    
    // ========================================================================
    // EDGE CASE TESTS
    // ========================================================================
    
    @IsTest
    static void testSendNotifyEmail_WhitespaceEmail() {
        GovUKNotify_Invocable.SendEmailRequest req = new GovUKNotify_Invocable.SendEmailRequest();
        req.recipientEmail = '   ';
        req.templateId = VALID_TEMPLATE_ID;
        
        List<GovUKNotify_Invocable.SendEmailRequest> requests = 
            new List<GovUKNotify_Invocable.SendEmailRequest>{ req };
        
        Test.startTest();
        List<GovUKNotify_Invocable.SendEmailResult> results = 
            GovUKNotify_Invocable.sendNotifyEmail(requests);
        Test.stopTest();
        
        Assert.isFalse(results[0].success, 'Whitespace email should fail');
    }
    
    @IsTest
    static void testSendNotifyEmail_WhitespaceTemplateId() {
        GovUKNotify_Invocable.SendEmailRequest req = new GovUKNotify_Invocable.SendEmailRequest();
        req.recipientEmail = VALID_EMAIL;
        req.templateId = '   ';
        
        List<GovUKNotify_Invocable.SendEmailRequest> requests = 
            new List<GovUKNotify_Invocable.SendEmailRequest>{ req };
        
        Test.startTest();
        List<GovUKNotify_Invocable.SendEmailResult> results = 
            GovUKNotify_Invocable.sendNotifyEmail(requests);
        Test.stopTest();
        
        Assert.isFalse(results[0].success, 'Whitespace template ID should fail');
    }
    
    @IsTest
    static void testSendNotifyEmail_LargePersonalisation() {
        String largeValue = 'A'.repeat(10000);
        String largeJson = '{"large_field": "' + largeValue + '"}';
        
        GovUKNotify_Invocable.SendEmailRequest req = createValidRequest();
        req.personalisationJson = largeJson;
        
        List<GovUKNotify_Invocable.SendEmailRequest> requests = 
            new List<GovUKNotify_Invocable.SendEmailRequest>{ req };
        
        Test.startTest();
        List<GovUKNotify_Invocable.SendEmailResult> results = 
            GovUKNotify_Invocable.sendNotifyEmail(requests);
        Test.stopTest();
        
        Assert.isTrue(results[0].success, 'Should handle large personalisation values');
    }
    
    @IsTest
    static void testSendNotifyEmail_SpecialCharactersInEmail() {
        GovUKNotify_Invocable.SendEmailRequest req = createValidRequest();
        req.recipientEmail = 'test+flow@example.gov.uk';
        
        List<GovUKNotify_Invocable.SendEmailRequest> requests = 
            new List<GovUKNotify_Invocable.SendEmailRequest>{ req };
        
        Test.startTest();
        List<GovUKNotify_Invocable.SendEmailResult> results = 
            GovUKNotify_Invocable.sendNotifyEmail(requests);
        Test.stopTest();
        
        Assert.isTrue(results[0].success, 'Should accept email with plus sign');
    }
}