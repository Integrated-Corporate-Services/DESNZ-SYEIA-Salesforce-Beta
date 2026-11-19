import { createElement } from '@lwc/engine-dom';
import { CurrentPageReference } from 'lightning/navigation';
import CaseDetails from 'c/caseDetails';

jest.mock('c/nwlObjectorDetails', () => {
    const { LightningElement, registerDecorators } = require('lwc');
    class ObjectorDetails extends LightningElement {}
    registerDecorators(ObjectorDetails, { publicProps: { recordId: { config: 0 } } });
    return { __esModule: true, default: ObjectorDetails };
}, { virtual: true });

jest.mock('c/nwlLandDetails', () => {
    const { LightningElement, registerDecorators } = require('lwc');
    class LandDetails extends LightningElement {}
    registerDecorators(LandDetails, { publicProps: { recordId: { config: 0 } } });
    return { __esModule: true, default: LandDetails };
}, { virtual: true });

const flushPromises = () => Promise.resolve();

describe('c-case-details', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('shows Name as read-only while keeping the other event fields editable', async () => {
        const element = createElement('c-case-details', { is: CaseDetails });
        document.body.appendChild(element);
        CurrentPageReference.emit({ state: { c__recordId: 'first-case' } });
        await flushPromises();

        const eventSection = element.shadowRoot
            .querySelector('button[data-section-name="event-details"]')
            .closest('section');
        const forms = eventSection.querySelectorAll('lightning-record-form');
        expect(forms).toHaveLength(2);
        expect(forms[0].fields).toEqual(['Name']);
        expect(forms[0].mode).toBe('readonly');
        expect(forms[1].fields).not.toContain('Name');
        expect(forms[1].fields).toContain('PINS_PEDW_1st_Referral_Date__c');
        expect(forms[1].mode).toBe('view');
    });

    it('uses the URL case ID instead of a configured preview ID and updates when it changes', async () => {
        const element = createElement('c-case-details', { is: CaseDetails });
        element.recordId = 'preview-id';
        document.body.appendChild(element);

        CurrentPageReference.emit({ state: { c__recordId: 'first-case' } });
        await flushPromises();
        expect(element.shadowRoot.querySelector('lightning-record-form').recordId).toBe('first-case');
        expect(element.shadowRoot.querySelector('c-nwl-objector-details').recordId).toBe('first-case');
        expect(element.shadowRoot.querySelector('c-nwl-land-details').recordId).toBe('first-case');

        CurrentPageReference.emit({ state: { c__recordId: 'second-case' } });
        await flushPromises();
        expect(element.shadowRoot.querySelector('lightning-record-form').recordId).toBe('second-case');
        expect(element.shadowRoot.querySelector('c-nwl-objector-details').recordId).toBe('second-case');
        expect(element.shadowRoot.querySelector('c-nwl-land-details').recordId).toBe('second-case');
    });

    it('uses the supplied record ID before the page record ID when no URL case ID is present', async () => {
        const element = createElement('c-case-details', { is: CaseDetails });
        element.recordId = 'supplied-id';
        document.body.appendChild(element);

        CurrentPageReference.emit({ attributes: { recordId: 'page-id' } });
        await flushPromises();
        expect(element.shadowRoot.querySelector('lightning-record-form').recordId).toBe('supplied-id');

        element.recordId = undefined;
        await flushPromises();
        expect(element.shadowRoot.querySelector('lightning-record-form').recordId).toBe('page-id');
    });
});
