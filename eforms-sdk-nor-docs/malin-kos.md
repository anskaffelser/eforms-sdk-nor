# 1. Purpose and scope

This document/page describes the **Norwegian national tailoring**
applied to selected eForms notice subtypes used for procurements below
the EU/EEA thresholds.

The document covers the following notice subtypes:

-   **E2 -- Contract Notice**

-   **E3 -- Contract Award Notice**

-   **E4 -- Contract Modification Notice**

### **In scope**

The scope of this document is limited to **national deviations and
implementation rules** introduced in the Norwegian eForms
implementation. These adaptations are applied on top of the standard
eForms specifications maintained by the Publications Office of the
European Union (OP TED), including the business rules defined in the
eForms SDK.

In particular, the document describes national adaptations related to:

-   **Business Terms (BT)** where the Norwegian implementation
    introduces specific values or constraints

-   **Codelists** where the set of permitted code values is restricted
    or codelist is tailored

-   **Mandatory rules** introduced at national level

-   ~~**Validation rules** specific to the Norwegian implementation~~

-   Other implementation constraints affecting the usage of the notice
    subtypes

The purpose of these adaptations is to support national requirements
related to Norwegian procurement procedures, while promoting best
practices and ensuring the quality and consistency of the data contained
in procurement notices.

### **Out of scope**

The notice subtypes E2, E3 and E4 otherwise follow the **standard eForms
specifications and business rules defined by the Publications Office (OP
TED)**.

Fields, rules, and constraints that remain unchanged from the official
eForms specification are **not reproduced or documented in this
document**. Consequently, this document does **not provide a complete
description of all mandatory, forbidden or optional fields** defined for
E2, E3 and E4 in the eForms SDK.

For the full specification of the notices, including all Business Terms,
codelists and validation rules defined by OP TED, readers should refer
to the official eForms documentation.

### Normative language 

The key words MUST, MUST NOT, REQUIRED, SHALL, SHALL NOT, SHOULD, SHOULD
NOT, RECOMMENDED, MAY, and OPTIONAL in this document are to be
interpreted as described in RFC 2119 and RFC 8174.

These words are normative only when they appear in all capitals.

In addition, the term NOTE is used to indicate non-normative
information.

## **Terminology and Symbols**

The following terms and symbols are used in the tables and diagrams
below.

### Acronymes and abbreviations

  -----------------------------------------------------------------------
  BG         Business Group
  ---------- ------------------------------------------------------------
  BT         Business Term

  CA         Contracting Authority

  CAN        Contract Award Notice

  CE         Contracting Entity

  CFC        Call For Competition

  CM         Contract Modification

  CN         Contract Notice

  ePO        eProcurement Ontology

  Nob        Norwegian Bokmål

  FA         Framework Agreement

  OJEU       Official Journal of the European Union

  OP         Publications Office of the European Union

  OPP        OP Production Term

  OPT        OP Technical Term

  PIN        Prior Information Notice

  PMC        Pre-Market Consultation
  -----------------------------------------------------------------------

### Structural Types

  ------------------------------------------------------------------------------------
  **Type**        **Icon**   **Description**
  --------------- ---------- ---------------------------------------------------------
  **SECTION**     🗂️         In this document, a SECTION refers to a top-level
                             conceptual area in the notice structure. In the XML
                             hierarchy, a SECTION corresponds to a major container
                             element or a logical grouping of root-level elements that
                             define a primary domain. A SECTION contains one or more
                             GROUP elements or FIELDS. In the user interface, a
                             SECTION is typically or **MAY** be represented as a main
                             heading, tab, or primary accordion panel.

  **GROUP**       🧩         In this document, a GROUP refers to a nested container
                             (aggregate element) within a SECTION or another GROUP. In
                             the XML hierarchy, a GROUP corresponds to a complex
                             element that organizes related information or fields. In
                             the user interface, a GROUP is typically rendered as a
                             fieldset, card, or subsection within a SECTION.

  **FIELD**       📝         In this document, a FIELD refers to a BT-field, an
                             OPT-field or an OPP-field, which is usually a leaf
                             element containing a single data value. In the user
                             interface, this corresponds to an input control where the
                             user enters information or views information (e.g. text
                             box, dropdown, date picker).

  **ATTRIBUTE**   🏷️         In this document, an ATTRIBUTE refers to an XML
                             **attribute** attached to an element, providing
                             additional metadata about the element (e.g. \@schemeName,
                             \@listName, \@currencyID). Attributes refine or qualify
                             the element value and do not exist independently.
  ------------------------------------------------------------------------------------

### Field Types and UI-elements

The field types and how it MAY be presented to the user:

+-------+--------------------------------------------------------------+
| **T   | **Description**                                              |
| ype** |                                                              |
+=======+==============================================================+
| **T   | A textbox, as a standard single-line text input (e.g. Name), |
| EXT** | or a text area with multi-line text input (e.g.              |
|       | Description).                                                |
+-------+--------------------------------------------------------------+
| **C   | A combobox/dropdown list where the user selects one value    |
| ODE** | from a predefined list.\                                     |
|       | Radio buttons where all options are visible, but only one    |
|       | may be selected.                                             |
|       |                                                              |
|       | A checkbox control, that allows multiple selections (e.g.    |
|       | CPV codes).                                                  |
+-------+--------------------------------------------------------------+
| **I   | A toggle switch, radio button, checkbox control that         |
| NDICA | represent Yes/No.                                            |
| TOR** |                                                              |
+-------+--------------------------------------------------------------+
| *     | A standard single-line text input or noneditable.            |
| *ID** |                                                              |
+-------+--------------------------------------------------------------+
| **D   | A date-input control (e.g. calendar or wheel-style date      |
| ATE** | picker).                                                     |
+-------+--------------------------------------------------------------+
| **NUM | A numeric input field that only accepts numbers.             |
| BER** |                                                              |
+-------+--------------------------------------------------------------+
| **    | A field validated for web addresses (URLs).                  |
| URL** |                                                              |
+-------+--------------------------------------------------------------+

### Field Properties

  -----------------------------------------------------------------------------------
  **Symbol**   **Term**         **Meaning**
  ------------ ---------------- -----------------------------------------------------
  🔒           **Hidden**       The field or element exists in the data structure but
                                **SHOULD NOT** be displayed in the user interface. It
                                is intended for technical fields that are populated
                                automatically.

  👁️           **Read-only**    The field or element **MUST/MAY?** be displayed in
                                the user interface but **MUST NOT** be editable by
                                the user. It is typically used for data retrieved
                                from external systems.

  🔄           **Repeatable**   The field or element **MAY** occur multiple times.
                                The implementation **MUST** support multiple
                                instances where the field is defined as repeatable.
  -----------------------------------------------------------------------------------

# 2. Form Types, Notice Types and Subtypes

eForms are structured in three hierarchical layers: **Form Type**,
**Notice Type**, and **Notice Subtype**.

**Form Types** define the overall structural template of a notice. They
determine the general XML structure, and which groups and Business Terms
may be included. The eForms Regulation identifies the following form
types: Consultation, Planning, Competition, Direct Award
Pre-notification, Result, Contract Modification, Completion, and Change.

**Notice Types** represent the legal publication category within a form
type, such as PIN, CN and CAN. The notice type determines the legal
purpose of the publication, and which information elements are required.

**Notice Subtypes** provide further specialization of a Notice Type.
Subtypes are used to adapt a notice to specific regulatory contexts.
Most subtypes fall under the EU Procurement Directives. Some subtypes
may be used under any law (E1 and E5), while others may be used under
any other applicable legal framework (E2, E3, E4, and E6). The latter
category is where national tailoring is implemented, including adjusted
mandatory fields, national code lists, and validation rules.

For an overview of all subtypes, their official Norwegian names, and
their corresponding regulations, sees the \[Doffin eForms overview\].
The notice subtypes with the prefix **"E"**, are not included.

# 3. National eForms (Norwegian tailored)

The Norwegian tailored eForms build upon the notice subtypes with the
prefix **"E"**, which were introduced with eForms SDK version 1.13 to
facilitate national tailoring.

Since the introduction of eForms in 2023, Doffin has been using cloned
versions of subtypes **4 (PIN)**, **16 (CN)**, and **29 (CAN)** for
procurements beneath the thresholds, prefixed with the letter **"N"**.

The intention is to gradually phase out the use of **N4**, **N16**, and
**N29**, replacing them with **E2 (PIN)**, **E3 (CN)**, and **E4
(CAN)**.

Currently, subtypes **E2**, **E3**, and **E4** covers the main phases of
a typical public procurement procedure in Norway in terms of notice
publication -- planning, competition and result. These notice subtypes
may be used for procurements carried out in accordance with:

-   Public Procurement Regulations

-   Concession Contracts Regulations

-   Utility Regulations

The forms are not intended for procurements conducted under the Defence
and Security Procurement Regulation (FOSA).

If a need for subtypes **E1** (PMC), **E5** (Contract completion), or
**E6** (CM) is identified at a later stage, these will be tailored and
supported accordingly.

## E2 \| National Prior Information Notice 

### **Purpose**

Nob: \[Nasjonal veiledende kunngjøring som kun brukes til informasjon\]

Used to announce planned procurements below the EU/EEA thresholds for
information purposes, providing early market visibility without
initiating a competition procedure.

### **Document references**

[Business rules for notice sub-type E2 :: TED Developer
Docs](https://docs.ted.europa.eu/eforms/latest/reference/business-rules/notice-subtype-E2.html)

### **Norwegian Tailoring**

+---------+-------+---------------+------+-----------------------------+
| **Fie   | **Ti  | **XPath**     | **   | **Norwegian Tailoring**     |
| ld-ID** | tle** |               | Data |                             |
|         |       |               | ty   |                             |
|         |       |               | pe** |                             |
+=========+=======+===============+======+=============================+
| 📝      | Pre   | */\*/c        | TEXT | Mandatory if Previous       |
| BT-1    | vious | ac:Procuremen | (ID) | Planning Identifier         |
| 251-Lot | Pla   | tProjectLot\[ |      | (BT-125(i)-Lot) is present. |
|         | nning | cbc:ID/@schem |      |                             |
|         | Part  | eName=\'Part\ |      |                             |
|         | Ident | '\]/cac:Tende |      |                             |
|         | ifier | ringProcess/c |      |                             |
|         |       | ac:NoticeDocu |      |                             |
|         |       | mentReference |      |                             |
|         |       | /cbc:Referenc |      |                             |
|         |       | edDocumentInt |      |                             |
|         |       | ernalAddress* |      |                             |
+---------+-------+---------------+------+-----------------------------+
| 📝BT-0  | Proc  | /\*/ca        | ID   | Mandatory: Always Mandatory |
| 1(c)-Pr | edure | c:TenderingTe |      | in E2.                      |
| ocedure | Legal | rms/cac:Procu |      |                             |
|         | Basis | rementLegisla |      | 🏷️\[@schemeName='ELI'\]     |
|         |       | tionDocumentR |      |                             |
|         |       | eference\[not |      | BT-01(c) shall be used to   |
|         |       | (cbc:ID/text( |      | reference the applicable    |
|         |       | )=(\'CrossBor |      | Norwegian procurement       |
|         |       | derLaw\',\'Lo |      | regulations using ELI       |
|         |       | calLegalBasis |      | (European Legislation       |
|         |       | \'))\]/cbc:ID |      | Identifier).                |
+---------+-------+---------------+------+-----------------------------+
| 📝BT-0  | Proc  | /\*/cac:Te    | TEXT | Mandatory: Always Mandatory |
| 1(d)-Pr | edure | nderingTerms/ |      | in E2.                      |
| ocedure | Legal | cac:Procureme |      |                             |
|         | Basis | ntLegislation |      | Codelist: Free text in      |
|         |       | DocumentRefer |      | BT-01(d) is not allowed in  |
|         |       | ence\[not(cbc |      | E2. Instead, a national     |
|         |       | :ID/text()=(\ |      | controlled codelist is used |
|         |       | 'CrossBorderL |      | to identify the applicable  |
|         |       | aw\',\'LocalL |      | legal basis. The value must |
|         |       | egalBasis\')) |      | be selected from the        |
|         |       | \]/cbc:Docume |      | [predefined                 |
|         |       | ntDescription |      | list]{.underline}.          |
+---------+-------+---------------+------+-----------------------------+
| 📝      | Buyer | /\*/cac:Co    | CODE | Mandatory: Always mandatory |
| BT-11-P | Legal | ntractingPart |      | in E2.                      |
| rocedur | Type  | y/cac:Contrac |      |                             |
| e-Buyer |       | tingPartyType |      | Codelist: The codelist      |
|         |       | /cbc:PartyTyp |      | 🏷️@li                       |
|         |       | eCode\[@listN |      | stName=\'buyer-legal-type\' |
|         |       | ame=\'buyer-l |      | is restricted. Generic      |
|         |       | egal-type\'\] |      | categories (e.g. body-pl,   |
|         |       |               |      | org-sub, pub-undert) are    |
|         |       |               |      | not permitted. Only         |
|         |       |               |      | specific organisational     |
|         |       |               |      | types (e.g. body-pl-cga,    |
|         |       |               |      | body-pl-la, body-pl-ra) may |
|         |       |               |      | be used.                    |
+---------+-------+---------------+------+-----------------------------+
| 📝      | Act   | */\           | CODE | Mandatory: Always mandatory |
| BT-10-P | ivity | */cac:Contrac |      | in E2.                      |
| rocedur | Auth  | tingParty/cac |      |                             |
| e-Buyer | ority | :ContractingA |      |                             |
|         |       | ctivity/cbc:A |      |                             |
|         |       | ctivityTypeCo |      |                             |
|         |       | de\[@listName |      |                             |
|         |       | =\'authority- |      |                             |
|         |       | activity\'\]* |      |                             |
+---------+-------+---------------+------+-----------------------------+

## E3 \| National Contract Notice 

### **Purpose** 

**Nob**: \[Nasjonal kunngjøring av konkurranse\] or \[alminnelig
kunngjøring\]

Used to initiate a procurement procedure below the EU/EEA thresholds by
formally inviting economic operators to submit tenders or requests to
participate.

### **Document references**

[Business rules for notice sub-type E3 :: TED Developer
Docs](https://docs.ted.europa.eu/eforms/latest/reference/business-rules/notice-subtype-E3.html)

### **Norwegian Tailoring**

Unless explicitly stated otherwise, the Norwegian tailoring rules
described for **E2** apply equally to **E3** for the following fields:
BT-01(c)-Procedure, BT-01(d)-Procedure, BT-11-Procedure-Buyer,
BT-10-Procedure-Buyer. Only deviations specific to **E3** are documented
in this section.

+--------+-------+----------------+------+---------------------------+
| **Fiel | **Ti  | **XPath**      | **   | **Norwegian Tailoring**   |
| d-ID** | tle** |                | Data |                           |
|        |       |                | ty   |                           |
|        |       |                | pe** |                           |
+========+=======+================+======+===========================+
| 📝     | Pre   | */\*/cac       | TEXT | Mandatory: Always         |
| BT-12  | vious | :ProcurementPr | (ID) | mandatory in E3.          |
| 51-Lot | Pla   | ojectLot\[cbc: |      |                           |
|        | nning | ID/@schemeName |      |                           |
|        | Part  | =\'Lot\'\]/cac |      |                           |
|        | Ident | :TenderingProc |      |                           |
|        | ifier | ess/cac:Notice |      |                           |
|        |       | DocumentRefere |      |                           |
|        |       | nce/cbc:Refere |      |                           |
|        |       | ncedDocumentIn |      |                           |
|        |       | ternalAddress* |      |                           |
+--------+-------+----------------+------+---------------------------+
| 📝     | Fram  | */\*/cac:Proc  | CODE | Mandatory: Always         |
| BT-7   | ework | urementProject |      | mandatory in E3.          |
| 65-Lot | Agre  | Lot\[cbc:ID/@s |      |                           |
|        | ement | chemeName=\'Lo |      |                           |
|        |       | t\'\]/**cac:Te |      |                           |
|        |       | nderingProcess |      |                           |
|        |       | /**cac:Contrac |      |                           |
|        |       | tingSystem\[** |      |                           |
|        |       | cbc:Contractin |      |                           |
|        |       | gSystemTypeCod |      |                           |
|        |       | e/@listName=\' |      |                           |
|        |       | framework-agre |      |                           |
|        |       | ement\'\]/**cb |      |                           |
|        |       | c:ContractingS |      |                           |
|        |       | ystemTypeCode* |      |                           |
+--------+-------+----------------+------+---------------------------+
| 📝     | Submi | */\*/cac:P     | CODE | Mandatory: Always         |
| BT-    | ssion | rocurementProj | (IN  | mandatory in E3.          |
| 17-Lot | Elect | ectLot\[cbc:ID | DICA |                           |
|        | ronic | /@schemeName=\ | TOR) |                           |
|        |       | 'Lot\'\]/cac:T |      |                           |
|        |       | enderingProces |      |                           |
|        |       | s/cbc:Submissi |      |                           |
|        |       | onMethodCode\[ |      |                           |
|        |       | @listName=\'es |      |                           |
|        |       | ubmission\'\]* |      |                           |
+--------+-------+----------------+------+---------------------------+
| 📝     | Submi | */\*/ca        | CODE | Mandatory if no           |
| BT-    | ssion | c:ProcurementP |      | electronic submission may |
| 19-Lot | Non-  | rojectLot\[cbc |      | take place (BT-17-Lot ==  |
|        | elect | :ID/@schemeNam |      | \'not-allowed\').         |
|        | ronic | e=\'Lot\'\]/ca |      |                           |
|        | Jus   | c:TenderingPro |      | **ELLER**                 |
|        | tific | cess/cac:Proce |      |                           |
|        | ation | ssJustificatio |      | Mandatory: Always         |
|        |       | n/cbc:ProcessR |      | mandatory in E3.          |
|        |       | easonCode\[@li |      |                           |
|        |       | stName=\'no-es |      |                           |
|        |       | ubmission-just |      |                           |
|        |       | ification\'\]* |      |                           |
+--------+-------+----------------+------+---------------------------+
| 📝     | Submi | */\*/cac:Pr    | TEXT | Mandatory if no           |
| BT-7   | ssion | ocurementProje |      | electronic submission may |
| 45-Lot | Non-  | ctLot\[cbc:ID/ |      | take place (BT-17-Lot ==  |
|        | elect | @schemeName=\' |      | \'not-allowed\').         |
|        | ronic | Lot\'\]/cac:Te |      |                           |
|        | D     | nderingProcess |      |                           |
|        | escri | /cac:ProcessJu |      |                           |
|        | ption | stification/cb |      |                           |
|        |       | c:Description* |      |                           |
+--------+-------+----------------+------+---------------------------+
| 📝     | Docu  | */\*/ca        | CODE | Mandatory: Always         |
| BT-    | ments | c:ProcurementP |      | mandatory in E3. **????** |
| 14-Lot | Restr | rojectLot\[cbc |      |                           |
|        | icted | :ID/@schemeNam |      |                           |
|        |       | e=\'Lot\'\]/ca |      |                           |
|        |       | c:TenderingTer |      |                           |
|        |       | ms/cac:CallFor |      |                           |
|        |       | TendersDocumen |      |                           |
|        |       | tReference/cbc |      |                           |
|        |       | :DocumentType* |      |                           |
+--------+-------+----------------+------+---------------------------+

## E4 \| National Contract Award Notice 

### **Purpose**

Nob: \[Nasjonal kunngjøring av kontraktsinngåelse\]

Used to announce the result of a completed procurement procedure below
the EU/EEA thresholds.

### **Document references**

[Business rules for notice sub-type E4 :: TED Developer
Docs](https://docs.ted.europa.eu/eforms/latest/reference/business-rules/notice-subtype-E4.html)

### **Norwegian Tailoring**

The Norwegian tailoring rules described for **E2** apply equally to
**E4** for the following fields: BT-01(c)-Procedure, BT-01(d)-Procedure,
BT-11-Procedure-Buyer, BT-10-Procedure-Buyer. As well does the rules
described for the following fields in **E3**: BT-1251-Lot, and
BT-765-Lot. Only deviations specific to **E3** are documented in this
section.

  ----------------------------------------------------------------------------------
  **Field-ID**   **Title**   **XPath**         **Data   **Norwegian Tailoring**
                                               type**   
  -------------- ----------- ----------------- -------- ----------------------------
  📝 BT-                     */\*/*                     

  ----------------------------------------------------------------------------------
