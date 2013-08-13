! refresh-all "kullulu" test

USING: kernel kullulu models namespaces sequences tools.test words
    ;

{ { "first" "second" "third" "fourth" } } [
"first   second third        fourth" line>words
] unit-test

{ 16 } [
{ "font-size 16 # commented" "# comment only" "" "Syntax error" }
process-options
options "font-size" word-prop
] unit-test

init-globals

{ t } [
<table-editor> fsm-members get first =
] unit-test

! ------------------------------------------------- sandbox
USING: classes prettyprint
    ;
