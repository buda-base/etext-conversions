 xquery version "3.0";

import module namespace cx="http://exist-db.org/xquery/contentextraction"
at "java:org.exist.contentextraction.xquery.ContentExtractionModule";

import module namespace fx="http://www.functx.com"
at "/db/modules/functx-1.0.xqm";

declare namespace q="http://exist-db.org/xquery/local";

declare default element namespace "http://www.w3.org/1999/xhtml";
declare namespace html="http://www.w3.org/1999/xhtml";
declare namespace tei="http://www.tei-c.org/ns/1.0";

declare namespace u="http://exist-db.org/xquery/util";
declare namespace f="http://exist-db.org/xquery/file";
declare namespace x="http://exist-db.org/xquery/xmldb";
declare namespace w="http://www.tbrc.org/models/work#";

declare option exist:timeout "7200000";

declare variable $collNm := "eTextsChunked";
declare variable $cUri := "/db/" || $collNm || "/";

declare function q:numberPages()
as element()
{
    <xsl:stylesheet version="2.0"
        xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
        xmlns:tei="http://www.tei-c.org/ns/1.0">
        <xsl:output omit-xml-declaration="yes" indent="yes"/>
        
        <xsl:template match="node()|@*">
            <xsl:copy>
                <xsl:apply-templates select="node()|@*"/>
            </xsl:copy>
        </xsl:template>
    
        <xsl:template match="tei:p" name="addPage">
            <xsl:variable name="pg" select="1 + count(preceding-sibling::tei:p)"/>
            <tei:p n="{{$pg}}">
                <xsl:apply-templates select="node()|@*"/>
            </tei:p>
        </xsl:template>
    </xsl:stylesheet>
};

declare function q:milestone2page($doc as element()?)
    as element()*
{
    let $xslt := 
        <xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
            xmlns:tei="http://www.tei-c.org/ns/1.0" version="2.0">
            <!-- delete the line markers -->
            <!-- xsl:template match="tei:milestone[@unit='line']"/ -->
            <!-- expand the page milestones to p elements containing the content between page milestones -->
            <xsl:template match="tei:div">
                <tei:div>
                    <xsl:for-each-group select="node()" group-starting-with="tei:milestone[@unit='page']">
                        <tei:p>
                            <!-- xsl:sequence select="current()/@*"/ -->
                            <xsl:apply-templates select="current-group()[not(self::tei:milestone/@unit='page')]"/>
                        </tei:p>
                    </xsl:for-each-group>
                </tei:div>
            </xsl:template>
            <!-- copy everything else -->
            <xsl:template match="@*|node()">
                <xsl:copy>
                    <xsl:apply-templates select="@*|node()"/>
                </xsl:copy>
            </xsl:template>
        </xsl:stylesheet>
    return 
        transform:transform($doc, $xslt, ())
};

declare function q:process-text($path as xs:string?, $textRid as xs:string?, $textPath as xs:string?, $volNo as xs:string?)
as element()*
{
    let $ign := util:log("INFO", "PROCESSING: " || $textRid)
    let $contents := f:read($path, "UTF-8")
    let $lines := tokenize($contents, '\n')
    let $title := $lines[1]
    let $header :=
        <tei:teiHeader>
    	    <tei:fileDesc>
        		<tei:titleStmt>
        			<tei:title>{$title} [{$volNo}]</tei:title>
        		</tei:titleStmt>
        		<tei:publicationStmt>
        			<tei:distributor>
        				Text input with the support of THDL at UVa, with supervision of Nawang Trinley
        			</tei:distributor>
        			<tei:idno type="TBRC_TEXT_RID">{$textRid}</tei:idno>
        			<tei:idno type="page_equals_image">page_equals_image</tei:idno>
        		</tei:publicationStmt>
        		<tei:sourceDesc>
        			<tei:bibl>
        				<tei:idno type="TBRC_RID">W4CZ5369</tei:idno>
        				<tei:idno type="SRC_PATH">{$textPath}</tei:idno>
        			</tei:bibl>
        		</tei:sourceDesc>
            </tei:fileDesc>
        </tei:teiHeader>
    let $body :=
        <tei:text>
            <tei:body>
                <tei:div>{
                    <tei:milestone unit="page" n="0"/>,
                    $title,
                    for $line at $pos in subsequence($lines, 2)
                    return
                        if (matches($line, "^\[.+\..+\]"))
                        then
                            let $parts := tokenize($line, "\]")
                            let $text := $parts[count(.)]
                            let $lineNo := tokenize($parts[1], "\.")[count(.)]
                            return
                                (<tei:milestone unit="line" n="{$lineNo}"/>, $text)
                        else if (matches($line, "^\["))
                        then <tei:milestone unit="page" n="{$pos}"/>
                        else $line
                }</tei:div>
            </tei:body>
        </tei:text>
    let $doc1 :=
        <tei:TEI xmlns:tei="http://www.tei-c.org/ns/1.0">{
            $header,
            $body
        }</tei:TEI>
    let $doc2 := q:milestone2page($doc1)
    let $doc3 := transform:transform($doc2, q:numberPages(), ())
    return
        $doc3
};

declare function q:import-text($base as xs:string?, $volPath as xs:string?, $textId as xs:string?, $vColl as xs:string?, $work as element()?)
as element()*
{
    let $textPath := concat($volPath, "/", $textId)
    let $fullPath := concat($base, "/", $textPath)
    let $textRid := replace(fx:substring-before-last($textId, "."), "^W", "UT")
    let $utNm := $textRid || ".xml"
    let $igroupRid := tokenize($vColl, "-")[count(.)]
    let $volNo := $work/w:volumeMap/w:volume[matches(@imagegroup, $igroupRid)]/@num
    let $newDoc := q:process-text($fullPath, $textRid, $textPath, $volNo)
    let $stored := x:store($vColl, $utNm, $newDoc)
    let $doc := doc($stored)
    let $title := "pod " || $volNo || " " || $work/w:title[1]
    return (
        <text>{ $stored,  $title }</text>
    )
};

declare function q:import-volume($base as xs:string?, $sourcesPath as xs:string?, $volNm as xs:string?, $vColl as xs:string?, $work as element()?)
as element()*
{
    let $volPath := $sourcesPath || "/" || $volNm
    let $fullPath := $base || "/" || $volPath
    for $text in f:list($fullPath)//f:file[@hidden="false"][matches(@name, ".+\.txt")]
    return
        q:import-text($base, $volPath, $text/@name, $vColl, $work)
};

declare function q:import-work($base as xs:string?, $source as xs:string?, $wRid as xs:string?, $wColl as xs:string?, $work as element()?)
as element()*
{
    let $srcsPath := $source || "/" || $wRid || "/sources"
    let $fullPath := $base || "/" || $srcsPath
    for $vol in f:list($fullPath)//f:directory[@hidden="false"]
    let $volNm := string($vol/@name)
    let $utNm := replace($volNm, "^W", "UT")
    let $vColl :=  x:create-collection($wColl, $utNm)
    return
        q:import-volume($base, $srcsPath, $volNm, $vColl, $work)
};

declare function q:import-source($base as xs:string?, $source as xs:string?, $destCollNm as xs:string?)
as element()*
{
    let $sourcePath := $base || "/" || $source
    let $sColl := x:create-collection($cUri, $destCollNm)
    for $wNm in f:list($sourcePath)//f:directory[@hidden="false"]
    let $wRid := string($wNm/@name)
    let $utNm := replace($wRid, "^W", "UT")
    let $work := collection("/db/tbrc/tbrc-works")/w:work[@RID=$wRid]
    let $wColl :=  x:create-collection($sColl, $utNm)
    return
        q:import-work($base, $source, $wRid, $wColl, $work)
};


<imported>{
q:import-source("/Users/chris/Desktop/TBRC/eTexts-Processing", "eKangyur", "eKangyur")
}</imported>


(: 
let $base := "/Users/chris/Desktop/TBRC/eTexts-Processing"
let $wRid := "W4CZ5369"
let $work := collection("/db/tbrc/tbrc-works")/w:work[@RID=$wRid]
let $textPath := "/eKangyur/" || $wRid || "/sources/" || "W4CZ5369-I1KG9127/" || "W4CZ5369-I1KG9127-0000.txt"
let $fullPath := $base || $textPath
let $textRid := "UT4CZ5369-I1KG9127-0000"
let $volNo := "1"
return
    q:process-text($fullPath, $textRid, $textPath, $volNo)
 :)

