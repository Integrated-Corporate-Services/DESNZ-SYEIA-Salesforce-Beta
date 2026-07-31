/**
 * Core processor for inbound form requests. Reads configuration from InboundForm_ConfigRegistry and 
 * creates Salesforce records based on JSON payloads.
 */
public with sharing class InboundForm_Processor {
    private static final String WITHDRAWAL_EVENT_TYPE = 'WITHDRAWAL_REQUESTED';
    private static final String S37_FORM_TYPE = 'S37';
    private static final String S37_WITHDRAWAL_FORM_TYPE = 'S37_WITHDRAWAL_REQUEST';
    
    // Schema cache to avoid repeated getGlobalDescribe calls
    private static Map<String, Schema.SObjectType> sObjectTypeCache = 
        new Map<String, Schema.SObjectType>();
    private static Map<String, Map<String, Id>> recordTypeCache = 
        new Map<String, Map<String, Id>>();
    private static Boolean schemaCacheInitialized = false;
    
    // Maximum field length for error log
    private static final Integer MAX_ERROR_LOG_LENGTH = 131072;
    
    // Handler cache to avoid multiple instantiations per request
    private static Map<String, IFormHandler> handlerCache = new Map<String, IFormHandler>();
    
    /**
     * Process a list of Inbound Request records
     */
    public static Map<Id, ProcessingResult> processRequests(List<Inbound_Request__c> requests) {
        Map<Id, ProcessingResult> results = new Map<Id, ProcessingResult>();
        
        // Clear handler cache at start of each batch
        handlerCache.clear();
        
        // Initialize schema cache once
        initializeSchemaCache();
        
        // Phase 1: Parse, validate, and build records for each request
        for (Inbound_Request__c req : requests) {
            ProcessingResult result = processRequest(req);
            results.put(req.Id, result);
        }
        
        // Phase 2: Commit successful records (consolidated DML)
        commitAllRecords(results);
        
        // Phase 3: Queue status updates asynchronously
        queueStatusUpdates(results);
        
        return results;
    }
    
    /**
     * Initialize schema cache for all registered objects
     */
    private static void initializeSchemaCache() {
        if (schemaCacheInitialized) return;
        
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        
        // Cache SObjectTypes for all configured objects
        for (InboundForm_MappingConfig.FormTypeConfig config : 
                InboundForm_ConfigRegistry.getAllActiveConfigs()) {
            
            cacheSObjectType(config.primaryObject, globalDescribe);
            
            for (InboundForm_MappingConfig.CollectionConfig coll : config.collections) {
                cacheSObjectType(coll.targetObject, globalDescribe);
            }
        }
        
        schemaCacheInitialized = true;
    }
    
    private static void cacheSObjectType(String objectName, 
                                          Map<String, Schema.SObjectType> globalDescribe) {
        if (String.isNotBlank(objectName) && !sObjectTypeCache.containsKey(objectName)) {
            Schema.SObjectType sObjType = globalDescribe.get(objectName);
            if (sObjType != null) {
                sObjectTypeCache.put(objectName, sObjType);
                
                // Also cache record types
                Map<String, Id> rtMap = new Map<String, Id>();
                for (Schema.RecordTypeInfo rti : 
                        sObjType.getDescribe().getRecordTypeInfosByDeveloperName().values()) {
                    rtMap.put(rti.getDeveloperName(), rti.getRecordTypeId());
                }
                recordTypeCache.put(objectName, rtMap);
            }
        }
    }
    
    /**
     * Get or create cached handler instance for a form type
     */
    private static IFormHandler getHandler(InboundForm_MappingConfig.FormTypeConfig config) {
        if (config.handlerClass == null) {
            return null;
        }
        
        String handlerKey = config.formType;
        if (!handlerCache.containsKey(handlerKey)) {
            try {
                IFormHandler handler = (IFormHandler) config.handlerClass.newInstance();
                handlerCache.put(handlerKey, handler);
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Failed to instantiate handler for ' + 
                    config.formType + ': ' + e.getMessage());
                Logger.error('Failed to instantiate handler for ' + config.formType + ': ' + e.getMessage());
                Logger.setScenario('InboundForm_Processor.getHandler');
                Logger.saveLog();
                return null;
            }
        }
        return handlerCache.get(handlerKey);
    }
    
    /**
     * Process a single Inbound Request
     */
    private static ProcessingResult processRequest(Inbound_Request__c req) {
        ProcessingResult result = new ProcessingResult(req.Id);
        
        if (String.isBlank(req.Payload__c)) {
            result.addError('Payload is empty');
            return result;
        }
        
        try {
            // Parse JSON
            InboundForm_JSONParser parser = new InboundForm_JSONParser(req.Payload__c);
            
            // Store parser in result for use in afterPrimaryInsert hook
            result.parser = parser;
            
            // Get configured form type (may be derived from event type)
            String payloadFormType = parser.getString('formType');
            if (String.isBlank(payloadFormType)) {
                result.addError('formType not found in payload');
                return result;
            }

            String formType = resolveConfiguredFormType(parser, payloadFormType);
            
            // Get configuration
            InboundForm_MappingConfig.FormTypeConfig formConfig = 
                InboundForm_ConfigRegistry.getConfig(formType);
            
            if (formConfig == null) {
                result.addError('No configuration found for form type: ' + formType + 
                    '. Registered types: ' + InboundForm_ConfigRegistry.getRegisteredFormTypes());
                return result;
            }
            
            if (!formConfig.active) {
                result.addError('Form type is not active: ' + formType);
                return result;
            }
            
            result.formType = formType;
            result.formConfig = formConfig;
            
            // Get cached handler instance (FIX: handler now cached, not instantiated twice)
            IFormHandler handler = getHandler(formConfig);
            
            // Run validation BEFORE building records
            if (handler != null) {
                List<String> validationErrors = handler.validate(parser);
                if (!validationErrors.isEmpty()) {
                    for (String error : validationErrors) {
                        result.addError(error);
                    }
                    return result; // Exit early - don't build records
                }
            }
            
            // Build primary record
            SObject primaryRecord = buildPrimaryRecord(parser, formConfig, req, result);
            if (primaryRecord != null && result.success) {
                result.addRecords(formConfig.primaryObject, new List<SObject>{ primaryRecord });
            }
            
            // Build child records from collections
            if (result.success) {
                buildChildRecords(parser, formConfig, result);
            }
            
            // Run post-build handler (using cached handler)
            if (result.success && handler != null) {
                try {
                    handler.afterBuild(parser, result.createdRecords);
                } catch (Exception e) {
                    Logger.error('Error in afterBuild handler: ' + e.getMessage());
                    Logger.setScenario('InboundForm_Processor.afterBuild');
                    Logger.saveLog();
                    result.addWarning('After-build handler error: ' + e.getMessage());
                    System.debug(LoggingLevel.WARN, 'After-build handler error: ' + e.getMessage());
                }
            }
            
        } catch (Exception e) {
            Logger.error('Error processing request: ' + e.getMessage());
            Logger.setScenario('InboundForm_Processor.processRequest');
            result.addError('Processing error: ' + e.getMessage() + 
                ' [Line: ' + e.getLineNumber() + ']');
        }
        finally{
            Logger.saveLog();
        }
        
        return result;
    }

    /**
     * Resolve inbound payload into a configured form type key.
     * S37 withdrawal events are processed by a dedicated withdrawal config.
     */
    private static String resolveConfiguredFormType(InboundForm_JSONParser parser, String payloadFormType) {
        if (isS37WithdrawalPayload(parser, payloadFormType)) {
            return S37_WITHDRAWAL_FORM_TYPE;
        }
        return payloadFormType;
    }

    private static Boolean isS37WithdrawalPayload(InboundForm_JSONParser parser, String payloadFormType) {
        if (payloadFormType == S37_WITHDRAWAL_FORM_TYPE) {
            return true;
        }

        if (payloadFormType != S37_FORM_TYPE) {
            return false;
        }

        String eventType = parser.getString('eventType');
        if (isWithdrawalRequestedEvent(eventType)) {
            return true;
        }

        return parser.hasValue('Withdraw') || parser.hasValue('Withdraw.withdrawalReason');
    }

    private static Boolean isWithdrawalRequestedEvent(String eventType) {
        if (String.isBlank(eventType)) {
            return false;
        }

        String normalizedEventType = eventType
            .toUpperCase()
            .replace('_', '')
            .replace('-', '')
            .replace(' ', '');

        return normalizedEventType == 'WITHDRAWALREQUESTED' ||
            normalizedEventType == 'WITHDRAWALREQUEST' ||
            normalizedEventType == WITHDRAWAL_EVENT_TYPE.replace('_', '');
    }
    
    /**
     * Build the primary record
     */
    private static SObject buildPrimaryRecord(InboundForm_JSONParser parser, 
                                               InboundForm_MappingConfig.FormTypeConfig config,
                                               Inbound_Request__c req,
                                               ProcessingResult result) {
        try {
            SObject record = createSObjectInstance(config.primaryObject);
            if (record == null) {
                result.addError('Cannot create instance of: ' + config.primaryObject);
                return null;
            }
            
            // Set record type
            if (String.isNotBlank(config.primaryRecordType)) {
                Id rtId = getRecordTypeId(config.primaryObject, config.primaryRecordType);
                if (rtId != null) {
                    record.put('RecordTypeId', rtId);
                }
            }
            
            // Set Inbound Request lookup
            if (String.isNotBlank(config.inboundRequestLookupField)) {
                record.put(config.inboundRequestLookupField, req.Id);
            }
            
            // Set Application ID
            if (String.isNotBlank(config.applicationIdField)) {
                String appId = parser.getString(config.applicationIdJsonPath);
                if (String.isNotBlank(appId)) {
                    record.put(config.applicationIdField, appId);
                }
            }
            
            // Set Name
            if (String.isNotBlank(config.nameField)) {
                String namePath = String.isNotBlank(config.nameJsonPath) 
                    ? config.nameJsonPath : config.applicationIdJsonPath;
                String name = parser.getString(namePath);
                if (String.isNotBlank(name)) {
                    record.put(config.nameField, name);
                }
            }
            
            // Set default status
            if (String.isNotBlank(config.statusField) && String.isNotBlank(config.defaultStatus)) {
                record.put(config.statusField, config.defaultStatus);
            }
            
            // Apply field mappings (using Map directly for efficiency)
            applyFieldMappings(record, parser.getRootMap(), config.fieldMappings, result);
            
            return record;
            
        } catch (Exception e) {
            Logger.error('Error building primary record: ' + e.getMessage());
            Logger.setScenario('InboundForm_Processor.buildPrimaryRecord');
            Logger.saveLog();
            result.addError('Error building primary record: ' + e.getMessage());
            return null;
        }
    }
    
    /**
     * Build all child records based on collection configurations
     */
    private static void buildChildRecords(InboundForm_JSONParser parser, 
                                           InboundForm_MappingConfig.FormTypeConfig config,
                                           ProcessingResult result) {
        List<InboundForm_MappingConfig.CollectionConfig> sortedCollections = 
            new List<InboundForm_MappingConfig.CollectionConfig>(config.collections);
        sortedCollections.sort();
        
        for (InboundForm_MappingConfig.CollectionConfig collConfig : sortedCollections) {
            try {
                List<SObject> records = buildCollectionRecords(parser, collConfig, result);
                if (!records.isEmpty()) {
                    result.addRecords(collConfig.targetObject, records);
                    result.collectionRecords.put(collConfig.collectionName, records);
                }
            } catch (Exception e) {
                result.addWarning('Error processing collection ' + collConfig.collectionName + 
                    ': ' + e.getMessage());
                Logger.error('Error processing collection ' + collConfig.collectionName + ': ' + e.getMessage());
                Logger.setScenario('InboundForm_Processor.buildChildRecords');
                Logger.saveLog();
            }
        }
    }
    
    /**
     * Build records from a single collection
     * OPTIMIZED: Reduced object creation by working with Maps directly
     */
    private static List<SObject> buildCollectionRecords(
            InboundForm_JSONParser parser,
            InboundForm_MappingConfig.CollectionConfig collConfig,
            ProcessingResult result) {
        
        List<SObject> records = new List<SObject>();
        
        // Handle simple arrays (array of strings)
        if (collConfig.isSimpleArray) {
            List<Object> simpleItems = parser.getList(collConfig.jsonPath);
            for (Object item : simpleItems) {
                if (item != null) {
                    SObject record = createSObjectInstance(collConfig.targetObject);
                    if (record != null) {
                        applyRecordType(record, collConfig);
                        record.put(collConfig.simpleArrayTargetField, String.valueOf(item));
                        records.add(record);
                    }
                }
            }
            return records;
        }
        
        // Handle nested arrays
        if (collConfig.isNestedArray) {
            return buildNestedCollectionRecords(parser, collConfig, result);
        }
        
        // Handle standard object arrays - OPTIMIZED: work with Maps directly
        List<Map<String, Object>> items = parser.getObjectList(collConfig.jsonPath);
        
        for (Map<String, Object> item : items) {
            SObject record = createSObjectInstance(collConfig.targetObject);
            
            if (record != null) {
                applyRecordType(record, collConfig);
                
                // Store link field for parent-child linking
                if (String.isNotBlank(collConfig.childLinkSfField) && 
                    String.isNotBlank(collConfig.parentLinkJsonField)) {
                    Object linkObj = item.get(collConfig.parentLinkJsonField);
                    String linkValue = linkObj != null ? String.valueOf(linkObj) : null;
                    if (String.isNotBlank(linkValue)) {
                        record.put(collConfig.childLinkSfField, linkValue);
                    }
                }
                
                // Apply field mappings using Map directly (OPTIMIZED)
                applyFieldMappings(record, item, collConfig.fieldMappings, result);
                records.add(record);
            }
        }
        
        return records;
    }
    
    /**
     * Build records from nested arrays
     * OPTIMIZED: Work with Maps directly instead of creating parser instances
     */
    private static List<SObject> buildNestedCollectionRecords(
            InboundForm_JSONParser parser,
            InboundForm_MappingConfig.CollectionConfig collConfig,
            ProcessingResult result) {
        
        List<SObject> records = new List<SObject>();
        List<Map<String, Object>> parentItems = parser.getObjectList(collConfig.jsonPath);
        
        for (Map<String, Object> parentItem : parentItems) {
            String parentLinkValue = null;
            if (String.isNotBlank(collConfig.parentLinkJsonField)) {
                Object linkObj = parentItem.get(collConfig.parentLinkJsonField);
                parentLinkValue = linkObj != null ? String.valueOf(linkObj) : null;
            }
            
            Object nestedObj = parentItem.get(collConfig.nestedArrayPath);
            if (nestedObj instanceof List<Object>) {
                for (Object childItem : (List<Object>) nestedObj) {
                    if (childItem instanceof Map<String, Object>) {
                        Map<String, Object> childMap = (Map<String, Object>) childItem;
                        SObject record = createSObjectInstance(collConfig.targetObject);
                        
                        if (record != null) {
                            applyRecordType(record, collConfig);
                            
                            if (String.isNotBlank(collConfig.childLinkSfField) && 
                                String.isNotBlank(parentLinkValue)) {
                                record.put(collConfig.childLinkSfField, parentLinkValue);
                            }
                            
                            // Apply field mappings using Map directly (OPTIMIZED)
                            applyFieldMappings(record, childMap, collConfig.fieldMappings, result);
                            records.add(record);
                        }
                    }
                }
            }
        }
        
        return records;
    }
    
    /**
     * Apply field mappings to a record
     * REFACTORED: Now accepts Map<String, Object> directly to avoid creating parser instances
     */
    private static void applyFieldMappings(
            SObject record, 
            Map<String, Object> dataMap,
            List<InboundForm_MappingConfig.FieldMapping> mappings,
            ProcessingResult result) {
        
        for (InboundForm_MappingConfig.FieldMapping mapping : mappings) {
            try {
                Object value = getTypedValueFromMap(dataMap, mapping);
                
                // Apply default if null
                if (value == null && String.isNotBlank(mapping.defaultValue)) {
                    value = convertDefault(mapping.defaultValue, mapping.dataType);
                }
                
                if (value != null) {
                    record.put(mapping.targetField, value);
                }
                
                // Check required
                if (mapping.isRequired && value == null) {
                    result.addError('Required field missing: ' + mapping.targetField + 
                        ' (JSON path: ' + mapping.jsonPath + ')');
                }
                
            } catch (Exception e) {
                Logger.error('Error mapping ' + mapping.jsonPath + ' to ' + mapping.targetField + ': ' + e.getMessage());
                Logger.setScenario('InboundForm_Processor.applyFieldMappings');
                Logger.saveLog();
                System.debug(LoggingLevel.WARN, 
                    'Error mapping ' + mapping.jsonPath + ' to ' + mapping.targetField + 
                    ': ' + e.getMessage());
            }
        }
    }
    
    /**
     * Get value from Map using dot-notation path
     * OPTIMIZED: Navigate Map directly without creating parser instance
     */
    private static Object getValueFromMap(Map<String, Object> dataMap, String path) {
        if (String.isBlank(path) || dataMap == null) {
            return null;
        }
        
        List<String> pathParts = path.split('\\.');
        Object current = dataMap;
        
        for (String part : pathParts) {
            if (current == null) {
                return null;
            }
            
            if (part.contains('[')) {
                current = handleArrayAccessFromMap(current, part);
            } else if (current instanceof Map<String, Object>) {
                current = ((Map<String, Object>) current).get(part);
            } else {
                return null;
            }
        }
        
        return current;
    }
    
    /**
     * Handle array access notation like "routes[0]"
     */
    private static Object handleArrayAccessFromMap(Object current, String part) {
        Integer bracketStart = part.indexOf('[');
        Integer bracketEnd = part.indexOf(']');
        
        if (bracketStart < 0 || bracketEnd < 0 || bracketEnd <= bracketStart) {
            return null;
        }
        
        String arrayName = part.substring(0, bracketStart);
        String indexStr = part.substring(bracketStart + 1, bracketEnd);
        
        Integer index;
        try {
            index = Integer.valueOf(indexStr);
        } catch (Exception e) {
            return null;
        }
        
        Object arrayObj = null;
        if (current instanceof Map<String, Object>) {
            arrayObj = ((Map<String, Object>) current).get(arrayName);
        }
        
        if (arrayObj instanceof List<Object>) {
            List<Object> arr = (List<Object>) arrayObj;
            if (index >= 0 && index < arr.size()) {
                return arr.get(index);
            }
        }
        
        return null;
    }
    
    /**
     * Get typed value from Map based on data type
     * OPTIMIZED: Work with Map directly
     */
    private static Object getTypedValueFromMap(
            Map<String, Object> dataMap, 
            InboundForm_MappingConfig.FieldMapping mapping) {
        
        Object value = getValueFromMap(dataMap, mapping.jsonPath);
        
        if (value == null) {
            return null;
        }
        
        switch on mapping.dataType {
            when STRING_TYPE {
                return String.valueOf(value);
            }
            when INTEGER_TYPE {
                return convertToInteger(value);
            }
            when DECIMAL_TYPE {
                return convertToDecimal(value);
            }
            when BOOLEAN_TYPE {
                return convertToBoolean(value);
            }
            when BOOLEAN_YES_NO {
                Boolean boolVal = convertToBoolean(value);
                if (boolVal == null) return null;
                return boolVal ? mapping.booleanTrueValue : mapping.booleanFalseValue;
            }
            when CURRENCY_TYPE {
                return convertToCurrency(value);
            }
            when DATE_TYPE {
                return convertToDate(value);
            }
            when DATETIME_TYPE {
                return convertToDateTime(value);
            }
            when else {
                return String.valueOf(value);
            }
        }
    }
    
    /**
     * Convert value to Integer
     */
    private static Integer convertToInteger(Object value) {
        if (value == null) return null;
        if (value instanceof Integer) return (Integer) value;
        if (value instanceof Decimal) return ((Decimal) value).intValue();
        if (value instanceof Long) return ((Long) value).intValue();
        if (value instanceof String) {
            try {
                return Integer.valueOf((String) value);
            } catch (Exception e) {
                return null;
            }
        }
        return null;
    }
    
    /**
     * Convert value to Decimal
     */
    private static Decimal convertToDecimal(Object value) {
        if (value == null) return null;
        if (value instanceof Decimal) return (Decimal) value;
        if (value instanceof Integer) return Decimal.valueOf((Integer) value);
        if (value instanceof Long) return Decimal.valueOf((Long) value);
        if (value instanceof Double) return Decimal.valueOf((Double) value);
        if (value instanceof String) {
            try {
                return Decimal.valueOf((String) value);
            } catch (Exception e) {
                return null;
            }
        }
        return null;
    }
    
    /**
     * Convert value to Boolean
     */
    private static Boolean convertToBoolean(Object value) {
        if (value == null) return null;
        if (value instanceof Boolean) return (Boolean) value;
        if (value instanceof String) {
            String strVal = ((String) value).toLowerCase().trim();
            if (strVal == 'true' || strVal == 'yes' || strVal == '1') return true;
            if (strVal == 'false' || strVal == 'no' || strVal == '0') return false;
        }
        return null;
    }

    /**
     * Convert value to Currency (Decimal)
     */
    private static Decimal convertToCurrency(Object value) {
        if (value == null) return null;
        if (value instanceof Decimal) return (Decimal)value;
        if (value instanceof Double) return Decimal.valueOf((Double)value);
        if (value instanceof Integer) return Decimal.valueOf((Integer)value);

        String strValue = String.valueOf(value).trim();

        if (String.isBlank(strValue)) return null;
        strValue = strValue.replaceAll('[£$€]','').replace(',','').trim();
        try {
            return Decimal.valueOf((String) strValue);
        } catch (Exception e) {
            return null;
        }
    }
    
    /**
     * Convert value to Date
     */
    private static Date convertToDate(Object value) {
        if (value == null) return null;
        String strValue = String.valueOf(value);
        if (String.isBlank(strValue)) return null;
        
        try {
            // Handle ISO datetime format (take date portion)
            if (strValue.length() >= 10) {
                String datePart = strValue.substring(0, 10);
                // Handle both YYYY-MM-DD and YYYY/MM/DD
                datePart = datePart.replace('/', '-');
                return Date.valueOf(datePart);
            }
            return Date.valueOf(strValue);
        } catch (Exception e) {
            Logger.error('Failed to parse date: ' + strValue + '. Error: ' + e.getMessage());
            Logger.setScenario('InboundForm_Processor.convertToDate');
            Logger.saveLog();
            System.debug(LoggingLevel.WARN, 'Failed to parse date: ' + strValue);
            return null;
        }
    }
    
    /**
     * Convert value to DateTime
     */
    private static DateTime convertToDateTime(Object value) {
        if (value == null) return null;
        String strValue = String.valueOf(value);
        if (String.isBlank(strValue)) return null;
        
        try {
            // Normalize ISO 8601 format
            String normalized = strValue.replace('T', ' ');
            
            // Remove timezone indicator
            normalized = normalized.replace('Z', '');
            
            // Handle timezone offsets like +00:00 or -05:00
            Integer plusIdx = normalized.lastIndexOf('+');
            Integer minusIdx = normalized.lastIndexOf('-');
            // Only consider minus after the date portion (position > 10)
            if (plusIdx > 10) {
                normalized = normalized.substring(0, plusIdx);
            } else if (minusIdx > 10) {
                normalized = normalized.substring(0, minusIdx);
            }
            
            // Remove milliseconds if present (e.g., .000, .123456)
            Integer dotIdx = normalized.indexOf('.');
            if (dotIdx > 0) {
                normalized = normalized.substring(0, dotIdx);
            }
            
            // Trim any whitespace
            normalized = normalized.trim();
            
            return DateTime.valueOfGmt(normalized);
        } catch (Exception e) {
            Logger.error('Failed to parse datetime: ' + strValue + '. Error: ' + e.getMessage());
            Logger.setScenario('InboundForm_Processor.convertToDateTime');
            Logger.saveLog();
            System.debug(LoggingLevel.WARN, 'Failed to parse datetime: ' + strValue);
            return null;
        }
    }
    
    /**
     * Convert default value string to appropriate type
     */
    private static Object convertDefault(String defaultValue, 
                                          InboundForm_MappingConfig.DataType dataType) {
        if (String.isBlank(defaultValue)) return null;
        
        try {
            switch on dataType {
                when INTEGER_TYPE {
                    return Integer.valueOf(defaultValue);
                }
                when DECIMAL_TYPE {
                    return Decimal.valueOf(defaultValue);
                }
                when BOOLEAN_TYPE {
                    return Boolean.valueOf(defaultValue);
                }
                when DATE_TYPE {
                    return Date.valueOf(defaultValue);
                }
                when else {
                    return defaultValue;
                }
            }
        } catch (Exception e) {
            Logger.error('Failed to convert default value: ' + defaultValue + ' for type: ' + dataType + '. Error: ' + e.getMessage());
            Logger.setScenario('InboundForm_Processor.convertDefault');
            Logger.saveLog();
            return defaultValue;
        }
    }
    
    // ========================================================================
    // COMMIT LOGIC - Consolidated DML
    // REFACTORED: Reduced DML statements by grouping all records by SObject type
    // ========================================================================
    
    /**
     * Commit all records with consolidated DML operations
     * REFACTORED: Now performs minimum DML statements by grouping records by SObject type
     */
    private static void commitAllRecords(Map<Id, ProcessingResult> results) {
        // Group results by form type
        Map<String, List<ProcessingResult>> byFormType = new Map<String, List<ProcessingResult>>();
        
        for (ProcessingResult result : results.values()) {
            if (!result.success || String.isBlank(result.formType)) continue;
            
            if (!byFormType.containsKey(result.formType)) {
                byFormType.put(result.formType, new List<ProcessingResult>());
            }
            byFormType.get(result.formType).add(result);
        }
        
        // Process each form type
        for (String formType : byFormType.keySet()) {
            commitFormTypeRecordsConsolidated(formType, byFormType.get(formType));
        }
    }
    
    /**
     * Commit records for a single form type with consolidated DML
     * REFACTORED: Minimizes DML operations while maintaining proper ordering
     */
    private static void commitFormTypeRecordsConsolidated(String formType, List<ProcessingResult> results) {
        InboundForm_MappingConfig.FormTypeConfig config = 
            InboundForm_ConfigRegistry.getConfig(formType);

        if (config == null) return;
        
        // Step 1: Insert all primary records (single DML)
        List<SObject> allPrimaryRecords = new List<SObject>();
        List<ProcessingResult> primaryRecordOwners = new List<ProcessingResult>();
        for (ProcessingResult result : results) {
            if (result.createdRecords.containsKey(config.primaryObject)) {
                for (SObject primaryRecord : result.createdRecords.get(config.primaryObject)) {
                    allPrimaryRecords.add(primaryRecord);
                    primaryRecordOwners.add(result);
                }
            }
        }

        if (!allPrimaryRecords.isEmpty()) {
            Database.SaveResult[] saveResults = Database.insert(allPrimaryRecords, false);
            logDmlErrors(saveResults, config.primaryObject);

            for (Integer i = 0; i < saveResults.size(); i++) {
                if (saveResults[i].isSuccess()) {
                    continue;
                }

                ProcessingResult owner = primaryRecordOwners[i];
                owner.addError(
                    'Failed to create ' + config.primaryObject + ' record: ' +
                    formatDmlErrors(saveResults[i].getErrors())
                );
            }
        }

        // Build inbound to primary map for linking child records
        Map<Id, Id> inboundToPrimaryMap = buildInboundToPrimaryMap(allPrimaryRecords, config);

        // Step 1.5: Call afterPrimaryInsert handler for each result
        // This allows handlers to create records that need the primary record ID (e.g., Related_Case__c)
        IFormHandler handler = getHandler(config);
        if (handler != null) {
            for (ProcessingResult result : results) {
                if (!result.success) continue;
                
                Id primaryId = inboundToPrimaryMap.get(result.inboundRequestId);
                if (primaryId == null
                        && result.createdRecords.containsKey(config.primaryObject)
                        && !result.createdRecords.get(config.primaryObject).isEmpty()) {
                    primaryId = result.createdRecords.get(config.primaryObject)[0].Id;
                }
                if (primaryId != null && result.parser != null) {
                    try {
                        handler.afterPrimaryInsert(result.parser, primaryId, result);
                    } catch (Exception e) {
                        Logger.error('After-primary-insert handler error: ' + e.getMessage());
                        Logger.setScenario('InboundForm_Processor.afterPrimaryInsert');
                        Logger.saveLog();
                        result.addWarning('After-primary-insert handler error: ' + e.getMessage());
                        System.debug(LoggingLevel.WARN, 'After-primary-insert handler error: ' + e.getMessage());
                    }
                }
            }
        }
        
        // Step 1.6: Insert all postPrimaryRecords (records created by afterPrimaryInsert)
        Map<String, List<SObject>> allPostPrimaryByObject = new Map<String, List<SObject>>();
        Map<String, List<ProcessingResult>> postPrimaryOwnersByObject =
            new Map<String, List<ProcessingResult>>();
        for (ProcessingResult result : results) {
            if (!result.success) continue;
            
            for (String objectType : result.postPrimaryRecords.keySet()) {
                if (!allPostPrimaryByObject.containsKey(objectType)) {
                    allPostPrimaryByObject.put(objectType, new List<SObject>());
                    postPrimaryOwnersByObject.put(objectType, new List<ProcessingResult>());
                }

                for (SObject record : result.postPrimaryRecords.get(objectType)) {
                    allPostPrimaryByObject.get(objectType).add(record);
                    postPrimaryOwnersByObject.get(objectType).add(result);
                }
            }
        }
        
        for (String objectType : allPostPrimaryByObject.keySet()) {
            List<SObject> recordsToInsert = allPostPrimaryByObject.get(objectType);
            if (!recordsToInsert.isEmpty()) {
                Database.SaveResult[] saveResults = Database.insert(recordsToInsert, false);
                logDmlErrors(saveResults, objectType);

                List<ProcessingResult> owners = postPrimaryOwnersByObject.get(objectType);
                for (Integer i = 0; i < saveResults.size(); i++) {
                    if (saveResults[i].isSuccess()) {
                        continue;
                    }

                    owners[i].addWarning(
                        'Failed to create ' + objectType + ' record: ' +
                        formatDmlErrors(saveResults[i].getErrors())
                    );
                }
            }
        }
        
        // Step 2: Build insertion order for collections based on dependencies
        List<List<InboundForm_MappingConfig.CollectionConfig>> collectionLevels = 
            buildCollectionInsertionLevels(config);
        
        // Step 3: Insert collections level by level
        // Each level contains collections that can be inserted together
        // (collections in the same level don't depend on each other)
        Map<String, Map<String, Id>> allLinkMaps = new Map<String, Map<String, Id>>();
        Set<String> collectionsUsedAsParents = new Set<String>();
        for (InboundForm_MappingConfig.CollectionConfig coll : config.collections) {
            if (String.isNotBlank(coll.parentCollection)) {
                collectionsUsedAsParents.add(coll.parentCollection);
            }
        }
        
        // Track all inserted records by object type for afterAllInserts hook
        Map<String, List<SObject>> allInsertedByObject = new Map<String, List<SObject>>();
        
        for (List<InboundForm_MappingConfig.CollectionConfig> level : collectionLevels) {
            // Group all records at this level by target object for consolidated DML
            Map<String, List<SObject>> recordsByObject = new Map<String, List<SObject>>();
            Map<String, List<ProcessingResult>> ownersByObject =
                new Map<String, List<ProcessingResult>>();
            Map<String, List<SObject>> recordsByCollection = new Map<String, List<SObject>>();
            Map<String, InboundForm_MappingConfig.CollectionConfig> configByCollection =
                new Map<String, InboundForm_MappingConfig.CollectionConfig>();
            
            for (InboundForm_MappingConfig.CollectionConfig collConfig : level) {
                CollectionGatherResult gathered = gatherCollectionRecords(
                    collConfig, results, inboundToPrimaryMap, allLinkMaps);
                
                if (!gathered.records.isEmpty()) {
                    String targetObj = collConfig.targetObject;
                    if (!recordsByObject.containsKey(targetObj)) {
                        recordsByObject.put(targetObj, new List<SObject>());
                        ownersByObject.put(targetObj, new List<ProcessingResult>());
                    }
                    recordsByObject.get(targetObj).addAll(gathered.records);
                    ownersByObject.get(targetObj).addAll(gathered.owners);

                    recordsByCollection.put(collConfig.collectionName, gathered.records);
                    configByCollection.put(collConfig.collectionName, collConfig);
                }
            }
            
            // Consolidated DML per object type at this level
            for (String objectType : recordsByObject.keySet()) {
                List<SObject> recordsToInsert = recordsByObject.get(objectType);
                if (!recordsToInsert.isEmpty()) {
                    Database.SaveResult[] saveResults = Database.insert(recordsToInsert, false);
                    logDmlErrors(saveResults, objectType);

                    List<ProcessingResult> owners = ownersByObject.get(objectType);
                    for (Integer i = 0; i < saveResults.size(); i++) {
                        if (saveResults[i].isSuccess()) {
                            continue;
                        }

                        owners[i].addWarning(
                            'Failed to create ' + objectType + ' record: ' +
                            formatDmlErrors(saveResults[i].getErrors())
                        );
                    }
                    
                    // Track inserted records for afterAllInserts
                    if (!allInsertedByObject.containsKey(objectType)) {
                        allInsertedByObject.put(objectType, new List<SObject>());
                    }
                    allInsertedByObject.get(objectType).addAll(recordsToInsert);
                }
            }

            // Update link maps for next level's parent-child linking per collection.
            for (String collectionName : recordsByCollection.keySet()) {
                InboundForm_MappingConfig.CollectionConfig collConfig =
                    configByCollection.get(collectionName);
                if (collConfig != null
                        && collectionsUsedAsParents.contains(collectionName)
                        && String.isNotBlank(collConfig.parentLinkSfField)) {
                    Map<String, Id> linkMap = buildLinkMapFromRecords(
                        recordsByCollection.get(collectionName),
                        collConfig.parentLinkSfField
                    );
                    allLinkMaps.put(collectionName, linkMap);
                }
            }
        }
        
        // Step 4: Call afterAllInserts handler for post-insert processing (e.g., setting DNO__c on Case)
        if (handler != null && !allInsertedByObject.isEmpty()) {
            for (ProcessingResult result : results) {
                if (!result.success) continue;
                
                Id primaryId = inboundToPrimaryMap.get(result.inboundRequestId);
                if (primaryId == null
                        && result.createdRecords.containsKey(config.primaryObject)
                        && !result.createdRecords.get(config.primaryObject).isEmpty()) {
                    primaryId = result.createdRecords.get(config.primaryObject)[0].Id;
                }

                if (primaryId != null) {
                    try {
                        // Filter inserted records to only those belonging to this result's primary record
                        Map<String, List<SObject>> resultInsertedRecords = 
                            filterRecordsByPrimaryId(allInsertedByObject, primaryId, config);
                        handler.afterAllInserts(primaryId, resultInsertedRecords);
                    } catch (Exception e) {
                        System.debug(LoggingLevel.WARN, 'After-all-inserts handler error: ' + e.getMessage());
                        Logger.error('After-all-inserts handler error: ' + e.getMessage());
                        Logger.setScenario('InboundForm_Processor.afterAllInserts');
                        Logger.saveLog();
                        result.addWarning('After-all-inserts handler error: ' + e.getMessage());
                    }
                }
            }
        }
    }
    
    /**
     * Filter inserted records to only those belonging to a specific primary record
     */
    private static Map<String, List<SObject>> filterRecordsByPrimaryId(
            Map<String, List<SObject>> allRecords, 
            Id primaryId,
            InboundForm_MappingConfig.FormTypeConfig config) {
        
        Map<String, List<SObject>> filtered = new Map<String, List<SObject>>();
        
        // Build a map of object type to parent lookup field
        Map<String, String> objectToParentField = new Map<String, String>();
        for (InboundForm_MappingConfig.CollectionConfig coll : config.collections) {
            if (String.isBlank(coll.parentCollection)) {
                // Direct child of primary - use parentLookupField
                objectToParentField.put(coll.targetObject, coll.parentLookupField);
            }
        }
        
        for (String objectType : allRecords.keySet()) {
            String parentField = objectToParentField.get(objectType);
            if (String.isBlank(parentField)) continue;
            
            List<SObject> filteredList = new List<SObject>();
            for (SObject rec : allRecords.get(objectType)) {
                Object parentIdObj = rec.get(parentField);
                if (parentIdObj != null && (Id)parentIdObj == primaryId) {
                    filteredList.add(rec);
                }
            }
            
            if (!filteredList.isEmpty()) {
                filtered.put(objectType, filteredList);
            }
        }
        
        return filtered;
    }
    
    /**
     * Build collection insertion levels based on dependencies
     * Collections in the same level can be inserted in a single batch
     */
    private static List<List<InboundForm_MappingConfig.CollectionConfig>> buildCollectionInsertionLevels(
            InboundForm_MappingConfig.FormTypeConfig config) {
        
        List<List<InboundForm_MappingConfig.CollectionConfig>> levels = 
            new List<List<InboundForm_MappingConfig.CollectionConfig>>();
        
        // Separate collections by whether they have parent collection dependencies
        List<InboundForm_MappingConfig.CollectionConfig> noDependency = 
            new List<InboundForm_MappingConfig.CollectionConfig>();
        Map<String, List<InboundForm_MappingConfig.CollectionConfig>> byParent = 
            new Map<String, List<InboundForm_MappingConfig.CollectionConfig>>();
        
        for (InboundForm_MappingConfig.CollectionConfig coll : config.collections) {
            if (String.isBlank(coll.parentCollection)) {
                noDependency.add(coll);
            } else {
                if (!byParent.containsKey(coll.parentCollection)) {
                    byParent.put(coll.parentCollection, new List<InboundForm_MappingConfig.CollectionConfig>());
                }
                byParent.get(coll.parentCollection).add(coll);
            }
        }
        
        // Sort each group by processing order
        noDependency.sort();
        
        // Level 0: Collections with no parent collection dependency (link to primary)
        if (!noDependency.isEmpty()) {
            levels.add(noDependency);
        }
        
        // Subsequent levels: Collections that depend on previous level
        Set<String> processedCollections = new Set<String>();
        for (InboundForm_MappingConfig.CollectionConfig coll : noDependency) {
            processedCollections.add(coll.collectionName);
        }
        
        // Keep adding levels until all collections are processed
        Integer maxIterations = 10; // Safety limit
        Integer iteration = 0;
        while (iteration < maxIterations) {
            List<InboundForm_MappingConfig.CollectionConfig> nextLevel = 
                new List<InboundForm_MappingConfig.CollectionConfig>();
            
            for (String parentName : byParent.keySet()) {
                if (processedCollections.contains(parentName)) {
                    for (InboundForm_MappingConfig.CollectionConfig child : byParent.get(parentName)) {
                        if (!processedCollections.contains(child.collectionName)) {
                            nextLevel.add(child);
                        }
                    }
                }
            }
            
            if (nextLevel.isEmpty()) {
                break;
            }
            
            nextLevel.sort();
            levels.add(nextLevel);
            
            for (InboundForm_MappingConfig.CollectionConfig coll : nextLevel) {
                processedCollections.add(coll.collectionName);
            }
            
            iteration++;
        }
        
        return levels;
    }
    
    private static Map<Id, Id> buildInboundToPrimaryMap(
            List<SObject> primaryRecords,
            InboundForm_MappingConfig.FormTypeConfig config) {
        
        Map<Id, Id> inboundToPrimaryMap = new Map<Id, Id>();
        
        for (SObject rec : primaryRecords) {
            if (rec.Id != null && String.isNotBlank(config.inboundRequestLookupField)) {
                Object inboundIdObj = rec.get(config.inboundRequestLookupField);
                Id inboundId = inboundIdObj != null ? (Id) inboundIdObj : null;
                if (inboundId != null) {
                    inboundToPrimaryMap.put(inboundId, rec.Id);
                }
            }
        }
        
        return inboundToPrimaryMap;
    }
    
    /**
     * Build link map from inserted records for parent-child linking
     */
    private static Map<String, Id> buildLinkMapFromRecords(
            List<SObject> records, 
            String linkField) {
        
        Map<String, Id> linkMap = new Map<String, Id>();
        
        for (SObject rec : records) {
            if (rec.Id != null && String.isNotBlank(linkField)) {
                Object linkObj = rec.get(linkField);
                String linkValue = linkObj != null ? String.valueOf(linkObj) : null;
                if (String.isNotBlank(linkValue)) {
                    linkMap.put(linkValue, rec.Id);
                }
            }
        }
        
        return linkMap;
    }
    
    private static CollectionGatherResult gatherCollectionRecords(
            InboundForm_MappingConfig.CollectionConfig collConfig,
            List<ProcessingResult> results,
            Map<Id, Id> inboundToPrimaryMap,
            Map<String, Map<String, Id>> allLinkMaps) {

        CollectionGatherResult gathered = new CollectionGatherResult();
        List<SObject> recordsToInsert = gathered.records;
        
        // Get parent link map if this collection links to another collection
        Map<String, Id> parentLinkMap = new Map<String, Id>();
        if (String.isNotBlank(collConfig.parentCollection)) {
            parentLinkMap = allLinkMaps.containsKey(collConfig.parentCollection) 
                ? allLinkMaps.get(collConfig.parentCollection) 
                : new Map<String, Id>();
        }
        
        for (ProcessingResult result : results) {
            if (!result.success) continue;
            
            Id primaryId = inboundToPrimaryMap.get(result.inboundRequestId);
            List<SObject> records = result.collectionRecords.get(collConfig.collectionName);
            if (records == null) continue;
            
            for (SObject record : records) {
                if (String.isNotBlank(collConfig.parentCollection)) {
                    // Link to parent collection
                    Object linkObj = record.get(collConfig.childLinkSfField);
                    String linkValue = linkObj != null ? String.valueOf(linkObj) : null;
                    Id parentId = parentLinkMap.get(linkValue);
                    if (parentId != null && String.isNotBlank(collConfig.parentLookupField)) {
                        record.put(collConfig.parentLookupField, parentId);
                    }
                } else if (primaryId != null && String.isNotBlank(collConfig.parentLookupField)) {
                    // Link to primary record
                    record.put(collConfig.parentLookupField, primaryId);
                }
                recordsToInsert.add(record);
                gathered.owners.add(result);
            }
        }

        return gathered;
    }

    private static String formatDmlErrors(Database.Error[] errors) {
        List<String> details = new List<String>();
        for (Database.Error err : errors) {
            details.add(err.getMessage() + ' [Fields: ' + err.getFields() + ']');
        }
        return String.join(details, '; ');
    }
    
    private static void logDmlErrors(Database.SaveResult[] results, String objectName) {
        for (Integer i = 0; i < results.size(); i++) {
            if (!results[i].isSuccess()) {
                for (Database.Error err : results[i].getErrors()) {
                    System.debug(LoggingLevel.ERROR, 
                        'DML Error on ' + objectName + ': ' + err.getMessage() + 
                        ' [Fields: ' + err.getFields() + ']');
                    Logger.error('DML Error on ' + objectName + ': ' + err.getMessage() + 
                        ' [Fields: ' + err.getFields() + ']');
                    Logger.setScenario('InboundForm_Processor.logDmlErrors');
                    Logger.saveLog();
                }
            }
        }
    }
    
    // ========================================================================
    // HELPER METHODS
    // ========================================================================
    
    private static SObject createSObjectInstance(String objectType) {
        Schema.SObjectType sObjType = sObjectTypeCache.get(objectType);
        return sObjType?.newSObject();
    }
    
    private static Id getRecordTypeId(String objectName, String developerName) {
        Map<String, Id> rtMap = recordTypeCache.get(objectName);
        return rtMap?.get(developerName);
    }
    
    private static void applyRecordType(
            SObject record, 
            InboundForm_MappingConfig.CollectionConfig config) {
        
        if (String.isNotBlank(config.targetRecordType)) {
            Id rtId = getRecordTypeId(config.targetObject, config.targetRecordType);
            if (rtId != null) {
                record.put('RecordTypeId', rtId);
            }
        }
    }
    
    // ========================================================================
    // STATUS UPDATE - Via Queueable
    // ========================================================================
    
    private static void queueStatusUpdates(Map<Id, ProcessingResult> results) {
        List<InboundForm_StatusUpdateQueueable.StatusUpdateData> statusUpdates = 
            new List<InboundForm_StatusUpdateQueueable.StatusUpdateData>();
        
        for (Id reqId : results.keySet()) {
            ProcessingResult result = results.get(reqId);
            
            // Determine status based on success and warnings
            String status;
            String errorText;
            
            if (!result.success) {
                status = 'Failed';
                errorText = truncateErrors(result.errors, MAX_ERROR_LOG_LENGTH);
            } else if (result.hasWarnings()) {
                status = 'Partial Success';
                errorText = truncateErrors(result.warnings, MAX_ERROR_LOG_LENGTH);
            } else {
                status = 'Processed';
                errorText = null;
            }
            
            statusUpdates.add(new InboundForm_StatusUpdateQueueable.StatusUpdateData(
                reqId,
                status,
                errorText
            ));
        }
        
        if (!statusUpdates.isEmpty()) {
            try {
                Id jobId = System.enqueueJob(new InboundForm_StatusUpdateQueueable(statusUpdates));
                // logging is handled in the queueable class, but we can log the enqueueing here
                Logger.info('Enqueued status update job: ' + jobId + 
                    ' for ' + statusUpdates.size() + ' records');
                Logger.saveLog();
                System.debug(LoggingLevel.INFO, 'Enqueued status update job: ' + jobId + 
                    ' for ' + statusUpdates.size() + ' records');
            } catch (Exception e) {
                Logger.error('Failed to enqueue status update job: ' + e.getMessage());
                Logger.setScenario('InboundForm_Processor.queueStatusUpdates');
                Logger.saveLog();
                System.debug(LoggingLevel.ERROR, 'Failed to enqueue status update job: ' + e.getMessage());
            }
        }
    }
    
    /**
     * Truncate errors while preserving first and last errors for better diagnostics
     */
    private static String truncateErrors(List<String> errors, Integer maxLength) {
        String joined = String.join(errors, '\n');
        if (joined.length() <= maxLength) {
            return joined;
        }
        
        // Keep first and last portions
        Integer halfLength = (maxLength - 50) / 2;
        return joined.left(halfLength) + '\n\n... [TRUNCATED ' + 
            (joined.length() - maxLength) + ' chars] ...\n\n' + joined.right(halfLength);
    }
    
    // ========================================================================
    // INNER CLASSES
    // ========================================================================

    private class CollectionGatherResult {
        public List<SObject> records = new List<SObject>();
        public List<ProcessingResult> owners = new List<ProcessingResult>();
    }
    
    /**
     * Processing result for a single request
     */
    public class ProcessingResult {
        public Id inboundRequestId { get; set; }
        public String formType { get; set; }
        public InboundForm_MappingConfig.FormTypeConfig formConfig { get; set; }
        public Boolean success { get; set; }
        public List<String> errors { get; set; }
        public List<String> warnings { get; set; }
        public Map<String, List<SObject>> createdRecords { get; set; }
        public Map<String, List<SObject>> collectionRecords { get; set; }
        // Records to insert after primary record is inserted (for lookups requiring parent ID)
        public Map<String, List<SObject>> postPrimaryRecords { get; set; }
        // Parser instance for use in afterPrimaryInsert hook
        public InboundForm_JSONParser parser { get; set; }
        
        public ProcessingResult(Id reqId) {
            this.inboundRequestId = reqId;
            this.success = true;
            this.errors = new List<String>();
            this.warnings = new List<String>();
            this.createdRecords = new Map<String, List<SObject>>();
            this.collectionRecords = new Map<String, List<SObject>>();
            this.postPrimaryRecords = new Map<String, List<SObject>>();
        }
        
        public void addError(String error) {
            this.errors.add(error);
            this.success = false;
        }
        
        public void addWarning(String warning) {
            this.warnings.add(warning);
        }
        
        public Boolean hasWarnings() {
            return !this.warnings.isEmpty();
        }
        
        public void addRecords(String objectType, List<SObject> records) {
            if (!createdRecords.containsKey(objectType)) {
                createdRecords.put(objectType, new List<SObject>());
            }
            createdRecords.get(objectType).addAll(records);
        }
        
        public void addPostPrimaryRecords(String objectType, List<SObject> records) {
            if (!postPrimaryRecords.containsKey(objectType)) {
                postPrimaryRecords.put(objectType, new List<SObject>());
            }
            postPrimaryRecords.get(objectType).addAll(records);
        }
    }
    
    /**
     * Interface for custom form handlers
     */
    public interface IFormHandler {
        List<String> validate(InboundForm_JSONParser parser);
        void afterBuild(InboundForm_JSONParser parser, Map<String, List<SObject>> records);
        void afterPrimaryInsert(InboundForm_JSONParser parser, Id primaryRecordId, ProcessingResult result);
        void afterAllInserts(Id primaryRecordId, Map<String, List<SObject>> insertedRecords);
    }
    
    /**
     * Clear all static caches (useful for testing)
     */
    @TestVisible
    private static void clearAllCaches() {
        sObjectTypeCache.clear();
        recordTypeCache.clear();
        handlerCache.clear();
        schemaCacheInitialized = false;
    }
}