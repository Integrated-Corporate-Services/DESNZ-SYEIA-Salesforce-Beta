public class InboundRequestTriggerHandler implements TriggerHandler {
    private boolean triggerIsExecuting;
    private integer triggerSize;
    public InboundRequestTriggerHelper helper;

    public InboundRequestTriggerHandler(boolean triggerIsExecuting, integer triggerSize) {
        this.triggerIsExecuting = triggerIsExecuting;
        this.triggerSize = triggerSize;
        this.helper = new InboundRequestTriggerHelper();
    }
    
    public void beforeInsert(List<Inbound_Request__c> newInboundRequest) { }

    public void beforeUpdate(List<Inbound_Request__c> oldInboundRequest, List<Inbound_Request__c> newInboundRequest, Map<ID, SObject> oldInboundRequestMap, Map<ID, SObject> newInboundRequestMap) {}

    public void beforeDelete(List<Inbound_Request__c> oldInboundRequest, Map<ID, SObject> oldInboundRequestMap) { }

    public void afterInsert(List<Inbound_Request__c> newInboundRequest, Map<ID, SObject> newInboundRequestMap) {
        helper.processInboundRequest(newInboundRequest, newInboundRequestMap);
    }

    public void afterUpdate(List<Inbound_Request__c> oldInboundRequest, List<Inbound_Request__c> newInboundRequest, Map<ID, SObject> oldInboundRequestMap, Map<ID, SObject> newInboundRequestMap) {}

    public void afterDelete(List<Inbound_Request__c> oldInboundRequest, Map<ID, SObject> oldInboundRequestMap) {}

    public void afterUndelete(List<Inbound_Request__c> newInboundRequest, Map<ID, SObject> newInboundRequestMap) {}

}