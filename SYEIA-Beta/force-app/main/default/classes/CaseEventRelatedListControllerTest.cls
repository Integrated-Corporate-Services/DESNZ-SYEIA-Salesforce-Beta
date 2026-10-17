@IsTest
private class CaseEventRelatedListControllerTest {
    @IsTest
    static void rejectsMissingParentRecordId() {
        try {
            CaseEventRelatedListController.getRelatedRecords(
                null,
                'Address__c',
                'Case__c',
                new List<String>{ 'Name' }
            );
            System.assert(false, 'Expected the missing parent ID to be rejected.');
        } catch (AuraHandledException error) {
            System.assert(error.getMessage().contains('valid Case record ID'));
        }
    }

    @IsTest
    static void rejectsNonCaseRelationship() {
        Id parentId = (Id)(Case__c.SObjectType.getDescribe().getKeyPrefix() + '000000000000');

        try {
            CaseEventRelatedListController.getRelatedRecords(
                parentId,
                'Address__c',
                'Name',
                new List<String>{ 'Name' }
            );
            System.assert(false, 'Expected a non-relationship field to be rejected.');
        } catch (AuraHandledException error) {
            System.assert(error.getMessage().contains('not an accessible Case relationship'));
        }
    }

    @IsTest
    static void queriesAccessibleRelatedRecords() {
        Id parentId = (Id)(Case__c.SObjectType.getDescribe().getKeyPrefix() + '000000000000');

        Test.startTest();
        List<Map<String, Object>> results =
            CaseEventRelatedListController.getRelatedRecords(
                parentId,
                'Address__c',
                'Case__c',
                new List<String>{ 'Name', 'County__c' }
            );
        Test.stopTest();

        System.assertEquals(0, results.size(), 'The test parent has no related address records.');
    }

    @IsTest
    static void returnsNoFilesForCaseWithoutFiles() {
        Id parentId = (Id)(Case__c.SObjectType.getDescribe().getKeyPrefix() + '000000000000');

        Test.startTest();
        List<CaseEventRelatedListController.CaseFile> results =
            CaseEventRelatedListController.getCaseFiles(parentId);
        Test.stopTest();

        System.assertEquals(0, results.size(), 'The test parent has no linked files.');
    }
}