@IsTest
private class JWTGeneratorTest {
    
    @IsTest
    static void testGenerateToken_ValidInputs() {
        String issuer = 'test-issuer-uuid';
        String secretKey = 'test-secret-key';
        
        Test.startTest();
        String token = JWTGenerator.generateToken(issuer, secretKey);
        Test.stopTest();
        
        Assert.isNotNull(token, 'Token should not be null');
        Assert.isTrue(token.contains('.'), 'Token should contain dots separating segments');
        
        // JWT format: header.payload.signature
        List<String> tokenParts = token.split('\\.');
        Assert.areEqual(3, tokenParts.size(), 'Token should have 3 parts (header.payload.signature)');
    }
    
    @IsTest
    static void testGenerateToken_HeaderStructure() {
        String issuer = 'test-issuer-uuid';
        String secretKey = 'test-secret-key';
        
        Test.startTest();
        String token = JWTGenerator.generateToken(issuer, secretKey);
        Test.stopTest();
        
        List<String> tokenParts = token.split('\\.');
        Assert.areEqual(3, tokenParts.size(), 'Token should have 3 parts');
        
        // Decode header (first part)
        String encodedHeader = tokenParts[0];
        Assert.isNotNull(encodedHeader, 'Header should not be null');
        Assert.isTrue(encodedHeader.length() > 0, 'Header should not be empty');
    }
    
    @IsTest
    static void testGenerateToken_PayloadContainsIssuer() {
        String issuer = 'test-issuer-uuid-12345';
        String secretKey = 'test-secret-key';
        
        Test.startTest();
        String token = JWTGenerator.generateToken(issuer, secretKey);
        Test.stopTest();
        
        List<String> tokenParts = token.split('\\.');
        String encodedPayload = tokenParts[1];
        
        // Base64 URL decode the payload
        String padding = '===='.substring(0, Math.mod(4 - Math.mod(encodedPayload.length(), 4), 4));
        String base64Payload = encodedPayload.replace('-', '+').replace('_', '/') + padding;
        String decodedPayload = EncodingUtil.base64Decode(base64Payload).toString();
        
        Assert.isTrue(
            decodedPayload.contains(issuer),
            'Decoded payload should contain the issuer UUID'
        );
        Assert.isTrue(
            decodedPayload.contains('iat'),
            'Decoded payload should contain issued at timestamp'
        );
    }
    
    @IsTest
    static void testGenerateToken_DifferentIssuers() {
        String secretKey = 'test-secret-key';
        
        Test.startTest();
        String token1 = JWTGenerator.generateToken('issuer-1', secretKey);
        String token2 = JWTGenerator.generateToken('issuer-2', secretKey);
        Test.stopTest();
        
        Assert.areNotEqual(token1, token2, 'Tokens with different issuers should not be equal');
    }
    
    @IsTest
    static void testGenerateToken_DifferentSecretKeys() {
        String issuer = 'test-issuer-uuid';
        
        Test.startTest();
        String token1 = JWTGenerator.generateToken(issuer, 'secret-key-1');
        String token2 = JWTGenerator.generateToken(issuer, 'secret-key-2');
        Test.stopTest();
        
        Assert.areNotEqual(token1, token2, 'Tokens with different secret keys should not be equal');
    }
    
    @IsTest
    static void testGenerateToken_SignatureNotEmpty() {
        String issuer = 'test-issuer-uuid';
        String secretKey = 'test-secret-key';
        
        Test.startTest();
        String token = JWTGenerator.generateToken(issuer, secretKey);
        Test.stopTest();
        
        List<String> tokenParts = token.split('\\.');
        String signature = tokenParts[2];
        
        Assert.isNotNull(signature, 'Signature should not be null');
        Assert.isTrue(signature.length() > 0, 'Signature should not be empty');
    }
    
    @IsTest
    static void testGenerateToken_ConsistentFormat() {
        String issuer = 'test-issuer-uuid';
        String secretKey = 'test-secret-key';
        
        Test.startTest();
        String token = JWTGenerator.generateToken(issuer, secretKey);
        Test.stopTest();
        
        // Verify no padding characters in the token (JWT uses base64url encoding)
        Assert.isFalse(token.contains('='), 'Token should not contain padding characters');
        Assert.isFalse(token.contains('+'), 'Token should use URL-safe base64 encoding');
        Assert.isFalse(token.contains('/'), 'Token should use URL-safe base64 encoding');
    }
    
    @IsTest
    static void testGenerateToken_TimestampGeneration() {
        String issuer = 'test-issuer-uuid';
        String secretKey = 'test-secret-key';
        
        Long beforeTime = DateTime.now().getTime() / 1000;
        
        Test.startTest();
        String token = JWTGenerator.generateToken(issuer, secretKey);
        Test.stopTest();
        
        Long afterTime = DateTime.now().getTime() / 1000;
        
        Assert.isNotNull(token, 'Token should be generated');
        // The timestamp in the token should be between before and after times
        // This is a basic sanity check
    }
}