import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';

export default class CaseDocuments extends LightningElement {
    @api recordId;

    pageReference;

    @wire(CurrentPageReference)
    setPageReference(pageReference) {
        this.pageReference = pageReference;
    }

    get effectiveRecordId() {
        return this.pageReference?.state?.c__recordId;
    }
}