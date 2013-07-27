! Copyright (C) 2013 Georg Simon.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays kernel models ui ui.gadgets.labels ui.gadgets.tables ;
IN: outline-manager

SINGLETON: short-line ! renderer

M: short-line row-columns ( line object -- line )
    drop
    ;
: default-font ( gadget -- gadget ) 16 over font>> size<<
    ;
: <outline-table> ( model renderer -- table )
    <table>
    { 333 666 } >>pref-dim
    default-font
    ;
MAIN-WINDOW: outline-manager

    { { title "Outline Manager" } }

    { { "Hello world" } { "Hello world" } { "Hello world" } } <model>
    short-line
    <outline-table>

    >>gadgets
    ;
