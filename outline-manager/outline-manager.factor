! Copyright (C) 2013 Georg Simon.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays continuations fry
    io io.files io.encodings.utf8 kernel models
    sequences ui ui.gadgets.tables ;
IN: outline-manager

USE: prettyprint ! todo for debugging only

: error>message ( error -- string )
    ! Factor errors are strings in Windows and tuples in Linux
    [ message>> ] [ drop ] recover
    ;
: default-font ( gadget -- gadget ) 16 over font>> size<<
    ;
SINGLETON: short-line ! renderer
M: short-line row-columns ( line object -- line )
    drop
    ;
: <outline-table> ( model renderer -- table )
    <table>
    { 333 666 } >>pref-dim
    default-font
    ;
: outline-manager ( -- )

    "outline.txt"
    [ utf8 file-lines [ 1array ] map ]
    [ error>message " : " append write print flush { } ]
    recover
    '[
        _ <model> short-line <outline-table>
        "Outline Manager"
        open-window
        ]
    with-ui
    ;
MAIN: outline-manager
