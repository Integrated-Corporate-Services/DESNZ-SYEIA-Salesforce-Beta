import { LightningElement, api, wire } from 'lwc';
import { getRelatedListInfo, getRelatedListRecords } from 'lightning/uiRelatedListApi';
import getRelatedRecords from '@salesforce/apex/CaseEventRelatedListController.getRelatedRecords';
import { NavigationMixin } from 'lightning/navigation';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';

const PREVIEW_SIZE = 3;

export default class CaseEventRelatedList extends NavigationMixin(LightningElement) {
    @api recordId;
    @api recordTypeId;
    @api relatedList;

    relatedListInfo;
    infoError;
    uiRecords;
    uiRecordsError;
    apexRecords;
    apexRecordsError;

    get relatedListId() {
        return this.fields.length && !this.relatedList?.useApex
            ? this.relatedList?.relatedListId
            : undefined;
    }

    get infoRelatedListId() {
        return this.relatedList?.useApex ? undefined : this.relatedList?.relatedListId;
    }

    get relatedObjectApiName() {
        return this.relatedList?.objectApiName || this.relatedListInfo?.objectApiNames?.[0];
    }

    get displayColumns() {
        return this.relatedList?.useApex
            ? this.relatedList.displayColumns || []
            : this.relatedListInfo?.displayColumns || [];
    }

    get fields() {
        if (!this.relatedObjectApiName) {
            return [];
        }
        return (this.relatedListInfo?.displayColumns || [])
            .map((column) => {
                const fieldApiName = column.fieldApiName;
                const fieldPath = fieldApiName?.startsWith(`${this.relatedObjectApiName}.`)
                    ? fieldApiName.slice(this.relatedObjectApiName.length + 1)
                    : fieldApiName;
                return fieldPath ? `${this.relatedObjectApiName}.${fieldPath}` : undefined;
            })
            .filter(Boolean);
    }

    get apexFieldNames() {
        if (!this.relatedList?.useApex) {
            return undefined;
        }
        const objectApiName = this.relatedList?.objectApiName || this.relatedObjectApiName;
        return this.displayColumns
            .map((column) => {
                const fieldApiName = column.fieldApiName;
                if (fieldApiName?.startsWith(`${objectApiName}.`)) {
                    return fieldApiName.slice(objectApiName.length + 1);
                }
                return fieldApiName;
            })
            .filter(Boolean);
    }

    get columns() {
        return this.displayColumns.map((column, index) => ({
            label: column.label,
            fieldName: `column${index}`,
            type: 'text'
        }));
    }

    get hasRecords() {
        return Boolean(this.records?.length);
    }

    get hasNoRecords() {
        return this.records?.length === 0 && !this.recordsError;
    }

    get recordCount() {
        return this.records?.length || 0;
    }

    get relatedListTitle() {
        return `${this.relatedList?.label || 'Related List'} (${this.recordCount})`;
    }

    get visibleRecords() {
        return this.records?.slice(0, PREVIEW_SIZE);
    }

    get visibleRows() {
        return this.visibleRecords?.map((record) => ({
            id: record.id,
            cells: this.columns.map((column, index) => ({
                key: `${record.id}-${column.fieldName}`,
                value: record[column.fieldName] ?? '',
                isLink: this.isNameColumn(index)
            }))
        }));
    }

    isNameColumn(index) {
        const column = this.displayColumns[index];
        const fieldName = column?.fieldApiName?.split('.').pop();
        return fieldName?.toLowerCase() === 'name' || column?.label?.toLowerCase() === 'name';
    }

    get canViewAll() {
        return !this.isLoading && !this.recordsError && this.recordCount > PREVIEW_SIZE;
    }

    get canCreate() {
        return Boolean(this.recordId && this.relatedObjectApiName);
    }

    get records() {
        return this.relatedList?.useApex ? this.apexRecords : this.uiRecords;
    }

    get recordsError() {
        if (this.relatedList?.useApex) {
            return this.apexRecordsError;
        }
        return this.uiRecordsError;
    }

    get hasNoColumns() {
        return (
            Boolean(this.relatedListInfo || this.relatedList?.useApex) &&
            !this.displayColumns.length
        );
    }

    get isLoading() {
        if (this.relatedList?.useApex) {
            return !this.apexRecords && !this.apexRecordsError;
        }
        return (
            (!this.relatedListInfo && !this.infoError) ||
            (Boolean(this.fields.length) && !this.records && !this.recordsError)
        );
    }

    get showInfoError() {
        return Boolean(this.infoError) && !this.relatedList?.useApex;
    }

    get loadingAlternativeText() {
        return `Loading ${this.relatedList?.label || 'related list'}`;
    }

    handleNew() {
        const relationshipFieldApiName = this.relatedList?.relationshipFieldApiName;
        const state = relationshipFieldApiName
            ? {
                  defaultFieldValues: encodeDefaultFieldValues({
                      [relationshipFieldApiName]: this.recordId
                  })
              }
            : {};

        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: this.relatedObjectApiName,
                actionName: 'new'
            },
            state
        });
    }

    handleViewAll() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordRelationshipPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'Case__c',
                relationshipApiName: this.relatedList.relatedListId,
                actionName: 'view'
            }
        });
    }

    handleRecordClick(event) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: event.currentTarget.dataset.recordId,
                actionName: 'view'
            }
        });
    }

    @wire(getRelatedListInfo, {
        parentObjectApiName: 'Case__c',
        relatedListId: '$infoRelatedListId',
        recordTypeId: '$recordTypeId',
        restrictColumnsToLayout: true
    })
    wiredRelatedListInfo({ data, error }) {
        if (data) {
            this.relatedListInfo = data;
            this.infoError = undefined;
        } else if (error) {
            this.relatedListInfo = undefined;
            this.infoError = this.getErrorMessage(error);
        }
    }

    @wire(getRelatedListRecords, {
        parentRecordId: '$recordId',
        relatedListId: '$relatedListId',
        fields: '$fields',
        pageSize: 50
    })
    wiredRelatedListRecords({ data, error }) {
        if (data) {
            this.uiRecords = data.records.map((record) =>
                this.mapRecord(record, (fieldApiName) => this.getFieldValue(record, fieldApiName))
            );
            this.uiRecordsError = undefined;
        } else if (error) {
            this.uiRecords = undefined;
            this.uiRecordsError = this.getErrorMessage(error);
        }
    }

    @wire(getRelatedRecords, {
        parentRecordId: '$recordId',
        childObjectApiName: '$apexObjectApiName',
        relationshipFieldApiName: '$apexRelationshipFieldApiName',
        fieldApiNames: '$apexFieldNames'
    })
    wiredApexRecords({ data, error }) {
        if (data) {
            this.apexRecords = data.map((record) =>
                this.mapRecord(record, (fieldApiName) => {
                    const objectApiName = this.relatedList.objectApiName;
                    const fieldName = fieldApiName?.startsWith(`${objectApiName}.`)
                        ? fieldApiName.slice(objectApiName.length + 1)
                        : fieldApiName;
                    return record[fieldName];
                })
            );
            this.apexRecordsError = undefined;
        } else if (error) {
            this.apexRecords = undefined;
            this.apexRecordsError = this.getErrorMessage(error);
        }
    }

    mapRecord(record, getValue) {
        const row = { id: record.id || record.Id };
        this.columns.forEach((column, index) => {
            const displayColumn = this.displayColumns[index];
            row[column.fieldName] = getValue(displayColumn.fieldApiName);
        });
        return row;
    }

    getFieldValue(record, fieldApiName) {
        const fieldPath = fieldApiName?.startsWith(`${this.relatedObjectApiName}.`)
            ? fieldApiName.slice(this.relatedObjectApiName.length + 1)
            : fieldApiName;
        const pathParts = fieldPath?.split('.') || [];
        let fields = record.fields;

        for (let index = 0; index < pathParts.length; index += 1) {
            const field = fields?.[pathParts[index]];
            if (!field) {
                return undefined;
            }
            if (index === pathParts.length - 1) {
                return field.displayValue ?? field.value;
            }
            fields = field.value?.fields;
        }
        return undefined;
    }

    get apexObjectApiName() {
        return this.relatedList?.useApex ? this.relatedList.objectApiName : undefined;
    }

    get apexRelationshipFieldApiName() {
        return this.relatedList?.useApex
            ? this.relatedList.relationshipFieldApiName
            : undefined;
    }

    getErrorMessage(error) {
        const body = error?.body;
        if (Array.isArray(body)) {
            return body.map((item) => item.message).join(', ');
        }
        return body?.message || error?.message || 'An unexpected error occurred.';
    }
}