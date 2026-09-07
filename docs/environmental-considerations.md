## Environmental considerations

### Norwegian eForms extension for compliance with Norwegian Procurement Regulations

For contracting authorities to indicate compliance with [Section 7-9 of Norway's Procurement Regulations](https://lovdata.no/forskrift/2016-08-12-974/§7-9), we have extended the codelist for specifying _award criterion types_. 

The extension is described in a structured format here: [codelist-no/award-criterion-type.no.yaml](../src/codelists-no/award-criterion-type.no.yaml). 

The extensions are patched into our validator, as described here: [patch/eforms-sdk-nor/1.13/0001-environment-codes.patch](../src/patch/eforms-sdk-nor/1.13/0001-environment-codes.patch).

### Encoding in national notices (E3)

The codes are placed as `cac:SubordinateAwardingCriterion` elements (BT-539) in the same `cac:AwardingCriterion` group as the ordinary award criteria. They fall into two categories with different encoding rules, enforced by `EFORMS-NOR-NATIONAL-EC-R001D` and `EFORMS-NOR-NATIONAL-EC-R001E` in [fields/national-e.yaml](../src/fields/national-e.yaml):

| Code | Nature | Weight / rank (BT-541, BT-5421) |
|------|--------|---------------------------------|
| `quality-nor-env-criteria` | A real award criterion that tenders are evaluated against | Encoded like any other award criterion: `per-exa` (weight ≥ 30 % in total) or `ord-imp` (among the three highest ranked). |
| `quality-nor-env-spec`, `quality-nor-env-exempt-*` | A *statement* of how the climate- and environmental obligation is met (requirements in the specifications, or an exemption). Not an award criterion. | Must **not** take part in the weighting or ranking. Either **omit** `efac:AwardCriterionParameter[efbc:ParameterCode/@listName='number-weight']` entirely, or state `per-exa` with `efbc:ParameterNumeric` = `0`. A non-empty `cbc:Description` (BT-540) with the justification is required. |

Both encodings of the statement codes are accepted so that the group stays valid under the generic eForms rules regardless of how the ordinary criteria are expressed:

* **Percentage model** (`per-exa`): `per-exa` 0 does not change the sum of 100 (BR-BT-00539-0200). Omitting the parameter is equally valid.
* **Order of importance** (`ord-imp`): BR-BT-00539-0194 requires every criterion *with* a weight type in the group to use `ord-imp`, and BR-BT-00539-0200 requires the `per-exa` weights to sum to 100 as soon as one exists. A `per-exa` 0 marker would violate both, so the parameter must be omitted for the statement code. Criteria without a weight type are ignored by both rules.

Example of a ranked group with climate- and environmental requirements in the specifications:

```xml
<cac:AwardingCriterion>
  <cac:SubordinateAwardingCriterion>
    <!-- ord-imp 1 -->
    <cbc:AwardingCriterionTypeCode listName="award-criterion-type">quality</cbc:AwardingCriterionTypeCode>
    ...
  </cac:SubordinateAwardingCriterion>
  <cac:SubordinateAwardingCriterion>
    <!-- ord-imp 2 -->
    <cbc:AwardingCriterionTypeCode listName="award-criterion-type">price</cbc:AwardingCriterionTypeCode>
    ...
  </cac:SubordinateAwardingCriterion>
  <cac:SubordinateAwardingCriterion>
    <!-- no efac:AwardCriterionParameter -->
    <cbc:AwardingCriterionTypeCode listName="award-criterion-type">quality-nor-env-spec</cbc:AwardingCriterionTypeCode>
    <cbc:Name languageID="NOR">Klima- og miljøhensyn</cbc:Name>
    <cbc:Description languageID="NOR">Klima- og miljøhensyn er ivaretatt gjennom krav i kravspesifikasjonen.</cbc:Description>
  </cac:SubordinateAwardingCriterion>
</cac:AwardingCriterion>
```

Note that `quality-nor-env-criteria` and `quality-nor-env-spec` also require the strategic-procurement code `env-imp` (BT-06-Lot) on the lot (`EFORMS-NOR-NATIONAL-SP-R004`), which in turn makes the strategic procurement description (BT-777-Lot, `cbc:ProcurementType`) mandatory under the generic eForms rules (BR-BT-00777-0026).

See the `*-env-spec*` and `*-env-exempt*` fixtures in [tests/national-e](../src/tests/national-e/) for complete notices covering both models.
