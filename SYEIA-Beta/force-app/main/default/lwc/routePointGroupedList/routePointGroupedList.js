import { LightningElement, api, wire } from 'lwc';

import getRoutes
    from '@salesforce/apex/RoutePointGroupedController.getRoutes';

import { NavigationMixin }
    from 'lightning/navigation';


export default class RoutePointGroupedList extends NavigationMixin(
    LightningElement
) {

    @api recordId;

    groups = [];

    error;

    collapsed = false;

    showAll = false;


    // =========================================================
    // Get Routes
    // =========================================================

    @wire(getRoutes, { caseId: '$recordId' })
    wiredRoutes({ data, error }) {

        console.log(
            '>>> LWC Case Id:',
            this.recordId
        );


        if (data) {

            console.log(
                '>>> LWC Apex data:',
                JSON.stringify(data)
            );


            this.error = undefined;


            // =================================================
            // Map Apex Routes
            // =================================================

            this.groups =
                data.map((route) => {


                    // =========================================
                    // Start Point
                    //
                    // Apex selects:
                    //
                    // 1. Sequence = 1
                    // OR
                    // 2. Earliest CreatedDate
                    // =========================================

                    const startPoint =
                        route.startPoint
                            ? {

                                id:
                                    route.startPoint.id,

                                sequenceNumber:
                                    route.startPoint.sequenceNumber,

                                createdDate:
                                    route.startPoint.createdDate,

                                easting:
                                    route.startPoint.easting || '',

                                northing:
                                    route.startPoint.northing || ''
                            }
                            : null;


                    // =========================================
                    // End Point
                    //
                    // Apex selects:
                    //
                    // 1. Highest Sequence
                    // OR
                    // 2. Latest CreatedDate
                    // =========================================

                    const endPoint =
                        route.endPoint
                            ? {

                                id:
                                    route.endPoint.id,

                                sequenceNumber:
                                    route.endPoint.sequenceNumber,

                                createdDate:
                                    route.endPoint.createdDate,

                                easting:
                                    route.endPoint.easting || '',

                                northing:
                                    route.endPoint.northing || ''
                            }
                            : null;


                    // =========================================
                    // Return Route Group
                    // =========================================

                    return {

                        routeId:
                            route.routeId,

                        routeName:
                            route.routeName,

                        pointCount:
                            route.pointCount || 0,

                        startPoint:
                            startPoint,

                        endPoint:
                            endPoint,

                        hasStartPoint:
                            startPoint !== null,

                        hasEndPoint:
                            endPoint !== null,

                        collapsed:
                            false,

                        icon:
                            'utility:chevrondown'
                    };
                });


            console.log(
                '>>> LWC groups:',
                JSON.stringify(this.groups)
            );


            this.showAll = false;

        }
        else if (error) {

            console.error(
                '>>> LWC ERROR:',
                JSON.stringify(error)
            );


            this.error =
                error;


            this.groups =
                [];
        }
    }


    // =========================================================
    // Total Routes
    // =========================================================

    get totalCount() {

        return this.groups.length;
    }


    // =========================================================
    // Has Routes
    // =========================================================

    get hasRoutes() {

        return this.groups.length > 0;
    }


    // =========================================================
    // Routes Shown
    // =========================================================

    get displayedGroups() {

        if (this.showAll) {

            return this.groups;
        }


        return this.groups.slice(
            0,
            3
        );
    }


    // =========================================================
    // View All
    // =========================================================

    get showViewAll() {

        return (
            this.groups.length > 3 &&
            !this.showAll
        );
    }


    handleViewAll() {

        this.showAll = true;
    }


    // =========================================================
    // Main Collapse
    // =========================================================

    get mainCollapseIcon() {

        return this.collapsed
            ? 'utility:chevronright'
            : 'utility:chevrondown';
    }


    toggleMainList() {

        this.collapsed =
            !this.collapsed;
    }


    // =========================================================
    // Route Collapse
    // =========================================================

    toggleGroup(event) {

        event.stopPropagation();


        const routeId =
            event.currentTarget.dataset.routeId;


        this.groups =
            this.groups.map((group) => {

                if (
                    group.routeId === routeId
                ) {

                    const newCollapsed =
                        !group.collapsed;


                    return {

                        ...group,

                        collapsed:
                            newCollapsed,

                        icon:
                            newCollapsed
                                ? 'utility:chevronright'
                                : 'utility:chevrondown'
                    };
                }


                return group;
            });
    }


    // =========================================================
    // Open Route
    // =========================================================

    openRoute(event) {

        event.preventDefault();

        event.stopPropagation();


        const routeId =
            event.currentTarget.dataset.id;


        if (!routeId) {

            return;
        }


        this[
            NavigationMixin.Navigate
        ]({

            type:
                'standard__recordPage',

            attributes: {

                recordId:
                    routeId,

                objectApiName:
                    'Route__c',

                actionName:
                    'view'
            }
        });
    }


    // =========================================================
    // Error
    // =========================================================

    get errorMessage() {

        if (!this.error) {

            return '';
        }


        if (
            this.error.body &&
            this.error.body.message
        ) {

            return this.error.body.message;
        }


        if (
            this.error.body &&
            Array.isArray(
                this.error.body
            )
        ) {

            return this.error.body
                .map(
                    (item) =>
                        item.message
                )
                .join(', ');
        }


        if (this.error.message) {

            return this.error.message;
        }


        return 'Unable to load Routes.';
    }
}
