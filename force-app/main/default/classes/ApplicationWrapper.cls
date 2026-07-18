global class ApplicationWrapper {

    global class ApplicationResult {
        @AuraEnabled global Boolean success {get; set;}
        @AuraEnabled global String recordType {get; set;}
        @AuraEnabled global String recordId {get; set;}
        @AuraEnabled global String message {get; set;}
    }

    public class ApplicationDTO {
        @AuraEnabled public String companyName {get; set;}
        @AuraEnabled public String federalTaxId {get; set;}
        @AuraEnabled public String contactFirstName {get; set;}
        @AuraEnabled public String contactLastName {get; set;}
        @AuraEnabled public String email {get; set;}
        @AuraEnabled public String phone {get; set;}
        @AuraEnabled public Decimal annualRevenue {get; set;}
        @AuraEnabled public String applicationSource {get; set;}
    }
}
