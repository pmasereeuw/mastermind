<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:svg="http://www.w3.org/2000/svg"
    xmlns:pcm="http://www.masereeuw.nl/xslt/2.0/functions"
    version="2.0">
    
    <!-- Copyright (c) Pieter Masereeuw 2016 - http://www.masereeuw.nl -->
    
    <!-- This is the template file that contains templates that are specific for the HTML view of the Mastermind program in XSLT. -->
    
    <xsl:variable name="color-image-alt-prefix" select="'color #'" as="xs:string"/>
    
    <!-- This template inspects the HTML view of the board and creates the <moves> XML data structure. -->
    <xsl:template name="collectHTMLMoves">
        <xsl:param name="mastermindDiv" as="element(div)" required="yes"/>
        <moves>
            <xsl:for-each select="$mastermindDiv/*:table[@id eq 'moves']/*:tbody/*:tr">
                <move
                    identicalColumnCount="{pcm:intFromWidget(*:td/*:input[@name eq 'identicalColumnCount'] | *:td/*:select[@name eq 'identicalColumnCount'])}"
                    identicalColorCount="{pcm:intFromWidget(*:td/*:input[@name eq 'identicalColorCount'] | *:td/*:select[@name eq 'identicalColorCount'])}">
                    <xsl:if test="@id">
                        <xsl:attribute name="id" select="@id"/>
                    </xsl:if>
                    <xsl:for-each select="*:td/*:img/@alt">
                        <color><xsl:value-of select="substring-after(., $color-image-alt-prefix)"/></color>
                    </xsl:for-each>
                </move>
            </xsl:for-each>
        </moves>
    </xsl:template>
    
    <!-- This is one of the templates that renders the <moves> XML data structure into HTML. -->
    <xsl:template match="moves" mode="html">
        <table id="moves">
            <thead>
                <tr>
                    <th colspan="4">Move</th>
                    <th># matching colums</th>
                    <th># matching colours</th>
                </tr>
            </thead>
            <tbody>
                <xsl:apply-templates mode="html"/>
            </tbody>
        </table>
        <xsl:variable name="lastmove" select="move[last()]" as="element(move)"/>
        
        <xsl:if test="$lastmove/@id eq 'proposal'">
            <p><input type="submit" id="next-move-button" value="Next move" style="height: 2em;"/></p>
        </xsl:if>
    </xsl:template>
    
    <!-- This is one of the templates that renders the <moves> XML data structure into HTML. -->
    <xsl:template match="move" mode="html">
        <tr>
            <xsl:if test="@id">
                <xsl:attribute name="id" select="@id"/>
            </xsl:if>
            <xsl:choose>
                <xsl:when test="@class eq 'giving-up'">
                    <td colspan="6" class="giving-up">Giving up (please check the scores you supplied)</td>
                </xsl:when>
                <xsl:when test="@id eq 'proposal'">
                    <xsl:apply-templates mode="html"/>
                    <td>
                        <xsl:call-template name="scoreInput">
                            <xsl:with-param name="inputName" select="'identicalColumnCount'"/>
                            <xsl:with-param name="inputValue"><xsl:value-of select="if (normalize-space(@identicalColumnCount) = '') then 0 else xs:integer(@identicalColumnCount)"/></xsl:with-param>
                        </xsl:call-template>
                    </td>
                    <td>
                        <xsl:call-template name="scoreInput">
                            <xsl:with-param name="inputName" select="'identicalColorCount'"/>
                            <xsl:with-param name="inputValue"><xsl:value-of select="if (normalize-space(@identicalColorCount) = '') then 0 else xs:integer(@identicalColorCount)"/></xsl:with-param>
                        </xsl:call-template>
                    </td>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates mode="html"/>
                    <td>
                        <xsl:value-of select="@identicalColumnCount"/>
                        <input type="hidden" name="identicalColumnCount"
                            value="{@identicalColumnCount}"/>
                    </td>
                    <td>
                        <xsl:value-of select="@identicalColorCount"/>
                        <input type="hidden" name="identicalColorCount"
                            value="{@identicalColorCount}"/>
                    </td>
                </xsl:otherwise>
            </xsl:choose>
        </tr>
    </xsl:template>
    
    <!-- This is one of the templates that renders the <moves> XML data structure into HTML. Note that the color image is defined
         by concatening a name prefix and the color number.
    -->
    <xsl:template match="color" mode="html">
        <td><img src="color{.}.png" alt="{concat($color-image-alt-prefix, .)}"/></td>    
    </xsl:template>
</xsl:stylesheet>