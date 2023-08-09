<?xml version="1.0" encoding="utf-8" ?>
<schema xmlns="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt2">

    <!-- UBL -->
    <ns prefix="can" uri="urn:oasis:names:specification:ubl:schema:xsd:ContractAwardNotice-2" />
    <ns prefix="cn" uri="urn:oasis:names:specification:ubl:schema:xsd:ContractNotice-2" />
    <ns prefix="pin" uri="urn:oasis:names:specification:ubl:schema:xsd:PriorInformationNotice-2" />
    <ns prefix="cbc" uri='urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2' />
    <ns prefix="cac" uri="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2" />
    <ns prefix="ext" uri="urn:oasis:names:specification:ubl:schema:xsd:CommonExtensionComponents-2" />
    
    <!-- OP -->
    <ns prefix="efac" uri="http://data.europa.eu/p27/eforms-ubl-extension-aggregate-components/1" />
    <ns prefix="efext" uri="http://data.europa.eu/p27/eforms-ubl-extensions/1" />
    <ns prefix="efbc" uri="http://data.europa.eu/p27/eforms-ubl-extension-basic-components/1" />

    <title>Norwegian tailoring (${KIND}) for eForms ${EFORMS_VERSION}</title>

    <!-- Variables -->
    <let name="noticeSubType" value="replace(/*/ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/efext:EformsExtension/efac:NoticeSubType/cbc:SubTypeCode/normalize-space(), 'N', '')"/>
    <let name="official_languages" value="('BUL', 'CES', 'DAN', 'DEU', 'ELL', 'ENG', 'EST', 'FIN', 'FRA', 'GLE', 'HRV', 'HUN', 'ITA', 'LAV', 'LIT', 'MLT', 'NLD', 'POL', 'POR', 'RON', 'SLK', 'SLV', 'SPA', 'SWE')"/>

    <include href="fields.sch"/>

</schema>