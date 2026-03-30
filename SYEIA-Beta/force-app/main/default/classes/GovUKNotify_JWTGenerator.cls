/**
 * Generates JSON Web Tokens (JWT) using HS256 (HMAC-SHA256) algorithm for GOV.UK Notify API authentication.
 */

public class GovUKNotify_JWTGenerator {
    
    private static final String ALGORITHM = 'HS256';
    private static final String TOKEN_TYPE = 'JWT';
    private static final String HMAC_ALGORITHM = 'HMACSHA256';
    
    /**
     * Generates a signed JWT token for GOV.UK Notify API authentication
     */
    public static String generateToken(String issuer, String secretKey) {
        validateInputs(issuer, secretKey);
        
        String encodedHeader = base64UrlEncode(buildHeader());
        String encodedPayload = base64UrlEncode(buildPayload(issuer));
        String signingInput = encodedHeader + '.' + encodedPayload;
        String signature = sign(signingInput, secretKey);

        System.debug(LoggingLevel.FINE, 'JWT generated for issuer: ' + issuer.left(8) + '...');

        return signingInput + '.' + signature;
    }
    
    private static void validateInputs(String issuer, String secretKey) {
        if (String.isBlank(issuer)) {
            throw new IllegalArgumentException('Issuer cannot be blank');
        }
        if (String.isBlank(secretKey)) {
            throw new IllegalArgumentException('Secret key cannot be blank');
        }
    }
    
    private static String buildHeader() {
        Map<String, String> header = new Map<String, String>{
            'alg' => ALGORITHM,
            'typ' => TOKEN_TYPE
        };
        return JSON.serialize(header);
    }
    
    private static String buildPayload(String issuer) {
        Long currentTimeSeconds = DateTime.now().getTime() / 1000;
        Map<String, Object> payload = new Map<String, Object>{
            'iss' => issuer,
            'iat' => currentTimeSeconds
        };
        return JSON.serialize(payload);
    }

    @TestVisible
    private static String base64UrlEncode(String input) {
        return EncodingUtil.base64Encode(Blob.valueOf(input))
            .replace('+', '-')
            .replace('/', '_')
            .replace('=', '');
    }

    private static String sign(String data, String secretKey) {
        Blob signatureBlob = Crypto.generateMac(
            HMAC_ALGORITHM, 
            Blob.valueOf(data), 
            Blob.valueOf(secretKey)
        );
        return EncodingUtil.base64Encode(signatureBlob)
            .replace('+', '-')
            .replace('/', '_')
            .replace('=', '');
    }
}