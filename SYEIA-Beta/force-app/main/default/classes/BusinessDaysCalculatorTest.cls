@IsTest
private class BusinessDaysCalculatorTest {

    @TestSetup
    static void setup() {
        // Make sure there is a default Business Hours record.
        // Salesforce orgs normally have one already, but we query it
        // rather than creating one because IsDefault is system-controlled.
        BusinessHours bh = [
            SELECT Id
            FROM BusinessHours
            WHERE IsDefault = true
            LIMIT 1
        ];

        System.assertNotEquals(
            null,
            bh.Id,
            'A default Business Hours record is required for this test.'
        );
    }

    @IsTest
    static void testCalculateOneBusinessDay() {

        BusinessDaysCalculator.Request request =
            new BusinessDaysCalculator.Request();

        request.businessDays = 1;

        Test.startTest();

        List<BusinessDaysCalculator.Response> results =
            BusinessDaysCalculator.calculate(
                new List<BusinessDaysCalculator.Request>{ request }
            );

        Test.stopTest();

        System.assertEquals(
            1,
            results.size(),
            'One response should be returned.'
        );

        System.assertNotEquals(
            null,
            results[0].businessDaysAgo,
            'businessDaysAgo should not be null.'
        );

        System.assert(
            results[0].businessDaysAgo < Date.today(),
            'The calculated date should be before today.'
        );
    }


    @IsTest
    static void testCalculateMultipleRequests() {

        BusinessDaysCalculator.Request request1 =
            new BusinessDaysCalculator.Request();
        request1.businessDays = 1;

        BusinessDaysCalculator.Request request2 =
            new BusinessDaysCalculator.Request();
        request2.businessDays = 2;

        BusinessDaysCalculator.Request request3 =
            new BusinessDaysCalculator.Request();
        request3.businessDays = 5;

        Test.startTest();

        List<BusinessDaysCalculator.Response> results =
            BusinessDaysCalculator.calculate(
                new List<BusinessDaysCalculator.Request>{
                    request1,
                    request2,
                    request3
                }
            );

        Test.stopTest();

        System.assertEquals(
            3,
            results.size(),
            'There should be one response for each request.'
        );

        for (BusinessDaysCalculator.Response result : results) {
            System.assertNotEquals(
                null,
                result.businessDaysAgo,
                'Each response should contain a date.'
            );
        }

        System.assert(
            results[0].businessDaysAgo > results[1].businessDaysAgo,
            'Subtracting more business days should produce an earlier date.'
        );

        System.assert(
            results[1].businessDaysAgo > results[2].businessDaysAgo,
            'Subtracting more business days should produce an earlier date.'
        );
    }


    @IsTest
    static void testZeroBusinessDays() {

        BusinessDaysCalculator.Request request =
            new BusinessDaysCalculator.Request();

        request.businessDays = 0;

        Test.startTest();

        List<BusinessDaysCalculator.Response> results =
            BusinessDaysCalculator.calculate(
                new List<BusinessDaysCalculator.Request>{ request }
            );

        Test.stopTest();

        System.assertEquals(1, results.size());

        System.assertEquals(
            Date.today(),
            results[0].businessDaysAgo,
            'Zero business days should return today.'
        );
    }
}