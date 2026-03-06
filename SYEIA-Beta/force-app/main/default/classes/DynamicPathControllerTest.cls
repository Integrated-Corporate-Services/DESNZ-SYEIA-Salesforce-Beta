@IsTest
public class DynamicPathControllerTest {

    @TestSetup
    static void setupTestData() {
        // Insert a test Case__c record with 'In-Progress' as picklist value
        Case__c testCase = new Case__c(
            Name = 'Test Case',
            Status__c = 'In-Progress' // must exist in your org picklist
        );
        insert testCase;
    }

    // Positive test for picklist values
    @IsTest
    static void testGetPicklistValuesByRecord_Positive() {
        Case__c c = [SELECT Id FROM Case__c LIMIT 1];

        List<String> picklistValues = DynamicPathController.getPicklistValuesByRecord(c.Id, 'Status__c');

        System.assertNotEquals(0, picklistValues.size(), 'Picklist values should be returned');
        System.assert(picklistValues.contains('In-Progress'), 'Picklist values should include "In-Progress"');
    }

    // Positive test for updateRecordStatus
    @IsTest
    static void testUpdateRecordStatus() {
        Case__c c = [SELECT Id, Status__c FROM Case__c LIMIT 1];

        // Update Status__c to 'Closed'
        DynamicPathController.updateRecordStatus(c.Id, 'Status__c', 'Closed');

        Case__c updated = [SELECT Id, Status__c FROM Case__c WHERE Id = :c.Id];
        System.assertEquals('Closed', updated.Status__c, 'Status__c should be updated to Closed');
    }
}