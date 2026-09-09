import { LightningElement, wire, track, api } from 'lwc';
import getApplicationDocuments from '@salesforce/apex/FileController.getApplicationDocuments';
import getDocumentExport from '@salesforce/apex/FileController.getDocumentExport';
import downloadApplicationDocument from '@salesforce/apex/FileController.downloadApplicationDocument';
import queueApplicationDocumentDownload from '@salesforce/apex/FileController.queueApplicationDocumentDownload';
import getAsyncDownloadStatus from '@salesforce/apex/FileController.getAsyncDownloadStatus';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import CUSTOM_FIELD from '@salesforce/schema/Case__c.AWS_Application_Id__c';

const FIELDS = [CUSTOM_FIELD];
const SYNCHRONOUS_DOWNLOAD_LIMIT_BYTES = 6 * 1024 * 1024;
const ASYNC_DOWNLOAD_POLL_INTERVAL_MS = 1000;

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
                label: 'Download',
                name: 'download'
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
                fileSizeBytes: document.fileSizeBytes
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

    async handleRowAction(event) {
        const action = event.detail.action.name;
        const row = event.detail.row;

        if (action === 'download') {
            try {
                if (Number(row.fileSizeBytes) > SYNCHRONOUS_DOWNLOAD_LIMIT_BYTES) {
                    const request = await queueApplicationDocumentDownload({
                        applicationId: this.customFieldValue,
                        documentId: row.Id,
                        fileName: row.Title,
                        recordId: this.recordId
                    });
                    this.showToast('Preparing download', 'Your file is being prepared for download.', 'info');
                    await this.waitForAsyncDownload(request.jobId, request.requestToken, row.Title);
                    return;
                }

                const zipBase64 = await downloadApplicationDocument({
                    applicationId: this.customFieldValue,
                    documentId: row.Id
                });
                this.downloadFile(zipBase64, row.Title + '.zip');
            } catch (e) {
                console.error('Error downloading document:', e);
            }
        }
    }

    async waitForAsyncDownload(jobId, requestToken, fileName) {
        while (true) {
            await this.delay(ASYNC_DOWNLOAD_POLL_INTERVAL_MS);
            const result = await getAsyncDownloadStatus({ jobId, requestToken });

            if (result.status === 'Completed' && result.contentVersionId) {
                window.open(`/sfc/servlet.shepherd/version/download/${result.contentVersionId}`, '_blank');
                return;
            }
            if (result.status === 'Failed' || result.status === 'Aborted') {
                throw new Error(result.errorMessage || `Unable to prepare ${fileName} for download.`);
            }
        }
    }

    downloadFile(base64Content, fileName) {
        const binaryString = atob(base64Content);
        const bytes = new Uint8Array(binaryString.length);
        for (let index = 0; index < binaryString.length; index += 1) {
            bytes[index] = binaryString.charCodeAt(index);
        }
        const url = URL.createObjectURL(new Blob([bytes], { type: 'application/zip' }));
        const link = document.createElement('a');
        link.href = url;
        link.download = fileName || 'download';
        link.rel = 'noopener';
        document.body.appendChild(link);
        link.click();
        link.remove();
        URL.revokeObjectURL(url);
    }

    delay(milliseconds) {
        return new Promise((resolve) => {
            window.setTimeout(resolve, milliseconds);
        });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

}