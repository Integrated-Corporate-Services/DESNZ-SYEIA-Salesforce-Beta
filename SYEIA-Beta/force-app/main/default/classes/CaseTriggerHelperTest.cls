@IsTest
public class CaseTriggerHelperTest {

    private static final String QUEUEABLE_CLASS = 'Application_StatusUpdateQueueable';

    @TestSetup
    static void setupData() {
        // OAuth settings used by OAuthTokenService inside the queueable
        insert new SalesforceSettings__c(
            SetupOwnerId     = UserInfo.getOrganizationId(),
            Endpoint_Url__c  = 'https://saas-page-9942--devsyeia2.sandbox.my.salesforce.com/services/oauth2/token',
            client_id__c     = 'CLIENT_ID_SAMPLE',
            client_secret__c = 'ClIENT_SECRET_SAMPLE',
            grant_type__c    = 'client_credentials'
            
        );

        // Bypass payment-date validation rules so Payment_Date__c can be set on Case__c in tests
        insert new Validation_Bypass__c(
            SetupOwnerId                   = UserInfo.getOrganizationId(),
            Disable_Payment_Date_Rules__c  = true
        );
    }

    // ========================================================================
    // MOCKS & HELPERS
    // ========================================================================

    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"access_token":"mock_token","success":true}');
            return res;
        }
    }

    private static List<Case__c> createCases(Integer count, String status) {
        List<Case__c> cases = new List<Case__c>();
        for (Integer i = 0; i < count; i++) {
            cases.add(new Case__c(Name = 'Case ' + i, Status__c = status));
        }
        return cases;
    }

    /** Snapshot of the records as they are now = Trigger.oldMap */
    private static Map<Id, SObject> buildOldMap(List<Case__c> cases) {
        Map<Id, SObject> oldMap = new Map<Id, SObject>();
        for (Case__c c : cases) {
            oldMap.put(c.Id, c.clone(true, true, false, false)); // keep Id
        }
        return oldMap;
    }

    /** In-memory status change only (no DML, so the real trigger doesn't enqueue extra jobs) */
    private static void changeStatus(List<Case__c> cases, String newStatus) {
        for (Case__c c : cases) {
            c.Status__c = newStatus;
        }
    }

    private static Integer countQueuedStatusJobs() {
        return [
            SELECT COUNT()
            FROM AsyncApexJob
            WHERE ApexClass.Name = :QUEUEABLE_CLASS
        ];
    }

    // ========================================================================
    // STATIC CONTROL METHODS
    // ========================================================================

    @IsTest
    static void testStaticMethods() {
        List<Case__c> cases = createCases(2, 'New');
        insert cases;

        Test.startTest();
        CaseTriggerHelper.markAsProcessed(cases[0].Id);
        CaseTriggerHelper.markAsProcessed(new Set<Id>{ cases[1].Id });
        Test.stopTest();

        Assert.isTrue(CaseTriggerHelper.isRecordProcessed(cases[0].Id));
        Assert.isTrue(CaseTriggerHelper.isRecordProcessed(cases[1].Id));
        Assert.areEqual(2, CaseTriggerHelper.getProcessedCount());
    }

    @IsTest
    static void testIsRecordProcessedReturnsFalseForUnknownId() {
        List<Case__c> cases = createCases(1, 'New');
        insert cases;

        Assert.isFalse(CaseTriggerHelper.isRecordProcessed(cases[0].Id));
        Assert.areEqual(0, CaseTriggerHelper.getProcessedCount());
    }

    @IsTest
    static void testNoOpTriggerEventMethods() {
        CaseTriggerHelper helper = new CaseTriggerHelper();

        Test.startTest();
        helper.processBeforeInsert();
        helper.processAfterInsert();
        helper.processBeforeUpdate();
        helper.processBeforeDelete();
        helper.processAfterDelete();
        helper.processAfterUndelete();
        Test.stopTest();

        Assert.areEqual(0, countQueuedStatusJobs(), 'No-op methods must not enqueue anything');
    }

    // ========================================================================
    // processAfterUpdate
    // ========================================================================

    @IsTest
    static void testProcessAfterUpdateWhenDisabledSkipsEverything() {
        List<Case__c> cases = createCases(2, 'New');
        insert cases;
        Map<Id, SObject> oldMap = buildOldMap(cases);
        changeStatus(cases, 'In Progress');

        CaseTriggerHelper.disableProcessing();
        Test.startTest();
        new CaseTriggerHelper().processAfterUpdate(cases, oldMap);
        Test.stopTest();
        CaseTriggerHelper.enableProcessing();

        Assert.areEqual(0, countQueuedStatusJobs(), 'Disabled processing must not enqueue the status job');
    }

    @IsTest
    static void testProcessAfterUpdateWithStatusChangeEnqueuesJob() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        List<Case__c> cases = createCases(2, 'New');
        insert cases;
        Map<Id, SObject> oldMap = buildOldMap(cases);   // old status = New
        changeStatus(cases, 'In Progress');             // new status = In Progress

        Test.startTest();
        new CaseTriggerHelper().processAfterUpdate(cases, oldMap);
        Test.stopTest();

        Assert.areEqual(1, countQueuedStatusJobs(), 'One job expected for 2 changed records');
    }

    @IsTest
    static void testProcessAfterUpdateWithoutStatusChangeDoesNotEnqueue() {
        List<Case__c> cases = createCases(2, 'New');
        insert cases;
        Map<Id, SObject> oldMap = buildOldMap(cases);   // same status in old and new

        Test.startTest();
        new CaseTriggerHelper().processAfterUpdate(cases, oldMap);
        Test.stopTest();

        Assert.areEqual(0, countQueuedStatusJobs(), 'No status change = no job');
    }

    // ========================================================================
    // updateStatusCallout (chunking + filtering)
    // ========================================================================

    @IsTest
    static void testUpdateStatusCalloutOnlyChangedRecords() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        List<Case__c> cases = createCases(3, 'New');
        insert cases;
        Map<Id, SObject> oldMap = buildOldMap(cases);
        cases[0].Status__c = 'In Progress';             // only one record changes

        Test.startTest();
        new CaseTriggerHelper().updateStatusCallout(cases, oldMap);
        Test.stopTest();

        Assert.areEqual(1, countQueuedStatusJobs(), 'Only changed records should be sent');
    }

    @IsTest
    static void testUpdateStatusCalloutExactlyOneFullChunk() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        List<Case__c> cases = createCases(90, 'New');   // exactly chunk size
        insert cases;
        Map<Id, SObject> oldMap = buildOldMap(cases);
        changeStatus(cases, 'In Progress');

        Test.startTest();
        new CaseTriggerHelper().updateStatusCallout(cases, oldMap);
        Test.stopTest();

        // Covers the "full chunk" branch with no remainder
        Assert.areEqual(1, countQueuedStatusJobs(), '90 records = 1 full chunk, no remainder');
    }

    @IsTest
    static void testUpdateStatusCalloutChunking() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        List<Case__c> cases = createCases(181, 'New');  // 90 + 90 + 1
        insert cases;
        Map<Id, SObject> oldMap = buildOldMap(cases);
        changeStatus(cases, 'In Progress');

        Test.startTest();
        new CaseTriggerHelper().updateStatusCallout(cases, oldMap);
        Test.stopTest();

        // Covers both the full-chunk branch and the remainder branch
        Assert.areEqual(3, countQueuedStatusJobs(), '181 records = 2 full chunks + 1 remainder');
    }

    @IsTest
    static void testUpdateStatusCalloutWithEmptyList() {
        Test.startTest();
        new CaseTriggerHelper().updateStatusCallout(new List<Case__c>(), new Map<Id, SObject>());
        Test.stopTest();

        Assert.areEqual(0, countQueuedStatusJobs());
    }

    // ========================================================================
    // markBacsPaymentsPaid
    // ========================================================================

    @IsTest
    static void testMarkBacsPaymentsPaidUpdatesBacsPayment() {
        Payment__c bacsPayment = new Payment__c(Payment_Method__c = 'BACS');
        insert bacsPayment;

        Case__c app = new Case__c(
            Name            = 'BACS Case',
            Status__c       = 'New',
            Payment__c      = bacsPayment.Id,
            Payment_Date__c = Date.today()
        );
        insert app;

        Test.startTest();
        CaseTriggerHelper.markBacsPaymentsPaid(new List<Case__c>{ app });
        Test.stopTest();

        Payment__c result = [SELECT Status__c FROM Payment__c WHERE Id = :bacsPayment.Id];
        Assert.areEqual('PAID', result.Status__c, 'BACS payment with a payment date should be marked PAID');
    }

    @IsTest
    static void testMarkBacsPaymentsPaidIgnoresNonBacsPayment() {
        Payment__c cardPayment = new Payment__c(Payment_Method__c = 'Credit Card');
        insert cardPayment;

        Case__c app = new Case__c(
            Name            = 'Card Case',
            Status__c       = 'New',
            Payment__c      = cardPayment.Id,
            Payment_Date__c = Date.today()
        );
        insert app;

        Test.startTest();
        CaseTriggerHelper.markBacsPaymentsPaid(new List<Case__c>{ app });
        Test.stopTest();

        Payment__c result = [SELECT Status__c FROM Payment__c WHERE Id = :cardPayment.Id];
        Assert.areNotEqual('PAID', result.Status__c, 'Non-BACS payments must not be changed');
    }

    @IsTest
    static void testMarkBacsPaymentsPaidSkipsAlreadyPaid() {
        Payment__c paidPayment = new Payment__c(Payment_Method__c = 'BACS', Status__c = 'PAID');
        insert paidPayment;

        Case__c app = new Case__c(
            Name            = 'Paid Case',
            Status__c       = 'New',
            Payment__c      = paidPayment.Id,
            Payment_Date__c = Date.today()
        );
        insert app;

        Test.startTest();
        CaseTriggerHelper.markBacsPaymentsPaid(new List<Case__c>{ app });
        Test.stopTest();

        Payment__c result = [SELECT Status__c FROM Payment__c WHERE Id = :paidPayment.Id];
        Assert.areEqual('PAID', result.Status__c, 'Already-paid payment stays PAID');
    }

    @IsTest
    static void testMarkBacsPaymentsPaidNoPaymentDate() {
        Payment__c bacsPayment = new Payment__c(Payment_Method__c = 'BACS');
        insert bacsPayment;

        Case__c app = new Case__c(
            Name       = 'No Date Case',
            Status__c  = 'New',
            Payment__c = bacsPayment.Id          // no Payment_Date__c -> early return
        );
        insert app;

        Test.startTest();
        CaseTriggerHelper.markBacsPaymentsPaid(new List<Case__c>{ app });
        Test.stopTest();

        Payment__c result = [SELECT Status__c FROM Payment__c WHERE Id = :bacsPayment.Id];
        Assert.areNotEqual('PAID', result.Status__c, 'Without a payment date nothing should change');
    }

    @IsTest
    static void testMarkBacsPaymentsPaidNoPaymentLinked() {
        Case__c app = new Case__c(Name = 'No Payment', Status__c = 'New', Payment_Date__c = Date.today());
        insert app;

        Test.startTest();
        CaseTriggerHelper.markBacsPaymentsPaid(new List<Case__c>{ app });  // early return
        Test.stopTest();

        Assert.areEqual(0, [SELECT COUNT() FROM Payment__c WHERE Status__c = 'PAID']);
    }

    @IsTest
    static void testProcessAfterUpdateMarksBacsPaidEndToEnd() {
        Payment__c bacsPayment = new Payment__c(Payment_Method__c = 'BACS');
        insert bacsPayment;

        Case__c app = new Case__c(
            Name            = 'E2E Case',
            Status__c       = 'New',
            Payment__c      = bacsPayment.Id,
            Payment_Date__c = Date.today()
        );
        insert app;

        List<Case__c> apps = new List<Case__c>{ app };
        Map<Id, SObject> oldMap = buildOldMap(apps);    // no status change -> no callout job

        Test.startTest();
        new CaseTriggerHelper().processAfterUpdate(apps, oldMap);
        Test.stopTest();

        Payment__c result = [SELECT Status__c FROM Payment__c WHERE Id = :bacsPayment.Id];
        Assert.areEqual('PAID', result.Status__c);
        Assert.areEqual(0, countQueuedStatusJobs());
    }
}