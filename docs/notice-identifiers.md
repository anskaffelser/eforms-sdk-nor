---
title: "Notice identifiers"
organization: "The Norwegian Agency for Finance and Public Management (DFØ)"
organization_url: "https://www.dfo.no"
date: "2026-02-17"
version: "0.1"
license:
  spdx: "CC-BY-4.0"
  name: "Creative Commons Attribution 4.0 International"
  url: "https://creativecommons.org/licenses/by/4.0/"
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
    license:
      spdx: "EUPL-1.2"
      name: "EU Public Licence v1.2"
      url: "https://eupl.eu/1.2/en"

references:
  - name: "TED Developer Docs"
    url: "https://docs.ted.europa.eu/home/index.html"
  - name: "eForms documentation"
    url: "https://docs.ted.europa.eu/eforms/latest/index.html"
---

# Notice identifiers

## 1. Purpose and scope

This document explains how identifiers are used for procurement notices in the
Norwegian implementation of eForms, with particular focus on:

- how Doffin identifiers relate to eForms notice identifiers
- how TED identifiers relate to eForms notice identifiers
- how notice versioning works in eForms (UUID4 + version)
- how related notices can be linked together across procurement phases,
  corrigenda, and cancellations
- how procedure-level identifiers (e.g. `procedure-identifier`) should be
  interpreted and used
  
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

### Normative language

The key words **MUST**, **MUST NOT**, **SHOULD**, **SHOULD NOT**, and **MAY**
in this document are to be interpreted as described in RFC 2119.

## 2. Overview: identifier landscape

This section describes and defines the identifier model used in the Norwegian
implementation of eForms. 

Identifiers are classified into two categories:

- notice-level identifiers
- procedure-level identifiers

Implementations **MUST** distinguish between these categories and **MUST NOT**
use notice-level identifiers as substitutes for procedure-level identifiers,
unless explicitly stated.

The table below provides a high-level overview of the identifiers covered by
this document.

| Identifier | Level | Stability | Primary purpose |
|------------|--------|-----------|-----------------|
| `doffin-identifier` | Notice | Stable | National notice ID (Norway). |
| `publication-number` | Notice | Stable | EU publication ID (TED). |
| `notice-identifier` | Notice | Stable | Notice identity across versions. |
| `notice-version` | Notice version | Changes | Version of a notice. |
| `procedure-identifier` | Procedure | Stable | Procedure identity across notices. |

### 2.1 Notice-level identifiers

Notice-level identifiers uniquely identify a published notice.

A notice-level identifier **MUST** refer to a specific published notice and
**MUST NOT** be used to identify an underlying procurement procedure.

The primary notice-level identifiers are:

- `doffin-identifier`
- `publication-number`
- `notice-identifier`
- `notice-version`

The combination of (`notice-identifier`, `notice-version`) **MUST** be used when
referencing a specific published state of an eForms notice.

Systems that reference a notice version **MUST** include both `notice-identifier`
and `notice-version`.

The `notice-identifier` **MUST** remain stable across notice updates, while
`notice-version` **MUST** change when a notice is republished in a new version,
including corrigenda.

Some documentation refers to a `business-identifier`, which is a string
representation derived from `notice-identifier` and `notice-version`.

Implementations **MUST NOT** treat the `business-identifier` as a separate
semantic identifier. It is a representation of the same underlying
(`notice-identifier`, `notice-version`) pair.

## 2.2 Procedure-level identifier

The `procedure-identifier` identifies the underlying procurement procedure.

A procurement procedure is established when a competition notice
(e.g. `ContractNotice`) is published. 

The `procedure-identifier` **MUST** remain stable across:

- multiple notice versions
- corrigenda
- procurement phases
- related notices belonging to the same procurement process

Systems that group notices belonging to the same procurement procedure
**MUST** use `procedure-identifier` as the primary grouping key.

Systems **MUST NOT** derive procedure identity from
(`notice-identifier`, `notice-version`).

An implementation that groups notices solely by `notice-identifier` is
non-compliant with this specification.

## 2.3 Referencing planning notices

A planning notice (`PriorInformationNotice`) does *not* establish a procurement
procedure and therefore **MUST NOT** contain a `procedure-identifier`.

Links between planning notices and subsequent notices
(e.g. `ContractNotice`, `ContractAwardNotice`, or another
`PriorInformationNotice`) **MUST** be expressed by referencing the earlier
published notice directly.

Such references **MUST** use the combination
(`notice-identifier`, `notice-version`) of the earlier notice.

A reference to a planning notice **MUST NOT** rely on a
`procedure-identifier`, since no procedure is established at that stage.

The reference **MUST** target a specific, versioned notice and
**MUST NOT** target a procedure-level identifier.

## License

© 2026 The Norwegian Agency for Finance and Public Management (DFØ).
SPDX: CC-BY-4.0
https://creativecommons.org/licenses/by/4.0/

## Attribution / sources

Build-time dependency: OP-TED/eForms-SDK (SPDX: EUPL-1.2)

References material derived from Publications Office of the European Union (TED).
