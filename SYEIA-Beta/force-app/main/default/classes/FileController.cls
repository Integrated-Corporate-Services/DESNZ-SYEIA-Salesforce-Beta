public with sharing class FileController {

    public class AsyncDownloadStatus {
        @AuraEnabled public String status;
        @AuraEnabled public Id contentVersionId;
        @AuraEnabled public String errorMessage;
    }

    public class AsyncDownloadRequest {
        @AuraEnabled public Id jobId;
        @AuraEnabled public String requestToken;
    }


    @AuraEnabled(cacheable=true)
    public static String getApplicationDocuments(String applicationId) {
        HttpRequest req = new HttpRequest();
        String bearerToken = OAuthTokenService.getBearerToken();

        req.setEndpoint('callout:Applicant_File_Download/' + applicationId + '/documents');
        req.setMethod('GET');
        req.setHeader('Accept', '*/*');
        req.setHeader('Authorization', 'Bearer ' + bearerToken);
        req.setHeader('X-Acting-User-Email', UserInfo.getUserEmail());
        req.setHeader('X-Acting-User-Id', UserInfo.getUserId());
        req.setHeader('X-Acting-User-Role', 'desnz_caseworker');
        req.setHeader('X-Correlation-ID', String.valueOf(Crypto.getRandomLong()));

        try {
            HttpResponse res = new Http().send(req);
            if (res.getStatusCode() != 200) {
                Logger.error('Failed to get application documents. Status: ' + res.getStatusCode() + ', Response: ' + res.getBody());
                Logger.saveLog();
                throw new AuraHandledException('Failed to get application documents. Status: ' + res.getStatusCode());
            }
            System.debug('test ' + res.getBody());
            return res.getBody();
        } catch (Exception e) {
            Logger.error('Error getting application documents: ' + e.getMessage());
            Logger.saveLog();
            throw new AuraHandledException('Error getting application documents: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String downloadApplicationDocument(String applicationId, String documentId) {
        HttpRequest req = new HttpRequest();
        String bearerToken = OAuthTokenService.getBearerToken();

        req.setEndpoint('callout:Applicant_File_Download/' + applicationId + '/documents/download');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/zip');
        req.setHeader('Authorization', 'Bearer ' + bearerToken);
        req.setHeader('X-Acting-User-Email', UserInfo.getUserEmail());
        req.setHeader('X-Acting-User-Id', UserInfo.getUserId());
        req.setHeader('X-Acting-User-Role', 'desnz_caseworker');
        req.setHeader('X-Correlation-ID', String.valueOf(Crypto.getRandomLong()));
        req.setBody(JSON.serialize(new Map<String, Object>{
            'scope' => 'SELECTION',
            'documentIds' => new List<String>{ documentId }
        }));

        try {
            HttpResponse res = new Http().send(req);
            if (res.getStatusCode() != 200) {
                Logger.error('Failed to download application document. Status: ' + res.getStatusCode() + ', Response: ' + res.getBody());
                Logger.saveLog();
                throw new AuraHandledException('Failed to download application document. Status: ' + res.getStatusCode());
            }

            return EncodingUtil.base64Encode(res.getBodyAsBlob());
        } catch (Exception e) {
            Logger.error('Error downloading application document: ' + e.getMessage());
            Logger.saveLog();
            throw new AuraHandledException('Error downloading application document: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static AsyncDownloadRequest queueApplicationDocumentDownload(
        String applicationId,
        String documentId,
        String fileName,
        Id recordId
    ) {
        AsyncDownloadRequest request = new AsyncDownloadRequest();
        request.requestToken = String.valueOf(DateTime.now().getTime()) + '-' +
            String.valueOf(Crypto.getRandomLong());
        request.jobId = System.enqueueJob(
            new ApplicationDocumentDownloadQueueable(
                applicationId,
                documentId,
                fileName,
                recordId,
                request.requestToken
            )
        );
        return request;
    }

    @AuraEnabled(cacheable=true)
    public static AsyncDownloadStatus getAsyncDownloadStatus(Id jobId, String requestToken) {
        AsyncApexJob job = [
            SELECT Status, ExtendedStatus
            FROM AsyncApexJob
            WHERE Id = :jobId
            LIMIT 1
        ];

        AsyncDownloadStatus result = new AsyncDownloadStatus();
        result.status = job.Status;
        result.errorMessage = job.Status == 'Failed' ? job.ExtendedStatus : null;

        if (job.Status == 'Completed') {
            List<ContentVersion> versions = [
                SELECT Id
                FROM ContentVersion
                WHERE Description = :ApplicationDocumentDownloadQueueable.getDescription(requestToken)
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
            if (!versions.isEmpty()) {
                result.contentVersionId = versions[0].Id;
            }
        }

        return result;
    }
    
    @AuraEnabled(cacheable=true)
    public static String getZipFiles(String applicationId) {

        Http http = new Http();
        HttpRequest req = new HttpRequest();
        String bearerToken = OAuthTokenService.getBearerToken();

        req.setEndpoint('callout:Applicant_File_Download/' + applicationId + '/documents/download'); 
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/zip');
        req.setHeader('Authorization', 'Bearer ' + bearerToken);
        req.setHeader('X-Acting-User-Email', UserInfo.getUserEmail());
        req.setHeader('X-Acting-User-Id', UserInfo.getUserId());
        req.setHeader('X-Acting-User-Role', 'desnz_caseworker');
        req.setHeader('X-Correlation-ID', String.valueOf(Crypto.getRandomLong()));
        Map<String,String> payload = new Map<String,String>{
            'scope' => 'APPLICATION'
        };
        req.setBody(JSON.serialize(payload));
        
        HttpResponse res = null;
        try {
            res = http.send(req);

            if (res.getStatusCode() != 200) {
                Logger.error('Failed to download zip file. Status: ' + res.getStatusCode() + ', Response: ' + res.getBody());
                Logger.saveLog();
                throw new AuraHandledException('Failed to download zip file. Status: ' + res.getStatusCode());
            }
            System.debug('Received response for zip file download. Status: ' + res.getStatusCode());
            Blob zipBlob = res.getBodyAsBlob();
            Logger.info('Sent request to download zip file. Status: ' + res.getStatusCode());
            Logger.saveLog();
        } catch (Exception e) {
            Logger.error('Error sending request to download zip file: ' + e.getMessage());
            Logger.saveLog();
            throw new AuraHandledException('Error downloading zip file: ' + e.getMessage());
        }

        Blob zipBlob = null;
        zipBlob = res.getBodyAsBlob();

        if (zipBlob == null) {
            Logger.info('Failed to retrieve zip file from the API. Response: ' + res.getBody());
            Logger.saveLog();
            throw new AuraHandledException('Failed to retrieve zip file from the API.');
        }

        return EncodingUtil.base64Encode(zipBlob);
    }

    public class TreeNode {
        @AuraEnabled public String key;
        @AuraEnabled public String name;
        @AuraEnabled public Boolean isFile;
        @AuraEnabled public Id contentDocumentId;
        @AuraEnabled public List<TreeNode> children;
    }

    @AuraEnabled(cacheable=true)
    public static List<TreeNode> extractZipAndBuildTree(String applicationId) {
        try{

            String zipBase64 = getZipFiles(applicationId);
            Blob zipBlob = EncodingUtil.base64Decode(zipBase64);
            Compression.ZipReader zipReader = new Compression.ZipReader(zipBlob);
            List<Compression.ZipEntry> entries = zipReader.getEntries();
            List<TreeNode> nodes = new List<TreeNode>();
            for (Compression.ZipEntry entry : entries) {
                String path = entry.getName();
                Integer lastSlash = path.lastIndexOf('/');
                String folderPath = lastSlash > -1 ? path.substring(0, lastSlash) : '';
                String fileName = lastSlash > -1 ? path.substring(lastSlash+1) : path;
                Blob fileBlob = zipReader.getEntry(entry.getName()).getContent();
                System.debug('logLevel' + fileBlob);
                TreeNode node = new TreeNode();
                node.key = path;
                node.name = fileName;
                node.isFile = true;
                node.children = new List<TreeNode>();
                nodes.add(node);
            }
            return nodes;
        } catch(Exception ex){
            System.debug('Error in extractZipAndBuildTree: ' + ex.getMessage());
            System.debug('Stack trace ' + ex.getStackTraceString());
            throw new AuraHandledException('Error processing ZIP file: ' + ex.getMessage());
        }
    }

}