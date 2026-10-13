import { createElement } from '@lwc/engine-dom';
import CaseDetails from 'c/caseDetails';

describe('c-case-details', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('shows a message when no Case record ID is available', () => {
        const element = createElement('c-case-details', {
            is: CaseDetails
        });

        document.body.appendChild(element);

        expect(element.shadowRoot.textContent).toContain('The Case record ID is unavailable.');
    });

    it('shows only Area A sections when Area A is selected', () => {
        const element = createElement('c-case-details', {
            is: CaseDetails
        });
        element.recordId = '500000000000001';
        element.area = 'A';

        document.body.appendChild(element);

        expect(element.shadowRoot.textContent).toContain('Event Details');
        expect(element.shadowRoot.textContent).toContain('Applicant Details');
        expect(element.shadowRoot.textContent).not.toContain('Case Overview');
    });

    it('shows the page-layout sections assigned to Area B', () => {
        const element = createElement('c-case-details', {
            is: CaseDetails
        });
        element.recordId = '500000000000001';
        element.area = 'B';

        document.body.appendChild(element);

        expect(element.shadowRoot.textContent).toContain('Case Overview');
        expect(element.shadowRoot.textContent).toContain('Assessment Details');
        expect(element.shadowRoot.textContent).toContain('Representation Details');
        expect(element.shadowRoot.textContent).toContain('Decision Details');
        expect(element.shadowRoot.textContent).toContain('Abeyance Details');
        expect(element.shadowRoot.textContent).not.toContain('Event Details');
    });
});
