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
        String bearerToken = '00DVd000005O3eb!AQEAQJ7ZsjNcnxO9OSqG5I1vb._Pwa.f7W5l855GJ63R7Zr4orIna2W5jSa3AgnJNqoL0lBfdVowJvnNoYLhFEdbhnPJbbvA';

        // req.setEndpoint('callout:Files_API');
        req.setEndpoint('https://api.dev.syeia.energysecurity.gov.uk/backend/api/v1/internal/applications/a79322f2-51c5-4391-ac57-21745bf5ac72/documents/zip'); 
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + bearerToken);
        // req.setHeader('Idempotency-Key', String.valueOf(Crypto.getRandomLong()));
        req.setHeader('X-Acting-User-Email', UserInfo.getUserEmail());
        req.setHeader('X-Acting-User-Id', UserInfo.getUserId());
        req.setHeader('X-Acting-User-Role', 'desnz_caseworker');
        req.setHeader('X-Correlation-ID', String.valueOf(Crypto.getRandomLong()));
        Map<String,String> payload = new Map<String,String>{
            'scope' => 'APPLICATION'
        };
        req.setBody(JSON.serialize(payload));
        
        Logger.info('Sending request to get zip file for applicationId: ' + applicationId);
        HttpResponse res = null;
        res = http.send(req);

        Blob zipBlob = null;
        zipBlob = res.getBodyAsBlob();
        if (zipBlob == null) {
            Logger.log('Failed to retrieve zip file from the API. Response: ' + res.getBody());
            Logger.save();
            throw new AuraHandledException('Failed to retrieve zip file from the API.');
        }

        // StaticResource myZip = [SELECT Id, Name, Body FROM StaticResource WHERE Name = 'SampleZipFile' LIMIT 1];
        // zipBlob = myZip.Body;

        return EncodingUtil.base64Encode(zipBlob);
    }
}