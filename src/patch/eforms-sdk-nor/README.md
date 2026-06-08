# Patches – eforms-sdk-nor

## `0001-environment-codes.patch`

Adds three Norwegian extension codes to the `award-criterion-type` codelist and updates
BT-539 validation in schematron files to accept them
[§ 7-9 of Norway's Procurement Regulations](https://lovdata.no/forskrift/2016-08-12-974/§7-9).

### New codes

| Code | Description |
|---|---|
| `quality-nor-env-criteria` | Kvalitet – klima- og miljøkriterium |
| `quality-nor-env-spec` | Kvalitet – klima- og miljøkrav i kravspesifikasjonen (begrunnes under) |
| `quality-nor-env-none` | Kvalitet – uvesentlig klimaavtrykk og miljøbelastning (begrunnes under) |

### Patched files

| File | Scope 
|---|---|
| `national-eforms-static.sch` | National, above threshold
| `national-eforms-dynamic.sch` | National, above threshold 
| `national-e-eforms-static.sch` | National, below threshold 
| `national-e-eforms-dynamic.sch` | National, below threshold

EU schematrons are not patched. Norwegian extension codes are not used in EU procurements.
