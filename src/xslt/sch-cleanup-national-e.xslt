<?xml version="1.0" encoding="utf-8" ?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:sch="http://purl.oclc.org/dsdl/schematron"
                version="2.0">

    <xsl:param name="removed" select="NA"/>
    <xsl:variable name="removed_parsed" select="tokenize($removed, ',')"/>

    <!-- Default behaviour: Copy as-is -->
    <xsl:template match="@* | node()">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>


    <!-- Things to remove -->
    <!--
      E2 cleanup: remove ALL rules that reference noticeSubType,
      except E2-E4
    -->
    <xsl:template match="sch:rule[contains(@context, 'noticeSubType') and not(matches(@context, '''E[2-4]'''))]" priority="300"/>
     <!-- Drop EU numerical notice subtypes (1–40 etc.) -->
    <xsl:template match="sch:rule[contains(@context, 'noticeSubType') and matches(@context, '''[0-9]{1,2}''')]" priority="250"/>
	<!-- Remove validation of specific fields -->
    <xsl:template match="sch:assert[@id = 'BR-BT-00702-0102']"/>
    <xsl:template match="sch:rule[@context = '/*/cbc:CustomizationID']" />
    <xsl:template match="sch:rule[@context = '/*/cac:AdditionalNoticeLanguage/cbc:ID']" />

    <!-- Remove removed fields -->
    <xsl:template match="sch:assert[@diagnostics = $removed_parsed or @id = $removed_parsed]"/>

    <!-- Remove schema types -->
    
    <!-- Fix of regexes with at least amount of chars -->
    <xsl:template match="sch:assert[matches(@test, '\{\d,\}')]">
        <xsl:copy>
            <xsl:copy-of select="@id"/>
            <xsl:copy-of select="@role"/>
            <xsl:attribute name="test" select="replace(@test, '\{(\d),\}', '{$1,63}')"/>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>

</xsl:stylesheet>