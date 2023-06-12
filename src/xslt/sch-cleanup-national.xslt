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

    <!-- Remove validation of specific fields -->
    <xsl:template match="sch:rule[@context = '/*/cbc:CustomizationID']" />
    <xsl:template match="sch:rule[@context = '/*/cbc:NoticeLanguageCode']" />
    <xsl:template match="sch:rule[@context = '/*/cac:AdditionalNoticeLanguage/cbc:ID']" />

    <!-- Remove role -->
    <xsl:template match="@role"/>

    <!-- Remove diagnostics -->
    <!-- <xsl:template match="@diagnostics" /> -->
    <xsl:template match="sch:diagnostics" />

    <!-- Remove schema types -->
    <xsl:template match="sch:rule[contains(@context, 'noticeSubType = ''1''')]" priority="100"/>
    <xsl:template match="sch:rule[contains(@context, 'noticeSubType = ''2''')]" priority="100"/>
    <xsl:template match="sch:rule[contains(@context, 'noticeSubType = ''3''')]" priority="100"/>
    <xsl:template match="sch:rule[contains(@context, 'noticeSubType = ''4''')]" priority="100"/>
    <xsl:template match="sch:rule[contains(@context, 'noticeSubType = ''5''')]" priority="100"/>
    <xsl:template match="sch:rule[contains(@context, 'noticeSubType = ''6''')]" priority="100"/>
    <xsl:template match="sch:rule[contains(@context, 'noticeSubType = ''7''')]" priority="100"/>
    <xsl:template match="sch:rule[contains(@context, 'noticeSubType = ''8''')]" priority="100"/>
    <xsl:template match="sch:rule[contains(@context, 'noticeSubType = ''9''')]" priority="100"/>
    <xsl:template match="sch:rule[contains(@context, 'noticeSubType = ''10''')]" priority="100"/>
    <xsl:template match="sch:rule[contains(@context, 'noticeSubType = ''11''')]" priority="100"/>
    <xsl:template match="sch:rule[contains(@context, 'noticeSubType = ''12''')]" priority="100"/>
    <xsl:template match="sch:rule[contains(@context, 'noticeSubType = ''13''')]" priority="100"/>
    <xsl:template match="sch:rule[contains(@context, 'noticeSubType = ''14''')]" priority="100"/>
    <xsl:template match="sch:rule[contains(@context, 'noticeSubType = ''15''')]" priority="100"/>
    <xsl:template match="sch:rule[contains(@context, 'noticeSubType = ''17''')]" priority="100"/>
    <xsl:template match="sch:rule[contains(@context, 'noticeSubType = ''18''')]" priority="100"/>
    <xsl:template match="sch:rule[contains(@context, 'noticeSubType = ''19''')]" priority="100"/>
    <xsl:template match="sch:rule[contains(@context, 'noticeSubType = ''20''')]" priority="100"/>
    <xsl:template match="sch:rule[contains(@context, 'noticeSubType = ''21''')]" priority="100"/>
    <xsl:template match="sch:rule[contains(@context, 'noticeSubType = ''22''')]" priority="100"/>
    <xsl:template match="sch:rule[contains(@context, 'noticeSubType = ''23''')]" priority="100"/>
    <xsl:template match="sch:rule[contains(@context, 'noticeSubType = ''24''')]" priority="100"/>
    <xsl:template match="sch:rule[contains(@context, 'noticeSubType = ''25''')]" priority="100"/>
    <xsl:template match="sch:rule[contains(@context, 'noticeSubType = ''26''')]" priority="100"/>
    <xsl:template match="sch:rule[contains(@context, 'noticeSubType = ''27''')]" priority="100"/>
    <xsl:template match="sch:rule[contains(@context, 'noticeSubType = ''28''')]" priority="100"/>
    <xsl:template match="sch:rule[contains(@context, 'noticeSubType = ''29''')]" priority="100"/>
    <xsl:template match="sch:rule[contains(@context, 'noticeSubType = ''31''')]" priority="100"/>
    <xsl:template match="sch:rule[contains(@context, 'noticeSubType = ''32''')]" priority="100"/>
    <xsl:template match="sch:rule[contains(@context, 'noticeSubType = ''33''')]" priority="100"/>
    <xsl:template match="sch:rule[contains(@context, 'noticeSubType = ''34''')]" priority="100"/>
    <xsl:template match="sch:rule[contains(@context, 'noticeSubType = ''35''')]" priority="100"/>
    <xsl:template match="sch:rule[contains(@context, 'noticeSubType = ''36''')]" priority="100"/>
    <xsl:template match="sch:rule[contains(@context, 'noticeSubType = ''37''')]" priority="100"/>
    <xsl:template match="sch:rule[contains(@context, 'noticeSubType = ''38''')]" priority="100"/>
    <xsl:template match="sch:rule[contains(@context, 'noticeSubType = ''39''')]" priority="100"/>
    <xsl:template match="sch:rule[contains(@context, 'noticeSubType = ''40''')]" priority="100"/>
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