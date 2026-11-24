/**
 * Handles Applicant Portal PROFILE_UPDATE events.
 *
 * Existing Party__c records are matched on Email__c (case-insensitive) and changes apply immediately:
 *   - firstName / lastName -> First_Name__c, Last_Name__c and Name kept in sync (Individual parties)
 *   - title                -> Salutation__c only - Name is not changed (Individual parties)
 *   - workAddress          -> Address__c records linked to the matched parties (Address__c.Party__c).
 *                             Every existing linked address is updated; when none of the matched parties
 *                             has an address, one is created on the Individual party (else first match).
 *   - personalIdentifier   -> Person_Identification__c, only when currently blank (all matched parties)
 *
 * After saving, each update that changed a name, title or address emails the relevant team inbox
 * once (InboundForm_ProfileUpdateNotifier, configured in Profile_Update_Notification__mdt).
 *
 * Invoked by InboundForm_Processor: validate() per request during parsing, then processBulk() once per
 * batch so that SOQL/DML stay constant regardless of the number of inbound requests.
 * See InboundForm_ProfileUpdateConfig for the payload contract.
 */
public inherited sharing class InboundForm_ProfileUpdateHandler {

    // ========================================================================
    // VALIDATION (per request, no SOQL)
    // ========================================================================

    public static List<String> validate(InboundForm_JSONParser parser) {
        List<String> errors = new List<String>();

        if (String.isBlank(parser.getString(InboundForm_ProfileUpdateConfig.EMAIL_PATH))) {
            errors.add('email is required for profile update events');
        }

        Object changes = parser.getValue(InboundForm_ProfileUpdateConfig.CHANGES_PATH);
        if (changes != null && !(changes instanceof Map<String, Object>)) {
            errors.add('changes must be a JSON object for profile update events');
            return errors;
        }

        Boolean hasChanges = changes != null && !((Map<String, Object>) changes).isEmpty();
        Boolean hasPersonalIdentifier = String.isNotBlank(
            parser.getString(InboundForm_ProfileUpdateConfig.PERSONAL_IDENTIFIER_PATH));

        if (!hasChanges && !hasPersonalIdentifier) {
            errors.add('Profile update event contains no changes');
        }

        return errors;
    }

    // ========================================================================
    // BULK PROCESSING
    // ========================================================================

    /**
     * Apply all successfully validated profile update results with one SOQL and at most three DML.
     * Results are applied in the order given, so later events for the same email win.
     */
    public static void processBulk(List<InboundForm_Processor.ProcessingResult> allResults) {
        List<InboundForm_Processor.ProcessingResult> results = new List<InboundForm_Processor.ProcessingResult>();
        for (InboundForm_Processor.ProcessingResult result : allResults) {
            if (result.success
                    && result.parser != null
                    && result.formType == InboundForm_ProfileUpdateConfig.FORM_TYPE) {
                results.add(result);
            }
        }
        if (results.isEmpty()) {
            return;
        }

        try {
            Set<String> emails = new Set<String>();
            for (InboundForm_Processor.ProcessingResult result : results) {
                emails.add(normalizeEmail(getEmail(result.parser)));
            }

            ChangeSet changeSet = new ChangeSet(queryPartiesByEmail(emails));

            for (InboundForm_Processor.ProcessingResult result : results) {
                String email = normalizeEmail(getEmail(result.parser));
                List<Party__c> parties = changeSet.partiesByEmail.get(email);

                if (parties == null || parties.isEmpty()) {
                    result.addError('No Party__c records found with Email__c: ' + email);
                    continue;
                }

                if (!applyChanges(result, parties, changeSet)) {
                    result.addWarning('No Party__c / Address__c fields required updating for email: ' + email);
                }
            }

            changeSet.commitChanges();
            notifyTeams(changeSet.notifications);

        } catch (Exception e) {
            for (InboundForm_Processor.ProcessingResult result : results) {
                result.addError('Profile update failed: ' + e.getMessage() + ' [Line: ' + e.getLineNumber() + ']');
            }
            Logger.error('Profile update failed: ' + e.getMessage());
            Logger.setScenario('InboundForm_ProfileUpdateHandler.processBulk');
        } finally {
            Logger.saveLog();
        }
    }

    /**
     * Email the relevant team inbox(es) once per successful profile update (AC3/AC4).
     * A notification problem never fails the profile update; it is reported as a warning.
     */
    private static void notifyTeams(List<InboundForm_ProfileUpdateNotifier.Notification> notifications) {
        List<InboundForm_ProfileUpdateNotifier.Notification> toSend =
            new List<InboundForm_ProfileUpdateNotifier.Notification>();
        for (InboundForm_ProfileUpdateNotifier.Notification notification : notifications) {
            if (notification.result.success) { // skip updates whose save failed
                toSend.add(notification);
            }
        }
        if (toSend.isEmpty()) {
            return;
        }

        try {
            InboundForm_ProfileUpdateNotifier.notify(toSend);
        } catch (Exception e) {
            for (InboundForm_ProfileUpdateNotifier.Notification notification : toSend) {
                notification.result.addWarning('Team notification failed: ' + e.getMessage());
            }
            Logger.error('Profile update team notification failed: ' + e.getMessage()
                + ' [Line: ' + e.getLineNumber() + ']');
            Logger.setScenario('InboundForm_ProfileUpdateHandler.notifyTeams');
        }
    }

    // ========================================================================
    // CHANGE APPLICATION
    // ========================================================================

    /**
     * Apply one event's changes to the parties matched on its email.
     * Returns true when anything changed.
     */
    private static Boolean applyChanges(
            InboundForm_Processor.ProcessingResult result,
            List<Party__c> parties,
            ChangeSet changeSet) {

        InboundForm_JSONParser parser = result.parser;
        Map<String, Object> changes = getChanges(parser);
        String personalIdentifier = trimToNull(
            parser.getString(InboundForm_ProfileUpdateConfig.PERSONAL_IDENTIFIER_PATH));

        for (String changeKey : changes.keySet()) {
            if (!InboundForm_ProfileUpdateConfig.SUPPORTED_CHANGE_KEYS.contains(changeKey)) {
                result.addWarning('Unsupported profile change ignored: ' + changeKey);
            }
        }

        Boolean hasNameChange = changes.containsKey(InboundForm_ProfileUpdateConfig.FIRST_NAME_KEY)
            || changes.containsKey(InboundForm_ProfileUpdateConfig.LAST_NAME_KEY);

        // Title -> Salutation__c (restricted picklist): resolve once per event; null result = skip
        Boolean hasTitleChange = changes.containsKey(InboundForm_ProfileUpdateConfig.TITLE_KEY);
        SalutationValue salutation = hasTitleChange ? resolveSalutation(changes, result) : null;

        Boolean anyChange = false;
        Boolean individualFound = false;
        // Name / title / address changes are what the team must be told about (not personalIdentifier)
        Boolean profileChanged = false;

        // ----- Party__c fields -----
        for (Party__c party : parties) {
            Boolean isIndividual = party.RecordType?.DeveloperName
                == InboundForm_ProfileUpdateConfig.INDIVIDUAL_RECORD_TYPE;
            individualFound = individualFound || isIndividual;

            Boolean changed = false;
            if (hasNameChange && isIndividual && applyNameChange(party, changes)) {
                changed = true;
                profileChanged = true;
            }
            if (salutation != null && isIndividual && differs(salutation.value, party.Salutation__c)) {
                party.Salutation__c = salutation.value;
                changed = true;
                profileChanged = true;
            }
            if (personalIdentifier != null && String.isBlank(party.Person_Identification__c)) {
                party.Person_Identification__c = personalIdentifier;
                changed = true;
            }

            if (changed) {
                changeSet.markPartyChanged(party, result);
                anyChange = true;
            }
        }

        if (hasNameChange && !individualFound) {
            result.addWarning('Name change ignored: no Individual Party__c found for email');
        }
        if (salutation != null && !individualFound) {
            result.addWarning('Title change ignored: no Individual Party__c found for email');
        }

        // ----- Address__c -----
        if (changes.containsKey(InboundForm_ProfileUpdateConfig.WORK_ADDRESS_KEY)
                && applyWorkAddressChange(result, parties, changes, changeSet)) {
            anyChange = true;
            profileChanged = true;
        }

        if (profileChanged) {
            changeSet.notifications.add(new InboundForm_ProfileUpdateNotifier.Notification(result, parties));
        }

        return anyChange;
    }

    /**
     * Resolved title for Salutation__c. A wrapper so "clear the field" (value = null) can be told
     * apart from "don't update" (no SalutationValue at all).
     */
    private class SalutationValue {
        public final String value;
        public SalutationValue(String value) {
            this.value = value;
        }
    }

    /**
     * Map changes.title.newValue onto an active Salutation__c picklist value, ignoring case and a
     * trailing full stop ("mr." -> "Mr"). A blank title clears the field. A value that isn't in the
     * restricted picklist would fail the whole Party__c save, so it is skipped with a warning.
     */
    private static SalutationValue resolveSalutation(
            Map<String, Object> changes,
            InboundForm_Processor.ProcessingResult result) {

        String title = getChangeValue(
            changes, InboundForm_ProfileUpdateConfig.TITLE_KEY, InboundForm_ProfileUpdateConfig.NEW_VALUE_KEY);
        if (title == null) {
            return new SalutationValue(null);
        }

        String resolved = matchSalutationPicklistValue(title);
        if (resolved == null) {
            result.addWarning('Title change ignored: "' + title + '" is not a valid Salutation value');
            return null;
        }
        return new SalutationValue(resolved);
    }

    @TestVisible
    private static String matchSalutationPicklistValue(String title) {
        String normalized = title.trim().removeEnd('.').trim();
        for (Schema.PicklistEntry entry : Party__c.Salutation__c.getDescribe().getPicklistValues()) {
            if (entry.isActive() && entry.getValue().equalsIgnoreCase(normalized)) {
                return entry.getValue();
            }
        }
        return null;
    }

    /**
     * Keeps First_Name__c, Last_Name__c and Name consistent when either name part changes.
     * When the party only has Name populated, first/last are derived from it first so the
     * unchanged part is preserved.
     */
    @TestVisible
    private static Boolean applyNameChange(Party__c party, Map<String, Object> changes) {
        String firstKey = InboundForm_ProfileUpdateConfig.FIRST_NAME_KEY;
        String lastKey = InboundForm_ProfileUpdateConfig.LAST_NAME_KEY;

        String firstName = trimToNull(party.First_Name__c);
        String lastName = trimToNull(party.Last_Name__c);

        if (firstName == null && lastName == null && String.isNotBlank(party.Name)) {
            List<String> parts = splitFullName(
                party.Name,
                getChangeValue(changes, firstKey, InboundForm_ProfileUpdateConfig.OLD_VALUE_KEY),
                getChangeValue(changes, lastKey, InboundForm_ProfileUpdateConfig.OLD_VALUE_KEY)
            );
            firstName = parts[0];
            lastName = parts[1];
        }

        if (changes.containsKey(firstKey)) {
            firstName = getChangeValue(changes, firstKey, InboundForm_ProfileUpdateConfig.NEW_VALUE_KEY);
        }
        if (changes.containsKey(lastKey)) {
            lastName = getChangeValue(changes, lastKey, InboundForm_ProfileUpdateConfig.NEW_VALUE_KEY);
        }

        String fullName = buildFullName(firstName, lastName);

        Boolean changed = differs(firstName, party.First_Name__c)
            || differs(lastName, party.Last_Name__c)
            || (fullName != null && differs(fullName, party.Name));

        party.First_Name__c = firstName;
        party.Last_Name__c = lastName;
        if (fullName != null) {
            party.Name = fullName;
        }
        return changed;
    }

    /**
     * Writes workAddress.newValue to the Address__c records of the matched parties.
     * Only keys present in newValue are written (an explicit null / "" clears that field);
     * Country__c is not touched.
     */
    private static Boolean applyWorkAddressChange(
            InboundForm_Processor.ProcessingResult result,
            List<Party__c> parties,
            Map<String, Object> changes,
            ChangeSet changeSet) {

        Map<String, Object> change = getChange(changes, InboundForm_ProfileUpdateConfig.WORK_ADDRESS_KEY);
        Object newValue = change != null ? change.get(InboundForm_ProfileUpdateConfig.NEW_VALUE_KEY) : null;
        if (!(newValue instanceof Map<String, Object>)) {
            result.addWarning('Work address change ignored: newValue is missing or not an object');
            return false;
        }
        Map<String, String> fieldValues = toAddressFieldValues((Map<String, Object>) newValue);

        // Existing addresses of every matched party (including ones created earlier in this batch)
        List<Address__c> addresses = new List<Address__c>();
        for (Party__c party : parties) {
            addresses.addAll(changeSet.getAddresses(party.Id));
        }

        Boolean changed = false;

        if (addresses.isEmpty()) {
            if (!hasAnyValue(fieldValues)) {
                return false;
            }
            Party__c owner = pickAddressOwner(parties);
            Address__c newAddress = changeSet.addNewAddress(owner, result);
            applyAddressValues(newAddress, fieldValues);
            return true;
        }

        for (Address__c address : addresses) {
            if (applyAddressValues(address, fieldValues)) {
                changeSet.markAddressChanged(address, result);
                changed = true;
            }
        }
        return changed;
    }

    private static Map<String, String> toAddressFieldValues(Map<String, Object> newValue) {
        Map<String, String> fieldValues = new Map<String, String>();
        for (String jsonKey : InboundForm_ProfileUpdateConfig.ADDRESS_FIELD_MAPPING.keySet()) {
            if (newValue.containsKey(jsonKey)) {
                Object value = newValue.get(jsonKey);
                fieldValues.put(
                    InboundForm_ProfileUpdateConfig.ADDRESS_FIELD_MAPPING.get(jsonKey),
                    value != null ? trimToNull(String.valueOf(value)) : null
                );
            }
        }
        return fieldValues;
    }

    @TestVisible
    private static Boolean applyAddressValues(Address__c address, Map<String, String> fieldValues) {
        Boolean changed = false;
        for (String field : fieldValues.keySet()) {
            String value = fieldValues.get(field);
            if (differs(value, (String) address.get(field))) {
                address.put(field, value);
                changed = true;
            }
        }
        return changed;
    }

    /**
     * Party that receives a new Address__c when none exist: the Individual party, else the first match.
     */
    private static Party__c pickAddressOwner(List<Party__c> parties) {
        for (Party__c party : parties) {
            if (party.RecordType?.DeveloperName == InboundForm_ProfileUpdateConfig.INDIVIDUAL_RECORD_TYPE) {
                return party;
            }
        }
        return parties[0];
    }

    // ========================================================================
    // CHANGE SET - working copies + DML
    // ========================================================================

    /**
     * Holds the queried records, accumulates changes across all events in the batch,
     * and commits them with consolidated DML, attributing failures to the owning results.
     */
    private class ChangeSet {
        public final Map<String, List<Party__c>> partiesByEmail = new Map<String, List<Party__c>>();
        private final Map<Id, List<Address__c>> addressesByPartyId = new Map<Id, List<Address__c>>();

        private final Map<Id, Party__c> changedParties = new Map<Id, Party__c>();
        private final Map<Id, Address__c> changedAddresses = new Map<Id, Address__c>();
        private final List<Address__c> newAddresses = new List<Address__c>();

        private final Map<Id, List<InboundForm_Processor.ProcessingResult>> ownersById =
            new Map<Id, List<InboundForm_Processor.ProcessingResult>>();
        private final List<List<InboundForm_Processor.ProcessingResult>> newAddressOwners =
            new List<List<InboundForm_Processor.ProcessingResult>>();
        // At most one new Address__c per party (only created when the matched parties have none),
        // so new addresses are indexed by party Id - SObjects can't be map keys once mutated.
        private final Map<Id, Integer> newAddressIndexByPartyId = new Map<Id, Integer>();

        // One entry per profile update that changed name / title / address - sent after commit
        public final List<InboundForm_ProfileUpdateNotifier.Notification> notifications =
            new List<InboundForm_ProfileUpdateNotifier.Notification>();

        public ChangeSet(List<Party__c> parties) {
            for (Party__c party : parties) {
                String key = normalizeEmail(party.Email__c);
                if (!partiesByEmail.containsKey(key)) {
                    partiesByEmail.put(key, new List<Party__c>());
                }
                partiesByEmail.get(key).add(party);
                addressesByPartyId.put(party.Id, new List<Address__c>(party.Addresses__r));
            }
        }

        public List<Address__c> getAddresses(Id partyId) {
            List<Address__c> addresses = addressesByPartyId.get(partyId);
            return addresses != null ? addresses : new List<Address__c>();
        }

        public void markPartyChanged(Party__c party, InboundForm_Processor.ProcessingResult owner) {
            changedParties.put(party.Id, party);
            addOwner(party.Id, owner);
        }

        public void markAddressChanged(Address__c address, InboundForm_Processor.ProcessingResult owner) {
            if (address.Id == null) {
                // Address created earlier in this batch - it is already queued for insert
                List<InboundForm_Processor.ProcessingResult> owners =
                    newAddressOwners[newAddressIndexByPartyId.get(address.Party__c)];
                if (!owners.contains(owner)) {
                    owners.add(owner);
                }
                return;
            }
            changedAddresses.put(address.Id, address);
            addOwner(address.Id, owner);
        }

        public Address__c addNewAddress(Party__c party, InboundForm_Processor.ProcessingResult owner) {
            Address__c address = new Address__c(Party__c = party.Id, Case__c = party.Case__c);
            newAddressIndexByPartyId.put(party.Id, newAddresses.size());
            newAddresses.add(address);
            newAddressOwners.add(new List<InboundForm_Processor.ProcessingResult>{ owner });
            addressesByPartyId.get(party.Id).add(address);
            return address;
        }

        public void commitChanges() {
            if (!changedParties.isEmpty()) {
                List<Party__c> records = new List<Party__c>();
                for (Party__c party : changedParties.values()) {
                    records.add(new Party__c(
                        Id = party.Id,
                        Name = party.Name,
                        First_Name__c = party.First_Name__c,
                        Last_Name__c = party.Last_Name__c,
                        Person_Identification__c = party.Person_Identification__c,
                        Salutation__c = party.Salutation__c
                    ));
                }
                handleResults(Database.update(records, false), records, null, 'update Party__c');
            }

            if (!changedAddresses.isEmpty()) {
                List<Address__c> records = new List<Address__c>();
                for (Address__c address : changedAddresses.values()) {
                    Address__c record = new Address__c(Id = address.Id);
                    for (String field : InboundForm_ProfileUpdateConfig.ADDRESS_FIELD_MAPPING.values()) {
                        record.put(field, address.get(field));
                    }
                    records.add(record);
                }
                handleResults(Database.update(records, false), records, null, 'update Address__c');
            }

            if (!newAddresses.isEmpty()) {
                handleResults(Database.insert(newAddresses, false), newAddresses, newAddressOwners, 'create Address__c');
            }

            Logger.info('Applicant profile update: ' + changedParties.size() + ' Party__c updated, '
                + changedAddresses.size() + ' Address__c updated, ' + newAddresses.size() + ' Address__c created');
        }

        private void handleResults(
                Database.SaveResult[] saveResults,
                List<SObject> records,
                List<List<InboundForm_Processor.ProcessingResult>> ownersByIndex,
                String operation) {

            for (Integer i = 0; i < saveResults.size(); i++) {
                if (saveResults[i].isSuccess()) {
                    continue;
                }

                List<String> messages = new List<String>();
                for (Database.Error err : saveResults[i].getErrors()) {
                    messages.add(err.getMessage() + ' [Fields: ' + err.getFields() + ']');
                }
                String message = 'Failed to ' + operation
                    + (records[i].Id != null ? ' ' + records[i].Id : '') + ': ' + String.join(messages, '; ');
                Logger.error(message);

                List<InboundForm_Processor.ProcessingResult> owners = ownersByIndex != null
                    ? ownersByIndex[i]
                    : ownersById.get(records[i].Id);
                for (InboundForm_Processor.ProcessingResult owner : owners) {
                    owner.addError(message);
                }
            }
        }

        private void addOwner(Id recordId, InboundForm_Processor.ProcessingResult owner) {
            if (!ownersById.containsKey(recordId)) {
                ownersById.put(recordId, new List<InboundForm_Processor.ProcessingResult>());
            }
            if (!ownersById.get(recordId).contains(owner)) {
                ownersById.get(recordId).add(owner);
            }
        }
    }

    // ========================================================================
    // HELPERS
    // ========================================================================

    private static List<Party__c> queryPartiesByEmail(Set<String> emails) {
        emails.remove(null);
        if (emails.isEmpty()) {
            return new List<Party__c>();
        }

        return [
            SELECT Id, Name, Email__c, First_Name__c, Last_Name__c, Person_Identification__c, Salutation__c,
                   Case__c, RecordType.DeveloperName,
                   (SELECT Id, Address_Line1__c, Address_Line_2__c, Town_City__c, County__c, Postcode__c
                    FROM Addresses__r
                    ORDER BY CreatedDate ASC)
            FROM Party__c
            WHERE Email__c IN :emails
            ORDER BY CreatedDate ASC
        ];
    }

    private static String getEmail(InboundForm_JSONParser parser) {
        return parser.getString(InboundForm_ProfileUpdateConfig.EMAIL_PATH);
    }

    private static Map<String, Object> getChanges(InboundForm_JSONParser parser) {
        Object changes = parser.getValue(InboundForm_ProfileUpdateConfig.CHANGES_PATH);
        return changes instanceof Map<String, Object>
            ? (Map<String, Object>) changes
            : new Map<String, Object>();
    }

    private static Map<String, Object> getChange(Map<String, Object> changes, String key) {
        Object change = changes.get(key);
        return change instanceof Map<String, Object> ? (Map<String, Object>) change : null;
    }

    private static String getChangeValue(Map<String, Object> changes, String key, String valueKey) {
        Map<String, Object> change = getChange(changes, key);
        if (change == null || change.get(valueKey) == null) {
            return null;
        }
        return trimToNull(String.valueOf(change.get(valueKey)));
    }

    /**
     * Split an existing full name into [first, last], using the payload oldValue as a hint
     * (e.g. Name "Sagar Kumar" + lastName.oldValue "Kumar" -> ["Sagar", "Kumar"]).
     * Falls back to splitting on the last space.
     */
    @TestVisible
    private static List<String> splitFullName(String fullName, String oldFirstName, String oldLastName) {
        String name = fullName.normalizeSpace();
        String oldFirst = oldFirstName != null ? oldFirstName.normalizeSpace() : null;
        String oldLast = oldLastName != null ? oldLastName.normalizeSpace() : null;

        if (oldLast != null) {
            if (name.equalsIgnoreCase(oldLast)) {
                return new List<String>{ null, name };
            }
            if (name.toLowerCase().endsWith(' ' + oldLast.toLowerCase())) {
                return new List<String>{
                    trimToNull(name.left(name.length() - oldLast.length())),
                    name.right(oldLast.length())
                };
            }
        }

        if (oldFirst != null) {
            if (name.equalsIgnoreCase(oldFirst)) {
                return new List<String>{ name, null };
            }
            if (name.toLowerCase().startsWith(oldFirst.toLowerCase() + ' ')) {
                return new List<String>{
                    name.left(oldFirst.length()),
                    trimToNull(name.substring(oldFirst.length()))
                };
            }
        }

        Integer lastSpace = name.lastIndexOf(' ');
        if (lastSpace < 0) {
            return new List<String>{ name, null };
        }
        return new List<String>{ name.left(lastSpace), name.substring(lastSpace + 1) };
    }

    private static String buildFullName(String firstName, String lastName) {
        List<String> parts = new List<String>();
        if (firstName != null) parts.add(firstName);
        if (lastName != null) parts.add(lastName);
        return parts.isEmpty()
            ? null
            : String.join(parts, ' ').left(InboundForm_ProfileUpdateConfig.NAME_MAX_LENGTH);
    }

    private static Boolean hasAnyValue(Map<String, String> values) {
        for (String value : values.values()) {
            if (value != null) {
                return true;
            }
        }
        return false;
    }

    private static String normalizeEmail(String email) {
        return String.isBlank(email) ? null : email.trim().toLowerCase();
    }

    private static String trimToNull(String value) {
        return String.isBlank(value) ? null : value.trim();
    }

    /**
     * Case-sensitive comparison (Apex == / != on Strings ignores case), treating blank as null.
     */
    private static Boolean differs(String a, String b) {
        String left = trimToNull(a);
        String right = trimToNull(b);
        if (left == null || right == null) {
            return left != right;
        }
        return !left.equals(right);
    }
}
