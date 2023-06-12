<?xml version="1.0" encoding="utf-8" ?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:sch="http://purl.oclc.org/dsdl/schematron"
                version="2.0">

    <!-- Default behaviour: Copy as-is -->
    <xsl:template match="@* | node()">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>


    <!-- Things to remove -->

    <!-- Remove specific rules -->
    <xsl:template match="sch:assert[ends-with(@id, '_B') and contains(@test, 'NoticeLanguageCode')]"/>
    <xsl:template match="sch:assert[ends-with(@id, '_C') and contains(@test, 'NoticeLanguageCode')]"/>

    <!-- Remove validation of specific fields -->
    <xsl:template match="sch:rule[@context = '/*/cbc:CustomizationID']" />

    <!-- Remove role -->
    <xsl:template match="@role"/>

    <!-- Remove diagnostics -->
    <!-- <xsl:template match="@diagnostics" /> -->
    <xsl:template match="sch:diagnostics" />

    <!-- Remove schema types -->
    <xsl:template match="sch:rule[contains(@context, 'noticeSubType = ''CEI''')]" priority="100"/>
    <xsl:template match="sch:rule[contains(@context, 'noticeSubType = ''T01''')]" priority="100"/>
    <xsl:template match="sch:rule[contains(@context, 'noticeSubType = ''T02''')]" priority="100"/>
    <xsl:template match="sch:rule[contains(@context, 'noticeSubType = ''X01''')]" priority="100"/>
    <xsl:template match="sch:rule[contains(@context, 'noticeSubType = ''X02''')]" priority="100"/>


    <!-- Things to fix -->

    <!-- Make sure flag is set correctly -->
    <xsl:template match="sch:assert">
        <xsl:copy>
            <xsl:if test="not(@flag)">
                <xsl:choose>
                    <xsl:when test="@role = 'ERROR'">
                        <xsl:attribute name="flag" select="'fatal'"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:attribute name="flag" select="@role"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:if>

            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>

    <!-- Testing out method to make validation faster -->
    <xsl:template match="sch:rule[contains(@context, '[$noticeSubType =')]">
        <xsl:copy>
            <xsl:variable name="context" select="substring-before(@context, '[$noticeSubType =')"/>
            <xsl:variable name="selector" select="substring(@context, string-length($context) + 1, string-length(@context))"/>
            <xsl:variable name="document" select="substring-before(substring-after($selector, ''''), '''')"/>
            <xsl:choose>
                <!-- PriorInformationNotice -->
                <xsl:when test="$document = ('1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13', '14')">
                    <xsl:attribute name="context" select="concat('/pin:PriorInformationNotice', $selector, substring($context, 3))"/>
                </xsl:when>
                <!-- ContractNotice -->
                <xsl:when test="$document = ('16', '17', '18', '19', '20', '21', '22', '23', '24')">
                    <xsl:attribute name="context" select="concat('/cn:ContractNotice', $selector, substring($context, 3))"/>
                </xsl:when>
                <xsl:when test="$document = ('25', '26', '27', '28', '29', '30', '31', '32', '33', '34', '35', '36', '37', '38', '39', '40')">
                <!-- ContractAwardNotice -->
                <xsl:attribute name="context" select="concat('/can:ContractAwardNotice', $selector, substring($context, 3))"/>
                </xsl:when>
                <!-- Fallback -->
                <xsl:otherwise>
                    <xsl:attribute name="context" select="concat('/*', $selector, substring($context, 3))"/>
                </xsl:otherwise>
            </xsl:choose>

            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>

</xsl:stylesheet>