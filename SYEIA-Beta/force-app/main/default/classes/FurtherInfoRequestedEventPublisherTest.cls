@IsTest
private class FurtherInfoRequestedEventPublisherTest {

    private static final String NWL_CASE_NAME = 'NWL00001';
    private static final String S37_CASE_NAME = 'S3700001';
    private static final String NWL_AWS_ID    = 'AWS-NWL-001';
    private static final String S37_AWS_ID    = 'AWS-S37-001';

    @TestSetup
    static void setupData() {
        CaseTriggerHelper.disableProcessing();
        insert new List<Case__c>{
            new Case__c(Name = NWL_CASE_NAME, AWS_Application_Id__c = NWL_AWS_ID),
            new Case__c(Name = S37_CASE_NAME, AWS_Application_Id__c = S37_AWS_ID)
        };
        CaseTriggerHelper.enableProcessing();
    }

    private static Id caseId(String awsId) {
        return [SELECT Id FROM Case__c WHERE AWS_Application_Id__c = :awsId LIMIT 1].Id;
    }

    private static Further_Information_Requested__c fir(Id caseId, String recipient, String message) {
        return new Further_Information_Requested__c(
            Case__c                                   = caseId,
            FIR_to_Applicant_or_Landowner__c          = recipient,
            Additional_Information_Required__c        = message,
            Further_Information_Requested_Deadline__c = Date.today().addDays(14)
        );
    }

    private static Map<String, Object> payloadOf(Further_Information_Request_Event__e evt) {
        return (Map<String, Object>) JSON.deserializeUntyped(evt.Payload__c);
    }

    // ------------------------------------------------------------------
    // Guard clauses
    // ------------------------------------------------------------------
    @IsTest
    static void testNullRecordsPublishesNothing() {
        Test.startTest();
        FurtherInfoRequestedEventPublisher.publishEvents(null, null);
        Test.stopTest();

        Assert.areEqual(0, FurtherInfoRequestedEventPublisher.publishedEvents.size());
    }

    @IsTest
    static void testEmptyRecordsPublishesNothing() {
        Test.startTest();
        FurtherInfoRequestedEventPublisher.publishEvents(new List<Further_Information_Requested__c>(), null);
        Test.stopTest();

        Assert.areEqual(0, FurtherInfoRequestedEventPublisher.publishedEvents.size());
    }

    // ------------------------------------------------------------------
    // Event fields by application type
    // ------------------------------------------------------------------
    @IsTest
    static void testNwlApplicationSetsRecipientType() {
        Id nwlCaseId = caseId(NWL_AWS_ID);

        Test.startTest();
        FurtherInfoRequestedEventPublisher.publishEvents(
            new List<Further_Information_Requested__c>{ fir(nwlCaseId, 'Applicant', 'Please send the map') },
            null
        );
        Test.stopTest();

        Assert.areEqual(1, FurtherInfoRequestedEventPublisher.publishedEvents.size());
        Further_Information_Request_Event__e evt = FurtherInfoRequestedEventPublisher.publishedEvents[0];

        Assert.areEqual(NWL_AWS_ID, evt.AWS_Application_Id__c);
        Assert.areEqual(String.valueOf(nwlCaseId), evt.Case__c);
        Assert.areEqual('NWL', evt.Type_of_Application__c);
        Assert.areEqual('Applicant', evt.Recipient_Type__c);

        Map<String, Object> payload = payloadOf(evt);
        Assert.areEqual('Please send the map', payload.get('message'));
        Assert.areEqual(String.valueOf(Date.today().addDays(14)), payload.get('responseDueDate'));
        Assert.isTrue(payload.containsKey('requestId'));
        Assert.isTrue(payload.containsKey('firId'), 'Payload should always contain firId');
        Assert.isNull(payload.get('firId'), 'Unsaved record has no Id, so firId is null');
        Assert.isFalse(payload.containsKey('FIR_Requested_Deadline'),
            'No old record, so FIR_Requested_Deadline is not sent');
    }

    @IsTest
    static void testS37ApplicationDoesNotSetRecipientType() {
        Id s37CaseId = caseId(S37_AWS_ID);

        Test.startTest();
        FurtherInfoRequestedEventPublisher.publishEvents(
            new List<Further_Information_Requested__c>{ fir(s37CaseId, 'Applicant', 'S37 info') },
            null
        );
        Test.stopTest();

        Further_Information_Request_Event__e evt = FurtherInfoRequestedEventPublisher.publishedEvents[0];
        Assert.areEqual('S37', evt.Type_of_Application__c);
        Assert.areEqual(S37_AWS_ID, evt.AWS_Application_Id__c);
        Assert.isNull(evt.Recipient_Type__c, 'S37 events must not carry a recipient type');
    }

    @IsTest
    static void testRecordWithoutCase() {
        Test.startTest();
        FurtherInfoRequestedEventPublisher.publishEvents(
            new List<Further_Information_Requested__c>{ fir(null, 'Applicant', 'No case') },
            null
        );
        Test.stopTest();

        Further_Information_Request_Event__e evt = FurtherInfoRequestedEventPublisher.publishedEvents[0];
        Assert.isNull(evt.AWS_Application_Id__c);
        Assert.isNull(evt.Case__c);
        Assert.isNull(evt.Type_of_Application__c);
        Assert.isNull(evt.Recipient_Type__c);
    }

    @IsTest
    static void testUpdatePathWithOldMap() {
        Id nwlCaseId = caseId(NWL_AWS_ID);
        Further_Information_Requested__c rec = fir(nwlCaseId, 'Landowner', 'Updated request');

        Test.startTest();
        FurtherInfoRequestedEventPublisher.publishEvents(
            new List<Further_Information_Requested__c>{ rec },
            new Map<Id, Further_Information_Requested__c>()
        );
        Test.stopTest();

        Assert.areEqual(1, FurtherInfoRequestedEventPublisher.publishedEvents.size());
        Assert.areEqual('Landowner', FurtherInfoRequestedEventPublisher.publishedEvents[0].Recipient_Type__c);
    }

    // ------------------------------------------------------------------
    // firId and FIR_Requested_Deadline: real records through the trigger
    // ------------------------------------------------------------------
    @IsTest
    static void testFirIdIncludedOnInsert() {
        Id nwlCaseId = caseId(NWL_AWS_ID);
        Further_Information_Requested__c rec = fir(nwlCaseId, 'Applicant', 'Insert test');

        Test.startTest();
        insert rec;   // after insert trigger publishes the event
        Test.stopTest();

        Assert.areEqual(1, FurtherInfoRequestedEventPublisher.publishedEvents.size());
        Map<String, Object> payload = payloadOf(FurtherInfoRequestedEventPublisher.publishedEvents[0]);
        Assert.areEqual(String.valueOf(rec.Id), payload.get('firId'),
            'Insert event should carry the new FIR Id');
    }

    @IsTest
    static void testInsertOmitsFirRequestedDeadline() {
        Id nwlCaseId = caseId(NWL_AWS_ID);

        Test.startTest();
        insert fir(nwlCaseId, 'Applicant', 'New request');
        Test.stopTest();

        Map<String, Object> payload = payloadOf(FurtherInfoRequestedEventPublisher.publishedEvents[0]);
        Assert.isFalse(payload.containsKey('FIR_Requested_Deadline'),
            'Insert has no previous deadline to compare');
    }

    @IsTest
    static void testDeadlineChangeAddsFirRequestedDeadline() {
        Id nwlCaseId = caseId(NWL_AWS_ID);
        Further_Information_Requested__c rec = fir(nwlCaseId, 'Applicant', 'Deadline test');
        insert rec;

        // Ignore the event from the insert; only check the update
        FurtherInfoRequestedEventPublisher.publishedEvents.clear();
        Date newDeadline = Date.today().addDays(30);

        Test.startTest();
        rec.Further_Information_Requested_Deadline__c = newDeadline;
        update rec;
        Test.stopTest();

        Assert.areEqual(1, FurtherInfoRequestedEventPublisher.publishedEvents.size());
        Map<String, Object> payload = payloadOf(FurtherInfoRequestedEventPublisher.publishedEvents[0]);
        Assert.areEqual(String.valueOf(rec.Id), payload.get('firId'),
            'Update event should carry the same FIR Id');
        Assert.isTrue(payload.containsKey('FIR_Requested_Deadline'),
            'Changed deadline should be sent');
        Assert.areEqual(String.valueOf(newDeadline), payload.get('FIR_Requested_Deadline'));
    }

    @IsTest
    static void testUpdateWithoutDeadlineChangeOmitsFirRequestedDeadline() {
        Id nwlCaseId = caseId(NWL_AWS_ID);
        Further_Information_Requested__c rec = fir(nwlCaseId, 'Applicant', 'Before');
        insert rec;

        FurtherInfoRequestedEventPublisher.publishedEvents.clear();

        Test.startTest();
        rec.Additional_Information_Required__c = 'After';   // deadline unchanged
        update rec;
        Test.stopTest();

        Assert.areEqual(1, FurtherInfoRequestedEventPublisher.publishedEvents.size(),
            'Updates still publish');
        Map<String, Object> payload = payloadOf(FurtherInfoRequestedEventPublisher.publishedEvents[0]);
        Assert.isFalse(payload.containsKey('FIR_Requested_Deadline'),
            'Unchanged deadline should not be sent');
    }

    @IsTest
    static void testDeadlineClearedSendsNullFirRequestedDeadline() {
        Id nwlCaseId = caseId(NWL_AWS_ID);
        Further_Information_Requested__c rec = fir(nwlCaseId, 'Applicant', 'Clear deadline');
        insert rec;

        FurtherInfoRequestedEventPublisher.publishedEvents.clear();

        Test.startTest();
        rec.Further_Information_Requested_Deadline__c = null;   // deadline removed
        update rec;
        Test.stopTest();

        Map<String, Object> payload = payloadOf(FurtherInfoRequestedEventPublisher.publishedEvents[0]);
        Assert.isTrue(payload.containsKey('FIR_Requested_Deadline'),
            'Clearing the deadline is a change, so the key is sent');
        Assert.isNull(payload.get('FIR_Requested_Deadline'));
    }

    // ------------------------------------------------------------------
    // Bulk and failure handling
    // ------------------------------------------------------------------
    @IsTest
    static void testBulkMixedApplications() {
        Id nwlCaseId = caseId(NWL_AWS_ID);
        Id s37CaseId = caseId(S37_AWS_ID);

        List<Further_Information_Requested__c> recs = new List<Further_Information_Requested__c>();
        for (Integer i = 0; i < 200; i++) {
            recs.add(fir(Math.mod(i, 2) == 0 ? nwlCaseId : s37CaseId, 'Applicant', 'Msg ' + i));
        }

        Test.startTest();
        FurtherInfoRequestedEventPublisher.publishEvents(recs, null);
        Test.stopTest();

        Assert.areEqual(200, FurtherInfoRequestedEventPublisher.publishedEvents.size());
    }

    @IsTest
    static void testPublishFailureIsHandled() {
        Id nwlCaseId = caseId(NWL_AWS_ID);
        String tooLong = 'X'.repeat(300);

        Test.startTest();
        FurtherInfoRequestedEventPublisher.publishEvents(
            new List<Further_Information_Requested__c>{ fir(nwlCaseId, tooLong, 'Will fail') },
            null
        );
        Test.stopTest();

        Assert.areEqual(1, FurtherInfoRequestedEventPublisher.publishedEvents.size());
    }

    // ------------------------------------------------------------------
    // buildPayload
    // ------------------------------------------------------------------
    @IsTest
    static void testBuildPayloadWithNullValues() {
        Further_Information_Requested__c rec = new Further_Information_Requested__c();

        String json = FurtherInfoRequestedEventPublisher.buildPayload(rec);
        Map<String, Object> payload = (Map<String, Object>) System.JSON.deserializeUntyped(json);

        Assert.isTrue(payload.containsKey('firId'));
        Assert.isTrue(payload.containsKey('requestId'));
        Assert.isTrue(payload.containsKey('responseDueDate'));
        Assert.isTrue(payload.containsKey('message'));
        Assert.isFalse(payload.containsKey('FIR_Requested_Deadline'));
        Assert.isNull(payload.get('firId'));
        Assert.isNull(payload.get('responseDueDate'));
        Assert.isNull(payload.get('message'));
    }

    @IsTest
    static void testBuildPayloadWithOldRecordDeadlineChanged() {
        Further_Information_Requested__c oldRec = new Further_Information_Requested__c(
            Further_Information_Requested_Deadline__c = Date.newInstance(2026, 12, 1)
        );
        Further_Information_Requested__c newRec = new Further_Information_Requested__c(
            Further_Information_Requested_Deadline__c = Date.newInstance(2026, 12, 15)
        );

        String json = FurtherInfoRequestedEventPublisher.buildPayload(newRec, oldRec);
        Map<String, Object> payload = (Map<String, Object>) System.JSON.deserializeUntyped(json);

        Assert.areEqual('2026-12-15', payload.get('FIR_Requested_Deadline'));
    }
}