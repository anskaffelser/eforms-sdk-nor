---
title: 'Environmental Considerations'
organization: 'The Norwegian Agency for Finance and Public Management (DFØ)'
organization_url: 'https://www.dfo.no'
date: '2026-05-15'
version: '0.2'
license:
  spdx: 'CC-BY-4.0'
  name: 'Creative Commons Attribution 4.0 International'
  url: 'https://creativecommons.org/licenses/by/4.0/'
copyright:
  year: 2026
  holder: 'The Norwegian Agency for Finance and Public Management (DFØ)'

source: 'https://github.com/anskaffelser/eforms-sdk-nor'

contributors:
  - organization_unit: 'The Department of Management and Digitalization'
    people:
      - 'Løken, Arne Magnus Tveita'
      - 'Østrem, Ingunn Balgaard'

dependencies:
  - name: 'OP-TED/eForms-SDK'
    type: 'git'
    url: 'https://github.com/OP-TED/eForms-SDK'
    usage: 'Build-time input (schemas/codelists); pulled in during build'
    license:
      spdx: 'EUPL-1.2'
      name: 'EU Public Licence v1.2'
      url: 'https://eupl.eu/1.2/en'

references:
  - name: 'TED Developer Docs'
    url: 'https://docs.ted.europa.eu/home/index.html'
  - name: 'eForms documentation'
    url: 'https://docs.ted.europa.eu/eforms/latest/index.html'
---

## Environmental considerations

### Norwegian eForms extension for compliance with Norwegian Publicv Procurement Regulations

For contracting authorities to indicate compliance with [Section 7-9 of Norway's Procurement Regulations](https://lovdata.no/forskrift/2016-08-12-974/§7-9), we have extended the codelist for specifying _award criterion types_. 

The extension is described in a structured format here: [codelist-no/award-criterion-type.no.yaml](../src/codelists-no/award-criterion-type.no.yaml). 

The extensions are patched into our validator, as described here: [patch/eforms-sdk-nor/1.13/0001-environment-codes.patch](../src/patch/eforms-sdk-nor/1.13/0001-environment-codes.patch).

### Note: Upcoming changes to the Norwegian Public Procurement Regulations

The aforementioned codelist extension now contains the planned future
state of the Norwegian codelist. See the `future` elements of the
codelist extensions, in addition to the `valid_from*` and `valid_to*` attributes.

Moreover, the associated upcoming future patch to our validator, which
will supercede and replace our current validator patch, is described
here: [patch/eforms-sdk-nor/1.14/0002-environment-codes-july-2026.patch.notbefore-2026-07-01](../src/patch/eforms-sdk-nor/1.14/0002-environment-codes-july-2026.patch.notbefore-2026-07-01).

#### Note: Finalization of labels for future values
Please note that the labels (human-readable strings) for the upcoming codelist values are subject to final administrative approval. Consequently, the *_verify attributes for these elements are currently set to false.

This indicates that the labels should not be subjected to literal string validation by consuming systems at this stage. When the labels are finalized, we will update the codelist's minor version and toggle the verification flags as necessary.
