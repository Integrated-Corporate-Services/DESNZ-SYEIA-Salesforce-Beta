public class DocGen_DocumentGenerationWrapper {
    
    @InvocableMethod(label='Generate Document' description='Creates a DocumentGenerationProcess record and returns its ID')
    public static List<String> generateDocument(List<DocumentGenerationRequest> requests) {
        
        List<String> documentGenerationProcessIds = new List<String>();
        
        if (requests == null || requests.isEmpty()) {
            return documentGenerationProcessIds;
        }
        
        DocumentGenerationRequest request = requests[0];
        
        String documentType = 'Generate';
        String documentStatus = 'InProgress';
        String documentDocGenApiVersionType = 'Advanced';
        
        String requestText =
            '{"keepIntermediate":false,"title":"' +
            request.documentTitle +
            '","templateContentVersionId":"' +
            request.templateContentVersionId +
            '"}';

        String safeTokenData = sanitizeTokenDataForJson(request.tokenData);

        DocumentGenerationProcess documentGenerationProcessToInsert = new DocumentGenerationProcess(
            Type = documentType,
            Status = documentStatus,
            RequestText = requestText,
            ReferenceObject = request.referenceObject,
            TokenData = safeTokenData,
            DocGenApiVersionType = documentDocGenApiVersionType
        );
        
        try {
            insert documentGenerationProcessToInsert;
            Logger.warn('Inserted DocumentGenerationProcess with Id: ' + documentGenerationProcessToInsert.Id);
        }
        catch (Exception e) {
            Logger.error('Error inserting DocumentGenerationProcess: ' + e.getMessage());
            Logger.setScenario('DocGen_DocumentGenerationWrapper.generateDocument');
            Logger.saveLog();
            throw e;
        }
        
        documentGenerationProcessIds.add(documentGenerationProcessToInsert.Id);
        return documentGenerationProcessIds;
    }

    @TestVisible
    private static String sanitizeTokenDataForJson(String tokenData){

        String safeTokenData = tokenData;
        
        if (safeTokenData != null) {

            safeTokenData = safeTokenData
                .replace('\r\n', '\\n')
                .replace('\n', '\\n')
                .replace('\r', '\\n');
            
            Map<String, Object> tokenMap =
                (Map<String, Object>) JSON.deserializeUntyped(safeTokenData);
            
            for (String k : tokenMap.keySet()) {
                
                Object val = tokenMap.get(k);
                
                if (val instanceof String) {
                    String s = (String) val;                    
                    s = s.replace('\\n', '\r\n');
                    tokenMap.put(k, s);
                }
            }            
            safeTokenData = JSON.serialize(tokenMap);
        }
        return safeTokenData;
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