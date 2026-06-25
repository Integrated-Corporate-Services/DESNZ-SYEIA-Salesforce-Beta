/**
 * Custom handler for NWL form type.
 */
public class InboundForm_NWLHandler implements InboundForm_Processor.IFormHandler {

    public List<String> validate(InboundForm_JSONParser parser) {
        return new List<String>();
    }

    public void afterBuild(InboundForm_JSONParser parser, Map<String, List<SObject>> records) {
        if (!records.containsKey('Case__c')) {
            return;
        }

        for (SObject record : records.get('Case__c')) {
            Case__c caseRecord = (Case__c) record;
            caseRecord.Case_Type__c = 'Necessary Wayleaves';
            caseRecord.Overdue_Email_Sent__c = false;

            normalizeApplicationType(caseRecord);

            caseRecord.Written_Removal_Notice_Been_Given__c =
                caseRecord.Written_Removal_Notice_Issue_Date__c != null ? 'Yes' : 'No';
            caseRecord.Written_Termination_Notice_Been_Given__c =
                caseRecord.Written_Termination_Notice_Issue_Date__c != null ? 'Yes' : 'No';
        }
    }

    public void afterPrimaryInsert(InboundForm_JSONParser parser, Id primaryCaseId,
                                    InboundForm_Processor.ProcessingResult result) {
        // No-op for NWL.
    }

    public void afterAllInserts(Id primaryCaseId, Map<String, List<SObject>> insertedRecords) {
        Case__c caseToUpdate = new Case__c(Id = primaryCaseId);
        Boolean shouldUpdate = false;

        Id paymentId = getFirstRecordId(insertedRecords, 'Payment__c');
        if (paymentId != null) {
            caseToUpdate.Payment__c = paymentId;
            shouldUpdate = true;
        }

        Id objectorId = getPartyIdByType(insertedRecords, 'Individual');
        if (objectorId != null) {
            caseToUpdate.Objector__c = objectorId;
            shouldUpdate = true;
        }

        Id landownerId = getPartyIdByType(insertedRecords, 'Landowner');
        if (landownerId != null) {
            caseToUpdate.Landowner__c = landownerId;
            shouldUpdate = true;
        }

        if (!shouldUpdate) {
            return;
        }

        try {
            update caseToUpdate;
        } catch (Exception e) {
            Logger.error('Error updating NWL case lookups: ' + e.getMessage());
            Logger.setScenario('InboundForm_NWLHandler.afterAllInserts');
            Logger.saveLog();
        }
    }

    private static void normalizeApplicationType(Case__c caseRecord) {
        if (String.isBlank(caseRecord.Application_Type__c)) {
            return;
        }

        if (caseRecord.Application_Type__c.equalsIgnoreCase('Existing line')) {
            caseRecord.Application_Type__c = 'Existing Line';
        } else if (caseRecord.Application_Type__c.equalsIgnoreCase('New line')) {
            caseRecord.Application_Type__c = 'New Line';
        }
    }

    private static Id getFirstRecordId(Map<String, List<SObject>> insertedRecords, String objectName) {
        if (!insertedRecords.containsKey(objectName)) {
            return null;
        }

        for (SObject record : insertedRecords.get(objectName)) {
            if (record.Id != null) {
                return record.Id;
            }
        }
        return null;
    }

    private static Id getPartyIdByType(Map<String, List<SObject>> insertedRecords, String partyType) {
        if (!insertedRecords.containsKey('Party__c')) {
            return null;
        }

        for (SObject record : insertedRecords.get('Party__c')) {
            Party__c party = (Party__c) record;
            if (party.Id != null && party.Party_Type__c == partyType) {
                return party.Id;
            }
        }
        return null;
    }
}