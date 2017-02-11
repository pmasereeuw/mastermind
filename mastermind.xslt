<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:pcm="http://www.masereeuw.nl/xslt/2.0/functions"
    exclude-result-prefixes="xs"
    version="2.0">
    
    <!-- Copyright (c) Pieter Masereeuw 2016 - http://www.masereeuw.nl --> 
    
    <!-- This template file contains the logic for solving a Mastermind challenge.
         It operates on a <moves> XML data structure (an example of which is given in a comment in the
         mastermind-webinterface XSLT file).
         This structure is translated into sequences of numbers (the numbers represent colors); all calculations
         are based on these sequences.
    -->
    
    <!-- Returns the value of parameter $color, plus 1. If the result value would be greater than $maxColors,
         1 is returned. If (even after that) the result value equals $stopAtColor, 0 is returned.
         In order to disable the $stopAtColor check, pass $stopAtColor an impossible value, e.g., 0.
    -->
    <xsl:function name="pcm:getNextColor" as="xs:integer">
        <xsl:param name="color" as="xs:integer"/>
        <xsl:param name="stopAtColor" as="xs:integer"/>
        
        <xsl:variable name="next1" select="$color + 1" as="xs:integer"/>
        <xsl:variable name="next2" select="if ($next1 gt $maxColors) then 1 else $next1" as="xs:integer"/>
        <xsl:sequence select="if ($next2 eq $stopAtColor) then 0 else $next2"/>
    </xsl:function>
    
    <!-- Inserts a zero in a sequence at the indicated column and returns the resulting sequence. -->
    <xsl:function name="pcm:zeroColumn" as="xs:integer+">
        <xsl:param name="sequence" as="xs:integer+"/>
        <xsl:param name="column" as="xs:integer"/>
        
        <xsl:sequence select="subsequence($sequence, 1, $column - 1), 0, subsequence($sequence, $column + 1)"></xsl:sequence>
    </xsl:function>
    
    <!-- Returns a copy of seq1 where all offsets whose value is equal in seq1 and seq2 are set to 0 -->
    <xsl:function name="pcm:zeroOutColumsWithSameColors" as="xs:integer+">
        <xsl:param name="seq1" as="xs:integer+"/>
        <xsl:param name="seq2" as="xs:integer+"/>
        
        <xsl:sequence select="for $i in 1 to count($seq1) return if ($seq1[$i] eq $seq2[$i]) then 0 else $seq1[$i]"></xsl:sequence>
    </xsl:function>
    
    <!-- This is the central template for calculating a new row on the board. If may return an imcomplete or empty sequence in case finding a solution is
         not possible, which may be the result of user errors (or implementation errors ;-) ).
    -->
    <xsl:function name="pcm:calculateColorsForMove" as="xs:integer*">
        <xsl:param name="color" as="xs:integer"/>
        <xsl:param name="stopAtColor" as="xs:integer"/>
        <xsl:param name="givenSequence" as="xs:integer*"/>
        <xsl:param name="earlierMoves" as="element(moves)"/>
        
        <!--<xsl:message><xsl:value-of select="concat('pcm:calculateColorsForMove(', $color, ', ', $stopAtColor, ', ', pcm:showIntSeq($givenSequence), ', .. )')"/></xsl:message>-->

        <xsl:choose>
            <xsl:when test="$color eq 0">
                <!-- All colours have been tried (0 value returned by pcm:getNextColor()), return error: empty sequence -->
                <!--<xsl:message>$color eq 0</xsl:message>-->
                <xsl:sequence select="()"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="newSequence" as="xs:integer+"><xsl:sequence select="$givenSequence, $color"/> </xsl:variable>
                
                <!--<xsl:message>$newSequence = <xsl:value-of select="pcm:showIntSeq($newSequence)"/></xsl:message>-->
                
                <xsl:choose>
                    <xsl:when test="count($newSequence) eq $maxColumns">
                        <xsl:choose>
                            <xsl:when test="pcm:checkEarlierMoves($newSequence, $earlierMoves)">
                                <!-- Found a new row, return it: -->
                                <!--<xsl:message>Found new row, $newSequence = <xsl:value-of select="pcm:showIntSeq($newSequence)"/></xsl:message>-->
                                <xsl:sequence select="$newSequence"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <!-- New row does not fit in with existing rows, try to calculate a new one: -->
                                <!--<xsl:message>Row does not fit, trying to create a better one</xsl:message>-->
                                <xsl:sequence select="pcm:calculateColorsForMove(pcm:getNextColor($color, $stopAtColor), $stopAtColor, $givenSequence, $earlierMoves)"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:otherwise>
                        <!-- Row not yet complete, so fill the next columns: -->
                        <xsl:variable name="nextColor" select="pcm:getNextColor($color, 0)" as="xs:integer"/>
                        <xsl:variable name="fullRow" as="xs:integer*">
                            <xsl:sequence select="pcm:calculateColorsForMove($nextColor, $nextColor, $newSequence, $earlierMoves)"/>
                        </xsl:variable>
                        <xsl:choose>
                            <xsl:when test="count($fullRow) gt 0">
                                <!-- Found a new row, return it -->
                                <!--<xsl:message>Found new row, $fullRow = <xsl:value-of select="pcm:showIntSeq($fullRow)"/></xsl:message>-->
                                <xsl:sequence select="$fullRow"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <!-- Failed to find a new row, try next color: -->
                                <!--<xsl:message>Trying next color</xsl:message>-->
                                <xsl:sequence select="pcm:calculateColorsForMove(pcm:getNextColor($color, $stopAtColor), $stopAtColor, $givenSequence, $earlierMoves)"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <!-- This function checks the validity of a new move attempt by comparing the attempt with earlier moves on the board,
         as defined in the <moves> XML data structure.
         It does so by calling the recursive function pcm:checkEarlierMove for each earlier move.
    -->
    <xsl:function name="pcm:checkEarlierMoves" as="xs:boolean">
        <xsl:param name="newSeq" as="xs:integer+"/>
        <xsl:param name="earlierMoves" as="element(moves)"/>
        
        <xsl:sequence select="pcm:checkEarlierMove($newSeq, $earlierMoves/move[1])"/>
    </xsl:function>
    
    <!-- This function checks the validity of a new move attempt by comparing the attempt with a given earlier move on the board.
         If the check indicates a valid move, other moves on the board (siblings in the <moves> XML data structure) are dealt with
         recursively.
    -->
    <xsl:function name="pcm:checkEarlierMove" as="xs:boolean">
        <xsl:param name="newSeq" as="xs:integer+"/>
        <xsl:param name="earlierMove" as="element(move)?"/>
        
        <xsl:choose>
            <xsl:when test="$earlierMove">
                <xsl:variable name="ok" select="pcm:checkColors($newSeq, $earlierMove)" as="xs:boolean"/>
                <xsl:choose>
                    <xsl:when test="$ok">
                        <xsl:sequence select="pcm:checkEarlierMove($newSeq, $earlierMove/following-sibling::move[1])"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:sequence select="false()"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="true()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <!-- This function determines if the colors of the newly proposed move are compatible with those of a earlier move (as defined in
         a <move> element of the <moves> XML data structure).
    -->
    <xsl:function name="pcm:checkColors" as="xs:boolean">
        <xsl:param name="newSeq" as="xs:integer+"/>
        <xsl:param name="earlierMove" as="element(move)?"/>
        
        <xsl:variable name="oldSeq" select="for $color in $earlierMove//color return xs:integer($color)" as="xs:integer+"/>
        
        <!--<xsl:message><xsl:value-of select="concat('pcm:checkColors, newSeq=', pcm:showIntSeq($newSeq), ' [pg,kg=',
            pcm:countColorsAtSameColumns($newSeq, $oldSeq), ', ',  pcm:countColorsAtOtherColumns($newSeq, $oldSeq), '], oldSeq=',
            pcm:showIntSeq($oldSeq), ' [pg,kg=', xs:integer($earlierMove/@identicalColumnCount), ', ', xs:integer($earlierMove/@identicalColorCount), ']')"/></xsl:message>-->
        
        <xsl:choose>
            <xsl:when test="pcm:countColorsAtSameColumns($newSeq, $oldSeq) eq xs:integer($earlierMove/@identicalColumnCount)">
                <xsl:choose>
                    <xsl:when test="pcm:countColorsAtOtherColumns($newSeq, $oldSeq) eq xs:integer($earlierMove/@identicalColorCount)">
                        <xsl:sequence select="not(deep-equal($oldSeq, $newSeq))"/> <!-- Prevent finding the same move a second time. Can this happen? Perhaps when $oldSeq contains the solution? -->
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:sequence select="false()"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="false()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="pcm:countColorsAtSameColumns" as="xs:integer">
        <!-- Counts how many offsets (columns) in $newSeq have the same value as the corresponding offset in $oldSeq. -->
        <xsl:param name="newSeq" as="xs:integer+"/>
        <xsl:param name="oldSeq" as="xs:integer+"/>
        
        <xsl:sequence select="sum(for $i in 1 to count($newSeq) return if ($newSeq[$i] eq $oldSeq[$i]) then 1 else 0)"/>
    </xsl:function>
    
    <xsl:function name="pcm:countColorsAtOtherColumns" as="xs:integer">
        <!-- Counts how many colours (values at offsets in $newSeq) reoccur in $oldSeq provided that the offsets are not identical. -->
        <xsl:param name="newSeq" as="xs:integer+"/>
        <xsl:param name="oldSeq" as="xs:integer+"/>
        
        <xsl:sequence select="pcm:auxCountColorsAtOtherColumns(pcm:zeroOutColumsWithSameColors($newSeq, $oldSeq), pcm:zeroOutColumsWithSameColors($oldSeq, $newSeq), 1)"/>
    </xsl:function>
    
    <xsl:function name="pcm:auxCountColorsAtOtherColumns" as="xs:integer">
        <xsl:param name="newSeq" as="xs:integer+"/>
        <xsl:param name="oldSeq" as="xs:integer+"/>
        <xsl:param name="colNum" as="xs:integer+"/>

        <xsl:choose>
            <xsl:when test="$colNum gt $maxColumns">0</xsl:when>
            <xsl:otherwise>
                <xsl:variable name="color" select="$newSeq[$colNum]" as="xs:integer"/>
                <!-- Note: the values at both offset have been set to zero (by the caller) if they had equal values. -->
                <xsl:variable name="matchingColumns" as="xs:integer*"
                    select="for $i in 1 to count($newSeq) return if (($color ne 0) and ($oldSeq[$i] eq $color)) then $i else ()"/>
                
                <!--<xsl:message>pcm:auxCountColorsAtOtherColumns: colNum=<xsl:value-of select="$colNum"/>, color=<xsl:value-of select="$color"/>,
                    matchingColumns=<xsl:value-of select="pcm:showIntSeq($matchingColumns)"/>, newSeq=<xsl:value-of select="pcm:showIntSeq($newSeq)"/>, oldSeq=<xsl:value-of select="pcm:showIntSeq($oldSeq)"/></xsl:message>-->
                
                <xsl:choose>
                    <xsl:when test="count($matchingColumns) gt 0">
                        <!-- Check the next columns, but remove the first matching column from the newSeq parameter in order to prevent counting it again. -->
                        <xsl:sequence
                            select="1 + pcm:auxCountColorsAtOtherColumns($newSeq, pcm:zeroColumn($oldSeq, $matchingColumns[1]), $colNum+1)"
                        />
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:sequence
                            select="pcm:auxCountColorsAtOtherColumns($newSeq, $oldSeq, $colNum+1)"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <!-- Test templates: -->
    <xsl:template match="REPLACE-ME-WITH-A-ROOT-TEMPLATE-FOR-TESTING-PURPOSES">
        <!--
            <xsl:variable name="answer" select="pcm:countColorsAtOtherColumns((1, 3, 2, 4), (1, 2, 4, 3))" as="xs:integer*"/>
            <xsl:message>The answer is: <xsl:value-of select="pcm:showIntSeq($answer)"/></xsl:message>
        -->

        <xsl:variable name="moves" as="element(moves)">
            <!-- Guess (6, 5, 4, 3), start with <moves/> (i.e., empty) -->
            <moves>
                <move identicalColumnCount="0" identicalColorCount="2">
                    <color>1</color>
                    <color>2</color>
                    <color>3</color>
                    <color>4</color>
                </move>
                <move identicalColumnCount="0" identicalColorCount="3">
                    <color>2</color>
                    <color>3</color>
                    <color>5</color>
                    <color>6</color>
                </move>
                <move identicalColumnCount="0" identicalColorCount="4">
                    <color>3</color>
                    <color>4</color>
                    <color>6</color>
                    <color>5</color>
                </move>
                <move identicalColumnCount="2" identicalColorCount="2">
                    <color>5</color>
                    <color>6</color>
                    <color>4</color>
                    <color>3</color>
                </move>
                <!--<move identicalColumnCount="4" identicalColorCount="0">
                    <color>6</color>
                    <color>5</color>
                    <color>4</color>
                    <color>3</color>
                </move>-->
            </moves>
        </xsl:variable>


        <!--<xsl:variable name="result" select="pcm:calculateColorsForMove(1, 1, (), $moves)" as="xs:integer*"/>
         <xsl:message>
            <xsl:value-of select="pcm:showIntSeq($result)"/>
        </xsl:message>-->
    </xsl:template>
    
    <xsl:function name="pcm:showIntSeq" as="xs:string">
        <!-- For testing/debugging only -->
        <xsl:param name="intseq" as="xs:integer*"/>
        <xsl:value-of select="concat('(', string-join(for $i in $intseq return string($i), ', '), ')')"/>
    </xsl:function>
    
</xsl:stylesheet>
