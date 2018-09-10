module Main exposing (suite)

import Dict
import Expect exposing (Expectation)
import Html.Parser exposing (Node(..))
import Test exposing (Test, describe, test)


testParseAll : String -> List Node -> (() -> Expectation)
testParseAll s astList =
    \_ ->
        Expect.equal (Ok astList) (Html.Parser.run s)


testParse : String -> Node -> (() -> Expectation)
testParse s ast =
    testParseAll s [ ast ]


testError : String -> (() -> Expectation)
testError s =
    \_ ->
        let
            failed =
                case Html.Parser.run s of
                    Ok _ ->
                        False

                    Err _ ->
                        True
        in
        Expect.true s failed


textNodeTests : Test
textNodeTests =
    describe "TextNode"
        [ test "basic1" (testParse "1" (Text "1"))
        , test "basic2" (testParse "a" (Text "a"))
        , test "basic3" (testParse "1a" (Text "1a"))
        , test "basic4" (testParse "^" (Text "^"))
        , test "decode1" (testParse "&" (Text "&"))
        , test "decode2" (testParse "&amp;" (Text "&"))
        , test "decode3" (testParse "&lt;" (Text "<"))
        , test "decode4" (testParse "&gt;" (Text ">"))
        , test "decode5" (testParse "&nbsp;" (Text " "))
        , test "decode6" (testParse "&apos;" (Text "'"))
        , test "decode7" (testParse "&#38;" (Text "&"))
        , test "decode8" (testParse "&#x26;" (Text "&"))
        , test "decode9" (testParse "&#x3E;" (Text ">"))
        , test "decodeA" (testParse "&#383;" (Text "ſ"))
        , test "decodeB" (testParse "&nbsp;" (Text " "))
        , test "decodeC" (testParse "&nbsp;&nbsp;" (Text "  "))
        , test "decodeD" (testParse "a&nbsp;b" (Text "a b"))
        , test "decodeE" (testParse "a&nbsp;&nbsp;b" (Text "a  b"))
        , test "decodeF" (testParse """<img alt="&lt;">""" (Element "img" [ ( "alt", "<" ) ] []))
        ]


nodeTests : Test
nodeTests =
    describe "Node"
        [ test "basic1" (testParse "<a></a>" (Element "a" [] []))
        , test "basic2" (testParse "<a></a >" (Element "a" [] []))
        , test "basic3" (testParse "<A></A >" (Element "a" [] []))
        , test "basic4" (testParseAll " <a></a> " [ Text " ", Element "a" [] [], Text " " ])
        , test "basic5" (testParseAll "a<a></a>b" [ Text "a", Element "a" [] [], Text "b" ])
        , test "basic6" (testParse "<A></A>" (Element "a" [] []))
        , test "basic7" (testParse "<a>a</a>" (Element "a" [] [ Text "a" ]))
        , test "basic8" (testParse "<a> a </a>" (Element "a" [] [ Text " a " ]))
        , test "basic10" (testParse "<br>" (Element "br" [] []))
        , test "basic11" (testParse "<a><a></a></a>" (Element "a" [] [ Element "a" [] [] ]))
        , test "basic12" (testParse "<a> <a> </a> </a>" (Element "a" [] [ Text " ", Element "a" [] [ Text " " ], Text " " ]))
        , test "basic13" (testParse "<a> <br> </a>" (Element "a" [] [ Text " ", Element "br" [] [], Text " " ]))
        , test "basic14" (testParse "<a><a></a><a></a></a>" (Element "a" [] [ Element "a" [] [], Element "a" [] [] ]))
        , test "basic15" (testParse "<a><a><a></a></a></a>" (Element "a" [] [ Element "a" [] [ Element "a" [] [] ] ]))
        , test "basic16" (testParse "<a><a></a><b></b></a>" (Element "a" [] [ Element "a" [] [], Element "b" [] [] ]))
        , test "basic17" (testParse "<h1></h1>" (Element "h1" [] []))
        , test "start-only-tag1" (testParse "<br>" (Element "br" [] []))
        , test "start-only-tag2" (testParse "<BR>" (Element "br" [] []))
        , test "start-only-tag3" (testParse "<br >" (Element "br" [] []))
        , test "start-only-tag4" (testParse "<BR >" (Element "br" [] []))
        , test "start-only-tag5" (testParse "<a> <br> </a>" (Element "a" [] [ Text " ", Element "br" [] [], Text " " ]))
        , test "start-only-tag6" (testParse "<a><br><br></a>" (Element "a" [] [ Element "br" [] [], Element "br" [] [] ]))
        , test "start-only-tag7" (testParse "<a><br><img><hr><meta></a>" (Element "a" [] [ Element "br" [] [], Element "img" [] [], Element "hr" [] [], Element "meta" [] [] ]))
        , test "start-only-tag8" (testParse "<a>foo<br>bar</a>" (Element "a" [] [ Text "foo", Element "br" [] [], Text "bar" ]))
        ]


scriptTests : Test
scriptTests =
    describe "Script"
        [ test "script1" (testParse """<script></script>""" (Element "script" [] []))
        , test "script2" (testParse """<SCRIPT></SCRIPT>""" (Element "script" [] []))
        , test "script3" (testParse """<script src="script.js">foo</script>""" (Element "script" [ ( "src", "script.js" ) ] [ Text "foo" ]))
        , test "script4" (testParse """<script>var a = 0 < 1; b = 1 > 0;</script>""" (Element "script" [] [ Text "var a = 0 < 1; b = 1 > 0;" ]))
        , test "script5" (testParse """<script><!----></script>""" (Element "script" [] [ Comment "" ]))
        , test "script6" (testParse """<script>a<!--</script><script>-->b</script>""" (Element "script" [] [ Text "a", Comment "</script><script>", Text "b" ]))
        , test "style" (testParse """<style>a<!--</style><style>-->b</style>""" (Element "style" [] [ Text "a", Comment "</style><style>", Text "b" ]))
        ]


commentTests : Test
commentTests =
    describe "Comment"
        [ test "basic1" (testParse """<!---->""" (Comment ""))

        --, test "basic" (testParse """<!--foo\t\x0D
        -->""" (Comment "foo\t\x0D\n "))
        , test "basic2" (testParse """<!--<div></div>-->""" (Comment "<div></div>"))
        , test "basic3" (testParse """<div><!--</div>--></div>""" (Element "div" [] [ Comment "</div>" ]))
        , test "basic4" (testParse """<!--<!---->""" (Comment "<!--"))
        ]


attributeTests : Test
attributeTests =
    describe "Attribute"
        [ test "basic1" (testParse """<a href="example.com"></a>""" (Element "a" [ ( "href", "example.com" ) ] []))
        , test "basic2" (testParse """<a href='example.com'></a>""" (Element "a" [ ( "href", "example.com" ) ] []))
        , test "basic3" (testParse """<a href=example.com></a>""" (Element "a" [ ( "href", "example.com" ) ] []))
        , test "basic4" (testParse """<a HREF=example.com></a>""" (Element "a" [ ( "href", "example.com" ) ] []))
        , test "basic5" (testParse """<a href=bare></a>""" (Element "a" [ ( "href", "bare" ) ] []))
        , test "basic6" (testParse """<a href="example.com?a=b&amp;c=d"></a>""" (Element "a" [ ( "href", "example.com?a=b&c=d" ) ] []))
        , test "basic7" (testParse """<a href="example.com?a=b&c=d"></a>""" (Element "a" [ ( "href", "example.com?a=b&c=d" ) ] []))
        , test "basic8" (testParse """<input max=100 min = 10.5>""" (Element "input" [ ( "max", "100" ), ( "min", "10.5" ) ] []))
        , test "basic9" (testParse """<input disabled>""" (Element "input" [ ( "disabled", "" ) ] []))
        , test "basic10" (testParse """<input DISABLED>""" (Element "input" [ ( "disabled", "" ) ] []))
        , test "basic11" (testParse """<meta http-equiv=Content-Type>""" (Element "meta" [ ( "http-equiv", "Content-Type" ) ] []))
        , test "basic12" (testParse """<input data-foo2="a">""" (Element "input" [ ( "data-foo2", "a" ) ] []))
        , test "basic13" (testParse """<html xmlns:v="urn:schemas-microsoft-com:vml"></html>""" (Element "html" [ ( "xmlns:v", "urn:schemas-microsoft-com:vml" ) ] []))
        , test "basic14" (testParse """<link rel=stylesheet
        href="">""" (Element "link" [ ( "rel", "stylesheet" ), ( "href", "" ) ] []))
        ]


selfClosingTests : Test
selfClosingTests =
    describe "Self-closing tags"
        [ test "br, no closing" (testParse """<br>""" (Element "br" [] []))
        , test "br, no space before closing" (testParse """<br/>""" (Element "br" [] []))
        , test "br, with space before closing" (testParse """<br />""" (Element "br" [] []))
        ]


errorTests : Test
errorTests =
    describe "Errors"
        [ test "invalid closing tag" (testError "<a><br></p>")
        , test "self-closing non-void tag" (testError "<p/>")
        ]


suite : Test
suite =
    describe "HtmlParser"
        [ textNodeTests
        , nodeTests
        , commentTests
        , attributeTests
        , selfClosingTests
        , errorTests

        --, scriptTests
        ]
