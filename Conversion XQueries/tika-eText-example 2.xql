xquery version "1.0";

import module namespace cx="http://exist-db.org/xquery/contentextraction"
at "java:org.exist.contentextraction.xquery.ContentExtractionModule";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace u="http://exist-db.org/xquery/util";
declare namespace f="http://exist-db.org/xquery/file";
declare namespace x="http://exist-db.org/xquery/xmldb";

let $collNm := "eTexts"
let $cPath := x:create-collection("/db", $collNm)
let $cUri := "/db/eTexts/"

let $docPath := "/Users/chris/Desktop/lcw-01-02.doc"
let $rtfPath := "/Users/chris/Desktop/lcw-01-02-word-libre-udp.rtf"
let $rtfNm := "lcw-01-02-word-libre-udp.rtf"
let $docNm := "lcw-01-02.doc"
let $rtfMime := "application/rtf"
let $docMime := "application/msword"
let $rtfFile := f:read-binary($rtfPath)
let $docFile := f:read-binary($docPath)
let $storeRtf := x:store($cUri, $rtfNm, $rtfFile, $rtfMime)
let $storeDoc := x:store($cUri, $docNm, $docFile, $docMime)
let $docDoc := u:binary-doc(concat($cUri, $docNm))
let $metaData := cx:get-metadata($docDoc)
let $rtfDoc := u:binary-doc(concat($cUri, $rtfNm))
let $uniData := cx:get-metadata-and-content($rtfDoc)
return
    ($metaData, $uniData)
