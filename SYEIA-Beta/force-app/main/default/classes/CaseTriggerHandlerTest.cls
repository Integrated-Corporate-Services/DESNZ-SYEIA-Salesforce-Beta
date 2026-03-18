@IsTest
public class CaseTriggerHandlerTest {

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
    
    // Utility method to create test Case__c records
    private static List<Case__c> createCases(Integer count) {
        List<Case__c> cases = new List<Case__c>();
        for(Integer i = 0; i < count; i++) {
            cases.add(new Case__c(
                Name = 'Test Case ' + i,
                Status__c = 'New'
            ));
        }
        return cases;
    }

    // Convert list of Case__c to list of SObject
    private static List<SObject> toSObjectList(List<Case__c> cases) {
        List<SObject> sObjects = new List<SObject>();
        for(Case__c c : cases) sObjects.add(c);
        return sObjects;
    }

    @IsTest
    static void testBeforeInsert() {
        List<Case__c> cases = createCases(2);
        List<SObject> sObjects = toSObjectList(cases);

        Test.startTest();
        CaseTriggerHandler handler = new CaseTriggerHandler(true, sObjects.size());
        handler.beforeInsert(sObjects);
        Test.stopTest();
    }

    @IsTest
    static void testBeforeUpdate() {
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        List<Case__c> cases = createCases(2);
        insert cases;

        // Build old map with clones BEFORE making changes
        Map<Id, SObject> oldMap = new Map<Id, SObject>();
        for(Case__c c : cases) oldMap.put(c.Id, c.clone(false, true, false, false));

        // Make changes for update
        for(Case__c c : cases) c.Name += ' Updated';
        update cases;

        List<SObject> sObjects = toSObjectList(cases);

        Test.startTest();
        CaseTriggerHandler handler = new CaseTriggerHandler(true, sObjects.size());
        handler.beforeUpdate(sObjects, sObjects, oldMap, oldMap);
        Test.stopTest();
    }

    @IsTest
    static void testBeforeDelete() {
        List<Case__c> cases = createCases(2);
        insert cases;

        Map<Id, SObject> oldMap = new Map<Id, SObject>();
        for(Case__c c : cases) oldMap.put(c.Id, c);

        List<SObject> sObjects = toSObjectList(cases);

        Test.startTest();
        CaseTriggerHandler handler = new CaseTriggerHandler(true, sObjects.size());
        handler.beforeDelete(sObjects, oldMap);
        Test.stopTest();
    }

    @IsTest
    static void testAfterInsert() {
        List<Case__c> cases = createCases(2);
        List<SObject> sObjects = toSObjectList(cases);

        Test.startTest();
        CaseTriggerHandler handler = new CaseTriggerHandler(true, sObjects.size());
        handler.afterInsert(sObjects, new Map<Id, SObject>());
        Test.stopTest();
    }

    @IsTest
    static void testAfterUpdate() {
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        List<Case__c> cases = createCases(2);
        insert cases;

        // Build old map with clones BEFORE changes
        Map<Id, SObject> oldMap = new Map<Id, SObject>();
        for(Case__c c : cases) oldMap.put(c.Id, c.clone(false, true, false, false));

        // Change Name and Status to trigger updateStatusCallout
        for(Case__c c : cases) {
            c.Name += ' Updated';
            c.Status__c = 'In Progress';
        }
        update cases;

        List<SObject> sObjects = toSObjectList(cases);

        Test.startTest();
        CaseTriggerHandler handler = new CaseTriggerHandler(true, sObjects.size());
        handler.afterUpdate(sObjects, sObjects, oldMap, oldMap);
        Test.stopTest();
    }

    @IsTest
    static void testAfterDelete() {
        List<Case__c> cases = createCases(2);
        insert cases;

        Map<Id, SObject> oldMap = new Map<Id, SObject>();
        for(Case__c c : cases) oldMap.put(c.Id, c);

        List<SObject> sObjects = toSObjectList(cases);

        Test.startTest();
        CaseTriggerHandler handler = new CaseTriggerHandler(true, sObjects.size());
        handler.afterDelete(sObjects, oldMap);
        Test.stopTest();
    }

    @IsTest
    static void testAfterUndelete() {
        List<Case__c> cases = createCases(2);
        insert cases;
        delete cases;

        List<SObject> sObjects = toSObjectList(cases);

        Test.startTest();
        CaseTriggerHandler handler = new CaseTriggerHandler(true, sObjects.size());
        handler.afterUndelete(sObjects, new Map<Id, SObject>());
        Test.stopTest();
    }
}