/* eslint-disable no-unused-expressions */
({
    handleFilesChange: function (component, event) {
        component.set('v.files', event.getParam('files'));
        component.set('v.hasFiles', event.getParam('hasFiles'));
        component.set('v.viewAllLabel', event.getParam('viewAllLabel') || 'View All');
    },

    handleDownload: function (component, event) {
        component.find('documents').downloadFile(event.currentTarget.dataset.documentId);
    },

    handleDelete: function (component, event) {
        component.find('documents').deleteFile(event.currentTarget.dataset.documentId);
    },

    handleViewAll: function (component) {
        component.find('documents').toggleFilesView();
    }
})
