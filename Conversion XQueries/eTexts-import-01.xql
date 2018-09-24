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

declare function q:add-title($ps as element()*)
as xs:string*
{
    if ($ps) then
        let $p := $ps[1]
        let $s1 := string($p)
        let $s2 := fx:left-trim(translate($s1, '/&amp;ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz', ''))
        let $s := normalize-space($s2)
        let $comp := compare("&#x0F00;", $s)
        return
            if ($comp = -1 and string-length($s) gt 12) then
                substring($s, 1, 128)
            else
                q:add-title(subsequence($ps, 2))
    else
        "no title"
};

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


declare function q:import-text($volPath as xs:string?, $textNm as xs:string?, $vColl as xs:string?)
as element()*
{
    let $textPath := concat($volPath, "/", $textNm, ".rtf")
    let $textFile := f:read-binary($textPath)
    let $tikaDoc := cx:get-metadata-and-content($textFile)
    let $tikaStr := fn:serialize($tikaDoc)
    let $head := substring-before($tikaStr, "<body>")
    let $body1 := substring-after($tikaStr, "</head>")
    let $body2 := fx:replace-multi($body1, ("&amp;#160;", "«", "»", "<b>", "</b>", "<b/>", "&amp;gt;"), (" ", "<span class='yigChung'>", "</span>", "", "", "", ""))
    let $body3 := fx:left-trim(translate($body2, '0123456789"$)#*%$@!¿¡(_-,]', ''))
    let $body4 := q:add-numbers($body3)    
    let $newStr1 := concat($head, $body4)
    let $newDoc1 := try{ u:parse($newStr1) } catch * { () }
    let $newStr2 :=
        if ($newDoc1) then
            $newStr1
        else
            let $s1 := replace($newStr1, "<span class='yigChung'>([\p{IsTibetan}| ]*?)</p>", "<span class='yigChung'>$1</span></p>")
            return
                replace($s1, "<p>([\p{IsTibetan}| ]*?)</span>", "<p><span class='yigChung'>$1</span>")
    let $newDoc2 := if ($newDoc1) then $newDoc1 else try{ u:parse($newStr2) } catch * { () }
    let $newStr3 :=
        if ($newDoc2) then
            $newStr2
        else
            let $s1 := fx:replace-multi($body1, ("&amp;#160;", "«", "»", "<b>", "</b>", "<b/>", "&amp;gt;"), (" ", "", "", "", "", "", ""))
            let $s2 :=  fx:left-trim(translate($s1, '0123456789"$)#*%$@!(_', ''))
            let $s3 := q:add-numbers($s2)
            return
                concat($head, $s3)
    let $newDoc := if ($newDoc2) then $newDoc2 else try{ u:parse($newStr3) } catch * { () }
    let $docNm := concat($textNm, ".html")
    return
        if ($newDoc) then
            let $stored := x:store($vColl, $docNm, $newDoc)
            let $fullName := concat($vColl, "/", $docNm)
            let $doc := doc($stored)
            let $title := q:add-title($doc/html/body/p)
            let $junk := update value $doc/html/head/title with $title
            return
               <text>{ $stored,  $title }</text>
        else
            <failed>### COULD NOT PARSE: { $textPath, $newStr3 }</failed>
};

declare function q:import-volume($rtfsPath as xs:string?, $volNm as xs:string?, $vColl as xs:string?)
as element()*
{
    let $volPath := concat($rtfsPath, "/", $volNm)
    for $text in f:list($volPath)//f:file[@hidden="false"]
    let $textNm := fx:substring-before-last(string($text/@name), ".")
    return
        q:import-text($volPath, $textNm, $vColl)
};

declare function q:import-work($sourcePath as xs:string?, $workNm as xs:string?, $wColl as xs:string?)
as element()*
{
    let $rtfsPath := concat($sourcePath, "/", $workNm, "/rtfs")
    for $vol in f:list($rtfsPath)//f:directory[@hidden="false"]
    let $volNm := string($vol/@name)
    let $vColl :=  x:create-collection($wColl, $volNm)
    return
        q:import-volume($rtfsPath, $volNm, $vColl)
};

declare function q:import-source($sourcePath as xs:string?)
as element()*
{
    let $sourceNm := tokenize($sourcePath, "/")[last()]
    let $sColl := x:create-collection($cUri, $sourceNm)
    for $work in f:list($sourcePath)//f:directory[@hidden="false"]
    let $workNm := string($work/@name)
    let $wColl :=  x:create-collection($sColl, $workNm)
    return
        q:import-work($sourcePath, $workNm, $wColl)
};

<imported>{
q:import-source("/Users/chris/Desktop/TBRC/eTexts-Processing/FINAL/Shechen")
}</imported>
