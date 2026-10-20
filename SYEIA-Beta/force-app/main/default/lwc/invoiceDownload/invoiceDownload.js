import { LightningElement, wire } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import {
    IsConsoleNavigation,
    EnclosingTabId,
    setTabLabel,
    setTabIcon,
    closeTab
} from 'lightning/platformWorkspaceApi';
import getApplicationDocuments from '@salesforce/apex/FileController.getApplicationDocuments';
import getDocumentDownloadUrl from '@salesforce/apex/FileController.getDocumentDownloadUrl';

export default class InvoiceDownload extends NavigationMixin(LightningElement) {
    message = 'Downloading invoice…';
    lastKey;
    returnUrl;
    tabLabelled = false;

    @wire(IsConsoleNavigation) isConsole;
    @wire(EnclosingTabId) tabId;

    connectedCallback() {
        console.log('[invoiceDownload] component loaded');
    }

    renderedCallback() {
        // Give the console subtab a proper label instead of "Loading..."
        if (this.isConsole && this.tabId && !this.tabLabelled) {
            this.tabLabelled = true;
            setTabLabel(this.tabId, 'Invoice');
            setTabIcon(this.tabId, 'utility:download');
        }
    }

    // Values come from the formula-field link
    @wire(CurrentPageReference)
    handlePageRef(ref) {
        console.log('[invoiceDownload] page state:', JSON.stringify(ref?.state));

        const recordId      = ref?.state?.c__recordId;  // Case Id (record to return to)
        const applicationId = ref?.state?.c__appId;     // Case__r.AWS_Application_Id__c
        const invoiceRef    = ref?.state?.c__ref;       // Invoice_Reference__c
        this.returnUrl      = ref?.state?.ws;           // page the user clicked from (console)
        const key = [recordId, applicationId, invoiceRef].join('|');

        if (!recordId || !applicationId || key === this.lastKey) {
            console.log('[invoiceDownload] skipped', {
                recordId, applicationId, sameAsLast: key === this.lastKey
            });
            return;
        }
        this.lastKey = key;
        this.download(recordId, applicationId, invoiceRef);
    }

    async download(recordId, applicationId, invoiceRef) {
        console.log('[invoiceDownload] download()', { recordId, applicationId, invoiceRef });
        try {
            // 1. List the application's documents (same as "Get Applicant Files")
            const response = await getApplicationDocuments({ applicationId });
            const parsed = JSON.parse(response);
            const documents = Array.isArray(parsed) ? parsed : parsed.documents || [];
            console.log('[invoiceDownload] documents:', JSON.stringify(documents));

            // 2. Find the invoice
            const invoices = documents.filter(
                d => (d.category || '').toUpperCase() === 'INVOICE'
            );
            const invoice =
                invoices.find(d => invoiceRef && (d.title || '').includes(invoiceRef)) ||
                invoices[0];
            console.log('[invoiceDownload] invoice picked:', JSON.stringify(invoice));

            if (!invoice) {
                throw new Error('No invoice document found for this application.');
            }

            // 3. Get its pre-signed URL (same as the "Download" button)
            const downloadUrl = await getDocumentDownloadUrl({
                applicationId,
                documentId: invoice.document_id
            });
            console.log('[invoiceDownload] downloadUrl:', downloadUrl);

            if (!downloadUrl) {
                throw new Error('The document did not return a download URL.');
            }

            // 4. Download
            const a = document.createElement('a');
            a.href = downloadUrl;
            a.click();

            // 5. Return the user to where they were
            this.message = 'Invoice downloaded.';
            this.finish(recordId);
        } catch (e) {
            // On error, stay on this subtab so the message is visible
            const msg = e?.body?.message || e?.message || 'Unknown error';
            console.error('[invoiceDownload] error:', e);
            this.message = 'Could not download invoice: ' + msg;
            this.dispatchEvent(new ShowToastEvent({
                title: 'Download failed',
                message: msg,
                variant: 'error'
            }));
        }
    }

    finish(recordId) {
        console.log('[invoiceDownload] finish', {
            isConsole: this.isConsole, tabId: this.tabId, returnUrl: this.returnUrl
        });

        // 1. Console subtab: close it -> user is back on the Case tab, unchanged
        if (this.isConsole && this.tabId) {
            setTimeout(() => closeTab(this.tabId), 1000);
            return;
        }

        // 2. Go back to the exact page the user came from
        if (this.returnUrl) {
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: { url: this.returnUrl }
            }, true);
            return;
        }

        // 3. Fallback: the record passed in the link (the Case)
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: { recordId, actionName: 'view' }
        }, true);
    }
}