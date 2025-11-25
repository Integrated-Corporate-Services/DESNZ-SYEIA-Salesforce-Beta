public class InboundRequestTriggerHandler implements TriggerHandler {
    private boolean triggerIsExecuting;
    private integer triggerSize;
    public InboundRequestTriggerHelper helper;

    public InboundRequestTriggerHandler(boolean triggerIsExecuting, integer triggerSize) {
        this.triggerIsExecuting = triggerIsExecuting;
        this.triggerSize = triggerSize;
        this.helper = new InboundRequestTriggerHelper();
    }
    
    public void beforeInsert(List<Inbound_Request__c> newInboundRequest) {
        helper.processBeforeInsert();
    }

    public void beforeUpdate(List<Inbound_Request__c> oldInboundRequest, List<Inbound_Request__c> newInboundRequest, Map<ID, SObject> oldInboundRequestMap, Map<ID, SObject> newInboundRequestMap) {
        helper.processBeforeUpdate();
    }

    public void beforeDelete(List<Inbound_Request__c> oldInboundRequest, Map<ID, SObject> oldInboundRequestMap) { 
        helper.processBeforeDelete();
    }

    public void afterInsert(List<Inbound_Request__c> newInboundRequest, Map<ID, SObject> newInboundRequestMap) {
        helper.processInboundRequest(newInboundRequest, newInboundRequestMap);
    }

    public void afterUpdate(List<Inbound_Request__c> oldInboundRequest, List<Inbound_Request__c> newInboundRequest, Map<ID, SObject> oldInboundRequestMap, Map<ID, SObject> newInboundRequestMap) {
        helper.processAfterUpdate();
    }

    public void afterDelete(List<Inbound_Request__c> oldInboundRequest, Map<ID, SObject> oldInboundRequestMap) {
        helper.processAfterDelete();
    }

    public void afterUndelete(List<Inbound_Request__c> newInboundRequest, Map<ID, SObject> newInboundRequestMap) {  
        helper.processAfterUndelete();
    }

}