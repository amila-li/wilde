xquery version "3.0";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace xhtml='http://www.w3.org/1999/xhtml';
declare namespace export="http://dhil.lib.sfu.ca/exist/wilde-app/export";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace json="http://www.json.org";

import module namespace config="http://dhil.lib.sfu.ca/exist/wilde-app/config" at "config.xqm";
import module namespace kwic="http://exist-db.org/xquery/kwic";
import module namespace collection="http://dhil.lib.sfu.ca/exist/wilde-app/collection" at "collection.xql";
import module namespace document="http://dhil.lib.sfu.ca/exist/wilde-app/document" at "document.xql";
import module namespace lang="http://dhil.lib.sfu.ca/exist/wilde-app/lang" at "lang.xql";

declare option output:method "text";
declare option output:media-type "text/csv";

declare function export:search() {
    let $query := request:get-parameter('query', '')
    let $page := request:get-parameter('p', 1)
    let $hits := collection:search($query)

    let $headers := (
      <row>
          <item>ID</item>
          <item>Title</item>
          <item>Result</item>
        </row>,
        <row>
          <item>Found {count($hits)} results for search query {$query}.</item>
        </row>
    )

    let $body := for $hit in $hits
        let $did := document:id($hit)
        let $title := document:title($hit)
        let $config := <config xmlns='' width="60" table="no" />
        let $kwic := kwic:summarize($hit, $config)
        for $node in $kwic
            return
                <row>
                    <item>{$did}</item>
                    <item>{$title}</item>
                    <item>{$node//text()}</item>
                </row>

    return ($headers, $body)
};

declare function export:volume() {
    let $headers :=
        <row>
            <item>Id</item>
            <item>Date</item>
            <item>Word count</item>
            <item>Document matches</item>
            <item>Paragraph matches</item>
            <item>Newspaper Title</item>
            <item>Region</item>
            <item>City</item>
            <item>Language</item>
        </row>

    let $body := for $document in collection:documents()
    return
        <row>
            <item>{document:id($document)}</item>
            <item>{document:date($document)}</item>
            <item>{document:word-count($document)}</item>
            <item>{count(document:document-matches($document, 'lev'))}</item>
            <item>{count(document:paragraph-matches($document, 'lev'))}</item>
            <item>{document:publisher($document)}</item>
            <item>{document:region($document)}</item>
            <item>{document:city($document)}</item>
            <item>{document:language($document)}</item>
        </row>

    return ($headers, $body)
};

declare function export:matching-paragraphs() {
    let $headers :=
        <row>
            <item>Source Id</item>
            <item>Source date</item>
            <item>Source paper</item>
            <item>Source region</item>
            <item>Source city</item>
            <item>Source language</item>
            <item>Target Id</item>
            <item>Target date</item>
            <item>Target paper</item>
            <item>Target region</item>
            <item>Target city</item>
            <item>Target language</item>
            <item>Match</item>
        </row>

    let $documents := collection:documents()
    let $body :=
        for $link in $documents//xhtml:a[contains(@class, 'similarity')]
        let $target := collection:fetch($link/@data-document/string())
        order by document:date($link), document:date($target), $link/@data-similarity descending
        return
            if((document:date($link) = document:date($target)) and (document:id($link) gt document:id($target))) then ()
            else if(document:date($link) gt document:date($target)) then ()
            else
        <row>
            <item>{document:id($link)}</item>
            <item>{document:date($link)}</item>
            <item>{document:publisher($link)}</item>
            <item>{document:region($link)}</item>
            <item>{document:city($link)}</item>
            <item>{document:language($link)}</item>
            <item>{document:id($target)}</item>
            <item>{document:date($target)}</item>
            <item>{document:publisher($target)}</item>
            <item>{document:region($target)}</item>
            <item>{document:city($target)}</item>
            <item>{document:language($target)}</item>
            <item>{$link/@data-similarity/string()}</item>
        </row>

    return ($headers, $body)
};

declare function export:matching() {
    let $headers :=
        <row>
            <item>Report Id</item>
            <item>Report date</item>
            <item>Report paper</item>
            <item>Report region</item>
            <item>Report city</item>
            <item>Match Id</item>
            <item>Match date</item>
            <item>Match paper</item>
            <item>Match region</item>
            <item>Match city</item>
            <item>Match similarity</item>
        </row>

    let $documents := collection:documents()
    let $body :=
        for $link in $documents//xhtml:link[@rel='similarity']
        let $target := collection:fetch($link/@href/string())
        order by document:date($link), document:date($target), $link/@data-similarity descending
        return
        <row>
            <item>{document:id($link)}</item>
            <item>{document:date($link)}</item>
            <item>{document:publisher($link)}</item>
            <item>{document:region($link)}</item>
            <item>{document:city($link)}</item>
            <item>{document:id($target)}</item>
            <item>{document:date($target)}</item>
            <item>{document:publisher($target)}</item>
            <item>{document:region($target)}</item>
            <item>{document:city($target)}</item>
            <item>{$link/@data-similarity/string()}</item>
        </row>

    return ($headers, $body)
};

declare function export:signatures() {
    let $headers :=
        <row>
            <item>Id</item>
            <item>Date</item>
            <item>Newspaper Title</item>
            <item>Country</item>
            <item>City</item>
            <item>Language</item>
            <item>Signature</item>
        </row>

    let $documents := collection:documents()
    let $paragraphs := $documents//xhtml:div[@id='original']//xhtml:p[@class='signature']
    let $body :=
        for $p in $paragraphs
        return
        <row>
            <item>{document:id($p)}</item>
            <item>{document:date($p)}</item>
            <item>{document:publisher($p)}</item>
            <item>{document:region($p)}</item>
            <item>{document:city($p)}</item>
            <item>{document:language($p)}</item>
            <item>{$p/text()}</item>
        </row>

    return ($headers, $body)
};

declare function export:bibliography() {
    let $headers :=
        <row>
            <item>Id</item>
            <item>Date</item>
            <item>Newspaper Title</item>
            <item>Country</item>
            <item>City</item>
            <item>Language</item>
        </row>

    let $documents := collection:documents()
    let $body :=
        for $doc in $documents
        return
        <row>
            <item>{document:id($doc)}</item>
            <item>{document:date($doc)}</item>
            <item>{document:publisher($doc)}</item>
            <item>{document:region($doc)}</item>
            <item>{document:city($doc)}</item>
            <item>{document:language($doc)}</item>
            <item>{$doc/text()}</item>
        </row>

    return ($headers, $body)
};

declare function local:paper-id($doc as node()) as xs:string {
    let $path := document:path($doc)
    let $parts := tokenize($path || ' ' || document:publisher($doc), '[^a-zA-Z]+')
    let $paper-id := string-join(for $part in $parts return substring($part, 1, 1), '')
    return $paper-id
};

declare function export:gephi-documents() {
    let $headers := 
        <row>
            <item>ID</item>
            <item>Label</item>
            <item>Language</item>
            <item>Region</item>
            <item>City</item>
        </row>
        
    let $documents := collection:documents()
    let $body := 
        for $doc in $documents
        where count(document:document-matches($doc)) > 0
        return
            <row>
                <item>{document:id($doc)}</item>
                <item>{document:title($doc)}</item>  
                <item>{lang:code2lang(document:language($doc))}</item>
                <item>{document:region($doc)}</item>
                <item>{document:city($doc)}</item>
            </row>
            
    return ($headers, $body)
};

declare function export:gephi-document-matches() {
    let $headers := 
        <row>
            <item>Source</item>
            <item>Target</item>
            <item>Type</item>
            <item>Weight</item>
        </row>
        
    let $documents := collection:documents()
    let $body := 
        for $doc in $documents
        where count(document:document-matches($doc)) > 0
        for $link in document:document-matches($doc)
            return
                <row>
                    <item>{document:id($doc)}</item>
                    <item>{$link/@href/string()}</item>  
                    <item>Undirected</item>
                    <item>{$link/@data-similarity/string()}</item>
                </row>
            
    return ($headers, $body)
};

declare function export:gephi-papers() {
  let $headers := 
    <row>
        <item>ID</item>
        <item>Label</item>
        <item>Language</item>
        <item>Region</item>
        <item>City</item>
    </row>

    let $paperIds := distinct-values(collection:collection()//meta[@name='dc.publisher.id']/@content/string())
    let $body := 
        for $id in $paperIds
        let $doc := collection:documents('dc.publisher.id', $id)[1]
        return
            <row>
                <item>{$id}</item>
                <item>{document:publisher($doc)}</item>
                <item>{lang:code2lang(document:language($doc))}</item>
                <item>{document:region($doc)}</item>
                <item>{document:city($doc)}</item>
            </row>

    return ($headers,$body)
};

declare function local:count-matches($source, $target) {
    let $sourceDocs := collection:collection()//html[.//meta[@name='dc.publisher.id' and @content=$source]]
    let $matches :=
        for $doc in $sourceDocs
        where $doc//link[@data-paper-id = $target]
        return 1
    return count($matches)
};

declare function export:gephi-papers-matches() {
    let $headers := 
        <row>
            <item>Source</item>
            <item>Target</item>
            <item>Type</item>
            <item>Weight</item>
        </row>

    let $paperIds := distinct-values(collection:collection()//meta[@name='dc.publisher.id']/@content/string())

    let $body := 
        for $source at $sp in $paperIds
            let $sourceReports := collection:documents('dc.publisher.id', $source)
            for $target at $tp in $paperIds
                where $tp lt $sp
                let $count := count($sourceReports[.//link[@data-paper-id=$target]])
                return if ($count gt 0) then
                    <row>
                        <item>{$source}</item>
                        <item>{$target}</item>
                        <item>Undirected</item>
                        <item>{$count}</item>
                    </row>
                else ()
    
    return ($headers, $body)    
};

declare function local:quote($str) {
  '"' || $str || '"'
};

declare function local:rows2csv($rows) {
    for $row in $rows
      let $items := for $item in $row/item
        return local:quote(normalize-space($item/text()))
      return string-join($items, ',') || codepoints-to-string(10)
};

let $request := request:get-attribute('function')
let $functionName :=
    if(ends-with($request, '.csv')) then 
        substring-before($request, '.csv')
    else 
        $request
let $function :=
    try {
        function-lookup(QName("http://dhil.lib.sfu.ca/exist/wilde-app/export", $functionName), 0)
    } catch * {
        ()
    }

return
if(exists($function)) then
    let $rows := $function()
    return local:rows2csv($rows)
else
    let $null := response:set-status-code(404)
    return "The export function " || $functionName || " cannot be found."
