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

declare option exist:timeout "7200000";

declare variable $collNm := "eTextsIncoming";
declare variable $cUri := "/db/eTextsIncoming/";

declare function q:toTEI($doc as element()?)
    as element()*
{
    let $xslt := 
        <xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
          xmlns:x="http://www.w3.org/1999/xhtml"
          xmlns:tei="http://www.tei-c.org/ns/1.0"
          version="1.0">
            <xsl:template match="x:b">
                <xsl:value-of select="."/>
            </xsl:template>
            <xsl:template match="x:p">
                <xsl:variable name="pNum">
                   <xsl:number level="any" count="x:p"/>
                </xsl:variable>
                <tei:milestone unit="chunk">
                    <xsl:attribute name="n">
                        <xsl:value-of select="$pNum"/>
                    </xsl:attribute>
                </tei:milestone>
                <xsl:analyze-string select="." regex="&#x00AB;|&#x00BB;">
                    <xsl:matching-substring>
                        <xsl:if test="matches(.,'&#x00AB;')" >
                            <tei:milestone unit="small"/>
                        </xsl:if>
                        <xsl:if test="matches(.,'&#x00BB;')" >
                            <tei:milestone unit="normal"/>
                        </xsl:if>
                    </xsl:matching-substring>
                    <xsl:non-matching-substring>
                        <xsl:value-of select="."/>
                    </xsl:non-matching-substring>
                </xsl:analyze-string>
            </xsl:template>
            <xsl:template match="x:html">
                <tei:TEI>
                    <xsl:apply-templates select="@*|node()"/>
                </tei:TEI>
            </xsl:template>
            <xsl:template match="x:head">
                <tei:teiHeader>
                    <tei:fileDesc>
                        <tei:titleStmt>
                            <tei:title type="derived"/>
                            <tei:author/>
                        </tei:titleStmt>
                        <tei:publicationStmt>
                            <tei:distributor/>
                            <tei:idno type="TBRC_RID"/>
                            <tei:availability status="free">
                                <tei:licence target="http://creativecommons.org/licenses/by/3.0/" when="2014-01-01">
                                    The Creative Commons Attribution 3.0 Unported (CC BY 3.0) Licence
                                        applies to this document.
                                    The licence was added on January 1, 2014.
                                </tei:licence>
                            </tei:availability>
                            <tei:date when="2014">2014</tei:date>
                        </tei:publicationStmt>
                        <tei:sourceDesc>
                            <tei:bibl>
                                <tei:idno type="TBRC_RID"/>
                            </tei:bibl>
                        </tei:sourceDesc>
                    </tei:fileDesc>
                </tei:teiHeader>
            </xsl:template>
            <xsl:template match="x:body">
                <tei:text>
                    <tei:body>
                        <tei:div>
                            <xsl:apply-templates select="@*|node()"/>
                        </tei:div>
                    </tei:body>
                </tei:text>
            </xsl:template>
            <xsl:template match="@*|node()">
                <xsl:copy>
                    <xsl:apply-templates select="@*|node()"/>
                </xsl:copy>
            </xsl:template>
        </xsl:stylesheet>
    return 
        transform:transform($doc, $xslt, ())
};

declare function q:add-title($ps as element()*)
as xs:string*
{
    if ($ps) then
        let $p := $ps[1]
        let $s1 := string($p)
        let $s2 := fx:left-trim(replace($s1, '\P{IsTibetan}', '')) (: ignore non-Tibetan chars :)
        let $s := replace($s2, '།།', '།  །')
        return
            if (string-length($s) gt 12) then
                substring($s, 1, 128)
            else
                q:add-title(subsequence($ps, 2))
    else
        "no title"
};


declare function q:import-text($volPath as xs:string?, $textId as xs:string?, $vColl as xs:string?, $dist as xs:string?)
as element()*
{
    let $textPath := concat($volPath, "/", $textId)
    let $textNm := fx:substring-before-last($textId, ".")
    let $textFile := f:read-binary($textPath)
    let $tikaDoc := cx:get-metadata-and-content($textFile)
    let $newDoc := q:toTEI($tikaDoc/html)
    let $docNm := concat($textNm, ".xml")
    return
        if ($newDoc) then
            let $stored := x:store($vColl, $docNm, $newDoc)
            let $fullName := concat($vColl, "/", $docNm)
            let $doc := doc($stored)
            let $title := q:add-title($tikaDoc/html/body/p)
            let $junk := update value $doc/tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title with $title
            let $junk := update value $doc/tei:TEI/tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:distributor with $dist
            return
               <text>{ $stored,  $title }</text>
        else
            <failed>### COULD NOT PARSE: { $textPath }</failed>
};

declare function q:import-volume($rtfsPath as xs:string?, $volNm as xs:string?, $vColl as xs:string?, $dist as xs:string?)
as element()*
{
    let $volPath := concat($rtfsPath, "/", $volNm)
    for $text in f:list($volPath)//f:file[@hidden="false"][matches(@name, ".+\.rtf")]
    return
        q:import-text($volPath, $text/@name, $vColl, $dist)
};

declare function q:import-work($sourcePath as xs:string?, $workNm as xs:string?, $wColl as xs:string?, $dist as xs:string?)
as element()*
{
    let $rtfsPath := concat($sourcePath, "/", $workNm, "/rtfs")
    for $vol in f:list($rtfsPath)//f:directory[@hidden="false"]
    let $volNm := string($vol/@name)
    let $vColl :=  x:create-collection($wColl, $volNm)
    return
        q:import-volume($rtfsPath, $volNm, $vColl, $dist)
};

declare function q:import-source($sourcePath as xs:string?, $destCollNm as xs:string?, $dist as xs:string?)
as element()*
{
    let $sColl := x:create-collection($cUri, $destCollNm)
    for $work in f:list($sourcePath)//f:directory[@hidden="false"]
    let $workNm := string($work/@name)
    let $wColl :=  x:create-collection($sColl, $workNm)
    return
        q:import-work($sourcePath, $workNm, $wColl, $dist)
};


<imported>{
q:import-source("/Users/chris/Desktop/TBRC/eTexts-Processing/FINAL/XXX", "LarungGar", "Larung Gar")
}</imported>

(: 
let $textPath := "/Users/chris/Desktop/TBRC/eTexts-Processing/FINAL/KarmaDelek/co-ne-grags-pa-bshad-sgrub-gsung-qbum/rtfs/volume_001/volume_001_003.rtf"
let $textFile := f:read-binary($textPath)
let $tikaDoc := cx:get-metadata-and-content($textFile)
return
    q:toTEI($tikaDoc/html)
:)
