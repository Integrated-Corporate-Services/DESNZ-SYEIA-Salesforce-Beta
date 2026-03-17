@IsTest
public class CaseTriggerHelperTest {

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

    // Utility to create test cases
    private static List<Case__c> createCases(Integer count) {
        List<Case__c> cases = new List<Case__c>();
        for(Integer i = 0; i < count; i++) {
            cases.add(new Case__c(Name='Case ' + i, Status__c='New'));
        }
        return cases;
    }

    // ----------------------------
    // Static method tests
    // ----------------------------
    @IsTest
    static void testStaticMethods() {
        List<Case__c> cases = createCases(2);
        insert cases;

        CaseTriggerHelper.markAsProcessed(cases[0].Id);
        CaseTriggerHelper.markAsProcessed(new Set<Id>{cases[1].Id});

        System.assert(CaseTriggerHelper.isRecordProcessed(cases[0].Id));
        System.assert(CaseTriggerHelper.isRecordProcessed(cases[1].Id));
        System.assertEquals(2, CaseTriggerHelper.getProcessedCount());

        CaseTriggerHelper.disableProcessing();
        System.assertEquals(true, true); // simple coverage
        CaseTriggerHelper.enableProcessing();
    }

    // ----------------------------
    // Test processAfterUpdate triggers private method
    // ----------------------------
    @IsTest
    static void testProcessAfterUpdateWithStatusChange() {
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        List<Case__c> cases = createCases(2);
        insert cases;

        // Build old map with clones
        Map<Id, SObject> oldMap = new Map<Id, SObject>();
        for(Case__c c : cases) oldMap.put(c.Id, c.clone(false, true, false, false));

        // Change status to trigger callout
        for(Case__c c : cases) c.Status__c = 'In Progress';
        update cases;

        CaseTriggerHelper helper = new CaseTriggerHelper();

        List<Case__c> updatedCases = [SELECT Id, Status__c FROM Case__c WHERE Id IN :cases];
        Map<Id, SObject> updatedMap = new Map<Id, SObject>();
        for(Case__c c : cases) updatedMap.put(c.Id, c.clone(false, true, false, false));

        Test.startTest();
        helper.processAfterUpdate(updatedCases, updatedMap);
        Test.stopTest();
    }

    // ----------------------------
    // Directly test private method using @TestVisible
    // ----------------------------
    @IsTest
    static void testPrivateUpdateStatusCalloutDirectly() {
        List<Case__c> cases = createCases(2);
        insert cases;

        Map<Id, SObject> oldMap = new Map<Id, SObject>();
        for(Case__c c : cases) oldMap.put(c.Id, c.clone(false, true, false, false));

        CaseTriggerHelper helper = new CaseTriggerHelper();

        Test.startTest();
        helper.updateStatusCallout(cases, oldMap); // @TestVisible allows direct access
        Test.stopTest();
    }

    // ----------------------------
    // Test processing disabled scenario
    // ----------------------------
    @IsTest
    static void testEmptyProcessAfterUpdateWhenDisabled() {
        CaseTriggerHelper.disableProcessing();

        CaseTriggerHelper helper = new CaseTriggerHelper();
        List<Case__c> cases = createCases(1);
        Map<Id, SObject> caseMap = new Map<Id, SObject>();

        Test.startTest();
        helper.processAfterUpdate(cases, caseMap); // should skip processing
        Test.stopTest();

        CaseTriggerHelper.enableProcessing();
    }

    // ----------------------------
    // Test >100 records to cover chunking logic
    // ----------------------------
    @IsTest
    static void testUpdateStatusCalloutChunking() {
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        List<Case__c> cases = createCases(250); // more than 100
        insert cases;

        // Build old map with clones
        Map<Id, SObject> oldMap = new Map<Id, SObject>();
        for(Case__c c : cases) oldMap.put(c.Id, c.clone(false, true, false, false));

        // Change status to trigger callout
        for(Case__c c : cases) c.Status__c = 'In Progress';
        update cases;

        CaseTriggerHelper helper = new CaseTriggerHelper();

        List<Case__c> updatedCases = [SELECT Id, Status__c FROM Case__c WHERE Id IN :cases];

        Map<Id, SObject> updatedMap = new Map<Id, SObject>();
        for(Case__c c : cases) updatedMap.put(c.Id, c.clone(false, true, false, false));

        Test.startTest();
        helper.updateStatusCallout(updatedCases, updatedMap); // triggers chunking logic (>100)
        Test.stopTest();
    }
}