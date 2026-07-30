/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an org are executed whenever Apex code is deployed
 * to a production org to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production org. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the org size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class FileControllerTest {

     private static final String APPLICATION_ID = 'APP-12345';
    private static final String ZIP_BASE64 =
        'UEsDBBQAAAAIAO46clyGphA2BwAAAAUAAAARAAAAZm9sZGVyMS9maWxlMS50eHTLSM3JyQcAUEsDBBQAAAAIAO46clxDEXc6BwAAAAUAAAAJAAAAZmlsZTIudHh0K88vykkBAFBLAQIUAxQAAAAIAO46clyGphA2BwAAAAUAAAARAAAAAAAAAAAAAACAAQAAAABmb2xkZXIxL2ZpbGUxLnR4dFBLAQIUAxQAAAAIAO46clxDEXc6BwAAAAUAAAAJAAAAAAAAAAAAAACAATYAAABmaWxlMi50eHRQSwUGAAAAAAIAAgB2AAAAZAAAAAAA';

    private static Blob getZipBlob() {
        return EncodingUtil.base64Decode(ZIP_BASE64);
    }

    private class FileControllerHttpMock implements HttpCalloutMock {
        private Integer downloadStatusCode;
        private Blob downloadBlob;
        private String downloadBody;
        private Boolean throwDownloadException;

        FileControllerHttpMock(
            Integer downloadStatusCode,
            Blob downloadBlob,
            String downloadBody,
            Boolean throwDownloadException
        ) {
            this.downloadStatusCode = downloadStatusCode;
            this.downloadBlob = downloadBlob;
            this.downloadBody = downloadBody;
            this.throwDownloadException = throwDownloadException;
        }

        public HttpResponse respond(HttpRequest req) {
            String endpoint = req.getEndpoint();

            if (endpoint != null && endpoint.contains('/documents/download')) {
                if (throwDownloadException) {
                    throw new CalloutException('Forced callout failure');
                }

                System.assertEquals('POST', req.getMethod(), 'Expected POST for document download');
                System.assert(endpoint.contains(APPLICATION_ID + '/documents/download'),
                    'Unexpected endpoint: ' + endpoint);
                System.assertEquals('application/json', req.getHeader('Content-Type'));
                System.assertEquals('application/zip', req.getHeader('Accept'));
                System.assertEquals(UserInfo.getUserEmail(), req.getHeader('X-Acting-User-Email'));
                System.assertEquals(UserInfo.getUserId(), req.getHeader('X-Acting-User-Id'));
                System.assertEquals('desnz_caseworker', req.getHeader('X-Acting-User-Role'));
                System.assertNotEquals(null, req.getHeader('X-Correlation-ID'));
                System.assert(
                    req.getHeader('Authorization') != null &&
                    req.getHeader('Authorization').startsWith('Bearer '),
                    'Authorization header must be present'
                );
                System.assertEquals(
                    JSON.serialize(new Map<String, String>{ 'scope' => 'APPLICATION' }),
                    req.getBody()
                );

                HttpResponse res = new HttpResponse();
                res.setStatusCode(downloadStatusCode);

                if (downloadBlob != null) {
                    res.setBodyAsBlob(downloadBlob);
                } else if (downloadBody != null) {
                    res.setBody(downloadBody);
                }

                return res;
            }

            /*
             * Fallback response for OAuthTokenService.getBearerToken()
             * in case that method performs an HTTP callout during the test.
             */
            HttpResponse tokenResponse = new HttpResponse();
            tokenResponse.setStatusCode(200);
            tokenResponse.setBody('{"access_token":"test-bearer-token","token_type":"Bearer","expires_in":3600}');
            return tokenResponse;
        }
    }

    @testSetup
    static void seedSettings() {
        SalesforceSettings__c cs = new SalesforceSettings__c();
        cs.SetupOwnerId = UserInfo.getOrganizationId();
        cs.Endpoint_Url__c = 'https://example.com/oauth/token';
        cs.client_id__c = 'client-id';
        cs.client_secret__c = 'client-secret';
        insert cs;
    }

    @IsTest
    static void testGetZipFiles_Success() {
        Test.setMock(
            HttpCalloutMock.class,
            new FileControllerHttpMock(200, getZipBlob(), null, false)
        );

        Test.startTest();
        String result = FileController.getZipFiles(APPLICATION_ID);
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals(ZIP_BASE64, result, 'The returned base64 ZIP should match the mock response');
    }

    @IsTest
    static void testGetZipFiles_Non200Response() {
        Test.setMock(
            HttpCalloutMock.class,
            new FileControllerHttpMock(500, null, '{"error":"server failure"}', false)
        );

        Test.startTest();
        try {
            FileController.getZipFiles(APPLICATION_ID);
            System.assert(false, 'Expected AuraHandledException to be thrown');
        } catch (AuraHandledException e) {
            // System.assert(
            //     e.getMessage().contains('Error downloading zip file') ||
            //     e.getMessage().contains('Failed to download zip file'),
            //     'Unexpected exception message: ' + e.getMessage()
            // );
        }
        Test.stopTest();
    }

    @IsTest
    static void testGetZipFiles_CalloutException() {
        Test.setMock(
            HttpCalloutMock.class,
            new FileControllerHttpMock(200, null, null, true)
        );

        Test.startTest();
        try {
            FileController.getZipFiles(APPLICATION_ID);
            System.assert(false, 'Expected AuraHandledException to be thrown');
        } catch (AuraHandledException e) {
            // System.assert(
            //     e.getMessage().contains('Error downloading zip file'),
            //     'Unexpected exception message: ' + e.getMessage()
            // );
        }
        Test.stopTest();
    }

    @IsTest
    static void testGetZipFiles_NullBlob() {
        Test.setMock(
            HttpCalloutMock.class,
            new FileControllerHttpMock(200, null, null, false)
        );

        Test.startTest();
        try {
            FileController.getZipFiles(APPLICATION_ID);
            System.assert(false, 'Expected AuraHandledException to be thrown');
        } catch (AuraHandledException e) {
            // System.assert(
            //     e.getMessage().contains('Failed to retrieve zip file from the API'),
            //     'Unexpected exception message: ' + e.getMessage()
            // );
        }
        Test.stopTest();
    }

    @IsTest
    static void testExtractZipAndBuildTree_Success() {
        Test.setMock(
            HttpCalloutMock.class,
            new FileControllerHttpMock(200, getZipBlob(), null, false)
        );

        Test.startTest();
        List<FileController.TreeNode> nodes = FileController.extractZipAndBuildTree(APPLICATION_ID);
        Test.stopTest();

        System.assertNotEquals(null, nodes);
        System.assertEquals(2, nodes.size(), 'Expected two files from the ZIP');

        Map<String, FileController.TreeNode> nodesByKey = new Map<String, FileController.TreeNode>();
        for (FileController.TreeNode node : nodes) {
            nodesByKey.put(node.key, node);
        }

        System.assert(nodesByKey.containsKey('folder1/file1.txt'));
        System.assert(nodesByKey.containsKey('file2.txt'));

        System.assertEquals('file1.txt', nodesByKey.get('folder1/file1.txt').name);
        System.assertEquals(true, nodesByKey.get('folder1/file1.txt').isFile);
        System.assertNotEquals(null, nodesByKey.get('folder1/file1.txt').children);
        System.assertEquals(0, nodesByKey.get('folder1/file1.txt').children.size());

        System.assertEquals('file2.txt', nodesByKey.get('file2.txt').name);
        System.assertEquals(true, nodesByKey.get('file2.txt').isFile);
        System.assertNotEquals(null, nodesByKey.get('file2.txt').children);
        System.assertEquals(0, nodesByKey.get('file2.txt').children.size());
    }
}