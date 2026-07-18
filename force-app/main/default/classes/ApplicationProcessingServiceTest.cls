@isTest
private class ApplicationProcessingServiceTest {

    @isTest
    static void test_createsOpportunityByFederalTaxId() {
        Account acc = new Account(Name = 'Acme Corp', Federal_Tax_Id__c = '12-3456789');
        insert acc;
        System.debug('Account created: ' + acc.Id + ', Federal Tax ID: ' + acc.Federal_Tax_Id__c);

        ApplicationWrapper.ApplicationDTO dto = buildDto();

        Test.startTest();
            ApplicationWrapper.ApplicationResult result = ApplicationProcessingService.processApplication(dto);
        Test.stopTest();

        System.assertEquals(true, result.success, 'Result should indicate success');
        System.assertEquals('Opportunity', result.recordType);
        System.assertNotEquals(null, result.recordId);

    }

    @isTest
    static void test_createsOpportunityByExactName() {
        Account acc = new Account(Name = 'Beta Industries');
        insert acc;

        ApplicationWrapper.ApplicationDTO dto = buildDto();
        dto.companyName = 'Beta Industries';
        dto.federalTaxId = '99-9999999';

        Test.startTest();
            ApplicationWrapper.ApplicationResult result = ApplicationProcessingService.processApplication(dto);
        Test.stopTest();

        System.assertEquals('Opportunity', result.recordType);
        Opportunity opp = [SELECT AccountId FROM Opportunity WHERE Id = :result.recordId];
        System.assertEquals(acc.Id, opp.AccountId);
    }

    @isTest
    static void test_createsLead() {
        ApplicationWrapper.ApplicationDTO dto = buildDto();
        dto.companyName = 'Nonexistent Co';
        dto.federalTaxId = '00-0000000';

        Test.startTest();
        ApplicationWrapper.ApplicationResult result = ApplicationProcessingService.processApplication(dto);
        Test.stopTest();

        System.assertEquals(true, result.success);
        System.assertEquals('Lead', result.recordType);

        Lead ld = [SELECT Company, Email, Phone, Federal_Tax_Id__c, Application_Source__c FROM Lead WHERE Id = :result.recordId];
        System.assertEquals(dto.companyName, ld.Company);
        System.assertEquals(dto.email, ld.Email);
        System.assertEquals(dto.phone, ld.Phone);
        System.assertEquals(dto.federalTaxId, ld.Federal_Tax_Id__c);
        System.assertEquals(dto.applicationSource, ld.Application_Source__c);
    }

    @isTest
    static void test_controllerSubmitApplicationCreatesLead() {
        ApplicationWrapper.ApplicationDTO dto = buildDto();
        dto.companyName = 'Nonexistent Co';
        dto.federalTaxId = '00-0000000';

        Test.startTest();
            ApplicationWrapper.ApplicationResult result = ApplicationFormController.submitApplication(dto);
        Test.stopTest();

        System.assertEquals(true, result.success, 'Result should indicate success');
        System.assertEquals('Lead', result.recordType);
        System.assertNotEquals(null, result.recordId);
    }

    private static ApplicationWrapper.ApplicationDTO buildDto() {
        ApplicationWrapper.ApplicationDTO dto = new ApplicationWrapper.ApplicationDTO();
        dto.companyName = 'Test Company';
        dto.federalTaxId = '12-3456789';
        dto.contactFirstName = 'John';
        dto.contactLastName = 'Doe';
        dto.email = 'john.doe@example.com';
        dto.phone = '555-1234';
        dto.annualRevenue = 100000;
        dto.applicationSource = 'Community';
        return dto;
    }
}
