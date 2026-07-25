public with sharing class DynamicPathController {

    @AuraEnabled(cacheable=true)
    public static List<String> getPicklistValuesByRecord(Id recordId, String fieldApiName) {
        if (recordId == null) {
            throw new AuraHandledException('Record Id is required');
        }

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
    public static void updateRecordStatus(Id recordId, String fieldApiName, String currentStatus) {
        if (recordId == null) {
            throw new AuraHandledException('Record Id is required');
        }

        if (String.isBlank(fieldApiName)) {
            throw new AuraHandledException('Field API Name is required');
        }

        if (String.isBlank(currentStatus)) {
            List<String> picklist = getPicklistValuesByRecord(recordId, fieldApiName);
            if (picklist.isEmpty()) {
                throw new AuraHandledException('No picklist values found for field ' + fieldApiName);
            }
            currentStatus = picklist[0];
        }

        String finalValue;

        // Routing metadata
        List<Dynamic_Application_Status_Routing__mdt> routing = [
            SELECT Current_Status__c, Next_Status__c
            FROM Dynamic_Application_Status_Routing__mdt
            WHERE Current_Status__c = :currentStatus
            LIMIT 1
        ];

        if (!routing.isEmpty() && !String.isBlank(routing[0].Next_Status__c)) {
            finalValue = routing[0].Next_Status__c;
        }

        // Prior status fallback
        if (String.isBlank(finalValue)) {
            List<Prior_Application_Status_Setting__mdt> priorSettings = [
                SELECT Applicable_Statuses__c
                FROM Prior_Application_Status_Setting__mdt
                LIMIT 1
            ];

            if (!priorSettings.isEmpty() && !String.isBlank(priorSettings[0].Applicable_Statuses__c)) {
                for (String s : priorSettings[0].Applicable_Statuses__c.split(',')) {
                    if (currentStatus.equalsIgnoreCase(s.trim())) {

                        SObject rec = Database.query(
                            'SELECT Prior_Application_Status__c FROM ' +
                            recordId.getSObjectType() +
                            ' WHERE Id = :recordId LIMIT 1'
                        );

                        String priorStatus = (String)rec.get('Prior_Application_Status__c');
                        if (!String.isBlank(priorStatus)) {
                            finalValue = priorStatus;
                        }
                        break;
                    }
                }
            }
        }

        if (String.isBlank(finalValue)) {
            finalValue = currentStatus;
        }

        // Validate picklist
        Schema.DescribeFieldResult fieldResult = recordId.getSObjectType().getDescribe()
            .fields.getMap().get(fieldApiName).getDescribe();

        Boolean isValid = false;
        for (Schema.PicklistEntry pe : fieldResult.getPicklistValues()) {
            if (pe.getValue().equalsIgnoreCase(finalValue)) {
                finalValue = pe.getValue();
                isValid = true;
                break;
            }
        }

        if (!isValid) {
            throw new AuraHandledException('Invalid status: ' + finalValue);
        }

        try {
            SObject record = recordId.getSObjectType().newSObject(recordId);
            record.put(fieldApiName, finalValue);
            update record;
        } catch (DmlException e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    //UPDATED METHOD (RecordType-aware)
    @AuraEnabled(cacheable=true)
    public static List<String> getStatusByCurrentStatus(String status, String recordTypeDevName) {
        if (String.isBlank(status)) {
            throw new AuraHandledException('Status is required');
        }

        if (String.isBlank(recordTypeDevName)) {
            throw new AuraHandledException('Record Type is required');
        }

        List<Application_Status_Path_Setting__mdt> settings = [
            SELECT Controlling_Status__c, Path_Statuses__c, Case_RecordType__c
            FROM Application_Status_Path_Setting__mdt
            WHERE Controlling_Status__c = :status
            AND Case_RecordType__c = :recordTypeDevName
            LIMIT 1
        ];

        // Fallback to DEFAULT
        if (settings.isEmpty()) {
            settings = [
                SELECT Controlling_Status__c, Path_Statuses__c
                FROM Application_Status_Path_Setting__mdt
                WHERE Controlling_Status__c = :status
                AND Case_RecordType__c = 'DEFAULT'
                LIMIT 1
            ];
        }

        if (settings.isEmpty() || String.isBlank(settings[0].Path_Statuses__c)) {
            return new List<String>();
        }

        List<String> result = new List<String>();
        for (String s : settings[0].Path_Statuses__c.split(',')) {
            if (!String.isBlank(s)) {
                result.add(s.trim());
            }
        }

        return result;
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getHideStatuses() {
        Mark_Status_as_Complete_Setting__mdt setting = [
            SELECT Button_Hide_Statuses__c
            FROM Mark_Status_as_Complete_Setting__mdt
            LIMIT 1
        ];

        if (String.isBlank(setting.Button_Hide_Statuses__c)) {
            return new List<String>();
        }

        List<String> result = new List<String>();
        for (String s : setting.Button_Hide_Statuses__c.split(',')) {
            if (!String.isBlank(s)) {
                result.add(s.trim().toLowerCase());
            }
        }

        return result;
    }
}