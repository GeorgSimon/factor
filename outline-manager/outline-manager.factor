! Copyright (C) 2013 Georg Simon.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays colors.constants continuations fry
    io io.files io.encodings.utf8 kernel math.rectangles models
    sequences
    ui ui.gadgets.glass ui.gadgets ui.gadgets.editors
    ui.gadgets.labeled ui.gadgets.tables ui.gestures ui.pens.solid
    ;
IN: outline-manager

USE: prettyprint ! todo for debugging only

! ---------
! utilities
! ---------
: error>message ( error -- string )
    ! Factor errors are strings in Windows and tuples in Linux
    [ message>> ] [ drop ] recover
    ;
: default-font ( gadget -- gadget ) 16 over font>> size<<
    ;
! --------
! renderer
! --------
SINGLETON: short-line ! renderer
M: short-line row-columns ( line object -- line )
    drop
    ;
! -------------------
! outline-table class
! -------------------
TUPLE: outline-table < table popup
    ;
: finish-outline ( table -- )
    close-window
    ;
: jot ( table -- )
    <editor> default-font
    COLOR: yellow [ over font>> background<< ] [ <solid> >>interior ] bi
    "new item line" <labeled-gadget>
    { 0 0 } { 0 0 } <rect> '[ _ show-popup ]
    [ request-focus ]
    bi
    ;
outline-table
H{
    { T{ key-down { sym "ESC" } }   [ finish-outline ] }
    { T{ key-down { sym " " } }     [ jot ] }
    }
set-gestures
! ----
! main
! ----
: <outline-table> ( model renderer -- table )
    outline-table new-table
    { 333 666 } >>pref-dim
    default-font
    ;
: outline-manager ( -- )
    "outline.txt"
    [ utf8 file-lines [ empty? not ] filter [ 1array ] map ]
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
