import { LightningElement, api, wire } from 'lwc';
import getRoutes from '@salesforce/apex/RouteMapController.getRoutes';

import LEAFLET from '@salesforce/resourceUrl/leaflet';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import { GeoConversionUtil } from './geoConversionUtil'; // client-side converter

export default class Routemap extends LightningElement {
    @api recordId;

    map;
    initialized = false;
    routes; // store fetched data if map not yet initialized

    renderedCallback() {
        if (this.initialized) return;
        this.initialized = true;

        Promise.all([
            loadStyle(this, LEAFLET + '/leaflet.css'),
            loadScript(this, LEAFLET + '/leaflet.js')
        ])
        .then(() => this.initMap())
        .catch(error => console.error('Leaflet load error:', error));
    }

    initMap() {
        const container = this.template.querySelector('.map-container');
        this.map = L.map(container).setView([51.5074, -0.1278], 6);

        L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
            attribution: '&copy; OpenStreetMap contributors'
        }).addTo(this.map);

        // Force Leaflet to recalc size (important for record pages)
        setTimeout(() => {
            this.map.invalidateSize();
        }, 300);

        if (this.routes) {
            this.renderRoutes(this.routes);
        }
    }

    @wire(getRoutes, { recordId: '$recordId' })
    wiredRoutes({ data, error }) {
        if (data) {
            this.routes = data;
            if (this.map) {
                this.renderRoutes(data);
            }
        }
        if (error) {
            console.error('Apex error:', error);
        }
    }

    renderRoutes(routes) {
        if (!routes || routes.length === 0) return;

        const bounds = [];

        routes.forEach(route => {
            // Convert points
            const path = route.points.map(p => {
                const latlng = GeoConversionUtil.osgbToLatLng(p.easting, p.northing);
                bounds.push([latlng.lat, latlng.lng]);
                return [latlng.lat, latlng.lng];
            });

            // Adjust polyline weight for visibility
            const weight = Math.min(8, Math.max(4, path.length / 5));

            // Draw polyline
            L.polyline(path, { color: route.color, weight }).addTo(this.map);

            // Add marker at each point
            path.forEach(coord => L.marker(coord).addTo(this.map));

            // Add label at midpoint using DivIcon
            const midIndex = Math.floor(path.length / 2);
            const midPoint = path[midIndex];

            L.marker(midPoint, {
                icon: L.divIcon({
                    className: 'route-label',
                    html: `<span style="background:white; color:${route.color}; font-weight:bold; padding:2px 5px; border-radius:3px;">${route.name}</span>`,
                    iconSize: null
                })
            }).addTo(this.map);
        });

        // Fit bounds with minimum zoom for large routes
        if (bounds.length > 0) {
            this.map.fitBounds(bounds, { padding: [50, 50] });
            const minZoom = 6; // prevent zooming out too far
            if (this.map.getZoom() < minZoom) {
                this.map.setZoom(minZoom);
            }
        }

        // Extra: force redraw in case container was hidden initially
        setTimeout(() => {
            this.map.invalidateSize();
        }, 500);
    }
}