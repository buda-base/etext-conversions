xquery version "3.0";

import module namespace kwic='http://exist-db.org/xquery/kwic';

declare namespace q="http://tbrc.org/exist/xquery";
declare namespace o="http://www.tbrc.org/models/outline#";
declare namespace w="http://www.tbrc.org/models/work#";
declare namespace tei="http://www.tei-c.org/ns/1.0";

declare variable $q:etext-path { ".*eTextsChunked.*" };
declare variable $q:etexts { "/db/eTextsChunked" };

<sources>{
let $allVols := collection("/db/eTextsChunked/")//tei:body
let $allPages := collection("/db/eTextsChunked/")//tei:p
let $allWorks :=
    let $sources := xmldb:get-child-collections($q:etexts)
    for $s in $sources
    return
        xmldb:get-child-collections($q:etexts || "/" || $s)
let $rs :=
    let $sources := xmldb:get-child-collections($q:etexts)
    for $s in $sources
    let $ws := xmldb:get-child-collections($q:etexts || "/" || $s)
    let $vs := 
        for $w in $ws
        return
            xmldb:get-child-collections($q:etexts || "/" || $s || "/" || $w)
    let $ps := collection($q:etexts || "/" || $s)//tei:p
    order by $s
    return
        <r>{ $s, count($ws), "works   ", count($vs), "volumes   ",  count($ps), "pages"}</r>
let $summary :=
    <summary>{ "Summary: ", count($allWorks), "works   ", count($allVols), "volumes   ",  count($allPages), "pages"}</summary>
return
    ($summary, $rs)
}</sources>
