public with sharing class BusinessDaysCalculator {

    public class Request {
        @InvocableVariable(required=true)
        public Integer businessDays;
    }

    public class Response {
        @InvocableVariable
        public Date businessDaysAgo;
    }

    @InvocableMethod(label='Calculate Date N Business Days Ago'
                     description='Returns the datetime after subtracting the specified business days using Salesforce Business Hours.')
    public static List<Response> calculate(List<Request> requests) {

        Id businessHoursId = [
            SELECT Id
            FROM BusinessHours
            WHERE IsDefault = true
            LIMIT 1
        ].Id;

        List<Response> results = new List<Response>();

        for (Request req : requests) {

            Response res = new Response();

            Long milliseconds =
                req.businessDays * 24L * 60L * 60L * 1000L;

            res.businessDaysAgo = BusinessHours.add(
                businessHoursId,
                System.now(),
                -milliseconds
            ).Date();

            results.add(res);
        }

        return results;
    }
}