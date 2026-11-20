import { createElement } from '@lwc/engine-dom';
import { CurrentPageReference } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';
import NwlPaymentInformation from 'c/nwlPaymentInformation';

const flushPromises = () => Promise.resolve().then(() => Promise.resolve());
const forRecord = (recordId) => (config) => config.recordId === recordId;
const caseRecord = (paymentId) => ({
    fields: { Payment__c: { value: paymentId } }
});
const paymentRecord = (status) => ({
    fields: { Status__c: { value: status } }
});
const displayedValues = (element) => Array.from(
    element.shadowRoot.querySelectorAll('lightning-formatted-text'),
    (field) => field.value
);

describe('c-nwl-payment-information', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.restoreAllMocks();
    });

    it('loads the linked payment and retains it when the case is refreshed', async () => {
        const element = createElement('c-nwl-payment-information', { is: NwlPaymentInformation });
        document.body.appendChild(element);
        CurrentPageReference.emit({ state: { c__recordId: 'case-1' } });
        await flushPromises();

        getRecord.emit(caseRecord('payment-1'), forRecord('case-1'));
        await flushPromises();
        expect(element.shadowRoot.querySelector('lightning-spinner')).not.toBeNull();

        getRecord.emit(paymentRecord('Paid'), forRecord('payment-1'));
        await flushPromises();
        expect(displayedValues(element)).toContain('Paid');

        getRecord.emit(caseRecord('payment-1'), forRecord('case-1'));
        await flushPromises();
        expect(displayedValues(element)).toContain('Paid');

        getRecord.emit(caseRecord('payment-2'), forRecord('case-1'));
        await flushPromises();
        expect(element.shadowRoot.querySelector('lightning-spinner')).not.toBeNull();
        getRecord.emit(paymentRecord('Pending'), forRecord('payment-2'));
        await flushPromises();
        expect(displayedValues(element)).toContain('Pending');
        expect(displayedValues(element)).not.toContain('Paid');
    });

    it('prefers the URL case ID and displays when no payment is linked', async () => {
        const element = createElement('c-nwl-payment-information', { is: NwlPaymentInformation });
        element.recordId = 'configured-case';
        document.body.appendChild(element);
        CurrentPageReference.emit({ state: { c__recordId: 'url-case' } });
        await flushPromises();

        getRecord.emit(caseRecord(null), forRecord('url-case'));
        await flushPromises();
        expect(element.shadowRoot.textContent).toContain('No payment is linked to this case.');
        expect(element.shadowRoot.querySelector('lightning-spinner')).toBeNull();
    });

    it('reports payment read errors and recovers when the payment is available', async () => {
        jest.spyOn(console, 'error').mockImplementation(() => {});
        const element = createElement('c-nwl-payment-information', { is: NwlPaymentInformation });
        document.body.appendChild(element);
        CurrentPageReference.emit({ state: { c__recordId: 'case-1' } });
        await flushPromises();
        getRecord.emit(caseRecord('payment-1'), forRecord('case-1'));
        await flushPromises();

        getRecord.emitError({ body: { message: 'Access denied' }, status: 403 }, forRecord('payment-1'));
        await flushPromises();
        expect(element.shadowRoot.querySelector('[role="alert"]').textContent)
            .toContain('Unable to load the linked payment.');
        expect(console.error).toHaveBeenCalled();

        getRecord.emit(paymentRecord('Paid'), forRecord('payment-1'));
        await flushPromises();
        expect(element.shadowRoot.querySelector('[role="alert"]')).toBeNull();
        expect(displayedValues(element)).toContain('Paid');
    });

    it('reports case read errors and recovers when the case has no payment', async () => {
        jest.spyOn(console, 'error').mockImplementation(() => {});
        const element = createElement('c-nwl-payment-information', { is: NwlPaymentInformation });
        document.body.appendChild(element);
        CurrentPageReference.emit({ state: { c__recordId: 'case-1' } });
        await flushPromises();

        getRecord.emitError({ body: { message: 'Access denied' }, status: 403 }, forRecord('case-1'));
        await flushPromises();
        expect(element.shadowRoot.querySelector('[role="alert"]').textContent)
            .toContain('Unable to load the case payment information.');

        getRecord.emit(caseRecord(null), forRecord('case-1'));
        await flushPromises();
        expect(element.shadowRoot.textContent).toContain('No payment is linked to this case.');
    });
});
