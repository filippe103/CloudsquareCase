@isTest
private class ApplicationWebhookTest {

    @isTest
    static void test_missingRequest_returnsBadRequest() {
        RestContext.response = new RestResponse();

        Test.startTest();
            ApplicationWrapper.ApplicationResult result = ApplicationWebhook.handlePost();
        Test.stopTest();

        System.assertEquals(false, result.success);
        System.assertEquals('Request body is required.', result.message);
        System.assertEquals(400, RestContext.response.statusCode);
    }

    @isTest
    static void test_malformedJson_returnsBadRequest() {
        setupRequest(Blob.valueOf('{ this is not valid json'));

        Test.startTest();
            ApplicationWrapper.ApplicationResult result = ApplicationWebhook.handlePost();
        Test.stopTest();

        System.assertEquals(false, result.success);
        System.assert(result.message.startsWith('Malformed JSON payload:'));
        System.assertEquals(400, RestContext.response.statusCode);
    }

    @isTest
    static void test_missingCompanyName_returnsValidationError() {
        setupRequest(buildPayloadJson('', '12-3456789', 'John', 'Doe', 'john.doe@example.com'));

        Test.startTest();
            ApplicationWrapper.ApplicationResult result = ApplicationWebhook.handlePost();
        Test.stopTest();

        System.assertEquals(false, result.success);
        System.assert(result.message.contains('companyName is required'));
        System.assertEquals(400, RestContext.response.statusCode);
    }

    

    @isTest
    static void test_validPayload_noMatchingAccount_createsLead() {
        setupRequest(buildPayloadJson('Nonexistent Co', '00-0000000', 'John', 'Doe', 'john.doe@example.com'));

        Test.startTest();
            ApplicationWrapper.ApplicationResult result = ApplicationWebhook.handlePost();
        Test.stopTest();

        System.assertEquals(true, result.success);
        System.assertEquals('Lead', result.recordType);
        System.assertNotEquals(null, result.recordId);
        System.assertEquals(201, RestContext.response.statusCode);

        Lead ld = [SELECT Company, Email, Federal_Tax_Id__c, Application_Source__c FROM Lead WHERE Id = :result.recordId];
        System.assertEquals('Nonexistent Co', ld.Company);
        System.assertEquals('john.doe@example.com', ld.Email);
        System.assertEquals('00-0000000', ld.Federal_Tax_Id__c);
        System.assertEquals('Webhook', ld.Application_Source__c);
    }

    @isTest
    static void test_validPayload_matchingAccount_createsOpportunity() {
        Account acc = new Account(Name = 'Acme Corp', Federal_Tax_Id__c = '12-3456789');
        insert acc;

        setupRequest(buildPayloadJson('Acme Corp', '12-3456789', 'John', 'Doe', 'john.doe@example.com'));

        Test.startTest();
            ApplicationWrapper.ApplicationResult result = ApplicationWebhook.handlePost();
        Test.stopTest();

        System.assertEquals(true, result.success);
        System.assertEquals('Opportunity', result.recordType);
        System.assertEquals(201, RestContext.response.statusCode);

        Opportunity opp = [SELECT AccountId, Application_Source__c FROM Opportunity WHERE Id = :result.recordId];
        System.assertEquals(acc.Id, opp.AccountId);
        System.assertEquals('Webhook', opp.Application_Source__c);
    }

    private static void setupRequest(Blob body) {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/external/applications/';
        req.httpMethod = 'POST';
        req.requestBody = body;
        RestContext.request = req;
        RestContext.response = new RestResponse();
    }

    private static Blob buildPayloadJson(String companyName, String federalTaxId, String firstName, String lastName, String email) {
        Map<String, Object> contact = new Map<String, Object>{
            'firstName' => firstName,
            'lastName' => lastName,
            'email' => email,
            'phone' => '555-1234'
        };
        Map<String, Object> body = new Map<String, Object>{
            'companyName' => companyName,
            'federalTaxId' => federalTaxId,
            'contact' => contact,
            'annualRevenue' => 100000
        };
        return Blob.valueOf(JSON.serialize(body));
    }
}
