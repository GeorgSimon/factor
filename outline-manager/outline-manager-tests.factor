! USE: outline-manager refresh-all "outline-manager" test

USING: accessors classes combinators kernel math.rectangles
    outline-manager sequences tools.test
    ui.gadgets ui.gadgets.borders ui.gadgets.frames ui.gadgets.grids
    ui.gadgets.icons ui.gadgets.labeled
    ;
IN: outline-manager.tests

{ ".kullulu/config.txt" ".kullulu/config.txt" } [
    ".kullulu/config.txt" <file-observer>
    [ get-data connections>> first path>> ] [ path>> ] bi
    ] unit-test
{ { tuple rect gadget grid frame labeled-gadget }
    labeled-gadget outline-table item-editor
    { { icon border icon } { icon outline-table icon } { icon icon icon } }
    { 1 1 }
    outline-table
    } [
    make-outline-manager {
        [ class-of superclasses ]
        [ dup content>> dup editor-gadget>> content>> [ class-of ] tri@ ]
        [ grid>> [ [ class-of ] map ] map ]
        [ filled-cell>> ]
        [ focusable-child class-of ]
        }
    cleave
    ] unit-test

USING: prettyprint
    ;

make-outline-manager <communicative-frame> focusable-child*
dup t = [ class-of ] unless .
