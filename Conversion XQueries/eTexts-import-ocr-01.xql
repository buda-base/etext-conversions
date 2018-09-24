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

declare variable $collNm := "eTexts";
declare variable $cUri := "/db/eTexts/";


declare function q:import-text($base as xs:string?, $volPath as xs:string?, $textId as xs:string?, $vColl as xs:string?, $work as element()?)
as element()*
{
    let $textPath := concat($volPath, "/", $textId)
    let $fullPath := concat($base, "/", $textPath)
    let $textRid := replace(concat(fx:substring-before-last($textId, "."), "-0000"), "^W", "UT")
    let $utNm := concat($textRid, ".xml")
    let $log := util:log("warn", concat("@@@@@@@@@@@@>>>> q:import-text PROCESSING: ", $fullPath))
    return
        try {
            let $xmlFile := f:read($fullPath)
            let $newDoc := util:parse($xmlFile)
            let $stored := x:store($vColl, $utNm, $newDoc)
            let $doc := doc($stored)
            let $igroupRid := tokenize($vColl, "-")[count(.)]
            let $volNo := $work/w:volumeMap/w:volume[matches(@imagegroup, $igroupRid)]/@num
            let $title := concat("pod ", $volNo, " ", $work/w:title[1])
            let $pubStmt := $doc/tei:TEI/tei:teiHeader/tei:fileDesc/tei:publicationStmt
            let $bibl := $doc/tei:TEI/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:bibl
            return (
                update value $doc/tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title with $title,
                update insert <tei:idno type="TBRC_TEXT_RID">{$textRid}</tei:idno> into $pubStmt,
                update insert <tei:idno type="page_equals_image">page_equals_image</tei:idno> into $pubStmt,
                update insert <tei:idno type="SRC_PATH">{$textPath}</tei:idno> into $bibl,
                <text>{ $stored,  $title }</text>
                )
        } catch * { <failed>Processing {$fullPath} got error {$err:code}: {$err:description}. Data: {$err:value}</failed> }
};

declare function q:import-volume($base as xs:string?, $xmlPath as xs:string?, $volNm as xs:string?, $vColl as xs:string?, $work as element()?)
as element()*
{
    let $volPath := concat($xmlPath, "/", $volNm)
    let $fullPath := concat($base, "/", $volPath)
    for $text in f:list($fullPath)//f:file[@hidden="false"][matches(@name, ".+\.xml")]
    return
        q:import-text($base, $volPath, $text/@name, $vColl, $work)
};

declare function q:import-work($base as xs:string?, $source as xs:string?, $wRid as xs:string?, $wColl as xs:string?, $work as element()?)
as element()*
{
    let $xmlPath := concat($source, "/", $wRid, "/xml")
    let $fullPath := concat($base, "/", $xmlPath)
    for $vol in f:list($fullPath)//f:directory[@hidden="false"]
    let $volNm := string($vol/@name)
    let $utNm := replace($volNm, "^W", "UT")
    let $vColl :=  x:create-collection($wColl, $utNm)
    return
        q:import-volume($base, $xmlPath, $volNm, $vColl, $work)
};

declare function q:import-source($base as xs:string?, $source as xs:string?, $destCollNm as xs:string?)
as element()*
{
    let $sourcePath := concat($base, "/", $source)
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
q:import-source("/Users/chris/Desktop/TBRC/ETEXTS_PROCESSING", "Namsel_OCR/Batch-20150713b", "UCB-OCR")
}</imported>
