---
title: 'Notice identifiers'
organization: 'The Norwegian Agency for Finance and Public Management (DFØ)'
organization_url: 'https://www.dfo.no'
date: '2026-02-17'
version: '0.1'
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

# 1. Purpose and scope

This document explains how identifiers are used for procurement notices
in the Norwegian implementation of eForms, with particular focus on:

- how Doffin identifiers relate to eForms notice identifiers

- how TED identifiers relate to eForms notice identifiers

- how notice versioning works in eForms (`UUIDv4` + version)

- how related notices can be linked together across procurement phases,
  corrigenda, and cancellations

- how procedure-level identifiers (e.g. `procedure-identifier`) should
  be interpreted and used

The intended audience includes both functional and technical
stakeholders, such as:

- contracting authorities and procurement specialists

- system integrators

- support tool vendors and downstream data consumers

## 1.1. In scope

- conceptual explanation of the identifier model

- recommended practices for grouping and linking notices

- examples illustrating common scenarios

## 1.2. Out of scope

Detailed XML field mappings, schema (XSD) structure, and BT-code
references are intentionally kept out of this document to preserve
readability.

Technical details are provided in separate documents (see references at
the end of this file).

## 1.3. Normative language

The key words **MUST**, **MUST NOT**, **REQUIRED**, **SHALL**, **SHALL
NOT**, **SHOULD**, **SHOULD NOT**, **RECOMMENDED**, **MAY**, and
**OPTIONAL** in this document are to be interpreted as described in [RFC
2119](https://www.rfc-editor.org/rfc/rfc2119) and [RFC
8174](https://www.rfc-editor.org/rfc/rfc8174).

These words are normative only when they appear in all capitals.

In addition, the term **NOTE** is used to indicate non-normative
information.

## 1.4. Terminology

- **Notice**: a published eForms notice.

- **Procedure**: the underlying procurement process identified by
  `procedure-identifier`.

# 2. Overview: identifier landscape

This section defines the identifier model used in the Norwegian
implementation of eForms.

Identifiers are classified into two categories:

- notice-level identifiers, and

- procedure-level identifiers.

Within the notice-level category, this document further distinguishes
between:

- eForms semantic identifiers (forming part of the eForms data model),
  and

- publication reference identifiers (assigned by publication systems
  such as Doffin or TED).

These dimensions are orthogonal: notice-level identifiers may be either
eForms semantic identifiers or publication reference identifiers,
whereas procedure-level identifiers are always semantic identifiers.

<div class="informalexample">

<div class="formalpara-title">

**Requirement R-1**

</div>

Systems that store, export or process notice data **MUST** distinguish
between notice-level identifiers and procedure-level identifiers.

</div>

<div class="informalexample">

<div class="formalpara-title">

**Requirement R-2**

</div>

Systems **MUST NOT** use notice-level identifiers as substitutes for
procedure-level identifiers.

</div>

The table below provides a high-level overview of the identifiers
covered by this document.

| Identifier             | Category                         | Applies to         | Stability                       | Primary purpose                          |
|------------------------|----------------------------------|--------------------|---------------------------------|------------------------------------------|
| `doffin-identifier`    | Publication reference identifier | Published notice   | Stable per publication instance | Doffin lookup and indexing               |
| `publication-number`   | Publication reference identifier | Published notice   | Stable per publication instance | TED lookup and indexing                  |
| `notice-identifier`    | eForms semantic identifier       | Notice identity    | Stable                          | Stable notice identity across versions   |
| `notice-version`       | eForms semantic identifier       | Notice identity    | Changes                         | Version within notice identity           |
| `procedure-identifier` | eForms semantic identifier       | Procedure identity | Stable                          | Stable procedure identity across notices |

<div class="note">

(`notice-identifier`, `notice-version`) and `procedure-identifier` are
eForms semantic identifiers. `doffin-identifier` and
`publication-number` are publication reference identifiers.

</div>

## 2.1. Notice-level identifiers

Notice-level identifiers relate to a specific published notice or to its
eForms notice identity.

<div class="informalexample">

<div class="formalpara-title">

**Requirement R-3**

</div>

A notice-level identifier **MUST** refer to a specific published notice.

</div>

<div class="informalexample">

<div class="formalpara-title">

**Requirement R-4**

</div>

A notice-level identifier **MUST NOT** be used to identify an underlying
procurement procedure.

</div>

This document distinguishes between:

- (eForms) notice identity identifiers, and

- publication reference identifiers (Doffin and TED).

<div class="informalexample">

<div class="formalpara-title">

**Requirement R-5**

</div>

Systems **MUST** treat notice identity identifiers and publication
reference identifiers as separate concepts.

</div>

The primary eForms notice identifiers are:

- `notice-identifier`

- `notice-version`

In addition, two publication reference identifiers may exist for a
notice:

- `doffin-identifier` (Doffin)

- `publication-number` (TED)

These identifiers support indexing and lookup in their respective
publication systems.

<div class="informalexample">

<div class="formalpara-title">

**Requirement R-6**

</div>

Systems **MUST NOT** treat `doffin-identifier` or `publication-number`
as substitutes for (`notice-identifier`, `notice-version`).

</div>

<div class="informalexample">

<div class="formalpara-title">

**Requirement R-7**

</div>

When referencing a specific notice version, systems **MUST** include
both `notice-identifier` and `notice-version`.

</div>

<div class="informalexample">

<div class="formalpara-title">

**Requirement R-8**

</div>

The `notice-identifier` **MUST** remain stable across notice updates.

</div>

<div class="informalexample">

<div class="formalpara-title">

**Requirement R-9**

</div>

The `notice-version` **MUST** change when a notice is republished in a
new version, including corrigenda.

</div>

In some contexts, the term `business-identifier` is used to denote a
string representation derived from `notice-identifier` and
`notice-version`.

<div class="informalexample">

<div class="formalpara-title">

**Requirement R-10**

</div>

Systems **MUST NOT** treat `business-identifier` as a distinct
identifier.

</div>

## 2.2. Procedure-level identifier

The `procedure-identifier` identifies the underlying procurement
procedure.

<div class="informalexample">

<div class="formalpara-title">

**Requirement R-11**

</div>

A procurement procedure **MUST** be considered established when a
competition notice (e.g. `ContractNotice`) is published.

</div>

<div class="informalexample">

<div class="formalpara-title">

**Requirement R-12**

</div>

The `procedure-identifier` **MUST** remain stable across multiple notice
versions, corrigenda, procurement phases, and related notices belonging
to the same procurement process.

</div>

<div class="informalexample">

<div class="formalpara-title">

**Requirement R-13**

</div>

Systems **MUST** use `procedure-identifier` as the primary grouping key
when grouping notices belonging to the same procurement procedure.

</div>

<div class="informalexample">

<div class="formalpara-title">

**Requirement R-14**

</div>

Systems **MUST NOT** use `notice-identifier` (with or without
`notice-version`) as a procedure-level grouping key.

</div>

## 2.3. Referencing planning notices

A planning notice (`PriorInformationNotice`) does not establish a
procurement procedure.

<div class="informalexample">

<div class="formalpara-title">

**Requirement R-15**

</div>

A planning notice (`PriorInformationNotice`) **MUST NOT** contain a
`procedure-identifier`.

</div>

Links between planning notices and subsequent notices (e.g.
`ContractNotice`, `ContractAwardNotice`, or another
`PriorInformationNotice`) are expressed by referencing the earlier
published notice directly.

<div class="informalexample">

<div class="formalpara-title">

**Requirement R-16**

</div>

Links between planning notices and subsequent notices **MUST** be
expressed by referencing the earlier published notice directly. Such
references **MUST** use the combination (`notice-identifier`,
`notice-version`) of the earlier notice.

</div>

<div class="informalexample">

<div class="formalpara-title">

**Requirement R-17**

</div>

A reference to a planning notice **MUST NOT** rely on a
`procedure-identifier`.

</div>

<div class="informalexample">

<div class="formalpara-title">

**Requirement R-18**

</div>

A reference to a planning notice **MUST** target a specific, versioned
notice.

</div>

<div class="informalexample">

<div class="formalpara-title">

**Requirement R-19**

</div>

A reference to a planning notice **MUST NOT** target a procedure-level
identifier.

</div>

# 3. Doffin publication reference identifier (`doffin-identifier`)

The `doffin-identifier` is a national publication reference identifier
assigned upon publication in the Doffin system.

The `doffin-identifier` is a human-readable national publication
identifier and is not part of the eForms notice payload exchanged with
TED.

<div class="note">

Although the `doffin-identifier` is not part of the eForms payload
exchanged with TED, TED publications can include hyperlinks to the
corresponding Doffin publication. In such cases, the `doffin-identifier`
can appear as part of the URL. This does not imply that it forms part of
the eForms notice data model.

</div>

## 3.1. Scope and semantics

The `doffin-identifier` identifies a specific published notice in
Doffin.

<div class="informalexample">

<div class="formalpara-title">

**Requirement R-20**

</div>

The `doffin-identifier` **MUST NOT** be interpreted as a procedure-level
identifier.

</div>

<div class="informalexample">

<div class="formalpara-title">

**Requirement R-21**

</div>

The `doffin-identifier` **MUST NOT** be used as a substitute for
`notice-identifier`.

</div>

The `doffin-identifier` has no semantic meaning beyond identifying a
specific publication instance.

It is a Doffin-specific publication identifier, and is only resolvable
within the Doffin ecosystem.

<div class="tip">

In some integrations, the Doffin identifier may be used in file naming
conventions (e.g. `<doffin-identifier>.xml`). This does not imply that
the identifier is part of the eForms notice payload.

</div>

## 3.2. Relationship to eForms identifiers

Each `doffin-identifier` corresponds to exactly one combination of
(`notice-identifier`, `notice-version`).

<div class="informalexample">

<div class="formalpara-title">

**Requirement R-22**

</div>

Systems that require a stable, version-aware reference to a notice
**SHOULD** rely on (`notice-identifier`, `notice-version`) rather than
`doffin-identifier`.

</div>

If a notice is republished as a new version, a new `doffin-identifier`
is assigned.

<div class="informalexample">

<div class="formalpara-title">

**Requirement R-23**

</div>

The `doffin-identifier` **MUST NOT** be used to group multiple versions
of the same notice.

</div>

## 3.3. Format

The format of the `doffin-identifier` is:

`YYYY-NNNNNN`

where:

- `YYYY` represents the publication year, and

- `NNNNNN` is a sequential number assigned upon publication

The format is intended for human readability and indexing purposes. It
does not encode procedure identity or version semantics.

# 4. TED (EU) publication reference identifier (`publication-number`)

The `publication-number` is the publication reference identifier
assigned by TED to a notice upon EU/EEA publication.

It serves a similar purpose to the `doffin-identifier`, in that it
provides a human-readable reference for locating a specific notice in
the TED system.

The `publication-number` is only applicable to notices that are
published in TED.

Not all Norwegian notices are published at EU/EEA level. A notice will
only receive a `publication-number` when it is published in TED, either
because the procurement is subject to EU/EEA publication requirements,
or because the contracting authority chooses to publish at EU level
voluntarily.

<div class="informalexample">

<div class="formalpara-title">

**Requirement R-24**

</div>

Systems **MUST NOT** require a `publication-number` for notices that are
not published in TED.

</div>

<div class="informalexample">

<div class="formalpara-title">

**Requirement R-25**

</div>

Systems **SHOULD NOT** require contracting authorities or end users to
manage or use the `publication-number` as part of the procurement
process.

</div>

The primary identifiers for linking notices and tracking notice versions
are the eForms identifiers (`notice-identifier`, `notice-version`) and
the procedure-level identifier (`procedure-identifier`).

<div class="informalexample">

<div class="formalpara-title">

**Requirement R-26**

</div>

The `publication-number` **MAY** be included as an additional reference
in later notices when a direct link back to a TED publication is useful.

</div>

Such references are optional and are primarily intended to support
navigation and external lookup, not notice identity or procedure
grouping.

In practice, the `publication-number` is assigned by TED during the
publication process and becomes available after EU/EEA publication.

<div class="note">

TED typically provides linkage between related publications based on
eForms identifiers (including `procedure-identifier`,
`notice-identifier`, and `notice-version`). Systems therefore **SHOULD
NOT** rely on `publication-number` for linking notices across versions
or procurement phases.

</div>

<div class="informalexample">

<div class="formalpara-title">

**Requirement R-27**

</div>

Linking between notices **MUST** be based on eForms semantic
identifiers.

</div>

<div class="note">

The `publication-number` is typically presented in the form
`XXXXXXXX-YYYY`, where

- `XXXXXXXX` is a sequential number assigned upon publication, and

- `YYYY` represents the publication year.

The format is defined by TED.

</div>

<div class="informalexample">

<div class="formalpara-title">

**Requirement R-28**

</div>

Systems **MUST NOT** use `publication-number` as a substitute for
`notice-identifier`, `notice-version`, `procedure-identifier`, or any
combinations thereof.

</div>

# 5. eForms notice identifier and versioning

This section describes how notice identity and versioning work in
eForms, and how individual notices relate to other notices, and to
procurement procedures.

The eForms identifier model distinguishes between three related
concepts:

- the identity of an individual notice (`notice-identifier`)

- the version of that notice (`notice-version`)

- the identity of the procurement procedure (`procedure-identifier`)

A procurement procedure may be associated with multiple notices over
time, and each notice may itself have multiple published versions.

## 5.1. Notice identity (`notice-identifier`)

The `notice-identifier` uniquely identifies a specific notice.

A notice represents a distinct publication act, such as a planning
notice, a competition notice, or a result notice. Each such notice has
its own persistent identity represented by the `notice-identifier`.

The notice identity remains stable across revisions of the same notice.
When a notice is corrected or republished, the notice identity remains
unchanged and only the notice version is incremented.

<div class="informalexample">

<div class="formalpara-title">

**Requirement R-29**

</div>

A new version of a notice **MUST** preserve the same
`notice-identifier`.

</div>

<div class="informalexample">

<div class="formalpara-title">

**Requirement R-30**

</div>

For a given `notice-identifier`, each new publication of the notice
**MUST** increase the `notice-version`.

</div>

Multiple notices may exist within the same procurement process. Each of
these notices has its own `notice-identifier`, even when they relate to
the same underlying procurement procedure.

For instance, the following notices may exist within a single
procurement context:

- one or more planning notices (`PriorInformationNotice`)

- a competition notice (`ContractNotice`)

- one or more result notices (`ContractAwardNotice`)

Each of these notices has its own independent notice identity.

## 5.2. Versioning model (`notice-version`)

The `notice-version` identifies a specific published state of a notice.

When a notice is first published, it is assigned an initial version. If
the notice is later corrected, updated, or republished, the same
`notice-identifier` is retained and a new `notice-version` is assigned.

<div class="formalpara-title">

**Example notice versioning**

</div>

``` text
ContractNotice
notice-identifier = CN-1

  version 1  -> first publication
  version 2  -> corrigendum / update
  version 3  -> later correction

Same notice-identifier, different notice-version values.
```

<div class="informalexample">

<div class="formalpara-title">

**Requirement R-31**

</div>

A new `notice-version` **MUST** be assigned whenever a notice is
corrected, updated, or republished.

</div>

Each published state of a notice is therefore uniquely identified by the
combination (`notice-identifier`, `notice-version`).

## 5.3. What constitutes a new notice

A new notice identity is established when a publication represents a
distinct notice rather than a revision of an existing one.

Each distinct notice is assigned its own `notice-identifier`.

Different notice types represent different publication acts and
therefore establish separate notice identities. For example:

- each distinct planning notice (`PriorInformationNotice`) establishes
  its own `notice-identifier`

- a competition notice (`ContractNotice`) establishes its own
  `notice-identifier`

- each result notice (`ContractAwardNotice`) establishes its own
  `notice-identifier`

Planning notices may be published independently and may later be
referenced by one or more competition notices.

A competition notice establishes the `procedure-identifier` for the
procurement procedure.

<div class="informalexample">

<div class="formalpara-title">

**Requirement R-32**

</div>

A procurement procedure **MUST** be established by exactly one
`ContractNotice`.

</div>

Result notices relating to that procurement procedure share the same
`procedure-identifier`, but each result notice has its own independent
`notice-identifier` and version history.

<div class="informalexample">

<div class="formalpara-title">

**Requirement R-33**

</div>

A result notice (`ContractAwardNotice`) **MUST** contain the
`procedure-identifier` of the procurement procedure to which it relates.

</div>

<div class="informalexample">

<div class="formalpara-title">

**Requirement R-34**

</div>

Result notices (`ContractAwardNotice`) relating to the same procurement
procedure **MUST** use the same `procedure-identifier`.

</div>

## 5.4. What constitutes a new version of a notice

A new notice version is created when an existing notice is republished
with modifications.

Such modifications may include corrections, clarifications, or other
updates to the published notice content. These updates do not establish
a new notice identity. Instead, they result in a new `notice-version`
associated with the same `notice-identifier`.

As a consequence, multiple versions may exist for the same notice. All
versions of a notice share the same `notice-identifier`.

# 6. Relationship between notices and procedures

Not all notices are associated with a procurement procedure.

Planning notices (`PriorInformationNotice`) may be published
independently and do not establish a procurement procedure. Multiple
procurement procedures may later reference the same planning notice.

<div class="informalexample">

<div class="formalpara-title">

**Requirement R-35**

</div>

A planning notice (`PriorInformationNotice`) **MUST NOT** establish a
`procedure-identifier`.

</div>

A procurement procedure is established when a competition notice
(`ContractNotice`) is published. At that point a `procedure-identifier`
is assigned to the procurement process.

<div class="informalexample">

<div class="formalpara-title">

**Requirement R-36**

</div>

A competition notice (`ContractNotice`) **MUST** establish a
`procedure-identifier` for the procurement procedure.

</div>

All later notices that relate to that procurement procedure share the
same `procedure-identifier`.

In particular, a procurement procedure may be associated with:

- one competition notice (`ContractNotice`)

- one or more result notices (`ContractAwardNotice`)

Each of these notices has its own notice identity (`notice-identifier`)
and its own version history (`notice-version`), while the shared
`procedure-identifier` links them to the same procurement procedure.

The following figure is illustrative and shows a typical relationship
between planning, competition, and result notices.

<div class="formalpara-title">

**Example relationships between planning, competition and result
notices**

</div>

    PriorInformationNotice
    notice-identifier = PIN-1
    notice-version    = 1
    (no procedure-identifier)

            |
            | referenced retrospectively
            |
            v

    ContractNotice
    notice-identifier    = CN-1
    notice-version       = 1
    procedure-identifier = PROC-1

            |
            | same procedure-identifier
            |
            +------------------------------+
            |                              |
            v                              v

    ContractAwardNotice              ContractAwardNotice
    notice-identifier    = CAN-1     notice-identifier    = CAN-2
    notice-version       = 1         notice-version       = 1
    procedure-identifier = PROC-1    procedure-identifier = PROC-1

## 6.1. Lifecycle of a procurement procedure

<div class="informalexample">

<div class="formalpara-title">

**Requirement R-37**

</div>

A procurement procedure **MUST NOT** be considered formally concluded
until at least one related result notice (`ContractAwardNotice`) has
been published for the same `procedure-identifier`.

</div>

# 7. Linking related notices

Notices may reference other notices in order to express relationships
between planning activities, competition notices, and result notices.

Such references allow systems to reconstruct the history and structure
of procurement procedures across multiple publications.

## 7.1. Version-aware referencing

References between notices are version-aware.

<div class="informalexample">

<div class="formalpara-title">

**Requirement R-38**

</div>

Systems that reference a specific published notice version **MUST** use
the combination (`notice-identifier`, `notice-version`).

</div>

The pair (`notice-identifier`, `notice-version`) uniquely identifies a
specific published state of a notice.

In some contexts, this pair is referred to as a **business identifier**.

## 7.2. Linking competition and result notices

Competition notices (`ContractNotice`) establish procurement procedures
through the assignment of a `procedure-identifier`.

Result notices (`ContractAwardNotice`) that relate to the same
procurement procedure reference that procedure using the same
`procedure-identifier`.

A procurement procedure may therefore contain multiple result notices,
each with its own `notice-identifier` and `notice-version`, but all
sharing the same `procedure-identifier`.

## 7.3. Linking planning notices retrospectively

Planning notices (`PriorInformationNotice`) may be published
independently before any procurement procedure has been established.

Later notices, such as competition notices or result notices, may refer
back to earlier planning notices.

<div class="informalexample">

<div class="formalpara-title">

**Requirement R-39**

</div>

References to a planning notice **MUST** identify the notice using the
combination (`notice-identifier`, `notice-version`).

</div>

Multiple procurement procedures **MAY** reference the same planning
notice.

References to planning notices therefore express informational or
contextual relationships rather than procedure identity.

<div class="note">

In some implementations, references may target a specific part of a
notice (for example a LOT or PART element in the eForms data model).

Such references operate at a finer granularity than notice-level
identifiers and are outside the scope of this document.

</div>

# License

<div class="note">

© 2026 The Norwegian Agency for Finance and Public Management (DFØ).

This documentation is licensed under [Creative Commons Attribution 4.0
International](https://creativecommons.org/licenses/by/4.0/) (SPDX:
CC-BY-4.0).

</div>

# Attribution / sources

- [OP-TED/eForms-SDK](https://github.com/OP-TED/eForms-SDK) ([EU Public
  Licence v1.2](https://eupl.eu/1.2/en), SPDX: EUPL-1.2).  
  Build-time input (schemas/codelists).


- [TED Developer Docs](https://docs.ted.europa.eu/home/index.html)

- [eForms
  documentation](https://docs.ted.europa.eu/eforms/latest/index.html)

<div class="note">

This document may reference upstream specifications and documentation
for context and interoperability guidance. Upstream materials remain
under their respective licenses.

Material derived from Publications Office of the European Union (TED).

</div>
