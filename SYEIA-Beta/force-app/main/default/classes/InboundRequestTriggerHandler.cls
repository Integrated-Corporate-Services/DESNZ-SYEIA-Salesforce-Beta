/**
 * @description Trigger handler for Inbound_Request__c object.
 *              Implements TriggerHandler interface and delegates to InboundRequestTriggerHelper.
 */
public class InboundRequestTriggerHandler implements TriggerHandler {
    
    private Boolean triggerIsExecuting;
    private Integer triggerSize;
    private InboundRequestTriggerHelper helper;
    
    public InboundRequestTriggerHandler(Boolean triggerIsExecuting, Integer triggerSize) {
        this.triggerIsExecuting = triggerIsExecuting;
        this.triggerSize = triggerSize;
        this.helper = new InboundRequestTriggerHelper();
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
        helper.processAfterInsert((List<Inbound_Request__c>) newRecords, newRecordMap);
    }
    
    public void afterUpdate(List<SObject> oldRecords, List<SObject> newRecords, 
                            Map<Id, SObject> oldRecordMap, Map<Id, SObject> newRecordMap) {
        helper.processAfterUpdate();
    }
    
    public void afterDelete(List<SObject> oldRecords, Map<Id, SObject> oldRecordMap) {
        helper.processAfterDelete();
    }
    
    public void afterUndelete(List<SObject> newRecords, Map<Id, SObject> newRecordMap) {
        helper.processAfterUndelete();
    }
}