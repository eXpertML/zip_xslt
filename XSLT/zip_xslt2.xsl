<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:zip="http://expertml.com/lib/zip"
  exclude-result-prefixes="#all"
  version="2.0">
  <!--xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
  
  <xd:doc scope="stylesheet">
    <xd:desc>
      <xd:p><xd:b>Created on:</xd:b> Aug 25, 2017</xd:p>
      <xd:p><xd:b>Author:</xd:b> TFJ Hillman</xd:p>
      <xd:p>This library of functions supports creation of base64 encoded zip files</xd:p>
    </xd:desc>
  </xd:doc>-->
  
  <xsl:function name="zip:string2chars" as="xs:string+">
    <xsl:param name="string" as="xs:string"/>
    <xsl:sequence select="zip:string2chars($string, ())"/>
  </xsl:function>
  
  <xsl:function name="zip:string2chars" as="xs:string+">
    <xsl:param name="string" as="xs:string?"/>
    <xsl:param name="out" as="xs:string*"/>
    <xsl:choose>
      <xsl:when test="$string">
        <xsl:sequence select="zip:string2chars(substring($string, 2), ($out, substring($string, 1, 1)))"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="$out"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <xsl:function name="zip:countChars" as="element(zip:leaf)*">
    <xsl:param name="in" as="xs:string"/>
    <xsl:variable name="chars" as="xs:string*" select="zip:string2chars($in)"/>
    <xsl:variable name="leaves">
      <xsl:for-each select="distinct-values($chars)">
        <xsl:variable name="char" select="."/>
        <zip:leaf char="{$char}" weight="{count($chars[. eq $char])}"/>
      </xsl:for-each>
    </xsl:variable>
    <xsl:perform-sort select="$leaves/*">
      <xsl:sort select="./@weight" order="ascending"/>
    </xsl:perform-sort>
  </xsl:function>
  
  <xsl:function name="zip:mkHuffTree" as="element(zip:leaf)?">
    <xsl:param name="in"/>
    <xsl:choose>
      <xsl:when test="$in instance of xs:string">
        <xsl:variable name="leaves" select="zip:countChars($in)"/>
        <xsl:sequence select="zip:mkHuffTree($leaves)"/>
      </xsl:when>
      <xsl:when test="$in[count(.) eq count(.[self::zip:leaf])]">
        <xsl:choose>
          <xsl:when test="count($in) le 1">
            <xsl:sequence select="$in"/>
          </xsl:when>
          <xsl:otherwise>
						<xsl:variable name="in2" as="element(zip:leaf)+">
							<xsl:perform-sort select="$in">
								<xsl:sort select="xs:double(./@weight)" order="ascending"/>
							</xsl:perform-sort>
						</xsl:variable>
            <xsl:variable name="newLeaf" as="element(zip:leaf)">
              <zip:leaf weight="{xs:integer(sum($in2[position() le 2]/@weight))}" chars="{string-join($in2[position() le 2]/(@char|@chars), '')}">
                <xsl:apply-templates select="$in2[1], $in2[2]" mode="zip:copy"/>
              </zip:leaf>
            </xsl:variable>
            <xsl:variable name="out" as="element(zip:leaf)+">
              <xsl:sequence select="($in2[position() gt 2], $newLeaf)"/>
            </xsl:variable>
            <xsl:sequence select="zip:mkHuffTree($out)"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
    </xsl:choose>
  </xsl:function>
  
  <xsl:function name="zip:bits2integer" as="xs:integer">
    <xsl:param name="in" as="xs:string"/>
    <xsl:variable name="i" select="replace($in, '[^01]', '')"/>
    <xsl:value-of select="zip:bits2integer($i, 0)"/>
  </xsl:function>
  
  <xsl:function name="zip:bits2integer" as="xs:integer">
    <xsl:param name="in" as="xs:string"/>
    <xsl:param name="out" as="xs:integer"/>
    <xsl:choose>
      <xsl:when test="string-length($in) eq 0">
        <xsl:value-of select="$out"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="zip:bits2integer(substring($in, 2), xs:integer(substring($in, 1, 1)) + 2*$out)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <xsl:function name="zip:integer2bits" as="xs:string">
    <xsl:param name="in" as="xs:integer"/>
    <xsl:value-of select="zip:integer2bits($in, '')"/>
  </xsl:function>
  
  <xsl:function name="zip:integer2bits" as="xs:string">
    <xsl:param name="in" as="xs:integer?"/>
    <xsl:param name="out" as="xs:string"/>
    <xsl:choose>
      <xsl:when test="$in ne 0">
        <xsl:value-of select="zip:integer2bits(xs:integer(floor($in div 2)), string-join((string($in mod 2), $out), ''))"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$out"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
 
  
  <xsl:function name="zip:Huffdecode" as="xs:string">
    <xsl:param name="in" as="xs:string"/>
    <xsl:param name="tree" as="element(zip:leaf)?"/>
    <xsl:value-of select="zip:Huffdecode($in, $tree, $tree, '')"/>
  </xsl:function>
  
  <xsl:function name="zip:Huffdecode" as="xs:string">
    <xsl:param name="in" as="xs:string"/>
    <xsl:param name="tree" as="element(zip:leaf)?"/>
    <xsl:param name="orig" as="element(zip:leaf)?"/>
    <xsl:param name="out" as="xs:string"/>
    <xsl:choose>
      <xsl:when test="$in">
        <xsl:variable name="pos" select="1 + xs:integer(substring($in, 1, 1))"/>
        <xsl:variable name="rem" select="substring($in, 2)"/>
        <xsl:choose>
          <xsl:when test="$tree/@char">
            <xsl:value-of select="zip:Huffdecode($in, $orig, $orig, concat($out, $tree/@char))"/>
          </xsl:when>
          <xsl:when test="$tree/@chars">
            <xsl:value-of select="zip:Huffdecode($rem, $tree/zip:leaf[$pos], $orig, $out)"/>
          </xsl:when>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:choose>
          <xsl:when test="$tree/@char">
            <xsl:value-of select="concat($out, $tree/@char)"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$out"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <xsl:function name="zip:HuffTreeEncode" as="xs:string">
    <xsl:param name="in" as="xs:string"/>
    <xsl:param name="tree" as="element(zip:leaf)"/>
    <xsl:variable name="char" select="substring($in, 1, 1)"/>
    <xsl:variable name="bits">
      <xsl:apply-templates select="$tree/*[contains((@chars, @char)[1], $char)]" mode="zip:HuffTreeEncode">
        <xsl:with-param name="ch" tunnel="yes" select="$char"/>
      </xsl:apply-templates>
    </xsl:variable>
    <xsl:value-of select="string-join($bits, '')"/>
  </xsl:function>
  
  <xsl:template match="zip:leaf" mode="zip:HuffTreeEncode">
    <xsl:param name="ch" tunnel="yes" as="xs:string"/>
    <xsl:value-of select="count(preceding-sibling::*)"/>
    <xsl:apply-templates select="zip:leaf[contains((@chars, @char)[1], $ch)]" mode="zip:HuffTreeEncode"/>
  </xsl:template>
  
  <xsl:function name="zip:mkEncodeTbl" as="element(zip:table)+">
    <xsl:param name="tree" as="element(zip:leaf)"/>
    <xsl:for-each select="zip:string2chars($tree/@chars)">
      <zip:table char="{.}" code="{zip:HuffTreeEncode(., $tree)}"/>
    </xsl:for-each>
  </xsl:function>
  
  <xsl:function name="zip:HuffEncode" as="xs:string">
    <xsl:param name="string" as="xs:string"/>
    <xsl:param name="tree" as="element(zip:leaf)"/>
    <xsl:variable name="table" select="zip:mkEncodeTbl($tree)"/>
    <xsl:variable name="codes">
      <xsl:for-each select="zip:string2chars($string)">
        <xsl:variable name="ch" select="."/>
        <xsl:value-of select="$table[@char eq $ch]/@code"/>
      </xsl:for-each>
    </xsl:variable>
    <xsl:value-of select="string-join($codes, '')"/>
  </xsl:function>
  
  <xsl:template match="node()|@*" mode="zip:copy">
    <xsl:copy>
      <xsl:apply-templates select="node()|@*" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
</xsl:stylesheet>
