import { LightningElement } from 'lwc';
import submitApplication from '@salesforce/apex/ApplicationFormController.submitApplication';

export default class ApplicationForm extends LightningElement {
    isLoading = false;
    showBanner = false;
    bannerMessage = '';
    bannerVariant = 'success';

    get bannerClass() {
        const theme = this.bannerVariant === 'success' ? 'slds-theme_success' : 'slds-theme_error';
        return `slds-notify slds-notify_alert slds-theme_alert-texture ${theme}`;
    }

    handleCloseBanner() {
        this.showBanner = false;
    }

    handleSubmit() {
        this.isLoading = true;

        const inputs = [...this.template.querySelectorAll('lightning-input')];

        const allValid = inputs.reduce((valid, input) => {
            input.reportValidity();
            return valid && input.checkValidity();
        }, true);

        if (!allValid) {
            this.isLoading = false;
            return;
        }

        const formValues = {};
        inputs.forEach((input) => {
            formValues[input.name] = input.type === 'number' && input.value !== ''
                ? Number(input.value)
                : input.value;
        });
        formValues.applicationSource = 'Community';

        submitApplication({ input: formValues })
        .then(result => {
            console.log('result:', result);
            this.isLoading = false;
            if (result.success) {
                this.showResultMessage('Success', `Application submitted successfully! Record Type: ${result.recordType}, Record Id: ${result.recordId}`, 'success');
            } else {
                this.showResultMessage('Error', 'An error occurred while submitting the application.', 'error');
            }
        })
        .catch(error => {
            console.error('Error submitting application:', error);
            this.showResultMessage('Error', 'An error occurred while submitting the application.', 'error');
        });
    }
    
    showResultMessage(title, message, variant){
        this.bannerVariant = variant;
        this.bannerMessage = `${title}: ${message}`;
        this.showBanner = true;
    }
}