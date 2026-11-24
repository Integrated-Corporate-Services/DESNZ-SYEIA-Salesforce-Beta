import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';

export default class CaseDocuments extends LightningElement {
    @api recordId;

    pageRecordId;

    @wire(CurrentPageReference)
    setPageReference(pageReference) {
        this.pageRecordId =
            pageReference?.state?.c__recordId || pageReference?.attributes?.recordId;
    }

    get effectiveRecordId() {
        return this.recordId || this.pageRecordId;
    }
}