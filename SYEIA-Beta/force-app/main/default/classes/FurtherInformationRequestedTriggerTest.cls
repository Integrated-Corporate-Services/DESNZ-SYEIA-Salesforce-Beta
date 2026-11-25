@IsTest
private class FurtherInformationRequestedTriggerTest {

    // ------------------------------------------------------------------
    // SETUP
    // Adjust the Case__c / Further_Information_Requested__c fields below
    // if your org has extra required fields or validation rules.
    // ------------------------------------------------------------------
    @TestSetup
    static void setupData() {
        CaseTriggerHelper.disableProcessing();   // don't fire the status-update callout logic
        insert new Case__c(
            Name                  = 'FIR Test Application',
            AWS_Application_Id__c = 'AWS-FIR-001'
        );
        CaseTriggerHelper.enableProcessing();
    }

    private static Case__c getApplication() {
        return [SELECT Id FROM Case__c WHERE AWS_Application_Id__c = 'AWS-FIR-001' LIMIT 1];
    }

    private static Further_Information_Requested__c newFir(Id caseId, String recipient) {
        return new Further_Information_Requested__c(
            Case__c                           = caseId,      // lookup to the application
            FIR_to_Applicant_or_Landowner__c  = recipient    // 'Applicant' or 'Landowner'
        );
    }

    private static Map<String, Object> payloadAt(Integer index) {
        Further_Information_Request_Event__e evt =
            FurtherInfoRequestedEventPublisher.publishedEvents[index];
        return (Map<String, Object>) JSON.deserializeUntyped(evt.Payload__c);
    }

    private static String firIdFromEvent(Integer index) {
        return (String) payloadAt(index).get('firId');
    }

    // ------------------------------------------------------------------
    // AFTER INSERT  ->  publishEvents(Trigger.new, null)
    // ------------------------------------------------------------------
    @IsTest
    static void testAfterInsertPublishesEvents() {
        Case__c app = getApplication();
        Further_Information_Requested__c fir = newFir(app.Id, 'Applicant');

        Test.startTest();
        insert fir;
        Test.getEventBus().deliver();   // deliver any published platform events
        Test.stopTest();

        Assert.areEqual(1,
            [SELECT COUNT() FROM Further_Information_Requested__c WHERE Case__c = :app.Id],
            'FIR record should be inserted and trigger should run without errors');

        Assert.areEqual(1, FurtherInfoRequestedEventPublisher.publishedEvents.size(),
            'One event should be published on insert');
        Assert.areEqual(String.valueOf(fir.Id), firIdFromEvent(0),
            'Insert event payload should contain the FIR Id');
        Assert.isFalse(payloadAt(0).containsKey('FIR_Requested_Deadline'),
            'Insert should not send FIR_Requested_Deadline');
    }

    @IsTest
    static void testAfterInsertBulk() {
        Case__c app = getApplication();

        List<Further_Information_Requested__c> firs = new List<Further_Information_Requested__c>();
        for (Integer i = 0; i < 200; i++) {
            firs.add(newFir(app.Id, Math.mod(i, 2) == 0 ? 'Applicant' : 'Landowner'));
        }

        Test.startTest();
        insert firs;                    // trigger must handle a full 200-record batch
        Test.getEventBus().deliver();
        Test.stopTest();

        Assert.areEqual(200,
            [SELECT COUNT() FROM Further_Information_Requested__c WHERE Case__c = :app.Id]);
        Assert.areEqual(200, FurtherInfoRequestedEventPublisher.publishedEvents.size());

        // Every event should carry one of the inserted FIR Ids
        Set<String> insertedIds = new Set<String>();
        for (Further_Information_Requested__c f : firs) {
            insertedIds.add(String.valueOf(f.Id));
        }
        for (Integer i = 0; i < 200; i++) {
            Assert.isTrue(insertedIds.contains(firIdFromEvent(i)));
        }
    }

    // ------------------------------------------------------------------
    // AFTER UPDATE  ->  publishEvents(Trigger.new, Trigger.oldMap)
    // ------------------------------------------------------------------
    @IsTest
    static void testAfterUpdatePublishesEvents() {
        Case__c app = getApplication();
        Further_Information_Requested__c fir = newFir(app.Id, 'Applicant');
        insert fir;

        // Ignore the insert event; only check the update
        FurtherInfoRequestedEventPublisher.publishedEvents.clear();
        Date newDeadline = Date.today().addDays(21);

        Test.startTest();
        fir.Further_Information_Requested_Deadline__c = newDeadline;   // change deadline
        update fir;
        Test.getEventBus().deliver();
        Test.stopTest();

        Assert.areEqual(1, FurtherInfoRequestedEventPublisher.publishedEvents.size(),
            'One event should be published on update');
        Assert.areEqual(String.valueOf(fir.Id), firIdFromEvent(0),
            'Update event payload should contain the FIR Id');
        Assert.areEqual(String.valueOf(newDeadline), payloadAt(0).get('FIR_Requested_Deadline'),
            'Changed deadline should be sent as FIR_Requested_Deadline');
    }

    @IsTest
    static void testAfterUpdateWithoutChanges() {
        Case__c app = getApplication();
        Further_Information_Requested__c fir = newFir(app.Id, 'Applicant');
        insert fir;

        FurtherInfoRequestedEventPublisher.publishedEvents.clear();

        Test.startTest();
        fir.FIR_to_Applicant_or_Landowner__c = 'Landowner';   // not the deadline
        update fir;
        Test.getEventBus().deliver();
        Test.stopTest();

        Assert.areEqual(1, FurtherInfoRequestedEventPublisher.publishedEvents.size(),
            'Updates still publish');
        Assert.isFalse(payloadAt(0).containsKey('FIR_Requested_Deadline'),
            'Unchanged deadline should not be sent');
    }

    @IsTest
    static void testAfterUpdateBulk() {
        Case__c app = getApplication();

        List<Further_Information_Requested__c> firs = new List<Further_Information_Requested__c>();
        for (Integer i = 0; i < 50; i++) {
            firs.add(newFir(app.Id, 'Applicant'));
        }
        insert firs;

        FurtherInfoRequestedEventPublisher.publishedEvents.clear();

        for (Further_Information_Requested__c f : firs) {
            f.Further_Information_Requested_Deadline__c = Date.today().addDays(21);
        }

        Test.startTest();
        update firs;
        Test.getEventBus().deliver();
        Test.stopTest();

        Assert.areEqual(50, FurtherInfoRequestedEventPublisher.publishedEvents.size(),
            'Each updated record should publish an event');
        for (Integer i = 0; i < 50; i++) {
            Assert.isTrue(payloadAt(i).containsKey('FIR_Requested_Deadline'));
        }
    }
}