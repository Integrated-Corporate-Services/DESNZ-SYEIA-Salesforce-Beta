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
        Utilities.logMethodEntry('processInboundRequest');
        System.debug('Executing Process Inbound Request Method');
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
                    Map<Id, String> errorMessages = new Map<Id, String>();
                    errorMessages.put(inboundReq.Id, 'Error parsing payload: ' + Utilities.formatException(e));
	                updateInboundRequestStatus(errorMessages);
                    Utilities.log('Error parsing payload for Inbound Request ' + inboundReq.Id + ': ' + Utilities.formatException(e));
                    System.debug('Error parsing payload for Inbound Request ' + inboundReq.Id + ': ' + e.getMessage());
                    return;
                }
            } else {
                System.debug('No payload found for Inbound Request: ' + inboundReq.Id);
            }
        }

        if (objectRecordMaps.isEmpty()) {
            Utilities.log('No valid Inbound Requests to process.');
            Utilities.logMethodExit('processInboundRequest');
            return;
        }
        try {
            commitRecords(objectRecordMaps);
        } catch (Exception e) {
            Utilities.log('Error committing records: ' + Utilities.formatException(e));
        }
        Utilities.logMethodExit('processInboundRequest');
        System.debug('Completed Processing Inbound Requests');
    }


    // Additional helper methods can be
    private static void commitRecords(Map<Id, Map<String, List<SObject>>> objectRecordMaps) {
        Utilities.logMethodEntry('commitRecords');
        
        // Implementation for committing records to the database

        List<Case__c> casesToInsert = new List<Case__c>();
        Map<Id, List<Route__c>> routesToInsertMap = new Map<Id, List<Route__c>>();
        Map<Id, List<Route_Point__c>> routePointsToInsertMap = new Map<Id, List<Route_Point__c>>();
        Map<Id, List<Party__c>> partyToInsertMap = new Map<Id, List<Party__c>>();
        Map<Id, List<Case_Party__c>> casePartyToInsertMap = new Map<Id, List<Case_Party__c>>();
        Map<Id, List<Sensitive_Area_Check__c>> sensitiveAreaCheckToInsertMap = new Map<Id, List<Sensitive_Area_Check__c>>();

        // Error messages on Inbound request level
        Map<Id, List<String>> errorMessagesMap = new Map<Id, List<String>>();

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
                // errorMessagesMap.put(inboundReqId, new List<String>{'No Case records to insert for Inbound Request: ' + inboundReqId});
            } else {
                errorMessagesMap.put(inboundReqId, new List<String>());
            }
        }

        Map<Id, sObject> insertCaseResultMap, insertRouteResultMap, insertRoutePointResultMap = new Map<Id, sObject>();
        Id inboundReqId = null;
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


        Utilities.logMethodExit('commitRecord');
        System.debug('Sensitive Area Check Records committed successfully.');
    }

    private static void commitRecord(Map<Id, List<String>> errorMessagesMap, List<SObject> recordsToInsert) {
        Utilities.logMethodEntry('commitRecord');
        // Implementation for committing a single record to the database
        Savepoint sp = Database.setSavePoint();

        // insert all records
        Database.SaveResult[] results = Database.insert(recordsToInsert, false);
        String errorMessages = '';
        Map<Id, List<String>> errorMap = new Map<Id, List<String>>();
        for (Database.SaveResult result : results) {
            if (!result.isSuccess()) {
                // result.getId()
                System.debug('Error inserting record: ' + result.getErrors()[0].getMessage());
                List<Id> errorIdList = new List<Id>();
                errorIdList.addAll(errorMap.keySet());

                getErrorMessageOnInboundRequest(errorMap, errorIdList[0], result.getErrors());
                Database.rollback(sp);
                System.debug('Rolling back transaction due to errors.');
            }
        }
        if (!errorMap.isEmpty()) {
            Map<Id, String> errorMapString = new Map<Id, String>();
            for (Id inboundReqId : errorMap.keySet()) {
                List<String> errorList = errorMap.get(inboundReqId);
                String combinedErrors = String.join(errorList, '; ');
                errorMapString.put(inboundReqId, combinedErrors);
            }
            updateInboundRequestStatus(errorMapString);
        }
        Utilities.logMethodExit('commitRecord');
    }

    private static void getErrorMessageOnInboundRequest(Map<Id, List<String>> errorMessagesMap, Id inboundReqId, List<Database.Error> errorObject) {
        Utilities.logMethodEntry('getErrorMessageOnInboundRequest');
        List<String> errorMessageList = errorMessagesMap.containsKey(inboundReqId) ? errorMessagesMap.get(inboundReqId) : new List<String>();
        for (Database.Error err : errorObject) {
            String errorMessage = 'Error Code: ' + err.getStatusCode() + ' - Message: ' + err.getMessage();
            errorMessageList.add(errorMessage);
        }
        errorMessagesMap.put(inboundReqId, errorMessageList);
        Utilities.logMethodExit('getErrorMessageOnInboundRequest');
    }

    @future
	public static void updateInboundRequestStatus(Map<Id, String> errorMessages) {
        Utilities.logMethodEntry('updateInboundRequestStatus');
        try {
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
        } catch (Exception ex) {
            Utilities.log(Utilities.formatException(ex));
        }
        
        Utilities.logMethodExit('updateInboundRequestStatus');
	}

}