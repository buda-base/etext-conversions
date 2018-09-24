xquery version "3.0";

import module namespace cx="http://exist-db.org/xquery/contentextraction"
at "java:org.exist.contentextraction.xquery.ContentExtractionModule";

import module namespace fx="http://www.functx.com"
at "/db/modules/functx-1.0.xqm";

declare namespace q="http://exist-db.org/xquery/local";

declare default element namespace "http://www.w3.org/1999/xhtml";
declare namespace html="http://www.w3.org/1999/xhtml";

declare namespace u="http://exist-db.org/xquery/util";
declare namespace f="http://exist-db.org/xquery/file";
declare namespace x="http://exist-db.org/xquery/xmldb";

declare option exist:timeout "7200000";

declare variable $collNm := "eTextsIncoming";
declare variable $cUri := "/db/eTextsIncoming/";

declare function q:add-numbers($str as xs:string?)
as xs:string
{
    let $ins := tokenize($str, "<p>")
    let $last := $ins[count(.)]
    let $rest := subsequence($ins, 1, count($ins)-1)
    let $outs :=
        for $p at $pos in $rest return concat($p, "<p><a id='", $pos, "'/>")
    return
        string-join(($outs, $last), '')
};

let $filePath := "/Users/chris/Desktop/TBRC/eTexts-Processing/FINAL/DharmaDownload/Karmapa-07/rtfs/Rigzhung-Jamtso/T0058_RJ_2.rtf"
let $file := f:read-binary($filePath)
let $doc := cx:get-metadata-and-content($file)
let $str := fn:serialize($doc)
let $new := q:add-numbers($str)
return
    $new
