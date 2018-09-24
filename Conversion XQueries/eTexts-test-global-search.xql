xquery version "3.0";


import module namespace wu="http://tbrc.org/xquery/ewts2unicode" 
at "java:org.tbrc.xquery.extensions.EwtsToUniModule";

import module namespace gs="http://tbrc.org/exist/xquery/global-search" 
at "xmldb:exist:///db/modules/gwt/global-search.xqm";

import module namespace kwic='http://exist-db.org/xquery/kwic';

declare namespace q="http://exist-db.org/xquery/local";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace w="http://www.tbrc.org/models/work#";

declare variable $q:etext-path { "/db/eTextsChunked" };
declare variable $q:etext-match-path { ".*eTextsChunked.*" };
declare variable $q:config { <config width="100"/> };

let $limit := "1000"
let $q := "'das log"
let $qw :=  '"' || $q || '"'
let $qu := '"' || wu:toUnicode($q) || '"'
(: let $hits := collection($q:etext-path)//tei:p[ft:query(., $qu)]
let $rezs := gs:etexts-resultset($hits, $limit)
let $sRezs := gs:etexts-search($qu, $limit) :)
(: let $utx := gs:utx($limit)) :)
let $t1 := util:system-time()
let $works := gs:utx-helper()
let $t2 := util:system-time()
let $exacts := gs:utx-exact-paths()
let $t3 := util:system-time()
let $exacting :=
    for $w in $works return gs:utx-exact($w, $exacts)
let $t4 :=  util:system-time()
let $rezults := gs:utx($limit)
let $t5 :=  util:system-time()
return
    <r>{
        (count($works), $t2 - $t1, count($exacts), $t3 - $t2, count($exacting), $t4 - $t3, count($rezults/result), $t5 - $t4, $rezults/result[4])
   }</r>
