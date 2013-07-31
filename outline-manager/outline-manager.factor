! Copyright (C) 2013 Georg Simon.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays colors.constants combinators continuations fry
    io io.backend io.files io.encodings.utf8
    kernel math math.order math.rectangles models namespaces sequences
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
: outline-index ( table -- index )
    selection-index>> value>> [ 0 ] unless*
    ;
: default-font ( gadget -- ) 16 swap font>> size<<
    ;
: <labeled-gadget-with-default-font> ( gadget title -- gadget' )
    <labeled-gadget>
    dup children>> [ border? ] find nip
    children>> [ label? ] find nip
    default-font
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
        [ outline-index swap over ]
        [ model>> ]
        bi                                          ! index new index model
        [ insert-nth ] change-model                 ! index

        "Index vor Einfügen : " write ! todo
        dup . ! todo
        "Index nach Einfügen : " write ! todo
        outline-pointer get outline-index . flush ! todo

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
    dup default-font
    COLOR: yellow [ over font>> background<< ] [ <solid> >>interior ] bi
    "new item line" <labeled-gadget-with-default-font>
    ;
! ------------------------------------------------- outline-table
TUPLE: outline-table < table popup counter
    ;
: (handle-gesture) ( gesture table quot -- )
    [ ( outline-table -- ) call-effect ] [ drop f swap counter<< ] 2bi drop
    ;
: ?update-counter ( gesture outline-table -- propagate-flag )
    drop dup key-down? [ . flush ] [ drop ] if t
    ;
M: outline-table handle-gesture ( gesture outline-table -- ? )
    2dup get-gesture-handler                        ! gesture table quot/f
    [ (handle-gesture) f ] [ ?update-counter ] if*
    ;
: selection-rect ( table -- rectangle )
    [ [ line-height ] [ outline-index ] bi * 0 swap ]
    [ [ total-width>> ] [ line-height ] bi 2 + ]
    bi
    [ 2array ] 2bi@ <rect>
    ;
: finish-outline ( table -- )
    save-data close-window
    ;
: pop-editor ( table -- )
    <item-editor>
    over selection-rect '[ _ show-popup ]
    [ request-focus ]
    bi
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
: (?move) ( table index flag direction -- )
    swap
    [ over + rot model>> [ [ exchange ] keep ] change-model ]
    [ 3drop "No movement possible" print flush ]
    if
    ;
: move-down ( table -- )
    dup [ selection-index>> value>> dup ] [ control-value length 1 - ] bi <
    1 (?move)
    ;
: move-up ( table -- )
    dup selection-index>>
    dup . flush ! todo
    dup -rot ! todo
    value>> dup 0 > -1 (?move)
    . flush ! todo
    ;
outline-table
H{
    { T{ key-down { sym "DELETE" } }                [ archive ] }
    { T{ key-down { mods { C+ } } { sym "DOWN" } }  [ move-down ] }
    { T{ key-down { sym "ESC" } }                   [ finish-outline ] }
    { T{ key-down { mods { C+ } } { sym "UP" } }    [ move-up ] }
    { T{ key-down { sym " " } }                     [ pop-editor ] }
    { T{ key-down { sym "a" } }                     [ archive ] }
    { T{ key-down { sym "h" } }                     [ move-up ] }
    { T{ key-down { sym "t" } }                     [ move-down ] }
    }
set-gestures
: (outline-table) ( table-model -- table )
    trivial-renderer outline-table new-table
    t >>selection-required? ! better behaviour before first cursor move
    dup default-font
    ;
: <outline-table> ( file-model table-model -- table )
    (outline-table) dup outline-pointer set
    swap path>> normalize-path <labeled-gadget-with-default-font>
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
