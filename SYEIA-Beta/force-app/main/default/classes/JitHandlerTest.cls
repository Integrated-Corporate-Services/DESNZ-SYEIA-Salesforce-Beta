/**
 * Test class for JitHandler
 */
@isTest
private class JitHandlerTest {
    
    private static final String TEST_FEDERATION_ID = 'test.user@example.gov.uk.testorg';
    private static final String TEST_PROFILE_NAME = 'Base Employee';
    
    /**
     * Test successful user creation
     */
    @isTest
    static void testCreateUser_Success() {
        JitHandler handler = new JitHandler();
        
        Map<String, String> attributes = new Map<String, String>();
        String assertion = 'test-assertion';
        
        Test.startTest();
        User newUser = handler.createUser(
            null,                   // samlSsoProviderId
            null,                   // communityId
            null,                   // portalId
            TEST_FEDERATION_ID,     // federationIdentifier
            attributes,             // attributes
            assertion               // assertion
        );
        Test.stopTest();
        
        // Verify user fields
        Assert.isNotNull(newUser, 'User should not be null');
        Assert.areEqual(TEST_FEDERATION_ID, newUser.FederationIdentifier, 'FederationIdentifier should match');
        Assert.areEqual(TEST_FEDERATION_ID, newUser.Username, 'Username should match federationIdentifier');
        Assert.areEqual(TEST_FEDERATION_ID, newUser.Email, 'Email should match federationIdentifier');
        Assert.areEqual('Test', newUser.FirstName, 'FirstName should be default value');
        Assert.areEqual('User', newUser.LastName, 'LastName should be default value');
        Assert.areEqual('tuser', newUser.Alias, 'Alias should be generated correctly');
        Assert.areEqual('Europe/London', newUser.TimeZoneSidKey, 'TimeZone should be UK');
        Assert.areEqual('en_GB', newUser.LocaleSidKey, 'Locale should be UK');
        Assert.isTrue(newUser.IsActive, 'User should be active');
        Assert.isNotNull(newUser.ProfileId, 'ProfileId should be set');
    }
    
    /**
     * Test user creation with blank federation identifier throws exception
     */
    @isTest
    static void testCreateUser_BlankFederationId_ThrowsException() {
        JitHandler handler = new JitHandler();
        
        Map<String, String> attributes = new Map<String, String>();
        String assertion = 'test-assertion';
        
        Test.startTest();
        try {
            handler.createUser(
                null,           // samlSsoProviderId
                null,           // communityId
                null,           // portalId
                '',             // blank federationIdentifier
                attributes,     // attributes
                assertion       // assertion
            );
            Assert.fail('Expected JitException to be thrown');
        } catch (JitHandler.JitException e) {
            Assert.areEqual('Federation Identifier is required for user creation.', e.getMessage(), 'Exception message should match');
        }
        Test.stopTest();
    }
    
    /**
     * Test user creation with null federation identifier throws exception
     */
    @isTest
    static void testCreateUser_NullFederationId_ThrowsException() {
        JitHandler handler = new JitHandler();
        
        Map<String, String> attributes = new Map<String, String>();
        String assertion = 'test-assertion';
        
        Test.startTest();
        try {
            handler.createUser(
                null,           // samlSsoProviderId
                null,           // communityId
                null,           // portalId
                null,           // null federationIdentifier
                attributes,     // attributes
                assertion       // assertion
            );
            Assert.fail('Expected JitException to be thrown');
        } catch (JitHandler.JitException e) {
            Assert.areEqual('Federation Identifier is required for user creation.', e.getMessage(), 'Exception message should match');
        }
        Test.stopTest();
    }
    
    /**
     * Test successful user update
     */
    @isTest
    static void testUpdateUser_Success() {
        // Create test user
        User testUser = createTestUser();
        insert testUser;
        
        JitHandler handler = new JitHandler();
        Map<String, String> attributes = new Map<String, String>();
        String assertion = 'test-assertion';
        String newFederationId = 'updated.user@example.gov.uk.testorg';
        
        Test.startTest();
        handler.updateUser(
            testUser.Id,            // userId
            null,                   // samlSsoProviderId
            null,                   // communityId
            null,                   // portalId
            newFederationId,        // federationIdentifier
            attributes,             // attributes
            assertion               // assertion
        );
        Test.stopTest();
        
        // Verify user was updated
        User updatedUser = [SELECT Id, FederationIdentifier, IsActive FROM User WHERE Id = :testUser.Id];
        Assert.areEqual(newFederationId, updatedUser.FederationIdentifier, 'FederationIdentifier should be updated');
        Assert.isTrue(updatedUser.IsActive, 'User should be active');
    }
    
    /**
     * Test update reactivates inactive user
     */
    @isTest
    static void testUpdateUser_ReactivatesInactiveUser() {
        // Create and deactivate test user
        User testUser = createTestUser();
        insert testUser;
        
        testUser.IsActive = false;
        update testUser;
        
        // Verify user is inactive
        User inactiveUser = [SELECT IsActive FROM User WHERE Id = :testUser.Id];
        Assert.isFalse(inactiveUser.IsActive, 'User should be inactive before test');
        
        JitHandler handler = new JitHandler();
        Map<String, String> attributes = new Map<String, String>();
        String assertion = 'test-assertion';
        
        Test.startTest();
        handler.updateUser(
            testUser.Id,            // userId
            null,                   // samlSsoProviderId
            null,                   // communityId
            null,                   // portalId
            TEST_FEDERATION_ID,     // federationIdentifier
            attributes,             // attributes
            assertion               // assertion
        );
        Test.stopTest();
        
        // Verify user was reactivated
        User reactivatedUser = [SELECT IsActive FROM User WHERE Id = :testUser.Id];
        Assert.isTrue(reactivatedUser.IsActive, 'User should be reactivated');
    }
    
    /**
     * Test update with null userId throws exception
     */
    @isTest
    static void testUpdateUser_NullUserId_ThrowsException() {
        JitHandler handler = new JitHandler();
        Map<String, String> attributes = new Map<String, String>();
        String assertion = 'test-assertion';
        
        Test.startTest();
        try {
            handler.updateUser(
                null,               // null userId
                null,               // samlSsoProviderId
                null,               // communityId
                null,               // portalId
                TEST_FEDERATION_ID, // federationIdentifier
                attributes,         // attributes
                assertion           // assertion
            );
            Assert.fail('Expected JitException to be thrown');
        } catch (JitHandler.JitException e) {
            Assert.areEqual('User Id is required for user update.', e.getMessage(), 'Exception message should match');
        }
        Test.stopTest();
    }
    
    /**
     * Test update does not change federation identifier if same value
     */
    @isTest
    static void testUpdateUser_SameFederationId_NoChange() {
        // Create test user with specific federation ID
        User testUser = createTestUser();
        testUser.FederationIdentifier = TEST_FEDERATION_ID;
        insert testUser;
        
        JitHandler handler = new JitHandler();
        Map<String, String> attributes = new Map<String, String>();
        String assertion = 'test-assertion';
        
        Test.startTest();
        handler.updateUser(
            testUser.Id,            // userId
            null,                   // samlSsoProviderId
            null,                   // communityId
            null,                   // portalId
            TEST_FEDERATION_ID,     // same federationIdentifier
            attributes,             // attributes
            assertion               // assertion
        );
        Test.stopTest();
        
        // Verify federation ID unchanged
        User updatedUser = [SELECT FederationIdentifier FROM User WHERE Id = :testUser.Id];
        Assert.areEqual(TEST_FEDERATION_ID, updatedUser.FederationIdentifier, 'FederationIdentifier should remain unchanged');
    }
    
    /**
     * Test update FirstName when attribute value is different
     */
    @isTest
    static void testUpdateUser_FirstName_UpdatesWhenDifferent() {
        User testUser = createTestUser();
        testUser.FirstName = 'Original';
        insert testUser;
        
        JitHandler handler = new JitHandler();
        Map<String, String> attributes = new Map<String, String>{
            'Firstname' => 'Updated'
        };
        String assertion = 'test-assertion';
        
        Test.startTest();
        handler.updateUser(
            testUser.Id,
            null,
            null,
            null,
            testUser.FederationIdentifier,
            attributes,
            assertion
        );
        Test.stopTest();
        
        User updatedUser = [SELECT FirstName FROM User WHERE Id = :testUser.Id];
        Assert.areEqual('Updated', updatedUser.FirstName, 'FirstName should be updated to new value');
    }
    
    /**
     * Test update FirstName when attribute value is the same (no update needed)
     */
    @isTest
    static void testUpdateUser_FirstName_NoChangeWhenSame() {
        User testUser = createTestUser();
        testUser.FirstName = 'SameName';
        insert testUser;
        
        JitHandler handler = new JitHandler();
        Map<String, String> attributes = new Map<String, String>{
            'Firstname' => 'SameName'
        };
        String assertion = 'test-assertion';
        
        Test.startTest();
        handler.updateUser(
            testUser.Id,
            null,
            null,
            null,
            testUser.FederationIdentifier,
            attributes,
            assertion
        );
        Test.stopTest();
        
        User updatedUser = [SELECT FirstName FROM User WHERE Id = :testUser.Id];
        Assert.areEqual('SameName', updatedUser.FirstName, 'FirstName should remain unchanged');
    }
    
    /**
     * Test update LastName when attribute value is different
     */
    @isTest
    static void testUpdateUser_LastName_UpdatesWhenDifferent() {
        User testUser = createTestUser();
        testUser.LastName = 'OriginalLast';
        insert testUser;
        
        JitHandler handler = new JitHandler();
        Map<String, String> attributes = new Map<String, String>{
            'Lastname' => 'UpdatedLast'
        };
        String assertion = 'test-assertion';
        
        Test.startTest();
        handler.updateUser(
            testUser.Id,
            null,
            null,
            null,
            testUser.FederationIdentifier,
            attributes,
            assertion
        );
        Test.stopTest();
        
        User updatedUser = [SELECT LastName FROM User WHERE Id = :testUser.Id];
        Assert.areEqual('UpdatedLast', updatedUser.LastName, 'LastName should be updated to new value');
    }
    
    /**
     * Test update LastName when attribute value is the same (no update needed)
     */
    @isTest
    static void testUpdateUser_LastName_NoChangeWhenSame() {
        User testUser = createTestUser();
        testUser.LastName = 'SameLastName';
        insert testUser;
        
        JitHandler handler = new JitHandler();
        Map<String, String> attributes = new Map<String, String>{
            'Lastname' => 'SameLastName'
        };
        String assertion = 'test-assertion';
        
        Test.startTest();
        handler.updateUser(
            testUser.Id,
            null,
            null,
            null,
            testUser.FederationIdentifier,
            attributes,
            assertion
        );
        Test.stopTest();
        
        User updatedUser = [SELECT LastName FROM User WHERE Id = :testUser.Id];
        Assert.areEqual('SameLastName', updatedUser.LastName, 'LastName should remain unchanged');
    }
    
    /**
     * Test update Title when attribute value is different
     */
    @isTest
    static void testUpdateUser_Title_UpdatesWhenDifferent() {
        User testUser = createTestUser();
        testUser.Title = 'Original Title';
        insert testUser;
        
        JitHandler handler = new JitHandler();
        Map<String, String> attributes = new Map<String, String>{
            'Title' => 'Senior Manager'
        };
        String assertion = 'test-assertion';
        
        Test.startTest();
        handler.updateUser(
            testUser.Id,
            null,
            null,
            null,
            testUser.FederationIdentifier,
            attributes,
            assertion
        );
        Test.stopTest();
        
        User updatedUser = [SELECT Title FROM User WHERE Id = :testUser.Id];
        Assert.areEqual('Senior Manager', updatedUser.Title, 'Title should be updated to new value');
    }
    
    /**
     * Test update Title when attribute value is the same (no update needed)
     */
    @isTest
    static void testUpdateUser_Title_NoChangeWhenSame() {
        User testUser = createTestUser();
        testUser.Title = 'Same Title';
        insert testUser;
        
        JitHandler handler = new JitHandler();
        Map<String, String> attributes = new Map<String, String>{
            'Title' => 'Same Title'
        };
        String assertion = 'test-assertion';
        
        Test.startTest();
        handler.updateUser(
            testUser.Id,
            null,
            null,
            null,
            testUser.FederationIdentifier,
            attributes,
            assertion
        );
        Test.stopTest();
        
        User updatedUser = [SELECT Title FROM User WHERE Id = :testUser.Id];
        Assert.areEqual('Same Title', updatedUser.Title, 'Title should remain unchanged');
    }
    
    /**
     * Test update Title from null to a value
     */
    @isTest
    static void testUpdateUser_Title_UpdatesFromNull() {
        User testUser = createTestUser();
        testUser.Title = null;
        insert testUser;
        
        JitHandler handler = new JitHandler();
        Map<String, String> attributes = new Map<String, String>{
            'Title' => 'New Title'
        };
        String assertion = 'test-assertion';
        
        Test.startTest();
        handler.updateUser(
            testUser.Id,
            null,
            null,
            null,
            testUser.FederationIdentifier,
            attributes,
            assertion
        );
        Test.stopTest();
        
        User updatedUser = [SELECT Title FROM User WHERE Id = :testUser.Id];
        Assert.areEqual('New Title', updatedUser.Title, 'Title should be updated from null');
    }
    
    /**
     * Test update multiple attributes at once
     */
    @isTest
    static void testUpdateUser_MultipleAttributes_AllUpdated() {
        User testUser = createTestUser();
        testUser.FirstName = 'OldFirst';
        testUser.LastName = 'OldLast';
        testUser.Title = 'Old Title';
        insert testUser;
        
        JitHandler handler = new JitHandler();
        Map<String, String> attributes = new Map<String, String>{
            'Firstname' => 'NewFirst',
            'Lastname' => 'NewLast',
            'Title' => 'New Title'
        };
        String assertion = 'test-assertion';
        
        Test.startTest();
        handler.updateUser(
            testUser.Id,
            null,
            null,
            null,
            testUser.FederationIdentifier,
            attributes,
            assertion
        );
        Test.stopTest();
        
        User updatedUser = [SELECT FirstName, LastName, Title FROM User WHERE Id = :testUser.Id];
        Assert.areEqual('NewFirst', updatedUser.FirstName, 'FirstName should be updated');
        Assert.areEqual('NewLast', updatedUser.LastName, 'LastName should be updated');
        Assert.areEqual('New Title', updatedUser.Title, 'Title should be updated');
    }
    
    /**
     * Helper method to create a test user
     */
    private static User createTestUser() {
        Profile p = [SELECT Id FROM Profile WHERE Name = :TEST_PROFILE_NAME LIMIT 1];
        
        String uniqueKey = String.valueOf(Datetime.now().getTime());
        
        return new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser' + uniqueKey + '@example.com',
            Username = 'testuser' + uniqueKey + '@example.com.test',
            Alias = 'tuser',
            FederationIdentifier = 'test.fed.id.' + uniqueKey,
            TimeZoneSidKey = 'Europe/London',
            LocaleSidKey = 'en_GB',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id,
            IsActive = true
        );
    }
}