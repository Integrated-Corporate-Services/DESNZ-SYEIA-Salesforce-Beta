public with sharing class FileController {
    
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
                // if (entry.isDirectory()) continue;
                String path = entry.getName();
                Integer lastSlash = path.lastIndexOf('/');
                String folderPath = lastSlash > -1 ? path.substring(0, lastSlash) : '';
                String fileName = lastSlash > -1 ? path.substring(lastSlash+1) : path;
                Blob fileBlob = zipReader.getEntry(entry.getName()).getContent();
                // ContentVersion cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = 'a00Vd00000Ld19sIAB' LIMIT 1];
                System.debug('logLevel' + fileBlob);
                // cv.Title = fileName;
                // cv.PathOnClient = path;
                // cv.VersionData = fileBlob;
                // cv.Description = 'Imported from ZIP path: ' + path;
                // if (recordId != null) {
                    // cv.FirstPublishLocationId = 'a00Vd00000Ld19sIAB';
                // }
                // insert cv;
                TreeNode node = new TreeNode();
                node.key = path;
                node.name = fileName;
                node.isFile = true;
                // node.contentDocumentId = cv.ContentDocumentId;
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