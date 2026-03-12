public with sharing class FileController {
    // @AuraEnabled(cacheable=true)
    public static List<ContentVersion> getFiles(Id recordId) {

        SET<Id> contentDocumentIdsSet = new SET<Id>();
        for (ContentDocumentLink cdl : [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :recordId
        ]) {
            contentDocumentIdsSet.add(cdl.ContentDocumentId);
        }

        return [
            SELECT Id, Title, FileType, ContentDocumentId
            FROM ContentVersion
            WHERE ContentDocumentId IN :contentDocumentIdsSet
            AND IsLatest = true
            ORDER BY Title
        ];
    }

    @AuraEnabled
    public static String getZipFiles() {

        Http http = new Http();
        HttpRequest req = new HttpRequest();

        // req.setEndpoint('callout:Files_API');
        // req.setMethod('POST');

        HttpResponse res = null;
        // res = http.send(req);

        Blob zipBlob = null;
        // zipBlob = res.getBodyAsBlob();
        // if (zipBlob == null) {
        //     Logger.log('Failed to retrieve zip file from the API. Response: ' + res.getBody());
        //     Logger.save();
        //     throw new AuraHandledException('Failed to retrieve zip file from the API.');
        // }

        StaticResource myZip = [SELECT Id, Name, Body FROM StaticResource WHERE Name = 'SampleZipFile' LIMIT 1];
        zipBlob = myZip.Body;

        return EncodingUtil.base64Encode(zipBlob);
    }
}