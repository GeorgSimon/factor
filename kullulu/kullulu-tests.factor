USING: kernel kullulu models namespaces sequences tools.test
    ;
{ fsm-members } [ off ] each

{ t } [
{ } <model> <table-editor> fsm-members get first =
] unit-test

! ------------------------------------------------- sandbox
USING: classes prettyprint
    ;
