import { LightningElement, api, track, wire } from 'lwc';
import getPicklistValuesByRecord from '@salesforce/apex/DynamicPathController.getPicklistValuesByRecord';
import { getRecord } from 'lightning/uiRecordApi';
import updateRecordStatus from '@salesforce/apex/DynamicPathController.updateRecordStatus';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class DynamicPath extends LightningElement {

    @api recordId;
    @api objectApiName;
    @api fieldApiName;

    @track stages = [];
    currentValue = '';

    ready = false;

    @wire(getPicklistValuesByRecord, {
        recordId: '$recordId',
        fieldApiName: '$fieldApiName'
    })
    wiredStages({ data, error }) {
        if (data) {
            this.stages = data.map(val => ({
                label: val,
                value: val
            }));
            this.initIfReady();
        }
    }

    @wire(getRecord, {
        recordId: '$recordId',
        fields: '$computedField'
    })
    wiredRecord({ data }) {
        if (data) {
            this.currentValue = data.fields[this.fieldApiName]?.value;
            this.initIfReady();
        }
    }

    get computedField() {
        return [`${this.objectApiName}.${this.fieldApiName}`];
    }

    initIfReady() {
        // Only mark ready when both stages and currentValue exist
        if (this.stages.length && this.currentValue) {
            this.ready = true;
        }
    }

    handleStageSelect(event) {
        this.currentValue = event.target.value;
    }

    handleUpdateStatus() {

        let newValue = this.currentValue;
        const currentIndex = this.stages.findIndex(s => s.value === this.currentValue);
        if (currentIndex < this.stages.length - 1) {
            newValue = this.stages[currentIndex + 1].value;
        }

        updateRecordStatus({
            recordId: this.recordId,
            fieldApiName: this.fieldApiName,
            fieldValue: newValue
        })
        .then(() => {
            this.currentValue = newValue;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Status updated',
                    variant: 'success'
                })
            );
        })
        .catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: error.body?.message || 'Error updating',
                    variant: 'error'
                })
            );
        });
    }
}