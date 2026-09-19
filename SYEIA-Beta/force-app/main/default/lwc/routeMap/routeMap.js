import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getRoutes from '@salesforce/apex/RouteMapController.getRoutes';

import LEAFLET from '@salesforce/resourceUrl/leaflet';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import { openTab } from 'lightning/platformWorkspaceApi';

// ✅ IMPORTANT: match your utility structure (CLASS)
import { GeoConversionUtil } from './geoConversionUtil';

export default class RouteMap extends LightningElement {

    @api recordId;
    routeId;

    map;
    routes;

    leafletLoaded = false;

    // =========================
    // APP PAGE PARAMS
    // =========================
    @wire(CurrentPageReference)
    setPageRef(pageRef) {
        if (!pageRef) return;

        this.recordId = this.recordId || pageRef.state?.c__caseId;
        this.routeId = pageRef.state?.c__routeId;

        if (this.recordId) {
            this.loadRoutes();
        }
    }

    // =========================
    // APEX WIRED (RECORD PAGE)
    // =========================
    @wire(getRoutes, { recordId: '$recordId' })
    wiredRoutes({ data, error }) {
        if (data) {
            this.routes = data;

            console.log('🟢 Routes received:', JSON.stringify(data));

            if (this.map) {
                this.renderRoutes(data);
            }
        }

        if (error) {
            console.error('❌ Apex error:', error);
        }
    }

    // =========================
    // LOAD LEAFLET
    // =========================
    renderedCallback() {
        if (this.leafletLoaded) return;
        this.leafletLoaded = true;

        Promise.all([
            loadStyle(this, LEAFLET + '/leaflet.css'),
            loadScript(this, LEAFLET + '/leaflet.js')
        ])
        .then(() => {
            console.log('🟢 Leaflet loaded');
            this.initMap();
        })
        .catch(error => {
            console.error('❌ Leaflet load failed', error);
        });
    }

    // =========================
    // INIT MAP
    // =========================
    initMap() {

        const container = this.template.querySelector('.map-container');
        if (!container) return;

        container.innerHTML = '';

        if (this.map) {
            this.map.remove();
        }

        this.map = L.map(container).setView([51.5074, -0.1278], 6);

        L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
            attribution: '&copy; OpenStreetMap'
        }).addTo(this.map);

        setTimeout(() => {
            this.map.invalidateSize(true);
        }, 200);

        if (this.routes) {
            this.renderRoutes(this.routes);
        }
    }

    // =========================
    // LOAD ROUTES (APP PAGE)
    // =========================
    loadRoutes() {
        getRoutes({
            recordId: this.recordId,
            routeId: this.routeId
        })
        .then(data => {
            this.routes = data;

            console.log('🟡 App routes:', JSON.stringify(data));

            if (this.map) {
                this.renderRoutes(data);
            }
        })
        .catch(error => {
            console.error('❌ Apex error:', error);
        });
    }

    // =========================
    // RENDER ROUTES (STRICT)
    // =========================
    renderRoutes(routes) {

        if (!this.map || !routes) return;

        // clear all except tile layer
        this.map.eachLayer(layer => {
            if (!(layer instanceof L.TileLayer)) {
                this.map.removeLayer(layer);
            }
        });

        const bounds = [];

        routes.forEach(route => {

            if (!route.points || route.points.length < 2) {
                console.error('❌ Route invalid (needs 2+ points):', route.name);
                return;
            }

            const sortedPoints = [...route.points]
                .sort((a, b) => a.sequence - b.sequence);

            const path = [];

            for (const p of sortedPoints) {

                if (
                    typeof p.easting !== 'number' ||
                    typeof p.northing !== 'number'
                ) {
                    console.error('❌ Invalid OSGB point:', p);
                    return;
                }

                // ✅ correct usage of your CLASS method
                const latlng = GeoConversionUtil.osgbToLatLng(p.easting, p.northing);

                if (
                    !latlng ||
                    typeof latlng.lat !== 'number' ||
                    typeof latlng.lng !== 'number'
                ) {
                    console.error('❌ Conversion failed:', p);
                    return;
                }

                path.push([latlng.lat, latlng.lng]);
                bounds.push([latlng.lat, latlng.lng]);
            }

            console.log('🧭 Route path:', route.name, path);

            if (path.length < 2) {
                console.error('❌ Skipping route (insufficient valid points):', route.name);
                return;
            }

            // draw line
            L.polyline(path, {
                color: route.color,
                weight: 5
            }).addTo(this.map);

            // markers
            path.forEach(coord => {
                L.marker(coord).addTo(this.map);
            });

            // label
            const mid = Math.floor(path.length / 2);

            L.marker(path[mid], {
                icon: L.divIcon({
                    className: 'route-label',
                    html: `
                        <span style="
                            background:white;
                            color:${route.color};
                            font-weight:bold;
                            padding:2px 6px;
                            border-radius:4px;
                            border:1px solid #ccc;
                        ">
                            ${route.name}
                        </span>
                    `
                })
            }).addTo(this.map);
        });

        if (bounds.length > 0) {
            this.map.fitBounds(bounds, { padding: [40, 40] });
        }

        this.map.invalidateSize(true);
    }

    // =========================
    // OPEN APP PAGE
    // =========================
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
        } catch (e) {
            console.error('❌ Console tab failed', e);
            window.open(url, '_blank');
        }
    }
}