! Copyright (C) 2013 Georg Simon.
! See http://factorcode.org/license.txt for BSD license.
! #### = todo
! #### for development and debugging only :
! USING: classes nested-comments ;

USING: accessors arrays calendar colors.constants combinators continuations
    io io.backend io.encodings.utf8 io.files io.pathnames
    kernel math math.parser math.rectangles models models.arrow
    namespaces prettyprint sequences splitting timers
    ui ui.gadgets ui.gadgets.borders ui.gadgets.editors ui.gadgets.frames
    ui.gadgets.glass ui.gadgets.grids ui.gadgets.labeled ui.gadgets.labels
    ui.gadgets.line-support ui.gadgets.tables ui.gestures ui.pens.solid
    vectors words
    ;
FROM: models => change-model ; ! to clear ambiguity
IN: outline-manager
! -------------------------------------------------
SYMBOLS: file-observers note-font-list options outline-pointer
    ;
! ------------------------------------------------- utilities
: error>message ( error -- string )
    ! Factor errors are strings in Windows and tuples in Linux
    [ message>> ] [ drop ] recover
    ;
: target-index ( table -- index )
    selection-index>> value>> [ 0 ] unless*
    ;
: fetch-lines ( path -- lines )
    [ utf8 file-lines ]
    [ error>message write " : " write normalize-path print flush { } ]
    recover
    ;
: lines>words ( lines -- arrayArray ) [ " " split [ empty? not ] filter ] map
    ;
! ------------------------------------------------- font-size management
: note-font ( gadget -- gadget )
    dup note-font-list [ get push ] [ drop [ 1vector ] dip set ] recover
    ;
: set-label-font-size ( size labeled-gadget -- size )
    children>> [ border? ] find nip children>> [ label? ] find nip
    font>> over >>size drop
    ;
: set-font-size ( size gadget -- size )
    [ font>> over >>size drop ]
    [ [ parent>> set-label-font-size ] [ 2drop ] recover ]
    bi
    ;
: set-noted ( font-size -- )
    note-font-list get [ set-font-size ] each drop
    ;
! ------------------------------------------------- arrow-frame
! frame with a status bar displaying an arrow model
! -------------------------------------------------
TUPLE: arrow-frame < frame
    ;
M: arrow-frame focusable-child* ( gadget -- child )
    children>> [ labeled-gadget? ] find nip
    ;
: <arrow-frame> ( table title model quot -- frame )
    <arrow> <label-control> note-font { 1 1 } <border>
    [ <labeled-gadget> ] dip
    1 2 arrow-frame new-frame { 0 0 } >>filled-cell
    swap { 0 1 } grid-add swap { 0 0 } grid-add
    ;
! ------------------------------------------------- file-observer
TUPLE: file-observer path model dirty
    ;
M: file-observer model-changed ( model observer -- )
    nip t swap dirty<<
    ;
: read-file ( path -- model )
    path>> fetch-lines [ 1array ] map <model> 
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
    item-editor new-editor note-font
    COLOR: yellow [ over font>> background<< ] [ <solid> >>interior ] bi
    "item title editor" <labeled-gadget>
    ;
! ------------------------------------------------- outline-table
TUPLE: outline-table < table editor-gadget popup { calls model }
    ;
: (handle-gesture) ( gesture outline-table handler -- f )
    over calls>> value>> [ 1 ] unless*
    [ 2dup ( outline-table -- ) call-effect ] times
    drop f swap calls>> set-model drop f
    ;
: update-calls ( outline-table number -- )
    swap calls>> [ [ 10 * + 100 mod ] when* ] change-model
    ;
: ?update-calls ( gesture outline-table -- propagate-flag )
    swap gesture>string
    dup "BACKSPACE" = [
        drop calls>> f swap set-model f ! f = handled ! #### dip ?
    ] [
        string>number [ update-calls f ] [ drop t ] if*
    ] if
    ;
M: outline-table handle-gesture ( gesture outline-table -- ? )
    2dup get-gesture-handler [ (handle-gesture) ] [ ?update-calls ] if*
    ;
: (archive) ( table object -- )
    "Line to archive : " write first . flush ! ####
    dup [ selection-index>> value>> dup ] [ model>> ] bi
    [ remove-nth ] change-model
    select-row
    ; inline
: archive ( table -- )
    dup (selected-row)
    [ (archive) ] [ 2drop "No item selected" print flush ] if
    ;
: save-all-data ( -- ) ! to be called periodically too
    file-observers get [ save-data ] each
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
    outline-table new-table t >>selection-required?
    ;
! ------------------------------------------------- main
: read-options ( -- )
    options  2 "save-interval" set-word-prop
    options 16 "font-size" set-word-prop
    ".kullulu/config.txt" home prepend-path fetch-lines
    [ empty? not ] filter [ first CHAR: # = not ] filter lines>words
    [   [   options swap
            [ second string>number dup number>string write ]
            [ first dup bl print ]
            bi
            set-word-prop
            ]
        [ drop "Syntax error :" write [ bl write ] each nl ]
        recover
        ]
    each
    flush
    ;
: make-outline-manager ( -- arrow-frame )
    "outline.txt" <file-observer>                       ! observer
    [ path>> ] [ 1vector file-observers set ] [ get-data ] tri
    trivial-renderer <outline-table> note-font
    dup outline-pointer set
    <item-editor> >>editor-gadget
    swap normalize-path                                 ! table title
    f <model> [ pick calls<< ] keep                     ! table title model
    [ [ number>string "calls : " prepend ] [ "" ] if* ] ! table title model qu
    <arrow-frame> ! ( table title model quot -- frame )
    options "font-size" word-prop set-noted
    ;
: outline-manager ( -- )
    read-options
    [ save-all-data ] options "save-interval" word-prop minutes delayed-every
    start-timer
    make-outline-manager [ "Outline Manager" open-window ] curry with-ui
    ;
MAIN: outline-manager
