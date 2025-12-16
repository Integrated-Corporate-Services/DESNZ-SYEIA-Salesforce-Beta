/**
 * @description Trigger for Inbound_Request__c object
 */
trigger InboundRequestTrigger on Inbound_Request__c (
    before insert, before update, before delete,
    after insert, after update, after delete, after undelete
) {
    InboundRequestTriggerHandler handler = new InboundRequestTriggerHandler(
        Trigger.isExecuting, 
        Trigger.size
    );
    
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            handler.beforeInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            handler.beforeUpdate(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);
        } else if (Trigger.isDelete) {
            handler.beforeDelete(Trigger.old, Trigger.oldMap);
        }
    } else if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            handler.afterInsert(Trigger.new, Trigger.newMap);
        } else if (Trigger.isUpdate) {
            handler.afterUpdate(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);
        } else if (Trigger.isDelete) {
            handler.afterDelete(Trigger.old, Trigger.oldMap);
        } else if (Trigger.isUndelete) {
            handler.afterUndelete(Trigger.new, Trigger.newMap);
        }
    }
}