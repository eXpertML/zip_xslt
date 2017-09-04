<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
	version="2.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:fn="http://www.w3.org/2005/xpath-functions"
	xmlns:b64="http://xsl.expertml.com/base64.xslt"
	>
	
	<!-- param to specify characters relating to positions 62 and 63 in base64 encoding map -->
	<xsl:param name="b64:encoding" select="'+/'" as="xs:string"/>
	<!-- param to specify entire base64 encoding map (position correlates to numeric value); generally, only the last two characters (if any) need to be specified: see $b64:encoding above -->
	<xsl:param name="b64:encoding_map" select="concat('ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789', $b64:encoding)" as="xs:string"/>
	
	<xsl:function name="b64:encode" as="xs:string">
		<xsl:param name="in" as="xs:string"/>
		<xsl:value-of select="b64:encode($in, '')"/>
	</xsl:function>
	
	<xsl:function name="b64:encode" as="xs:string">
		<xsl:param name="in" as="xs:string"/>
		<xsl:param name="out" as="xs:string"/>
		<xsl:choose>
			<xsl:when test="fn:string-length($in) eq 0">
				<xsl:value-of select="$out"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="cps" select="fn:string-to-codepoints(substring($in, 1, 3))"/>
				<xsl:variable name="b" select="string-join(for $cp in $cps return format-number(xs:integer(b64:dec2bin($cp)), '00000000'), '')"/>
				<xsl:variable name="bl" select="string-length($b)"/>
				<xsl:variable name="bin" select="concat($b, substring('000000000000000000000000', $bl))"/>
				<xsl:variable name="bin4" select="for $i in 0 to 3 return substring($bin, 1 + ($i * 6), 6)"/>
				<xsl:variable name="dec4" select="for $x in $bin4 return b64:bin2dec($x)"/>
				<xsl:variable name="chars">
					<xsl:for-each select="$dec4">
						<xsl:choose>
							<xsl:when test=". eq 0">
								<xsl:value-of select="'='"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="b64:lookupChar(.)"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:for-each>
				</xsl:variable>
				<xsl:value-of select="b64:encode(substring($in, 4), concat($out, string-join($chars, '')))"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	
	<xsl:function name="b64:decode" as="xs:string">
		<xsl:param name="in" as="xs:string"/>
		<xsl:value-of select="fn:codepoints-to-string(b64:decodeCP($in)[. ne 0])"/>
	</xsl:function>
	
	<xsl:function name="b64:decodePadding" as="xs:string">
		<xsl:param name="in" as="xs:string"/>
		<xsl:variable name="unpadded" select="fn:replace($in, '^(.+?)=+$', '$1')"/>
		<xsl:variable name="padding-size" select="(4 - fn:string-length($unpadded) mod 4) mod 4"/>
		<xsl:variable name="padding" select="for $n in 1 to $padding-size return ' '" as="xs:string*"/>
		<xsl:value-of select="fn:string-join(($unpadded, $padding), '')"/>
	</xsl:function>
	
	<xsl:function name="b64:decodeCP" as="xs:integer*">
		<xsl:param name="in" as="xs:string"/>
		<xsl:sequence select="b64:decodeCP(b64:decodePadding($in), ())"/>
	</xsl:function>
	
	<xsl:function name="b64:decodeCP" as="xs:integer*">
		<xsl:param name="in" as="xs:string"/>
		<xsl:param name="out" as="xs:integer*"/>
		<xsl:choose>
			<xsl:when test="string-length($in) lt 4">
				<xsl:sequence select="$out"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="cp" as="xs:integer*" select="for $n in 1 to 4 return b64:lookupNum(substring($in, $n, 1))"/>
				<xsl:variable name="bin" select="string-join(for $i in $cp return format-number(xs:integer(b64:dec2bin($i)), '000000'), '')" as="xs:string"/>
				<xsl:variable name="bin3" select="for $j in 0 to 2 return substring($bin, 1 + ($j * 8), 8)" as="xs:string+"/>
				<xsl:variable name="dec3" select="for $b in $bin3 return b64:bin2dec($b)" as="xs:integer+"/>
				<xsl:sequence select="b64:decodeCP(fn:substring($in, 5), ($out, $dec3))"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	
	<xsl:function name="b64:toHex" as="xs:string*">
		<xsl:param name="in" as="xs:string"/>
		<xsl:sequence select="for $i in b64:decodeCP($in) return b64:dec2hex($i)"/>
	</xsl:function>

	<xsl:function name="b64:lookupChar" as="xs:string">
		<xsl:param name="number" as="xs:integer"/>
		<xsl:value-of select="substring($b64:encoding_map, $number + 1, 1)"/>
	</xsl:function>
	
	<xsl:function name="b64:lookupNum" as="xs:integer">
		<xsl:param name="char" as="xs:string"/>
		<xsl:variable name="first" select="fn:substring($char, 1, 1)"/>
		<xsl:value-of select="string-length(substring-before($b64:encoding_map, $first))"/>
	</xsl:function>
	
	<xsl:function name="b64:string2chars" as="xs:string*">
		<xsl:param name="in" as="xs:string"/>
		<xsl:sequence select="for $x in 1 to string-length($in) return substring($in, $x, 1)"/>
	</xsl:function>

	<xsl:function name="b64:dec2hex" as="xs:string">
		<xsl:param name="in" as="xs:integer"/>
		<xsl:value-of select="b64:dec2hex($in, '')"/>
	</xsl:function>
	
	<xsl:function name="b64:dec2hex" as="xs:string">
		<xsl:param name="in" as="xs:integer"/>
		<xsl:param name="out" as="xs:string"/>
		<xsl:choose>
			<xsl:when test="$in eq 0">
			<xsl:variable name="value">
				<xsl:if test="fn:string-length($out) mod 2 eq 1"><xsl:text>0</xsl:text></xsl:if>
				<xsl:value-of select="$out"/>
			</xsl:variable>
			<xsl:value-of select="fn:string-join($value, '')"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="b64:dec2hex(xs:integer(floor($in div 16)), concat(substring('0123456789ABCDEF', 1 + ($in mod 16), 1), $out))"/>
			</xsl:otherwise>
		</xsl:choose>		
	</xsl:function>
	
	<xsl:function name="b64:hex2bin" as="xs:string">
		<xsl:param name="hex"/>
		<xsl:value-of select="b64:dec2bin(b64:hex2dec($hex))"/>
	</xsl:function>
		
	<xsl:function name="b64:dec2bin" as="xs:string">
		<xsl:param name="dec"/>
		<xsl:value-of select="b64:dec2bin(xs:integer($dec), '')"/>
	</xsl:function>
	
	<xsl:function name="b64:dec2bin" as="xs:string">
		<xsl:param name="dec" as="xs:integer"/>
		<xsl:param name="bin" as="xs:string"/>
		<xsl:choose>
			<xsl:when test="$dec ne 0">
				<xsl:value-of select="b64:dec2bin(xs:integer(fn:floor($dec div 2)), fn:concat(xs:string($dec mod 2), $bin))"/>
			</xsl:when>
			<xsl:when test="fn:string-length($bin) eq 0">
				<xsl:value-of select="0"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$bin"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	
	<xsl:function name="b64:hex2dec" as="xs:integer">
		<xsl:param name="hex"/>
		<xsl:variable name="h">
			<xsl:choose>
				<xsl:when test="fn:string-length(xs:string($hex)) mod 2 eq 0">
					<xsl:value-of select="$hex"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="fn:concat('0', xs:string($hex))"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:value-of select="b64:hex2dec(xs:string(xs:hexBinary($h)), 0)"/>
	</xsl:function>
	
	<xsl:function name="b64:hex2dec" as="xs:integer">
		<xsl:param name="hex" as="xs:string"/>
		<xsl:param name="dec" as="xs:integer"/>
		<xsl:variable name="i" select="substring($hex, 1, 1)"/>
		<xsl:variable name="value" select="string-length(substring-before('0123456789ABCDEF', $i))"/>
		<xsl:variable name="result" select="$value + 16 * $dec"/>
		<xsl:choose>
			<xsl:when test="string-length($hex) gt 1">
				<xsl:value-of select="b64:hex2dec(substring($hex, 2), $result)"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$result"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	
	<xsl:function name="b64:bin2dec" as="xs:integer">
		<xsl:param name="bin"/>
		<xsl:variable name="b" select="xs:string(replace(xs:string($bin), '[^01]', ''))"/>
		<xsl:value-of select="b64:bin2dec($b, 0)"/>
	</xsl:function>
	
	<xsl:function name="b64:bin2dec" as="xs:integer">
		<xsl:param name="bin" as="xs:string"/>
		<xsl:param name="dec" as="xs:integer"/>
		<xsl:variable name="i" select="xs:integer(substring($bin, 1, 1))"/>
		<xsl:variable name="result" select="$i + 2 * $dec"/>
		<xsl:variable name="remainder" select="substring($bin, 2)"/>
		<xsl:choose>
			<xsl:when test="xs:string($i) eq $bin">
				<xsl:value-of select="$result"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="b64:bin2dec($remainder, $result)"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	
</xsl:stylesheet>
