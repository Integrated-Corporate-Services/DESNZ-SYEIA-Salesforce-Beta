public with sharing class CaseEventRelatedListController {
    public class CaseFile {
        @AuraEnabled public String documentId;
        @AuraEnabled public String title;
        @AuraEnabled public String fileType;
        @AuraEnabled public Integer contentSize;
        @AuraEnabled public Datetime lastModifiedDate;
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getRelatedRecords(
        Id parentRecordId,
        String childObjectApiName,
        String relationshipFieldApiName,
        List<String> fieldApiNames
    ) {
        if (parentRecordId == null || parentRecordId.getSObjectType() != Case__c.SObjectType) {
            throw new AuraHandledException('A valid Case record ID is required.');
        }
        if (String.isBlank(childObjectApiName) || String.isBlank(relationshipFieldApiName)) {
            throw new AuraHandledException('The related object and relationship field are required.');
        }

        Map<String, Schema.SObjectType> objectTypes = Schema.getGlobalDescribe();
        Schema.SObjectType childType = objectTypes.get(childObjectApiName);
        if (childType == null || !childType.getDescribe().isAccessible()) {
            throw new AuraHandledException('The related object is unavailable.');
        }

        Map<String, Schema.SObjectField> childFields = childType.getDescribe().fields.getMap();
        Schema.SObjectField relationshipField = childFields.get(relationshipFieldApiName);
        if (relationshipField == null) {
            throw new AuraHandledException('The Case relationship field is unavailable.');
        }

        Schema.DescribeFieldResult relationshipDescribe = relationshipField.getDescribe();
        if (
            relationshipDescribe.getType() != Schema.DisplayType.REFERENCE ||
            !relationshipDescribe.isAccessible() ||
            !relationshipDescribe.getReferenceTo().contains(Case__c.SObjectType)
        ) {
            throw new AuraHandledException('The selected field is not an accessible Case relationship.');
        }

        Set<String> selectedFields = new Set<String>();
        if (fieldApiNames != null) {
            for (String fieldApiName : fieldApiNames) {
                if (String.isBlank(fieldApiName) || fieldApiName.contains('.')) {
                    throw new AuraHandledException('Related-list columns must be direct fields.');
                }

                Schema.SObjectField selectedField = childFields.get(fieldApiName);
                if (selectedField == null || !selectedField.getDescribe().isAccessible()) {
                    throw new AuraHandledException('A related-list column is unavailable: ' + fieldApiName);
                }
                selectedFields.add(selectedField.getDescribe().getName());
            }
        }

        List<String> queryFields = new List<String>{ 'Id' };
        queryFields.addAll(new List<String>(selectedFields));
        String queryString =
            'SELECT ' + String.join(queryFields, ',') +
            ' FROM ' + childType.getDescribe().getName() +
            ' WHERE ' + relationshipDescribe.getName() + ' = :parentRecordId' +
            ' WITH USER_MODE LIMIT 50';

        List<Map<String, Object>> results = new List<Map<String, Object>>();
        for (SObject record : Database.query(queryString)) {
            Map<String, Object> row = new Map<String, Object>{ 'Id' => record.get('Id') };
            for (String fieldApiName : selectedFields) {
                row.put(fieldApiName, record.get(fieldApiName));
            }
            results.add(row);
        }
        return results;
    }

    @AuraEnabled
    public static List<CaseFile> getCaseFiles(Id parentRecordId) {
        if (parentRecordId == null || parentRecordId.getSObjectType() != Case__c.SObjectType) {
            throw new AuraHandledException('A valid Case record ID is required.');
        }

        List<ContentDocumentLink> links = [
            SELECT
                ContentDocumentId,
                ContentDocument.Title,
                ContentDocument.FileType,
                ContentDocument.ContentSize,
                ContentDocument.LastModifiedDate
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :parentRecordId
            WITH USER_MODE
            ORDER BY ContentDocument.LastModifiedDate DESC
            LIMIT 200
        ];

        List<CaseFile> files = new List<CaseFile>();
        for (ContentDocumentLink link : links) {
            CaseFile file = new CaseFile();
            file.documentId = link.ContentDocumentId;
            file.title = link.ContentDocument.Title;
            file.fileType = link.ContentDocument.FileType;
            file.contentSize = link.ContentDocument.ContentSize;
            file.lastModifiedDate = link.ContentDocument.LastModifiedDate;
            files.add(file);
        }
        return files;
    }
}