# eForms SDK NOR

This repository contains the resources used to create a modified edition of the official eForms SDK distribution with modifications for the Norwegian market.

Please see the [releases page](https://github.com/anskaffelser/eforms-sdk-nor/releases) to download modified distributions of the [official eForms SDK](https://github.com/OP-TED/eForms-SDK) for use in the Norwegian market. For all documentation of how to use and interpret eForms please refer to the [official eForms documentation](https://docs.ted.europa.eu/home/index.html).

## The Doffin API

The Doffin API is available at the following endpoints:
* For testing and development: [https://dof-notices-dev-api.developer.azure-api.net/](https://dof-notices-dev-api.developer.azure-api.net/)
* For production: [https://dof-notices-prod-api.developer.azure-api.net/](https://dof-notices-prod-api.developer.azure-api.net/)

These are hosted as two independent systems, so you need to register for each environment that you want to access. For example, to start using using the test/dev API's you first have to [sign up](https://dof-notices-dev-api.developer.azure-api.net/signup) as a user, log in and [create one or more subscriptions](https://dof-notices-dev-api.developer.azure-api.net/profile).

Each endpoint provides two APIs:
* [Notices API](https://dof-notices-dev-api.developer.azure-api.net/api-details#api=eform-api&operation=645cce8e4ffd2d6d5768181e) used to submit, stop, validate and translate notices. This API mimics the [TED API](https://docs.ted.europa.eu/api/index.html) as closely as possible.
* [Public API](https://dof-notices-dev-api.developer.azure-api.net/api-details#api=public-api&operation=65015b9b566f983bdcfcaee7) used to search for and download published notices.

### Important regarding the Notices API
Once you have created a subscription for the Notices API please contact [ingunn.ostrem@dfo.no](mailto:ingunn.ostrem@dfo.no) to get the subscription activated.

For now we are not returning any validation results. Please make sure that you are using valid and well-formed eForms messages before testing the integration. To test for validity and well-formness during development please use:
* our online [validator tool] (https://anskaffelser.dev/service/validator/)
  For development and production environments we strongly recommend:
* the validation function in the Notices API
* or a local validator service, i.e. [based on our code](https://github.com/anskaffelser/vefa-validator).  

Please note that eForms messages using these extensions will fail validation in TED unless you pre-process with using the xslt-filter provided in this repository. 

The endpoint supports the eForms-versions included in the newest release of this repository. 

## Why do we need a Norwegian SDK? 

This SDK completes the official SDK with two extensions needed for the Norwegian market: 

* Norwegian is not an official EU language and is hence not part of the official TED SDK distribution. This SDK adds Norwegian translations where needed as well as validation rules to ensure that any eForms-document complies with both national and EU regulation regarding content. 

* Adds Notification forms to be used below threshold. The new Doffin is “native” eForms. It has been signalled that eForms will be extended to support this later, so for now we have added simplified versions of a subset of the forms available with the aim of making the use as easy as possible, but still withing the SDK format.  

This SDK is not [tailoring of eForms](https://op.europa.eu/en/publication-detail/-/publication/73a78487-cc8b-11ea-adf7-01aa75ed71a1) for Norway (changing the content in eForms). For now, we have opted not to do any tailoring.


## How to identify Norwegian eForms?

To indicate that you are submitting Norwegian eForms to us please extend the content in your CustomizationID-element where you indicate which version of eForms you are submitting with one of the following two constants:

* "#extended#urn:fdc:anskaffelser.no:2023:eforms:eu" indicating eForms to be submitted to TED (above threshold or voluntary notification)

* "#extended#urn:fdc:anskaffelser.no:2023:eforms:national" indicating Norwegian notifications (below threshold)

Example:

```xml
<cbc:CustomizationID>eforms-sdk-1.8#extended#urn:fdc:anskaffelser.no:2023:eforms:national</cbc:CustomizationID> 
```

b
