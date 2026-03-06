public with sharing class DynamicPathController {

    @AuraEnabled(cacheable=true)
    public static List<String> getPicklistValuesByRecord(Id recordId, String fieldApiName) {
        if (recordId == null) {
            throw new AuraHandledException('Record Id is required');
        }

        // Get object API name dynamically
        String objectApiName = recordId.getSObjectType().getDescribe().getName();

        Schema.SObjectType sObjType = Schema.getGlobalDescribe().get(objectApiName);
        if (!sObjType.getDescribe().fields.getMap().containsKey(fieldApiName)) {
            throw new AuraHandledException('Field not found: ' + fieldApiName);
        }

        Schema.DescribeFieldResult fieldResult =
            sObjType.getDescribe().fields.getMap().get(fieldApiName).getDescribe();

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
        if (recordId == null || String.isBlank(fieldApiName) || String.isBlank(fieldValue)) {
            throw new AuraHandledException('Invalid parameters');
        }
    
        try {
            // Create SObject dynamically and update field
            SObject record = recordId.getSObjectType().newSObject(recordId);
            record.put(fieldApiName, fieldValue);
            update record;
        } catch (DmlException e) {
            // Extract only the first DML error message
            String errorMessage = '';
            if (e.getNumDml() > 0) {
                errorMessage = e.getDmlMessage(0); // This gives just the friendly message
            } else {
                errorMessage = e.getMessage();
            }
            throw new AuraHandledException(errorMessage);
        }
    }
}