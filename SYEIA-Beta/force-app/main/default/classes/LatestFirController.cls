public with sharing class LatestFirController {

    // Returns the Id of the most recently created Further Information Requested
    // record for the given Case, or null if the Case has none.
    @AuraEnabled(cacheable=true)
    public static Id getLatestFirId(Id caseId) {
        if (caseId == null) {
            return null;
        }

        List<Further_Information_Requested__c> firs = [
            SELECT Id
            FROM Further_Information_Requested__c
            WHERE Case__c = :caseId
            WITH USER_MODE
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        return firs.isEmpty() ? null : firs[0].Id;
    }
}