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
            // SORT POINTS BY SEQUENCE NUMBER
            // =================================================

            const sortedPoints =
                [...route.points]
                    .sort(
                        (a, b) =>
                            Number(a.sequenceNumber) -
                            Number(b.sequenceNumber)
                    );


            console.log(
                '🧭 Sorted points:',
                route.name,
                JSON.stringify(sortedPoints)
            );


            const path = [];


            // =================================================
            // CONVERT OSGB -> LAT/LNG
            // =================================================

            for (const p of sortedPoints) {

                const easting =
                    Number(p.easting);

                const northing =
                    Number(p.northing);


                if (
                    !Number.isFinite(easting) ||
                    !Number.isFinite(northing)
                ) {

                    console.error(
                        '❌ Invalid OSGB point:',
                        p
                    );

                    return;
                }


                const latlng =
                    GeoConversionUtil.osgbToLatLng(
                        easting,
                        northing
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
            // DRAW SEQUENCE NUMBER AT EACH ROUTE POINT
            // =================================================

            path.forEach(
                (coord, index) => {

                    const sequenceNumber =
                        sortedPoints[index]
                            .sequenceNumber;


                    L.marker(
                        coord,
                        {

                            icon:
                                L.divIcon({

                                    className:
                                        'route-point-number',

                                    html: `
                                        <span
                                            class="route-point-number-text"
                                        >
                                            ${sequenceNumber}
                                        </span>
                                    `,

                                    iconSize: [
                                        24,
                                        24
                                    ],

                                    iconAnchor: [
                                        12,
                                        12
                                    ]

                                }),

                            zIndexOffset: 500,

                            interactive: false

                        }
                    ).addTo(this.map);

                }
            );


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

                            iconSize: [
                                1,
                                1
                            ],

                            iconAnchor: [
                                0,
                                0
                            ]

                        }),

                    zIndexOffset:
                        1000,

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