public with sharing class RoutePointGroupedController {

@AuraEnabled(cacheable=true)
public static List<RouteWrapper> getRoutes(Id caseId) {

    System.debug('>>> Case Id: ' + caseId);

    List<RouteWrapper> results = new List<RouteWrapper>();

    if (caseId == null) {
        return results;
    }

    // =====================================================
    // Get ALL Routes directly related to Case
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
        '>>> Routes found: ' + routes.size()
    );


    // =====================================================
    // Get Route Points through Route -> Case
    // This is the relationship that was working previously
    // =====================================================

    List<Route_Point__c> routePoints = [
        SELECT
            Id,
            Route__c,
            Route__r.Name,
            Route__r.Case__c,
            Easting__c,
            Northing__c,
            CreatedDate
        FROM Route_Point__c
        WHERE Route__r.Case__c = :caseId
        ORDER BY
            Route__c ASC,
            CreatedDate ASC
    ];

    System.debug(
        '>>> Route Points found: ' +
        routePoints.size()
    );


    // =====================================================
    // Group Route Points by Route
    // =====================================================

    Map<Id, List<RoutePointWrapper>> pointsByRoute =
        new Map<Id, List<RoutePointWrapper>>();


    for (Route_Point__c point : routePoints) {

        System.debug(
            '>>> Route Point: ' +
            point.Id +
            ' | Route: ' +
            point.Route__c +
            ' | Easting: ' +
            point.Easting__c +
            ' | Northing: ' +
            point.Northing__c
        );


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
    // Create wrapper for EVERY Route
    // =====================================================

    for (Route__c route : routes) {

        List<RoutePointWrapper> points =
            pointsByRoute.containsKey(route.Id)
                ? pointsByRoute.get(route.Id)
                : new List<RoutePointWrapper>();


        RoutePointWrapper startPoint = null;

        RoutePointWrapper endPoint = null;


        // First Route Point = Start
        if (points.size() >= 1) {

            startPoint = points[0];
        }


        // Second Route Point = End
        if (points.size() >= 2) {

            endPoint = points[1];
        }


        results.add(
            new RouteWrapper(
                route.Id,
                route.Name,
                startPoint,
                endPoint,
                points.size()
            )
        );


        System.debug(
            '>>> Route: ' +
            route.Name +
            ' | Points: ' +
            points.size()
        );
    }


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
        }
    }
}
