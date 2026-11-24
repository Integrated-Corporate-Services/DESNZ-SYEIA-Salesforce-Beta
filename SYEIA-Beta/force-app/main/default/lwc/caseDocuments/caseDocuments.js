import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';

export default class CaseDocuments extends LightningElement {
    @api recordId;
    @api useFileCards = false;

    pageReference;

    @wire(CurrentPageReference)
    setPageReference(pageReference) {
        const previousRecordId = this.effectiveRecordId;
        this.pageReference = pageReference;
        if (this.useFileCards && previousRecordId !== this.effectiveRecordId) {
            this.dispatchEvent(new CustomEvent('fileschange', {
                detail: { files: [], hasFiles: false },
                bubbles: true,
                composed: true
            }));
        }
    }

    get effectiveRecordId() {
        return this.pageReference?.state?.c__recordId;
    }

    @api
    deleteFile(documentId) {
        return this.template.querySelector('c-case-files-panel').deleteFile(documentId);
    }

    @api
    downloadFile(documentId) {
        this.template.querySelector('c-case-files-panel').downloadFile(documentId);
    }

    @api
    toggleFilesView() {
        this.template.querySelector('c-case-files-panel').toggleFilesView();
    }
}