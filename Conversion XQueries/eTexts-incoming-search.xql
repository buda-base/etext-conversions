xquery version "1.0";

import module namespace ut="http://tbrc.org/xquery/ewts2unicode" 
at "java:org.tbrc.xquery.extensions.EwtsToUniModule";

import module namespace kwic='http://exist-db.org/xquery/kwic';

declare namespace u="http://exist-db.org/xquery/util";

declare namespace q="http://www.tbrc.org/xquery/query#";
declare namespace g="http://www.tbrc.org/models/place#";
declare namespace html="http://www.w3.org/1999/xhtml";

declare namespace request="http://exist-db.org/xquery/request";

declare option exist:serialize "method=xhtml media-type=text/html indent=yes omit-xml-declaration=yes";

declare variable $collNm := "eTextsIncoming";
declare variable $cUri := "/db/eTextsIncoming/";

let $qStr := request:get-parameter("str", "")
let $qu := concat('"', ut:toUnicode($qStr), '"')
let $logit := u:log("INFO", $qu)
let $rezs := collection($cUri)//html:body[ft:query(., $qu)]
let $body :=
    (
    <h4>Found matches in {count($rezs)} documents for: {$qu}</h4>,
    for $rez in $rezs
    let $kwic := kwic:summarize($rez, <config width="150"/>)
    let $cPath := u:collection-name($rez)
    let $dName := u:document-name($rez)
    return
        <div>{<h4>{$dName}</h4>, <h5>{$cPath}</h5>, $kwic}</div>
    )
return
<html>
<head>
    <title>Search Incoming eTexts for: {$qu}</title>
    <style type="text/css">
        .hi {{ color:blue }}
    </style>
</head>
<body>{ $body }</body>
</html>
