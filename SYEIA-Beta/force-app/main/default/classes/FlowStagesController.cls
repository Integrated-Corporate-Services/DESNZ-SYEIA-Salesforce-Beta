public with sharing class FlowStagesController {

    @AuraEnabled(cacheable=true)
    public static List<String> getPicklistValuesByRecord(Id recordId, String fieldApiName) {
        if(recordId == null) {
            throw new AuraHandledException('Record Id is required');
        }

        // Get object API name dynamically
        String objectApiName = recordId.getSObjectType().getDescribe().getName();

        // Describe the sObject and field
        Schema.SObjectType sObjType = Schema.getGlobalDescribe().get(objectApiName);
        if (!sObjType.getDescribe().fields.getMap().containsKey(fieldApiName)) {
            throw new AuraHandledException('Field not found: ' + fieldApiName);
        }
        Schema.DescribeFieldResult fieldResult = sObjType.getDescribe().fields.getMap().get(fieldApiName).getDescribe();

        // Return all active picklist values
        List<String> picklistValues = new List<String>();
        for (Schema.PicklistEntry pe : fieldResult.getPicklistValues()) {
            if (pe.isActive()) {
                picklistValues.add(pe.getValue());
            }
        }
        return picklistValues;
    }

    @AuraEnabled
    public static void updateRecordStatus(Id recordId, String fieldApiName, String fieldValue) {
        if (recordId == null || String.isBlank(fieldApiName) || String.isBlank(fieldValue)) return;

        String objectApiName = recordId.getSObjectType().getDescribe().getName();

        // Query record dynamically
        SObject record = Database.query(
            'SELECT Id FROM ' + objectApiName + ' WHERE Id = :recordId LIMIT 1'
        );

        // Update field
        record.put(fieldApiName, fieldValue);
        update record;
    }
}