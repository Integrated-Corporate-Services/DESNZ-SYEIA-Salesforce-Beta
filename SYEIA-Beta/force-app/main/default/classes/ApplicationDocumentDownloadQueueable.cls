public class ApplicationDocumentDownloadQueueable implements Queueable, Database.AllowsCallouts {
    private String applicationId;
    private String documentId;
    private String fileName;
    private Id recordId;
    private String requestToken;

    public ApplicationDocumentDownloadQueueable(
        String applicationId,
        String documentId,
        String fileName,
        Id recordId,
        String requestToken
    ) {
        this.applicationId = applicationId;
        this.documentId = documentId;
        this.fileName = fileName;
        this.recordId = recordId;
        this.requestToken = requestToken;
    }

    public void execute(QueueableContext context) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Applicant_File_Download/' + applicationId + '/documents/download');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/zip');
        req.setHeader('Authorization', 'Bearer ' + OAuthTokenService.getBearerToken());
        req.setHeader('X-Acting-User-Email', UserInfo.getUserEmail());
        req.setHeader('X-Acting-User-Id', UserInfo.getUserId());
        req.setHeader('X-Acting-User-Role', 'desnz_caseworker');
        req.setHeader('X-Correlation-ID', String.valueOf(Crypto.getRandomLong()));
        req.setBody(JSON.serialize(new Map<String, Object>{
            'scope' => 'SELECTION',
            'documentIds' => new List<String>{ documentId }
        }));

        HttpResponse res = new Http().send(req);
        if (res.getStatusCode() != 200) {
            throw new CalloutException(
                'Failed to download application document. Status: ' + res.getStatusCode()
            );
        }

        ContentVersion version = new ContentVersion(
            Title = fileName,
            PathOnClient = fileName + '.zip',
            VersionData = res.getBodyAsBlob(),
            Description = getDescription(requestToken)
        );
        if (recordId != null) {
            version.FirstPublishLocationId = recordId;
        }
        insert version;
    }

    public static String getDescription(String requestToken) {
        return 'Async application document download: ' + requestToken;
    }
}