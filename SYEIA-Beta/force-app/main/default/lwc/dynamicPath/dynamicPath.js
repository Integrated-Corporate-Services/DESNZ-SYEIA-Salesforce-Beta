import { LightningElement, api, track, wire } from 'lwc';
import getPicklistValuesByRecord from '@salesforce/apex/FlowStagesController.getPicklistValuesByRecord';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class DynamicPath extends LightningElement {
    @api recordId;
    @api objectApiName;
    @api fieldApiName;

    @track stages = [];
    @track currentValue = '';
    @track selectedStage = ''; // Track selected stage separately

    @track error;

    // Load picklist values dynamically
    @wire(getPicklistValuesByRecord, { recordId: '$recordId', fieldApiName: '$fieldApiName' })
    wiredStages({ data, error }) {
        if (data) {
            this.stages = data.map(value => ({ value, class: '' }));
            this.updateStepClasses();
        } else if (error) {
            this.error = error.body?.message || 'Error loading picklist values';
        }
    }

    // Load current record picklist value
    @wire(getRecord, { recordId: '$recordId', fields: '$computedField' })
    wiredRecord({ data }) {
        if (data) {
            this.currentValue = data.fields[this.fieldApiName]?.value || '';
            this.selectedStage = this.currentValue;
            this.updateStepClasses();
        }
    }

    get computedField() {
        return [`${this.objectApiName}.${this.fieldApiName}`];
    }

    // When user clicks on a stage
    handleStageSelect(event) {
        const clickedValue = event.target.value;
        this.selectedStage = clickedValue;

        // Update highlight classes
        this.updateStepClasses();
    }

    // Button clicked: move selected stage to record
    handleUpdateStatus() {
        if (!this.selectedStage) return;

        let newValue = this.selectedStage;

        // If selected stage is current, move to next stage
        const currentIndex = this.stages.findIndex(s => s.value === this.currentValue);
        const selectedIndex = this.stages.findIndex(s => s.value === this.selectedStage);

        if (selectedIndex === currentIndex && currentIndex < this.stages.length - 1) {
            newValue = this.stages[currentIndex + 1].value;
        }

        // Update record
        const fields = { Id: this.recordId };
        fields[this.fieldApiName] = newValue;

        updateRecord({ fields })
            .then(() => {
                this.currentValue = newValue;
                this.selectedStage = newValue;
                this.updateStepClasses();
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Status updated successfully',
                        variant: 'success'
                    })
                );
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: error.body?.message || 'Error updating status',
                        variant: 'error'
                    })
                );
            });
    }

    // Update path step classes to reflect current and completed stages
    updateStepClasses() {
        const currentIndex = this.stages.findIndex(s => s.value === this.currentValue);
        const selectedIndex = this.stages.findIndex(s => s.value === this.selectedStage);

        this.stages = this.stages.map((stage, idx) => {
            let cls = '';
            if (idx < currentIndex) cls = 'slds-is-completed';
            if (idx === selectedIndex && idx !== currentIndex) cls += ' slds-is-active'; // Highlight selected
            return { ...stage, class: cls };
        });
    }
}