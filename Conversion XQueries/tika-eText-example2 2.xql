xquery version "1.0";

import module namespace cx="http://exist-db.org/xquery/contentextraction"
at "java:org.exist.contentextraction.xquery.ContentExtractionModule";

declare namespace u="http://exist-db.org/xquery/util";
declare namespace f="http://exist-db.org/xquery/file";
declare namespace x="http://exist-db.org/xquery/xmldb";
declare namespace html="http://www.w3.org/1999/xhtml";

let $collNm := "eTexts"
let $cPath := x:create-collection("/db", $collNm)
let $cUri := "/db/eTexts/"

let $docPath := "/Users/chris/Desktop/lcw-01-03.doc"
let $rtfPath := "/Users/chris/Desktop/lcw-01-03-word-libre-udp.rtf"
let $docNm := "lcw-01-03.xml"
let $rtfMime := "application/rtf"
let $docMime := "application/msword"
let $rtfFile := f:read-binary($rtfPath)
let $docFile := f:read-binary($docPath)
let $metaData := cx:get-metadata($docFile)
let $uniData := cx:get-metadata-and-content($rtfFile)
let $doc := <doc>{$metaData//html:head, $uniData//html:body}</doc>
let $stored := x:store($cUri, $docNm, $doc)
return
    $stored
