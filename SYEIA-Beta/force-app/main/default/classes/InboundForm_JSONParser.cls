/**
 * Generic JSON path parser for navigating JSON structures using dot-notation paths like "sections.worksOverview.polesAdded"
 */
public class InboundForm_JSONParser {
    
    private Map<String, Object> rootMap;
    
    /**
     * Constructor that parses JSON string
     */
    public InboundForm_JSONParser(String jsonString) {
        if (String.isBlank(jsonString)) {
            this.rootMap = new Map<String, Object>();
            return;
        }
        
        try {
            Object parsed = JSON.deserializeUntyped(jsonString);
            if (parsed instanceof Map<String, Object>) {
                this.rootMap = (Map<String, Object>) parsed;
            } else {
                this.rootMap = new Map<String, Object>();
            }
        } catch (Exception e) {
            Logger.error('Failed to parse JSON string: ' + e.getMessage());
            Logger.setScenario('InboundForm_JSONParser.constructor');
            Logger.saveLog();
            throw new JSONParserException('Failed to parse JSON: ' + e.getMessage());
        }
    }
    
    /**
     * Constructor that accepts pre-parsed map
     */
    public InboundForm_JSONParser(Map<String, Object> parsedMap) {
        this.rootMap = parsedMap != null ? parsedMap : new Map<String, Object>();
    }
    
    /**
     * Get value at specified JSON path
     */
    public Object getValue(String path) {
        if (String.isBlank(path) || rootMap == null) {
            return null;
        }
        
        List<String> pathParts = path.split('\\.');
        Object current = rootMap;
        
        for (String part : pathParts) {
            if (current == null) {
                return null;
            }
            
            if (part.contains('[')) {
                current = handleArrayAccess(current, part);
            } else if (current instanceof Map<String, Object>) {
                current = ((Map<String, Object>) current).get(part);
            } else {
                return null;
            }
        }
        
        return current;
    }
    
    /**
     * Get string value at path
     */
    public String getString(String path) {
        Object value = getValue(path);
        return value != null ? String.valueOf(value) : null;
    }
    
    /**
     * Get integer value at path
     */
    public Integer getInteger(String path) {
        Object value = getValue(path);
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
     * Get decimal value at path
     */
    public Decimal getDecimal(String path) {
        Object value = getValue(path);
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
     * Get boolean value at path
     */
    public Boolean getBoolean(String path) {
        Object value = getValue(path);
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
     * Get date value at path (handles ISO formats)
     */
    public Date getDate(String path) {
        String value = getString(path);
        if (String.isBlank(value)) return null;
        
        try {
            // Handle ISO datetime format (take date portion)
            if (value.length() >= 10) {
                String datePart = value.substring(0, 10);
                // Handle both YYYY-MM-DD and YYYY/MM/DD
                datePart = datePart.replace('/', '-');
                return Date.valueOf(datePart);
            }
            return Date.valueOf(value);
        } catch (Exception e) {
            Logger.error('Failed to parse date from path "' + path + '": ' + e.getMessage());
            Logger.setScenario('InboundForm_JSONParser.getDate');
            Logger.saveLog();

            System.debug(LoggingLevel.WARN, 
                'Failed to parse date from path "' + path + '": ' + value);
            return null;
        }
    }
    
    /**
     * Get datetime value at path (handles multiple ISO 8601 formats)
     */
    public DateTime getDateTime(String path) {
        String value = getString(path);
        if (String.isBlank(value)) return null;
        
        try {
            // Normalize ISO 8601 format
            String normalized = value.replace('T', ' ');
            
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
            Logger.error('Failed to parse datetime from path "' + path + '": ' + e.getMessage());
            Logger.setScenario('InboundForm_JSONParser.getDateTime');
            Logger.saveLog();
            System.debug(LoggingLevel.WARN, 
                'Failed to parse datetime from path "' + path + '": ' + value);
            return null;
        }
    }
    
    /**
     * Get list of objects at path
     */
    public List<Object> getList(String path) {
        Object value = getValue(path);
        if (value instanceof List<Object>) {
            return (List<Object>) value;
        }
        return new List<Object>();
    }
    
    /**
     * Get list of maps at path (for array of objects)
     * Also handles single objects by wrapping them in a list
     */
    public List<Map<String, Object>> getObjectList(String path) {
        Object value = getValue(path);
        List<Map<String, Object>> result = new List<Map<String, Object>>();
        
        // Handle single object - wrap in list
        if (value instanceof Map<String, Object>) {
            result.add((Map<String, Object>) value);
            return result;
        }
        
        // Handle array of objects
        if (value instanceof List<Object>) {
            List<Object> rawList = (List<Object>) value;
            for (Object item : rawList) {
                if (item instanceof Map<String, Object>) {
                    result.add((Map<String, Object>) item);
                }
            }
        }
        
        return result;
    }
    
    /**
     * Check if path exists and has a non-null value
     */
    public Boolean hasValue(String path) {
        return getValue(path) != null;
    }
    
    /**
     * Get the root map
     */
    public Map<String, Object> getRootMap() {
        return this.rootMap;
    }
    
    /**
     * Handle array access notation like "routes[0]"
     */
    private Object handleArrayAccess(Object current, String part) {
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
    
    public class JSONParserException extends Exception {}
}