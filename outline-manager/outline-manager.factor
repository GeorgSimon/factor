! Copyright (C) 2013 Georg Simon.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays kernel models ui ui.gadgets.labels ui.gadgets.tables ;
IN: outline-manager

SINGLETON: short-line ! renderer

M: short-line row-columns ( line object -- line )
    drop
    ;
MAIN-WINDOW: outline-manager
    { { title "Outline Manager" } }
    { { "Hello world" } { "Hello world" } { "Hello world" } } <model>
    short-line <table>
    >>gadgets
    ;
