! refresh-all "kullulu" test

USING: accessors kernel kullulu models namespaces sequences tools.test words
    ;

{ { "first" "second" "third" "fourth" } } [
"first   second third        fourth" line>words
] unit-test

{ 16 } [
{ "font-size 16 # commented" "# comment only" "" "Syntax error" }
process-options
options "font-size" word-prop
] unit-test

{ t } [
fsm-members off <table-editor> fsm-members get first =
] unit-test

persistents off init-i18n

{ f } [ persistents get last dirty>> ] unit-test
{ "Gefundene Optionen :" } [ "Found options :" i18n ] unit-test
{ f } [ persistents get last dirty>> ] unit-test
{ "missing translation" } [ "missing translation" i18n ] unit-test
{ t } [ persistents get last dirty>> ] unit-test


! ------------------------------------------------- sandbox
USING: classes prettyprint
    ;
