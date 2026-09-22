import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getRoutes from '@salesforce/apex/RouteMapController.getRoutes';

import LEAFLET from '@salesforce/resourceUrl/leaflet';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import { openTab } from 'lightning/platformWorkspaceApi';

import { GeoConversionUtil } from './geoConversionUtil';

export default class RouteMap extends LightningElement {

    @api recordId;
    routeId;

    map;
    routes;

    leafletLoaded = false;


    // =====================================================
    // ROUTE COLOUR
    // =====================================================

    ROUTE_COLOR = '#1d70b8';


    // =====================================================
    // APP PAGE PARAMS
    // =====================================================

    @wire(CurrentPageReference)
    setPageRef(pageRef) {

        if (!pageRef) {
            return;
        }

        this.recordId =
            this.recordId ||
            pageRef.state?.c__caseId;

        this.routeId =
            pageRef.state?.c__routeId;

        if (this.recordId) {
            this.loadRoutes();
        }
    }


    // =====================================================
    // APEX WIRED - RECORD PAGE
    // =====================================================

    @wire(getRoutes, { recordId: '$recordId' })
    wiredRoutes({ data, error }) {

        if (data) {

            this.routes = data;

            console.log(
                '🟢 Routes received:',
                JSON.stringify(data)
            );

            if (this.map) {
                this.renderRoutes(data);
            }
        }

        if (error) {

            console.error(
                '❌ Apex error:',
                error
            );
        }
    }


    // =====================================================
    // LOAD LEAFLET
    // =====================================================

    renderedCallback() {

        if (this.leafletLoaded) {
            return;
        }

        this.leafletLoaded = true;

        Promise.all([
            loadStyle(
                this,
                LEAFLET + '/leaflet.css'
            ),

            loadScript(
                this,
                LEAFLET + '/leaflet.js'
            )
        ])
        .then(() => {

            console.log(
                '🟢 Leaflet loaded'
            );

            this.initMap();
        })
        .catch(error => {

            console.error(
                '❌ Leaflet load failed',
                error
            );
        });
    }


    // =====================================================
    // INIT MAP
    // =====================================================

    initMap() {

        const container =
            this.template.querySelector(
                '.map-container'
            );

        if (!container) {
            return;
        }

        container.innerHTML = '';

        if (this.map) {
            this.map.remove();
        }

        this.map = L.map(container)
            .setView(
                [51.5074, -0.1278],
                6
            );


        // =================================================
        // OPEN STREET MAP
        // =================================================

        L.tileLayer(
            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            {
                attribution:
                    '&copy; OpenStreetMap'
            }
        ).addTo(this.map);


        // =================================================
        // FIX INITIAL MAP SIZE
        // =================================================

        setTimeout(() => {

            if (this.map) {
                this.map.invalidateSize(true);
            }

        }, 200);


        // =================================================
        // RENDER ROUTES
        // =================================================

        if (this.routes) {
            this.renderRoutes(
                this.routes
            );
        }
    }


    // =====================================================
    // LOAD ROUTES - APP PAGE
    // =====================================================

    loadRoutes() {

        getRoutes({
            recordId: this.recordId,
            routeId: this.routeId
        })
        .then(data => {

            this.routes = data;

            console.log(
                '🟡 App routes:',
                JSON.stringify(data)
            );

            if (this.map) {
                this.renderRoutes(data);
            }
        })
        .catch(error => {

            console.error(
                '❌ Apex error:',
                error
            );
        });
    }


    // =====================================================
    // GET ROUTE LABEL ANGLE
    // =====================================================

    getRouteLabelAngle(path, mid) {

        /*
         * Use points immediately before and after
         * the midpoint to determine route direction.
         */

        const startIndex =
            Math.max(
                0,
                mid - 1
            );

        const endIndex =
            Math.min(
                path.length - 1,
                mid + 1
            );


        const start =
            this.map.latLngToContainerPoint(
                path[startIndex]
            );

        const end =
            this.map.latLngToContainerPoint(
                path[endIndex]
            );


        let angle =
            Math.atan2(
                end.y - start.y,
                end.x - start.x
            ) *
            180 /
            Math.PI;


        /*
         * Prevent route name from appearing upside down.
         */

        if (
            angle > 90 ||
            angle < -90
        ) {
            angle += 180;
        }


        return angle;
    }


    // =====================================================
    // RENDER ROUTES
    // =====================================================

    renderRoutes(routes) {

        if (!this.map || !routes) {
            return;
        }


        // =================================================
        // CLEAR EXISTING ROUTE LAYERS
        // KEEP TILE LAYER
        // =================================================

        this.map.eachLayer(layer => {

            if (!(layer instanceof L.TileLayer)) {

                this.map.removeLayer(
                    layer
                );
            }

        });


        const bounds = [];


        // =================================================
        // LOOP THROUGH ROUTES
        // =================================================

        routes.forEach(route => {


            // =================================================
            // VALIDATE ROUTE
            // =================================================

            if (
                !route.points ||
                route.points.length < 2
            ) {

                console.error(
                    '❌ Route invalid (needs 2+ points):',
                    route.name
                );

                return;
            }


            // =================================================
            // SORT POINTS
            // =================================================

            const sortedPoints =
                [...route.points]
                    .sort(
                        (a, b) =>
                            a.sequence - b.sequence
                    );


            const path = [];


            // =================================================
            // CONVERT OSGB -> LAT/LNG
            // =================================================

            for (const p of sortedPoints) {

                if (
                    typeof p.easting !== 'number' ||
                    typeof p.northing !== 'number'
                ) {

                    console.error(
                        '❌ Invalid OSGB point:',
                        p
                    );

                    return;
                }


                const latlng =
                    GeoConversionUtil.osgbToLatLng(
                        p.easting,
                        p.northing
                    );


                if (
                    !latlng ||
                    typeof latlng.lat !== 'number' ||
                    typeof latlng.lng !== 'number'
                ) {

                    console.error(
                        '❌ Conversion failed:',
                        p
                    );

                    return;
                }


                path.push([
                    latlng.lat,
                    latlng.lng
                ]);


                bounds.push([
                    latlng.lat,
                    latlng.lng
                ]);
            }


            // =================================================
            // VALIDATE PATH
            // =================================================

            if (path.length < 2) {

                console.error(
                    '❌ Skipping route:',
                    route.name
                );

                return;
            }


            console.log(
                '🧭 Route path:',
                route.name,
                path
            );


            // =================================================
            // DRAW ROUTE LINE
            // =================================================

            L.polyline(
                path,
                {
                    color:
                        this.ROUTE_COLOR,

                    weight: 5,

                    opacity: 1,

                    lineCap: 'round',

                    lineJoin: 'round'
                }
            ).addTo(this.map);


            // =================================================
            // DRAW X AT EACH ROUTE POINT
            // =================================================

            path.forEach(coord => {

                L.marker(
                    coord,
                    {

                        icon:
                            L.divIcon({

                                className:
                                    'route-point-x',

                                html: `
                                    <span
                                        class="route-x"
                                    >&#10005;</span>
                                `,

                                iconSize: [
                                    16,
                                    16
                                ],

                                iconAnchor: [
                                    8,
                                    8
                                ]

                            }),

                        interactive: false

                    }
                ).addTo(this.map);

            });


            // =================================================
            // ROUTE LABEL
            // =================================================

            const mid =
                Math.floor(
                    path.length / 2
                );


            // =================================================
            // CALCULATE ROUTE DIRECTION
            // =================================================

            const angle =
                this.getRouteLabelAngle(
                    path,
                    mid
                );


            // =================================================
            // CREATE ROUTE LABEL
            // =================================================

            L.marker(
                path[mid],
                {

                    icon:
                        L.divIcon({

                            className:
                                'route-label',

                            html: `
                                <span
                                    class="route-label-text"
                                    style="
                                        transform:
                                        translate(-50%, -50%)
                                        rotate(${angle}deg);
                                    "
                                >
                                    ${route.name}
                                </span>
                            `,

                            /*
                             * Invisible Leaflet anchor.
                             */
                            iconSize: [
                                1,
                                1
                            ],

                            iconAnchor: [
                                0,
                                0
                            ]

                        }),

                    /*
                     * Keep route name above
                     * route line and X markers.
                     */
                    zIndexOffset: 1000,

                    interactive: false

                }
            ).addTo(this.map);

        });


        // =================================================
        // FIT MAP TO ROUTES
        // =================================================

        if (bounds.length > 0) {

            this.map.fitBounds(
                bounds,
                {
                    padding: [
                        40,
                        40
                    ]
                }
            );
        }


        // =================================================
        // INVALIDATE MAP SIZE
        // =================================================

        this.map.invalidateSize(true);
    }


    // =====================================================
    // OPEN FULL MAP
    // =====================================================

    async openFullMap() {

        const url =
            `/lightning/n/Route_Map_App_Page` +
            `?c__caseId=${this.recordId}` +
            `&c__routeId=${this.routeId || ''}`;


        try {

            await openTab({
                url,
                focus: true
            });

        }
        catch (e) {

            console.error(
                '❌ Console tab failed',
                e
            );

            window.open(
                url,
                '_blank'
            );
        }
    }
}
