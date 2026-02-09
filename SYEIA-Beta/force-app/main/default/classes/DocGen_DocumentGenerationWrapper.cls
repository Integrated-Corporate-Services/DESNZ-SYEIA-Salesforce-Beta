/**
 * Invocable action for generating documents via Salesforce Document Generation.
 * Creates DocumentGenerationProcess records for use with OmniStudio Document Generation.
 */
public without sharing class DocGen_DocumentGenerationWrapper {
    
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
            DocGenApiVersionType = documentDocGenApiVersionType
        );
        
        insert documentGenerationProcessToInsert;
        
        documentGenerationProcessIds.add(documentGenerationProcessToInsert.Id);
        
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