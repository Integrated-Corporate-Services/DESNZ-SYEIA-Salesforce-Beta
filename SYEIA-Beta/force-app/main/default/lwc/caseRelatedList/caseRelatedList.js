import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';
import RECORD_TYPE_ID_FIELD from '@salesforce/schema/Case__c.RecordTypeId';

export default class CaseRelatedList extends LightningElement {
    @api recordId;

    pageRecordId;
    recordTypeId;
    recordError;

    relatedLists = [
        {
            relatedListId: 'Parties',
            label: 'Parties',
            useApex: true,
            objectApiName: 'Party__c',
            relationshipFieldApiName: 'Case__c',
            displayColumns: [
                { fieldApiName: 'Name', label: 'Name' },
                { fieldApiName: 'Party_Type__c', label: 'Party Type' },
                { fieldApiName: 'Email__c', label: 'Email' }
            ]
        },
        {
            relatedListId: 'Asset_Information__r',
            label: 'Asset Information',
            objectApiName: 'Asset_Information__c',
            relationshipFieldApiName: 'Case__c'
        },
        {
            relatedListId: 'Addresses',
            label: 'Address',
            useApex: true,
            objectApiName: 'Address__c',
            relationshipFieldApiName: 'Case__c',
            displayColumns: [{ fieldApiName: 'Name', label: 'Name' }]
        },
        {
            relatedListId: 'Land__r',
            label: 'Land',
            objectApiName: 'Land__c',
            relationshipFieldApiName: 'Case__c'
        },
        {
            relatedListId: 'Further_Information_Requested__r',
            label: 'Further Information Requested',
            objectApiName: 'Further_Information_Requested__c',
            relationshipFieldApiName: 'Case__c',
            restrictColumnsToLayout: false
        }
    ];

    @wire(CurrentPageReference)
    setPageReference(pageReference) {
        this.pageRecordId =
            pageReference?.state?.c__recordId || pageReference?.attributes?.recordId;
    }

    @wire(getRecord, { recordId: '$effectiveRecordId', fields: [RECORD_TYPE_ID_FIELD] })
    wiredRecord({ data, error }) {
        if (data) {
            this.recordTypeId = data.fields.RecordTypeId.value;
            this.recordError = undefined;
        } else if (error) {
            this.recordTypeId = undefined;
            this.recordError = this.getErrorMessage(error);
        }
    }

    get effectiveRecordId() {
        return this.recordId || this.pageRecordId;
    }

    getErrorMessage(error) {
        const body = error?.body;
        if (Array.isArray(body)) {
            return body.map((item) => item.message).join(', ');
        }
        return body?.message || error?.message || 'An unexpected error occurred.';
    }
}