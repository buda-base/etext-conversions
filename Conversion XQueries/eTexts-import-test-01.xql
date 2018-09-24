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

declare variable $collNm := "eTextsIncoming";
declare variable $cUri := "/db/eTextsIncoming/";

declare function q:guess-title($ps as element()*)
as xs:string*
{
    if ($ps) then
        let $p := $ps[1]
        let $s1 := string($p)
        let $s := fx:left-trim(translate($s1, '0123456789"$)#>*%$@!(&amp;_ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz', ''))
        let $comp := compare("&#x0F00;", $s)
        return
            if ($comp = -1 and string-length($s) gt 7) then
                normalize-space(substring($s, 1, 128))
            else
                q:guess-title(subsequence($ps, 2))
    else
        "no title"
};

declare function q:import-text($volPath as xs:string?, $textNm as xs:string?, $vColl as xs:string?)
as element()*
{
    let $textPath := concat($volPath, "/", $textNm, ".rtf")
    let $textFile := f:read-binary($textPath)
    let $tikaDoc := cx:get-metadata-and-content($textFile)
    let $docStr := fn:serialize($tikaDoc)
    let $newStr1 := fx:replace-multi($docStr, ( "&amp;#160;", "«", "»"), (" ", "<div class='yigChung'>", "</div>"))
    let $newDoc1 := try{ u:parse($newStr1) } catch * { () }
    let $newStr2 :=
        if ($newDoc1) then
            ""
        else
            replace($newStr1, "<div class='yigChung'>(.*?)</p>", "<div class='yigChung'>$1</div></p>")
    let $newDoc :=
        if ($newDoc1) then
            $newDoc1
        else
            try{ u:parse($newStr2) } catch * { () }
    let $docNm := concat($textNm, ".html")
    return
        if ($newDoc) then
            let $stored := x:store($vColl, $docNm, $newDoc)
            let $fullName := concat($vColl, "/", $docNm)
            let $doc := doc($stored)
            let $title := q:guess-title($doc/html/body/p)
            let $junk := update value $doc/html/head/title with $title
            return
               <text>{ $stored,  $title }</text>
        else
            <failed>### COULD NOT PARSE: { $textPath }</failed>
};

<r>{
    q:import-text("/Users/chris/Desktop/TBRC/eTexts-Processing/FINAL/DharmaDownload/gdams-ngag-mdzod/rtfs/01_gdams-ngag-mdzod_ka", "01_04_ma-mo-gsang-ba-las-kyi-thig-le", "/db/eTextsIncoming/DharmaDownload/gdams-ngag-mdzod/01_gdams-ngag-mdzod_ka")
}</r>
