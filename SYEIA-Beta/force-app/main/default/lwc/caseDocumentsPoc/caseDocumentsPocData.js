const applicationDocuments = [
    {
        fileName: 'Wayleave copy - Plot 5 Turner Road',
        fileType: 'PDF',
        applicationSection: 'Application details',
        uploadMethod: 'Original application',
        uploadedBy: 'Applicant',
        dateAdded: '03.06.2026, 11:37'
    },
    {
        fileName: 'Notice to remove - Plot 5 Turner Road',
        fileType: 'PDF',
        applicationSection: 'Application details',
        uploadMethod: 'Original application',
        uploadedBy: 'Applicant',
        dateAdded: '03.06.2026, 11:37'
    },
    {
        fileName: 'UPDATED Notice to remove - Plot 5 Turner Road',
        fileType: 'PDF',
        applicationSection: 'Application details',
        uploadMethod: 'Further information',
        uploadedBy: 'Applicant',
        dateAdded: '03.06.2026, 11:37'
    },
    {
        fileName: 'Land Registry Certificate',
        fileType: 'JPEG',
        applicationSection: 'Land details',
        uploadMethod: 'Manual',
        uploadedBy: 'Case Officer',
        dateAdded: '03.06.2026, 11:37'
    },
    {
        fileName: 'Negotiations_Emails with Objector',
        fileType: 'MSG',
        applicationSection: 'Negotiations',
        uploadMethod: 'Original application',
        uploadedBy: 'Applicant',
        dateAdded: '03.06.2026, 11:37'
    }
];

const supportingDocuments = [
    {
        fileName: 'NWL 05 Abeyance Letter - Applicant',
        fileType: 'PDF',
        category: 'Additional Evidence',
        from: 'Landowner',
        uploadedBy: 'Case Officer',
        dateAdded: '15.06.2026, 10:37'
    },
    {
        fileName: 'NWL 05 Abeyance Letter - Applicant',
        fileType: 'PDF',
        category: 'Letters',
        from: 'PINS/PEDW',
        uploadedBy: 'PINS/PEDW',
        dateAdded: '21.08.2026, 11:10'
    },
    {
        fileName: 'Decision-letter',
        fileType: 'PDF',
        category: 'Letters',
        from: 'Decision Manager',
        uploadedBy: 'Decision Manager',
        dateAdded: '21.08.2026, 11:10'
    }
];

const caseOfficerDocuments = [
    {
        fileName: 'NWL 05 Abeyance Letter - Applicant',
        fileType: 'DOCX',
        published: false,
        uploadedBy: 'Decision Manager',
        dateAdded: '21.08.2026, 11:10'
    }
];

function makeSection(key, title, columns, documents) {
    return {
        key,
        title,
        columns,
        rows: documents.map((document, index) => ({
            key: `${key}-${index}`,
            fileName: document.fileName,
            fileType: document.fileType,
            cells: columns.map((column) => ({
                key: column.key,
                value: column.key === 'published'
                    ? (document.published ? 'Yes' : 'No')
                    : document[column.key],
                valueClass: column.key === 'fileName' ? 'file-name' : 'cell-value',
                isFileName: column.key === 'fileName',
                isPublished: column.key === 'published',
                published: document.published
            }))
        }))
    };
}

export default function getSampleDocuments() {
    return [
        makeSection('application', 'Application Documents', [
            { key: 'fileName', label: 'File name' },
            { key: 'fileType', label: 'File type' },
            { key: 'applicationSection', label: 'Application section' },
            { key: 'uploadMethod', label: 'Upload method' },
            { key: 'uploadedBy', label: 'Uploaded by' },
            { key: 'dateAdded', label: 'Date added ↓' }
        ], applicationDocuments),
        makeSection('supporting', 'Supporting Documents', [
            { key: 'fileName', label: 'File name' },
            { key: 'fileType', label: 'File type' },
            { key: 'category', label: 'Category' },
            { key: 'from', label: 'From' },
            { key: 'uploadedBy', label: 'Uploaded by' },
            { key: 'dateAdded', label: 'Date added ↓' }
        ], supportingDocuments),
        makeSection('case-officer', 'Case Officer Documents', [
            { key: 'fileName', label: 'File name' },
            { key: 'fileType', label: 'File type' },
            { key: 'published', label: 'Published' },
            { key: 'uploadedBy', label: 'Uploaded by' },
            { key: 'dateAdded', label: 'Date added ↓' }
        ], caseOfficerDocuments)
    ];
}