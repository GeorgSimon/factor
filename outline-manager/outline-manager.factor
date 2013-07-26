! Copyright (C) 2013 Georg Simon.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays ui ui.gadgets.labels ;
IN: outline-manager

SINGLETON: short-line ! renderer

M: short-line row-columns ( item-key object -- columns )
    drop
    ;
MAIN-WINDOW: outline-manager
    { { title "Outline Manager" } }
    "Hello world" <label>
    { 99 99 } >>pref-dim
    { { "Hello world" } { "Hello world" } { "Hello world" } } short-line <table>
    { 333 333 } >>pref-dim
    2array
    >>gadgets
    ;
