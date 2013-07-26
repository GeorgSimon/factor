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

    "Überschrift" <label>
    { 333 55 } >>pref-dim

    { { "Hello world" } { "Hello world" } { "Hello world" } } <model>
    short-line
    <table>
    { 333 666 } >>pref-dim

    2array >>gadgets
    ;
