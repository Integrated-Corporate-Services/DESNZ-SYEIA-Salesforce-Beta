public class DocGen_DocumentGenerationWrapper {
    
    @InvocableMethod(label='Generate Document' description='Creates a DocumentGenerationProcess record and returns its ID')
    public static List<String> generateDocument(List<DocumentGenerationRequest> requests) {
        List<String> documentGenerationProcessIds = new List<String>();
        
        if (requests == null || requests.isEmpty()) {
            return documentGenerationProcessIds;
        }
        
        DocumentGenerationRequest request = requests[0];
        
        String documentType = 'GenerateAndConvert';
        String documentStatus = 'InProgress';
        String documentDocGenApiVersionType = 'Advanced';
        
        String requestText = '{"keepIntermediate":false,"title":"' + request.documentTitle + '","templateContentVersionId":"' + request.templateContentVersionId + '"}';
        
        DocumentGenerationProcess documentGenerationProcessToInsert = new DocumentGenerationProcess(
            Type = documentType,
            Status = documentStatus,
            RequestText = requestText,
            ReferenceObject = request.referenceObject,
            TokenData = request.tokenData,
            // TokenData = '{}',
            DocGenApiVersionType = documentDocGenApiVersionType
        );

        try{
            System.debug('DocumentGenerationProcess to insert: ' + documentGenerationProcessToInsert);
        
            insert documentGenerationProcessToInsert;

            System.debug('DocumentGenerationProcess created: ' + documentGenerationProcessToInsert);
            List<DocumentGenerationProcess> dgpRecordList = [
                SELECT Id, Type, Status, RequestText, ReferenceObject, TokenData, DocGenApiVersionType 
                FROM DocumentGenerationProcess 
                WHERE Id = :documentGenerationProcessToInsert.Id
            ];
            System.debug('Retrieved DocumentGenerationProcess: ' + dgpRecordList);

            if (!dgpRecordList.isEmpty()) {
                Id documentGenerationProcessId = dgpRecordList[0].Id;
                documentGenerationProcessIds.add(documentGenerationProcessId);
                return documentGenerationProcessIds;
            } 
            // else {
            //     System.debug('No DocumentGenerationProcess record found after insertion.');
            //     throw new AuraHandledException('Failed to create DocumentGenerationProcess record.');
            // }
        } catch(Exception e){
            System.debug('Error occurred: ' + e.getMessage());
            System.debug('Stack Trace: ' + e.getStackTraceString());
            throw new AuraHandledException('Error preparing DocumentGenerationProcess: ' + e.getMessage()); 
        }
        return documentGenerationProcessIds;
        
    }
    
    public class DocumentGenerationRequest {
        @InvocableVariable(label='Template Content Version ID' required=true)
        public String templateContentVersionId;
        
        @InvocableVariable(label='Document Title' required=true)
        public String documentTitle;
        
        @InvocableVariable(label='Reference Object' description='The record Id to attach the newly generated file.' required=true)
        public String referenceObject;
        
        @InvocableVariable(label='Token Data' description='The JSON object containing any merge data.' required=true)
        public String tokenData;
    }
}