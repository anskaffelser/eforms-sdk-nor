<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:sch="http://purl.oclc.org/dsdl/schematron"
    version="2.0">

    <xsl:param name="target" select="'pin'"/>

    <xsl:template match="@* | node()">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="sch:rule[$target != 'pin'][contains(@context, 'noticeSubType = ''1''')]" priority="100"/>
    <xsl:template match="sch:rule[$target != 'pin'][contains(@context, 'noticeSubType = ''2''')]" priority="100"/>
    <xsl:template match="sch:rule[$target != 'pin'][contains(@context, 'noticeSubType = ''3''')]" priority="100"/>
    <xsl:template match="sch:rule[$target != 'pin'][contains(@context, 'noticeSubType = ''4''')]" priority="100"/>
    <xsl:template match="sch:rule[$target != 'pin'][contains(@context, 'noticeSubType = ''5''')]" priority="100"/>
    <xsl:template match="sch:rule[$target != 'pin'][contains(@context, 'noticeSubType = ''6''')]" priority="100"/>
    <xsl:template match="sch:rule[$target != 'pin'][contains(@context, 'noticeSubType = ''7''')]" priority="100"/>
    <xsl:template match="sch:rule[$target != 'pin'][contains(@context, 'noticeSubType = ''8''')]" priority="100"/>
    <xsl:template match="sch:rule[$target != 'pin'][contains(@context, 'noticeSubType = ''9''')]" priority="100"/>
    <xsl:template match="sch:rule[$target != 'pin'][contains(@context, 'noticeSubType = ''10''')]" priority="100"/>
    <xsl:template match="sch:rule[$target != 'pin'][contains(@context, 'noticeSubType = ''11''')]" priority="100"/>
    <xsl:template match="sch:rule[$target != 'pin'][contains(@context, 'noticeSubType = ''12''')]" priority="100"/>
    <xsl:template match="sch:rule[$target != 'pin'][contains(@context, 'noticeSubType = ''13''')]" priority="100"/>
    <xsl:template match="sch:rule[$target != 'pin'][contains(@context, 'noticeSubType = ''14''')]" priority="100"/>
    <xsl:template match="sch:rule[$target != 'cn'][contains(@context, 'noticeSubType = ''15''')]" priority="100"/>
    <xsl:template match="sch:rule[$target != 'cn'][contains(@context, 'noticeSubType = ''16''')]" priority="100"/>
    <xsl:template match="sch:rule[$target != 'cn'][contains(@context, 'noticeSubType = ''17''')]" priority="100"/>
    <xsl:template match="sch:rule[$target != 'cn'][contains(@context, 'noticeSubType = ''18''')]" priority="100"/>
    <xsl:template match="sch:rule[$target != 'cn'][contains(@context, 'noticeSubType = ''19''')]" priority="100"/>
    <xsl:template match="sch:rule[$target != 'cn'][contains(@context, 'noticeSubType = ''20''')]" priority="100"/>
    <xsl:template match="sch:rule[$target != 'cn'][contains(@context, 'noticeSubType = ''21''')]" priority="100"/>
    <xsl:template match="sch:rule[$target != 'cn'][contains(@context, 'noticeSubType = ''22''')]" priority="100"/>
    <xsl:template match="sch:rule[$target != 'cn'][contains(@context, 'noticeSubType = ''23''')]" priority="100"/>
    <xsl:template match="sch:rule[$target != 'cn'][contains(@context, 'noticeSubType = ''24''')]" priority="100"/>
    <xsl:template match="sch:rule[$target != 'can'][contains(@context, 'noticeSubType = ''25''')]" priority="100"/>
    <xsl:template match="sch:rule[$target != 'can'][contains(@context, 'noticeSubType = ''26''')]" priority="100"/>
    <xsl:template match="sch:rule[$target != 'can'][contains(@context, 'noticeSubType = ''27''')]" priority="100"/>
    <xsl:template match="sch:rule[$target != 'can'][contains(@context, 'noticeSubType = ''28''')]" priority="100"/>
    <xsl:template match="sch:rule[$target != 'can'][contains(@context, 'noticeSubType = ''29''')]" priority="100"/>
    <xsl:template match="sch:rule[$target != 'can'][contains(@context, 'noticeSubType = ''30''')]" priority="100"/>
    <xsl:template match="sch:rule[$target != 'can'][contains(@context, 'noticeSubType = ''31''')]" priority="100"/>
    <xsl:template match="sch:rule[$target != 'can'][contains(@context, 'noticeSubType = ''32''')]" priority="100"/>
    <xsl:template match="sch:rule[$target != 'can'][contains(@context, 'noticeSubType = ''33''')]" priority="100"/>
    <xsl:template match="sch:rule[$target != 'can'][contains(@context, 'noticeSubType = ''34''')]" priority="100"/>
    <xsl:template match="sch:rule[$target != 'can'][contains(@context, 'noticeSubType = ''35''')]" priority="100"/>
    <xsl:template match="sch:rule[$target != 'can'][contains(@context, 'noticeSubType = ''36''')]" priority="100"/>
    <xsl:template match="sch:rule[$target != 'can'][contains(@context, 'noticeSubType = ''37''')]" priority="100"/>
    <xsl:template match="sch:rule[$target != 'can'][contains(@context, 'noticeSubType = ''38''')]" priority="100"/>
    <xsl:template match="sch:rule[$target != 'can'][contains(@context, 'noticeSubType = ''39''')]" priority="100"/>
    <xsl:template match="sch:rule[$target != 'can'][contains(@context, 'noticeSubType = ''40''')]" priority="100"/>

</xsl:stylesheet>