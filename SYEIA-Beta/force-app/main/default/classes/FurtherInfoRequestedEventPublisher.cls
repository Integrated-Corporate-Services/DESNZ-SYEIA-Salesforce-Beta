/**
 * Publishes Further_Information_Request_Event__e platform events when
 * Further_Information_Requested__c records are inserted or updated.
 *
 * Platform event fields:
 *   AWS_Application_Id__c   Text(255)
 *   Case__c                 Text(25)
 *   Payload__c              Long Text Area(130000)
 *   Type_of_Application__c  Text(10)
 *   Recipient_Type__c       (NWL only)
 *
 * Payload__c shape:
 *   { firId, requestId, responseDueDate, message [, FIR_Requested_Deadline] }
 *   FIR_Requested_Deadline is only included on update when the deadline changed.
 */
public with sharing class FurtherInfoRequestedEventPublisher {

    public static final String TYPE_S37 = 'S37';
    public static final String TYPE_NWL = 'NWL';

    // Field length limits on the platform event
    private static final Integer AWS_APP_ID_MAX = 255;
    private static final Integer CASE_MAX       = 25;
    private static final Integer APP_TYPE_MAX   = 10;
    private static final Integer PAYLOAD_MAX    = 130000;

    // Lets the test class inspect what was published
    @TestVisible
    private static List<Further_Information_Request_Event__e> publishedEvents =
        new List<Further_Information_Request_Event__e>();

    public static void publishEvents(
        List<Further_Information_Requested__c> newRecords,
        Map<Id, Further_Information_Requested__c> oldMap
    ) {
        if (newRecords == null || newRecords.isEmpty()) {
            return;
        }

        // 1. Collect the Case Ids from the incoming records
        Set<Id> caseIds = new Set<Id>();
        for (Further_Information_Requested__c rec : newRecords) {
            if (rec.Case__c != null) {
                caseIds.add(rec.Case__c);
            }
        }

        // 2. One query for all Cases (bulk-safe)
        Map<Id, Case__c> caseMap = new Map<Id, Case__c>([
            SELECT Id, Name, AWS_Application_Id__c
            FROM Case__c
            WHERE Id IN :caseIds
        ]);

        List<Further_Information_Request_Event__e> events =
            new List<Further_Information_Request_Event__e>();
        List<Id> sourceIds = new List<Id>(); // keeps results aligned with records

        for (Further_Information_Requested__c rec : newRecords) {
            Further_Information_Requested__c oldRec =
                (oldMap == null) ? null : oldMap.get(rec.Id);

            Case__c relatedCase = caseMap.get(rec.Case__c);
            String awsAppId = (relatedCase == null) ? null : relatedCase.AWS_Application_Id__c;
            String caseNamePrefix = (relatedCase == null || relatedCase.Name == null)
                ? null
                : relatedCase.Name.left(3);

            Further_Information_Request_Event__e evt = new Further_Information_Request_Event__e(
                AWS_Application_Id__c  = truncate(awsAppId, AWS_APP_ID_MAX),
                Case__c                = truncate(String.valueOf(rec.Case__c), CASE_MAX),
                Type_of_Application__c = truncate(caseNamePrefix, APP_TYPE_MAX),
                Payload__c             = truncate(buildPayload(rec, oldRec), PAYLOAD_MAX)
            );

            // Only populate recipient type for NWL applications
            if (caseNamePrefix == TYPE_NWL) {
                evt.Recipient_Type__c = rec.FIR_to_Applicant_or_Landowner__c;
            }

            events.add(evt);
            sourceIds.add(rec.Id);
        }

        if (events.isEmpty()) {
            return;
        }

        List<Database.SaveResult> results = EventBus.publish(events);
        publishedEvents.addAll(events);

        for (Integer i = 0; i < results.size(); i++) {
            if (!results[i].isSuccess()) {
                for (Database.Error err : results[i].getErrors()) {
                    System.debug(LoggingLevel.ERROR,
                        'Failed to publish Further_Information_Request_Event__e for record '
                        + sourceIds[i] + ': ' + err.getStatusCode() + ' - ' + err.getMessage());
                }
            }
        }
    }

    /**
     * Builds the payload without an old record (insert / direct calls).
     */
    @TestVisible
    private static String buildPayload(Further_Information_Requested__c rec) {
        return buildPayload(rec, null);
    }

    /**
     * Builds the JSON payload. FIR_Requested_Deadline is only included
     * on update when the deadline has changed.
     * JSONGenerator is used so the key order matches the agreed contract.
     */
    @TestVisible
    private static String buildPayload(
        Further_Information_Requested__c rec,
        Further_Information_Requested__c oldRec
    ) {
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
        writeStringOrNull(gen, 'firId', rec.Id == null ? null : String.valueOf(rec.Id));
        writeStringOrNull(gen, 'requestId', rec.Name);
        writeStringOrNull(gen, 'responseDueDate',
            rec.Further_Information_Requested_Deadline__c == null
                ? null
                : String.valueOf(rec.Further_Information_Requested_Deadline__c));
        writeStringOrNull(gen, 'message', rec.Additional_Information_Required__c);

        // Only on update, and only when the deadline has changed
        if (oldRec != null
                && rec.Further_Information_Requested_Deadline__c
                   != oldRec.Further_Information_Requested_Deadline__c) {
            writeStringOrNull(gen, 'FIR_Requested_Deadline',
                rec.Further_Information_Requested_Deadline__c == null
                    ? null
                    : String.valueOf(rec.Further_Information_Requested_Deadline__c));
        }

        gen.writeEndObject();
        return gen.getAsString();
    }

    private static void writeStringOrNull(JSONGenerator gen, String key, String value) {
        if (value == null) {
            gen.writeNullField(key);
        } else {
            gen.writeStringField(key, value);
        }
    }

    private static String truncate(String value, Integer maxLength) {
        return (value == null) ? null : value.left(maxLength);
    }
}