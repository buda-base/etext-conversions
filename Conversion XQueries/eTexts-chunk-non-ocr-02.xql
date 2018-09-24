xquery version "3.0";

declare namespace q="http://tbrc.org/exist/xquery/local";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace x="http://exist-db.org/xquery/xmldb";

declare variable $q:inPath { "/db/eTexts" };
declare variable $q:outPath { "/db/eTextsChunked" };
declare variable $q:size { 1380 };

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

declare function q:process-node($node as  xs:string?, $sz as xs:int)
as element()*
{
    let $pieces := tokenize($node, "\s+")
    let $chunks := q:chunk-text($pieces, $sz, ())
    return
        $chunks
};

declare function q:join-text-nodes($node as xs:string?, $rest as xs:string*, $sz as xs:int)
as xs:string*
{
    if (empty($rest)) then
        $node
    else if (string-length($node) ge 8 * $sz) then
        ($node, q:join-text-nodes($rest[1], subsequence($rest, 2), $sz))
    else
        q:join-text-nodes($node || " " || $rest[1], subsequence($rest, 2), $sz)
    
};

declare function q:process-nodes($nodes0 as xs:string*, $sz as xs:int)
as element()*
{
    let $ign := util:log("INFO", "      Process Nodes " || count($nodes0))
    let $firstNode := $nodes0[1]
    let $rest0 := subsequence($nodes0, 2)
    let $nodes :=  ($firstNode, q:join-text-nodes($rest0[1], subsequence($rest0, 2), $sz))
    for $node in $nodes
    let $rezs := q:process-node($node, $sz)
    return
        $rezs
};

declare function q:numberChunks()
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

declare function q:chunkDoc($doc as element())
as element()*
{
    let $header := $doc/tei:teiHeader
    let $nodes0 := $doc//tei:div/node()
    return
        if (empty($nodes0)) then
            let $ign := util:log("INFO", "!!!!!!!!!!!!!!! EMPTY DOC: " || util:document-name($doc))
            return
                <tei:TEI>{ $doc/@*,
                    $header
                    }<tei:text><tei:body><tei:div/></tei:body></tei:text>
                </tei:TEI>
        else
            let $nodes := $nodes0[not(self::tei:milestone)]
            let $rez :=  q:process-nodes($nodes, $q:size)
            let $doc1 :=
                <tei:TEI>{ $doc/@*,
                    $header
                    }<tei:text><tei:body><tei:div>{
                       $rez
                    }</tei:div></tei:body></tei:text>
                </tei:TEI>
            (: add page numbers to <tei:p/> elements :)
            let $doc2 := transform:transform($doc1, q:numberChunks(), ())
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
    let $rez := 
        if (not(empty($outDoc))) then
            x:store($outPath, util:document-name($inDoc), $outDoc)
        else
            ()
    return
        ()
};

let $rez := q:processCollection("VajraVidya")
return
    "done"

 
(: let $doc2 := doc("/db/eTexts/DharmaDownload/UT10736/UT10736-001/UT10736-001-0002.xml")/tei:TEI
let $nodes := $doc2//tei:div/node()[not(self::tei:milestone)]
let $rez :=  q:process-nodes($nodes, $q:size)
return
    <x>{ $rez }</x> :)

(: let $doc1 := doc("/db/eTexts/DharmaDownload/UT10919/UT10919-001/UT10919-001-0000.xml")/tei:TEI :)
(: let $doc1 := doc("/db/eTexts/DharmaDownload/UT1KG12028/UT1KG12028-001/UT1KG12028-001-0000.xml")/tei:TEI :)
(: let $doc1 := doc("/db/eTexts/DrikungChetsang/UT23784/UT23784-001/UT23784-001-0001.xml")/tei:TEI :)
(: let $doc1 := doc("/db/eTexts/Shechen/UT1KG14/UT1KG14-043/UT1KG14-043-0063.xml")/tei:TEI
let $xot := q:chunkDoc($doc1)
return
    $xot :)
    
    
    
    
    
 
