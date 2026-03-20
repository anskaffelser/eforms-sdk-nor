# eForms SDK NOR

This repository contains the resources used to create a modified edition of the official eForms SDK distribution with modifications for the Norwegian market.

Please see the [releases page](https://github.com/anskaffelser/eforms-sdk-nor/releases) to download modified distributions of the [official eForms SDK](https://github.com/OP-TED/eForms-SDK) for use in the Norwegian market. For all documentation of how to use and interpret eForms please refer to the [official eForms documentation](https://docs.ted.europa.eu/home/index.html).

## Why do we need a Norwegian SDK? 

This SDK completes the official SDK with two extensions needed for the Norwegian market: 

* Norwegian is not an official EU language and is hence not part of the official TED SDK distribution. This SDK adds Norwegian translations where needed as well as validation rules to ensure that any eForms-document complies with both national and EU regulation regarding content. 

* Adds Notification forms to be used below threshold. The new Doffin is “native” eForms. It has been signalled that eForms will be extended to support this later, so for now we have added simplified versions of a subset of the forms available with the aim of making the use as easy as possible, but still withing the SDK format.  

## How to identify Norwegian eForms?

To indicate that you are submitting Norwegian eForms to us please extend the content in your CustomizationID-element where you indicate which version of eForms you are submitting with one of the following two constants:

* "#extended#urn:fdc:anskaffelser.no:2023:eforms:eu" indicating eForms to be submitted to TED (above threshold or voluntary notification)

* "#extended#urn:fdc:anskaffelser.no:2023:eforms:national" indicating Norwegian notifications (below threshold)

Example:

```xml
<cbc:CustomizationID>eforms-sdk-1.8#extended#urn:fdc:anskaffelser.no:2023:eforms:national</cbc:CustomizationID> 
```

