xquery version "3.0";

import module namespace wu="http://tbrc.org/xquery/ewts2unicode" 
at "java:org.tbrc.xquery.extensions.EwtsToUniModule";

import module namespace gs="http://tbrc.org/exist/xquery/global-search" 
at "xmldb:exist:///db/modules/gwt/global-search.xqm";

declare namespace q="http://exist-db.org/xquery/local";
declare namespace tei="http://www.tei-c.org/ns/1.0";

declare variable $q:etext-path { "/db/eTextsChunked" };
declare variable $q:etext-match-path { ".*eTextsChunked.*" };

let $path := "/db/eTextsChunked/Shechen/UT1KG14/UT1KG14-052/UT1KG14-052-0014.xml"
let $target :=
    if (ends-with($path, ".xml")) then
        doc($path)
    else 
        collection($path)
let $q := "'das log"
let $qw :=  '"' || $q || '"'
let $qu := '"' || wu:toUnicode($q) || '"'
let $etexts := $target//tei:p[ft:query(., $qu)]
let $n := 1
return
    (count($target), count($target//tei:p),
    count($etexts), 
    util:document-name($etexts[$n]), $etexts[$n])
