trigger FurtherInformationRequestedTrigger on Further_Information_Requested__c (after insert, after update) {
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
             system.debug('Raghu-furtherinfoTrigger');
            FurtherInfoRequestedEventPublisher.publishEvents(Trigger.new, null);
        } else if (Trigger.isUpdate) {
            FurtherInfoRequestedEventPublisher.publishEvents(Trigger.new, Trigger.oldMap);
        }
    }
}