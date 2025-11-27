public with sharing class CaseDeadlineReminderController {
    public CaseDeadlineReminderController() {}

    @AuraEnabled(cacheable=true)
    public static List<Case__c> getCasesWithUpcomingDeadlines() {
        Date today = Date.today();
        Date upcomingDate = today.addDays(7);
        Date decisionDateNow = Date.today().addDays(-7);

        List<Case__c> casesWithDeadlines = [
            SELECT Id, Applicant_Reference__c, Decision_Deadline_Formula__c, Decision_Deadline_Display__c
            FROM Case__c 
            WHERE 
            Case_Type__c IN :getDeadlineConfig().keySet()
                AND Decision_Deadline_Formula__c != null 
                AND (Decision_Deadline_Formula__c >= :decisionDateNow
                AND Decision_Deadline_Formula__c <= :upcomingDate)
            ORDER BY Decision_Deadline_Formula__c 
            ASC
        ];
        System.debug('What do we have here ' + casesWithDeadlines);
        return casesWithDeadlines;

    }

    private static Map<String, Integer> getDeadlineConfig() {
        Map<String, Integer> transformedCases = new Map<String, Integer>();
        // Map<String, Application_Deadline_Reminder_Config__mdt> configMap = Application_Deadline_Reminder_Config__mdt.getAll();
        for (Application_Deadline_Reminder_Config__mdt config : Application_Deadline_Reminder_Config__mdt.getAll().values()) {
            if(config.Show_in_Reminder_List__c == true) {
                String caseForm = String.valueOf(config.Case_Form__c);
                transformedCases.put(caseForm, Integer.valueOf(config.Advance_Notice_Days__c));
            }
            
        }
        return transformedCases;
    }

    private class CaseObject {
        @AuraEnabled public Id Id { get; set; }
        @AuraEnabled public String Subject { get; set; }
        // @AuraEnabled public Date Decision_Deadline_Display__c { get; set; }
    }

    // public static void sendDeadlineReminder(List<Id> caseIds) {
    //     Case caseRecord = [SELECT Id, Subject, Owner.Email, Deadline__c FROM Case WHERE Id = :caseIds[0] LIMIT 1];
    //     if (caseRecord != null && caseRecord.Deadline__c != null) {
    //         Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
    //         email.setToAddresses(new String[] { caseRecord.Owner.Email });
    //         email.setSubject('Reminder: Case Deadline Approaching');
    //         email.setPlainTextBody('Dear Case Owner,\n\nThis is a reminder that the deadline for the case "' + caseRecord.Subject + '" is approaching on ' + String.valueOf(caseRecord.Deadline__c) + '.\n\nPlease take the necessary actions.\n\nBest regards,\nSupport Team');
    //         Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
    //     }
    // }
}