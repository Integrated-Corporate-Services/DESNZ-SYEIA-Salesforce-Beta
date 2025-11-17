public with sharing class InboundRequestTriggerHelper {
    public InboundRequestTriggerHelper() {
        System.debug('InboundRequestTriggerHelper instantiated');
    }

    public void processInboundRequest(List<Inbound_Request__c> newInboundRequest, Map<ID, SObject> newInboundRequestMap) {
        System.debug('Executing Process Inbound Request 1');

        // process the payload from new Inbound_Request__c records
        for (Inbound_Request__c inboundReq : newInboundRequest) {
            System.debug('Processing Inbound Request: ' + inboundReq.Id);
            if (inboundReq.Payload__c != null) {
                try {
                    S37ApplicationDTO s37App = S37ApplicationDTO.parse(inboundReq.Payload__c);
                    System.debug('Parsed S37 Application: ' + s37App);
                    // Further processing logic here
                    GW_CustomCase.createS37CaseFromAWS(s37App);
                } catch (Exception e) {
                    System.debug('Error parsing payload for Inbound Request ' + inboundReq.Id + ': ' + e.getMessage());
                }
            } else {
                System.debug('No payload found for Inbound Request: ' + inboundReq.Id);
            }
        }
    }
}