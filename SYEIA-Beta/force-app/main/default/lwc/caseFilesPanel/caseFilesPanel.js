import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import LightningConfirm from 'lightning/confirm';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getCaseFiles from '@salesforce/apex/CaseFilesPanelController.getCaseFiles';
import deleteCaseFile from '@salesforce/apex/CaseFilesPanelController.deleteCaseFile';
import basePath from '@salesforce/community/basePath';

const PREVIEW_SIZE = 10;

export default class CaseFilesPanel extends NavigationMixin(LightningElement) {
    _recordId;
    @api useFileCards = false;

    @api
    get recordId() {
        return this._recordId;
    }

    set recordId(value) {
        if (value !== this._recordId) {
            this._recordId = value;
            this.loadSequence += 1;
            this.files = [];
            this.filesError = undefined;
            this.isViewAll = false;
            this.notifyFilesChanged();
            if (this.isConnected && value) {
                this.loadFiles();
            }
        }
    }

    files = [];
    filesError;
    isLoading = true;
    isDeleting = false;
    isViewAll = false;
    showUploader = false;
    loadSequence = 0;
    windowFocusHandler = () => this.loadFiles();
    visibilityChangeHandler = () => {
        if (document.visibilityState === 'visible') {
            this.loadFiles();
        }
    };

    connectedCallback() {
        window.addEventListener('focus', this.windowFocusHandler);
        document.addEventListener('visibilitychange', this.visibilityChangeHandler);
        this.loadFiles();
    }

    disconnectedCallback() {
        window.removeEventListener('focus', this.windowFocusHandler);
        document.removeEventListener('visibilitychange', this.visibilityChangeHandler);
    }

    async loadFiles() {
        if (!this.recordId) {
            return false;
        }

        const currentSequence = ++this.loadSequence;
        this.isLoading = true;
        this.filesError = undefined;
        try {
            const data = await getCaseFiles({ parentRecordId: this.recordId });
            if (currentSequence === this.loadSequence) {
                this.files = data.map((file) => this.formatFile(file));
                this.filesError = undefined;
                this.notifyFilesChanged();
            }
            return true;
        } catch (error) {
            if (currentSequence === this.loadSequence) {
                this.files = [];
                this.filesError = this.getErrorMessage(error);
                this.notifyFilesChanged();
            }
            return false;
        } finally {
            if (currentSequence === this.loadSequence) {
                this.isLoading = false;
            }
        }
    }

    async handleRefresh() {
        await this.loadFiles();
    }

    get fileCount() {
        return this.files.length;
    }

    get hasFiles() {
        return this.fileCount > 0;
    }

    get visibleFiles() {
        return this.isViewAll ? this.files : this.files.slice(0, PREVIEW_SIZE);
    }

    get viewAllLabel() {
        return this.isViewAll ? 'Show Less' : 'View All';
    }

    formatFile(file) {
        const fileType = file.fileType || '';
        const size = Number(file.contentSize) || 0;
        const date = file.lastModifiedDate
            ? new Intl.DateTimeFormat(undefined, {
                  day: 'numeric',
                  month: 'short',
                  year: 'numeric'
              }).format(new Date(file.lastModifiedDate))
            : '';

        return {
            ...file,
            iconName: this.getIconName(fileType),
            fileTypeLabel: fileType.toLowerCase(),
            metadata: [date, this.formatSize(size), fileType.toLowerCase()]
                .filter(Boolean)
                .join(' • ')
        };
    }

    getIconName(fileType) {
        const type = fileType.toLowerCase();
        if (['png', 'jpg', 'jpeg', 'gif', 'bmp'].includes(type)) {
            return 'doctype:image';
        }
        if (type === 'pdf') {
            return 'doctype:pdf';
        }
        if (['doc', 'docx'].includes(type)) {
            return 'doctype:word';
        }
        if (['xls', 'xlsx', 'csv'].includes(type)) {
            return 'doctype:excel';
        }
        return 'doctype:attachment';
    }

    formatSize(size) {
        if (size >= 1024 * 1024) {
            return `${Math.round((size / (1024 * 1024)) * 10) / 10}MB`;
        }
        if (size >= 1024) {
            return `${Math.round(size / 1024)}KB`;
        }
        return `${size}B`;
    }

    handleShowUploader() {
        this.showUploader = !this.showUploader;
    }

    async handleUploadFinished(event) {
        const fileCount = event.detail.files.length;
        this.showUploader = false;
        const refreshed = await this.loadFiles();
        if (refreshed) {
            const fileLabel = fileCount === 1 ? 'file' : 'files';
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Upload complete',
                    message: `${fileCount} ${fileLabel} uploaded and attached to this Case.`,
                    variant: 'success'
                })
            );
        } else {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Upload complete, refresh failed',
                    message: 'The upload succeeded, but the file list could not be refreshed. Use Refresh files to try again.',
                    variant: 'warning'
                })
            );
        }
    }

    handleViewAll() {
        this.toggleFilesView();
    }

    @api
    toggleFilesView() {
        this.isViewAll = !this.isViewAll;
        this.notifyFilesChanged();
    }

    notifyFilesChanged() {
        if (this.useFileCards) {
            this.dispatchEvent(new CustomEvent('fileschange', {
                detail: {
                    files: this.visibleFiles.map((file) => ({
                        ...file,
                        previewId: file.documentId.substring(0, 15)
                    })),
                    hasFiles: this.hasFiles,
                    viewAllLabel: this.viewAllLabel
                },
                bubbles: true,
                composed: true
            }));
        }
    }

    async handleDelete(event) {
        await this.deleteFile(event.currentTarget.dataset.documentId);
    }

    @api
    async deleteFile(documentId) {
        const file = this.files.find((item) => item.documentId === documentId);
        if (this.isDeleting || !file?.canDelete) {
            return;
        }

        const parentRecordId = this.recordId;
        this.isDeleting = true;
        try {
            const confirmed = await LightningConfirm.open({
                label: 'Delete file',
                message: `Delete "${file.title}".`,
                theme: 'error'
            });
            if (!confirmed) {
                return;
            }

            await deleteCaseFile({ parentRecordId, documentId });
            const refreshed = await this.loadFiles();
            this.dispatchEvent(
                new ShowToastEvent({
                    title: refreshed ? 'File deleted' : 'File deleted, refresh failed',
                    message: refreshed
                        ? `"${file.title}" was deleted from Salesforce.`
                        : 'The file was deleted, but the file list could not be refreshed. Use Refresh files to try again.',
                    variant: refreshed ? 'success' : 'warning'
                })
            );
        } catch (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Unable to delete file',
                    message: this.getErrorMessage(error),
                    variant: 'error'
                })
            );
        } finally {
            this.isDeleting = false;
        }
    }

    handlePreview(event) {
        const documentId = event.currentTarget.dataset.documentId;
        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: {
                pageName: 'filePreview'
            },
            state: {
                recordIds: documentId,
                selectedRecordId: documentId
            }
        });
    }

    handleDownload(event) {
        this.downloadFile(event.currentTarget.dataset.documentId);
    }

    @api
    downloadFile(documentId) {
        try {
            this.isDownloading = true;
            console.log('Starting download for documentId:', documentId);
            const sitePrefix = basePath.replace(/\/s\/?$/, '');
            window.open(`${sitePrefix}/sfc/servlet.shepherd/document/download/${documentId}`, '_self');
        } catch (error) {
            console.error('Error downloading documentId:', documentId, error);
        } finally {
            console.log('Finished download attempt for documentId:', documentId);
            this.isDownloading = false;
        }
    }

    getErrorMessage(error) {
        const body = error?.body;
        if (Array.isArray(body)) {
            return body.map((item) => item.message).join(', ');
        }
        return body?.message || error?.message || 'An unexpected error occurred.';
    }
}