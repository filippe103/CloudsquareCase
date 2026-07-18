@RestResource(urlMapping='/external/applications/*')
global without sharing class ApplicationWebhook {

    @HttpPost
    global static ApplicationWrapper.ApplicationResult handlePost() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        ApplicationWrapper.ApplicationResult output = new ApplicationWrapper.ApplicationResult();

        try {
            if (req == null || req.requestBody == null || req.requestBody.size() == 0) {
                res.statusCode = 400;
                output.success = false;
                output.message = 'Request body is required.';
                return output;
            }

            ApplicationPayload payload;
            try {
                payload = (ApplicationPayload) JSON.deserialize(req.requestBody.toString(), ApplicationPayload.class);
            } catch (Exception ex) {
                res.statusCode = 400;
                output.success = false;
                output.message = 'Malformed JSON payload: ' + ex.getMessage();
                return output;
            }

            List<String> validationErrors = validate(payload);
            if (!validationErrors.isEmpty()) {
                res.statusCode = 400;
                output.success = false;
                output.message = 'Validation failed: ' + String.join(validationErrors, '; ');
                return output;
            }

            output = processApplication(payload);
            res.statusCode = (output.success == true) ? 201 : 400;

        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'ApplicationWebhook error: ' + ex.getMessage() + ' ' + ex.getStackTraceString());
            res.statusCode = 500;
            output.success = false;
            output.message = 'An unexpected error occurred while processing the request: ' + ex.getMessage();
        }

        return output;
    }

    private static ApplicationWrapper.ApplicationResult processApplication(ApplicationPayload payload) {
        ApplicationWrapper.ApplicationDTO dto = new ApplicationWrapper.ApplicationDTO();
        dto.companyName      = payload.companyName;
        dto.federalTaxId     = payload.federalTaxId;
        dto.contactFirstName = payload.contact.firstName;
        dto.contactLastName  = payload.contact.lastName;
        dto.email            = payload.contact.email;
        dto.phone            = payload.contact.phone;
        dto.annualRevenue    = payload.annualRevenue;
        dto.applicationSource  = 'Webhook';

        ApplicationWrapper.ApplicationResult result = ApplicationProcessingService.processApplication(dto);
        return result;
    }

    private static List<String> validate(ApplicationPayload payload) {
        List<String> errors = new List<String>();

        if (payload == null) {
            errors.add('payload is required');
            return errors;
        }

        if (String.isBlank(payload.companyName)) errors.add('companyName is required');
        if (String.isBlank(payload.federalTaxId)) errors.add('federalTaxId is required');

        if (payload.contact == null) {
            errors.add('contact is required');
        } else {
            if (String.isBlank(payload.contact.firstName)) errors.add('contact.firstName is required');
            if (String.isBlank(payload.contact.lastName)) errors.add('contact.lastName is required');
            if (String.isBlank(payload.contact.email) || !isValidEmail(payload.contact.email)) {
                errors.add('contact.email is required and must be a valid email address');
            }
        }

        return errors;
    }

    private static Boolean isValidEmail(String email) {
        return Pattern.matches('^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$', email);
    }

    global class ApplicationPayload {
        global String companyName;
        global String federalTaxId;
        global ContactPayload contact;
        global Decimal annualRevenue;
    }

    global class ContactPayload {
        global String firstName;
        global String lastName;
        global String email;
        global String phone;
    }
    
}
