<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:svg="http://www.w3.org/2000/svg"
    xmlns:pcm="http://www.masereeuw.nl/xslt/2.0/functions"
    xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
    extension-element-prefixes="ixsl"
    version="2.0">
    
    <!-- Copyright (c) Pieter Masereeuw 2013 - http://www.masereeuw.nl -->

    <!-- This is the main template file for the Mastermind program in XSLT. It loads the parameters (mastermind-params.xslt), the main
         Mastermind logic (mastermind.xslt) and the HTML and SVG views (mastermind-webinterface-html.xslt and mastermind-webinterface-svg.xslt).
         
         The general driving templates and general view templates are defined in this file.
    -->
    <xsl:import href="mastermind-params.xslt"/>
    <xsl:import href="mastermind.xslt"/>
    
    <xsl:include href="mastermind-webinterface-html.xslt"/>
    <xsl:include href="mastermind-webinterface-svg.xslt"/>

    <xsl:output method="html"/>
    
    <!-- First, we define some wrapper functions, mainly in order to reduce warnings from my XSLT editor about undeclared ixsl functions. -->

    <xsl:function name="pcm:page" as="document-node()">
        <xsl:sequence select="ixsl:page()"/>
    </xsl:function>
    
    <xsl:function name="pcm:get" as="item()?">
        <xsl:param name="object" as="item()"/>
        <xsl:param name="property" as="xs:string"/>
        <xsl:sequence select="ixsl:get($object, $property)"/>
    </xsl:function>
    
    <!-- End of wrapper functions -->

    <xsl:function name="pcm:intFromWidget" as="xs:integer">
        <xsl:param name="element" as="element()"/>
        <xsl:variable name="val" as="xs:string">
            <xsl:choose>
                <xsl:when test="$element/self::*:input">
                    <xsl:value-of select="pcm:get($element, 'value')"/> 
                </xsl:when>
                <xsl:when test="$element/self::*:select">
                    <xsl:value-of select="pcm:get($element, 'value')"/> 
                </xsl:when>
                <xsl:otherwise>-666</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:sequence select="if (normalize-space($val) eq '') then 0 else xs:integer($val)"/>
    </xsl:function>

    <xsl:function name="pcm:boolFromInput" as="xs:boolean">
        <xsl:param name="element" as="element()"/>
        <xsl:param name="property" as="xs:string"/>
        
        <xsl:variable name="val" as="xs:string" select="string(pcm:get($element, $property))"/>
        <xsl:sequence select="if ($val eq '') then false() else xs:boolean($val)"/>
    </xsl:function>
    
    
    <!-- Tests if we are in SVG mode (true) or in HTML mode (false) -->
    <xsl:function name="pcm:isSVG" as="xs:boolean">
        <xsl:sequence select="pcm:boolFromInput(pcm:page()//*:input[@id eq 'renderAsSVG'], 'checked')"/>
    </xsl:function>
    
    <!-- Generates the HTML select box for entering the score of the last row on the board. -->
    <xsl:template name="scoreInput">
        <xsl:param name="inputName" as="xs:string" required="yes"/>
        <xsl:param name="inputValue" as="xs:integer" required="yes"/>
        <select name="{$inputName}" class="score">
            <xsl:for-each select="0 to $maxColumns">
                <option value="{.}">
                    <xsl:if test=". eq $inputValue">
                        <xsl:attribute name="selected">selected</xsl:attribute>
                    </xsl:if>
                    <xsl:value-of select="."/>
                </option>
            </xsl:for-each>
        </select>
    </xsl:template>
    
    <!-- This is the entry point for XSLT processing, as specified in the calling HTML page.
    -->
    <xsl:template name="initial-template">
        <!-- <moves> is an internal XML structure that is build from HTML or SVG tags every time we need to calculate a new row
             on the board. The following set of moves illustrates a session where the computer tries to guess the sequence
             (6, 5, 4, 3). It starts out with an empty <moves/> element.
             
             Not listed here is the @proposal attribute, which is used to mark the row that is currently proposed by the program.
             
             Of course, the numbers stand for various colors - either by means of CSS or my means of the same number being part
             of an image name.
        
        <moves>
            <move identicalColumnCount="0" identicalColorCount="2">
                <color>1</color><color>2</color><color>3</color><color>4</color>
            </move>
            <move identicalColumnCount="0" identicalColorCount="3">
                <color>2</color><color>3</color><color>5</color><color>6</color>
            </move>
            <move identicalColumnCount="0" identicalColorCount="4">
                <color>3</color><color>4</color><color>6</color><color>5</color>
            </move>
            <move identicalColumnCount="2" identicalColorCount="2">
                <color>5</color><color>6</color><color>4</color><color>3</color>
            </move>
            <move identicalColumnCount="4" identicalColorCount="0">
                <color>6</color><color>5</color><color>4</color><color>3</color>
            </move>
        </moves>
        -->
        <xsl:variable name="emptyMoves" as="element(moves)">
            <moves/>
        </xsl:variable>
        <xsl:variable name="first-move" select="pcm:calculateColorsForMove(1, 1, (), $emptyMoves)" as="xs:integer*"/>
        
        <xsl:variable name="moves" as="element(moves)">
            <moves>
                <xsl:call-template name="doNewMoves"><xsl:with-param name="newColors" select="$first-move"/></xsl:call-template>
            </moves>
        </xsl:variable>
        
        <!-- The user can switch between various documents. One of them is the board. Non-active documents are hidden by means of
             CSS.
        -->
        <xsl:result-document href="#about" method="ixsl:replace-content">
            <xsl:copy-of select="doc('about.xml')/*"/>
        </xsl:result-document>
        
        <xsl:result-document href="#howtoplay" method="ixsl:replace-content">
            <xsl:copy-of select="doc('howtoplay.xml')/*"/>
        </xsl:result-document>
        
        <xsl:result-document href="#mastermind" method="ixsl:replace-content">
            <xsl:call-template name="showMoves">
                <xsl:with-param name="moves" select="$moves"/>
            </xsl:call-template>
        </xsl:result-document>
    </xsl:template>
    
    <!-- Create a new (proposal) <move> element in the <moves> data structure. The colors are given in parameter 
        newColors. This parameter is empty in the case of the user event that leads to a switch
        from HTML to SVG or vice versa.
    -->
    <xsl:template name="doNewMoves">
        <xsl:param name="newColors" as="xs:integer*" required="yes"/>
        
        <move id="proposal">
            <xsl:choose>
                <xsl:when test="count($newColors) ne $maxColumns">
                    <xsl:attribute name="class" select="'giving-up'"></xsl:attribute>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:for-each select="$newColors">
                        <color><xsl:value-of select="."/></color>
                    </xsl:for-each>
                </xsl:otherwise>
            </xsl:choose>
        </move>
    </xsl:template>
    
    <!-- Shows the current board, either in HTML or in SVG.
         The board is represented as an XML <moves> data structure, which is passed as the moves parameter.
    -->
    <xsl:template name="showMoves">
        <xsl:param name="moves" as="element(moves)" required="yes"/>
        
        <xsl:choose>
            <xsl:when test="pcm:isSVG()">
                <xsl:apply-templates select="$moves" mode="svg"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="$moves" mode="html"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- This template is triggered when the user clicks the button that toggles between HTML and SVG mode. -->
    <xsl:template match="*:input[@id eq 'renderAsSVG']" mode="ixsl:onchange">
        <xsl:variable name="mastermindDiv" select="//*:div[@id eq 'mastermind']" as="element(div)"/>
        <xsl:variable name="moves" as="element(moves)">
            <xsl:call-template name="collectMoves"><xsl:with-param name="mastermindDiv" select="$mastermindDiv"/></xsl:call-template>
        </xsl:variable>

        <xsl:result-document href="#mastermind" method="ixsl:replace-content">
            <xsl:call-template name="showMoves">
                <xsl:with-param name="moves" select="$moves"/>
            </xsl:call-template>
        </xsl:result-document>
    </xsl:template>
    
    <!-- Inspect the HTML or SVG data structure and build the <moves> XML data structure which is the basis for all mastermind game calculations. -->
    <xsl:template name="collectMoves">
        <xsl:param name="mastermindDiv" as="element()" required="yes"/>

        <xsl:choose>
            <xsl:when test="$mastermindDiv/svg:svg">
                <xsl:call-template name="collectSVGMoves"><xsl:with-param name="mastermindDiv" select="$mastermindDiv"/></xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="collectHTMLMoves"><xsl:with-param name="mastermindDiv" select="$mastermindDiv"/></xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>     
    </xsl:template>
    
    <!-- This template is triggered when the user clicks the hyperlink that shows the current board (either as SVG or as HTML). --> 
    <xsl:template match="*:a[@class eq 'switch-to-play']" mode="ixsl:onclick">
        <xsl:for-each select="//*:div[contains(@class, 'hideable')]">
            <xsl:choose>
                <xsl:when test="@id eq 'play'"><ixsl:set-style name="display" select="'block'"/></xsl:when>
                <xsl:otherwise><ixsl:set-style name="display" select="'none'"/></xsl:otherwise>
            </xsl:choose>            
        </xsl:for-each>
    </xsl:template>
    
    <!-- This template is triggered when the user clicks the hyperlink that shows the information about this little program. -->
    <xsl:template match="*:a[@class eq 'switch-to-about']" mode="ixsl:onclick">
        <xsl:for-each select="//*:div[contains(@class, 'hideable')]">
            <xsl:choose>
                <xsl:when test="@id eq 'about'"><ixsl:set-style name="display" select="'block'"/></xsl:when>
                <xsl:otherwise><ixsl:set-style name="display" select="'none'"/></xsl:otherwise>
            </xsl:choose>            
        </xsl:for-each>
    </xsl:template>
    
    <!-- This template is triggered when the user clicks the hyperlink that shows the information about the rules for playing Mastermind. -->
    <xsl:template match="*:a[@class eq 'switch-to-howtoplay']" mode="ixsl:onclick">
        <xsl:for-each select="//*:div[contains(@class, 'hideable')]">
            <xsl:choose>
                <xsl:when test="@id eq 'howtoplay'"><ixsl:set-style name="display" select="'block'"/></xsl:when>
                <xsl:otherwise><ixsl:set-style name="display" select="'none'"/></xsl:otherwise>
            </xsl:choose>            
        </xsl:for-each>
    </xsl:template>

    <!-- This template is triggered when the user clicks the button that indicates that the score for the proposed row has been entered
         and the program may calculate a new proposal row.
    -->
    <xsl:template match="*:input[@id eq 'next-move-button']" mode="ixsl:onclick">
        <xsl:variable name="mastermindDiv" select="//div[@id eq 'mastermind']" as="element(div)"/>
        <!-- Create the <moves> XML structure in order to pass it to the mastermind processor: -->
        <xsl:variable name="earlierMoves" as="element(moves)">
            <xsl:call-template name="collectMoves"><xsl:with-param name="mastermindDiv" select="$mastermindDiv"/></xsl:call-template>
        </xsl:variable>
        
        <xsl:choose>
            <xsl:when test="xs:integer($earlierMoves/move[last()]/@identicalColumnCount) lt $maxColumns"> <!-- TODO test for giving up - remove button then too -->
                <xsl:variable name="next-move" select="pcm:calculateColorsForMove(1, 1, (), $earlierMoves)" as="xs:integer*"/>
                
                <!-- Create the <moves> XML structure in order to pass it to the mastermind processor: -->
                <xsl:variable name="moves" as="element(moves)">
                    <xsl:call-template name="injectNewMove">
                        <xsl:with-param name="moves" select="$earlierMoves"/>
                        <xsl:with-param name="newColors" select="$next-move"/>
                    </xsl:call-template>
                </xsl:variable>
                
                <xsl:result-document href="#mastermind" method="ixsl:replace-content">
                    <xsl:call-template name="showMoves">
                        <xsl:with-param name="moves" select="$moves"/>
                    </xsl:call-template>
                </xsl:result-document>
            </xsl:when> 
            <xsl:otherwise>
                <xsl:variable name="button-p" select="$mastermindDiv/p[input/@id eq 'next-move-button']"/>
                <xsl:for-each select="$button-p"><ixsl:set-style name="display" select="'none'"/></xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- This template passes a new row (a sequence of colors/integers) into a <moves> XML data structure. -->
    <xsl:template name="injectNewMove">
        <xsl:param name="moves" as="element(moves)" required="yes"></xsl:param>
        <xsl:param name="newColors" as="xs:integer*" required="yes"/>
        <xsl:for-each select="$moves">
            <xsl:copy>
                <xsl:apply-templates select="@*|node()" mode="copy-moves"/>
                <xsl:call-template name="doNewMoves"><xsl:with-param name="newColors" select="$newColors"/></xsl:call-template>
            </xsl:copy>
        </xsl:for-each>
    </xsl:template>
    
    <!-- Remove the proposal id while copying the <moves> XML data structure. -->
    <xsl:template match="move/@id[. eq 'proposal']" mode="copy-moves"/>    
    
    <xsl:template match="@*|node()" mode="copy-moves">
        <xsl:copy><xsl:apply-templates select="@*|node()" mode="copy-moves"/></xsl:copy>
    </xsl:template>
    
</xsl:stylesheet>
