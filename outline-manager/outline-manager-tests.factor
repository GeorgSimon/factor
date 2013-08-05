! USE: outline-manager refresh-all "outline-manager" test

USING: accessors classes combinators kernel math.rectangles models
    namespaces nested-comments outline-manager sequences tools.test
    ui.gadgets ui.gadgets.borders ui.gadgets.frames ui.gadgets.grids
    ui.gadgets.icons ui.gadgets.labeled
    ;
IN: outline-manager.tests

{ ".kullulu/config.txt" ".kullulu/config.txt" } [
    ".kullulu/config.txt" [ ] [ ] <file-observer>
    [ get-model connections>> first path>> ] [ path>> ] bi
    ] unit-test
{ { tuple rect gadget grid frame arrow-frame } } [
    V{ } clone file-observers set
    make-outline-manager class-of superclasses
    ] unit-test
{ f } [
    V{ } clone file-observers set
    make-outline-manager focusable-child* content>> calls>> value>>
    ] unit-test

USING: prettyprint
    ;
