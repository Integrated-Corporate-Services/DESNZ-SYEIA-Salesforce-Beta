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
    recordTypeDevName;

    ready = false;
    hideButton = true;
    hideStatuses = [];

    isSaving = false;
    showSuccess = false;

    // Fields for wire
    get computedFields() {
        return [
            `${this.objectApiName}.${this.fieldApiName}`,
            `${this.objectApiName}.RecordType.DeveloperName`
        ];
    }

    connectedCallback() {
        getHideStatuses()
            .then(data => {
                this.hideStatuses = data;
                this.checkButtonVisibility();
            })
            .catch(console.error);
    }

    @wire(getRecord, {
        recordId: '$recordId',
        fields: '$computedFields'
    })
    wiredRecord({ data, error }) {
        if (data) {
            const newValue = data.fields[this.fieldApiName]?.value;

            this.recordTypeDevName =
                data.fields.RecordType?.value?.fields?.DeveloperName?.value;

            if (newValue && newValue !== this.currentValue) {
                this.currentValue = newValue;

                this.ready = false;

                this.loadStages();
                this.checkButtonVisibility();
            }

        } else if (error) {
            this.showToast('Error', 'Error loading record', 'error');
            console.error(error);
        }
    }

    loadStages() {
        if (!this.currentValue || !this.recordTypeDevName) return;

        getStatusByCurrentStatus({
            status: this.currentValue,
            recordTypeDevName: this.recordTypeDevName
        })
        .then(data => {
            this.stages = data.map(val => ({
                label: val,
                value: val.trim()
            }));

            // Ensure current value exists in stages
            if (!this.stages.some(s => s.value === this.currentValue)) {
                this.stages = [
                    ...this.stages,
                    { label: this.currentValue, value: this.currentValue }
                ];
            }

            this.ready = true;
        })
        .catch(error => {
            console.error(error);
            this.showToast('Error', 'Error loading path', 'error');
        });
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

    handleStageSelect(event) {
        this.selectedValue = event.currentTarget.dataset.value;
    }

    handleUpdateStatus() {
        let newValue;

        if (this.selectedValue && this.selectedValue !== this.currentValue) {
            newValue = this.selectedValue;
        } else {
            const index = this.stages.findIndex(s => s.value === this.currentValue);
            newValue = index < this.stages.length - 1
                ? this.stages[index + 1].value
                : this.currentValue;
        }

        this.isSaving = true;

        updateRecordStatus({
            recordId: this.recordId,
            fieldApiName: this.fieldApiName,
            currentStatus: newValue
        })
        .then(() => {
            this.selectedValue = null;
            this.currentValue = newValue;

            this.showSuccess = true;
            setTimeout(() => this.showSuccess = false, 1200);

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

    // 🔥 KEY FIX: always return correct step
    get displayValue() {
        return this.selectedValue || this.currentValue;
    }

    get buttonIcon() {
        return this.showSuccess ? 'utility:success' : 'utility:check';
    }

    get isButtonDisabled() {
        return this.isSaving;
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({ title, message, variant })
        );
    }
}