<?xml version="1.0" encoding="utf-8" ?>
<!--
Stylesheet used to convert eForms notifications created according to Norwegian rules to a notification accepted by TED.
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2"
                xmlns:ext="urn:oasis:names:specification:ubl:schema:xsd:CommonExtensionComponents-2"
                xmlns:efext="http://data.europa.eu/p27/eforms-ubl-extensions/1"
                xmlns:efac="http://data.europa.eu/p27/eforms-ubl-extension-aggregate-components/1"
                version="2.0">

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

    <!-- Remove traces of non-EU languages -->
    <xsl:template match="/*/ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/efext:EformsExtension/efac:NonOfficialLanguages"/>
    <xsl:template match="cbc:*[@languageID='NOR']"/>
    <xsl:template match="cbc:*[@languageID='NNO']"/>
    <xsl:template match="cbc:*[@languageID='NOB']"/>
    
</xsl:stylesheet>