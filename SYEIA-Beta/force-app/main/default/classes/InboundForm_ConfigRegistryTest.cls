/**
 * Test class for InboundForm_ConfigRegistry.
 */
@IsTest
private class InboundForm_ConfigRegistryTest {
    
    // ========================================================================
    // TEST SETUP
    // ========================================================================
    
    @TestSetup
    static void setupTestData() {
        // No test data required - configuration is code-based
    }
    
    // ========================================================================
    // GET CONFIG TESTS
    // ========================================================================
    
    @IsTest
    static void testGetConfig_ValidFormType() {
        // Clear cache to ensure fresh state
        InboundForm_ConfigRegistry.clearCache();
        
        Test.startTest();
        InboundForm_MappingConfig.FormTypeConfig config = 
            InboundForm_ConfigRegistry.getConfig('S37');
        Test.stopTest();
        
        Assert.isNotNull(config, 'Config should not be null for S37 form type');
        Assert.areEqual('S37', config.formType, 'Form type should be S37');
        Assert.isTrue(config.active, 'S37 config should be active');
        Assert.areEqual('Case__c', config.primaryObject, 'Primary object should be Case__c');
    }
    
    @IsTest
    static void testGetConfig_InvalidFormType() {
        InboundForm_ConfigRegistry.clearCache();
        
        Test.startTest();
        InboundForm_MappingConfig.FormTypeConfig config = 
            InboundForm_ConfigRegistry.getConfig('INVALID_TYPE');
        Test.stopTest();
        
        Assert.isNull(config, 'Config should be null for invalid form type');
    }
    
    @IsTest
    static void testGetConfig_NullFormType() {
        InboundForm_ConfigRegistry.clearCache();
        
        Test.startTest();
        InboundForm_MappingConfig.FormTypeConfig config = 
            InboundForm_ConfigRegistry.getConfig(null);
        Test.stopTest();
        
        Assert.isNull(config, 'Config should be null for null form type');
    }
    
    @IsTest
    static void testGetConfig_CacheHit() {
        InboundForm_ConfigRegistry.clearCache();
        
        // First call initializes cache
        InboundForm_MappingConfig.FormTypeConfig config1 = 
            InboundForm_ConfigRegistry.getConfig('S37');
        
        Test.startTest();
        // Second call should hit cache
        InboundForm_MappingConfig.FormTypeConfig config2 = 
            InboundForm_ConfigRegistry.getConfig('S37');
        Test.stopTest();
        
        Assert.isNotNull(config1, 'First config should not be null');
        Assert.isNotNull(config2, 'Second config should not be null');
        Assert.areEqual(config1.formType, config2.formType, 
            'Both configs should have same form type');
    }
    
    // ========================================================================
    // GET REGISTERED FORM TYPES TESTS
    // ========================================================================
    
    @IsTest
    static void testGetRegisteredFormTypes() {
        InboundForm_ConfigRegistry.clearCache();
        
        Test.startTest();
        Set<String> formTypes = InboundForm_ConfigRegistry.getRegisteredFormTypes();
        Test.stopTest();
        
        Assert.isNotNull(formTypes, 'Form types set should not be null');
        Assert.isTrue(formTypes.contains('S37'), 'S37 should be registered');
        Assert.isTrue(formTypes.contains('NWL'), 'NWL should be registered');
        Assert.isTrue(formTypes.contains('S37_WITHDRAWAL_REQUEST'),
            'S37 withdrawal form type should be registered');
        Assert.isTrue(formTypes.contains('NWL_WITHDRAWAL_REQUEST'),
            'NWL withdrawal form type should be registered');
    }
    
    // ========================================================================
    // IS FORM TYPE SUPPORTED TESTS
    // ========================================================================
    
    @IsTest
    static void testIsFormTypeSupported_ValidActive() {
        InboundForm_ConfigRegistry.clearCache();
        
        Test.startTest();
        Boolean isSupported = InboundForm_ConfigRegistry.isFormTypeSupported('S37');
        Test.stopTest();
        
        Assert.isTrue(isSupported, 'S37 should be supported');
        Assert.isTrue(
            InboundForm_ConfigRegistry.isFormTypeSupported('NWL'),
            'NWL form type should be supported'
        );
        Assert.isTrue(
            InboundForm_ConfigRegistry.isFormTypeSupported('S37_WITHDRAWAL_REQUEST'),
            'S37 withdrawal form type should be supported'
        );
        Assert.isTrue(
            InboundForm_ConfigRegistry.isFormTypeSupported('NWL_WITHDRAWAL_REQUEST'),
            'NWL withdrawal form type should be supported'
        );
    }
    
    @IsTest
    static void testIsFormTypeSupported_Invalid() {
        InboundForm_ConfigRegistry.clearCache();
        
        Test.startTest();
        Boolean isSupported = InboundForm_ConfigRegistry.isFormTypeSupported('INVALID');
        Test.stopTest();
        
        Assert.isFalse(isSupported, 'Invalid form type should not be supported');
    }
    
    @IsTest
    static void testIsFormTypeSupported_Null() {
        InboundForm_ConfigRegistry.clearCache();
        
        Test.startTest();
        Boolean isSupported = InboundForm_ConfigRegistry.isFormTypeSupported(null);
        Test.stopTest();
        
        Assert.isFalse(isSupported, 'Null form type should not be supported');
    }
    
    // ========================================================================
    // GET ALL ACTIVE CONFIGS TESTS
    // ========================================================================
    
    @IsTest
    static void testGetAllActiveConfigs() {
        InboundForm_ConfigRegistry.clearCache();
        
        Test.startTest();
        List<InboundForm_MappingConfig.FormTypeConfig> activeConfigs = 
            InboundForm_ConfigRegistry.getAllActiveConfigs();
        Test.stopTest();
        
        Assert.isNotNull(activeConfigs, 'Active configs list should not be null');
        Assert.isFalse(activeConfigs.isEmpty(), 'Should have at least one active config');
        
        // Verify all returned configs are active
        for (InboundForm_MappingConfig.FormTypeConfig config : activeConfigs) {
            Assert.isTrue(config.active, 'All returned configs should be active');
        }
    }
    
    // ========================================================================
    // GET REGISTRY SUMMARY TESTS
    // ========================================================================
    
    @IsTest
    static void testGetRegistrySummary() {
        InboundForm_ConfigRegistry.clearCache();
        
        Test.startTest();
        String summary = InboundForm_ConfigRegistry.getRegistrySummary();
        Test.stopTest();
        
        Assert.isNotNull(summary, 'Summary should not be null');
        Assert.isTrue(summary.contains('Form Type Registry Summary'), 
            'Summary should contain header');
        Assert.isTrue(summary.contains('S37'), 'Summary should contain S37');
        Assert.isTrue(summary.contains('NWL'), 'Summary should contain NWL');
        Assert.isTrue(summary.contains('S37_WITHDRAWAL_REQUEST'),
            'Summary should contain S37 withdrawal form type');
        Assert.isTrue(summary.contains('NWL_WITHDRAWAL_REQUEST'),
            'Summary should contain NWL withdrawal form type');
    }
    
    // ========================================================================
    // CLEAR CACHE TESTS
    // ========================================================================
    
    @IsTest
    static void testClearCache() {
        // Initialize cache
        InboundForm_ConfigRegistry.getConfig('S37');
        
        Test.startTest();
        InboundForm_ConfigRegistry.clearCache();
        // After clear, next call should reinitialize
        InboundForm_MappingConfig.FormTypeConfig config = 
            InboundForm_ConfigRegistry.getConfig('S37');
        Test.stopTest();
        
        Assert.isNotNull(config, 'Config should be available after cache clear');
    }
}