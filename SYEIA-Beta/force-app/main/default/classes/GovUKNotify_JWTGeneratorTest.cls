/**
 * Test class for GovUKNotify_JWTGenerator
 */
@IsTest
private class GovUKNotify_JWTGeneratorTest {
    
    // ========================================================================
    // TEST CONSTANTS
    // ========================================================================
    
    private static final String TEST_ISSUER = 'test-issuer-uuid-12345';
    private static final String TEST_SECRET_KEY = 'test-secret-key-abcdef';
    
    // ========================================================================
    // GENERATE TOKEN TESTS
    // ========================================================================
    
    @IsTest
    static void testGenerateToken_ValidInputs() {
        Test.startTest();
        String token = GovUKNotify_JWTGenerator.generateToken(TEST_ISSUER, TEST_SECRET_KEY);
        Test.stopTest();
        
        Assert.isNotNull(token, 'Token should not be null');
        Assert.isTrue(token.length() > 0, 'Token should not be empty');
        
        // JWT should have three parts separated by dots
        List<String> parts = token.split('\\.');
        Assert.areEqual(3, parts.size(), 'JWT should have 3 parts (header.payload.signature)');
        
        // All parts should be non-empty
        Assert.isTrue(String.isNotBlank(parts[0]), 'Header should not be blank');
        Assert.isTrue(String.isNotBlank(parts[1]), 'Payload should not be blank');
        Assert.isTrue(String.isNotBlank(parts[2]), 'Signature should not be blank');
    }
    
    @IsTest
    static void testGenerateToken_HeaderContainsCorrectAlgorithm() {
        Test.startTest();
        String token = GovUKNotify_JWTGenerator.generateToken(TEST_ISSUER, TEST_SECRET_KEY);
        Test.stopTest();
        
        List<String> parts = token.split('\\.');
        String headerEncoded = parts[0];
        
        // Decode header (reverse Base64URL encoding)
        String headerPadded = headerEncoded.replace('-', '+').replace('_', '/');
        // Add padding if needed
        Integer padding = Math.mod(4 - Math.mod(headerPadded.length(), 4), 4);
        for (Integer i = 0; i < padding; i++) {
            headerPadded += '=';
        }
        
        String headerJson = EncodingUtil.base64Decode(headerPadded).toString();
        Map<String, Object> header = (Map<String, Object>) JSON.deserializeUntyped(headerJson);
        
        Assert.areEqual('HS256', header.get('alg'), 'Algorithm should be HS256');
        Assert.areEqual('JWT', header.get('typ'), 'Type should be JWT');
    }
    
    @IsTest
    static void testGenerateToken_PayloadContainsIssuer() {
        Test.startTest();
        String token = GovUKNotify_JWTGenerator.generateToken(TEST_ISSUER, TEST_SECRET_KEY);
        Test.stopTest();
        
        List<String> parts = token.split('\\.');
        String payloadEncoded = parts[1];
        
        // Decode payload
        String payloadPadded = payloadEncoded.replace('-', '+').replace('_', '/');
        Integer padding = Math.mod(4 - Math.mod(payloadPadded.length(), 4), 4);
        for (Integer i = 0; i < padding; i++) {
            payloadPadded += '=';
        }
        
        String payloadJson = EncodingUtil.base64Decode(payloadPadded).toString();
        Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(payloadJson);
        
        Assert.areEqual(TEST_ISSUER, payload.get('iss'), 'Issuer should match input');
        Assert.isTrue(payload.containsKey('iat'), 'Payload should contain issued-at time');
    }
    
    @IsTest
    static void testGenerateToken_PayloadContainsIssuedAtTime() {
        Long beforeTime = DateTime.now().getTime() / 1000;
        
        Test.startTest();
        String token = GovUKNotify_JWTGenerator.generateToken(TEST_ISSUER, TEST_SECRET_KEY);
        Test.stopTest();
        
        Long afterTime = DateTime.now().getTime() / 1000;
        
        List<String> parts = token.split('\\.');
        String payloadEncoded = parts[1];
        
        // Decode payload
        String payloadPadded = payloadEncoded.replace('-', '+').replace('_', '/');
        Integer padding = Math.mod(4 - Math.mod(payloadPadded.length(), 4), 4);
        for (Integer i = 0; i < padding; i++) {
            payloadPadded += '=';
        }
        
        String payloadJson = EncodingUtil.base64Decode(payloadPadded).toString();
        Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(payloadJson);
        
        Long iat = (Long) payload.get('iat');
        Assert.isTrue(iat >= beforeTime, 'Issued-at should be >= time before generation');
        Assert.isTrue(iat <= afterTime, 'Issued-at should be <= time after generation');
    }
    
    @IsTest
    static void testGenerateToken_DifferentSecretsDifferentSignatures() {
        Test.startTest();
        String token1 = GovUKNotify_JWTGenerator.generateToken(TEST_ISSUER, 'secret-one');
        String token2 = GovUKNotify_JWTGenerator.generateToken(TEST_ISSUER, 'secret-two');
        Test.stopTest();
        
        List<String> parts1 = token1.split('\\.');
        List<String> parts2 = token2.split('\\.');
        
        // Signatures should be different with different secrets
        Assert.areNotEqual(parts1[2], parts2[2], 
            'Different secrets should produce different signatures');
    }
    
    @IsTest
    static void testGenerateToken_ConsistentWithSameInputs() {
        // Note: Tokens will differ due to iat timestamp, but structure should be consistent
        Test.startTest();
        String token1 = GovUKNotify_JWTGenerator.generateToken(TEST_ISSUER, TEST_SECRET_KEY);
        String token2 = GovUKNotify_JWTGenerator.generateToken(TEST_ISSUER, TEST_SECRET_KEY);
        Test.stopTest();
        
        List<String> parts1 = token1.split('\\.');
        List<String> parts2 = token2.split('\\.');
        
        // Headers should be identical (same algorithm and type)
        Assert.areEqual(parts1[0], parts2[0], 'Headers should be identical');
    }
    
    // ========================================================================
    // VALIDATION TESTS
    // ========================================================================
    
    @IsTest
    static void testGenerateToken_BlankIssuer() {
        Test.startTest();
        Boolean exceptionThrown = false;
        String exceptionMessage = '';
        
        try {
            GovUKNotify_JWTGenerator.generateToken('', TEST_SECRET_KEY);
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
            exceptionMessage = e.getMessage();
        }
        Test.stopTest();
        
        Assert.isTrue(exceptionThrown, 'Should throw exception for blank issuer');
        Assert.isTrue(exceptionMessage.contains('Issuer cannot be blank'), 
            'Exception should mention issuer');
    }
    
    @IsTest
    static void testGenerateToken_NullIssuer() {
        Test.startTest();
        Boolean exceptionThrown = false;
        String exceptionMessage = '';
        
        try {
            GovUKNotify_JWTGenerator.generateToken(null, TEST_SECRET_KEY);
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
            exceptionMessage = e.getMessage();
        }
        Test.stopTest();
        
        Assert.isTrue(exceptionThrown, 'Should throw exception for null issuer');
        Assert.isTrue(exceptionMessage.contains('Issuer cannot be blank'), 
            'Exception should mention issuer');
    }
    
    @IsTest
    static void testGenerateToken_BlankSecretKey() {
        Test.startTest();
        Boolean exceptionThrown = false;
        String exceptionMessage = '';
        
        try {
            GovUKNotify_JWTGenerator.generateToken(TEST_ISSUER, '');
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
            exceptionMessage = e.getMessage();
        }
        Test.stopTest();
        
        Assert.isTrue(exceptionThrown, 'Should throw exception for blank secret key');
        Assert.isTrue(exceptionMessage.contains('Secret key cannot be blank'), 
            'Exception should mention secret key');
    }
    
    @IsTest
    static void testGenerateToken_NullSecretKey() {
        Test.startTest();
        Boolean exceptionThrown = false;
        String exceptionMessage = '';
        
        try {
            GovUKNotify_JWTGenerator.generateToken(TEST_ISSUER, null);
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
            exceptionMessage = e.getMessage();
        }
        Test.stopTest();
        
        Assert.isTrue(exceptionThrown, 'Should throw exception for null secret key');
        Assert.isTrue(exceptionMessage.contains('Secret key cannot be blank'), 
            'Exception should mention secret key');
    }
    
    @IsTest
    static void testGenerateToken_WhitespaceIssuer() {
        Test.startTest();
        Boolean exceptionThrown = false;
        
        try {
            GovUKNotify_JWTGenerator.generateToken('   ', TEST_SECRET_KEY);
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        
        Assert.isTrue(exceptionThrown, 'Should throw exception for whitespace-only issuer');
    }
    
    @IsTest
    static void testGenerateToken_WhitespaceSecretKey() {
        Test.startTest();
        Boolean exceptionThrown = false;
        
        try {
            GovUKNotify_JWTGenerator.generateToken(TEST_ISSUER, '   ');
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        
        Assert.isTrue(exceptionThrown, 'Should throw exception for whitespace-only secret key');
    }
    
    // ========================================================================
    // BASE64URL ENCODING TESTS
    // ========================================================================
    
    @IsTest
    static void testBase64UrlEncode_BasicString() {
        Test.startTest();
        String encoded = GovUKNotify_JWTGenerator.base64UrlEncode('Hello World');
        Test.stopTest();
        
        Assert.isNotNull(encoded, 'Encoded string should not be null');
        Assert.isFalse(encoded.contains('+'), 'Should not contain +');
        Assert.isFalse(encoded.contains('/'), 'Should not contain /');
        Assert.isFalse(encoded.contains('='), 'Should not contain padding');
    }
    
    @IsTest
    static void testBase64UrlEncode_SpecialCharacters() {
        // Test string that would produce +, /, or = in standard Base64
        String testInput = '{"alg":"HS256","typ":"JWT"}';
        
        Test.startTest();
        String encoded = GovUKNotify_JWTGenerator.base64UrlEncode(testInput);
        Test.stopTest();
        
        Assert.isFalse(encoded.contains('+'), 'Should not contain +');
        Assert.isFalse(encoded.contains('/'), 'Should not contain /');
        Assert.isFalse(encoded.contains('='), 'Should not contain padding');
    }
    
    @IsTest
    static void testBase64UrlEncode_EmptyString() {
        Test.startTest();
        String encoded = GovUKNotify_JWTGenerator.base64UrlEncode('');
        Test.stopTest();
        
        Assert.isNotNull(encoded, 'Should return non-null for empty string');
        Assert.areEqual('', encoded, 'Empty string should encode to empty');
    }
    
    @IsTest
    static void testBase64UrlEncode_LongString() {
        String longInput = 'A'.repeat(1000);
        
        Test.startTest();
        String encoded = GovUKNotify_JWTGenerator.base64UrlEncode(longInput);
        Test.stopTest();
        
        Assert.isNotNull(encoded, 'Should handle long strings');
        Assert.isFalse(encoded.contains('+'), 'Should not contain +');
        Assert.isFalse(encoded.contains('/'), 'Should not contain /');
        Assert.isFalse(encoded.contains('='), 'Should not contain padding');
    }
    
    // ========================================================================
    // TOKEN FORMAT TESTS
    // ========================================================================
    
    @IsTest
    static void testGenerateToken_NoUrlUnsafeCharacters() {
        Test.startTest();
        String token = GovUKNotify_JWTGenerator.generateToken(TEST_ISSUER, TEST_SECRET_KEY);
        Test.stopTest();
        
        // Check that token doesn't contain URL-unsafe characters (except dots)
        String tokenWithoutDots = token.replace('.', '');
        Assert.isFalse(tokenWithoutDots.contains('+'), 'Token should not contain +');
        Assert.isFalse(tokenWithoutDots.contains('/'), 'Token should not contain /');
        Assert.isFalse(tokenWithoutDots.contains('='), 'Token should not contain =');
    }
    
    @IsTest
    static void testGenerateToken_LongIssuer() {
        String longIssuer = 'issuer-' + 'x'.repeat(500);
        
        Test.startTest();
        String token = GovUKNotify_JWTGenerator.generateToken(longIssuer, TEST_SECRET_KEY);
        Test.stopTest();
        
        Assert.isNotNull(token, 'Should handle long issuer');
        List<String> parts = token.split('\\.');
        Assert.areEqual(3, parts.size(), 'Should still produce valid JWT structure');
    }
    
    @IsTest
    static void testGenerateToken_SpecialCharactersInIssuer() {
        String specialIssuer = 'issuer-with-special_chars.and@symbols';
        
        Test.startTest();
        String token = GovUKNotify_JWTGenerator.generateToken(specialIssuer, TEST_SECRET_KEY);
        Test.stopTest();
        
        Assert.isNotNull(token, 'Should handle special characters in issuer');
        
        // Verify the issuer is correctly encoded in payload
        List<String> parts = token.split('\\.');
        String payloadEncoded = parts[1];
        String payloadPadded = payloadEncoded.replace('-', '+').replace('_', '/');
        Integer padding = Math.mod(4 - Math.mod(payloadPadded.length(), 4), 4);
        for (Integer i = 0; i < padding; i++) {
            payloadPadded += '=';
        }
        
        String payloadJson = EncodingUtil.base64Decode(payloadPadded).toString();
        Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(payloadJson);
        Assert.areEqual(specialIssuer, payload.get('iss'), 'Special characters should be preserved');
    }
    
    @IsTest
    static void testGenerateToken_UnicodeInIssuer() {
        String unicodeIssuer = 'issuer-éàü-日本語';
        
        Test.startTest();
        String token = GovUKNotify_JWTGenerator.generateToken(unicodeIssuer, TEST_SECRET_KEY);
        Test.stopTest();
        
        Assert.isNotNull(token, 'Should handle unicode in issuer');
        List<String> parts = token.split('\\.');
        Assert.areEqual(3, parts.size(), 'Should produce valid JWT structure');
    }
}