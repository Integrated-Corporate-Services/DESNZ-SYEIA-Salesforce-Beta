public with sharing class CaseFilesPanelController {
    public class CaseFile {
        @AuraEnabled public Id documentId;
        @AuraEnabled public String title;
        @AuraEnabled public String fileType;
        @AuraEnabled public Integer contentSize;
        @AuraEnabled public Datetime lastModifiedDate;
        @AuraEnabled public Boolean canDelete;
    }

    @AuraEnabled
    public static List<CaseFile> getCaseFiles(Id parentRecordId) {
        validateCaseId(parentRecordId);

        Boolean canDeleteDocuments = ContentDocument.SObjectType.getDescribe().isDeletable();
        Id userId = UserInfo.getUserId();
        List<CaseFile> files = new List<CaseFile>();
        for (ContentDocumentLink link : [
            SELECT ContentDocumentId, ContentDocument.Title, ContentDocument.FileType,
                ContentDocument.ContentSize, ContentDocument.LastModifiedDate, ContentDocument.CreatedById
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :parentRecordId
            WITH USER_MODE
            ORDER BY ContentDocument.LastModifiedDate DESC
            LIMIT 200
        ]) {
            CaseFile file = new CaseFile();
            file.documentId = link.ContentDocumentId;
            file.title = link.ContentDocument.Title;
            file.fileType = link.ContentDocument.FileType;
            file.contentSize = link.ContentDocument.ContentSize;
            file.lastModifiedDate = link.ContentDocument.LastModifiedDate;
            file.canDelete = canDeleteDocuments && link.ContentDocument.CreatedById == userId;
            files.add(file);
        }
        return files;
    }

    @AuraEnabled
    public static void deleteCaseFile(Id parentRecordId, Id documentId) {
        validateCaseId(parentRecordId);
        if (documentId == null || documentId.getSObjectType() != ContentDocument.SObjectType) {
            throw handledError('A valid Salesforce file ID is required.');
        }

        List<Case__c> cases = [SELECT Id FROM Case__c WHERE Id = :parentRecordId WITH USER_MODE];
        if (cases.isEmpty()) {
            throw handledError('This Case is not available.');
        }

        List<ContentDocumentLink> links = [
            SELECT ContentDocument.CreatedById
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :parentRecordId AND ContentDocumentId = :documentId
            WITH USER_MODE
            LIMIT 1
        ];
        if (links.isEmpty()) {
            throw handledError('This file is not available on the current Case.');
        }
        if (links[0].ContentDocument.CreatedById != UserInfo.getUserId()) {
            throw handledError('You can delete only files you uploaded.');
        }

        try {
            delete as user new ContentDocument(Id = documentId);
        } catch (DmlException error) {
            throw handledError(error.getDmlMessage(0));
        }
    }

    private static void validateCaseId(Id parentRecordId) {
        if (parentRecordId == null || parentRecordId.getSObjectType() != Case__c.SObjectType) {
            throw handledError('A valid Case record ID is required.');
        }
    }

    private static AuraHandledException handledError(String message) {
        AuraHandledException error = new AuraHandledException(message);
        error.setMessage(message);
        return error;
    }
}
