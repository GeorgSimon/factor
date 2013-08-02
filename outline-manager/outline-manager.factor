! Copyright (C) 2013 Georg Simon.
! See http://factorcode.org/license.txt for BSD license.
! #### = todo
USING: classes prettyprint ; ! #### for development and debugging only

USING: accessors arrays continuations
    io io.backend io.encodings.utf8 io.files kernel models namespaces sequences
    ui ui.gadgets.tables ui.gestures
    ;
IN: outline-manager
! -------------------------------------------------
SYMBOLS: global-font-size outline-file ;
! ------------------------------------------------- utilities
: error>message ( error -- string )
    ! Factor errors are strings in Windows and tuples in Linux
    [ message>> ] [ drop ] recover
    ;
! ------------------------------------------------- global-data
TUPLE: global-data value observers
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
! ------------------------------------------------- file-observer
TUPLE: file-observer path model
    ;
M: file-observer model-changed ! ####
    "file-observer model-changed" print
    [ class-of . ] bi@
    flush
    ;
: read-file ( path -- model )
    path>>
    [ utf8 file-lines [ 1array ] map ]
    [ error>message write " : " write normalize-path print flush { } ]
    recover
    <model> 
    ; inline
: get-data ( file-observer-object -- model )
    [ read-file dup ] [ model<< ] [ over add-connection ] tri
    ;
: save-data ( file-observer-object -- )
    class-of . ! ####
    ;
: <file-observer> ( path -- file-observer )
    file-observer new swap >>path
    ;
! -------------------------------------------------
TUPLE: outline-table < table
    ;
M: outline-table data-changed
    [ value>> ] dip font>> size<<
    ;
: finish-manager ( gadget -- )
    outline-file get save-data
    close-window
    ; inline
outline-table
H{
    { T{ key-down { sym "ESC" } }   [ finish-manager ] }
    }
set-gestures

: <outline-table> ( model renderer -- table )
    outline-table new-table t >>selection-required?
    ;
! -------------------------------------------------
: make-outline-manager ( -- outline-table )
    "outline.txt" <file-observer> [ outline-file set ] [ get-data ] bi
    trivial-renderer <outline-table>
    <global-data>
    2dup add-observer
    16 over set-global-data
    global-font-size set
    ;
: outline-manager ( -- )
    make-outline-manager [ "Outline Manager" open-window ] curry with-ui
    ;
MAIN: outline-manager
