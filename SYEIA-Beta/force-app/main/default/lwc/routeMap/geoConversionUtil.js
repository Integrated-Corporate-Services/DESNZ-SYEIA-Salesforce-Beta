// =====================================================
// GeoConversionUtil

// =====================================================

export class GeoConversionUtil {


    // =====================================================
    // LAT / LNG OBJECT
    // =====================================================

    static LatLng(lat, lng) {

        return {
            lat,
            lng
        };
    }


    // =====================================================
    // AIRY 1830 (OSGB36) -> WGS84
    // 7-parameter Helmert transform.
    // Same 7 params as the +towgs84 clause on the frontend's
    // proj4 EPSG:27700 definition - keep the two in sync.
    // =====================================================

    static toWgs84(lat, lon) {

        const toRad =
            (deg) =>
                deg *
                Math.PI /
                180;

        const toDeg =
            (rad) =>
                rad *
                180 /
                Math.PI;


        // ---- Airy 1830 (source ellipsoid) ------------------

        const a1 =
            6377563.396;

        const b1 =
            6356256.909;

        const e1Sq =
            (a1 * a1 - b1 * b1) /
            (a1 * a1);


        // ---- WGS84 (target ellipsoid) -----------------------

        const a2 =
            6378137.0;

        const b2 =
            6356752.314245;

        const e2Sq =
            (a2 * a2 - b2 * b2) /
            (a2 * a2);


        // ---- Helmert parameters ------------------------------
        // Identical to the frontend's +towgs84 string.

        const tx =
            446.448;

        const ty =
            -125.157;

        const tz =
            542.060;

        const rx =
            toRad(0.1502 / 3600);

        const ry =
            toRad(0.2470 / 3600);

        const rz =
            toRad(0.8421 / 3600);

        const s =
            -20.4894 / 1e6;


        // ---- lat/lon (Airy1830, h=0) -> cartesian -----------

        const phi =
            toRad(lat);

        const lambda =
            toRad(lon);

        const sinPhi =
            Math.sin(phi);

        const cosPhi =
            Math.cos(phi);

        const sinLambda =
            Math.sin(lambda);

        const cosLambda =
            Math.cos(lambda);

        const nu1 =
            a1 /
            Math.sqrt(
                1 -
                e1Sq *
                sinPhi *
                sinPhi
            );

        const x1 =
            nu1 *
            cosPhi *
            cosLambda;

        const y1 =
            nu1 *
            cosPhi *
            sinLambda;

        const z1 =
            (1 - e1Sq) *
            nu1 *
            sinPhi;


        // ---- apply Helmert transform -> WGS84 cartesian -----

        const x2 =
            tx +
            x1 * (1 + s) -
            y1 * rz +
            z1 * ry;

        const y2 =
            ty +
            x1 * rz +
            y1 * (1 + s) -
            z1 * rx;

        const z2 =
            tz -
            x1 * ry +
            y1 * rx +
            z1 * (1 + s);


        // ---- cartesian -> lat/lon on WGS84 (iterative) ------

        const p =
            Math.sqrt(
                x2 * x2 +
                y2 * y2
            );

        let phi2 =
            Math.atan2(
                z2,
                p * (1 - e2Sq)
            );

        for (let i = 0; i < 10; i++) {

            const nu2 =
                a2 /
                Math.sqrt(
                    1 -
                    e2Sq *
                    Math.sin(phi2) *
                    Math.sin(phi2)
                );

            const phiNext =
                Math.atan2(
                    z2 +
                    e2Sq *
                    nu2 *
                    Math.sin(phi2),
                    p
                );

            if (
                Math.abs(
                    phiNext -
                    phi2
                ) <
                1e-12
            ) {

                phi2 =
                    phiNext;

                break;
            }

            phi2 =
                phiNext;
        }

        const lambda2 =
            Math.atan2(
                y2,
                x2
            );


        return this.LatLng(
            toDeg(phi2),
            toDeg(lambda2)
        );
    }


    // =====================================================
    // OSGB36 / BRITISH NATIONAL GRID
    // -> LATITUDE / LONGITUDE
    // =====================================================

    static osgbToLatLng(E, N) {

        console.log(
            '========================================'
        );

        console.log(
            '🌍 OSGB CONVERSION INPUT'
        );

        console.log(
            'Easting:',
            E
        );

        console.log(
            'Northing:',
            N
        );


        // =================================================
        // OSGB36 ELLIPSOID
        // =================================================

        const a =
            6377563.396;

        const b =
            6356256.909;

        const F0 =
            0.9996012717;


        // =================================================
        // TRUE ORIGIN
        // =================================================

        const phi0 =
            49.0 *
            Math.PI /
            180.0;

        const lambda0 =
            -2.0 *
            Math.PI /
            180.0;


        // =================================================
        // FALSE ORIGIN
        // =================================================

        const E0 =
            400000.0;

        const N0 =
            -100000.0;


        // =================================================
        // ECCENTRICITY
        // =================================================

        const e2 =
            (a * a - b * b) /
            (a * a);


        // =================================================
        // n CONSTANT
        // =================================================

        const nConst =
            (a - b) /
            (a + b);


        // =================================================
        // ITERATE LATITUDE
        // =================================================

        let phi =
            phi0;

        let M =
            0;


        while (true) {

            const dPhi =
                phi - phi0;


            const M1 =
                (
                    1 +
                    nConst +
                    5 / 4 *
                    nConst *
                    nConst +
                    5 / 4 *
                    nConst *
                    nConst *
                    nConst
                ) *
                dPhi;


            const M2 =
                (
                    3 *
                    nConst +
                    3 *
                    nConst *
                    nConst +
                    21 / 8 *
                    nConst *
                    nConst *
                    nConst
                ) *
                Math.sin(dPhi) *
                Math.cos(
                    phi + phi0
                );


            const M3 =
                (
                    15 / 8 *
                    nConst *
                    nConst +
                    15 / 8 *
                    nConst *
                    nConst *
                    nConst
                ) *
                Math.sin(
                    2 * dPhi
                ) *
                Math.cos(
                    2 * (
                        phi +
                        phi0
                    )
                );


            const M4 =
                35 / 24 *
                nConst *
                nConst *
                nConst *
                Math.sin(
                    3 * dPhi
                ) *
                Math.cos(
                    3 * (
                        phi +
                        phi0
                    )
                );


            M =
                b *
                F0 *
                (
                    M1 -
                    M2 +
                    M3 -
                    M4
                );


            const newPhi =
                (
                    N -
                    N0 -
                    M
                ) /
                (
                    a *
                    F0
                ) +
                phi;


            if (
                Math.abs(
                    newPhi -
                    phi
                ) <
                1e-12
            ) {

                phi =
                    newPhi;

                break;
            }


            phi =
                newPhi;
        }


        // =================================================
        // CALCULATE RADII
        // =================================================

        const sinPhi =
            Math.sin(phi);


        const nu =
            a *
            F0 /
            Math.sqrt(
                1 -
                e2 *
                sinPhi *
                sinPhi
            );


        const rho =
            a *
            F0 *
            (
                1 -
                e2
            ) /
            Math.pow(
                1 -
                e2 *
                sinPhi *
                sinPhi,
                1.5
            );


        const tanPhi =
            Math.tan(phi);


        const secPhi =
            1 /
            Math.cos(phi);


        // =================================================
        // DIFFERENCE FROM FALSE EASTING
        // =================================================

        const dE =
            E -
            E0;


        // =================================================
        // EASTING POWERS
        // =================================================

        const dE2 =
            dE *
            dE;

        const dE3 =
            dE2 *
            dE;

        const dE4 =
            dE2 *
            dE2;

        const dE5 =
            dE4 *
            dE;

        const dE6 =
            dE3 *
            dE3;

        const dE7 =
            dE6 *
            dE;


        // =================================================
        // NU POWERS
        // =================================================

        const nu2 =
            nu *
            nu;

        const nu3 =
            nu2 *
            nu;

        const nu4 =
            nu2 *
            nu2;

        const nu5 =
            nu4 *
            nu;

        const nu7 =
            nu4 *
            nu2 *
            nu;


        // =================================================
        // SERIES COEFFICIENTS
        // =================================================

        const VII =
            tanPhi /
            (
                2 *
                rho *
                nu
            );


        const VIII =
            tanPhi /
            (
                24 *
                rho *
                nu3
            );


        const IX =
            tanPhi /
            (
                720 *
                rho *
                nu5
            );


        const X =
            secPhi /
            nu;


        const XI =
            secPhi /
            (
                6 *
                nu3
            );


        const XII =
            secPhi /
            (
                120 *
                nu5
            );


        const XIIA =
            secPhi /
            (
                5040 *
                nu7
            );


        // =================================================
        // CALCULATE LATITUDE
        // =================================================

        const latRad =
            phi -
            VII *
            dE2 +
            VIII *
            dE4 -
            IX *
            dE6;


        // =================================================
        // CALCULATE LONGITUDE
        // =================================================

        const lngRad =
            lambda0 +
            X *
            dE -
            XI *
            dE3 +
            XII *
            dE5 -
            XIIA *
            dE7;


        // =================================================
        // CONVERT TO DEGREES
        // (still OSGB36 / Airy 1830 at this point)
        // =================================================

        const latitude =
            latRad *
            180 /
            Math.PI;


        const longitude =
            lngRad *
            180 /
            Math.PI;


        const result =
            this.toWgs84(
                latitude,
                longitude
            );


        // =================================================
        // DEBUG OUTPUT
        // =================================================

        console.log(
            '🌍 OSGB CONVERSION RESULT'
        );

        console.log(
            'Easting:',
            E
        );

        console.log(
            'Northing:',
            N
        );

        console.log(
            'Latitude (OSGB36):',
            latitude
        );

        console.log(
            'Longitude (OSGB36):',
            longitude
        );

        console.log(
            'Latitude (WGS84):',
            result.lat
        );

        console.log(
            'Longitude (WGS84):',
            result.lng
        );

        console.log(
            'LatLng object:',
            JSON.stringify(result)
        );

        console.log(
            '========================================'
        );


        return result;
    }
} 