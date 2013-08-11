USING: accessors io io.styles kernel models prettyprint
    ui ui.gadgets ui.gadgets.panes ui.gestures ;
IN: sandbox

: dim. ( gadget -- )
    dup <pane-stream> [ dim>> . ] with-output-stream
    ;
TUPLE: test-pane < pane style
    ;
: <test-pane> ( -- pane )
    f test-pane new-pane
    H{ { font-name "sans-serif" } { font-size 64 } } >>style
    "a string which could be too long" <model> >>model
    dup [ dup dup style>> [ control-value print ] with-style ] with-pane
    dup dim.
    ;
MAIN-WINDOW: test-main
    { } <test-pane> >>gadgets
    ;
test-pane
H{
    { T{ key-down { sym "ESC" } }   [ close-window ] }
    { T{ key-down { sym "F1" } }    [ dim. ] }
    }
set-gestures

! ------------------------------------------------- model-changed method
! Factor seems to
! - register test-pane
! - call model-changed before window gets visible
! -------------------------------------------------
M: test-pane model-changed ( model observer -- )
    dim. drop
    ;
