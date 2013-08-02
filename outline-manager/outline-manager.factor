! Copyright (C) 2013 Georg Simon.
! See http://factorcode.org/license.txt for BSD license.
! #### = todo
USING: classes prettyprint ; ! #### for development and debugging only

USING: accessors kernel models namespaces sequences
    ui ui.gadgets.tables ui.gestures
    ;
IN: outline-manager
! -------------------------------------------------
SYMBOL: global-font-size
! -------------------------------------------------
TUPLE: global-data
    value observers
    ;
GENERIC: data-changed ( global-data observer -- )
: notify-observers ( global-data -- )
    dup observers>> [ data-changed ] with each
    ;
: set-global-data ( value global-data -- )
    swap >>value notify-observers
    ;
: add-observer ( observer global-data -- )
    observers>> push
    ;
: <global-data> ( -- global-data-object )
    global-data new V{ } clone >>observers
    ;
! -------------------------------------------------
TUPLE: outline-table < table
    ;
M: outline-table data-changed
    [ value>> ] dip font>> size<<
    ;
: finish-manager ( gadget -- )
    close-window
    ; inline
outline-table
H{
    { T{ key-down { sym "ESC" } }   [ finish-manager ] }
    }
set-gestures

: <outline-table> ( model renderer -- table )
    outline-table new-table
    ;
! -------------------------------------------------
: make-outline-manager ( -- outline-table )
    { { "Hello world!" } } <model> trivial-renderer <outline-table>
    <global-data>
    2dup add-observer
    16 over set-global-data
    global-font-size set
    ;
: outline-manager ( -- )
    make-outline-manager [ "Outline Manager" open-window ] curry with-ui
    ;
MAIN: outline-manager
