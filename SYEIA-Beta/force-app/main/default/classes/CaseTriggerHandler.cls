/**
 * @description Trigger handler for Case__c object.
 *              Implements TriggerHandler interface and delegates to CaseTriggerHandlerHelper.
 */
public class CaseTriggerHandler implements TriggerHandler {
    
    private Boolean triggerIsExecuting;
    private Integer triggerSize;
    private CaseTriggerHelper helper;
    
    public CaseTriggerHandler(Boolean triggerIsExecuting, Integer triggerSize) {
        this.triggerIsExecuting = triggerIsExecuting;
        this.triggerSize = triggerSize;
        this.helper = new CaseTriggerHelper();
    }
   
    
    public void beforeInsert(List<SObject> newRecords) {
        helper.processBeforeInsert();
    }
    
    public void beforeUpdate(List<SObject> oldRecords, List<SObject> newRecords, 
                             Map<Id, SObject> oldRecordMap, Map<Id, SObject> newRecordMap) {
        helper.processBeforeUpdate();
    }
    
    public void beforeDelete(List<SObject> oldRecords, Map<Id, SObject> oldRecordMap) {
        helper.processBeforeDelete();
    }
    
    public void afterInsert(List<SObject> newRecords, Map<Id, SObject> newRecordMap) {
        helper.processAfterInsert();
    }
    
    public void afterUpdate(List<SObject> oldRecords, List<SObject> newRecords, 
                            Map<Id, SObject> oldRecordMap, Map<Id, SObject> newRecordMap) {
        helper.processAfterUpdate((List<Case__c>) newRecords, oldRecordMap);
    }
    
    public void afterDelete(List<SObject> oldRecords, Map<Id, SObject> oldRecordMap) {
        helper.processAfterDelete();
    }
    
    public void afterUndelete(List<SObject> newRecords, Map<Id, SObject> newRecordMap) {
        helper.processAfterUndelete();
    }
    
    
}