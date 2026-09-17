// geoConversionUtil.js
export class GeoConversionUtil {

    static LatLng(lat, lng) {
        return { lat, lng };
    }

    static osgbToLatLng(E, N) {

        const a = 6377563.396;
        const b = 6356256.909;
        const F0 = 0.9996012717;

        const phi0 = 49.0 * Math.PI / 180.0;
        const lambda0 = -2.0 * Math.PI / 180.0;

        const E0 = 400000.0;
        const N0 = -100000.0;

        const e2 = (a * a - b * b) / (a * a);
        const nConst = (a - b) / (a + b);

        let phi = phi0;
        let M = 0;

        while (true) {
            const dPhi = phi - phi0;
            const M1 = (1 + nConst + 5/4*nConst*nConst + 5/4*nConst*nConst*nConst) * dPhi;
            const M2 = (3*nConst + 3*nConst*nConst + 21/8*nConst*nConst*nConst) * Math.sin(dPhi) * Math.cos(phi + phi0);
            const M3 = (15/8*nConst*nConst + 15/8*nConst*nConst*nConst) * Math.sin(2*dPhi) * Math.cos(2*(phi + phi0));
            const M4 = 35/24*nConst*nConst*nConst * Math.sin(3*dPhi) * Math.cos(3*(phi + phi0));
            M = b * F0 * (M1 - M2 + M3 - M4);
            const newPhi = (N - N0 - M)/(a*F0) + phi;
            if (Math.abs(newPhi - phi) < 1e-12) { phi = newPhi; break; }
            phi = newPhi;
        }

        const sinPhi = Math.sin(phi);
        const nu = a * F0 / Math.sqrt(1 - e2 * sinPhi * sinPhi);
        const rho = a * F0 * (1 - e2) / Math.pow(1 - e2 * sinPhi * sinPhi, 1.5);
        const tanPhi = Math.tan(phi);
        const secPhi = 1 / Math.cos(phi);
        const dE = E - E0;

        const dE2 = dE*dE, dE3 = dE2*dE, dE4=dE2*dE2, dE5=dE4*dE, dE6=dE3*dE3, dE7=dE6*dE;

        const nu2 = nu*nu, nu3=nu2*nu, nu4=nu2*nu2, nu5=nu4*nu, nu7=nu4*nu2*nu;

        const VII  = tanPhi / (2 * rho * nu);
        const VIII = tanPhi / (24 * rho * nu3);
        const IX   = tanPhi / (720 * rho * nu5);
        const X    = secPhi / nu;
        const XI   = secPhi / (6 * nu3);
        const XII  = secPhi / (120 * nu5);
        const XIIA = secPhi / (5040 * nu7);

        const latRad = phi - VII*dE2 + VIII*dE4 - IX*dE6;
        const lngRad = lambda0 + X*dE - XI*dE3 + XII*dE5 - XIIA*dE7;

        return this.LatLng(latRad * 180/Math.PI, lngRad * 180/Math.PI);
    }
}