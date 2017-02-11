<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:pcm="http://www.masereeuw.nl/xslt/2.0/functions"
    exclude-result-prefixes="xs"
    version="2.0">
    
    <!-- Copyright (c) Pieter Masereeuw 2016 - http://www.masereeuw.nl -->
    
    <!-- Parameters for the Mastermind program in XSLT. Changing the parameter values has not been tested.
         Changing the maxColumns value to a larger number may lead to long calculation times (the algorithm
         is exponential).
         Changing the maxColors value cannot be done without creating more color images for the HMTL view and
         more color classes for the SVG view.
    -->
    
    <xsl:param name="maxColumns" select="4" as="xs:integer"/>
    <xsl:param name="maxColors" select="6" as="xs:integer"/>
</xsl:stylesheet>