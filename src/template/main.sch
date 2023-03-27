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

    <title>Norwegian tailoring (${KIND} threshold) for eForms ${EFORMS_VERSION}</title>

    <let name="noticeSubType" value="/*/ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/efext:EformsExtension/efac:NoticeSubType/cbc:SubTypeCode/normalize-text()"/>
    <let name="is1" value="$${q}noticeSubType = '1'"/>
    <let name="is2" value="$${q}noticeSubType = '2'"/>
    <let name="is3" value="$${q}noticeSubType = '3'"/>
    <let name="is4" value="$${q}noticeSubType = '4'"/>
    <let name="is5" value="$${q}noticeSubType = '5'"/>
    <let name="is6" value="$${q}noticeSubType = '6'"/>
    <let name="is7" value="$${q}noticeSubType = '7'"/>
    <let name="is8" value="$${q}noticeSubType = '8'"/>
    <let name="is9" value="$${q}noticeSubType = '9'"/>
    <let name="is10" value="$${q}noticeSubType = '10'"/>
    <let name="is11" value="$${q}noticeSubType = '11'"/>
    <let name="is12" value="$${q}noticeSubType = '12'"/>
    <let name="is13" value="$${q}noticeSubType = '13'"/>
    <let name="is14" value="$${q}noticeSubType = '14'"/>
    <let name="is15" value="$${q}noticeSubType = '15'"/>
    <let name="is16" value="$${q}noticeSubType = '16'"/>
    <let name="is17" value="$${q}noticeSubType = '17'"/>
    <let name="is18" value="$${q}noticeSubType = '18'"/>
    <let name="is19" value="$${q}noticeSubType = '19'"/>
    <let name="is20" value="$${q}noticeSubType = '20'"/>
    <let name="is21" value="$${q}noticeSubType = '21'"/>
    <let name="is22" value="$${q}noticeSubType = '22'"/>
    <let name="is23" value="$${q}noticeSubType = '23'"/>
    <let name="is24" value="$${q}noticeSubType = '24'"/>
    <let name="is25" value="$${q}noticeSubType = '25'"/>
    <let name="is26" value="$${q}noticeSubType = '26'"/>
    <let name="is27" value="$${q}noticeSubType = '27'"/>
    <let name="is28" value="$${q}noticeSubType = '28'"/>
    <let name="is29" value="$${q}noticeSubType = '29'"/>
    <let name="is30" value="$${q}noticeSubType = '30'"/>
    <let name="is31" value="$${q}noticeSubType = '31'"/>
    <let name="is32" value="$${q}noticeSubType = '32'"/>
    <let name="is33" value="$${q}noticeSubType = '33'"/>
    <let name="is34" value="$${q}noticeSubType = '34'"/>
    <let name="is35" value="$${q}noticeSubType = '35'"/>
    <let name="is36" value="$${q}noticeSubType = '36'"/>
    <let name="is37" value="$${q}noticeSubType = '37'"/>
    <let name="is38" value="$${q}noticeSubType = '38'"/>
    <let name="is39" value="$${q}noticeSubType = '39'"/>
    <let name="is40" value="$${q}noticeSubType = '40'"/>

</schema>