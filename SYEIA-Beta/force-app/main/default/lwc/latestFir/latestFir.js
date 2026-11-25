import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getLatestFirId from '@salesforce/apex/LatestFirController.getLatestFirId';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import CASE_NAME from '@salesforce/schema/Case__c.Name';

// Editable fields, left-to-right, row by row (2 columns).
// Replace with the real API names from Object Manager.
const EDITABLE_FIELDS = [
    'Name',
    'Date_Information_was_Requested__c',
    'FIR_to_Applicant_or_Landowner__c',
    'Date_Information_was_Received__c',
    'Further_Information_Requested_Deadline__c',
    'Date_Further_Info_Request_Resolved__c',
    'Additional_Information_Required__c',
    'Further_Information_Exchange_Letter_Date__c'
];

const EDITABLE_FIELDS_S37 = [
    'Name',
    'Type_of_Information_Requested__c',
    'Additional_Information_Required__c',
    'Date_Information_was_Requested__c',
    'Date_Information_was_Received__c',
    'Further_Information_Requested_Deadline__c',
    'Date_Further_Info_Request_Resolved__c',
 ];


export default class LatestFir extends LightningElement {
    @api recordId; // Case Id from the record page

    objectApiName = 'Further_Information_Requested__c';

    commentField = 'Comment_From_Applicant__c';

    firId;
    isLoaded = false;
    errorMessage;

    isOpen = true;
    isEditing = false;


    @wire(getLatestFirId, { caseId: '$recordId' })
    wiredFir({ data, error }) {
        if (error) {
            this.errorMessage = error.body ? error.body.message : 'Could not load the latest FIR.';
            this.firId = undefined;
            this.isLoaded = true;
        } else if (data !== undefined) {
            this.firId = data;
            this.errorMessage = undefined;
            this.isLoaded = true;
        }
    }
   
    @wire(getRecord, { recordId: '$recordId', fields: [CASE_NAME] })
    caseRecord;

    get caseName() {
        return getFieldValue(this.caseRecord.data, CASE_NAME);
    }  

    get isS37() {
        return (this.caseName || '').toUpperCase().startsWith('S37');
    }  

    get editableFields() {
        return this.isS37 ? EDITABLE_FIELDS_S37 : EDITABLE_FIELDS;
    }

    get noRecord() {
        return this.isLoaded && !this.firId && !this.errorMessage;
    }

    get isViewMode() {
        return !this.isEditing;
    }

    get sectionClass() {
        return this.isOpen ? 'slds-section slds-is-open' : 'slds-section';
    }

    toggleSection() {
        this.isOpen = !this.isOpen;
    }

    handleEdit() {
        this.isEditing = true;
    }

    handleCancel() {
        this.template.querySelectorAll('lightning-input-field').forEach((f) => f.reset());
        this.isEditing = false;
    }

    handleSuccess() {
        this.isEditing = false;
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Saved',
                message: 'Further information request updated.',
                variant: 'success'
            })
        );
    }

    handleError(event) {
        // lightning-messages shows the field errors on the form; this adds a toast
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Could not save',
                message: event.detail ? event.detail.detail || event.detail.message : 'Unknown error',
                variant: 'error'
            })
        );
    }
}