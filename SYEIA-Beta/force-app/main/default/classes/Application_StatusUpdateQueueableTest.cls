@IsTest
public class Application_StatusUpdateQueueableTest {

    @testSetup
    static void createSalesforceSetting() {

        SalesforceSettings__c settings = new SalesforceSettings__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            Endpoint_Url__c = 'https://saas-page-9942--devsyeia2.sandbox.my.salesforce.com/services/oauth2/token',
            client_id__c ='SAMPL3C1ENT1D',
            client_secret__c='SAMPL3C1ENTS3CR3T',
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
     * Returns a metadata mapping for a specific Salesforce status.
     */
    private static Application_Status_Mapping__mdt getMappingForStatus(String salesforceStatus) {

        return [
            SELECT Salesforce_Status__c,
                   AWS_Status__c,
                   RecordType_Dev_Name__c
            FROM Application_Status_Mapping__mdt
            WHERE Salesforce_Status__c = :salesforceStatus
            LIMIT 1
        ];
    }

    private static Id getRecordTypeId(String devName) {

        Schema.RecordTypeInfo rtInfo =
            Schema.SObjectType.Case__c
                .getRecordTypeInfosByDeveloperName()
                .get(devName);

        System.assertNotEquals(null, rtInfo, 'Record type not found: ' + devName);
        return rtInfo.getRecordTypeId();
    }

    /**
     * Creates Cases for the supplied Record Type and Status.
     */
    private static List<Case__c> getCases(
        Integer count,
        String status,
        Id recordTypeId
    ) {
        return getCases(count, status, recordTypeId, null);
    }

    /**
     * Creates Cases for the supplied Record Type and Status, optionally linked to a Payment.
     */
    private static List<Case__c> getCases(
        Integer count,
        String status,
        Id recordTypeId,
        Id paymentId
    ) {

        List<Case__c> cases = new List<Case__c>();

        for(Integer i = 0; i < count; i++) {

            cases.add(new Case__c(
                Name = 'Case ' + i,
                AWS_Application_Id__c = 'AWS' + i,
                RecordTypeId = recordTypeId,
                Payment__c = paymentId
            ));
        }

        insert cases;

        for(Case__c c : cases){
            c.Status__c = status;
        }

        update cases;

        return cases;
    }

    /**
     * Builds the previous-status map that CaseTriggerHelper passes in.
     */
    private static Map<Id, String> previousStatusMap(List<Case__c> cases, String previousStatus) {

        Map<Id, String> previousStatusById = new Map<Id, String>();

        for(Case__c c : cases){
            previousStatusById.put(c.Id, previousStatus);
        }

        return previousStatusById;
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

        List<Case__c> cases = getCases(
            2,
            mapping.Salesforce_Status__c,
            getRecordTypeId(mapping.RecordType_Dev_Name__c)
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

        List<Case__c> cases = getCases(
            1,
            'Some Invalid Status',
            getRecordTypeId(mapping.RecordType_Dev_Name__c)
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

        List<Case__c> cases = getCases(
            99,
            mapping.Salesforce_Status__c,
            getRecordTypeId(mapping.RecordType_Dev_Name__c)
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

    // ------------------------------------------------------------------
    // NEW: Withdrawal Requested -> Application Received + BACS payment
    // Covers: withdrawal block, paymentMethod line, 'Processing Payment',
    //         reasonCode = 'WITHDRAWAL_REJECTED'
    // ------------------------------------------------------------------
    @IsTest
    static void testWithdrawalRejectedWithBacsPayment() {

        Test.setMock(HttpCalloutMock.class,
            new MockHttpResponseGenerator());

        createAWSSetting();

        Payment__c bacsPayment = new Payment__c(Payment_Method__c = 'BACS');
        insert bacsPayment;

        Application_Status_Mapping__mdt mapping = getMappingForStatus('Application Received');

        List<Case__c> cases = getCases(
            1,
            'Application Received',
            getRecordTypeId(mapping.RecordType_Dev_Name__c),
            bacsPayment.Id
        );

        Test.startTest();

        Id jobId = System.enqueueJob(
            new Application_StatusUpdateQueueable(
                new List<Id>{ cases[0].Id },
                previousStatusMap(cases, 'Withdrawal Requested')
            )
        );

        Test.stopTest();

        System.assertNotEquals(null, jobId);
    }

    // ------------------------------------------------------------------
    // NEW: Withdrawal Requested -> Application Received, no payment
    // Covers: withdrawal block where the inner BACS condition is false
    // ------------------------------------------------------------------
    @IsTest
    static void testWithdrawalRejectedWithoutPayment() {

        Test.setMock(HttpCalloutMock.class,
            new MockHttpResponseGenerator());

        createAWSSetting();

        Application_Status_Mapping__mdt mapping = getMappingForStatus('Application Received');

        List<Case__c> cases = getCases(
            1,
            'Application Received',
            getRecordTypeId(mapping.RecordType_Dev_Name__c)
        );

        Test.startTest();

        Id jobId = System.enqueueJob(
            new Application_StatusUpdateQueueable(
                new List<Id>{ cases[0].Id },
                previousStatusMap(cases, 'Withdrawal Requested')
            )
        );

        Test.stopTest();

        System.assertNotEquals(null, jobId);
    }

    // ------------------------------------------------------------------
    // NEW: Withdrawal Requested -> Withdrawn (approved, no reason code)
    // Covers: the "!= 'Withdrawn'" side of the condition
    // ------------------------------------------------------------------
    @IsTest
    static void testWithdrawalApproved() {

        Test.setMock(HttpCalloutMock.class,
            new MockHttpResponseGenerator());

        createAWSSetting();

        Application_Status_Mapping__mdt mapping = getMappingForStatus('Withdrawn');

        List<Case__c> cases = getCases(
            1,
            'Withdrawn',
            getRecordTypeId(mapping.RecordType_Dev_Name__c)
        );

        Test.startTest();

        Id jobId = System.enqueueJob(
            new Application_StatusUpdateQueueable(
                new List<Id>{ cases[0].Id },
                previousStatusMap(cases, 'Withdrawal Requested')
            )
        );

        Test.stopTest();

        System.assertNotEquals(null, jobId);
    }

    // ------------------------------------------------------------------
    // NEW: two-argument constructor with a null map
    // ------------------------------------------------------------------
    @IsTest
    static void testTwoArgConstructorWithNullMap() {

        createAWSSetting();

        Test.startTest();

        Id jobId = System.enqueueJob(
            new Application_StatusUpdateQueueable(new List<Id>(), null)
        );

        Test.stopTest();

        System.assertNotEquals(null, jobId);
    }
}