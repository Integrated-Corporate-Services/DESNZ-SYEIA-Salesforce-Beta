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
            JSON.stringify(exportResponse); // Ensure the response is valid JSON
            if (!exportResponse?.downloadUrl) {
                throw new Error('The document export did not return a download URL.');
            }
            // window.open('https://s3-eip-dev-doc-scan-clean.s3.eu-west-2.amazonaws.com/NWL/c6a18b59-b40a-4456-9589-8e7eb8a8f49b/DOCUMENT_EXPORTS/application-c6a18b59-b40a-4456-9589-8e7eb8a8f49b-documents.zip?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Content-Sha256=UNSIGNED-PAYLOAD&X-Amz-Credential=ASIA5PXGRFK6E3AZH7TN%2F20260909%2Feu-west-2%2Fs3%2Faws4_request&X-Amz-Date=20260909T170117Z&X-Amz-Expires=300&X-Amz-Security-Token=IQoJb3JpZ2luX2VjEKX%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FwEaCWV1LXdlc3QtMiJHMEUCIQCSGfMVTCK4vyRkuR9fzHOGjKvOatj%2BJdmVTqcfWXo2JwIgFfTV4N3Zju5X32CuHP3NlrQ%2FdfaQmtMmYXQB5O%2B99%2BAq5QMIbRABGgw5MjcxMjI2NjQxMjQiDGygFIDOogGkjGHxiyrCA1EH78qHeVasm2j9hhG%2FFd3fe5KmUzgqGyD%2BsQulmebuI8zL19Pf6XpQ60pU6Rko505pq3yeRIwfCOOOUtqRQx1bfoLseSyBAPBKUzh9P8cI6SDZpNXcSebmgVOOXpp1wpPEZ9xBczCGL5VmAIplJiuhWb2LBf29OrbilvpNxO6KRS3UNMffET0UlL%2FR1dLDPjvhq8L08aRKvvesh4yuzVa8gcJKCGe0By8tYA9kZnNA3uscLos7HEsAr%2BHGrqpTIJHiA%2FeftnWVzId2Te5FDvkujEVecDMs8OmM3Fp86t3eqNC9xEPctMFaFF5D18hzpHoOIa1oFQjYzOiQo72fQJCNDXR6V%2BeGXronKYPzWPAFea1m%2Be%2B6fUyf6nSBv6Y3raAg8dg1ZsTlFLTxfdcKK0RdvrtzMUTWxynpoyfyt6pFiNxRJioOWMcjWWvm%2Bg%2BoQyycB%2FbNTfKK4OMCWV1zuafR7L2zLgv%2Ba9LLNc5r0lLoXI6PXJx0RCKcJjc6Cyk1Vbj0l0JhaSiNq9YIPjrOqB%2FJDjq0Xek8Ccj9C%2F%2BdG8BnY42q1Pm4CDeeBGTURGn25ojrJ%2FqmpGj7g784jST%2F25AhjzDbm4XVBjqlAZVfplW5KEcOzCuJkwxms5K6mPp5bktYtvxZrpa6iaM57ueh7IbVuHcghhfeTBM8d6nkm6x1qNFWN%2BuQPDnN66KrNhluH1UOxsvnXe232WX1WGqKB6dmAVOi4E41I5X%2F5b596CtTM%2FndeXxpb0VHJ6Ez9e3tCoookJU70PjSVh8vcVPVqryWq2p7x%2FcEaxCPCBWyrFjjL2ZG1FjNh44ozi73IKLklQ%3D%3D&X-Amz-Signature=139b2dd8a385e6ed8933adfe89abaefab5d72911a95f68766df56a29b8ba6aeb&X-Amz-SignedHeaders=host&response-content-disposition=attachment%3B%20filename%3D%22application-c6a18b59-b40a-4456-9589-8e7eb8a8f49b-documents.zip%22&x-amz-checksum-mode=ENABLED&x-id=GetObject', '_blank');
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