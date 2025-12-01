public with sharing class Utilities {


    /* ============================================================
       EXCEPTION / LOGGING UTILITIES
    ============================================================ */

    /**
     * @description  Wraps an exception into an easy-to-read message.
    */
    public static String formatException(Exception e) {
        return e == null ? 'Unknown error.' :
            'Exception: ' + e.getMessage() +
            '\nLine: ' + e.getLineNumber() +
            '\nClass: ' + e.getTypeName() +
            '\nStack Trace: ' + e.getStackTraceString();
    }

    /**
     * @description  Simple debug wrapper with consistent formatting.
     */
    public static void log(Object message) {
        System.debug(LoggingLevel.INFO, ' ' + String.valueOf(message));
    }

    public static void logMethodEntry(String methodName) {
        System.debug(LoggingLevel.INFO, ' --- Entering Method: ' + methodName + ' --- ');
    }

    public static void logMethodExit(String methodName) {
        System.debug(LoggingLevel.INFO, ' --- Exiting Method: ' + methodName + ' --- ');
    }

    /**
     * Returns true if the input value is:
     * - null
     * - an empty string
     * - only whitespace characters
     */
    public static Boolean isNullOrBlank(Object value) {
        // Null is always blank
        if (value == null) return true;

        // If Boolean, false is NOT blank — treat only null as blank
        if (value instanceof Boolean) {
            return false; 
        }

        // If Number, not blank (unless null, handled above)
        if (value instanceof Integer ||
            value instanceof Long ||
            value instanceof Decimal ||
            value instanceof Double) {
            return false;
        }

        // Convert to string and test
        try {
            String s = String.valueOf(value);
            if (s == null) return true;

            // Replace isEmpty with a safe comparison
            return s.trim() == '';
        }
        catch (Exception ex) {
            // If conversion fails, treat as blank
            return true;
        }
    }
}