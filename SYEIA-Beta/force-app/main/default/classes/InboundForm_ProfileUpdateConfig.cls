/**
 * Applicant Profile Update configuration.
 *
 * Unlike the other InboundForm_*Config classes this event does NOT create a primary record, so it is not
 * registered as a FormTypeConfig in InboundForm_ConfigRegistry (the generic pipeline always inserts
 * a primary record). Instead InboundForm_Processor routes PROFILE_UPDATE events to
 * InboundForm_ProfileUpdateHandler, which updates existing Party__c / Address__c records matched on
 * Party__c.Email__c.
 *
 * This class is the single place that describes the payload contract and the JSON -> Salesforce mapping.
 *
 *   changes.firstName.newValue  -> Party__c.First_Name__c + Name   (Individual parties)
 *   changes.lastName.newValue   -> Party__c.Last_Name__c  + Name   (Individual parties)
 *   changes.workAddress.newValue -> Address__c linked to the matched parties (Address__c.Party__c)
 *        line1    -> Address_Line1__c
 *        line2    -> Address_Line_2__c
 *        townCity -> Town_City__c
 *        county   -> County__c
 *        postcode -> Postcode__c
 *   personalIdentifier          -> Party__c.Person_Identification__c, only when blank (all matched parties)
 */
public class InboundForm_ProfileUpdateConfig {

    public static final String FORM_TYPE = 'APPLICANT_PROFILE_UPDATE';
    public static final String EVENT_TYPE = 'PROFILE_UPDATE';
    public static final String DESCRIPTION = 'Applicant Portal profile update event (updates Party__c / Address__c)';

    // ----- Payload paths -----
    public static final String EVENT_TYPE_PATH = 'eventType';
    public static final String EMAIL_PATH = 'email';
    public static final String PERSONAL_IDENTIFIER_PATH = 'personalIdentifier';
    public static final String CHANGES_PATH = 'changes';
    public static final String NEW_VALUE_KEY = 'newValue';
    public static final String OLD_VALUE_KEY = 'oldValue';

    // ----- Change keys (children of "changes") -----
    public static final String FIRST_NAME_KEY = 'firstName';
    public static final String LAST_NAME_KEY = 'lastName';
    public static final String WORK_ADDRESS_KEY = 'workAddress';

    public static final Set<String> SUPPORTED_CHANGE_KEYS = new Set<String>{
        FIRST_NAME_KEY, LAST_NAME_KEY, WORK_ADDRESS_KEY
    };

    // ----- workAddress.newValue key -> Address__c field -----
    public static final Map<String, String> ADDRESS_FIELD_MAPPING = new Map<String, String>{
        'line1'    => 'Address_Line1__c',
        'line2'    => 'Address_Line_2__c',
        'townCity' => 'Town_City__c',
        'county'   => 'County__c',
        'postcode' => 'Postcode__c'
    };

    // ----- Party__c record types -----
    public static final String INDIVIDUAL_RECORD_TYPE = 'Individual';

    // Party__c.Name is a standard 80 character Text name field
    public static final Integer NAME_MAX_LENGTH = 80;

    /**
     * True when the payload eventType is a profile update (tolerates case, '_', '-', ' ' differences).
     */
    public static Boolean isProfileUpdateEvent(String eventType) {
        if (String.isBlank(eventType)) {
            return false;
        }
        String normalized = eventType.toUpperCase().replace('_', '').replace('-', '').replace(' ', '');
        return normalized == 'PROFILEUPDATE' || normalized == 'PROFILEUPDATED';
    }
}
