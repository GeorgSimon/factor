! Copyright (C) 2013 Georg Simon.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays colors.constants combinators continuations fry
    io io.backend io.files io.encodings.utf8 kernel
    math math.order math.parser math.rectangles models namespaces sequences
    ui ui.gadgets.borders ui.gadgets.glass ui.gadgets ui.gadgets.editors
    ui.gadgets.labeled ui.gadgets.labels ui.gadgets.line-support
    ui.gadgets.tables
    ui.gestures ui.pens.solid
    ;
FROM: models => change-model ; ! to clear ambiguity
IN: outline-manager

USE: prettyprint ! todo for development and debugging only

SYMBOL: outline-pointer ! jot can find outline-table here
SYMBOL: outline-file    ! save-data must know which files to save

! ------------------------------------------------- utilities
: error>message ( error -- string )
    ! Factor errors are strings in Windows and tuples in Linux
    [ message>> ] [ drop ] recover
    ;
: target-index ( table -- index )
    selection-index>> value>> [ 0 ] unless*
    ;
! ------------------------------------------------- table-model
TUPLE: table-model < model
    ;
: init-table ( lines table-model -- ) ! without notifying observers
    [ [ 1array ] map ] dip value<<
    ;
: table>lines ( table-model -- lines )
    value>> [ first ] map
    ;
: <table-model> ( -- table-model )
    { { "1 column" } } ! will be overwritten by read-file
    table-model new-model
    ;
! ------------------------------------------------- file management
TUPLE: file-model < model path changed
    ;
M: file-model model-changed ( model observer -- )
    t swap changed<<
    drop
    ;
: (read-file) ( path -- lines )
    [ utf8 file-lines ]
    [ error>message " : " [ write ] bi@ print flush { } ]
    recover
    ;
: read-file ( file-model -- )
    [ path>> (read-file) ] [ value>> ] bi init-table
    ;
: save-file ( file-model -- )
    dup changed>>
    [ [ value>> table>lines ] [ path>> ] bi utf8 set-file-lines ]
    [ drop ]
    if
    ;
: <file-model> ( path data-model -- file-model )
    file-model new-model
    swap >>path
    dup dup value>> add-connection
    ;
: save-data ( -- )
    outline-file get save-file
    ;
! ------------------------------------------------- item-editor
TUPLE: item-editor < editor
    ;
: jot ( editor -- )
    [   control-value                               ! new
        outline-pointer get                         ! new table
        [ target-index swap over ] [ model>> ] bi   ! index new index model
        [ insert-nth ] change-model                 ! index
        outline-pointer get swap select-row ! ( table n -- )
        ]
    [ hide-glass ]
    bi
    ;
item-editor
H{
    { T{ key-down { sym "RET" } }   [ jot ] }
    }
set-gestures
: <item-editor> ( -- editor )
    item-editor new-editor
    COLOR: yellow [ over font>> background<< ] [ <solid> >>interior ] bi
    "new item line" <labeled-gadget>
    ;
! ------------------------------------------------- outline-table
TUPLE: outline-table < table popup repeats
    ;
: (handle-gesture) ( gesture table quot -- )
    [ ( outline-table -- ) call-effect ] [ drop f swap repeats<< ] 2bi drop
    ;
: update-repeats ( outline-table number -- outline-table )
    swap [ [ 10 * + ] when* ] change-repeats
    ;
: ?update-repeats ( gesture outline-table -- propagate-flag )
    swap gesture>string
    dup "BACKSPACE" =
    [ drop f >>repeats t ] [ string>number [ update-repeats f ] [ t ] if* ] if
    nip ! outline-table
    ;
M: outline-table handle-gesture ( gesture outline-table -- ? )
    2dup get-gesture-handler                        ! gesture table quot/f
    [ (handle-gesture) f ] [ ?update-repeats ] if*
    ;
: (archive) ( table -- )
    [   [ selection-index>> value>> dup ] [ model>> ] bi
        [ remove-nth ] change-model
        ]
    [   [ control-value length [ drop f ] [ 1 - min ] if-zero ]
        [ selection-index>> ]
        bi
        set-model
        ]
    bi
    ;
: archive ( table -- )
    dup selection-index>> value>>
    [ (archive) ] [ drop "No item selected" print flush ] if
    ;
: finish-outline ( table -- )
    save-data close-window
    ;
: (?move) ( table index flag direction -- )
    swap
    [ over + rot model>> [ [ exchange ] keep ] change-model ]
    [ 3drop "No movement possible" print flush ]
    if
    ;
: (move-down) ( table -- )
    dup [ selection-index>> value>> dup ] [ control-value length 1 - ] bi <
    1 (?move)
    ;
: move-down ( table -- )
    dup repeats>> [ [ dup (move-down) ] times drop ] [ (move-down) ] if*
    ;
: (move-up) ( table -- )
    dup selection-index>> value>> dup 0 > -1 (?move)
    ;
: move-up ( table -- )
    dup repeats>> [ [ dup (move-up) ] times drop ] [ (move-up) ] if*
    ;
: selection-rect ( table -- rectangle )
    [ [ line-height ] [ target-index ] bi * 0 swap ]
    [ [ total-width>> ] [ line-height ] bi 2 + ]
    bi
    [ 2array ] 2bi@ <rect>
    ;
: pop-editor ( table -- )
    <item-editor>
    over selection-rect '[ _ show-popup ]
    [ request-focus ]
    bi
    ;
outline-table
H{
    { T{ key-down { sym "DELETE" } }                [ archive ] }
    { T{ key-down { sym "a" } }                     [ archive ] }
    { T{ key-down { sym "ESC" } }                   [ finish-outline ] }
    { T{ key-down { sym "t" } }                     [ move-down ] }
    { T{ key-down { mods { C+ } } { sym "DOWN" } }  [ move-down ] }
    { T{ key-down { mods { C+ } } { sym "UP" } }    [ move-up ] }
    { T{ key-down { sym "h" } }                     [ move-up ] }
    { T{ key-down { sym " " } }                     [ pop-editor ] }
    }
set-gestures
: (outline-table) ( table-model -- table )
    trivial-renderer outline-table new-table
    t >>selection-required? ! better behaviour before first cursor move
    ;
: <outline-table> ( file-model table-model -- table )
    (outline-table) dup outline-pointer set
    swap path>> normalize-path <labeled-gadget>
    { 333 666 } >>pref-dim
    ;
! ------------------------------------------------- main
: outline-manager ( -- )
    "outline.txt" <table-model>
    [ <file-model> [ outline-file set ] [ read-file ] bi outline-file get ]
    keep
    <outline-table>
    '[ _ "Outline Manager" open-window ] with-ui
    ;
MAIN: outline-manager
