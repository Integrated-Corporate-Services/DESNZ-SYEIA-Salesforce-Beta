import { createElement } from '@lwc/engine-dom';
import { getListRecordsByName } from 'lightning/uiListsApi';
import CaseManagementSuite from 'c/caseManagementSuite';

jest.mock('lightning/uiListsApi', () => {
    const { createLdsTestWireAdapter } = require('@salesforce/wire-service-jest-util');
    return { getListRecordsByName: createLdsTestWireAdapter(jest.fn()) };
}, { virtual: true });

jest.mock('@salesforce/user/isGuest', () => ({ __esModule: true, default: false }), { virtual: true });

const flushPromises = () => Promise.resolve();
const casePage = {
    records: [{
        id: 'a00000000000001AAA',
        fields: {
            Name: { value: 'CASE-001' },
            Case_Type__c: { value: 'Section 37' },
            Status__c: { value: 'New', displayValue: 'New' }
        }
    }],
    nextPageToken: '25',
    previousPageToken: null
};

function mount() {
    const element = createElement('c-case-management-suite', { is: CaseManagementSuite });
    document.body.appendChild(element);
    return element;
}

describe('c-case-management-suite', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
        jest.requireMock('@salesforce/user/isGuest').default = false;
    });

    it('loads cases and opens read-only details without leaving the site', async () => {
        const element = mount();
        getListRecordsByName.emit(casePage);
        await flushPromises();
        expect(element.shadowRoot.textContent).toContain('CASE-001');
        element.shadowRoot.querySelector('button[data-id]').click();
        await flushPromises();
        const form = element.shadowRoot.querySelector('lightning-record-form');
        expect(form.recordId).toBe(casePage.records[0].id);
        expect(form.mode).toBe('readonly');
        element.shadowRoot.querySelector('lightning-button').click();
        await flushPromises();
        expect(element.shadowRoot.querySelector('lightning-record-form')).toBeNull();
    });

    it('requests the next page and resets pagination when searching', async () => {
        const element = mount();
        getListRecordsByName.emit(casePage);
        await flushPromises();
        const buttons = element.shadowRoot.querySelectorAll('nav lightning-button');
        expect(buttons[0].disabled).toBe(true);
        buttons[1].click();
        await flushPromises();
        expect(getListRecordsByName.getLastConfig().pageToken).toBe('25');
        const search = element.shadowRoot.querySelector('lightning-input');
        search.value = ' CASE-001 ';
        search.dispatchEvent(new CustomEvent('change'));
        await flushPromises();
        expect(getListRecordsByName.getLastConfig()).toMatchObject({
            pageToken: '0', searchTerm: 'CASE-001'
        });
    });

    it('handles empty results and inaccessible optional fields', async () => {
        const element = mount();
        getListRecordsByName.emit({ records: [] });
        await flushPromises();
        expect(element.shadowRoot.textContent).toContain('No cases found.');
        getListRecordsByName.emit({ records: [{ id: 'a00000000000001AAA', fields: { Name: { value: 'CASE-002' } } }] });
        await flushPromises();
        expect(element.shadowRoot.textContent).toContain('CASE-002');
    });

    it('clears stale records on errors without exposing server details', async () => {
        const element = mount();
        getListRecordsByName.emit(casePage);
        await flushPromises();
        getListRecordsByName.error({ message: 'Internal diagnostic' });
        await flushPromises();
        expect(element.shadowRoot.querySelector('[role="alert"]').textContent).toContain('Cases could not be loaded');
        expect(element.shadowRoot.querySelector('button[data-id]')).toBeNull();
        expect(element.shadowRoot.textContent).not.toContain('Internal diagnostic');
    });

    it('does not request case data for guests', async () => {
        jest.requireMock('@salesforce/user/isGuest').default = true;
        const element = mount();
        await flushPromises();
        expect(getListRecordsByName.getLastConfig().objectApiName).toBeUndefined();
        expect(element.shadowRoot.textContent).toContain('Sign in to view your cases.');
        expect(element.shadowRoot.querySelector('lightning-input')).toBeNull();
    });

    it('reports detail errors without displaying server diagnostics', async () => {
        const element = mount();
        getListRecordsByName.emit(casePage);
        await flushPromises();
        element.shadowRoot.querySelector('button[data-id]').click();
        await flushPromises();
        element.shadowRoot.querySelector('lightning-record-form').dispatchEvent(new CustomEvent('error'));
        await flushPromises();
        expect(element.shadowRoot.querySelector('[role="alert"]').textContent).toContain('This case could not be opened');
    });
});