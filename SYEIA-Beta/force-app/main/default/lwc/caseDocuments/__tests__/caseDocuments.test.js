import { createElement } from '@lwc/engine-dom';
import { CurrentPageReference } from 'lightning/navigation';
import CaseDocuments from 'c/caseDocuments';
import getCaseFiles from '@salesforce/apex/CaseFilesPanelController.getCaseFiles';

jest.mock('c/applicationDocumentManager', () => {
    const { LightningElement, registerDecorators } = require('lwc');
    class ApplicationDocumentManager extends LightningElement {}
    registerDecorators(ApplicationDocumentManager, { publicProps: { recordId: { config: 0 } } });
    return { __esModule: true, default: ApplicationDocumentManager };
}, { virtual: true });

jest.mock('@salesforce/apex/CaseFilesPanelController.getCaseFiles', () => ({
    default: jest.fn()
}), { virtual: true });

jest.mock('@salesforce/apex/CaseFilesPanelController.deleteCaseFile', () => ({
    default: jest.fn()
}), { virtual: true });

jest.mock('@salesforce/community/basePath', () => ({
    __esModule: true,
    default: '/s'
}), { virtual: true });

const flushPromises = () => Promise.resolve().then(() => Promise.resolve()).then(() => Promise.resolve());

describe('c-case-documents file cards', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('forwards card data through the documents component and resets it on navigation', async () => {
        getCaseFiles.mockResolvedValue([{
            documentId: '069000000000001AAA',
            title: 'Case file',
            fileType: 'PDF',
            contentSize: 1024
        }]);
        const element = createElement('c-case-documents', { is: CaseDocuments });
        const onFilesChange = jest.fn();
        element.useFileCards = true;
        element.addEventListener('fileschange', onFilesChange);
        document.body.appendChild(element);
        CurrentPageReference.emit({ state: { c__recordId: 'case-1' } });
        await flushPromises();

        const event = onFilesChange.mock.calls[onFilesChange.mock.calls.length - 1][0];
        expect(event.bubbles).toBe(true);
        expect(event.composed).toBe(true);
        expect(event.detail.files[0]).toMatchObject({
            title: 'Case file',
            previewId: '069000000000001'
        });

        CurrentPageReference.emit({ state: {} });
        await flushPromises();
        expect(onFilesChange.mock.calls[onFilesChange.mock.calls.length - 1][0].detail.hasFiles).toBe(false);
    });
});
