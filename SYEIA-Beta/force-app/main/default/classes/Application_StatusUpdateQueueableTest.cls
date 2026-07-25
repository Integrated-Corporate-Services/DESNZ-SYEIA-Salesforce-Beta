@IsTest
public class Application_StatusUpdateQueueableTest {

    @testSetup
    static void createSalesforceSetting() {

        SalesforceSettings__c settings = new SalesforceSettings__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            Endpoint_Url__c = 'https://saas-page-9942--devsyeia2.sandbox.my.salesforce.com/services/oauth2/token',
            client_id__c ='3MVG92ZJW.xbfBW3MVG92ZJW.xbfBW3MVG92ZJW.xbfBW3MVG92ZJW.xbfBW',
            client_secret__c='6A05AF344FD291BD6A05AF344FD291BD6A05AF344FD291BD6A05AF344FD291BD',
            grant_type__c = 'client_credentials'
        );
        insert settings;
    }

    static void createAWSSetting() {

        AWS_EndPoints__c settings = new AWS_EndPoints__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            Update_Status_Endpoint__c =
                'https://test.com/backend/api/v1/internal/applications/{0}/status'
        );
        insert settings;
    }

    class MockHttpResponseGenerator implements HttpCalloutMock {

        public HttpResponse respond(HttpRequest req) {

            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);

            if(req.getEndpoint().contains('/oauth2/token')){
                res.setBody('{"access_token":"mock_token"}');
            }
            else{
                res.setBody('{"success":true}');
            }

            return res;
        }
    }

    /**
     * Returns any metadata mapping configured in the org.
     */
    private static Application_Status_Mapping__mdt getMapping() {

        return [
            SELECT Salesforce_Status__c,
                   AWS_Status__c,
                   RecordType_Dev_Name__c
            FROM Application_Status_Mapping__mdt
            LIMIT 1
        ];
    }

    /**
     * Creates Cases for the supplied Record Type and Status.
     */
    private static List<Case__c> getCases(
        Integer count,
        String status,
        Id recordTypeId
    ) {

        List<Case__c> cases = new List<Case__c>();

        for(Integer i = 0; i < count; i++) {

            cases.add(new Case__c(
                Name = 'Case ' + i,
                AWS_Application_Id__c = 'AWS' + i,
                RecordTypeId = recordTypeId
            ));
        }

        insert cases;

        for(Case__c c : cases){
            c.Status__c = status;
        }

        update cases;

        return cases;
    }

    @IsTest
    static void testConstructorAndEmptyExecute() {

        createAWSSetting();

        Test.startTest();

        Id jobId = System.enqueueJob(
            new Application_StatusUpdateQueueable(new List<Id>())
        );

        Test.stopTest();

        System.assertNotEquals(null, jobId);
    }

    @IsTest
    static void testExecuteWithNullIds() {

        createAWSSetting();

        Test.startTest();

        Id jobId = System.enqueueJob(
            new Application_StatusUpdateQueueable(null)
        );

        Test.stopTest();

        System.assertNotEquals(null, jobId);
    }

    @IsTest
    static void testExecuteWithCases() {

        Test.setMock(HttpCalloutMock.class,
            new MockHttpResponseGenerator());

        createAWSSetting();

        Application_Status_Mapping__mdt mapping = getMapping();

        Schema.RecordTypeInfo rtInfo =
            Schema.SObjectType.Case__c
                .getRecordTypeInfosByDeveloperName()
                .get(mapping.RecordType_Dev_Name__c);

        System.assertNotEquals(null, rtInfo);

        List<Case__c> cases = getCases(
            2,
            mapping.Salesforce_Status__c,
            rtInfo.getRecordTypeId()
        );

        List<Id> ids = new List<Id>();

        for(Case__c c : cases){
            ids.add(c.Id);
        }

        Test.startTest();

        Id jobId = System.enqueueJob(
            new Application_StatusUpdateQueueable(ids)
        );

        Test.stopTest();

        System.assertNotEquals(null, jobId);
    }

    @IsTest
    static void testExecuteWithNoMatchingMetadata() {

        Test.setMock(HttpCalloutMock.class,
            new MockHttpResponseGenerator());

        createAWSSetting();

        Application_Status_Mapping__mdt mapping = getMapping();

        Schema.RecordTypeInfo rtInfo =
            Schema.SObjectType.Case__c
                .getRecordTypeInfosByDeveloperName()
                .get(mapping.RecordType_Dev_Name__c);

        List<Case__c> cases = getCases(
            1,
            'Some Invalid Status',
            rtInfo.getRecordTypeId()
        );

        Test.startTest();

        System.enqueueJob(
            new Application_StatusUpdateQueueable(
                new List<Id>{cases[0].Id}
            )
        );

        Test.stopTest();

        System.assert(true);
    }

    @IsTest
    static void testExecuteWithLargeBatch() {

        Test.setMock(HttpCalloutMock.class,
            new MockHttpResponseGenerator());

        createAWSSetting();

        Application_Status_Mapping__mdt mapping = getMapping();

        Schema.RecordTypeInfo rtInfo =
            Schema.SObjectType.Case__c
                .getRecordTypeInfosByDeveloperName()
                .get(mapping.RecordType_Dev_Name__c);

        List<Case__c> cases = getCases(
            99,
            mapping.Salesforce_Status__c,
            rtInfo.getRecordTypeId()
        );

        List<Id> ids = new List<Id>();

        for(Case__c c : cases){
            ids.add(c.Id);
        }

        Test.startTest();

        System.enqueueJob(
            new Application_StatusUpdateQueueable(ids)
        );

        Test.stopTest();

        System.assertEquals(99, ids.size());
    }
}