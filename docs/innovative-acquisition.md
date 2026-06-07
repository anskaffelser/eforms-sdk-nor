---
title: "Innovative Acquisition"
organization: "The Norwegian Agency for Finance and Public Management (DFØ)"
organization_url: "https://www.dfo.no"
date: "2026-06-05"
version: "0.1"
status: "public"
license:
  spdx: "CC-BY-4.0"
  name: "Creative Commons Attribution 4.0 International"
  url: "https://creativecommons.org/licenses/by/4.0/"
copyright:
  year: 2026
  holder: "The Norwegian Agency for Finance and Public Management (DFØ)"

source: "https://github.com/anskaffelser/eforms-sdk-nor"

codelist:
  id: "innovative-acquisition"
  bt: "BT-776-Lot"

contributors:
  - organization_unit: "The Department of Management and Digitalization"
    people:
      - "Bech, Malin Mæland"
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

## Guidance on the `innovative-acquisition` codelist for BT-776 Procurement of Innovation
Here, we provide guidance on how to use the different code values in the
`innovative-acquisition` codelist for BT-776 Procurement of Innovation.

The information contained within is intended for procurement platform providers
implementing BT-776, covering how a public procurement procedure
involves innovative aspects, and associated business logic in their solutions.

The descriptions and examples below are suggestions for help texts that can be
surfaced to contracting authorities at the point of data entry.

The descriptions are also intended to support platform providers in
implementing smart guidance logic; rather than expecting contracting
authorities to navigate cryptic BT field identifiers directly, platforms
may where possible surface contextual prompts that help the user recognise
whether their procurement holds innovative aspects. For instance, a platform
may detect signals in other information aspects, including the use of
functional specifications, pilot or R&D budget lines, or market dialogue
procedures, and proactively suggest that the procurement appears to involve
innovative elements, inviting the user to confirm or adjust. In such cases,
the confirmation itself is what the user engages with, not the underlying
BT-776 field or its codelist values directly. 

---

### `mar-nov`: Challenges the market to offer or develop innovative solutions
The procurement requires suppliers to offer or develop something that is not
currently available as an off-the-shelf solution in today's market. This
applies when the contracting authority has identified a need that existing
products or services cannot adequately meet, and the procurement therefore
invites the market to present new methods, technologies or approaches.

**Guidance text that can be displayed as an informative popup:**
Challenging the market to offer or develop innovative solutions applies
for procurements where the needs themselves push the boundaries of what
the market currently offers:

- **No existing solution:** The required product or service does not yet
exist in a form that meets the need. For example, procuring a zero-emissions
vessel for a ferry route where no certified solution is currently available.
- **Significantly beyond current offerings:** Existing solutions exist, but
none meet the requirements without substantial further development. For
example, commissioning a digital tool for a specialised workflow where no
comparable product exists on the market.

---

### `proc-innov`: Process innovation (new ways of producing or delivering the service)
This applies when the contracting authority seeks solutions that
introduce new or significantly improved ways of producing or delivering
the procured service.

**Guidance text that can be displayed as an informative popup:**
Process innovation concerns how the service is produced and delivered:

- **Production methods:** New ways of creating the solution. For example,
introducing automated case handling using algorithms to replace manual
assessments, or welfare technology that changes how care is provided.

- **Delivery methods:** New ways of reaching the user. For example, moving
from physical service offices to digital self-service solutions.

---

### `prod-innov`: Product innovation (new or significantly improved services that change the value for the user)
This applies when the contracting authority seeks solutions that
represent a new or significantly improved service, changing the value
delivered to the end user.

**Guidance text that can be displayed as an informative popup:**
Product innovation concerns what the user receives: the end result that meets
the citizen or user.

- **New services:** Services that did not previously exist. For example, a
new low-threshold mental health service without referral.

- **Significantly improved services:** Existing services with new qualities
that change the value for the user. For example, waste collection using
sensor-based emptying when needed, instead of fixed collection days.

---

### `rd-act`: Includes research and development activities

The procurement includes activities aimed at generating new knowledge or
developing new ways of applying existing knowledge. This applies when the
solution cannot simply be sourced or specified in advance, but must be
developed, tested or validated as part of the contract.

**Guidance text that can be displayed as an informative popup:**
R&D activities apply when the procurement involves an element of structured
inquiry or development under uncertainty:

- **Applied research:** The procurement involves investigating whether a
known technology or method can work in a new context. For example, procuring
a pilot to test whether a specific AI model can reliably support case
assessments in a given domain.

- **Development and validation:** The procurement involves building and
testing something new where the outcome is not yet certain. For example,
developing and validating a new measurement methodology for environmental
monitoring, where the correct approach has not yet been established.

### Retired codes

These codes are retired upstream by OP TED, and are briefly mentioned here for
historical reference. 

#### `buy-eff`: The procurement is likely to make the work of the buyer more effective

#### `fp-requ`: The specifications are primarily functional and performative rather than technical descriptions

#### `other`: Other

### `org-nov`: The procurement concerns works, supplies or services that are novel to the organisation
