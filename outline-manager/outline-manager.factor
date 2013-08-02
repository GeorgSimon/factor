! Copyright (C) 2013 Georg Simon.
! See http://factorcode.org/license.txt for BSD license.
! #### = todo
USING: classes prettyprint ; ! #### for development and debugging only

USING: accessors arrays continuations
    io io.backend io.encodings.utf8 io.files kernel math models namespaces
    sequences
    ui ui.gadgets.borders ui.gadgets.labeled ui.gadgets.labels
    ui.gadgets.tables ui.gestures
    ;
IN: outline-manager
! -------------------------------------------------
SYMBOLS: global-font-size outline-file ;
! ------------------------------------------------- utilities
: error>message ( error -- string )
    ! Factor errors are strings in Windows and tuples in Linux
    [ message>> ] [ drop ] recover
    ;
: set-label-font-size ( size gadget -- )
    parent>> children>> [ border? ] find nip children>> [ label? ] find nip
    font>> size<<
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
    "save-data : " write
    class-of . ! ####
    ;
: <file-observer> ( path -- file-observer )
    file-observer new swap >>path
    ;
! -------------------------------------------------
TUPLE: outline-table < table
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
: read-options ( -- ) ! #### stub
    16 global-font-size set
    ;
: make-outline-manager ( -- labeled-gadget )
    read-options
!    [ value>> ] dip [ font>> size<< ] [ set-label-font-size ] 2bi
    global-font-size get . flush
    "outline.txt" <file-observer> [ outline-file set ] [ get-data ] bi
    trivial-renderer <outline-table>
    outline-file get path>> normalize-path <labeled-gadget>
    ;
: outline-manager ( -- )
    make-outline-manager [ "Outline Manager" open-window ] curry with-ui
    ;
MAIN: outline-manager
