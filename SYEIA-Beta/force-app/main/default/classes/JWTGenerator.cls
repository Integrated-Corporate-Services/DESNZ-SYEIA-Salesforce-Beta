public class JWTGenerator {

    public static String generateToken(String issuer, String secretKey) {
        // Create JWT header
        Map<String, String> header = new Map<String, String>{
            'alg' => 'HS256',
            'typ' => 'JWT'
        };

        // Create JWT payload with current timestamp
        Long currentTime = DateTime.now().getTime() / 1000;
        Map<String, Object> payload = new Map<String, Object>{
            'iss' => issuer,
            'iat' => currentTime
        };

        // Encode header and payload
        String encodedHeader = base64UrlEncode(JSON.serialize(header));
        String encodedPayload = base64UrlEncode(JSON.serialize(payload));

        // Create signing input
        String signingInput = encodedHeader + '.' + encodedPayload;

        // Sign the token with HMAC SHA256
        String signature = signWithHMACSHA256(signingInput, secretKey);

        System.debug(LoggingLevel.INFO, 'Generated JWT: ' + signingInput + '.' + signature);

        // Return the complete JWT
        return signingInput + '.' + signature;
    }

    private static String base64UrlEncode(String input) {
        String base64 = EncodingUtil.base64Encode(Blob.valueOf(input));
        return base64.replace('+', '-').replace('/', '_').replace('=', '');
    }

    private static String signWithHMACSHA256(String data, String secretKey) {
        Blob dataBlob = Blob.valueOf(data);
        Blob keyBlob = Blob.valueOf(secretKey);

        // Generate HMAC SHA256 signature
        Blob signatureBlob = Crypto.generateMac('HMACSHA256', dataBlob, keyBlob);

        // Convert to Base64 URL-safe string
        String signature = EncodingUtil.base64Encode(signatureBlob);
        signature = signature.replace('+', '-').replace('/', '_').replace('=', '');

        return signature;
    }

}