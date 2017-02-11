<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:svg="http://www.w3.org/2000/svg"
    xmlns:pcm="http://www.masereeuw.nl/xslt/2.0/functions"
    version="2.0">
    
    <!-- Copyright (c) Pieter Masereeuw 2013 - http://www.masereeuw.nl -->

    <!-- This is the template file that contains templates that are specific for the SVG view of the Mastermind program in XSLT. -->
    
    <xsl:variable name="svgRowHeight" select="125" as="xs:integer"/>
    <xsl:variable name="svgColWidth" select="125" as="xs:integer"/>
    <xsl:variable name="widthForScore" select="3 * $svgColWidth" as="xs:integer"/>
    
    <xsl:variable name="svgBoardWidth" select="($svgColWidth * $maxColumns) + $widthForScore" as="xs:integer"/>
    <xsl:variable name="svgCircleRadius" select="50" as="xs:integer"/>
    <xsl:variable name="svgImageClassPrefix" select="'color-'" as="xs:string"/>
    
    <xsl:variable name="svgPinWidth" select="xs:integer($svgColWidth div 2)" as="xs:integer"/>
    <xsl:variable name="svgPinRadius" select="xs:integer($svgCircleRadius div 2)" as="xs:integer"/>
    <xsl:variable name="svgPinClassPrefix" select="'pincolor-'" as="xs:string"/>
    
    <xsl:variable name="svgPointsToEmFactor" select=".03" as="xs:float"/>
    
    <xsl:variable name="boardcolor" select="'#552200'" as="xs:string"/>
    
    <!-- This template inspects the SVG view of the board and creates the <moves> XML data structure. -->
    <xsl:template name="collectSVGMoves">
        <xsl:param name="mastermindDiv" as="element()" required="yes"/>
        <moves>
            <xsl:for-each select="$mastermindDiv/svg:svg//svg:g[@class='move']">
                <xsl:variable name="identicalColumnCount"
                    select="if (@id eq 'proposal')
                    then pcm:intFromWidget($mastermindDiv//*:select[@name eq 'identicalColumnCount'])
                    else count(svg:circle[@class eq concat($svgPinClassPrefix, 1)])" as="xs:integer"/>
                <xsl:variable name="identicalColorCount"
                    select="if (@id eq 'proposal')
                    then pcm:intFromWidget($mastermindDiv//*:select[@name eq 'identicalColorCount'])
                    else count(svg:circle[@class eq concat($svgPinClassPrefix, 2)])" as="xs:integer"/>
                <move
                    identicalColumnCount="{$identicalColumnCount}"
                    identicalColorCount="{$identicalColorCount}">
                    <xsl:if test="@id">
                        <xsl:attribute name="id" select="@id"/>
                    </xsl:if>
                    <xsl:for-each select="svg:circle[starts-with(@class, $svgImageClassPrefix)]">
                        <color><xsl:value-of select="substring-after(@class, $svgImageClassPrefix)"/></color>
                    </xsl:for-each>
                </move>
            </xsl:for-each>
        </moves>
    </xsl:template>
    
    <!-- This is one of the templates that renders the <moves> XML data structure into SVG. -->
    <xsl:template match="moves" mode="svg">
        <xsl:variable name="svgBoardHeight" select="($svgRowHeight * count(move)) + $svgRowHeight" as="xs:integer"/>
        <svg:svg
            version="1.1"
            width="{xs:integer($svgBoardWidth * $svgPointsToEmFactor)}em" 
            height="{xs:integer($svgBoardHeight * $svgPointsToEmFactor)}em"
            viewBox="0 0 {$svgBoardWidth} {$svgBoardHeight}">
            <svg:style type="text/css">
                <![CDATA[
                circle.color-1 {
                    fill:red;
                }
                circle.color-2 {
                    fill:yellow;
                }
                circle.color-3 {
                    fill:green;
                }
                circle.color-4 {
                    fill:blue;
                }
                circle.color-5 {
                    fill:black;
                }
                circle.color-6 {
                    fill:white;
                }
                
                circle.pincolor-1 {
                    /* Columns correct */
                    fill: black;
                }
                circle.pincolor-2 {
                    /* Other colours correct */
                    fill: white;
                }
                ]]>
            </svg:style>
            <svg:g>
                <svg:rect width="{$svgBoardWidth}" height="{$svgBoardHeight}" x="0" y="0" fill="{$boardcolor}"/>
                
                <xsl:apply-templates mode="svg"/>
            </svg:g>
        </svg:svg>
        
        <xsl:variable name="lastmove" select="move[last()]" as="element(move)"/>
        <xsl:if test="$lastmove/@id eq 'proposal'">
            <xsl:variable name="identicalColumnCount"
                select="if (normalize-space($lastmove/@identicalColumnCount) eq '') then 0 else xs:integer($lastmove/@identicalColumnCount)"
                as="xs:integer"/>
            <xsl:variable name="identicalColorCount"
                select="if (normalize-space($lastmove/@identicalColorCount) eq '') then 0 else xs:integer($lastmove/@identicalColorCount)"
                as="xs:integer"
            />
            <table>
                <thead>
                    <tr>
                        <th># matching<br/>colums</th>
                        <th># matching<br/>colours</th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                        <td>
                            <xsl:call-template name="scoreInput">
                                <xsl:with-param name="inputName" select="'identicalColumnCount'"/>
                                <xsl:with-param name="inputValue"><xsl:value-of select="$identicalColumnCount"/></xsl:with-param>
                            </xsl:call-template>
                        </td>
                        <td>
                            <xsl:call-template name="scoreInput">
                                <xsl:with-param name="inputName" select="'identicalColorCount'"/>
                                <xsl:with-param name="inputValue"><xsl:value-of select="$identicalColorCount"/></xsl:with-param>
                            </xsl:call-template>
                        </td>
                    </tr>
                </tbody>
            </table>
            <p><input type="submit" id="next-move-button" value="Next move" style="height: 2em;"/></p>
        </xsl:if>
    </xsl:template>
    
    <!-- This is one of the templates that renders the <moves> XML data structure into SVG. -->
    <xsl:template match="move" mode="svg">
        <xsl:variable name="y" select="(1 + count(preceding-sibling::move)) * $svgRowHeight" as="xs:integer"/>
        
        <xsl:variable name="yForRect" select="xs:integer($y - (0.5 * $svgRowHeight))" as="xs:integer"/>
        <xsl:variable name="xForScorebox" select="($svgColWidth * ($maxColumns + 1))" as="xs:integer"/>
        
        <svg:g class="move">
            <xsl:if test="@id">
                <xsl:attribute name="id" select="@id"/>
            </xsl:if>
            <svg:rect width="{$svgBoardWidth}" height="{$svgRowHeight}" x="0" y="{$yForRect}" stroke="black" stroke-width="1" fill="none"/>
            <svg:line x1="{$xForScorebox}" x2="{$xForScorebox}" y1="{$yForRect}" y2="{$yForRect + $svgRowHeight}"
                stroke="black" stroke-width="1" />
            
            <xsl:apply-templates mode="svg"><xsl:with-param name="y" select="$y"/></xsl:apply-templates>
            
            <xsl:if test="not(@id eq 'proposal')">
                <xsl:call-template name="paintScoreBox">
                    <xsl:with-param name="baseX" select="$xForScorebox"/>
                    <xsl:with-param name="baseY" select="$yForRect"/>
                </xsl:call-template>
            </xsl:if>
        </svg:g>
    </xsl:template>
    
    <!-- This is one of the templates that renders the <moves> XML data structure into SVG. Note that the color image is defined
         by concatening a CSS class name prefix and the color number.
    -->
    <xsl:template match="color" mode="svg">
        <xsl:param name="y" required="yes" as="xs:integer"/>
        
        <xsl:variable name="x" select="(1 + count(preceding-sibling::color)) * $svgColWidth"/>
        
        <svg:circle cx="{$x}" cy="{$y}" r="{$svgCircleRadius}" class="{concat($svgImageClassPrefix, .)}"/>
    </xsl:template>
    
    <!-- This template draws the SVG score box as little black and white circles (pins, in the physical game). The colors black and white
         are actually defined in the CSS section, see above.
    -->
    <xsl:template name="paintScoreBox">
        <xsl:param name="baseX" as="xs:integer" required="yes"/>
        <xsl:param name="baseY" as="xs:integer" required="yes"/>
        
        <xsl:variable name="columnOk" select="1" as="xs:integer"/>
        <xsl:variable name="colorOk" select="2" as="xs:integer"/>
        
        <xsl:variable name="identicalColumnCount" select="if (@identicalColumnCount ne '') then @identicalColumnCount else 0" as="xs:integer"/>
        <xsl:variable name="identicalColorCount" select="if (@identicalColorCount ne '') then @identicalColorCount else 0" as="xs:integer"/>
        <xsl:variable name="scorePins" select="(for $i in 1 to $identicalColumnCount return $columnOk, for $i in 1 to $identicalColorCount return $colorOk)"
            as="xs:integer*"/>
        
        <xsl:call-template name="placeScorePin">
            <xsl:with-param name="scorePins" select="$scorePins"/>
            <xsl:with-param name="whichPin" select="1"/>
            <xsl:with-param name="baseX" select="$baseX"/>
            <xsl:with-param name="baseY" select="$baseY"/>
        </xsl:call-template>
    </xsl:template>
    
    <!-- This template draws one of the circles/pins in the SVG score box. Its definition is recursive; this is the easiest way to make sure that
         the pins are neatly distributed horizontally and vertically.
    -->
    <xsl:template name="placeScorePin">
        <xsl:param name="scorePins" as="xs:integer*" required="yes"/>
        <xsl:param name="whichPin" as="xs:integer" required="yes"/>
        <xsl:param name="baseX" as="xs:integer" required="yes"/>
        <xsl:param name="baseY" as="xs:integer" required="yes"/>
        
        <xsl:if test="$scorePins[$whichPin]">
            <xsl:variable name="y"
                select="if ($whichPin le $maxColumns div 2) then $baseY + xs:integer($svgRowHeight div 4) else $baseY + xs:integer(($svgRowHeight div 4) * 3)"
                as="xs:integer"/>
            <xsl:variable name="x"
                select="if ($whichPin le $maxColumns div 2) then $baseX + ($whichPin * $svgPinWidth) else $baseX + (xs:integer($whichPin div 2) * $svgPinWidth)"
                as="xs:integer"/>
            
            <svg:circle  cx="{$x}" cy="{$y}" r="{$svgPinRadius}" class="{concat($svgPinClassPrefix, $scorePins[$whichPin])}"/>
            
            <xsl:call-template name="placeScorePin">                
                <xsl:with-param name="scorePins" select="$scorePins"/>
                <xsl:with-param name="whichPin" select="$whichPin + 1"/>
                <xsl:with-param name="baseX" select="$baseX"/>
                <xsl:with-param name="baseY" select="$baseY"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>
    
</xsl:stylesheet>