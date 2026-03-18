@isTest
public class OAuthTokenServiceTest {
    
    static void createSalesforceSetting(){
        SalesforceSettings__c settings = new SalesforceSettings__c(
            SetupOwnerId = UserInfo.getOrganizationId(), // KEY LINE
            Endpoint_Url__c = 'https://saas-page-9942--devsyeia2.sandbox.my.salesforce.com/services/oauth2/token',
            client_id__c ='3MVG92ZJW.xbfBW3MVG92ZJW.xbfBW3MVG92ZJW.xbfBW3MVG92ZJW.xbfBW',
            client_secret__c='6A05AF344FD291BD6A05AF344FD291BD6A05AF344FD291BD6A05AF344FD291BD',
            grant_type__c = 'client_credentials'
        );
        insert settings;
    }
    
    // Mock HTTP callout for getAccessToken()
    class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"access_token":"mock_token"}');
            return res;
        }
    }
    
    
    // Mock HTTP callout for getAccessToken()
    class MockHttpResponseGeneratorError implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(403);
            return res;
        }
    }
    
    // ----------------------------
    // Test OAuthTokenService getBearerToken method
    // ----------------------------
    @IsTest
    static void testOAuthTokenService() {
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        createSalesforceSetting();
        String token;
        
        Test.startTest();
        	token = OAuthTokenService.getBearerToken();
        Test.stopTest();
        Assert.isTrue(String.isNOtBlank(token), 'getBearerToken should retrun a token String Value');
        
    }
    
    // ----------------------------
    // Test OAuthTokenService getBearerToken method - Catch Error
    // ----------------------------
    @IsTest
    static void testOAuthTokenServiceCatchError() {
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorError());
        createSalesforceSetting();
        String token;
        
        Test.startTest();
        	token = OAuthTokenService.getBearerToken();
        Test.stopTest();
        Assert.isTrue(String.isBlank(token), 'getBearerToken should retrun a null Value');
        
    } 
    
    // ----------------------------
    // Test OAuthTokenService getBearerToken method - CustomSetting Error
    // ----------------------------
    @IsTest
    static void testOAuthTokenServiceCustomSetting() {
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorError());
        String errorMessage;
        
        Test.startTest();
        try{
        	OAuthTokenService.getBearerToken();
        }
        catch(Exception ex){
        	errorMessage = ex.getMessage();
        }
        Test.stopTest();
        Assert.AreEqual('Missing Salesforce settings', errorMessage, 'getBearerToken should trhow error message');
    } 
}