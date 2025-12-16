/**
 * Configuration classes for defining JSON-to-Salesforce mappings. Used by the InboundForm processing framework.
 */
public class InboundForm_MappingConfig {
    
    // ========================================================================
    // CONFIGURATION CLASSES
    // ========================================================================
    
    /**
     * Configuration for a form type (e.g., S37, NWL, TL)
     */
    public class FormTypeConfig {
        public String formType { get; set; }
        public String description { get; set; }
        public String primaryObject { get; set; }
        public String primaryRecordType { get; set; }
        public String inboundRequestLookupField { get; set; }
        public String applicationIdField { get; set; }
        public String applicationIdJsonPath { get; set; }
        public String nameField { get; set; }
        public String nameJsonPath { get; set; }
        public String statusField { get; set; }
        public String defaultStatus { get; set; }
        public Type handlerClass { get; set; }
        public Boolean active { get; set; }
        public List<FieldMapping> fieldMappings { get; set; }
        public List<CollectionConfig> collections { get; set; }
        
        public FormTypeConfig() {
            this.active = true;
            this.fieldMappings = new List<FieldMapping>();
            this.collections = new List<CollectionConfig>();
            this.inboundRequestLookupField = 'Inbound_Request__c';
            this.applicationIdJsonPath = 'applicationId';
            this.nameField = 'Name';
        }
        
        // Fluent builder methods
        public FormTypeConfig setFormType(String value) { 
            this.formType = value; 
            return this; 
        }
        public FormTypeConfig setDescription(String value) { 
            this.description = value; 
            return this; 
        }
        public FormTypeConfig setPrimaryObject(String value) { 
            this.primaryObject = value; 
            return this; 
        }
        public FormTypeConfig setPrimaryRecordType(String value) { 
            this.primaryRecordType = value; 
            return this; 
        }
        public FormTypeConfig setApplicationIdField(String value) { 
            this.applicationIdField = value; 
            return this; 
        }
        public FormTypeConfig setApplicationIdJsonPath(String value) { 
            this.applicationIdJsonPath = value; 
            return this; 
        }
        public FormTypeConfig setNameJsonPath(String value) { 
            this.nameJsonPath = value; 
            return this; 
        }
        public FormTypeConfig setStatusField(String value) { 
            this.statusField = value; 
            return this; 
        }
        public FormTypeConfig setDefaultStatus(String value) { 
            this.defaultStatus = value; 
            return this; 
        }
        public FormTypeConfig setHandlerClass(Type value) { 
            this.handlerClass = value; 
            return this; 
        }
        public FormTypeConfig setActive(Boolean value) { 
            this.active = value; 
            return this; 
        }
        
        public FormTypeConfig addFieldMapping(FieldMapping mapping) {
            this.fieldMappings.add(mapping);
            return this;
        }
        
        public FormTypeConfig addCollection(CollectionConfig collection) {
            this.collections.add(collection);
            return this;
        }
    }
    
    /**
     * Configuration for a JSON array/collection
     */
    public class CollectionConfig implements Comparable {
        public String collectionName { get; set; }
        public String jsonPath { get; set; }
        public String targetObject { get; set; }
        public String targetRecordType { get; set; }
        public String parentLookupField { get; set; }
        public String parentCollection { get; set; }
        public String parentLinkJsonField { get; set; }
        public String parentLinkSfField { get; set; }
        public String childLinkSfField { get; set; }
        public Boolean isNestedArray { get; set; }
        public String nestedArrayPath { get; set; }
        public Boolean isSimpleArray { get; set; }
        public String simpleArrayTargetField { get; set; }
        public Integer processingOrder { get; set; }
        public List<FieldMapping> fieldMappings { get; set; }
        
        public CollectionConfig() {
            this.isNestedArray = false;
            this.isSimpleArray = false;
            this.processingOrder = 100;
            this.fieldMappings = new List<FieldMapping>();
        }
        
        // Fluent builder methods
        public CollectionConfig setCollectionName(String value) { 
            this.collectionName = value; 
            return this; 
        }
        public CollectionConfig setJsonPath(String value) { 
            this.jsonPath = value; 
            return this; 
        }
        public CollectionConfig setTargetObject(String value) { 
            this.targetObject = value; 
            return this; 
        }
        public CollectionConfig setTargetRecordType(String value) { 
            this.targetRecordType = value; 
            return this; 
        }
        public CollectionConfig setParentLookupField(String value) { 
            this.parentLookupField = value; 
            return this; 
        }
        public CollectionConfig setParentCollection(String value) { 
            this.parentCollection = value; 
            return this; 
        }
        public CollectionConfig setParentLinkJsonField(String value) { 
            this.parentLinkJsonField = value; 
            return this; 
        }
        public CollectionConfig setParentLinkSfField(String value) { 
            this.parentLinkSfField = value; 
            return this; 
        }
        public CollectionConfig setChildLinkSfField(String value) { 
            this.childLinkSfField = value; 
            return this; 
        }
        public CollectionConfig setIsNestedArray(Boolean value) { 
            this.isNestedArray = value; 
            return this; 
        }
        public CollectionConfig setNestedArrayPath(String value) { 
            this.nestedArrayPath = value; 
            return this; 
        }
        public CollectionConfig setIsSimpleArray(Boolean value) { 
            this.isSimpleArray = value; 
            return this; 
        }
        public CollectionConfig setSimpleArrayTargetField(String value) { 
            this.simpleArrayTargetField = value; 
            return this; 
        }
        public CollectionConfig setProcessingOrder(Integer value) { 
            this.processingOrder = value; 
            return this; 
        }
        
        public CollectionConfig addFieldMapping(FieldMapping mapping) {
            this.fieldMappings.add(mapping);
            return this;
        }
        
        public Integer compareTo(Object compareTo) {
            CollectionConfig other = (CollectionConfig) compareTo;
            Integer thisOrder = this.processingOrder != null ? this.processingOrder : 100;
            Integer otherOrder = other.processingOrder != null ? other.processingOrder : 100;
            return thisOrder - otherOrder;
        }
    }
    
    /**
     * Configuration for a single field mapping
     */
    public class FieldMapping {
        public String jsonPath { get; set; }
        public String targetField { get; set; }
        public DataType dataType { get; set; }
        public String booleanTrueValue { get; set; }
        public String booleanFalseValue { get; set; }
        public Boolean isRequired { get; set; }
        public String defaultValue { get; set; }
        
        public FieldMapping() {
            this.dataType = InboundForm_MappingConfig.DataType.STRING_TYPE;
            this.isRequired = false;
            this.booleanTrueValue = 'Yes';
            this.booleanFalseValue = 'No';
        }
        
        public FieldMapping(String jsonPath, String targetField) {
            this();
            this.jsonPath = jsonPath;
            this.targetField = targetField;
        }
        
        public FieldMapping(String jsonPath, String targetField, DataType dataType) {
            this(jsonPath, targetField);
            this.dataType = dataType;
        }
        
        // Fluent builder methods
        public FieldMapping setJsonPath(String value) { 
            this.jsonPath = value; 
            return this; 
        }
        public FieldMapping setTargetField(String value) { 
            this.targetField = value; 
            return this; 
        }
        public FieldMapping setDataType(DataType value) { 
            this.dataType = value; 
            return this; 
        }
        public FieldMapping setBooleanTrueValue(String value) { 
            this.booleanTrueValue = value; 
            return this; 
        }
        public FieldMapping setBooleanFalseValue(String value) { 
            this.booleanFalseValue = value; 
            return this; 
        }
        public FieldMapping setIsRequired(Boolean value) { 
            this.isRequired = value; 
            return this; 
        }
        public FieldMapping setDefaultValue(String value) { 
            this.defaultValue = value; 
            return this; 
        }
    }
    
    /**
     * Data types for field mapping
     */
    public enum DataType {
        STRING_TYPE,
        INTEGER_TYPE,
        DECIMAL_TYPE,
        BOOLEAN_TYPE,
        BOOLEAN_YES_NO,
        DATE_TYPE,
        DATETIME_TYPE
    }
    
    // ========================================================================
    // STATIC FACTORY METHODS
    // ========================================================================
    
    public static FieldMapping stringField(String jsonPath, String targetField) {
        return new FieldMapping(jsonPath, targetField, DataType.STRING_TYPE);
    }
    
    public static FieldMapping integerField(String jsonPath, String targetField) {
        return new FieldMapping(jsonPath, targetField, DataType.INTEGER_TYPE);
    }
    
    public static FieldMapping decimalField(String jsonPath, String targetField) {
        return new FieldMapping(jsonPath, targetField, DataType.DECIMAL_TYPE);
    }
    
    public static FieldMapping booleanField(String jsonPath, String targetField) {
        return new FieldMapping(jsonPath, targetField, DataType.BOOLEAN_TYPE);
    }
    
    public static FieldMapping yesNoField(String jsonPath, String targetField) {
        return new FieldMapping(jsonPath, targetField, DataType.BOOLEAN_YES_NO);
    }
    
    public static FieldMapping dateField(String jsonPath, String targetField) {
        return new FieldMapping(jsonPath, targetField, DataType.DATE_TYPE);
    }
    
    public static FieldMapping datetimeField(String jsonPath, String targetField) {
        return new FieldMapping(jsonPath, targetField, DataType.DATETIME_TYPE);
    }
    
    public static FieldMapping requiredString(String jsonPath, String targetField) {
        return new FieldMapping(jsonPath, targetField, DataType.STRING_TYPE)
            .setIsRequired(true);
    }
}