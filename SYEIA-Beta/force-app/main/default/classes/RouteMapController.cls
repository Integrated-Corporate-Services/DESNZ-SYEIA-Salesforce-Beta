public with sharing class RouteMapController {

    public class RoutePointDTO {
        @AuraEnabled public Double easting;
        @AuraEnabled public Double northing;
    }

    public class RouteDTO {
        @AuraEnabled public String name;
        @AuraEnabled public String color;
        @AuraEnabled public List<RoutePointDTO> points;
    }

    @AuraEnabled(cacheable=true)
    public static List<RouteDTO> getRoutes(Id recordId) {
        if (recordId == null) return new List<RouteDTO>();

        List<Route__c> routes = new List<Route__c>();

        // Determine the SObject type of the recordId
        Schema.SObjectType sobjectType = recordId.getSObjectType();

        if (sobjectType == Case__c.SObjectType) {
            // Case__c scenario
            routes = [
                SELECT Id, Name,
                       (SELECT Easting__c, Northing__c, Sequence_Number__c
                        FROM Route_Points__r
                        ORDER BY Sequence_Number__c ASC)
                FROM Route__c
                WHERE Case__c = :recordId
            ];
        } 
        else if (sobjectType == Route__c.SObjectType) {
            // Route__c scenario
            routes = [
                SELECT Id, Name,
                       (SELECT Easting__c, Northing__c, Sequence_Number__c
                        FROM Route_Points__r
                        ORDER BY Sequence_Number__c ASC)
                FROM Route__c
                WHERE Id = :recordId
            ];
        } 
        else {
            return new List<RouteDTO>(); // unsupported object
        }

        // Colors
        List<String> colors = new List<String>{'red', 'blue', 'green', 'orange', 'purple'};
        Integer index = 0;
        List<RouteDTO> results = new List<RouteDTO>();

        for (Route__c r : routes) {
            RouteDTO dto = new RouteDTO();
            dto.name = r.Name;
            dto.color = colors[Math.mod(index, colors.size())];
            dto.points = new List<RoutePointDTO>();

            for (Route_Point__c p : r.Route_Points__r) {
                RoutePointDTO pt = new RoutePointDTO();
                pt.easting = p.Easting__c != null ? Double.valueOf(p.Easting__c) : 0;
                pt.northing = p.Northing__c != null ? Double.valueOf(p.Northing__c) : 0;
                dto.points.add(pt);
            }

            results.add(dto);
            index++;
        }

        return results;
    }
}