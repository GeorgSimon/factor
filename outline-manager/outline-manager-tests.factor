! USE: outline-manager refresh-all "outline-manager" test

USING: accessors classes kernel outline-manager sequences tools.test
    ui.gadgets.labeled
    ;
IN: outline-manager.tests

{ ".kullulu/config.txt" ".kullulu/config.txt" } [
    ".kullulu/config.txt" <file-observer>
    [ get-data connections>> first path>> ] [ path>> ] bi
    ] unit-test
{ labeled-gadget outline-table item-editor } [
    make-outline-manager dup content>> dup editor-gadget>> content>>
    [ class-of ] tri@
    ] unit-test

USING: prettyprint
    ;

