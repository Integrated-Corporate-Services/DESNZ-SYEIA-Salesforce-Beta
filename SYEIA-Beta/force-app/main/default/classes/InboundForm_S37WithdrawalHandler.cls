public class InboundForm_S37WithdrawalHandler implements InboundForm_Processor.IFormHandler {
    private static final String WITHDRAWAL_EVENT_TYPE = 'WITHDRAWAL_REQUESTED';
    private static final String WITHDRAWAL_REQUESTED_STATUS = 'Withdrawal Requested';

    public List<String> validate(InboundForm_JSONParser parser) {
        List<String> errors = new List<String>();

        String desnzRef = parser.getString('desnzRef');
        String eventType = parser.getString('eventType');

        if (String.isBlank(desnzRef)) {
            errors.add('desnzRef is required for withdrawal requests');
            return errors;
        }

        if (!isWithdrawalRequestedEvent(eventType)) {
            errors.add('Unsupported eventType for S37 withdrawal handler: ' + eventType);
            return errors;
        }

        List<Case__c> matches = [
            SELECT Id
            FROM Case__c
            WHERE Name = :desnzRef
            LIMIT 1
        ];

        if (matches.isEmpty()) {
            errors.add('No Case__c found for desnzRef: ' + desnzRef);
        }

        return errors;
    }

    public void afterBuild(InboundForm_JSONParser parser, Map<String, List<SObject>> records) {
        List<SObject> withdrawalRecords = records.get('Withdrawal_Request__c');
        if (withdrawalRecords == null || withdrawalRecords.isEmpty()) {
            return;
        }

        String desnzRef = parser.getString('desnzRef');
        if (String.isBlank(desnzRef)) {
            return;
        }

        List<Case__c> matches = [
            SELECT Id
            FROM Case__c
            WHERE Name = :desnzRef
            LIMIT 1
        ];

        if (matches.isEmpty()) {
            return;
        }

        Id caseId = matches[0].Id;
        for (SObject rec : withdrawalRecords) {
            Withdrawal_Request__c withdrawal = (Withdrawal_Request__c) rec;
            withdrawal.Case__c = caseId;
            withdrawal.Status__c = 'Pending';
        }
    }

    public void afterPrimaryInsert(
        InboundForm_JSONParser parser,
        Id primaryRecordId,
        InboundForm_Processor.ProcessingResult result
    ) {
        String desnzRef = parser.getString('desnzRef');
        if (String.isBlank(desnzRef)) {
            return;
        }

        List<Case__c> matches = [
            SELECT Id, Status__c
            FROM Case__c
            WHERE Name = :desnzRef
            LIMIT 1
        ];

        if (matches.isEmpty()) {
            return;
        }

        Case__c caseToUpdate = matches[0];
        caseToUpdate.Status__c = WITHDRAWAL_REQUESTED_STATUS;
        update caseToUpdate;
    }

    public void afterAllInserts(Id primaryRecordId, Map<String, List<SObject>> insertedRecords) {
        // No-op for this event type.
    }

    private static Boolean isWithdrawalRequestedEvent(String eventType) {
        if (String.isBlank(eventType)) {
            return false;
        }

        return eventType.equalsIgnoreCase(WITHDRAWAL_EVENT_TYPE);
    }
}