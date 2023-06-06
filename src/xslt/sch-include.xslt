<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns="http://purl.oclc.org/dsdl/schematron"
    xmlns:sch="http://purl.oclc.org/dsdl/schematron"
    exclude-result-prefixes="sch"
    version="2.0">

    <xsl:template match="sch:include">
        <xsl:apply-templates select="document(@href)"/>
    </xsl:template>

    <xsl:template match="sch:assert">
        <xsl:element name="{local-name()}">
            <xsl:if test="@role = 'ERROR'">
                <xsl:attribute name="flag" select="'fatal'"/>
            </xsl:if>
            <xsl:if test="@role = 'WARN'">
                <xsl:attribute name="flag" select="'warning'"/>
            </xsl:if>

            <xsl:apply-templates select="node()|@*"/>
        </xsl:element>
    </xsl:template>

    <!-- Ignore... -->
    <xsl:template match="@flag"/>

    <xsl:template match="node()|@*">
        <xsl:copy>
            <xsl:apply-templates select="node()|@*"/>
        </xsl:copy>
    </xsl:template>
    
</xsl:stylesheet>