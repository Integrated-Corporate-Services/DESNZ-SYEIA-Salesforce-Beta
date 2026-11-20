@IsTest
private class CaseFilesPanelControllerTest {
    @IsTest
    static void uploaderCanDeleteDocumentSharedAcrossCases() {
        Case__c firstCase = createCase('First Case');
        Case__c secondCase = createCase('Second Case');
        Id documentId = uploadFile(firstCase.Id);
        insert new ContentDocumentLink(
            ContentDocumentId = documentId,
            LinkedEntityId = secondCase.Id,
            ShareType = 'V'
        );

        List<CaseFilesPanelController.CaseFile> files = CaseFilesPanelController.getCaseFiles(firstCase.Id);
        Assert.areEqual(1, files.size());
        Assert.areEqual(documentId, files[0].documentId);
        Assert.isTrue(files[0].canDelete);

        CaseFilesPanelController.deleteCaseFile(firstCase.Id, documentId);

        Assert.areEqual(0, [SELECT COUNT() FROM ContentDocument WHERE Id = :documentId]);
        Assert.areEqual(0, CaseFilesPanelController.getCaseFiles(firstCase.Id).size());
        Assert.areEqual(0, CaseFilesPanelController.getCaseFiles(secondCase.Id).size());
    }

    @IsTest
    static void anotherUserCannotDeleteVisibleFile() {
        User otherUser = new User(
            ProfileId = UserInfo.getProfileId(),
            Username = 'case.files.' + Test.getRunId() + '@example.com',
            LastName = 'File Panel Tester',
            Email = 'case.files@example.com',
            Alias = 'filetest',
            TimeZoneSidKey = 'Europe/London',
            LocaleSidKey = 'en_GB',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert otherUser;
        }
        Case__c parentCase = new Case__c(Name = 'Shared Case', OwnerId = otherUser.Id);
        insert parentCase;
        Id documentId = uploadFile(parentCase.Id);

        System.runAs(otherUser) {
            List<CaseFilesPanelController.CaseFile> files = CaseFilesPanelController.getCaseFiles(parentCase.Id);
            Assert.areEqual(1, files.size());
            Assert.isFalse(files[0].canDelete);
            assertDeleteRejected(parentCase.Id, documentId, 'You can delete only files you uploaded.');
        }
        Assert.areEqual(1, [SELECT COUNT() FROM ContentDocument WHERE Id = :documentId]);
    }

    @IsTest
    static void uploaderCannotDeleteFileThroughAnUnrelatedCase() {
        Case__c linkedCase = createCase('Linked Case');
        Case__c unrelatedCase = createCase('Unrelated Case');
        Id documentId = uploadFile(linkedCase.Id);

        assertDeleteRejected(unrelatedCase.Id, documentId, 'This file is not available on the current Case.');
        Assert.areEqual(1, [SELECT COUNT() FROM ContentDocument WHERE Id = :documentId]);
    }

    private static void assertDeleteRejected(Id caseId, Id documentId, String expectedMessage) {
        try {
            CaseFilesPanelController.deleteCaseFile(caseId, documentId);
            Assert.fail('Expected deletion to be rejected.');
        } catch (AuraHandledException error) {
            Assert.areEqual(expectedMessage, error.getMessage());
        }
    }

    private static Case__c createCase(String name) {
        Case__c record = new Case__c(Name = name);
        insert record;
        return record;
    }

    private static Id uploadFile(Id caseId) {
        ContentVersion version = new ContentVersion(
            Title = 'Case evidence',
            PathOnClient = 'case-evidence.txt',
            VersionData = Blob.valueOf('Test evidence'),
            FirstPublishLocationId = caseId
        );
        insert version;
        return [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :version.Id].ContentDocumentId;
    }
}
