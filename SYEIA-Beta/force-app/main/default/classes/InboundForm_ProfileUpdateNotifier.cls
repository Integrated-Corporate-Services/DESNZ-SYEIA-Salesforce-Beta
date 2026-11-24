/**
 * Emails the team inbox when an applicant changes their SYEIA profile (SYEIA-2040 AC3 / AC4).
 *
 * Draft letters cannot be updated automatically, so the team that owns the applicant's cases is told
 * to update them. For each profile update (name, title or address change):
 *   - the open Cases linked to the person's Party__c records are found (Party__c.Case__c, or the Case's
 *     applicant organisation DNO__c / its representative DNO__r.Representative__c);
 *   - those Cases are grouped by team using Profile_Update_Notification__mdt (Case_Types__c);
 *   - ONE email is sent per team - never one per Case.
 *
 * Recipients, team names and the optional sender live in Profile_Update_Notification__mdt so the
 * live team mailboxes can be set per environment without a code change.
 */
public inherited sharing class InboundForm_ProfileUpdateNotifier {

    public static final Set<String> CLOSED_CASE_STATUSES = new Set<String>{
        'Withdrawn', 'Rejected', 'Invalid', 'Archived'
    };

    public static final String SUBJECT_TEMPLATE = 'SYEIA applicant {0} profile has changed';
    public static final String SERVICE_NAME = 'Submit Your Energy Application Infrastructure (SYEIA)';
    public static final String DEFAULT_SENDER_NAME = 'SYEIA';

    private static final String ORGANISATION_RECORD_TYPE = 'Organisation';

    @TestVisible
    private static List<Profile_Update_Notification__mdt> configOverride;

    // Emails built by the last notify() call - lets tests check content without relying on delivery
    @TestVisible
    private static List<Messaging.SingleEmailMessage> lastEmails = new List<Messaging.SingleEmailMessage>();

    /**
     * One successful profile update and the Party__c records (already updated) it matched.
     */
    public class Notification {
        public final InboundForm_Processor.ProcessingResult result;
        public final List<Party__c> parties;

        public Notification(InboundForm_Processor.ProcessingResult result, List<Party__c> parties) {
            this.result = result;
            this.parties = parties;
        }
    }

    /**
     * Send one email per team per profile update. Returns the number of emails sent.
     */
    public static Integer notify(List<Notification> notifications) {
        lastEmails = new List<Messaging.SingleEmailMessage>();
        if (notifications == null || notifications.isEmpty()) {
            return 0;
        }

        Map<String, Profile_Update_Notification__mdt> configByCaseType = getConfigByCaseType();
        if (configByCaseType.isEmpty()) {
            return 0;
        }

        List<Case__c> openCases = queryOpenCases(notifications);
        Map<String, Id> senderIdByAddress = getSenderIds(configByCaseType.values());

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        List<Notification> owners = new List<Notification>();

        for (Notification notification : notifications) {
            Map<String, List<Case__c>> casesByTeam = new Map<String, List<Case__c>>();
            Map<String, Profile_Update_Notification__mdt> configByTeam =
                new Map<String, Profile_Update_Notification__mdt>();

            for (Case__c c : linkedCases(notification, openCases)) {
                Profile_Update_Notification__mdt config = configByCaseType.get(c.Case_Type__c);
                if (config == null) {
                    continue; // no team configured for this case type
                }
                if (!casesByTeam.containsKey(config.DeveloperName)) {
                    casesByTeam.put(config.DeveloperName, new List<Case__c>());
                    configByTeam.put(config.DeveloperName, config);
                }
                casesByTeam.get(config.DeveloperName).add(c);
            }

            for (String team : casesByTeam.keySet()) {
                emails.add(buildEmail(notification, configByTeam.get(team), casesByTeam.get(team), senderIdByAddress));
                owners.add(notification);
            }
        }

        lastEmails = emails;
        if (emails.isEmpty()) {
            return 0;
        }
        return send(emails, owners);
    }

    // ========================================================================
    // EMAIL
    // ========================================================================

    @TestVisible
    private static Messaging.SingleEmailMessage buildEmail(
            Notification notification,
            Profile_Update_Notification__mdt config,
            List<Case__c> teamCases,
            Map<String, Id> senderIdByAddress) {

        String role = contactRole(notification);
        String body = 'Dear ' + config.Team_Name__c + '\n\n'
            + 'The applicant ' + role + ' ' + contactName(notification)
            + ' for ' + organisationName(notification, teamCases)
            + ' has changed their profile information for their ' + SERVICE_NAME + ' service account.\n\n'
            + 'All draft letters addressed to them must be updated to show their new profile information.\n\n'
            + 'Do not reply to this email.';

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new List<String>{ config.Recipient_Email__c });
        email.setSubject(String.format(SUBJECT_TEMPLATE, new List<Object>{ role }));
        email.setPlainTextBody(body);
        email.setSaveAsActivity(false);
        email.setUseSignature(false);
        email.setBccSender(false);

        Id senderId = String.isBlank(config.Sender_Address__c)
            ? null
            : senderIdByAddress.get(config.Sender_Address__c.toLowerCase());
        if (senderId != null) {
            email.setOrgWideEmailAddressId(senderId);
        } else {
            email.setSenderDisplayName(DEFAULT_SENDER_NAME);
        }
        return email;
    }

    private static Integer send(List<Messaging.SingleEmailMessage> emails, List<Notification> owners) {
        List<Messaging.SendEmailResult> sendResults;
        try {
            sendResults = Messaging.sendEmail(emails, false);
        } catch (Exception e) {
            // e.g. sandbox email deliverability switched off
            for (Notification owner : owners) {
                owner.result.addWarning('Team notification email not sent: ' + e.getMessage());
            }
            Logger.error('Profile update team notification not sent: ' + e.getMessage());
            return 0;
        }

        Integer sent = 0;
        for (Integer i = 0; i < sendResults.size(); i++) {
            if (sendResults[i].isSuccess()) {
                sent++;
                continue;
            }
            List<String> messages = new List<String>();
            for (Messaging.SendEmailError err : sendResults[i].getErrors()) {
                messages.add(err.getMessage());
            }
            String message = 'Team notification email to ' + emails[i].getToAddresses()[0]
                + ' failed: ' + String.join(messages, '; ');
            owners[i].result.addWarning(message);
            Logger.error(message);
        }
        Logger.info('Profile update team notifications sent: ' + sent + ' of ' + emails.size());
        return sent;
    }

    /**
     * "contact" or "agent". Party__c has no agent marker yet, so every notification refers to the
     * applicant contact; switch here once agents can be identified.
     */
    private static String contactRole(Notification notification) {
        return 'contact';
    }

    /**
     * The person's (updated) name: their Individual party, else the first matched party.
     */
    private static String contactName(Notification notification) {
        String fallback = null;
        for (Party__c party : notification.parties) {
            if (String.isBlank(party.Name)) {
                continue;
            }
            if (party.RecordType?.DeveloperName == InboundForm_ProfileUpdateConfig.INDIVIDUAL_RECORD_TYPE) {
                return party.Name;
            }
            if (fallback == null) {
                fallback = party.Name;
            }
        }
        return fallback != null ? fallback : 'unknown';
    }

    /**
     * Applicant organisation(s) of the team's cases (Case.DNO__r.Name), else the person's own
     * Organisation party.
     */
    private static String organisationName(Notification notification, List<Case__c> teamCases) {
        Set<String> names = new Set<String>();
        for (Case__c c : teamCases) {
            if (String.isNotBlank(c.DNO__r?.Name)) {
                names.add(c.DNO__r.Name);
            }
        }
        if (names.isEmpty()) {
            for (Party__c party : notification.parties) {
                if (party.RecordType?.DeveloperName == ORGANISATION_RECORD_TYPE && String.isNotBlank(party.Name)) {
                    names.add(party.Name);
                }
            }
        }
        return names.isEmpty() ? 'their organisation' : String.join(new List<String>(names), ', ');
    }

    // ========================================================================
    // LOOKUPS
    // ========================================================================

    private static Map<String, Profile_Update_Notification__mdt> getConfigByCaseType() {
        List<Profile_Update_Notification__mdt> configs = configOverride != null
            ? configOverride
            : Profile_Update_Notification__mdt.getAll().values();

        Map<String, Profile_Update_Notification__mdt> configByCaseType =
            new Map<String, Profile_Update_Notification__mdt>();
        for (Profile_Update_Notification__mdt config : configs) {
            if (!config.Active__c
                    || String.isBlank(config.Recipient_Email__c)
                    || String.isBlank(config.Case_Types__c)) {
                continue;
            }
            for (String caseType : config.Case_Types__c.split(';')) {
                if (String.isNotBlank(caseType)) {
                    configByCaseType.put(caseType.trim(), config);
                }
            }
        }
        return configByCaseType;
    }

    private static List<Case__c> queryOpenCases(List<Notification> notifications) {
        Set<Id> partyIds = new Set<Id>();
        Set<Id> caseIds = new Set<Id>();
        for (Notification notification : notifications) {
            for (Party__c party : notification.parties) {
                partyIds.add(party.Id);
                if (party.Case__c != null) {
                    caseIds.add(party.Case__c);
                }
            }
        }

        return [
            SELECT Id, Case_Type__c, DNO__c, DNO__r.Name, DNO__r.Representative__c
            FROM Case__c
            WHERE (Id IN :caseIds OR DNO__c IN :partyIds OR DNO__r.Representative__c IN :partyIds)
              AND Status__c NOT IN :CLOSED_CASE_STATUSES
            ORDER BY CreatedDate ASC
        ];
    }

    private static List<Case__c> linkedCases(Notification notification, List<Case__c> openCases) {
        Set<Id> partyIds = new Set<Id>();
        Set<Id> caseIds = new Set<Id>();
        for (Party__c party : notification.parties) {
            partyIds.add(party.Id);
            caseIds.add(party.Case__c);
        }

        List<Case__c> linked = new List<Case__c>();
        for (Case__c c : openCases) {
            if (caseIds.contains(c.Id)
                    || partyIds.contains(c.DNO__c)
                    || partyIds.contains(c.DNO__r?.Representative__c)) {
                linked.add(c);
            }
        }
        return linked;
    }

    private static Map<String, Id> getSenderIds(List<Profile_Update_Notification__mdt> configs) {
        Set<String> addresses = new Set<String>();
        for (Profile_Update_Notification__mdt config : configs) {
            if (String.isNotBlank(config.Sender_Address__c)) {
                addresses.add(config.Sender_Address__c);
            }
        }

        Map<String, Id> senderIdByAddress = new Map<String, Id>();
        if (addresses.isEmpty()) {
            return senderIdByAddress;
        }
        for (OrgWideEmailAddress sender : [
                SELECT Id, Address FROM OrgWideEmailAddress WHERE Address IN :addresses
        ]) {
            senderIdByAddress.put(sender.Address.toLowerCase(), sender.Id);
        }
        return senderIdByAddress;
    }
}
