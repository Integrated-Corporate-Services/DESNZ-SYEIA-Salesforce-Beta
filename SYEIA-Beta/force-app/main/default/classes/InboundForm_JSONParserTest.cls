/**
 * Test class for InboundForm_JSONParser.
 * Tests JSON parsing, path navigation, and type conversion functionality.
 */
@IsTest
private class InboundForm_JSONParserTest {
    
    // ========================================================================
    // TEST DATA
    // ========================================================================
    
    private static String getTestJson() {
        return '{' +
            '"formType": "S37",' +
            '"applicationId": "APP-12345",' +
            '"stringValue": "test string",' +
            '"integerValue": 42,' +
            '"decimalValue": 123.45,' +
            '"booleanTrue": true,' +
            '"booleanFalse": false,' +
            '"booleanYes": "yes",' +
            '"booleanNo": "no",' +
            '"dateValue": "2024-03-15",' +
            '"datetimeValue": "2024-03-15T10:30:00Z",' +
            '"datetimeWithOffset": "2024-03-15T10:30:00+05:00",' +
            '"datetimeWithMillis": "2024-03-15T10:30:00.123Z",' +
            '"sections": {' +
                '"worksOverview": {' +
                    '"polesAdded": 5,' +
                    '"excavationRequired": true,' +
                    '"details": "Test details"' +
                '},' +
                '"location": {' +
                    '"routes": [' +
                        '{' +
                            '"routeName": "Route 1",' +
                            '"route_id": "R001",' +
                            '"gridPoints": [' +
                                '{"point_id": "P1", "easting": "123456", "northing": "654321"},' +
                                '{"point_id": "P2", "easting": "123457", "northing": "654322"}' +
                            ']' +
                        '},' +
                        '{' +
                            '"routeName": "Route 2",' +
                            '"route_id": "R002",' +
                            '"gridPoints": [' +
                                '{"point_id": "P3", "easting": "223456", "northing": "754321"}' +
                            ']' +
                        '}' +
                    ']' +
                '}' +
            '},' +
            '"simpleArray": ["item1", "item2", "item3"],' +
            '"nullValue": null' +
        '}';
    }
    
    // ========================================================================
    // CONSTRUCTOR TESTS
    // ========================================================================
    
    @IsTest
    static void testConstructor_ValidJson() {
        Test.startTest();
        InboundForm_JSONParser parser = new InboundForm_JSONParser(getTestJson());
        Test.stopTest();
        
        Assert.isNotNull(parser.getRootMap(), 'Root map should not be null');
        Assert.areEqual('S37', parser.getString('formType'), 'Form type should match');
    }
    
    @IsTest
    static void testConstructor_BlankJson() {
        Test.startTest();
        InboundForm_JSONParser parser = new InboundForm_JSONParser('');
        Test.stopTest();
        
        Assert.isNotNull(parser.getRootMap(), 'Root map should not be null for blank JSON');
        Assert.isTrue(parser.getRootMap().isEmpty(), 'Root map should be empty for blank JSON');
    }
    
    @IsTest
    static void testConstructor_NullJson() {
        Test.startTest();
        InboundForm_JSONParser parser = new InboundForm_JSONParser((String) null);
        Test.stopTest();
        
        Assert.isNotNull(parser.getRootMap(), 'Root map should not be null for null JSON');
        Assert.isTrue(parser.getRootMap().isEmpty(), 'Root map should be empty for null JSON');
    }
    
    @IsTest
    static void testConstructor_InvalidJson() {
        Test.startTest();
        try {
            InboundForm_JSONParser parser = new InboundForm_JSONParser('invalid json {{{');
            Assert.fail('Should have thrown exception for invalid JSON');
        } catch (InboundForm_JSONParser.JSONParserException e) {
            Assert.isTrue(e.getMessage().contains('Failed to parse JSON'), 
                'Exception message should indicate parse failure');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testConstructor_WithMap() {
        Map<String, Object> testMap = new Map<String, Object>{
            'key1' => 'value1',
            'key2' => 123
        };
        
        Test.startTest();
        InboundForm_JSONParser parser = new InboundForm_JSONParser(testMap);
        Test.stopTest();
        
        Assert.areEqual('value1', parser.getString('key1'), 'Should retrieve string value');
        Assert.areEqual(123, parser.getInteger('key2'), 'Should retrieve integer value');
    }
    
    @IsTest
    static void testConstructor_WithNullMap() {
        Test.startTest();
        InboundForm_JSONParser parser = new InboundForm_JSONParser((Map<String, Object>) null);
        Test.stopTest();
        
        Assert.isNotNull(parser.getRootMap(), 'Root map should not be null');
        Assert.isTrue(parser.getRootMap().isEmpty(), 'Root map should be empty');
    }
    
    // ========================================================================
    // GET VALUE TESTS
    // ========================================================================
    
    @IsTest
    static void testGetValue_TopLevel() {
        InboundForm_JSONParser parser = new InboundForm_JSONParser(getTestJson());
        
        Test.startTest();
        Object value = parser.getValue('formType');
        Test.stopTest();
        
        Assert.areEqual('S37', value, 'Should get top-level value');
    }
    
    @IsTest
    static void testGetValue_Nested() {
        InboundForm_JSONParser parser = new InboundForm_JSONParser(getTestJson());
        
        Test.startTest();
        Object value = parser.getValue('sections.worksOverview.polesAdded');
        Test.stopTest();
        
        Assert.areEqual(5, value, 'Should get nested value');
    }
    
    @IsTest
    static void testGetValue_ArrayAccess() {
        InboundForm_JSONParser parser = new InboundForm_JSONParser(getTestJson());
        
        Test.startTest();
        Object value = parser.getValue('sections.location.routes[0].routeName');
        Test.stopTest();
        
        Assert.areEqual('Route 1', value, 'Should get array element value');
    }
    
    @IsTest
    static void testGetValue_BlankPath() {
        InboundForm_JSONParser parser = new InboundForm_JSONParser(getTestJson());
        
        Test.startTest();
        Object value = parser.getValue('');
        Test.stopTest();
        
        Assert.isNull(value, 'Should return null for blank path');
    }
    
    @IsTest
    static void testGetValue_NonExistentPath() {
        InboundForm_JSONParser parser = new InboundForm_JSONParser(getTestJson());
        
        Test.startTest();
        Object value = parser.getValue('nonexistent.path');
        Test.stopTest();
        
        Assert.isNull(value, 'Should return null for non-existent path');
    }
    
    // ========================================================================
    // GET STRING TESTS
    // ========================================================================
    
    @IsTest
    static void testGetString_ValidPath() {
        InboundForm_JSONParser parser = new InboundForm_JSONParser(getTestJson());
        
        Test.startTest();
        String value = parser.getString('stringValue');
        Test.stopTest();
        
        Assert.areEqual('test string', value, 'Should get string value');
    }
    
    @IsTest
    static void testGetString_NumericValue() {
        InboundForm_JSONParser parser = new InboundForm_JSONParser(getTestJson());
        
        Test.startTest();
        String value = parser.getString('integerValue');
        Test.stopTest();
        
        Assert.areEqual('42', value, 'Should convert numeric to string');
    }
    
    @IsTest
    static void testGetString_NullValue() {
        InboundForm_JSONParser parser = new InboundForm_JSONParser(getTestJson());
        
        Test.startTest();
        String value = parser.getString('nullValue');
        Test.stopTest();
        
        Assert.isNull(value, 'Should return null for null value');
    }
    
    // ========================================================================
    // GET INTEGER TESTS
    // ========================================================================
    
    @IsTest
    static void testGetInteger_ValidInteger() {
        InboundForm_JSONParser parser = new InboundForm_JSONParser(getTestJson());
        
        Test.startTest();
        Integer value = parser.getInteger('integerValue');
        Test.stopTest();
        
        Assert.areEqual(42, value, 'Should get integer value');
    }
    
    @IsTest
    static void testGetInteger_FromDecimal() {
        InboundForm_JSONParser parser = new InboundForm_JSONParser(getTestJson());
        
        Test.startTest();
        Integer value = parser.getInteger('decimalValue');
        Test.stopTest();
        
        Assert.areEqual(123, value, 'Should convert decimal to integer');
    }
    
    @IsTest
    static void testGetInteger_FromString() {
        String json = '{"stringInt": "99"}';
        InboundForm_JSONParser parser = new InboundForm_JSONParser(json);
        
        Test.startTest();
        Integer value = parser.getInteger('stringInt');
        Test.stopTest();
        
        Assert.areEqual(99, value, 'Should parse string to integer');
    }
    
    @IsTest
    static void testGetInteger_InvalidString() {
        String json = '{"invalid": "not a number"}';
        InboundForm_JSONParser parser = new InboundForm_JSONParser(json);
        
        Test.startTest();
        Integer value = parser.getInteger('invalid');
        Test.stopTest();
        
        Assert.isNull(value, 'Should return null for invalid string');
    }
    
    // ========================================================================
    // GET DECIMAL TESTS
    // ========================================================================
    
    @IsTest
    static void testGetDecimal_ValidDecimal() {
        InboundForm_JSONParser parser = new InboundForm_JSONParser(getTestJson());
        
        Test.startTest();
        Decimal value = parser.getDecimal('decimalValue');
        Test.stopTest();
        
        Assert.areEqual(123.45, value, 'Should get decimal value');
    }
    
    @IsTest
    static void testGetDecimal_FromInteger() {
        InboundForm_JSONParser parser = new InboundForm_JSONParser(getTestJson());
        
        Test.startTest();
        Decimal value = parser.getDecimal('integerValue');
        Test.stopTest();
        
        Assert.areEqual(42, value, 'Should convert integer to decimal');
    }
    
    @IsTest
    static void testGetDecimal_FromString() {
        String json = '{"stringDec": "45.67"}';
        InboundForm_JSONParser parser = new InboundForm_JSONParser(json);
        
        Test.startTest();
        Decimal value = parser.getDecimal('stringDec');
        Test.stopTest();
        
        Assert.areEqual(45.67, value, 'Should parse string to decimal');
    }
    
    // ========================================================================
    // GET BOOLEAN TESTS
    // ========================================================================
    
    @IsTest
    static void testGetBoolean_TrueValue() {
        InboundForm_JSONParser parser = new InboundForm_JSONParser(getTestJson());
        
        Test.startTest();
        Boolean value = parser.getBoolean('booleanTrue');
        Test.stopTest();
        
        Assert.isTrue(value, 'Should get true boolean');
    }
    
    @IsTest
    static void testGetBoolean_FalseValue() {
        InboundForm_JSONParser parser = new InboundForm_JSONParser(getTestJson());
        
        Test.startTest();
        Boolean value = parser.getBoolean('booleanFalse');
        Test.stopTest();
        
        Assert.isFalse(value, 'Should get false boolean');
    }
    
    @IsTest
    static void testGetBoolean_YesString() {
        InboundForm_JSONParser parser = new InboundForm_JSONParser(getTestJson());
        
        Test.startTest();
        Boolean value = parser.getBoolean('booleanYes');
        Test.stopTest();
        
        Assert.isTrue(value, 'Should convert "yes" to true');
    }
    
    @IsTest
    static void testGetBoolean_NoString() {
        InboundForm_JSONParser parser = new InboundForm_JSONParser(getTestJson());
        
        Test.startTest();
        Boolean value = parser.getBoolean('booleanNo');
        Test.stopTest();
        
        Assert.isFalse(value, 'Should convert "no" to false');
    }
    
    @IsTest
    static void testGetBoolean_OneString() {
        String json = '{"val": "1"}';
        InboundForm_JSONParser parser = new InboundForm_JSONParser(json);
        
        Test.startTest();
        Boolean value = parser.getBoolean('val');
        Test.stopTest();
        
        Assert.isTrue(value, 'Should convert "1" to true');
    }
    
    // ========================================================================
    // GET DATE TESTS
    // ========================================================================
    
    @IsTest
    static void testGetDate_ValidDate() {
        InboundForm_JSONParser parser = new InboundForm_JSONParser(getTestJson());
        
        Test.startTest();
        Date value = parser.getDate('dateValue');
        Test.stopTest();
        
        Assert.areEqual(Date.newInstance(2024, 3, 15), value, 'Should parse date');
    }
    
    @IsTest
    static void testGetDate_FromDatetime() {
        InboundForm_JSONParser parser = new InboundForm_JSONParser(getTestJson());
        
        Test.startTest();
        Date value = parser.getDate('datetimeValue');
        Test.stopTest();
        
        Assert.areEqual(Date.newInstance(2024, 3, 15), value, 
            'Should extract date from datetime');
    }
    
    @IsTest
    static void testGetDate_InvalidFormat() {
        String json = '{"bad": "not-a-date"}';
        InboundForm_JSONParser parser = new InboundForm_JSONParser(json);
        
        Test.startTest();
        Date value = parser.getDate('bad');
        Test.stopTest();
        
        Assert.isNull(value, 'Should return null for invalid date format');
    }
    
    // ========================================================================
    // GET DATETIME TESTS
    // ========================================================================
    
    @IsTest
    static void testGetDateTime_ValidISO() {
        InboundForm_JSONParser parser = new InboundForm_JSONParser(getTestJson());
        
        Test.startTest();
        DateTime value = parser.getDateTime('datetimeValue');
        Test.stopTest();
        
        Assert.isNotNull(value, 'Should parse ISO datetime');
        Assert.areEqual(2024, value.yearGmt(), 'Year should match');
        Assert.areEqual(3, value.monthGmt(), 'Month should match');
        Assert.areEqual(15, value.dayGmt(), 'Day should match');
    }
    
    @IsTest
    static void testGetDateTime_WithOffset() {
        InboundForm_JSONParser parser = new InboundForm_JSONParser(getTestJson());
        
        Test.startTest();
        DateTime value = parser.getDateTime('datetimeWithOffset');
        Test.stopTest();
        
        Assert.isNotNull(value, 'Should parse datetime with offset');
    }
    
    @IsTest
    static void testGetDateTime_WithMilliseconds() {
        InboundForm_JSONParser parser = new InboundForm_JSONParser(getTestJson());
        
        Test.startTest();
        DateTime value = parser.getDateTime('datetimeWithMillis');
        Test.stopTest();
        
        Assert.isNotNull(value, 'Should parse datetime with milliseconds');
    }
    
    // ========================================================================
    // GET LIST TESTS
    // ========================================================================
    
    @IsTest
    static void testGetList_ValidArray() {
        InboundForm_JSONParser parser = new InboundForm_JSONParser(getTestJson());
        
        Test.startTest();
        List<Object> value = parser.getList('simpleArray');
        Test.stopTest();
        
        Assert.areEqual(3, value.size(), 'Should have 3 items');
        Assert.areEqual('item1', value[0], 'First item should match');
    }
    
    @IsTest
    static void testGetList_NonArrayPath() {
        InboundForm_JSONParser parser = new InboundForm_JSONParser(getTestJson());
        
        Test.startTest();
        List<Object> value = parser.getList('formType');
        Test.stopTest();
        
        Assert.isTrue(value.isEmpty(), 'Should return empty list for non-array');
    }
    
    // ========================================================================
    // GET OBJECT LIST TESTS
    // ========================================================================
    
    @IsTest
    static void testGetObjectList_ValidArray() {
        InboundForm_JSONParser parser = new InboundForm_JSONParser(getTestJson());
        
        Test.startTest();
        List<Map<String, Object>> routes = parser.getObjectList('sections.location.routes');
        Test.stopTest();
        
        Assert.areEqual(2, routes.size(), 'Should have 2 routes');
        Assert.areEqual('Route 1', routes[0].get('routeName'), 'First route name should match');
    }
    
    // ========================================================================
    // HAS VALUE TESTS
    // ========================================================================
    
    @IsTest
    static void testHasValue_ExistingPath() {
        InboundForm_JSONParser parser = new InboundForm_JSONParser(getTestJson());
        
        Test.startTest();
        Boolean hasValue = parser.hasValue('formType');
        Test.stopTest();
        
        Assert.isTrue(hasValue, 'Should have value for existing path');
    }
    
    @IsTest
    static void testHasValue_NullPath() {
        InboundForm_JSONParser parser = new InboundForm_JSONParser(getTestJson());
        
        Test.startTest();
        Boolean hasValue = parser.hasValue('nullValue');
        Test.stopTest();
        
        Assert.isFalse(hasValue, 'Should not have value for null path');
    }
    
    @IsTest
    static void testHasValue_NonExistentPath() {
        InboundForm_JSONParser parser = new InboundForm_JSONParser(getTestJson());
        
        Test.startTest();
        Boolean hasValue = parser.hasValue('nonexistent');
        Test.stopTest();
        
        Assert.isFalse(hasValue, 'Should not have value for non-existent path');
    }
    
    // ========================================================================
    // ARRAY ACCESS EDGE CASES
    // ========================================================================
    
    @IsTest
    static void testArrayAccess_OutOfBounds() {
        InboundForm_JSONParser parser = new InboundForm_JSONParser(getTestJson());
        
        Test.startTest();
        Object value = parser.getValue('sections.location.routes[99].routeName');
        Test.stopTest();
        
        Assert.isNull(value, 'Should return null for out of bounds index');
    }
    
    @IsTest
    static void testArrayAccess_NegativeIndex() {
        InboundForm_JSONParser parser = new InboundForm_JSONParser(getTestJson());
        
        Test.startTest();
        Object value = parser.getValue('sections.location.routes[-1].routeName');
        Test.stopTest();
        
        Assert.isNull(value, 'Should return null for negative index');
    }
    
    @IsTest
    static void testArrayAccess_InvalidIndexFormat() {
        InboundForm_JSONParser parser = new InboundForm_JSONParser(getTestJson());
        
        Test.startTest();
        Object value = parser.getValue('sections.location.routes[abc].routeName');
        Test.stopTest();
        
        Assert.isNull(value, 'Should return null for invalid index format');
    }
}