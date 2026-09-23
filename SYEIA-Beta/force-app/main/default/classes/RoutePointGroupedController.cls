public with sharing class RoutePointGroupedController {

    @AuraEnabled(cacheable=true)
    public static List<RouteWrapper> getRoutes(Id caseId) {

        System.debug('========================================');
        System.debug('>>> Case Id: ' + caseId);
        System.debug('========================================');


        List<RouteWrapper> results =
            new List<RouteWrapper>();


        if (caseId == null) {
            return results;
        }


        // =====================================================
        // 1. Get ALL Routes directly related to Case
        // =====================================================

        List<Route__c> routes = [
            SELECT
                Id,
                Name,
                Case__c
            FROM Route__c
            WHERE Case__c = :caseId
            ORDER BY Name ASC
        ];


        System.debug(
            '>>> Routes found: ' +
            routes.size()
        );


        if (routes.isEmpty()) {

            System.debug(
                '>>> No Routes found for Case: ' +
                caseId
            );

            return results;
        }


        // =====================================================
        // 2. Build Route Id Set
        // =====================================================

        Set<Id> routeIds =
            new Set<Id>();


        for (Route__c route : routes) {

            routeIds.add(route.Id);

            System.debug(
                '>>> Route Id: ' +
                route.Id +
                ' | Route Name: ' +
                route.Name
            );
        }


        // =====================================================
        // 3. Get Route Points DIRECTLY by Route__c
        //
        // Do NOT use:
        //
        // WHERE Route__r.Case__c = :caseId
        //
        // We already know which Routes belong to the Case.
        // =====================================================

        List<Route_Point__c> routePoints = [

            SELECT
                Id,
                Route__c,
                Easting__c,
                Northing__c,
                SequenceNumber__c,
                CreatedDate

            FROM Route_Point__c

            WHERE Route__c IN :routeIds

            ORDER BY
                Route__c ASC,
                SequenceNumber__c ASC,
                CreatedDate ASC
        ];


        System.debug(
            '========================================'
        );

        System.debug(
            '>>> Route Points found: ' +
            routePoints.size()
        );

        System.debug(
            '========================================'
        );


        // =====================================================
        // 4. Debug every Route Point
        // =====================================================

        for (Route_Point__c point : routePoints) {

            System.debug(
                '>>> ROUTE POINT' +
                ' | Id=' + point.Id +
                ' | Route=' + point.Route__c +
                ' | Sequence=' + point.SequenceNumber__c +
                ' | Easting=' + point.Easting__c +
                ' | Northing=' + point.Northing__c
            );
        }


        // =====================================================
        // 5. Group Route Points by Route
        // =====================================================

        Map<Id, List<RoutePointWrapper>>
            pointsByRoute =
                new Map<Id, List<RoutePointWrapper>>();


        for (Route_Point__c point : routePoints) {

            if (!pointsByRoute.containsKey(point.Route__c)) {

                pointsByRoute.put(
                    point.Route__c,
                    new List<RoutePointWrapper>()
                );
            }


            pointsByRoute
                .get(point.Route__c)
                .add(
                    new RoutePointWrapper(point)
                );
        }


        // =====================================================
        // 6. Create Wrapper for EVERY Route
        // =====================================================

        for (Route__c route : routes) {

            List<RoutePointWrapper> points =
                pointsByRoute.containsKey(route.Id)
                    ? pointsByRoute.get(route.Id)
                    : new List<RoutePointWrapper>();


            RoutePointWrapper startPoint = null;

            RoutePointWrapper endPoint = null;


            // =================================================
            // 7. Find Start Point
            //
            // SequenceNumber__c = 1
            // =================================================

            for (RoutePointWrapper point : points) {

                if (
                    point.sequenceNumber != null &&
                    point.sequenceNumber == 1
                ) {

                    startPoint = point;

                    break;
                }
            }


            // =================================================
            // 8. Find End Point
            //
            // Highest SequenceNumber__c
            // =================================================

            for (RoutePointWrapper point : points) {

                if (point.sequenceNumber == null) {
                    continue;
                }


                if (
                    endPoint == null ||
                    point.sequenceNumber >
                    endPoint.sequenceNumber
                ) {

                    endPoint = point;
                }
            }


            // =================================================
            // 9. Debug Route Result
            // =================================================

            System.debug(
                '----------------------------------------'
            );

            System.debug(
                '>>> ROUTE: ' +
                route.Name
            );

            System.debug(
                '>>> Route Id: ' +
                route.Id
            );

            System.debug(
                '>>> Point Count: ' +
                points.size()
            );


            if (startPoint != null) {

                System.debug(
                    '>>> START POINT' +
                    ' | Sequence=' +
                    startPoint.sequenceNumber +
                    ' | Easting=' +
                    startPoint.easting +
                    ' | Northing=' +
                    startPoint.northing
                );

            } else {

                System.debug(
                    '>>> START POINT: NULL'
                );
            }


            if (endPoint != null) {

                System.debug(
                    '>>> END POINT' +
                    ' | Sequence=' +
                    endPoint.sequenceNumber +
                    ' | Easting=' +
                    endPoint.easting +
                    ' | Northing=' +
                    endPoint.northing
                );

            } else {

                System.debug(
                    '>>> END POINT: NULL'
                );
            }


            // =================================================
            // 10. Add Route Result
            // =================================================

            results.add(
                new RouteWrapper(
                    route.Id,
                    route.Name,
                    startPoint,
                    endPoint,
                    points.size()
                )
            );
        }


        System.debug(
            '========================================'
        );

        System.debug(
            '>>> FINAL ROUTE COUNT: ' +
            results.size()
        );

        System.debug(
            '========================================'
        );


        return results;
    }



    // =========================================================
    // Route Wrapper
    // =========================================================

    public class RouteWrapper {

        @AuraEnabled
        public Id routeId;

        @AuraEnabled
        public String routeName;

        @AuraEnabled
        public RoutePointWrapper startPoint;

        @AuraEnabled
        public RoutePointWrapper endPoint;

        @AuraEnabled
        public Integer pointCount;


        public RouteWrapper(
            Id routeId,
            String routeName,
            RoutePointWrapper startPoint,
            RoutePointWrapper endPoint,
            Integer pointCount
        ) {

            this.routeId = routeId;

            this.routeName = routeName;

            this.startPoint = startPoint;

            this.endPoint = endPoint;

            this.pointCount = pointCount;
        }
    }



    // =========================================================
    // Route Point Wrapper
    // =========================================================

    public class RoutePointWrapper {

        @AuraEnabled
        public Id id;

        @AuraEnabled
        public String easting;

        @AuraEnabled
        public String northing;

        @AuraEnabled
        public Decimal sequenceNumber;


        public RoutePointWrapper(
            Route_Point__c point
        ) {

            this.id = point.Id;


            this.easting =
                point.Easting__c != null
                    ? point.Easting__c
                    : '';


            this.northing =
                point.Northing__c != null
                    ? point.Northing__c
                    : '';


            this.sequenceNumber =
                point.SequenceNumber__c;
        }
    }
}
