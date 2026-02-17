---
title: "Notice identifiers"
organization: "The Norwegian Agency for Finance and Public Management (DFØ)"
organization_url: "https://www.dfo.no"
date: "2026-02-17"
version: "0.1"
license: "CC BY 4.0"
license_url: "https://creativecommons.org/licenses/by/4.0/"
copyright:
  year: 2026
  holder: "The Norwegian Agency for Finance and Public Management (DFØ)"

source: "https://github.com/anskaffelser/eforms-sdk-nor"

contributors:
  - organization_unit: "The Department of Management and Digitalization"
    people:
      - "Løken, Arne Magnus Tveita"

dependencies:
  - name: "OP-TED/eForms-SDK"
    type: "git"
    url: "https://github.com/OP-TED/eForms-SDK"
    usage: "Build-time input (schemas/codelists); pulled in during build"
    license: "EUPL-1.2"
    license_url: "https://eupl.eu/1.2/en"

references:
  - name: "TED Developer Docs"
    url: "https://docs.ted.europa.eu/home/index.html"
  - name: "eForms documentation"
    url: "https://docs.ted.europa.eu/eforms/latest/index.html"
---

# Notice identifiers

## 1. Purpose and scope

This document explains how identifiers are used for procurement notices in the Norwegian implementation of eForms, with particular focus on:

- how Doffin identifiers relate to eForms notice identifiers
- how TED identifiers relate to eForms notice identifiers
- how notice versioning works in eForms (UUID4 + version)
- how related notices can be linked together across procurement phases,
  corrigenda, and cancellations
- how procedure-level identifiers 
  (e.g. `ContractFolderID`/`procedure-identifier`) should be interpreted and
  used
  
The intended audience includes both functional and technical stakeholders, such
as:
- contracting authorities and procurement specialists
- system integrators
- support tool vendors and downstream data consumers

### In scope

- conceptual explanation of the identifier model
- recommended practices for grouping and linking notices
- examples illustrating common scenarios

### Out of scope

Detailed XML field mappings, schema (XSD) structure, and BT-code references
are intentionally kept out of this document to preserve readability.

Technical details are provided in separate documents (see references at the
end of this file).

## License
© 2026 The Norwegian Agency for Finance and Public Management (DFØ).

This document is licensed under the Creative Commons Attribution 4.0 International License (CC BY 4.0).
See: https://creativecommons.org/licenses/by/4.0/

Source repository: https://github.com/anskaffelser/eforms-sdk-nor

## Attribution / sources

References material derived from Publications Office of the European Union (TED).
Original material licensed under the EU Public License (EUPL).
