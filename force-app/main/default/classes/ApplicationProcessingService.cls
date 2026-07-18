public without sharing class ApplicationProcessingService {

    public static ApplicationWrapper.ApplicationResult processApplication(ApplicationWrapper.ApplicationDTO app){
        ApplicationWrapper.ApplicationResult result = new ApplicationWrapper.ApplicationResult();

        List<Account> accountsByFederalTaxId = [SELECT Id FROM Account WHERE Federal_Tax_Id__c = :app.federalTaxId LIMIT 1];
        Account existingAccount = accountsByFederalTaxId.isEmpty() ? findAccountByExactName(app.companyName) : accountsByFederalTaxId[0];

        try {
            if (existingAccount != null) {
                Opportunity opportunityCreated = createOpportunity(app, existingAccount);
                result.recordId = opportunityCreated.Id;
                result.recordType = 'Opportunity';
            } else {
                Lead leadCreated = createLead(app);
                result.recordId = leadCreated.Id;
                result.recordType = 'Lead';
            }

            result.success = true;
            result.message = 'Application processed successfully.';
        } catch (Exception ex) {
            System.debug('Error processing application: ' + ex.getMessage());
            result.success = false;
            result.message = 'Error processing application: ' +  ex.getMessage();
        }

        return result;
    }

    private static Account findAccountByExactName(String companyName) {
        for (Account acc : [SELECT Id, Name FROM Account WHERE Name = :companyName LIMIT 200]) {
            if (acc.Name.equals(companyName)) {
                return acc;
            }
        }
        return null;
    }

    private static Opportunity createOpportunity(ApplicationWrapper.ApplicationDTO app, Account account) {
        Opportunity newOpp = new Opportunity();
        newOpp.Name = app.companyName + ' - New Application';
        newOpp.StageName = 'Prospecting';
        newOpp.CloseDate = Date.today().addDays(30);
        newOpp.AccountId = account.Id;
        newOpp.Application_Source__c = app.applicationSource;
        insert newOpp;

        return newOpp;
    }

    private static Lead createLead(ApplicationWrapper.ApplicationDTO app) {
        Lead newLead = new Lead();
        newLead.FirstName = app.contactFirstName;
        newLead.LastName = app.contactLastName;
        newLead.Email = app.email;
        newLead.Phone = app.phone;
        newLead.Company = app.companyName;
        newLead.Federal_Tax_Id__c = app.federalTaxId;
        newLead.Application_Source__c = app.applicationSource;
        insert newLead;

        return newLead;
    }
}