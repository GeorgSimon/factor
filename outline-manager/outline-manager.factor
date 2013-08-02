! Copyright (C) 2013 Georg Simon.
! See http://factorcode.org/license.txt for BSD license.
USING: kernel models ui ui.gadgets.tables ui.gestures ;
IN: outline-manager

TUPLE: outline-table < table
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
: outline-manager ( -- )
    { { "Hello world!" } } <model> trivial-renderer <outline-table>
    [ "Outline Manager" open-window ] curry with-ui
    ;
MAIN: outline-manager
