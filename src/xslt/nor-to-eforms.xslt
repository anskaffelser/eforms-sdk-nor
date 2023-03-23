<?xml version="1.0" encoding="utf-8" ?>
<!--
Stylesheet used to convert eForms notifications created according to Norwegian rules to a notification accepted by TED.
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2"
                version="2.0">

    <xsl:template match="@* | node()">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="/*/cbc:CustomizationID">
        <xsl:copy>
            <xsl:value-of select="tokenize(normalize-space(), '#')[1]"/>
        </xsl:copy>
    </xsl:template>

</xsl:stylesheet>