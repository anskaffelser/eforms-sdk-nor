<?xml version="1.0" encoding="utf-8" ?>
<!--
Stylesheet used to convert eForms notifications created according to Norwegian rules to a notification accepted by TED.
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2"
    xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2"
    xmlns:ext="urn:oasis:names:specification:ubl:schema:xsd:CommonExtensionComponents-2"
    xmlns:efext="http://data.europa.eu/p27/eforms-ubl-extensions/1"
    xmlns:efac="http://data.europa.eu/p27/eforms-ubl-extension-aggregate-components/1"
    xmlns:efbc="http://data.europa.eu/p27/eforms-ubl-extension-basic-components/1" 
    version="2.0">
    
    <!-- List of official EU languages -->
    <xsl:variable name="official_languages" select="('BUL', 'CES', 'DAN', 'DEU', 'ELL', 'ENG', 'EST', 'FIN', 'FRA', 'GLE', 'HRV', 'HUN', 'ITA', 'LAV', 'LIT', 'MLT', 'NLD', 'POL', 'POR', 'RON', 'SLK', 'SLV', 'SPA', 'SWE')"/>
    
    <!-- Copy all content by default -->
    <xsl:template match="@* | node()">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- Change CustomizationID so TED may recognize the notice -->
    <xsl:template match="/*/cbc:CustomizationID">
        <xsl:copy>
            <xsl:value-of select="tokenize(normalize-space(), '#')[1]"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- Remove traces of non-official EU languages -->
    <xsl:template match="/*/ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/efext:EformsExtension/efac:NonOfficialLanguages"/>
    <xsl:template match="efbc:*[@languageID][not(@languageID = $official_languages)]"/>
    <xsl:template match="cbc:*[@languageID][not(@languageID = $official_languages)]"/>
    <xsl:template match="cac:*[count(*) = 1][cbc:*[@languageID][not(@languageID = $official_languages)]]"/>
    
    <!-- Rebuild BT-702 (DEPRECATED) -->
    <xsl:template match="/*/cac:AdditionalNoticeLanguage"/>
    <xsl:template match="/*/cbc:NoticeLanguageCode">
        <xsl:variable name="languages" select="/*/cbc:NoticeLanguageCode[normalize-space() = $official_languages]/normalize-space(), /*/cac:AdditionalNoticeLanguage/cbc:ID[normalize-space() = $official_languages]/normalize-space()"/>
        <cbc:NoticeLanguageCode><xsl:value-of select="$languages[1]"/></cbc:NoticeLanguageCode>
        <xsl:for-each select="$languages[position() > 1]">
            <cac:AdditionalNoticeLanguage>
                <cbc:ID><xsl:value-of select="current()"/></cbc:ID>
            </cac:AdditionalNoticeLanguage>
        </xsl:for-each>
    </xsl:template>
    
</xsl:stylesheet>
