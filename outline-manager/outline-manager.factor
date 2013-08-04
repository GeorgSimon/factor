! Copyright (C) 2013 Georg Simon.
! See http://factorcode.org/license.txt for BSD license.
! #### = todo
! #### for development and debugging only :
USING: classes nested-comments prettyprint
    ;
USING: accessors arrays colors.constants combinators continuations
    io io.backend io.encodings.utf8 io.files kernel
    math math.parser math.rectangles models models.arrow namespaces sequences
    ui ui.gadgets ui.gadgets.borders ui.gadgets.editors ui.gadgets.frames
    ui.gadgets.glass ui.gadgets.grids ui.gadgets.labeled ui.gadgets.labels
    ui.gadgets.line-support ui.gadgets.tables ui.gestures
    ui.pens.solid
    ;
FROM: models => change-model ; ! to clear ambiguity
IN: outline-manager
! -------------------------------------------------
SYMBOLS: global-font-size outline-file outline-pointer ;
! ------------------------------------------------- utilities
: error>message ( error -- string )
    ! Factor errors are strings in Windows and tuples in Linux
    [ message>> ] [ drop ] recover
    ;
: set-label-font-size ( size labeled-gadget -- )
    children>> [ border? ] find nip children>> [ label? ] find nip
    font>> size<<
    ;
: set-font-sizes ( labeled-gadget -- labeled-gadget' ) ! #### use change-font ?
    global-font-size get swap
    2dup content>> font>> size<<
    [ set-label-font-size ] keep
    ;
: target-index ( table -- index )
    selection-index>> value>> [ 0 ] unless*
    ;
! ------------------------------------------------- communicative-frame
TUPLE: communicative-frame < frame
    ;
M: communicative-frame focusable-child* ( gadget -- child )
    children>> [ labeled-gadget? ] find nip
    ;
: <communicative-frame> ( focusable-child model -- frame )
    1 2 communicative-frame new-frame { 0 0 } >>filled-cell
    swap <label-control>
    global-font-size get over font>> size<<
    { 0 1 } grid-add
    swap { 0 0 } grid-add
    ;
! ------------------------------------------------- file-observer
TUPLE: file-observer path model dirty
    ;
M: file-observer model-changed ( model observer -- )
    nip t swap dirty<<
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
: (save-data) ( file-observer-object -- )
    [ model>> value>> [ first ] map ] [ path>> ] bi utf8 set-file-lines
    ; inline
: save-data ( file-observer-object -- )
    dup dirty>> [ (save-data) ] [ drop ] if
    ;
: <file-observer> ( path -- file-observer-object )
    file-observer new swap >>path
    ;
! ------------------------------------------------- item-editor
TUPLE: item-editor < editor
    ;
: jot ( editor -- )
    [   control-value                               ! new
        outline-pointer get                         ! new table
        [ target-index swap over ] [ model>> ] bi   ! index new index model
        [ insert-nth ] change-model                 ! index
        outline-pointer get swap select-row
        ]
    [ hide-glass ]
    bi
    ;
item-editor
H{
    { T{ key-down { sym "RET" } }   [ jot ] }
    }
set-gestures
: <item-editor> ( -- labeled-editor )
    item-editor new-editor
    COLOR: yellow [ over font>> background<< ] [ <solid> >>interior ] bi
    "item title editor" <labeled-gadget>
    ;
! ------------------------------------------------- outline-table
TUPLE: outline-table < table editor-gadget popup { repeats model }
    ;
: (handle-gesture) ( gesture outline-table handler -- f )
    over repeats>> value>> [ 1 ] unless*
    [ 2dup ( outline-table -- ) call-effect ] times
    drop f swap repeats>> set-model drop f
    ;
: update-repeats ( outline-table number -- )
    swap repeats>> [ [ 10 * + 100 mod ] when* ] change-model
    ;
: ?update-repeats ( gesture outline-table -- propagate-flag )
    swap gesture>string
    dup "BACKSPACE" = [
        drop repeats>> f swap set-model f ! f = handled ! #### dip ?
    ] [
        string>number [ update-repeats f ] [ drop t ] if*
    ] if
    ;
M: outline-table handle-gesture ( gesture outline-table -- ? )
    2dup get-gesture-handler [ (handle-gesture) ] [ ?update-repeats ] if*
    ;
: (archive) ( table object -- )
    "Object to archive : " write . flush ! ####
    dup [ selection-index>> value>> dup ] [ model>> ] bi
    [ remove-nth ] change-model
    select-row
    ; inline
: archive ( table -- )
    dup (selected-row)
    [ (archive) ] [ 2drop "No item selected" print flush ] if
    ;
: save-all-data ( -- ) ! to be called periodically
    outline-file get save-data
    ;
: finish-manager ( gadget -- )
    save-all-data close-window
    ; inline
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
    dup selection-index>> value>> dup 0 > -1 (?move)
    ;
: selection-rect ( table -- rectangle )
    [ [ line-height ] [ target-index ] bi * 0 swap ]
    [ [ total-width>> ] [ line-height ] bi 2 + ]
    bi
    [ 2array ] 2bi@ <rect>
    ;
: init-editor ( editor -- )
    dup control-value first empty?
    [
        "item title"                    ! editor string
        0 over length 2array swap       ! editor array string
        pick user-input* drop           ! editor array
        swap caret>> set-model          !
    ] [                                 ! editor
        { 0 0 } swap mark>> set-model
        ]
    if
    ;
: pop-editor ( table -- )
    dup editor-gadget>> dup content>> init-editor
    over selection-rect [ show-popup ] curry [ request-focus ] bi
    ;
outline-table
H{
    { T{ key-down { sym "DELETE" } }                [ archive ] }
    { T{ key-down { sym "a" } }                     [ archive ] }
    { T{ key-down { sym "ESC" } }                   [ finish-manager ] }
    { T{ key-down { sym "t" } }                     [ move-down ] }
    { T{ key-down { mods { C+ } } { sym "DOWN" } }  [ move-down ] }
    { T{ key-down { mods { C+ } } { sym "UP" } }    [ move-up ] }
    { T{ key-down { sym "h" } }                     [ move-up ] }
    { T{ key-down { sym " " } }                     [ pop-editor ] }
    }
set-gestures

: <outline-table> ( model renderer -- table )
    outline-table new-table t >>selection-required? ! #### necessary?
    ;
! ------------------------------------------------- main
: read-options ( -- ) ! #### stub
    16 global-font-size set
    ;
: make-outline-manager ( -- labeled-gadget )
    read-options
    "outline.txt" <file-observer> [ outline-file set ] [ get-data ] bi
    trivial-renderer <outline-table> dup outline-pointer set
    <item-editor> set-font-sizes >>editor-gadget
    f <model> >>repeats
    [ outline-file get path>> normalize-path <labeled-gadget> set-font-sizes ]
    [ repeats>> [ [ number>string ] [ "" ] if* ] <arrow> ]
    bi
    <communicative-frame>
    ;
: outline-manager ( -- )
    make-outline-manager [ "Outline Manager" open-window ] curry with-ui
    ;
MAIN: outline-manager
