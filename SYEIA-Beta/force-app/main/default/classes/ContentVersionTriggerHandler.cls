/**
 * Trigger handler for ContentVersion object.
 *              Implements TriggerHandler interface and delegates to ContentVersionTriggerHelper.
 */
public class ContentVersionTriggerHandler implements TriggerHandler {
    
     private Boolean triggerIsExecuting;
    private Integer triggerSize;
    private ContentVersionTriggerHelper helper;
    
    public ContentVersionTriggerHandler(Boolean triggerIsExecuting, Integer triggerSize) {
        this.triggerIsExecuting = triggerIsExecuting;
        this.triggerSize = triggerSize;
        this.helper = new ContentVersionTriggerHelper();
    }
    
    public void beforeInsert(List<SObject> newRecords) {
        helper.processBeforeInsert((List<ContentVersion>) newRecords);
    }
    
    public void beforeUpdate(List<SObject> oldRecords, List<SObject> newRecords, 
                             Map<Id, SObject> oldRecordMap, Map<Id, SObject> newRecordMap) {
        helper.processBeforeUpdate(
            (List<ContentVersion>) oldRecords, 
            (List<ContentVersion>) newRecords, 
            oldRecordMap, 
            newRecordMap
        );
    }
    
    public void beforeDelete(List<SObject> oldRecords, Map<Id, SObject> oldRecordMap) {
        helper.processBeforeDelete();
    }
    
    public void afterInsert(List<SObject> newRecords, Map<Id, SObject> newRecordMap) {
        helper.processAfterInsert();
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