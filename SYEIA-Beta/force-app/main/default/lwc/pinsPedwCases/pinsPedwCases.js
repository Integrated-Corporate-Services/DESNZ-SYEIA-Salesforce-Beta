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
            label: 'Status',
            fieldName: 'status'
        }
    ];

    @wire(getListRecordsByName, {
        objectApiName: '$objectApiName',
        listViewApiName: '$listViewApiName',
        fields: ['Case__c.Name', 'Case__c.Status__c'],
        pageSize: 50
    })
    wiredCases({ data, error }) {
        this.isLoading = false;

        if (data) {
            this.records = data.records.map((record) => {
                const desnzCaseReference =
                    record.fields?.Name?.value || 'No Reference';
                const status = record.fields?.Status__c?.value || '';

                return {
                    id: record.id,
                    caseUrl: `/s/case-details?c__recordId=${encodeURIComponent(record.id)}`,
                    desnzCaseReference,
                    status
                };
            });

            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.records = [];
        }
    }
}