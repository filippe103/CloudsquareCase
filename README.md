# Application Form Case (CloudSquare)

This project implements a **new business application intake flow** that automatically decides whether to create a **Lead** or an **Opportunity**, depending on whether the applying company already exists as an Account in Salesforce. The flow has two entry points: a public form on the **CloudSquare** Experience Site and a REST endpoint (webhook) for external systems.


## Components

| Component | File | Responsibility |
|---|---|---|
| **Wrapper** | [ApplicationWrapper.cls](force-app/main/default/classes/ApplicationWrapper.cls) | Defines the data contracts: `ApplicationDTO` (input, used by both the LWC and the webhook) and `ApplicationResult` (standardized output with `success`, `recordType`, `recordId`, `message`). |
| **Service** | [ApplicationProcessingService.cls](force-app/main/default/classes/ApplicationProcessingService.cls) | Core business rule: looks up an Account by `Federal_Tax_Id__c` (falling back to an exact company name match); if found, creates a linked `Opportunity`, otherwise creates a `Lead`. |
| **Controller** | [ApplicationFormController.cls](force-app/main/default/classes/ApplicationFormController.cls) | `@AuraEnabled` bridge between the LWC and the Service, used by the form on the Experience Site. |
| **Webhook** | [ApplicationWebhook.cls](force-app/main/default/classes/ApplicationWebhook.cls) | REST resource (`/services/apexrest/external/applications/*`) that accepts JSON from external systems, validates the payload, and delegates to the Service. Returns 201 on success, 400 for invalid/malformed payloads, and 500 for unexpected errors. |
| **LWC** | [applicationForm](force-app/main/default/lwc/applicationForm/) | Form rendered on the site, with client-side validation (`reportValidity`/`checkValidity`), a loading spinner, and a success/error banner. Sets `applicationSource = 'Community'` before submitting. |
| **Tests** | `ApplicationProcessingServiceTest.cls`, `ApplicationWebhookTest.cls` | Cover all three business paths (match by Tax ID, match by exact name, Lead creation) and the webhook's error scenarios (empty request, malformed JSON, validation failures, success). |

### Custom fields used
- `Account.Federal_Tax_Id__c` — primary matching key to decide Lead vs. Opportunity.
- `Lead.Federal_Tax_Id__c` and `Lead.Application_Source__c` — populated when a Lead is created.
- `Opportunity.Application_Source__c` — populated when an Opportunity is created.

`applicationSource` is set to `'Community'` by the LWC and `'Webhook'` by the `ApplicationWebhook` class, so the created records can be traced back to their origin.

## Experience Site and Guest User configuration

- **Site**: CloudSquare
- **Page**: `cloudsquare-form` (where the `applicationForm` component was added via Experience Builder)
- **URL**: `https://resilient-badger-knsr1i-dev-ed.trailblaze.my.site.com/CloudSquare/cloudsquare-form`

For the form to work for anonymous (Guest) users, the following was granted on the site's **Guest User Profile**:

- **Lead**: **Create** permission, including the `Federal_Tax_Id__c` and `Application_Source__c` fields.
- **Opportunity**: **Create** permission, including the `Application_Source__c` field.
- **Apex classes**: access to `ApplicationFormController` (and, transitively, the classes it calls) was granted **directly on the Guest User Profile** of the site — no dedicated Permission Set was used.

> **Security note**: since `ApplicationFormController` and `ApplicationProcessingService` are both declared `without sharing`, Account/Lead/Opportunity access via Apex bypasses sharing rules — the real access control lives entirely in the Guest Profile's object/field permissions listed above. Worth periodically reviewing that this profile hasn't accumulated more access than it needs.

## External webhook

The `POST /services/apexrest/external/applications/` endpoint was created to receive the payload and also execute the business requirement.

Expected payload:
```json
{
  "companyName": "Acme Corp",
  "federalTaxId": "12-3456789",
  "contact": {
    "firstName": "John",
    "lastName": "Doe",
    "email": "john.doe@example.com",
    "phone": "555-1234"
  },
  "annualRevenue": 100000
}
```
