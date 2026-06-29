/**
 * Central registry for all form type configurations. Single entry point to get configuration for any form type.
 */
public class InboundForm_ConfigRegistry {
    
    private static Map<String, InboundForm_MappingConfig.FormTypeConfig> configCache;
    
    /**
     * Get configuration for a specific form type
     */
    public static InboundForm_MappingConfig.FormTypeConfig getConfig(String formType) {
        if (configCache == null) {
            initializeConfigs();
        }
        return configCache.get(formType);
    }
    
    /**
     * Get all registered form types
     */
    public static Set<String> getRegisteredFormTypes() {
        if (configCache == null) {
            initializeConfigs();
        }
        return configCache.keySet();
    }
    
    /**
     * Check if a form type is registered and active
     */
    public static Boolean isFormTypeSupported(String formType) {
        InboundForm_MappingConfig.FormTypeConfig config = getConfig(formType);
        return config != null && config.active;
    }
    
    /**
     * Get all active form type configurations
     */
    public static List<InboundForm_MappingConfig.FormTypeConfig> getAllActiveConfigs() {
        if (configCache == null) {
            initializeConfigs();
        }
        
        List<InboundForm_MappingConfig.FormTypeConfig> activeConfigs = 
            new List<InboundForm_MappingConfig.FormTypeConfig>();
        
        for (InboundForm_MappingConfig.FormTypeConfig config : configCache.values()) {
            if (config.active) {
                activeConfigs.add(config);
            }
        }
        return activeConfigs;
    }
    
    /**
     * Initialize all form type configurations
     */
    private static void initializeConfigs() {
        configCache = new Map<String, InboundForm_MappingConfig.FormTypeConfig>();
        
        // ═══════════════════════════════════════════════════════════
        // REGISTER ALL FORM TYPE CONFIGURATIONS HERE
        // ═══════════════════════════════════════════════════════════
        
        registerConfig(InboundForm_S37Config.getConfig());
        registerConfig(InboundForm_S37WithdrawalConfig.getConfig());
        registerConfig(InboundForm_NWLConfig.getConfig());
        
        // ═══════════════════════════════════════════════════════════
    }
    
    private static void registerConfig(InboundForm_MappingConfig.FormTypeConfig config) {
        if (config != null && String.isNotBlank(config.formType)) {
            configCache.put(config.formType, config);
            System.debug(LoggingLevel.INFO, 
                'Registered form type: ' + config.formType + ' (' + config.description + ')');
        }
    }
    
    /**
     * Clear the configuration cache (useful for testing)
     */
    @TestVisible
    private static void clearCache() {
        configCache = null;
    }
    
    /**
     * Get a summary of all registered form types
     */
    public static String getRegistrySummary() {
        if (configCache == null) {
            initializeConfigs();
        }
        
        List<String> lines = new List<String>{
            'Form Type Registry Summary',
            '==========================='
        };
        
        for (String formType : configCache.keySet()) {
            InboundForm_MappingConfig.FormTypeConfig config = configCache.get(formType);
            lines.add('');
            lines.add('• ' + formType + ' - ' + config.description);
            lines.add('  Primary Object: ' + config.primaryObject);
            lines.add('  Active: ' + config.active);
            lines.add('  Field Mappings: ' + config.fieldMappings.size());
            lines.add('  Collections: ' + config.collections.size());
        }
        
        return String.join(lines, '\n');
    }
}