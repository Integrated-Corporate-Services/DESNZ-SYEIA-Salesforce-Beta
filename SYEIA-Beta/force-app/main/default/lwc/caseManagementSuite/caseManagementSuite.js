import { LightningElement, wire } from 'lwc';
import { getListRecordsByName } from 'lightning/uiListsApi';
import isGuest from '@salesforce/user/isGuest';
import CASE_OBJECT from '@salesforce/schema/Case__c';
import NAME_FIELD from '@salesforce/schema/Case__c.Name';
import TYPE_FIELD from '@salesforce/schema/Case__c.Case_Type__c';
import STATUS_FIELD from '@salesforce/schema/Case__c.Status__c';

export default class CaseManagementSuite extends LightningElement {
    records = [];
    selectedRecordId;
    selectedRecordName;
    error;
    detailError;
    isLoading = true;
    pageToken = '0';
    nextPageToken;
    previousPageToken;
    searchTerm = '';
    objectApiName = CASE_OBJECT;
    detailFields = [NAME_FIELD, TYPE_FIELD, STATUS_FIELD];

    get isGuestUser() {
        return isGuest;
    }

    get listObjectApiName() {
        return isGuest ? undefined : 'Case__c';
    }

    @wire(getListRecordsByName, {
        objectApiName: '$listObjectApiName',
        listViewApiName: 'Experience_Cases',
        fields: ['Case__c.Name'],
        optionalFields: ['Case__c.Case_Type__c', 'Case__c.Status__c'],
        pageSize: 25,
        pageToken: '$pageToken',
        searchTerm: '$searchTerm',
        sortBy: ['Name']
    })
    wiredCases({ data, error }) {
        this.isLoading = false;
        if (data) {
            this.records = data.records.map((record) => ({
                id: record.id,
                name: record.fields.Name.value,
                type: this.fieldValue(record.fields.Case_Type__c),
                status: this.fieldValue(record.fields.Status__c)
            }));
            this.nextPageToken = data.nextPageToken;
            this.previousPageToken = data.previousPageToken;
            this.error = undefined;
        } else if (error) {
            this.records = [];
            this.nextPageToken = undefined;
            this.previousPageToken = undefined;
            this.error = 'Cases could not be loaded. Contact your site administrator if this continues.';
        }
    }

    fieldValue(field) {
        return field?.displayValue ?? field?.value ?? '';
    }

    get hasRecords() {
        return this.records.length > 0;
    }

    get showEmptyState() {
        return !this.isLoading && !this.error && !this.hasRecords;
    }

    get previousDisabled() {
        return this.isLoading || this.previousPageToken == null;
    }

    get nextDisabled() {
        return this.isLoading || this.nextPageToken == null;
    }

    handleSearch(event) {
        const searchTerm = event.target.value.trim();
        if (this.searchTerm === searchTerm && this.pageToken === '0') {
            return;
        }
        this.isLoading = true;
        this.pageToken = '0';
        this.searchTerm = searchTerm;
    }

    handlePrevious() {
        this.isLoading = true;
        this.pageToken = this.previousPageToken;
    }

    handleNext() {
        this.isLoading = true;
        this.pageToken = this.nextPageToken;
    }

    handleOpen(event) {
        this.selectedRecordId = event.currentTarget.dataset.id;
        this.selectedRecordName = event.currentTarget.dataset.name;
        this.detailError = undefined;
    }

    handleBack() {
        this.selectedRecordId = undefined;
        this.detailError = undefined;
    }

    handleDetailError() {
        this.detailError = 'This case could not be opened. It may no longer be available to you.';
    }
}