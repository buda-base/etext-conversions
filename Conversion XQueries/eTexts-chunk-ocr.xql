xquery version "3.0";

declare namespace q="http://tbrc.org/exist/xquery";
declare namespace x="http://exist-db.org/xquery/xmldb";
declare namespace tei="http://www.tei-c.org/ns/1.0";

declare variable $q:inPath { "/db/eTexts" };
declare variable $q:outPath { "/db/eTextsChunked" };

declare option exist:timeout "14400000";

declare function q:chunkOcr($doc as element()?)
    as element()*
{
    let $xslt := 
        <xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
            xmlns:tei="http://www.tei-c.org/ns/1.0" version="2.0">
            <!-- delete the line markers
            <xsl:template match="tei:milestone[@unit='line']"/> -->
            <!-- expand the page milestones to p elements containing the content between page milestones -->
            <xsl:template match="tei:div">
                <tei:div>
                    <xsl:for-each-group select="node()" group-starting-with="tei:milestone[@unit='page']">
                        <tei:p>
                            <xsl:sequence select="current()/@*"/>
                            <xsl:apply-templates select="current-group()[not(self::tei:milestone)]"/>
                        </tei:p>
                    </xsl:for-each-group>
                </tei:div>
            </xsl:template>
            <!-- copy everything else -->
            <xsl:template match="@*|node()">
                <xsl:copy>
                    <xsl:apply-templates select="@*|node()"/>
                </xsl:copy>
            </xsl:template>
        </xsl:stylesheet>
    let $ign := util:log("INFO", "chunkOcr transforming doc: " || util:document-name($doc))
    return 
        transform:transform($doc, $xslt, ())
};

declare function q:processOcr($collNm as xs:string?)
as element()*
{
    let $destColl := x:create-collection($q:outPath, $collNm)
    for $utNm in xmldb:get-child-collections($q:inPath || "/" || $collNm)
    let $utColl :=  x:create-collection($destColl, $utNm)
    for $volNm in xmldb:get-child-collections($q:inPath || "/" || $collNm || "/" || $utNm)
    let $volColl := x:create-collection($utColl, $volNm)
    for $inDoc in collection($q:inPath || "/" || $collNm || "/" || $utNm || "/" || $volNm)/tei:TEI
    let $outDoc := q:chunkOcr($inDoc)
    let $outPath := $q:outPath || "/" || $collNm || "/" || $utNm || "/" || $volNm
    let $rez := x:store($outPath, util:document-name($inDoc), $outDoc)
    return
        ()
};

let $rez := q:processOcr("UCB-OCR")
return
    "done"
