import { LightningElement, wire, track, api } from 'lwc';
import getZipFiles from '@salesforce/apex/FileController.getZipFiles';
import JSZIP_Resource from '@salesforce/resourceUrl/jszip';
import { loadScript } from 'lightning/platformResourceLoader';
import { NavigationMixin } from 'lightning/navigation';
import getFileTree from '@salesforce/apex/FileController.extractZipAndBuildTree';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import CUSTOM_FIELD from '@salesforce/schema/Case__c.AWS_Application_Id__c';

const FIELDS = [CUSTOM_FIELD];

export default class ApplicationDocumentManager extends NavigationMixin(LightningElement) {
    files = [];
    zipInitialized = false;
    JSZip;
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

    async renderedCallback() {
        if (this.zipInitialized) return;

        this.zipInitialized = true;

        try {
            await loadScript(this, JSZIP_Resource);
            this.JSZip = window.JSZip;
            if (!this.JSZip) {
                throw new Error('JSZip not found on window');
            }
        } catch (e) {
            console.error('Failed to load JSZip', e);
        }
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
        console.log('Loading files...');
        if (!this.JSZip) {
            console.log('JSZip not loaded yet, attempting to load now...');
            try {
                await loadScript(this, JSZIP_RESOURCE);
                this.JSZip = window.JSZip;
                console.log('JSZip loaded successfully in loadFiles');
                if (!this.JSZip) {
                    console.error('JSZip not found on window after load in loadFiles');
                    throw new Error('JSZip not available after lazy load');
                }
            } catch (e) {
                console.error('Failed to load JSZip during loadFiles', e);
                return;
            }
        }
        console.log('JSZip is available, proceeding to fetch zip file');

        try {
            console.log('Fetching file tree from server for applicationId:', this.customFieldValue);
            // this.treeData = await getFileTree({ applicationId: this.customFieldValue });
            console.log('Tree data loaded:', this.treeData);
            console.log('Calling Apex method to get zip file...');
            const zipBase64 = await getZipFiles({ applicationId: this.customFieldValue });
            console.log('Received zip file from server');

            // Validate base64 is not empty
            if (!zipBase64 || zipBase64.length === 0) {
                throw new Error('No zip data received from server');
            }

            // Decode base64 to bytes
            const binaryString = atob(zipBase64);
            const bytes = new Uint8Array(binaryString.length);
            for (let i = 0; i < binaryString.length; i++) {
                bytes[i] = binaryString.charCodeAt(i);
            }

            console.log('Zip data converted, size:', bytes.length);
            
            // Validate ZIP file signature (should start with 0x50 0x4B)
            const firstBytes = Array.from(bytes.slice(0, 4));
            const hexSignature = firstBytes.map(b => '0x' + b.toString(16).toUpperCase()).join(' ');
            console.log('File signature (hex):', hexSignature);
            
            if (bytes.length < 4 || bytes[0] !== 0x50 || bytes[1] !== 0x4B) {
                console.error('ERROR: Invalid ZIP file signature!');
                console.error('Expected: 0x50 0x4B (PK)');
                console.error('Got:', hexSignature);
                
                // Try to identify what file type this actually is
                if (bytes[0] === 0x89 && bytes[1] === 0x50 && bytes[2] === 0x4E && bytes[3] === 0x47) {
                    console.error('⚠️ This is a PNG image file, not a ZIP!');
                } else if (bytes[0] === 0xFF && bytes[1] === 0xD8) {
                    console.error('⚠️ This is a JPEG image file, not a ZIP!');
                } else if (String.fromCharCode(...firstBytes) === '%PDF') {
                    console.error('⚠️ This is a PDF file, not a ZIP!');
                }
                
                throw new Error('Invalid ZIP file format - received file is not a ZIP. Signature: ' + hexSignature);
            }

            console.log('ZIP file signature is valid');
            const zip = await this.JSZip.loadAsync(bytes).catch(e => {
                console.error('Error loading zip file:', e);
                console.error('Error message:', e.message);
                console.error('Error stack:', e.stack);
                console.error('Zip file size:', bytes.length);
                console.error('First 20 bytes:', Array.from(bytes.slice(0, 20)).map(b => '0x' + b.toString(16).toUpperCase()).join(' '));
                throw e;
            });
            if (!zip) {
                console.error('Zip file could not be loaded');
                return;
            }
            console.log('Zip loaded successfully');

            const itemList = [];

            for (const filename of Object.keys(zip.files)) {
                const file = zip.files[filename];
                console.log('Processing:', filename, 'Is Directory:', file.dir);

                if (file.dir) {
                    itemList.push({
                        Id: filename,
                        ContentDocumentId: filename,
                        Title: filename.replace(/\/$/, ''),
                        FileType: 'Folder',
                        name: filename,
                        size: 0,
                        sizeLabel: '-',
                        url: null,
                        isFolder: true
                    });
                } else {
                    const blob = await file.async("blob");
                    itemList.push({
                        Id: filename,
                        ContentDocumentId: filename,
                        Title: filename,
                        FileType: filename.split('.').pop().toUpperCase(),
                        name: filename,
                        size: blob.size,
                        sizeLabel: this.formatBytes(blob.size),
                        url: URL.createObjectURL(blob),
                        isFolder: false
                    });
                }
            }

            this.files = itemList;
            console.log('Files loaded:', this.files.length);
        } catch (e) {
            console.error('Error loading files:', e);
            console.error('Error details:', e.message);
            console.error('Stack:', e.stack);
        }
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

        if (action === 'download') {
            this.downloadFile(row.url, row.Title);
        }
    }

    async previewFile(fileUrl) {
        // Handles both flat files (e.g. 'manifest.txt') and files in folders (e.g. 'PLAN_INFO/manifest.txt')
        let file = null;
        if (this.zip && this.zip.files) {
            // Try direct lookup
            file = this.zip.files[fileUrl];
            // If not found, search for filename anywhere in ZIP
            if (!file) {
                const matches = Object.keys(this.zip.files).filter(f => f.endsWith('/' + fileUrl) || f === fileUrl);
                if (matches.length > 0) {
                    file = this.zip.files[matches[0]];
                }
            }
        } else {
            window.open(fileUrl, '_blank');
        }
    }

    isDownloadingAll = false;

    // Replace `rows` with whatever array you bind into lightning-datatable `data`
    rows = this.files;
    selectedRows = this.files;

    get disableDownloadAll() {
        return this.isDownloadingAll || !this.files || this.files.length === 0;
    }

    get disableDownloadSelected() {
        return this.isDownloadingSelected || !this.selectedRows || this.selectedRows.length === 0;
    }

    downloadFile(fileUrl, filename) {
        const link = document.createElement('a');
        link.href = fileUrl;
        link.download = filename;
        link.click();
    }

    handleRowSelection(event) {
        this.selectedRows = event.detail.selectedRows || [];
    }

    async handleDownloadSelected() {
        if (this.disableDownloadSelected) {
            return;
        }

        this.isDownloadingSelected = true;

        try {
            for (const row of this.selectedRows) {
                if (row?.url) {
                    this.downloadFile(row.url, row.Title);
                    await this.delay(300);
                }
            }
        } finally {
            this.isDownloadingSelected = false;
        }
    }

    async handleDownloadAll() {
        if (this.disableDownloadAll) {
            return;
        }

        this.isDownloadingAll = true;

        try {
            for (const row of this.files) {
                if (row?.url) {
                    this.downloadFile(row.url, row.Title);
                    await this.delay(300);
                }
            }
        } finally {
            this.isDownloadingAll = false;
        }
    }

    downloadFile(url, fileName) {
        const link = document.createElement('a');
        link.href = url;
        link.download = fileName || 'download';
        link.rel = 'noopener';
        document.body.appendChild(link);
        link.click();
        link.remove();
    }

    delay(ms) {
        return new Promise((resolve) => {
            window.setTimeout(resolve, ms);
        });
    }


}
