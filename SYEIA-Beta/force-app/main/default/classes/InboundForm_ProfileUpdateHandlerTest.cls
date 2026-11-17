/**
 * Tests for Applicant Portal PROFILE_UPDATE processing
 * (InboundForm_ProfileUpdateConfig, InboundForm_ProfileUpdateHandler, InboundForm_Processor routing).
 */
@IsTest
private class InboundForm_ProfileUpdateHandlerTest {

    private static final String EMAIL = 'sagar.kumar@ics.gov.uk';
    private static final String PERSONAL_ID = 'c69ad059-1c05-496c-ba0f-6f1120c6c994';

    private static final Id INDIVIDUAL_RT = Schema.SObjectType.Party__c
        .getRecordTypeInfosByDeveloperName().get('Individual').getRecordTypeId();
    private static final Id ORGANISATION_RT = Schema.SObjectType.Party__c
        .getRecordTypeInfosByDeveloperName().get('Organisation').getRecordTypeId();

    // ========================================================================
    // TEST DATA
    // ========================================================================

    /**
     * Mirrors what the NWL form creates: an Organisation party (with an Address__c) and an
     * Individual contact party, both sharing the applicant email.
     */
    @TestSetup
    static void setup() {
        CaseTriggerHelper.disableProcessing();
        Case__c existingCase = new Case__c(
            Name = 'NWL09999',
            Status__c = 'New',
            AWS_Application_Id__c = 'a3d42bff-058d-4e82-9e87-dda5867da7ef'
        );
        insert existingCase;
        CaseTriggerHelper.enableProcessing();

        Party__c individual = new Party__c(
            RecordTypeId = INDIVIDUAL_RT,
            Case__c = existingCase.Id,
            Name = 'Sagar Kumar',
            First_Name__c = 'Sagar',
            Last_Name__c = 'Kumar',
            Email__c = EMAIL,
            Party_Type__c = 'Representative'
        );
        Party__c organisation = new Party__c(
            RecordTypeId = ORGANISATION_RT,
            Case__c = existingCase.Id,
            Name = 'test agency',
            Email__c = EMAIL,
            Party_Type__c = 'DNO'
        );
        insert new List<Party__c>{ individual, organisation };

        insert new Address__c(
            Party__c = organisation.Id,
            Case__c = existingCase.Id,
            Address_Line1__c = 'test address',
            Address_Line_2__c = 'address line 2',
            Town_City__c = 'town int',
            County__c = 'county',
            Postcode__c = 'M11AA',
            Country__c = 'United Kingdom'
        );
    }

    private static String nameUpdateJson(String email, String oldLast, String newLast) {
        return '{' +
            '"email":"' + email + '",' +
            '"source":"ApplicantPortal",' +
            '"changes":{"lastName":{"newValue":"' + newLast + '","oldValue":"' + oldLast + '"}},' +
            '"eventId":"0c4fe81e-fdc6-4d06-9c36-6a373528750a",' +
            '"eventType":"PROFILE_UPDATE",' +
            '"occurredAt":"2026-11-13T11:55:21.477Z",' +
            '"changedFields":["lastName"],' +
            '"correlationId":"10cf27ea-48c7-474e-90a6-655716794768",' +
            '"organisationId":"33333333-3333-3333-3333-333333333333",' +
            '"profileVersion":6,' +
            '"personalIdentifier":"' + PERSONAL_ID + '"' +
        '}';
    }

    private static String firstNameUpdateJson(String oldFirst, String newFirst) {
        return '{' +
            '"email":"' + EMAIL + '",' +
            '"changes":{"firstName":{"newValue":"' + newFirst + '","oldValue":"' + oldFirst + '"}},' +
            '"eventType":"PROFILE_UPDATE",' +
            '"changedFields":["firstName"],' +
            '"personalIdentifier":"' + PERSONAL_ID + '"' +
        '}';
    }

    private static String addressUpdateJson() {
        return addressUpdateJson(
            '{"line1":"test address line 1","line2":"test address line 2",' +
            '"county":"test county","postcode":"LS8 1AA","townCity":"test town or city"}'
        );
    }

    private static String addressUpdateJson(String newValueJson) {
        return '{' +
            '"email":"' + EMAIL + '",' +
            '"source":"ApplicantPortal",' +
            '"changes":{"workAddress":{' +
                '"newValue":' + newValueJson + ',' +
                '"oldValue":{"line1":"test address","line2":"address line 2",' +
                    '"county":"county","postcode":"M11AA","townCity":"town int"}' +
            '}},' +
            '"eventId":"fd2a43d3-674a-4663-8dd6-c83e3b24f19f",' +
            '"eventType":"PROFILE_UPDATE",' +
            '"occurredAt":"2026-11-13T11:56:09.162Z",' +
            '"changedFields":["workAddress.line1","workAddress.line2","workAddress.townCity",' +
                '"workAddress.county","workAddress.postcode"],' +
            '"correlationId":"fd888d24-630d-4e67-afc5-24f67bd58563",' +
            '"organisationId":"33333333-3333-3333-3333-333333333333",' +
            '"profileVersion":7,' +
            '"personalIdentifier":"' + PERSONAL_ID + '"' +
        '}';
    }

    /**
     * Insert requests with the trigger disabled, then run the processor directly
     * (avoids the trigger processing the same payload a second time).
     */
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

    private static Party__c getParty(Id recordTypeId) {
        return [
            SELECT Id, Name, First_Name__c, Last_Name__c, Person_Identification__c
            FROM Party__c
            WHERE RecordTypeId = :recordTypeId AND Email__c = :EMAIL
            LIMIT 1
        ];
    }

    private static List<Address__c> getAddresses(Id partyId) {
        return [
            SELECT Id, Case__c, Address_Line1__c, Address_Line_2__c, Town_City__c, County__c,
                   Postcode__c, Country__c
            FROM Address__c
            WHERE Party__c = :partyId
        ];
    }

    private static Integer countAddresses() {
        return [SELECT COUNT() FROM Address__c];
    }

    // ========================================================================
    // NAME UPDATE
    // ========================================================================

    @IsTest
    static void testLastNameUpdate_UpdatesFirstLastAndName() {
        InboundForm_Processor.ProcessingResult result = processSingle(nameUpdateJson(EMAIL, 'Kumar', 'Kumar AG'));

        Assert.isTrue(result.success, 'Name update should succeed: ' + result.errors);
        Assert.areEqual(InboundForm_ProfileUpdateConfig.FORM_TYPE, result.formType);

        Party__c individual = getParty(INDIVIDUAL_RT);
        Assert.areEqual('Sagar', individual.First_Name__c, 'First name should be preserved');
        Assert.areEqual('Kumar AG', individual.Last_Name__c, 'Last name should be updated');
        Assert.areEqual('Sagar Kumar AG', individual.Name, 'Name should be rebuilt from first + last');
        Assert.areEqual(PERSONAL_ID, individual.Person_Identification__c);

        Party__c organisation = getParty(ORGANISATION_RT);
        Assert.areEqual('test agency', organisation.Name, 'Organisation Name must not change on a person name update');
        Assert.areEqual(PERSONAL_ID, organisation.Person_Identification__c);

        Assert.areEqual(1, countAddresses(), 'Name update must not touch addresses');
    }

    @IsTest
    static void testFirstNameUpdate_UpdatesFirstLastAndName() {
        InboundForm_Processor.ProcessingResult result = processSingle(firstNameUpdateJson('Sagar', 'Sagar J'));

        Assert.isTrue(result.success, 'First name update should succeed: ' + result.errors);
        Party__c individual = getParty(INDIVIDUAL_RT);
        Assert.areEqual('Sagar J', individual.First_Name__c);
        Assert.areEqual('Kumar', individual.Last_Name__c, 'Last name should be preserved');
        Assert.areEqual('Sagar J Kumar', individual.Name);
    }

    @IsTest
    static void testLastNameUpdate_DerivesFirstAndLastWhenOnlyNamePopulated() {
        Party__c individual = getParty(INDIVIDUAL_RT);
        individual.First_Name__c = null;
        individual.Last_Name__c = null;
        individual.Name = 'Sagar Ravi Kumar';
        update individual;

        InboundForm_Processor.ProcessingResult result = processSingle(nameUpdateJson(EMAIL, 'Kumar', 'Kumar AG'));

        Assert.isTrue(result.success, 'Name update should succeed: ' + result.errors);
        individual = getParty(INDIVIDUAL_RT);
        Assert.areEqual('Sagar Ravi', individual.First_Name__c, 'First name derived from Name using oldValue');
        Assert.areEqual('Kumar AG', individual.Last_Name__c);
        Assert.areEqual('Sagar Ravi Kumar AG', individual.Name);
    }

    @IsTest
    static void testNameUpdate_CaseOnlyChangeIsApplied() {
        InboundForm_Processor.ProcessingResult result = processSingle(nameUpdateJson(EMAIL, 'Kumar', 'KUMAR'));

        Assert.isTrue(result.success, 'Name update should succeed: ' + result.errors);
        Assert.isFalse(result.hasWarnings(), 'Case-only change must be detected as a change: ' + result.warnings);
        Party__c individual = getParty(INDIVIDUAL_RT);
        Assert.isTrue('KUMAR'.equals(individual.Last_Name__c), 'Case-only change should be saved');
        Assert.isTrue('Sagar KUMAR'.equals(individual.Name), 'Name should reflect case-only change');
    }

    @IsTest
    static void testNameUpdate_WarnsWhenNoIndividualParty() {
        delete [SELECT Id FROM Party__c WHERE RecordTypeId = :INDIVIDUAL_RT];

        InboundForm_Processor.ProcessingResult result = processSingle(nameUpdateJson(EMAIL, 'Kumar', 'Kumar AG'));

        Assert.isTrue(result.success, 'Should still succeed (personal identifier applied): ' + result.errors);
        Assert.isTrue(String.join(result.warnings, ' ').contains('Name change ignored'));
        Assert.areEqual('test agency', getParty(ORGANISATION_RT).Name, 'Organisation Name must not change');
    }

    @IsTest
    static void testEmailMatchIsCaseInsensitive() {
        InboundForm_Processor.ProcessingResult result =
            processSingle(nameUpdateJson('Sagar.Kumar@ICS.gov.uk', 'Kumar', 'Kumar AG'));

        Assert.isTrue(result.success, 'Email matching should be case-insensitive: ' + result.errors);
        Assert.areEqual('Kumar AG', getParty(INDIVIDUAL_RT).Last_Name__c);
    }

    // ========================================================================
    // ADDRESS UPDATE (Address__c)
    // ========================================================================

    @IsTest
    static void testAddressUpdate_UpdatesExistingAddress() {
        InboundForm_Processor.ProcessingResult result = processSingle(addressUpdateJson());

        Assert.isTrue(result.success, 'Address update should succeed: ' + result.errors);
        Assert.areEqual(1, countAddresses(), 'Existing address should be updated, not duplicated');

        Address__c address = getAddresses(getParty(ORGANISATION_RT).Id)[0];
        Assert.areEqual('test address line 1', address.Address_Line1__c);
        Assert.areEqual('test address line 2', address.Address_Line_2__c);
        Assert.areEqual('test town or city', address.Town_City__c);
        Assert.areEqual('test county', address.County__c);
        Assert.areEqual('LS8 1AA', address.Postcode__c);
        Assert.areEqual('United Kingdom', address.Country__c, 'Country__c must not be touched');

        Party__c individual = getParty(INDIVIDUAL_RT);
        Assert.areEqual('Sagar Kumar', individual.Name, 'Name should not change on address update');
        Assert.areEqual(PERSONAL_ID, individual.Person_Identification__c);
    }

    @IsTest
    static void testAddressUpdate_CreatesAddressWhenNoneExist() {
        delete [SELECT Id FROM Address__c];

        InboundForm_Processor.ProcessingResult result = processSingle(addressUpdateJson());

        Assert.isTrue(result.success, 'Address update should succeed: ' + result.errors);
        Assert.areEqual(1, countAddresses(), 'Exactly one address should be created');

        Party__c individual = [SELECT Id, Case__c FROM Party__c WHERE RecordTypeId = :INDIVIDUAL_RT LIMIT 1];
        List<Address__c> addresses = getAddresses(individual.Id);
        Assert.areEqual(1, addresses.size(), 'New address should be linked to the Individual party');
        Assert.areEqual(individual.Case__c, addresses[0].Case__c, 'New address should carry the party Case');
        Assert.areEqual('test address line 1', addresses[0].Address_Line1__c);
        Assert.areEqual('LS8 1AA', addresses[0].Postcode__c);
    }

    @IsTest
    static void testAddressUpdate_UpdatesEveryLinkedAddress() {
        Party__c individual = getParty(INDIVIDUAL_RT);
        insert new Address__c(Party__c = individual.Id, Address_Line1__c = 'old individual address');

        InboundForm_Processor.ProcessingResult result = processSingle(addressUpdateJson());

        Assert.isTrue(result.success, 'Address update should succeed: ' + result.errors);
        Assert.areEqual(2, countAddresses());
        for (Address__c address : [SELECT Address_Line1__c, Postcode__c FROM Address__c]) {
            Assert.areEqual('test address line 1', address.Address_Line1__c);
            Assert.areEqual('LS8 1AA', address.Postcode__c);
        }
    }

    @IsTest
    static void testAddressUpdate_OnlyProvidedKeysAreWritten() {
        InboundForm_Processor.ProcessingResult result =
            processSingle(addressUpdateJson('{"postcode":"LS8 1AA","line2":null}'));

        Assert.isTrue(result.success, 'Partial address update should succeed: ' + result.errors);
        Address__c address = getAddresses(getParty(ORGANISATION_RT).Id)[0];
        Assert.areEqual('LS8 1AA', address.Postcode__c, 'Provided key should be written');
        Assert.isNull(address.Address_Line_2__c, 'Explicit null should clear the field');
        Assert.areEqual('test address', address.Address_Line1__c, 'Missing key should be left unchanged');
        Assert.areEqual('town int', address.Town_City__c, 'Missing key should be left unchanged');
    }

    @IsTest
    static void testAddressUpdate_MissingNewValueWarns() {
        InboundForm_Processor.ProcessingResult result = processSingle(addressUpdateJson('null'));

        Assert.isTrue(result.success, 'Should still succeed (personal identifier applied): ' + result.errors);
        Assert.isTrue(String.join(result.warnings, ' ').contains('Work address change ignored'));
        Assert.areEqual('test address', getAddresses(getParty(ORGANISATION_RT).Id)[0].Address_Line1__c);
    }

    @IsTest
    static void testAddressUpdate_TwoEventsInBatchCreateSingleAddress() {
        delete [SELECT Id FROM Address__c];

        Map<Id, InboundForm_Processor.ProcessingResult> results = process(new List<String>{
            addressUpdateJson(),
            addressUpdateJson('{"line1":"second line 1","postcode":"LS1 1AA"}')
        });

        for (InboundForm_Processor.ProcessingResult result : results.values()) {
            Assert.isTrue(result.success, 'Every event should succeed: ' + result.errors);
        }
        Assert.areEqual(1, countAddresses(), 'Second event should update the address created by the first');

        Address__c address = [SELECT Address_Line1__c, Address_Line_2__c, Postcode__c FROM Address__c LIMIT 1];
        Assert.areEqual('second line 1', address.Address_Line1__c, 'Later event should win');
        Assert.areEqual('LS1 1AA', address.Postcode__c);
        Assert.areEqual('test address line 2', address.Address_Line_2__c, 'Earlier value kept for keys not resent');
    }

    // ========================================================================
    // PERSONAL IDENTIFIER
    // ========================================================================

    @IsTest
    static void testPersonalIdentifier_NotOverwrittenWhenPopulated() {
        Party__c individual = getParty(INDIVIDUAL_RT);
        individual.Person_Identification__c = 'EXISTING-ID';
        update individual;

        InboundForm_Processor.ProcessingResult result = processSingle(addressUpdateJson());

        Assert.isTrue(result.success, 'Address update should succeed: ' + result.errors);
        Assert.areEqual('EXISTING-ID', getParty(INDIVIDUAL_RT).Person_Identification__c,
            'Existing Person_Identification__c must not be overwritten');
        Assert.areEqual(PERSONAL_ID, getParty(ORGANISATION_RT).Person_Identification__c,
            'Blank Person_Identification__c should be populated');
    }

    // ========================================================================
    // BULK / ORDERING
    // ========================================================================

    @IsTest
    static void testNameAndAddressEventsInOneBatch() {
        Map<Id, InboundForm_Processor.ProcessingResult> results = process(new List<String>{
            nameUpdateJson(EMAIL, 'Kumar', 'Kumar AG'),
            addressUpdateJson()
        });

        for (InboundForm_Processor.ProcessingResult result : results.values()) {
            Assert.isTrue(result.success, 'Every event should succeed: ' + result.errors);
        }

        Party__c individual = getParty(INDIVIDUAL_RT);
        Assert.areEqual('Sagar Kumar AG', individual.Name);
        Assert.areEqual('Kumar AG', individual.Last_Name__c);
        Assert.areEqual('LS8 1AA', getAddresses(getParty(ORGANISATION_RT).Id)[0].Postcode__c);
    }

    // ========================================================================
    // OUT OF SCOPE / FAILURES
    // ========================================================================

    @IsTest
    static void testAgencyNameChange_IsIgnored() {
        InboundForm_Processor.ProcessingResult result = processSingle(
            '{"eventType":"PROFILE_UPDATE","email":"' + EMAIL + '",' +
            '"changes":{"agencyName":{"newValue":"test agency AG","oldValue":"test agency"}},' +
            '"personalIdentifier":"' + PERSONAL_ID + '"}');

        Assert.isTrue(result.success, 'Out-of-scope keys should not fail the event: ' + result.errors);
        Assert.isTrue(String.join(result.warnings, ' ').contains('Unsupported profile change ignored: agencyName'));
        Assert.areEqual('test agency', getParty(ORGANISATION_RT).Name, 'Agency name must not be applied');
        Assert.areEqual('Sagar Kumar', getParty(INDIVIDUAL_RT).Name);
    }

    @IsTest
    static void testNoMatchingParty_Fails() {
        InboundForm_Processor.ProcessingResult result =
            processSingle(nameUpdateJson('nobody@example.com', 'Kumar', 'Kumar AG'));

        Assert.isFalse(result.success, 'Should fail when no Party__c matches the email');
        Assert.isTrue(result.errors[0].contains('No Party__c records found'), result.errors[0]);
        Assert.areEqual('Kumar', getParty(INDIVIDUAL_RT).Last_Name__c, 'No records should change');
    }

    @IsTest
    static void testMissingEmail_FailsValidation() {
        InboundForm_Processor.ProcessingResult result =
            processSingle('{"eventType":"PROFILE_UPDATE","changes":{"lastName":{"newValue":"X"}}}');

        Assert.isFalse(result.success, 'Should fail validation without email');
        Assert.isTrue(String.join(result.errors, ' ').contains('email is required'));
    }

    @IsTest
    static void testNoChanges_FailsValidation() {
        InboundForm_Processor.ProcessingResult result =
            processSingle('{"eventType":"PROFILE_UPDATE","email":"' + EMAIL + '","changes":{}}');

        Assert.isFalse(result.success, 'Should fail validation with no changes');
        Assert.isTrue(String.join(result.errors, ' ').contains('no changes'));
    }

    // ========================================================================
    // END TO END (trigger -> processor -> status queueable)
    // ========================================================================

    @IsTest
    static void testTriggerEndToEnd_SetsRequestProcessed() {
        Inbound_Request__c request = new Inbound_Request__c(
            Payload__c = nameUpdateJson(EMAIL, 'Kumar', 'Kumar AG'),
            Status__c = 'Received'
        );

        Test.startTest();
        insert request;
        Test.stopTest();

        Assert.areEqual('Processed',
            [SELECT Status__c FROM Inbound_Request__c WHERE Id = :request.Id].Status__c);
        Assert.areEqual('Sagar Kumar AG', getParty(INDIVIDUAL_RT).Name);
    }

    // ========================================================================
    // UNIT HELPERS
    // ========================================================================

    @IsTest
    static void testIsProfileUpdateEvent() {
        Assert.isTrue(InboundForm_ProfileUpdateConfig.isProfileUpdateEvent('PROFILE_UPDATE'));
        Assert.isTrue(InboundForm_ProfileUpdateConfig.isProfileUpdateEvent('profile-updated'));
        Assert.isFalse(InboundForm_ProfileUpdateConfig.isProfileUpdateEvent('WITHDRAWAL_REQUESTED'));
        Assert.isFalse(InboundForm_ProfileUpdateConfig.isProfileUpdateEvent(null));
    }

    @IsTest
    static void testSplitFullName() {
        List<String> parts = InboundForm_ProfileUpdateHandler.splitFullName('Sagar Kumar', null, 'Kumar');
        Assert.areEqual('Sagar', parts[0]);
        Assert.areEqual('Kumar', parts[1]);

        parts = InboundForm_ProfileUpdateHandler.splitFullName('Sagar Ravi Kumar', 'Sagar', null);
        Assert.areEqual('Sagar', parts[0]);
        Assert.areEqual('Ravi Kumar', parts[1]);

        parts = InboundForm_ProfileUpdateHandler.splitFullName('Kumar', null, 'Kumar');
        Assert.isNull(parts[0]);
        Assert.areEqual('Kumar', parts[1]);

        parts = InboundForm_ProfileUpdateHandler.splitFullName('Sagar  Kumar', null, null);
        Assert.areEqual('Sagar', parts[0]);
        Assert.areEqual('Kumar', parts[1]);
    }
}
