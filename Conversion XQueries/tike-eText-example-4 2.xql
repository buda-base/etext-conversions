xquery version "1.0";

import module namespace cx="http://exist-db.org/xquery/contentextraction"
at "java:org.exist.contentextraction.xquery.ContentExtractionModule";

import module namespace fx="http://www.functx.com"
at "/db/modules/functx-1.0.xqm";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace u="http://exist-db.org/xquery/util";
declare namespace f="http://exist-db.org/xquery/file";
declare namespace x="http://exist-db.org/xquery/xmldb";
declare namespace html="http://www.w3.org/1999/xhtml";

let $collNm := "eTexts"
let $cPath := x:create-collection("/db", $collNm)
let $cUri := "/db/eTexts/"

let $docPath := "/Users/chris/Desktop/TBRC/eTexts-Processing/FINAL/KarmaDelek/klong-chen-rab-byams-gung-'bum/sources/volume_001/volume_001_018.doc"
let $rtfPath := "/Users/chris/Desktop/TBRC/eTexts-Processing/FINAL/KarmaDelek/klong-chen-rab-byams-gung-'bum/rtfs/volume_001/volume_001_018.rtf"
let $docNm := "volume_001_018.html"
let $rtfFile := f:read-binary($rtfPath)
let $docFile := f:read-binary($docPath)
let $metaData := cx:get-metadata($docFile)
let $uniData := cx:get-metadata-and-content($rtfFile)
let $doc := <doc>{$metaData//html:head, $uniData//html:body}</doc>
let $docStr := fn:serialize($doc)
let $newStr := fx:replace-multi($docStr, ("«", "»", "<p>", "</p>"), ("<note/>", "<text/>", "<milestone unit='part'/>", ""))
let $stored := x:store($cUri, $docNm, $doc)
return
   $newStr
