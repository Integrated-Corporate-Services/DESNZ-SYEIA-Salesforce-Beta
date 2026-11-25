@IsTest
private class LatestFirControllerTest {

    @TestSetup
    static void setupData() {
        CaseTriggerHelper.disableProcessing();
        insert new Case__c(
            Name                  = 'NWL00999',
            AWS_Application_Id__c = 'AWS-LATESTFIR-001'
        );
        CaseTriggerHelper.enableProcessing();
    }

    private static Id caseId() {
        return [SELECT Id FROM Case__c WHERE AWS_Application_Id__c = 'AWS-LATESTFIR-001' LIMIT 1].Id;
    }

    @IsTest
    static void returnsLatestFir() {
        Id cId = caseId();

        Further_Information_Requested__c fir = new Further_Information_Requested__c(Case__c = cId);
        insert fir;

        Test.startTest();
        Id result = LatestFirController.getLatestFirId(cId);
        Test.stopTest();

        Assert.areEqual(fir.Id, result, 'Should return the FIR linked to the case');
    }

    @IsTest
    static void returnsNewestWhenSeveralExist() {
        Id cId = caseId();

        Further_Information_Requested__c older = new Further_Information_Requested__c(Case__c = cId);
        insert older;
        Test.setCreatedDate(older.Id, Datetime.now().addDays(-2));

        Further_Information_Requested__c newer = new Further_Information_Requested__c(Case__c = cId);
        insert newer;

        Test.startTest();
        Id result = LatestFirController.getLatestFirId(cId);
        Test.stopTest();

        Assert.areEqual(newer.Id, result, 'Should return the most recently created FIR');
    }

    @IsTest
    static void returnsNullWhenNoFir() {
        Test.startTest();
        Id result = LatestFirController.getLatestFirId(caseId());
        Test.stopTest();

        Assert.isNull(result, 'Should be null when the case has no FIR');
        Assert.isNull(LatestFirController.getLatestFirId(null), 'Should be null for a null case Id');
    }
}