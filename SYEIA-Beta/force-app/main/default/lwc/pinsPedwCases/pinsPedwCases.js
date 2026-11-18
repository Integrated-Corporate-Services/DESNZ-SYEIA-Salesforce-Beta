import { LightningElement, wire } from 'lwc';
import { getListRecordsByName } from 'lightning/uiListsApi';

export default class PinsPedwCases extends LightningElement {
    objectApiName = 'Case__c';
    listViewApiName = 'PINS_PEDW_Referred_Cases';

    records = [];
    error;
    isLoading = true;

    columns = [
        {
            label: 'DESNZ Case Reference',
            fieldName: 'caseUrl',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'desnzCaseReference' },
                target: '_self'
            }
        },
        {
            label: 'Case Type',
            fieldName: 'caseType'
        },
        {
            label: 'Company',
            fieldName: 'company'
        },
        {
            label: 'Status',
            fieldName: 'status'
        }
    ];

    @wire(getListRecordsByName, {
        objectApiName: '$objectApiName',
        listViewApiName: '$listViewApiName',
        fields: ['Case__c.Name', 'Case__c.Status__c', 'Case__c.DNO_Name__c', 'Case__c.Case_Type__c'],
        pageSize: 1000
    })
    wiredCases({ data, error }) {
        this.isLoading = false;

        if (data) {
            this.records = data.records.map((record) => {

                const desnzCaseReference =
                    record.fields?.Name?.value || 'No Reference';
                const status = record.fields?.Status__c?.value || '';
                const company = record.fields?.DNO_Name__c?.value || '';
                const caseType = record.fields?.Case_Type__c?.value || '';

                return {
                    id: record.id,
                    caseUrl: `/s/case-details?c__recordId=${encodeURIComponent(record.id)}`,
                    desnzCaseReference,
                    caseType,
                    status,
                    company
                };
            });

            this.error = undefined;
        } else if (error) {
            this.error = error;
            console.error(error);
            this.records = [];
        }
    }
}