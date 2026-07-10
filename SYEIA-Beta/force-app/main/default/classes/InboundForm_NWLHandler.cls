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

        normalizeLandLocation(records);
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

        linkLandToSiteAddress(insertedRecords);

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
        if (!String.isBlank(caseRecord.Application_Type__c)) {
            if (caseRecord.Application_Type__c.equalsIgnoreCase('Existing line')) {
                caseRecord.Application_Type__c = 'Existing Line';
            } else if (caseRecord.Application_Type__c.equalsIgnoreCase('New line')) {
                caseRecord.Application_Type__c = 'New Line';
            }
        }

        caseRecord.Type_Of_NWL_That_Existed__c =
            mapNwlWayleaveType(caseRecord.Type_Of_NWL_That_Existed__c);

        caseRecord.Legislation_Applicable__c =
            mapNwlGroundsForApplication(caseRecord.Legislation_Applicable__c);
    }

    @TestVisible
    private static String mapNwlWayleaveType(String value) {
        if (String.isBlank(value)) {
            return value;
        }

        if (value.equalsIgnoreCase('inherited_necessary_wayleave')) {
            return Label.NWL_Inherited_Necessary_Wayleave;
        }
        if (value.equalsIgnoreCase('implied_wayleave')) {
            return Label.NWL_Implied_Wayleave;
        }
        if (value.equalsIgnoreCase('wayleave')) {
            return Label.NWL_Wayleave;
        }

        return value;
    }

    @TestVisible
    private static String mapNwlGroundsForApplication(String value) {
        if (String.isBlank(value)) {
            return value;
        }

        if (value.equalsIgnoreCase('no_wayleave_exists')) {
            return Label.NWL_no_wayleave_exists;
        } else if (value.equalsIgnoreCase('wayleave_has_been_terminated')) {
            return Label.NWL_Wayleave_has_been_terminated;
        } else if (value.equalsIgnoreCase('wayleave_expired')) {
            return Label.NWL_Wayleave_has_Expired;
        }

        return value;
    }

    private static void normalizeLandLocation(Map<String, List<SObject>> records) {
        if (!records.containsKey('Land__c')) {
            return;
        }

        for (SObject record : records.get('Land__c')) {
            Land__c landRecord = (Land__c) record;
            if (String.isBlank(landRecord.Land_Location__c)) {
                continue;
            }

            if (landRecord.Land_Location__c.equalsIgnoreCase('england')) {
                landRecord.Land_Location__c = 'England';
            } else if (landRecord.Land_Location__c.equalsIgnoreCase('wales')) {
                landRecord.Land_Location__c = 'Wales';
            }
        }
    }

    private static Boolean linkLandToSiteAddress(Map<String, List<SObject>> insertedRecords) {
        if (!insertedRecords.containsKey('Land__c') || !insertedRecords.containsKey('Address__c')) {
            return false;
        }

        Id landId;
        for (SObject record : insertedRecords.get('Land__c')) {
            if (record.Id != null) {
                landId = record.Id;
                break;
            }
        }

        if (landId == null) {
            return false;
        }

        Id siteAddressId;
        for (SObject record : insertedRecords.get('Address__c')) {
            Address__c addr = (Address__c) record;
            if (addr.Id != null && addr.Application_Party_Identification__c == 'NWL_SITE_ADDRESS') {
                siteAddressId = addr.Id;
                break;
            }
        }

        if (siteAddressId == null) {
            return false;
        }

        try {
            update new Land__c(
                Id = landId,
                Site_Address__c = siteAddressId
            );
            return true;
        } catch (Exception e) {
            Logger.error('Error linking NWL land to site address: ' + e.getMessage());
            Logger.setScenario('InboundForm_NWLHandler.linkLandToSiteAddress');
            Logger.saveLog();
            return false;
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