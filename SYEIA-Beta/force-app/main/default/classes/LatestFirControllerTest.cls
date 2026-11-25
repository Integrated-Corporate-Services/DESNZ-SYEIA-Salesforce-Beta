@IsTest
private class LatestFirControllerTest {

    @IsTest
    static void returnsLatestFir() {
        // Add any required fields for Case / FIR in your org
        Case c = new Case(Subject = 'Test case');
        insert c;

        Further_Information_Requested__c fir = new Further_Information_Requested__c(Case__c = c.Id);
        insert fir;

        Test.startTest();
        Id result = LatestFirController.getLatestFirId(c.Id);
        Test.stopTest();

        Assert.areEqual(fir.Id, result, 'Should return the FIR linked to the case');
    }

    @IsTest
    static void returnsNullWhenNoFir() {
        Case c = new Case(Subject = 'Test case');
        insert c;

        Assert.isNull(LatestFirController.getLatestFirId(c.Id), 'Should be null when the case has no FIR');
        Assert.isNull(LatestFirController.getLatestFirId(null), 'Should be null for a null case Id');
    }
}