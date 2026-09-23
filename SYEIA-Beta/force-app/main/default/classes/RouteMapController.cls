public with sharing class RouteMapController {

    // =========================================================
    // Route Point DTO
    // =========================================================

    public class RoutePointDTO {

        @AuraEnabled
        public Double easting;

        @AuraEnabled
        public Double northing;

        @AuraEnabled
        public Decimal sequenceNumber;
    }


    // =========================================================
    // Route DTO
    // =========================================================

    public class RouteDTO {

        @AuraEnabled
        public String name;

        @AuraEnabled
        public String color;

        @AuraEnabled
        public List<RoutePointDTO> points;
    }


    // =========================================================
    // Get Routes
    // =========================================================

    @AuraEnabled(cacheable=true)
    public static List<RouteDTO> getRoutes(Id recordId) {

        List<RouteDTO> results =
            new List<RouteDTO>();


        if (recordId == null) {
            return results;
        }


        List<Route__c> routes =
            new List<Route__c>();


        // =====================================================
        // Determine SObject Type
        // =====================================================

        Schema.SObjectType sobjectType =
            recordId.getSObjectType();


        // =====================================================
        // CASE
        // =====================================================

        if (
            sobjectType ==
            Case__c.SObjectType
        ) {

            routes = [
                SELECT
                    Id,
                    Name,

                    (
                        SELECT
                            Id,
                            Easting__c,
                            Northing__c,
                            SequenceNumber__c

                        FROM Route_Points__r

                        ORDER BY
                            SequenceNumber__c ASC
                    )

                FROM Route__c

                WHERE Case__c = :recordId

                ORDER BY
                    Name ASC
            ];
        }


        // =====================================================
        // ROUTE
        // =====================================================

        else if (
            sobjectType ==
            Route__c.SObjectType
        ) {

            routes = [
                SELECT
                    Id,
                    Name,

                    (
                        SELECT
                            Id,
                            Easting__c,
                            Northing__c,
                            SequenceNumber__c

                        FROM Route_Points__r

                        ORDER BY
                            SequenceNumber__c ASC
                    )

                FROM Route__c

                WHERE Id = :recordId
            ];
        }


        // =====================================================
        // UNSUPPORTED RECORD
        // =====================================================

        else {

            return results;
        }


        // =====================================================
        // ROUTE COLOURS
        // =====================================================

        List<String> colors =
            new List<String>{
                'red',
                'blue',
                'green',
                'orange',
                'purple'
            };


        Integer colorIndex = 0;


        // =====================================================
        // BUILD DTOs
        // =====================================================

        for (Route__c route : routes) {

            RouteDTO routeDTO =
                new RouteDTO();


            routeDTO.name =
                route.Name;


            routeDTO.color =
                colors[
                    Math.mod(
                        colorIndex,
                        colors.size()
                    )
                ];


            routeDTO.points =
                new List<RoutePointDTO>();


            // =================================================
            // BUILD ROUTE POINT DTOs
            // =================================================

            for (
                Route_Point__c point :
                route.Route_Points__r
            ) {

                RoutePointDTO pointDTO =
                    new RoutePointDTO();


                // =============================================
                // EASTING
                // =============================================

                pointDTO.easting =
                    point.Easting__c != null
                        ? Double.valueOf(
                            point.Easting__c
                        )
                        : null;


                // =============================================
                // NORTHING
                // =============================================

                pointDTO.northing =
                    point.Northing__c != null
                        ? Double.valueOf(
                            point.Northing__c
                        )
                        : null;


                // =============================================
                // SEQUENCE
                // =============================================

                pointDTO.sequenceNumber =
                    point.SequenceNumber__c;


                routeDTO.points.add(
                    pointDTO
                );
            }


            results.add(
                routeDTO
            );


            colorIndex++;
        }


        // =====================================================
        // DEBUG
        // =====================================================

        System.debug(
            '>>> RouteMapController results: ' +
            JSON.serialize(results)
        );


        return results;
    }
}
