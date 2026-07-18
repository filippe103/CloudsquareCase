public without sharing class ApplicationFormController {
    
    @AuraEnabled
    public static ApplicationWrapper.ApplicationResult submitApplication(ApplicationWrapper.ApplicationDTO input){
        ApplicationWrapper.ApplicationResult result = ApplicationProcessingService.processApplication(input);
        return result;
    }
}