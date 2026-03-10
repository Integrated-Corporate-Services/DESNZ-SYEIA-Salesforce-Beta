@IsTest
private class DocGen_DocumentGenerationWrapperTest {
  @TestSetup
  static void setupTestData() {
    // Create a test Case__c record
    Case__c testCase = new Case__c(Name = 'Test Case for DocGen');
    insert testCase;

    // Create a ContentVersion for the template
    ContentVersion templateCV = new ContentVersion(
      Title = 'Test Template',
      PathOnClient = 'TestTemplate.docx',
      VersionData = Blob.valueOf('Test Template Content'),
      IsMajorVersion = true
    );
    insert templateCV;
  }

  @IsTest
  static void testGenerateDocumentWithValidInputs() {
    // Get test data
    Case__c testCase = [SELECT Id FROM Case__c LIMIT 1];
    ContentVersion templateCV = [
      SELECT Id, ContentDocumentId
      FROM ContentVersion
      LIMIT 1
    ];

    // Prepare request
    DocGen_DocumentGenerationWrapper.DocumentGenerationRequest request = new DocGen_DocumentGenerationWrapper.DocumentGenerationRequest();
    request.templateContentVersionId = templateCV.Id;
    request.documentTitle = 'Test Generated Document';
    request.referenceObject = testCase.Id;
    request.tokenData = '{"field1":"value1","field2":"value2"}';

    List<DocGen_DocumentGenerationWrapper.DocumentGenerationRequest> requests = new List<DocGen_DocumentGenerationWrapper.DocumentGenerationRequest>{
      request
    };

    Test.startTest();
    List<String> results = DocGen_DocumentGenerationWrapper.generateDocument(
      requests
    );
    Test.stopTest();

    // Verify results
    Assert.isNotNull(results, 'Results should not be null');
    Assert.areEqual(1, results.size(), 'Should return exactly one result');
    Assert.isNotNull(results[0], 'Returned ID should not be null');

    // Verify DocumentGenerationProcess was created correctly
    List<DocumentGenerationProcess> createdProcesses = [
      SELECT
        Id,
        Type,
        Status,
        RequestText,
        ReferenceObject,
        TokenData,
        DocGenApiVersionType
      FROM DocumentGenerationProcess
      WHERE Id = :results[0]
    ];

    Assert.areEqual(
      1,
      createdProcesses.size(),
      'Should have created one DocumentGenerationProcess'
    );

    DocumentGenerationProcess process = createdProcesses[0];
    Assert.areEqual(
      'Generate',
      process.Type,
      'Type should be Generate'
    );
    Assert.areEqual(
      'InProgress',
      process.Status,
      'Status should be InProgress'
    );
    Assert.areEqual(
      testCase.Id,
      process.ReferenceObject,
      'ReferenceObject should match test case ID'
    );
    Assert.areEqual(
      '{"field1":"value1","field2":"value2"}',
      process.TokenData,
      'TokenData should match input'
    );
    Assert.areEqual(
      'Advanced',
      process.DocGenApiVersionType,
      'DocGenApiVersionType should be Advanced'
    );

    // Verify RequestText contains expected values
    Assert.isTrue(
      process.RequestText.contains('"keepIntermediate":false'),
      'RequestText should contain keepIntermediate:false'
    );
    Assert.isTrue(
      process.RequestText.contains('"title":"Test Generated Document"'),
      'RequestText should contain document title'
    );
    Assert.isTrue(
      process.RequestText.contains(
        '"templateContentVersionId":"' + templateCV.Id + '"'
      ),
      'RequestText should contain template content version ID'
    );
  }

  @IsTest
  static void testGenerateDocumentWithNullRequestList() {
    Test.startTest();
    List<String> results = DocGen_DocumentGenerationWrapper.generateDocument(
      null
    );
    Test.stopTest();

    Assert.isNotNull(
      results,
      'Results should not be null even with null input'
    );
    Assert.areEqual(
      0,
      results.size(),
      'Should return empty list for null input'
    );

    // Verify no DocumentGenerationProcess was created
    List<DocumentGenerationProcess> processes = [
      SELECT Id
      FROM DocumentGenerationProcess
    ];
    Assert.areEqual(
      0,
      processes.size(),
      'No DocumentGenerationProcess should be created'
    );
  }

  @IsTest
  static void testGenerateDocumentWithEmptyRequestList() {
    List<DocGen_DocumentGenerationWrapper.DocumentGenerationRequest> emptyRequests = new List<DocGen_DocumentGenerationWrapper.DocumentGenerationRequest>();

    Test.startTest();
    List<String> results = DocGen_DocumentGenerationWrapper.generateDocument(
      emptyRequests
    );
    Test.stopTest();

    Assert.isNotNull(
      results,
      'Results should not be null even with empty input'
    );
    Assert.areEqual(
      0,
      results.size(),
      'Should return empty list for empty input'
    );

    // Verify no DocumentGenerationProcess was created
    List<DocumentGenerationProcess> processes = [
      SELECT Id
      FROM DocumentGenerationProcess
    ];
    Assert.areEqual(
      0,
      processes.size(),
      'No DocumentGenerationProcess should be created'
    );
  }

  @IsTest
  static void testGenerateDocumentWithMultipleRequests() {
    // Get test data
    Case__c testCase = [SELECT Id FROM Case__c LIMIT 1];
    ContentVersion templateCV = [
      SELECT Id, ContentDocumentId
      FROM ContentVersion
      LIMIT 1
    ];

    // Prepare multiple requests (though only first will be processed)
    DocGen_DocumentGenerationWrapper.DocumentGenerationRequest request1 = new DocGen_DocumentGenerationWrapper.DocumentGenerationRequest();
    request1.templateContentVersionId = templateCV.Id;
    request1.documentTitle = 'First Document';
    request1.referenceObject = testCase.Id;
    request1.tokenData = '{"field":"value1"}';

    DocGen_DocumentGenerationWrapper.DocumentGenerationRequest request2 = new DocGen_DocumentGenerationWrapper.DocumentGenerationRequest();
    request2.templateContentVersionId = templateCV.Id;
    request2.documentTitle = 'Second Document';
    request2.referenceObject = testCase.Id;
    request2.tokenData = '{"field":"value2"}';

    List<DocGen_DocumentGenerationWrapper.DocumentGenerationRequest> requests = new List<DocGen_DocumentGenerationWrapper.DocumentGenerationRequest>{
      request1,
      request2
    };

    Test.startTest();
    List<String> results = DocGen_DocumentGenerationWrapper.generateDocument(
      requests
    );
    Test.stopTest();

    // Verify only one result (only first request is processed)
    Assert.areEqual(
      1,
      results.size(),
      'Should return exactly one result even with multiple requests'
    );

    // Verify only one DocumentGenerationProcess was created
    List<DocumentGenerationProcess> processes = [
      SELECT Id, RequestText
      FROM DocumentGenerationProcess
    ];
    Assert.areEqual(
      1,
      processes.size(),
      'Should have created only one DocumentGenerationProcess'
    );

    // Verify it's the first request that was processed
    Assert.isTrue(
      processes[0].RequestText.contains('"title":"First Document"'),
      'Should have processed the first request'
    );
  }

  @IsTest
  static void testGenerateDocumentWithComplexTokenData() {
    // Get test data
    Case__c testCase = [SELECT Id FROM Case__c LIMIT 1];
    ContentVersion templateCV = [
      SELECT Id, ContentDocumentId
      FROM ContentVersion
      LIMIT 1
    ];

    // Prepare request with complex JSON token data
    String complexTokenData =
      '{' +
      '"customer": {"name":"John Doe","email":"john@example.com"},' +
      '"items": [{"product":"Widget","quantity":5},{"product":"Gadget","quantity":3}],' +
      '"total": 150.50' +
      '}';

    DocGen_DocumentGenerationWrapper.DocumentGenerationRequest request = new DocGen_DocumentGenerationWrapper.DocumentGenerationRequest();
    request.templateContentVersionId = templateCV.Id;
    request.documentTitle = 'Complex Token Test';
    request.referenceObject = testCase.Id;
    request.tokenData = complexTokenData;

    List<DocGen_DocumentGenerationWrapper.DocumentGenerationRequest> requests = new List<DocGen_DocumentGenerationWrapper.DocumentGenerationRequest>{
      request
    };

    Test.startTest();
    List<String> results = DocGen_DocumentGenerationWrapper.generateDocument(
      requests
    );
    Test.stopTest();

    // Verify document was created
    Assert.areEqual(
      1,
      results.size(),
      'Should return exactly one result'
    );

    // Verify TokenData was stored correctly
    DocumentGenerationProcess process = [
      SELECT TokenData
      FROM DocumentGenerationProcess
      WHERE Id = :results[0]
    ];

    Assert.areEqual(
      complexTokenData,
      process.TokenData,
      'Complex token data should be stored correctly'
    );
  }

  @IsTest
  static void testGenerateDocumentWithMinimalTokenData() {
    // Get test data
    Case__c testCase = [SELECT Id FROM Case__c LIMIT 1];
    ContentVersion templateCV = [
      SELECT Id, ContentDocumentId
      FROM ContentVersion
      LIMIT 1
    ];

    // Prepare request with minimal token data
    DocGen_DocumentGenerationWrapper.DocumentGenerationRequest request = new DocGen_DocumentGenerationWrapper.DocumentGenerationRequest();
    request.templateContentVersionId = templateCV.Id;
    request.documentTitle = 'Minimal Token Test';
    request.referenceObject = testCase.Id;
    request.tokenData = '{}';

    List<DocGen_DocumentGenerationWrapper.DocumentGenerationRequest> requests = new List<DocGen_DocumentGenerationWrapper.DocumentGenerationRequest>{
      request
    };

    Test.startTest();
    List<String> results = DocGen_DocumentGenerationWrapper.generateDocument(
      requests
    );
    Test.stopTest();

    // Verify document was created
    Assert.areEqual(
      1,
      results.size(),
      'Should return exactly one result'
    );

    // Verify TokenData was stored correctly
    DocumentGenerationProcess process = [
      SELECT TokenData
      FROM DocumentGenerationProcess
      WHERE Id = :results[0]
    ];

    Assert.areEqual(
      '{}',
      process.TokenData,
      'Empty JSON object should be stored correctly'
    );
  }

  @IsTest
  static void testDocumentGenerationRequestClass() {
    // Test that the inner class can be instantiated and properties set
    DocGen_DocumentGenerationWrapper.DocumentGenerationRequest request = new DocGen_DocumentGenerationWrapper.DocumentGenerationRequest();

    String testTemplateId = '068000000000001';
    String testTitle = 'Test Title';
    String testReferenceId = '500000000000001';
    String testTokenData = '{"test":"data"}';

    request.templateContentVersionId = testTemplateId;
    request.documentTitle = testTitle;
    request.referenceObject = testReferenceId;
    request.tokenData = testTokenData;

    Assert.areEqual(
      testTemplateId,
      request.templateContentVersionId,
      'Template ID should be set correctly'
    );
    Assert.areEqual(
      testTitle,
      request.documentTitle,
      'Document title should be set correctly'
    );
    Assert.areEqual(
      testReferenceId,
      request.referenceObject,
      'Reference object should be set correctly'
    );
    Assert.areEqual(
      testTokenData,
      request.tokenData,
      'Token data should be set correctly'
    );
  }

  @IsTest
  static void testGenerateDocumentReturnedIdIsValid() {
    // Get test data
    Case__c testCase = [SELECT Id FROM Case__c LIMIT 1];
    ContentVersion templateCV = [
      SELECT Id, ContentDocumentId
      FROM ContentVersion
      LIMIT 1
    ];

    // Prepare request
    DocGen_DocumentGenerationWrapper.DocumentGenerationRequest request = new DocGen_DocumentGenerationWrapper.DocumentGenerationRequest();
    request.templateContentVersionId = templateCV.Id;
    request.documentTitle = 'ID Validation Test';
    request.referenceObject = testCase.Id;
    request.tokenData = '{"test":"value"}';

    List<DocGen_DocumentGenerationWrapper.DocumentGenerationRequest> requests = new List<DocGen_DocumentGenerationWrapper.DocumentGenerationRequest>{
      request
    };

    Test.startTest();
    List<String> results = DocGen_DocumentGenerationWrapper.generateDocument(
      requests
    );
    Test.stopTest();

    // Verify returned ID is a valid 18-character Salesforce ID
    String returnedId = results[0];
    Assert.isTrue(
      returnedId.length() == 15 || returnedId.length() == 18,
      'Returned ID should be a valid Salesforce ID (15 or 18 chars)'
    );

    // Verify the ID can be used to query the record
    List<DocumentGenerationProcess> processes = [
      SELECT Id
      FROM DocumentGenerationProcess
      WHERE Id = :returnedId
    ];

    Assert.areEqual(
      1,
      processes.size(),
      'Should be able to query using returned ID'
    );
    Assert.areEqual(
      returnedId,
      processes[0].Id,
      'Queried ID should match returned ID'
    );
  }
}