import { LightningElement, wire, track } from 'lwc';
import getCasesWithUpcomingDeadlines from '@salesforce/apex/CaseDeadlineReminderController.getCasesWithUpcomingDeadlines';


export default class CaseDeadlineReminder extends LightningElement {
    @track cases = [];

    @wire(getCasesWithUpcomingDeadlines)
    wiredCases({ data, error }) {
        if (data) {
            this.cases = data.map(c => ({
                id: c.Id,
                name: c.Applicant_Reference__c,
                caseLink: '/' + c.Id,
                actionNeeded: c.Applicant_Reference__c,
                decisionDeadline: c.Decision_Deadline_Display__c
            }));

            console.log('Cases with upcoming deadlines:', this.cases);
        } else if (error) {
            console.error(error);
        }
    }
}