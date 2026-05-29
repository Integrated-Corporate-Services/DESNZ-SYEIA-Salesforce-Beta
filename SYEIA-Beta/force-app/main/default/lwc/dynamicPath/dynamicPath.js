import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, getRecordNotifyChange } from 'lightning/uiRecordApi';

import getStatusByCurrentStatus from '@salesforce/apex/DynamicPathController.getStatusByCurrentStatus';
import updateRecordStatus from '@salesforce/apex/DynamicPathController.updateRecordStatus';
import getHideStatuses from '@salesforce/apex/DynamicPathController.getHideStatuses';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class DynamicPath extends LightningElement {

    @api recordId;
    @api objectApiName;
    @api fieldApiName;

    @track stages = [];

    currentValue = '';
    selectedValue = null;
    ready = false;

    hideButton = true;
    hideStatuses = [];

    progressKey = 0;
    isSaving = false;
    showSuccess = false;

    get computedField() {
        return [`${this.objectApiName}.${this.fieldApiName}`];
    }

    connectedCallback() {
        getHideStatuses()
            .then(data => {
                this.hideStatuses = data;
                this.checkButtonVisibility();
            })
            .catch(error => {
                console.error(error);
            });
    }

    @wire(getRecord, {
        recordId: '$recordId',
        fields: '$computedField'
    })
    wiredRecord({ data, error }) {
        if (data) {
            const newValue = data.fields[this.fieldApiName]?.value;

            if (newValue && newValue !== this.currentValue) {
                this.currentValue = newValue;

                this.ready = false;
                this.progressKey++;

                this.loadStages();
                this.checkButtonVisibility();
            }

        } else if (error) {
            this.showToast('Error', 'Error loading record', 'error');
            console.error(error);
        }
    }

    loadStages() {
        if (!this.currentValue) return;

        getStatusByCurrentStatus({ status: this.currentValue })
            .then(data => {
                this.stages = data.map(val => ({
                    label: val,
                    value: val
                }));

                this.initIfReady();
            })
            .catch(error => {
                console.error(error);
                this.showToast('Error', 'Error loading path configuration', 'error');
            });
    }

    initIfReady() {
        if (this.stages.length && this.currentValue) {
            this.ready = true;
        }
    }

    checkButtonVisibility() {
        if (!this.currentValue) {
            this.hideButton = true;
            return;
        }

        this.hideButton = this.hideStatuses.includes(
            this.currentValue.toLowerCase()
        );
    }

    get displayValue() {
        return this.selectedValue || this.currentValue;
    }

    handleStageSelect(event) {
        this.selectedValue = event.currentTarget.dataset.value;
    }

    handleUpdateStatus() {

        let newValue;

        // Use selected value if user clicked
        if (this.selectedValue && this.selectedValue !== this.currentValue) {
            newValue = this.selectedValue;
        } 
        else {
            const currentIndex = this.stages.findIndex(
                s => s.value === this.currentValue
            );

            if (currentIndex < this.stages.length - 1) {
                newValue = this.stages[currentIndex + 1].value;
            } else {
                newValue = this.currentValue;
            }
        }

        this.isSaving = true;

        updateRecordStatus({
            recordId: this.recordId,
            fieldApiName: this.fieldApiName,
            currentStatus: newValue // Apex will handle prior status override
        })
        .then(() => {

            this.selectedValue = null;
            this.currentValue = newValue;

            this.showSuccess = true;
            setTimeout(() => {
                this.showSuccess = false;
            }, 1200);

            this.ready = false;
            this.progressKey++;

            getRecordNotifyChange([{ recordId: this.recordId }]);
            this.loadStages();
            this.checkButtonVisibility();

            this.showToast('Success', 'Status updated', 'success');
        })
        .catch(error => {
            this.showToast(
                'Error',
                error.body?.message || 'Error updating',
                'error'
            );
        })
        .finally(() => {
            this.isSaving = false;
        });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }

    get buttonIcon() {
        return this.showSuccess ? 'utility:success' : 'utility:check';
    }

    get isButtonDisabled() {
        return this.isSaving;
    }
}