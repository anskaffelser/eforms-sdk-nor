<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns="http://purl.oclc.org/dsdl/schematron"
    xmlns:sch="http://purl.oclc.org/dsdl/schematron"
    exclude-result-prefixes="sch"
    version="2.0">

    <xsl:param name="language" select="'en'"/>

    <!-- Load translation -->
    <xsl:variable name="translations" select="document(concat('../../target/eforms-sdk/translations/rule_', $language, '.xml'))"/>

    <!-- Modify cloning of asserts to make sure we update translation -->
    <xsl:template match="sch:assert[starts-with(normalize-space(), 'rule|')]">
        <xsl:variable name="key" select="normalize-space()"/>
        
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:choose>
                <xsl:when test="$translations/properties/entry[@key = $key]">
                    <xsl:value-of select="$translations/properties/entry[@key = $key]/normalize-space()"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>Message missing: <xsl:value-of select="$key"/></xsl:message>
                    <xsl:apply-templates select="normalize-space()"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:copy>
    </xsl:template>

    <!-- Simply cloning -->
    <xsl:template match="node()|@*">
        <xsl:copy>
            <xsl:apply-templates select="node()|@*"/>
        </xsl:copy>
    </xsl:template>
    
</xsl:stylesheet>