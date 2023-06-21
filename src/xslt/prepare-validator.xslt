<?xml version="1.0" encoding="utf-8" ?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns="http://purl.oclc.org/dsdl/schematron"
    xmlns:sch="http://purl.oclc.org/dsdl/schematron"
    exclude-result-prefixes="sch"
    version="2.0">

    <!-- Copy -->
    <xsl:template match="node()|@*">
        <xsl:copy>
            <xsl:apply-templates select="node()|@*"/>
        </xsl:copy>
    </xsl:template>

    <!-- Append flag -->
    <xsl:template match="@role">
        <xsl:attribute name="role" select="current()"/>
        
        <xsl:choose>
            <xsl:when test="normalize-space() = 'WARN'">
                <xsl:attribute name="flag" select="'warning'"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:attribute name="flag" select="'fatal'"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Remove -->    
    <xsl:template match="@flag"/>
    <xsl:template match="@diagnostics"/>
    <xsl:template match="sch:diagnostic"/>

</xsl:stylesheet>