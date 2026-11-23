/**
 * Tests for InboundForm_ProfileUpdateNotifier (SYEIA-2040 AC3 / AC4 team notification emails),
 * driven end to end through InboundForm_Processor with PROFILE_UPDATE payloads.
 */
@IsTest
private class InboundForm_ProfileUpdateNotifierTest {

    private static final String EMAIL = 'sagar.kumar@ics.gov.uk';
    private static final String PERSONAL_ID = 'c69ad059-1c05-496c-ba0f-6f1120c6c994';

    private static final String NWL_INBOX = 'nwl-team@example.com';
    private static final String S37_INBOX = 's37-team@example.com';
    private static final String CPO_INBOX = 'cpo-team@example.com';

    private static final Id INDIVIDUAL_RT = Schema.SObjectType.Party__c
        .getRecordTypeInfosByDeveloperName().get('Individual').getRecordTypeId();
    private static final Id ORGANISATION_RT = Schema.SObjectType.Party__c
        .getRecordTypeInfosByDeveloperName().get('Organisation').getRecordTypeId();

    // ========================================================================
    // TEST DATA
    // ========================================================================

    /**
     * The same applicant contact on two NWL applications. Each application has its own
     * Individual contact party and Organisation (applicant) party, as the inbound forms create them.
     */
    @TestSetup
    static void setup() {
        createApplication('NWL00001', 'Necessary Wayleaves', 'Under Review');
        createApplication('NWL00002', 'Necessary Wayleaves', 'In-Progress');
    }

    private static Case__c createApplication(String reference, String caseType, String status) {
        CaseTriggerHelper.disableProcessing();
        Case__c application = new Case__c(Name = reference, Case_Type__c = caseType, Status__c = status);
        insert application;

        Party__c contact = new Party__c(
            RecordTypeId = INDIVIDUAL_RT,
            Case__c = application.Id,
            Name = 'Sagar Kumar',
            First_Name__c = 'Sagar',
            Last_Name__c = 'Kumar',
            Email__c = EMAIL,
            Party_Type__c = 'Representative'
        );
        insert contact;

        Party__c organisation = new Party__c(
            RecordTypeId = ORGANISATION_RT,
            Case__c = application.Id,
            Name = 'test agency',
            Email__c = EMAIL,
            Party_Type__c = 'DNO',
            Representative__c = contact.Id
        );
        insert organisation;

        application.DNO__c = organisation.Id;
        update application;
        CaseTriggerHelper.enableProcessing();

        insert new Address__c(Party__c = organisation.Id, Case__c = application.Id, Address_Line1__c = 'old line 1');
        return application;
    }

    private static Profile_Update_Notification__mdt config(
            String developerName, String caseTypes, String teamName, String recipient, Boolean active) {
        // Custom metadata can't be inserted in tests - build the records in memory
        return (Profile_Update_Notification__mdt) JSON.deserialize(JSON.serialize(new Map<String, Object>{
            'attributes' => new Map<String, Object>{ 'type' => 'Profile_Update_Notification__mdt' },
            'DeveloperName' => developerName,
            'Case_Types__c' => caseTypes,
            'Team_Name__c' => teamName,
            'Recipient_Email__c' => recipient,
            'Active__c' => active
        }), Profile_Update_Notification__mdt.class);
    }

    private static void useTestTeams() {
        InboundForm_ProfileUpdateNotifier.configOverride = new List<Profile_Update_Notification__mdt>{
            config('Section_37', 'Section 37', 'Section 37 Team', S37_INBOX, true),
            config('Necessary_Wayleaves', 'Necessary Wayleaves;Tree Lopping', 'Necessary Wayleaves Team', NWL_INBOX, true),
            config('Compulsory_Purchase_Order', 'Compulsory Purchase Order', 'Compulsory Purchase Order Team', CPO_INBOX, true)
        };
    }

    private static String lastNameUpdateJson(String newLast) {
        return '{"email":"' + EMAIL + '","source":"ApplicantPortal","eventType":"PROFILE_UPDATE",'
            + '"changes":{"lastName":{"newValue":"' + newLast + '","oldValue":"Kumar"}},'
            + '"changedFields":["lastName"],"personalIdentifier":"' + PERSONAL_ID + '"}';
    }

    private static Map<Id, InboundForm_Processor.ProcessingResult> process(List<String> payloads) {
        List<Inbound_Request__c> requests = new List<Inbound_Request__c>();
        for (String payload : payloads) {
            requests.add(new Inbound_Request__c(Payload__c = payload, Status__c = 'Received'));
        }
        InboundRequestTriggerHelper.disableProcessing();
        insert requests;
        InboundRequestTriggerHelper.enableProcessing();

        InboundForm_Processor.clearAllCaches();
        InboundForm_ConfigRegistry.clearCache();

        Test.startTest();
        Map<Id, InboundForm_Processor.ProcessingResult> results = InboundForm_Processor.processRequests(requests);
        Test.stopTest();
        return results;
    }

    private static InboundForm_Processor.ProcessingResult processSingle(String payload) {
        return process(new List<String>{ payload }).values()[0];
    }

    private static List<Messaging.SingleEmailMessage> emails() {
        return InboundForm_ProfileUpdateNotifier.lastEmails;
    }

    private static Messaging.SingleEmailMessage emailTo(String inbox) {
        for (Messaging.SingleEmailMessage email : emails()) {
            if (email.getToAddresses()[0] == inbox) {
                return email;
            }
        }
        return null;
    }

    // ========================================================================
    // AC3 - single notification to the right team
    // ========================================================================

    @IsTest
    static void testNameChange_SendsOneEmailForAllCasesOfTheTeam() {
        useTestTeams();

        InboundForm_Processor.ProcessingResult result = processSingle(lastNameUpdateJson('Kumar AG'));

        Assert.isTrue(result.success, 'Profile update should succeed: ' + result.errors);
        Assert.areEqual(1, emails().size(), 'Two NWL cases must produce ONE email, not one per case');
        Assert.areEqual(new List<String>{ NWL_INBOX }, emails()[0].getToAddresses());
    }

    @IsTest
    static void testEmailContent_MatchesAc4() {
        useTestTeams();

        processSingle(lastNameUpdateJson('Kumar AG'));

        Messaging.SingleEmailMessage email = emails()[0];
        Assert.areEqual('SYEIA applicant contact profile has changed', email.getSubject());
        Assert.areEqual(
            'Dear Necessary Wayleaves Team\n\n'
                + 'The applicant contact Sagar Kumar AG for test agency has changed their profile information '
                + 'for their Submit Your Energy Application Infrastructure (SYEIA) service account.\n\n'
                + 'All draft letters addressed to them must be updated to show their new profile information.\n\n'
                + 'Do not reply to this email.',
            email.getPlainTextBody(),
            'Body must match the agreed wording, using the updated name');
        Assert.areEqual('SYEIA', email.getSenderDisplayName(), 'No org-wide sender configured');
        Assert.isFalse(email.getSaveAsActivity());
    }

    @IsTest
    static void testCasesOfTwoTeams_SendOneEmailPerTeam() {
        useTestTeams();
        createApplication('S3700001', 'Section 37', 'Under Review');

        processSingle(lastNameUpdateJson('Kumar AG'));

        Assert.areEqual(2, emails().size(), 'One email per team');
        Assert.isNotNull(emailTo(NWL_INBOX));
        Messaging.SingleEmailMessage s37Email = emailTo(S37_INBOX);
        Assert.isNotNull(s37Email);
        Assert.isTrue(s37Email.getPlainTextBody().startsWith('Dear Section 37 Team'));
    }

    @IsTest
    static void testTreeLopping_GoesToNecessaryWayleavesTeam() {
        useTestTeams();
        delete [SELECT Id FROM Case__c];
        createApplication('TRL00001', 'Tree Lopping', 'Under Review');

        processSingle(lastNameUpdateJson('Kumar AG'));

        Assert.areEqual(1, emails().size());
        Assert.areEqual(NWL_INBOX, emails()[0].getToAddresses()[0]);
    }

    @IsTest
    static void testAddressAndTitleChanges_AlsoNotify() {
        useTestTeams();

        process(new List<String>{
            '{"email":"' + EMAIL + '","eventType":"PROFILE_UPDATE",'
                + '"changes":{"workAddress":{"newValue":{"line1":"new line 1","postcode":"LS8 1AA"}}}}',
            '{"email":"' + EMAIL + '","eventType":"PROFILE_UPDATE",'
                + '"changes":{"title":{"newValue":"Dr","oldValue":null}}}'
        });

        Assert.areEqual(2, emails().size(), 'Each profile update notifies once');
    }

    // ========================================================================
    // NO NOTIFICATION
    // ========================================================================

    @IsTest
    static void testPersonalIdentifierOnlyUpdate_DoesNotNotify() {
        useTestTeams();

        processSingle('{"email":"' + EMAIL + '","eventType":"PROFILE_UPDATE","changes":{},'
            + '"personalIdentifier":"' + PERSONAL_ID + '"}');

        Assert.areEqual(0, emails().size(), 'Only name, title or address changes are notified');
    }

    @IsTest
    static void testNoActualChange_DoesNotNotify() {
        useTestTeams();

        processSingle(lastNameUpdateJson('Kumar')); // same as current

        Assert.areEqual(0, emails().size());
    }

    @IsTest
    static void testClosedCasesOnly_DoesNotNotify() {
        useTestTeams();
        CaseTriggerHelper.disableProcessing();
        List<Case__c> cases = [SELECT Id FROM Case__c];
        for (Case__c c : cases) {
            c.Status__c = 'Archived';
        }
        update cases;
        CaseTriggerHelper.enableProcessing();

        InboundForm_Processor.ProcessingResult result = processSingle(lastNameUpdateJson('Kumar AG'));

        Assert.isTrue(result.success, 'Profile is still updated: ' + result.errors);
        Assert.areEqual(0, emails().size(), 'Closed / archived cases are not notified');
    }

    @IsTest
    static void testInactiveOrMissingTeam_DoesNotNotify() {
        InboundForm_ProfileUpdateNotifier.configOverride = new List<Profile_Update_Notification__mdt>{
            config('Necessary_Wayleaves', 'Necessary Wayleaves', 'Necessary Wayleaves Team', NWL_INBOX, false),
            config('Section_37', 'Section 37', 'Section 37 Team', S37_INBOX, true)
        };

        processSingle(lastNameUpdateJson('Kumar AG'));

        Assert.areEqual(0, emails().size(), 'Inactive team, and no team for the case type, sends nothing');
    }

    @IsTest
    static void testNotifyWithNothingToSend() {
        Assert.areEqual(0, InboundForm_ProfileUpdateNotifier.notify(null));
        Assert.areEqual(0, InboundForm_ProfileUpdateNotifier.notify(
            new List<InboundForm_ProfileUpdateNotifier.Notification>()));
    }

    // ========================================================================
    // CONFIGURATION
    // ========================================================================

    @IsTest
    static void testDeployedConfiguration_IsUsedWhenNoOverride() {
        Profile_Update_Notification__mdt nwlTeam = Profile_Update_Notification__mdt.getInstance('Necessary_Wayleaves');
        Assert.isNotNull(nwlTeam, 'Necessary_Wayleaves record should be deployed');

        processSingle(lastNameUpdateJson('Kumar AG'));

        if (nwlTeam.Active__c) {
            Assert.areEqual(1, emails().size());
            Assert.areEqual(nwlTeam.Recipient_Email__c, emails()[0].getToAddresses()[0]);
            Assert.isTrue(emails()[0].getPlainTextBody().startsWith('Dear ' + nwlTeam.Team_Name__c));
        } else {
            Assert.areEqual(0, emails().size());
        }
    }
}
