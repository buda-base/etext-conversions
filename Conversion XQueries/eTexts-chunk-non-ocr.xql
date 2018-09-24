xquery version "3.0";

declare namespace q="http://tbrc.org/exist/xquery/local";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace x="http://exist-db.org/xquery/xmldb";

declare variable $q:inPath { "/db/eTexts" };
declare variable $q:outPath { "/db/eTextsChunked" };
declare variable $q:size { 1000 };

declare option exist:timeout "14400000";

declare function q:get-chunk-end($piece as xs:string?, $rest as xs:string*, $currSz as xs:int, $inx as xs:int, $lim as xs:int)
as xs:int
{
    if ($currSz gt $lim or empty($rest)) then
        $inx
    else
        let $p := $rest[1]
        let $r := subsequence($rest, 2)
        return
            q:get-chunk-end($p, $r, $currSz + string-length($p), $inx + 1, $lim)
};

declare function q:chunk-text($pieces as xs:string*, $sz as xs:int, $chunks as element()*)
as element()*
{
    if (empty($pieces)) then
        $chunks
    else
        let $piece := $pieces[1]
        let $rest := subsequence($pieces, 2)
        let $cx := q:get-chunk-end($piece, $rest, string-length($piece), 1, $sz)
        let $chunkTxt := string-join(subsequence($pieces, 1, $cx), " ")
        let $chunk :=
            <tei:p unit="page">{$chunkTxt}</tei:p>
        return
            q:chunk-text(subsequence($pieces, $cx + 1), $sz, ($chunks, $chunk))
};

declare function q:process-node($node as node()?, $sz as xs:int)
as element()*
{
    if ($node instance of element()) then
        if ($node/@unit eq "chunk") then
            ()
        else
            $node
    else if ($node instance of text()) then
        let $pieces := tokenize($node, "\s+")
        let $chunks := q:chunk-text($pieces, $sz, ())
        return
            $chunks
    else
        ()
};

declare function q:process-nodes($nodes as node()*, $sz as xs:int)
as element()*
{
    for $node in $nodes
    let $rezs := q:process-node($node, $sz)
    return
        $rezs
};

declare function q:chunkDoc($doc as element())
as element()*
{
    let $header := $doc/tei:teiHeader
    let $nodes := $doc//tei:div/node()
    let $rez :=  q:process-nodes($nodes, $q:size)
    let $doc1 :=
        <tei:TEI>{ $doc/@*,
            $header
            }<tei:text><tei:body><tei:div>{
               $rez
            }</tei:div></tei:body></tei:text>
        </tei:TEI>
    (: the following adds in the page numbers :)
    let $xslt :=
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
    let $doc2 := transform:transform($doc1, $xslt, ())
    return
        $doc2
};

declare function q:processCollection($collNm as xs:string?)
as element()*
{
    let $destColl := x:create-collection($q:outPath, $collNm)
    for $utNm in xmldb:get-child-collections($q:inPath || "/" || $collNm)
    let $utColl :=  x:create-collection($destColl, $utNm)
    for $volNm in xmldb:get-child-collections($q:inPath || "/" || $collNm || "/" || $utNm)
    let $volColl := x:create-collection($utColl, $volNm)
    for $inDoc in collection($q:inPath || "/" || $collNm || "/" || $utNm || "/" || $volNm)/tei:TEI
    let $ign := util:log("INFO", "Processing " || util:document-name($inDoc))
    let $outDoc := q:chunkDoc($inDoc)
    let $outPath := $q:outPath || "/" || $collNm || "/" || $utNm || "/" || $volNm
    let $rez := x:store($outPath, util:document-name($inDoc), $outDoc)
    return
        ()
};

let $rez := q:processCollection("GuruLamaWorks")
return
    "done"

(: 
let $doc1 := doc("/db/eTexts/DharmaDownload/UT10919/UT10919-001/UT10919-001-0000.xml")/tei:TEI
let $doc2 := doc("/db/eTexts/DharmaDownload/UT10736/UT10736-001/UT10736-001-0002.xml")/tei:TEI
let $nodes := $doc2//tei:div/node()
let $rez :=  q:process-nodes($nodes, $q:size)
let $xot := q:chunkDoc($doc1)
return
    $xot
    
    
    
    
    
 :)
