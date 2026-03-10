# eForms SDK NOR

This repository contains the resources used to create a modified edition of the official eForms SDK distribution with modifications for the Norwegian market.

Please see the [releases page](https://github.com/anskaffelser/eforms-sdk-nor/releases) to download modified distributions of the [official eForms SDK](https://github.com/OP-TED/eForms-SDK) for use in the Norwegian market. For all documentation of how to use and interpret eForms please refer to the [official eForms documentation](https://docs.ted.europa.eu/home/index.html).

## The Doffin API
The Doffin API has different features and also terms of use. 
We offer **two types** of API. 
*The Notices API* is intended for those who will submit quality-assured notices to TED and Doffin.no. This is typically service providers of competition tools. To access this API we need a process in place to ensure you are ready to go to market. 
*The Public API* is intended to those who will access notices at Doffin.no in a machine readable format, such as search and download. This API has a wider scope of users. Both private and public enterprises. Some also create third-party solutions.

The Doffin API is available at the following endpoints:
* [Public API](https://dof-notices-prod-api.developer.azure-api.net/api-details#api=651eeff38be0c56022ac741d&operation=65015cc43a2729c87e6be1a8) used to search for and download published notices.

* [Notices API test](https://dof-notices-test-api.developer.azure-api.net/) for testing our SDK validation through sending notices to the TED and Doffin test environment.
Such submissions do not become legally committing procurement notices. This environment is meant for support tool vendors to familiarize themselves with Norwegian eForms validation rules.
At [https://test.doffin.no/](http://test.doffin.no/) you can find the submitted published notices in a a userfriendly interface.

* [Notices API prod](https://dof-notices-prod-api.developer.azure-api.net/api-details#api=eform-api&operation=645cce8e4ffd2d6d5768181e) for sending notices through the SDK validatation to TED`s and Doffin`s production environment. Submitted notices are legally binding and can not be deleted. 

These are hosted as two independent systems, so you need to register for each environment that you want to access. For example, to start using using the test/prod API's you first have to [sign up](https://dof-notices-test-api.developer.azure-api.net/signup) as a user, log in and [create one or more subscriptions](https://dof-notices-test-api.developer.azure-api.net/signin).



### Important regarding the Notices API
Once you have created a subscription for the Notices API please contact [ingunn.ostrem@dfo.no](mailto:ingunn.ostrem@dfo.no) to get the subscription activated.

For now we are **not returning** any validation results. Please make sure that you are using valid and well-formed eForms messages before testing the integration. To test for validity and well-formness during development please use:

  For development and production environments we strongly recommend:
* the validation function in the Notices API
* or a local validator service, i.e. [based on our code](https://github.com/anskaffelser/vefa-validator).  

Please note that eForms messages using these extensions will fail validation in TED unless you pre-process with using the xslt-filter provided in this repository. 

The endpoint supports the eForms-versions included in the newest release of this repository. 

## Why do we need a Norwegian SDK? 

This SDK completes the official SDK with two extensions needed for the Norwegian market: 

* Norwegian is not an official EU language and is hence not part of the official TED SDK distribution. This SDK adds Norwegian translations where needed as well as validation rules to ensure that any eForms-document complies with both national and EU regulation regarding content. 

* Adds Notification forms to be used below threshold. The new Doffin is “native” eForms. It has been signalled that eForms will be extended to support this later, so for now we have added simplified versions of a subset of the forms available with the aim of making the use as easy as possible, but still withing the SDK format.  

## Environmental considerations

### Norwegian eForms extension for compliance with Norwegian Procurement Regulations

For contracting authorities to indicate compliance with [Section 7-9 of Norway's Procurement Regulations](https://lovdata.no/forskrift/2016-08-12-974/§7-9), we have extended the codelist for specifying _award criterion types_. 

The extension is described in a structured format here: [codelist-no/award-criterion-type.no.yaml](src/codelists-no/award-criterion-type.no.yaml). 

The extensions are patched into our validator, as described here: [patch/eforms-sdk-nor/1.13/0001-environment-codes.patch](src/patch/eforms-sdk-nor/1.13/0001-environment-codes.patch).

## How to identify Norwegian eForms?

To indicate that you are submitting Norwegian eForms to us please extend the content in your CustomizationID-element where you indicate which version of eForms you are submitting with one of the following two constants:

* "#extended#urn:fdc:anskaffelser.no:2023:eforms:eu" indicating eForms to be submitted to TED (above threshold or voluntary notification)

* "#extended#urn:fdc:anskaffelser.no:2023:eforms:national" indicating Norwegian notifications (below threshold)

Example:

```xml
<cbc:CustomizationID>eforms-sdk-1.8#extended#urn:fdc:anskaffelser.no:2023:eforms:national</cbc:CustomizationID> 
```

