import { LightningElement } from 'lwc';
import getZipFiles from '@salesforce/apex/FileController.getZipFiles';
import JSZIP_Resource from '@salesforce/resourceUrl/jszip';
import { loadScript } from 'lightning/platformResourceLoader';
import { NavigationMixin } from 'lightning/navigation';


export default class ApplicationDocumentManager extends NavigationMixin(LightningElement) {
    files = [];
    zipInitialized = false;
    JSZip;

    async renderedCallback() {
        if (this.zipInitialized) return;

        this.zipInitialized = true;

        try {
            // await loadScript(this, JSZIP_Resource);
            this.JSZip = window.JSZip;
            if (!this.JSZip) {
                throw new Error('JSZip not found on window after loading static resource');
            }
        } catch (e) {
            // eslint-disable-next-line no-console
            console.error('Failed to load JSZip static resource', e);
        }
    }


    columns = [
        { label: 'Title', fieldName: 'Title' },
        { label: 'Type', fieldName: 'FileType' },
        {
            type: 'button',
            typeAttributes: {
                label: 'Preview',
                name: 'preview'
            }
        },
        {
            type: 'button',
            typeAttributes: {
                label: 'Download',
                name: 'download'
            }
        }
    ];
    async loadFiles() {

        if (!this.JSZip) {
            try {
                // await loadScript(this, JSZIP_Resource);
                this.JSZip = window.JSZip;
                if (!this.JSZip) {
                    throw new Error('JSZip not available after lazy load');
                }
            } catch (e) {
                // eslint-disable-next-line no-console
                console.error('Failed to load JSZip during loadFiles', e);
                return;
            }
        }

        const zipBase64 = await getZipFiles();

        const zipData = Uint8Array.from(atob(zipBase64), c => c.charCodeAt(0));

        const zip = await this.JSZip.loadAsync(zipData);

        const fileList = [];

        for (const filename of Object.keys(zip.files)) {

            const file = zip.files[filename];

            if (!file.dir) {

                const blob = await file.async("blob");

                fileList.push({
                    Id: filename,
                    ContentDocumentId: filename,
                    Title: filename,
                    FileType: filename.split('.').pop().toUpperCase(),
                    name: filename,
                    size: blob.size,
                    sizeLabel: this.formatBytes(blob.size),
                    url: URL.createObjectURL(blob)
                });

            }
        }

        this.files = fileList;
    }

    formatBytes(bytes) {
        if (bytes === 0) return '0 Bytes';

        const sizes = ['Bytes', 'KB', 'MB'];

        const i = Math.floor(Math.log(bytes) / Math.log(1024));

        return (bytes / Math.pow(1024, i)).toFixed(2) + ' ' + sizes[i];
    }

    handleRowAction(event) {
        const action = event.detail.action.name;
        const row = event.detail.row;

        if (action === 'preview') {
            this.previewFile({ target: { dataset: { id: row.ContentDocumentId }}});
        }
        if (action === 'download') {
            this.downloadFile({ target: { dataset: { id: row.Id }}});
        }
    }


    previewFile(event) {
        const contentDocumentId = event.target.dataset.id;

        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: {
                pageName: 'filePreview'
            },
            state: {
                selectedRecordId: contentDocumentId
            }
        });
    }

    downloadFile(event) {
        const versionId = event.target.dataset.id;
        window.open(`/sfc/servlet.shepherd/version/download/${versionId}`, '_blank');
    }
}
