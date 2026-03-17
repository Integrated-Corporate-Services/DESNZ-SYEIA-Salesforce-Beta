@IsTest
public class ApplicationStatusServiceTest {

    // Mock class for successful HTTP callout
    class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"success","message":"Updated successfully"}');
            res.setStatusCode(200);
            return res;
        }
    }

    // Mock class that throws an exception
    class ExceptionMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            throw new CalloutException('Mock callout failure');
        }
    }

    @IsTest
    static void testUpdateApplicationStatus_Success() {
        // Set mock
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        String applicationId = '12345';
        String targetStatus = 'In-Progress';
        String reason = 'Testing';
        String bearerToken = 'mock_token';

        Test.startTest();
        HttpResponse response = ApplicationStatusService.updateApplicationStatus(
            applicationId,
            targetStatus,
            reason,
            bearerToken
        );
        Test.stopTest();

        // Assertions
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assertEquals(200, response.getStatusCode(), 'Status code should be 200');
        System.assert(response.getBody().contains('Updated successfully'), 'Body should contain success message');
    }

    @IsTest
    static void testUpdateApplicationStatus_Exception() {
        // Set mock that throws exception
        Test.setMock(HttpCalloutMock.class, new ExceptionMock());

        String applicationId = '12345';
        String targetStatus = 'In-Progress';
        String reason = 'Testing';
        String bearerToken = 'mock_token';

        Test.startTest();
        try {
            ApplicationStatusService.updateApplicationStatus(
                applicationId,
                targetStatus,
                reason,
                bearerToken
            );
            System.assert(false, 'Exception should have been thrown');
        } catch (CalloutException e) {
            System.assert(e.getMessage().contains('Mock callout failure'), 'Exception message should match mock');
        }
        Test.stopTest();
    }
}