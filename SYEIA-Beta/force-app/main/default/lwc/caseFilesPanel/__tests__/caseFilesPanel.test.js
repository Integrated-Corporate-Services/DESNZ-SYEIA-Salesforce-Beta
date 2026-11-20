import { createElement } from '@lwc/engine-dom';
import LightningConfirm from 'lightning/confirm';
import CaseFilesPanel from 'c/caseFilesPanel';
import getCaseFiles from '@salesforce/apex/CaseFilesPanelController.getCaseFiles';
import deleteCaseFile from '@salesforce/apex/CaseFilesPanelController.deleteCaseFile';

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

const flushPromises = () => Promise.resolve().then(() => Promise.resolve());
const makeFile = (number) => ({
    documentId: `069000000000${String(number).padStart(3, '0')}AAA`,
    title: `File ${number}`,
    fileType: 'PDF',
    contentSize: 1024,
    canDelete: true
});

describe('c-case-files-panel file cards', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
        jest.restoreAllMocks();
    });

    it('sends preview IDs and the visible files to the Aura wrapper', async () => {
        getCaseFiles.mockResolvedValue(Array.from({ length: 11 }, (_, i) => makeFile(i)));
        const element = createElement('c-case-files-panel', { is: CaseFilesPanel });
        const onFilesChange = jest.fn();
        element.useFileCards = true;
        element.recordId = 'case-1';
        element.addEventListener('fileschange', onFilesChange);
        document.body.appendChild(element);
        await flushPromises();

        const detail = onFilesChange.mock.calls[onFilesChange.mock.calls.length - 1][0].detail;
        expect(detail.files).toHaveLength(10);
        expect(detail.files[0].previewId).toBe(detail.files[0].documentId.substring(0, 15));
        expect(detail.viewAllLabel).toBe('View All');
        expect(element.shadowRoot.querySelector('.files-list')).toBeNull();

        element.toggleFilesView();
        expect(onFilesChange.mock.calls[onFilesChange.mock.calls.length - 1][0].detail)
            .toMatchObject({ files: expect.arrayContaining([expect.objectContaining({ title: 'File 10' })]), viewAllLabel: 'Show Less' });
    });

    it('clears stale cards and loads files when the case changes', async () => {
        getCaseFiles.mockResolvedValueOnce([makeFile(1)]).mockResolvedValueOnce([makeFile(2)]);
        const element = createElement('c-case-files-panel', { is: CaseFilesPanel });
        const onFilesChange = jest.fn();
        element.useFileCards = true;
        element.recordId = 'case-1';
        element.addEventListener('fileschange', onFilesChange);
        document.body.appendChild(element);
        await flushPromises();

        element.recordId = 'case-2';
        expect(onFilesChange.mock.calls[onFilesChange.mock.calls.length - 1][0].detail.hasFiles).toBe(false);
        await flushPromises();
        expect(getCaseFiles).toHaveBeenLastCalledWith({ parentRecordId: 'case-2' });
        expect(onFilesChange.mock.calls[onFilesChange.mock.calls.length - 1][0].detail.files[0].title).toBe('File 2');
    });

    it('keeps delete permissions and confirmation when deleting from a card', async () => {
        const permittedFile = makeFile(1);
        const otherFile = { ...makeFile(2), canDelete: false };
        getCaseFiles.mockResolvedValue([permittedFile, otherFile]);
        deleteCaseFile.mockResolvedValue();
        const confirm = jest.spyOn(LightningConfirm, 'open').mockResolvedValue(true);
        const element = createElement('c-case-files-panel', { is: CaseFilesPanel });
        element.useFileCards = true;
        element.recordId = 'case-1';
        document.body.appendChild(element);
        await flushPromises();

        await element.deleteFile(otherFile.documentId);
        expect(confirm).not.toHaveBeenCalled();
        expect(deleteCaseFile).not.toHaveBeenCalled();

        await element.deleteFile(permittedFile.documentId);
        expect(confirm).toHaveBeenCalledTimes(1);
        expect(deleteCaseFile).toHaveBeenCalledWith({
            parentRecordId: 'case-1',
            documentId: permittedFile.documentId
        });
    });

    it.each([
        ['/s', '/sfc/servlet.shepherd/document/download/069000000000001AAA'],
        ['/portal/s', '/portal/sfc/servlet.shepherd/document/download/069000000000001AAA'],
        ['/portal', '/portal/sfc/servlet.shepherd/document/download/069000000000001AAA']
    ])('downloads using the site prefix for base path %s', (basePath, expectedUrl) => {
        jest.requireMock('@salesforce/community/basePath').default = basePath;
        const open = jest.spyOn(window, 'open').mockImplementation(() => null);
        const element = createElement('c-case-files-panel', { is: CaseFilesPanel });

        element.downloadFile('069000000000001AAA');

        expect(open).toHaveBeenCalledWith(expectedUrl, '_self');
    });
});
