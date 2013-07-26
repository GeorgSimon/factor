! Copyright (C) 2013 Georg Simon.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays ui ui.gadgets.labels ;
IN: outline-manager

MAIN-WINDOW: outline-manager
    { { title "Outline Manager" } }
    "Hello world" <label>
    { 99 99 } >>pref-dim
    { { "Hello world" } { "Hello world" } { "Hello world" } } <table>
    { 333 333 } >>pref-dim
    2array
    >>gadgets
    ;
