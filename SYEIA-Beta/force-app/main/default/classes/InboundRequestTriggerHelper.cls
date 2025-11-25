public with sharing class InboundRequestTriggerHelper {
    public InboundRequestTriggerHelper() {
        System.debug('InboundRequestTriggerHelper instantiated');
    }

    public void processBeforeInsert() {
        System.debug('Executing Process Insert Method');
    }

    public void processBeforeUpdate() {
        System.debug('Executing Process Update Method');
    }

    public void processBeforeDelete() {
        System.debug('Executing Process Delete Method');
    }

    public void processAfterUpdate() {
        System.debug('Executing After Update Method');
    }

    public void processAfterDelete() {
        System.debug('Executing After Delete Method');
    }

    public void processAfterUndelete() {
        System.debug('Executing After Undelete Method');
    }

    public void processInboundRequest(List<Inbound_Request__c> newInboundRequest, Map<Id, sObject> newInboundRequestMap) {
        System.debug('Executing Process Inbound Request 1');
        Map<Id, Map<String, List<SObject>>> objectRecordMaps = new Map<Id, Map<String, List<SObject>>>();

        // process the payload from new Inbound_Request__c records
        for (Inbound_Request__c inboundReq : newInboundRequest) {
            System.debug('Processing Inbound Request: ' + inboundReq.Id);
            if (inboundReq.Payload__c != null) {
                try {
                    S37ApplicationDTO s37App = S37ApplicationDTO.parse(inboundReq.Payload__c);
                    // Further processing logic here
                    objectRecordMaps.put(inboundReq.Id, GW_CustomCase.createS37CaseFromAWS(s37App, inboundReq));
                } catch (Exception e) {
                    System.debug('Error parsing payload for Inbound Request ' + inboundReq.Id + ': ' + e.getMessage());
                }
            } else {
                System.debug('No payload found for Inbound Request: ' + inboundReq.Id);
            }
        }

        try {
            commitRecords(objectRecordMaps);
        } catch (Exception e) {
            System.debug('Error committing records: ' + e.getMessage());
        }
    }


    // Additional helper methods can be
    private static void commitRecords(Map<Id, Map<String, List<SObject>>> objectRecordMaps) {
        
        // Implementation for committing records to the database

        List<Case__c> casesToInsert = new List<Case__c>();
        Map<Id, List<Route__c>> routesToInsertMap = new Map<Id, List<Route__c>>();
        Map<Id, List<Route_Point__c>> routePointsToInsertMap = new Map<Id, List<Route_Point__c>>();
        Map<Id, List<Party__c>> partyToInsertMap = new Map<Id, List<Party__c>>();
        Map<Id, List<Case_Party__c>> casePartyToInsertMap = new Map<Id, List<Case_Party__c>>();
        Map<Id, List<Sensitive_Area_Check__c>> sensitiveAreaCheckToInsertMap = new Map<Id, List<Sensitive_Area_Check__c>>();

        // Error messages on Inbound request level
        Map<Id, String> errorMessagesMap = new Map<Id, String>();

        List<Case__c> caseToUpdateList = new List<Case__c>();

        for (Id inboundReqId : objectRecordMaps.keySet()) {
            casesToInsert.addAll((List<Case__c>) objectRecordMaps.get(inboundReqId).get('Case__c'));
            routesToInsertMap.put(inboundReqId, (List<Route__c>) objectRecordMaps.get(inboundReqId).get('Route__c'));
            routePointsToInsertMap.put(inboundReqId, (List<Route_Point__c>) objectRecordMaps.get(inboundReqId).get('Route_Point__c'));
            partyToInsertMap.put(inboundReqId, (List<Party__c>) objectRecordMaps.get(inboundReqId).get('Party__c'));
            casePartyToInsertMap.put(inboundReqId, (List<Case_Party__c>) objectRecordMaps.get(inboundReqId).get('Case_Party__c'));
            sensitiveAreaCheckToInsertMap.put(inboundReqId, (List<Sensitive_Area_Check__c>) objectRecordMaps.get(inboundReqId).get('Sensitive_Area_Check__c'));

            // error catcher 
            if (casesToInsert.isEmpty()) {
                errorMessagesMap.put(inboundReqId, 'No Case records to insert for Inbound Request: ' + inboundReqId);
            } else {
                errorMessagesMap.put(inboundReqId, '');
            }
        }

        Map<Id, sObject> insertCaseResultMap, insertRouteResultMap, insertRoutePointResultMap = new Map<Id, sObject>();
        commitRecord(errorMessagesMap, casesToInsert);
        System.debug('Case Records committed successfully.');

        // assign parent case to Route and insert 
        List<Route__c> routeListToInsert = new List<Route__c>();
        List<Case__c> caseRecList = [SELECT Id, Inbound_Request__c FROM Case__c WHERE Inbound_Request__c IN :objectRecordMaps.keySet()];

        for (Case__c caseRec : caseRecList) {
            for (Route__c routeRec : routesToInsertMap.get(caseRec.Inbound_Request__c)) {
                routeRec.Case__c = caseRec.Id;
                routeListToInsert.add(routeRec);
            }
        }
        commitRecord(errorMessagesMap, routeListToInsert);
        System.debug('Route Records committed successfully.');

        // assign parent route to Route Points and insert
        List<Route_Point__c> routePointsToInsert = new List<Route_Point__c>();
        for (Route__c routeRec : [
            SELECT Id, Case__r.Inbound_Request__c, Route_Id__c
            FROM Route__c 
            WHERE Case__r.Inbound_Request__c IN :routePointsToInsertMap.keySet()
        ]) {
            System.debug('Processing Route Record: ' + routeRec);
            for (Route_Point__c routePointRec : routePointsToInsertMap.get(routeRec.Case__r.Inbound_Request__c)) {
                System.debug(routeRec.Id + ' Assigning Route to Route Point: ' + routePointRec);
                if (routeRec.Route_Id__c == routePointRec.Route_Id__c) {
                    System.debug('Route Ids match: ' + routeRec.Route_Id__c + ' == ' + routePointRec.Route_Id__c);
                    routePointRec.Route__c = routeRec.Id;
                    routePointsToInsert.add(routePointRec);
                }
            }
        }
        System.debug('Route Points to Insert: ' + routePointsToInsert);
        commitRecord(errorMessagesMap, routePointsToInsert);
        System.debug('Route Point Records committed successfully.');

        // insert Party records
        List<Party__c> partyRecordsToInsert = new List<Party__c>();
        for (Case__c caseRec : caseRecList) {
            partyRecordsToInsert.addAll(partyToInsertMap.get(caseRec.Inbound_Request__c));
        }
        commitRecord(errorMessagesMap,partyRecordsToInsert);
        System.debug('Party Records committed successfully.');

        // insert Case Party records
        List<Case_Party__c> casePartyRecordsToInsert = new List<Case_Party__c>();
        for(Case__c caseRec : caseRecList) {
            System.debug('Processing Case Record for Case Party: ' + caseRec);
            for (Case_Party__c casePartyRec : casePartyToInsertMap.get(caseRec.Inbound_Request__c)) {
                casePartyRec.Case__c = caseRec.Id;
                for (Party__c partyRecord: partyToInsertMap.get(caseRec.Inbound_Request__c)) {
                    System.debug('Matching Party Record for Case Party: ' + partyToInsertMap.get(caseRec.Inbound_Request__c));
                    if (partyRecord.Application_Party_Id__c == casePartyRec.Application_Party_Id__c) {
                        System.debug('Party Ids match: ' + partyRecord.Application_Party_Id__c + ' == ' + casePartyRec.Application_Party_Id__c);
                        casePartyRec.Party__c = partyRecord.Id;
                    }
                }
                casePartyRecordsToInsert.add(casePartyRec);
            }
        }
        
        commitRecord(errorMessagesMap,casePartyRecordsToInsert);
        System.debug('Case Party Records committed successfully.');

        // update case record with DNO lookup
        for (Case__c caseRec : caseRecList) {
            for (Party__c partyRec : partyToInsertMap.get(caseRec.Inbound_Request__c)) {
                if (partyRec.Is_Primary__c) {
                    caseRec.DNO__c = partyRec.Id;
                    caseToUpdateList.add(caseRec);
                }
            }
        }
        update caseToUpdateList;
        System.debug('Case Records updated successfully with DNO lookup.');

        // sensitive area check records can be committed here similarly
        List<Sensitive_Area_Check__c> sensitiveAreaCheckRecordsToInsert = new List<Sensitive_Area_Check__c>();
        for (Case__c caseRec : caseRecList) {
            for(Sensitive_Area_Check__c sensitiveAreaCheckRec : sensitiveAreaCheckToInsertMap.get(caseRec.Inbound_Request__c)) {
                sensitiveAreaCheckRec.Case__c = caseRec.Id;
                sensitiveAreaCheckRecordsToInsert.add(sensitiveAreaCheckRec);
            }
        }
        commitRecord(errorMessagesMap, sensitiveAreaCheckRecordsToInsert);
        System.debug('Sensitive Area Check Records committed successfully.');
    }

    private static void commitRecord(Map<Id, String> errorMessagesMap, List<SObject> recordsToInsert) {
        // Implementation for committing a single record to the database
        Savepoint sp = Database.setSavePoint();

        // insert all records
        Database.SaveResult[] results = Database.insert(recordsToInsert, false);
        String errorMessages = '';
        Map<Id, String> errorMap = new Map<Id, String>();
        for (Database.SaveResult result : results) {
            if (!result.isSuccess()) {
                System.debug('Error inserting record: ' + result.getErrors()[0].getMessage());
                getErrorMessageOnInboundRequest(errorMap, recordsToInsert[0].Id, result.getErrors());
                Database.rollback(sp);
                System.debug('Rolling back transaction due to errors.');
            }
        }
        if (!errorMap.isEmpty()) {
            updateInboundRequestStatus(errorMap);
        }
    }

    private static void getErrorMessageOnInboundRequest(Map<Id, String> errorMessagesMap, Id inboundReqId, List<Database.Error> errorObject) {
        // for (Database.Error err : errorObject) {
        //     String errorMessage = 'Error Code: ' + err.getStatusCode() + ' - Message: ' + err.getMessage();
        //     appendErrorMessage(errorMessagesMap, inboundReqId, errorMessage);
        // }   
        // if (errorMessagesMap.containsKey(inboundReqId)) {
        //     String existingErrors = errorMessagesMap.get(inboundReqId);
        //     existingErrors += errorMessage + '\n';
        //     if(existingErrors.length() > 32000) {
        //         existingErrors = existingErrors.substring(0, 32000);
        //     }
        //     errorMessagesMap.put(inboundReqId, existingErrors);
        // } else {
        //     errorMessagesMap.put(inboundReqId, errorMessage + '\n');
        // }
    }

    @future
	public static void updateInboundRequestStatus(Map<Id, String> errorMessages) {
        List<Inbound_Request__c> inboundRequestsToUpdate = new List<Inbound_Request__c>();
        for (Id inboundReqId : errorMessages.keySet()) {
            Inbound_Request__c inboundReq = new Inbound_Request__c(Id = inboundReqId);
            String errors = errorMessages.get(inboundReqId);
            if (errors != '') {
                inboundReq.Status__c = 'Failed';
                inboundReq.Error_Log_Text__c += errors;
            } else {
                inboundReq.Status__c = 'Processed';
            }
            inboundRequestsToUpdate.add(inboundReq);
        }
        update inboundRequestsToUpdate;
	}

}