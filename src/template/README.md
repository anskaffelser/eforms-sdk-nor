# eForms SDK ${EFORMS_VERSION} NOR (Norway) ${VERSION}

This package is modified variant of the [official eForms SDK](https://github.com/OP-TED/eForms-SDK) ${EFORMS_VERSION}.


## Contents

The following folders contains modified content:

    * `codelists` - Translations are added to existing code list files
    * `fields` - Field definitions used above and below thresholds
    * `schemas` - Modified XSDs for Norwegian notices (applies to only 1.6 and 1.7)
    * `schematrons` - Additional files for Norwegian notices and modified editions of the original files
    * `translations` - Additional translation files are added

The following folders contains new content:

    * `xslt` - Stylesheet to modify Norwegian notices into notices accepted by TED

The rest of the files in this package contains no modifications.

Please see the [information on Anskaffelser.no](https://anskaffelser.no/dfos-arbeid-med-offentlige-anskaffelser/program-digitale-anskaffelser/nye-kunngjoringsskjemaer-eforms) for information related to tailoring for the Norwegian market.


## Validation

The contents of the `schematron` folder contains modified Schematron files based upon the original Schematron files from the official eForms SDK and Schematron files containing rules created for the Norwegian eForms SDK.

In addition to XSD files, the following files are used during validation:

* Notices to be published to Doffin and TED:
  * `eu-eforms-dynamic.sch` or `eu-eforms-static.sch`
  * `eu-norway.sch`

* Norices to be published to Doffin only:
  * `national-eforms-dynamic.sch` or `national-eforms-static.sch`
  * `national-norway.sch`

Any files not passing the XSD validation or triggering `failed-assert` containing a `@role` with value `ERROR` are not accepted by Doffin.


## Licensing

eForms SDK is licensed under the [Creative Commons Attribution 4.0 International License](https://creativecommons.org/licenses/by/4.0/).

Additions made available in this package is licensed under the [Creative Commons Attribution 4.0 International License](https://creativecommons.org/licenses/by/4.0/).