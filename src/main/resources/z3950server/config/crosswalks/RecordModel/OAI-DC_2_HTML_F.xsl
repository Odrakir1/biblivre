<?xml version="1.0"?>

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="text"/>

<xsl:template match="/">
  <sutrs>
    <xsl:apply-templates select="dc"/>
  </sutrs>
</xsl:template>

<xsl:template match="dc">
<html>
  <head>
  </head>
  <body>
    A Full format Sutrs record with title <xsl:apply-templates select="title"/>
  </body>
</html>
</xsl:template>

</xsl:stylesheet>
