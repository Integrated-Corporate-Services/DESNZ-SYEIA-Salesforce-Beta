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
}