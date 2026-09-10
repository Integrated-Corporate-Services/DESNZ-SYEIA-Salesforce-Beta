import { LightningElement, wire, track, api } from 'lwc';
import getApplicationDocuments from '@salesforce/apex/FileController.getApplicationDocuments';
import getDocumentExport from '@salesforce/apex/FileController.getDocumentExport';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import CUSTOM_FIELD from '@salesforce/schema/Case__c.AWS_Application_Id__c';

const FIELDS = [CUSTOM_FIELD];

export default class ApplicationDocumentManager extends LightningElement {
    files = [];
    @track treeData = [];
    hasRequestedFiles = false;

    @api recordId;
    @api objectApiName;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    record;

    get customFieldValue() {
        return getFieldValue(this.record.data, CUSTOM_FIELD);
    }

    get hasFiles() {
        return Array.isArray(this.files) && this.files.length > 0;
    }

    get hasNotDownloaded() {
        return !this.hasRequestedFiles && !this.hasFiles;
    }

    columns = [
        { label: 'Title', fieldName: 'Title' },
        { label: 'Type', fieldName: 'FileType' },
        {
            type: 'button',
            typeAttributes: {
                label: { fieldName: 'downloadLabel' },
                name: 'download',
                disabled: { fieldName: 'downloadDisabled' }
            }
        }
    ];

    async loadFiles() {
        this.hasRequestedFiles = true;

        try {
            const response = await getApplicationDocuments({ applicationId: this.customFieldValue });
            const parsedResponse = JSON.parse(response);
            const documents = Array.isArray(parsedResponse)
                ? parsedResponse
                : parsedResponse.documents || [];

            this.files = documents.map((document) => ({
                Id: document.document_id,
                Title: document.title,
                FileType: document.contentType || document.ContentType,
                downloadUrl: document.downloadUrl,
                downloadLabel: document.downloadUrl ? 'Download' : 'Use Download All',
                downloadDisabled: !document.downloadUrl
            }));
        } catch (e) {
            console.error('Error loading files:', e);
        }
    }

    async downloadAll() {
        try {
            const exportResponse = await getDocumentExport({ applicationId: this.customFieldValue });
            if (!exportResponse?.downloadUrl) {
                throw new Error('The document export did not return a download URL.');
            }
            window.open(exportResponse.downloadUrl, '_blank');
        } catch (e) {
            console.error('Error downloading all files:', e);
            this.showToast('Download failed', 'Unable to prepare the document export.', 'error');
        }
    }

    handleRowAction(event) {
        const action = event.detail.action.name;
        const row = event.detail.row;

        if (action === 'download') {
            try {
                if (!row.downloadUrl) {
                    throw new Error('The document did not return a download URL.');
                }
                window.open(row.downloadUrl, '_blank');
            } catch (e) {
                console.error('Error downloading document:', e);
                this.showToast('Download failed', 'Unable to download the document.', 'error');
            }
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

}