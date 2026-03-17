@IsTest
public class CaseTriggerHandlerTest {

    // Utility method to create test Case__c records
    private static List<Case__c> createCases(Integer count) {
        List<Case__c> cases = new List<Case__c>();
        for(Integer i = 0; i < count; i++) {
            cases.add(new Case__c(
                Name = 'Test Case ' + i,
                Status__c = 'New'
            ));
        }
        return cases;
    }

    // Convert list of Case__c to list of SObject
    private static List<SObject> toSObjectList(List<Case__c> cases) {
        List<SObject> sObjects = new List<SObject>();
        for(Case__c c : cases) sObjects.add(c);
        return sObjects;
    }

    @IsTest
    static void testBeforeInsert() {
        List<Case__c> cases = createCases(2);
        List<SObject> sObjects = toSObjectList(cases);

        Test.startTest();
        CaseTriggerHandler handler = new CaseTriggerHandler(true, sObjects.size());
        handler.beforeInsert(sObjects);
        Test.stopTest();
    }

    @IsTest
    static void testBeforeUpdate() {
        List<Case__c> cases = createCases(2);
        insert cases;

        // Build old map with clones BEFORE making changes
        Map<Id, SObject> oldMap = new Map<Id, SObject>();
        for(Case__c c : cases) oldMap.put(c.Id, c.clone(false, true, false, false));

        // Make changes for update
        for(Case__c c : cases) c.Name += ' Updated';
        update cases;

        List<SObject> sObjects = toSObjectList(cases);

        Test.startTest();
        CaseTriggerHandler handler = new CaseTriggerHandler(true, sObjects.size());
        handler.beforeUpdate(sObjects, sObjects, oldMap, oldMap);
        Test.stopTest();
    }

    @IsTest
    static void testBeforeDelete() {
        List<Case__c> cases = createCases(2);
        insert cases;

        Map<Id, SObject> oldMap = new Map<Id, SObject>();
        for(Case__c c : cases) oldMap.put(c.Id, c);

        List<SObject> sObjects = toSObjectList(cases);

        Test.startTest();
        CaseTriggerHandler handler = new CaseTriggerHandler(true, sObjects.size());
        handler.beforeDelete(sObjects, oldMap);
        Test.stopTest();
    }

    @IsTest
    static void testAfterInsert() {
        List<Case__c> cases = createCases(2);
        List<SObject> sObjects = toSObjectList(cases);

        Test.startTest();
        CaseTriggerHandler handler = new CaseTriggerHandler(true, sObjects.size());
        handler.afterInsert(sObjects, new Map<Id, SObject>());
        Test.stopTest();
    }

    @IsTest
    static void testAfterUpdate() {
        List<Case__c> cases = createCases(2);
        insert cases;

        // Build old map with clones BEFORE changes
        Map<Id, SObject> oldMap = new Map<Id, SObject>();
        for(Case__c c : cases) oldMap.put(c.Id, c.clone(false, true, false, false));

        // Change Name and Status to trigger updateStatusCallout
        for(Case__c c : cases) {
            c.Name += ' Updated';
            c.Status__c = 'In Progress';
        }
        update cases;

        List<SObject> sObjects = toSObjectList(cases);

        Test.startTest();
        CaseTriggerHandler handler = new CaseTriggerHandler(true, sObjects.size());
        handler.afterUpdate(sObjects, sObjects, oldMap, oldMap);
        Test.stopTest();
    }

    @IsTest
    static void testAfterDelete() {
        List<Case__c> cases = createCases(2);
        insert cases;

        Map<Id, SObject> oldMap = new Map<Id, SObject>();
        for(Case__c c : cases) oldMap.put(c.Id, c);

        List<SObject> sObjects = toSObjectList(cases);

        Test.startTest();
        CaseTriggerHandler handler = new CaseTriggerHandler(true, sObjects.size());
        handler.afterDelete(sObjects, oldMap);
        Test.stopTest();
    }

    @IsTest
    static void testAfterUndelete() {
        List<Case__c> cases = createCases(2);
        insert cases;
        delete cases;

        List<SObject> sObjects = toSObjectList(cases);

        Test.startTest();
        CaseTriggerHandler handler = new CaseTriggerHandler(true, sObjects.size());
        handler.afterUndelete(sObjects, new Map<Id, SObject>());
        Test.stopTest();
    }
}