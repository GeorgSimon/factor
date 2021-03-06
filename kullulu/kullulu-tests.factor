! refresh-all "kullulu" test

USING: accessors kernel kullulu models namespaces sequences tools.test words
    ;

{ { "first" "second" "third" "fourth" } } [
"first   second third        fourth" line>words
] unit-test

init-options persistents off init-i18n

{ 16 } [
{ "font-size 16 # commented" "# comment only" "" "Syntax error" }
[ line>words ] map process-options
options "font-size" word-prop
] unit-test

{ t } [
fsm-subscribers off <table-editor> fsm-subscribers get last =
] unit-test

persistents off init-i18n

{ f } [ persistents get last dirty>> ] unit-test
{ "Gefundene Optionen :" } [ "Found options :" i18n ] unit-test
{ f } [ persistents get last dirty>> ] unit-test
{ "missing translation" } [ "missing translation" i18n ] unit-test
{ t } [ persistents get last dirty>> ] unit-test

{ t } [
<table-editor> <arrow-bar> children>> first model>> dependencies>> first
swap get-table calls>> =
] unit-test

! why are persistent models not connected twice ?
{ 1 } [
<table-editor> get-table model>> connections>> length
] unit-test

! ------------------------------------------------- sandbox
USING: classes prettyprint
    ;
{ "font-size 16 # commented" "# comment only" "" "Syntax error" }
[ line>words ] map process-options
options "font-size" word-prop .
