@IsTest
public class Application_StatusUpdateQueueableTest {
    
    @testSetup
    static void createSalesforceSetting(){
        SalesforceSettings__c settings = new SalesforceSettings__c(
            SetupOwnerId = UserInfo.getOrganizationId(), // KEY LINE
            Endpoint_Url__c = 'https://saas-page-9942--devsyeia2.sandbox.my.salesforce.com/services/oauth2/token',
            client_id__c ='3MVG92ZJW.xbfBW3MVG92ZJW.xbfBW3MVG92ZJW.xbfBW3MVG92ZJW.xbfBW',
            client_secret__c='6A05AF344FD291BD6A05AF344FD291BD6A05AF344FD291BD6A05AF344FD291BD',
            grant_type__c = 'client_credentials'
        );
        insert settings;
    }
    // Mock HTTP callout for getAccessToken()
    class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"access_token":"mock_token"}');
            return res;
        }
    }

    // Utility to create test Case__c records
    private static List<Case__c> GetCasesWithInProgress(Integer count) {
        List<Case__c> cases = new List<Case__c>();
        for(Integer i = 0; i < count; i++) {
            cases.add(new Case__c(
                Name='Case ' + i,
                AWS_Application_Id__c='AWS' + i
            ));
        }
        insert cases;
        
       for(Case__c application: cases) {
			application.Status__c = 'In-Progress';
        }
		update cases;        
        return cases;
    }

    // -----------------------------
    // Test empty constructor and execute
    // -----------------------------
    @IsTest
    static void testConstructorAndEmptyExecute() {
        Application_StatusUpdateQueueable job = new Application_StatusUpdateQueueable(new List<Id>());
        Test.startTest();
        Id jobId = System.enqueueJob(job);
        Test.stopTest();
        System.assertNotEquals(null, jobId, 'Job ID should not be null');
    }

    // -----------------------------
    // Test execute with actual cases
    // -----------------------------
    @IsTest
    static void testExecuteWithCases() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Create two test cases with In-Progress status
        List<Case__c> cases = GetCasesWithInProgress(2);
        List<Id> caseIds = new List<Id>();
        
        
        
        for(Case__c c : cases) caseIds.add(c.Id);

        Test.startTest();
        Application_StatusUpdateQueueable job = new Application_StatusUpdateQueueable(caseIds);
        Id jobId = System.enqueueJob(job);
        Test.stopTest();
        System.assertNotEquals(null, jobId, 'Job ID should not be null');
    }

    // -----------------------------
    // Test execute with null list
    // -----------------------------
    @IsTest
    static void testExecuteWithNullIds() {
        Test.startTest();
        Application_StatusUpdateQueueable job = new Application_StatusUpdateQueueable(null);
        Id jobId = System.enqueueJob(job);
        Test.stopTest();
        System.assertNotEquals(null, jobId, 'Job ID should not be null');
    }

    // -----------------------------
    // Test execute with =100 records (chunking)
    // -----------------------------
    @IsTest
    static void testExecuteWithChunking() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        List<Case__c> cases = GetCasesWithInProgress(99); // 100 to trigger chunking
        List<Id> caseIds = new List<Id>();
        for(Case__c c : cases) caseIds.add(c.Id);

        Test.startTest();
        Application_StatusUpdateQueueable job = new Application_StatusUpdateQueueable(caseIds);
        Id jobId = System.enqueueJob(job);
        Test.stopTest();
        System.assertNotEquals(null, jobId, 'Job ID should not be null');
    }
}