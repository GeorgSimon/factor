! Copyright (C) 2013 Georg Simon.
! See http://factorcode.org/license.txt for BSD license.
! #### = todo
! #### for development and debugging only :
USING: classes nested-comments prettyprint
    ;
USING: accessors arrays colors.constants combinators continuations
    io io.backend io.encodings.utf8 io.files kernel
    math math.rectangles models namespaces sequences
    ui ui.gadgets ui.gadgets.borders ui.gadgets.editors ui.gadgets.glass
    ui.gadgets.labeled ui.gadgets.labels ui.gadgets.line-support
    ui.gadgets.tables ui.gestures
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
    "new item line" <labeled-gadget>
    ;
! ------------------------------------------------- outline-table
TUPLE: outline-table < table editor-gadget popup
    ;
M: outline-table handle-gesture ( gesture outline-table -- ? )
    2dup get-gesture-handler
    [ ( outline-table -- ) call-effect drop f ]
    [ drop dup class-of key-down = [ gesture>string . flush ] [ drop ] if t ]
    if*
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
    { T{ key-down { sym "DELETE" } }    [ archive ] }
    { T{ key-down { sym "a" } }         [ archive ] }
    { T{ key-down { sym "ESC" } }       [ finish-manager ] }
    { T{ key-down { sym " " } }         [ pop-editor ] }
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
    outline-file get path>> normalize-path <labeled-gadget> set-font-sizes
    ;
: outline-manager ( -- )
    make-outline-manager [ "Outline Manager" open-window ] curry with-ui
    ;
MAIN: outline-manager
