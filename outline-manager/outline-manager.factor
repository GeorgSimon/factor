! Copyright (C) 2013 Georg Simon.
! See http://factorcode.org/license.txt for BSD license.
USING: kernel models ui ui.gadgets.tables ;
IN: outline-manager

: outline-manager ( -- )
    { { "Hello world!" } } <model> trivial-renderer <table>
    [ "Outline Manager" open-window ] curry with-ui
    ;
MAIN: outline-manager
