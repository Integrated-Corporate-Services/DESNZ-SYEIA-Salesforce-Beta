import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getSampleDocuments from './caseDocumentsPocData';

export default class CaseDocumentsPoc extends LightningElement {
    sections = getSampleDocuments();
    previewDocument;

    handleDemoAction(event) {
        const action = event.currentTarget.dataset.action;
        const section = event.currentTarget.dataset.section;
        const message = action === 'upload'
            ? `Demo only: no file was uploaded to ${section}.`
            : `Demo only: no files were downloaded from ${section}.`;
        this.showDemoToast(message);
    }

    handleDocumentAction(event) {
        const { rowKey } = event.currentTarget.dataset;
        if (event.detail.value === 'preview') {
            this.openPreview(rowKey);
            return;
        }
        this.showDemoToast('Demo only: no file was downloaded.');
    }

    handlePreview(event) {
        this.openPreview(event.currentTarget.dataset.rowKey);
    }

    openPreview(rowKey) {
        for (const section of this.sections) {
            const row = section.rows.find((item) => item.key === rowKey);
            if (row) {
                this.previewDocument = row;
                return;
            }
        }
    }

    closePreview() {
        this.previewDocument = undefined;
    }

    handlePublishedToggle(event) {
        const { rowKey } = event.currentTarget.dataset;
        const published = event.target.checked;
        this.sections = this.sections.map((section) => ({
            ...section,
            rows: section.rows.map((row) => row.key !== rowKey ? row : {
                ...row,
                cells: row.cells.map((cell) => cell.isPublished ? {
                    ...cell,
                    published,
                    value: published ? 'Yes' : 'No'
                } : cell)
            })
        }));
        this.showDemoToast('Demo only: this change is temporary and was not saved.');
    }

    showDemoToast(message) {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Demo interaction',
            message,
            variant: 'info'
        }));
    }
}