! Copyright (C) 2013 Georg Simon.
! See http://factorcode.org/license.txt for BSD license.
! #### = todo
! #### for development and debugging only :
USING: classes nested-comments ;

USING: accessors arrays assocs
    calendar colors.constants combinators continuations fonts
    hashtables help.markup help.stylesheet help.syntax
    io io.backend io.encodings.utf8 io.files io.pathnames io.styles
    kernel math math.parser math.rectangles models models.arrow
    namespaces parser prettyprint sequences splitting timers ui ui.gadgets
    ui.gadgets.books ui.gadgets.borders ui.gadgets.editors ui.gadgets.frames
    ui.gadgets.glass ui.gadgets.grids ui.gadgets.labeled ui.gadgets.labels
    ui.gadgets.line-support ui.gadgets.panes ui.gadgets.tables
    ui.gestures ui.pens.solid
    vectors words
    ;
! #### FROM: assocs => change-at ; ! to clear ambiguity
FROM: models => change-model ; ! to clear ambiguity
IN: outline-manager
! -------------------------------------------------
SYMBOLS: file-observers i18n-pointer note-font-list options outline-pointer
    ;
! ------------------------------------------------- i18n
: i18n-hashtable ( -- hashtable ) ! or error
    i18n-pointer get value>>
    ;
: (i18n) ( string hashtable -- translated )
    ?at [
        "No translation found for following text line :"
        i18n-hashtable ?at drop print dup print
        "A template will be inserted into the translation table."
        i18n-hashtable ?at drop print nl flush
        i18n-pointer get [ [ dup dup ] dip ?set-at ] change-model
    ] unless
    ; inline
: i18n ( string -- translated )
    [ i18n-hashtable (i18n) ]
    [ drop "i18n not initialized" print flush ] recover
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
    [ error>message i18n write " : " write normalize-path print flush { } ]
    recover
    ;
: line>words ( line -- array )
    " " split [ empty? not ] filter
    ;
: report-discarded ( line number -- )
    "Line" write bl number>string write bl "discarded :" print
    print nl flush
    ;
: lines>hash ( lines -- hash )
    0 swap
    [   over
        [                                           ! count line count
            {   [ empty? [ f ] [ 1 + t ] if ]
                [ drop 1 + t ]
                [ dup empty? [ 2drop 0 ] [ 2 report-discarded 1 + ] if f ]
                }
            nth
            call( count line -- count flag )
            ]
        [                                           ! count line count error
            drop over empty? [
                3drop 0
            ] [
                report-discarded
                1 +
            ] if
            f
            ]
        recover
        ]
    filter
    swap 1 =
    [ dup last [ suffix ] keep "Line 2 appended :" print print nl flush ] when
    f swap [ drop not dup ] partition [ 2array ] 2map >hashtable nip
    ;
: lines>element ( lines -- element )
    ! [ [ { $nl } ] [ " " 2array ] if-empty ] map
    ;
: config-path ( filename -- path )
    ".kullulu" prepend-path home prepend-path
    ;
! ------------------------------------------------- file-observer
! initializes model from path using lines>
! flushes model to path using >line if dirty
! -------------------------------------------------
TUPLE: file-observer path model lines> >lines dirty
    ;
M: file-observer model-changed ( model observer -- )
    nip t swap dirty<<
    ;
: read-file ( file-observer-object -- model )
    [ path>> fetch-lines ] [ lines>>> ] bi call( lines -- value ) <model> 
    ; inline
: init-model ( file-observer-object -- model )
    [ read-file dup ] [ model<< ] [ over add-connection ] tri
    ;
: (save-data) ( file-observer-object -- )
    [ model>> value>> ] [ >lines>> call( value -- lines ) ] [ path>> ] tri
    utf8 set-file-lines
    ; inline
: save-data ( file-observer-object -- )
    dup dirty>> [ f >>dirty (save-data) ] [ drop ] if
    ;
: <file-observer> ( path lines> >lines -- file-observer-object )
    file-observer new swap >>>lines swap >>lines> swap >>path
    dup file-observers [ ?push ] change
    ;
: save-all-data ( -- ) ! to be called when finishing and also periodically
    file-observers get [ save-data ] each
    ;
! ------------------------------------------------- font-size management
: note-to-font-list ( object -- object )
    dup note-font-list [ ?push ] change
    ;
: set-gadget-font-size ( size gadget -- size )
    font>> over >>size drop
    ;
: set-label-font-size ( size content-gadget -- size )
    parent>>
    children>> [ border? ] find nip children>> [ label? ] find nip
    font>> over >>size drop
    ;
GENERIC: set-font-size ( size object -- size )

: set-noted ( font-size -- )
    note-font-list get [ set-font-size ] each drop
    ;
! ------------------------------------------------- arrow-frame
! frame with a labeled-gadget and a status bar displaying an arrow model
! -------------------------------------------------
TUPLE: arrow-frame < frame
    ;
M: arrow-frame focusable-child* ( gadget -- child )
    children>> [ labeled-gadget? ] find nip
    ;
TUPLE: display-control < label-control
    ;
M: display-control set-font-size ( size gadget -- size )
    set-gadget-font-size
    ;
: <display-control> ( model -- display-control )
    "" display-control new-label swap >>model ;
: <arrow-frame> ( table title model quot -- frame )
    <arrow> <display-control> note-to-font-list { 1 1 } <border>
    [ <labeled-gadget> ] dip
    1 2 arrow-frame new-frame { 0 0 } >>filled-cell
    swap { 0 1 } grid-add swap { 0 0 } grid-add
    ;
! ------------------------------------------------- item-editor
TUPLE: item-editor < editor
    ;
M: item-editor set-font-size ( size gadget -- size )
    [ set-gadget-font-size ] [ set-label-font-size ] bi
    ;
: jot ( editor -- index )
    control-value                               ! new
    outline-pointer get                         ! new table
    [ target-index swap over ] [ model>> ] bi   ! index new index model
    [ insert-nth ] change-model                 ! index
    ;
: jot-and-up ( editor -- )
    jot outline-pointer get swap select-row
    ;
: mark-all ( editor -- )
    { 0 0 } swap mark>> set-model
    ;
item-editor
H{
    { T{ key-down { sym "UP" } }    [ [ jot-and-up ] [ hide-glass ] bi ] }
    { T{ key-down { sym "DOWN" } }  [ [ jot drop ] [ hide-glass ] bi ] }
    ! #### { T{ key-down { sym "S+RET" } } currently does not work
    { T{ key-down { sym "RET" } }   [ [ jot drop ] [ mark-all ] bi ] }
    }
set-gestures

: <item-editor> ( -- labeled-editor )
    item-editor new-editor note-to-font-list
    COLOR: yellow [ over font>> background<< ] [ <solid> >>interior ] bi
    "item title editor" <labeled-gadget>
    ;
! ------------------------------------------------- outline-table
TUPLE: outline-table < table
    { calls model } manual-gadget manual-open? popup editor-gadget
    ;
M: outline-table set-font-size ( size gadget -- size )
    [ set-gadget-font-size ] [ set-label-font-size ] bi
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
    swap gesture>string dup [ dup empty? [ not ] when ] when
    dup "BACKSPACE" = [
        drop calls>> f swap set-model f ! f = handled ! #### dip ?
    ] [
        dup string>number [ nip update-calls f ]
        [ [ "Not a command key :" i18n write bl print flush ] when* drop t ]
        if*
    ] if
    ;
M: outline-table handle-gesture ( gesture outline-table -- ? )
    2dup get-gesture-handler [ (handle-gesture) ] [ ?update-calls ] if*
    ;
: (archive) ( table object -- )
    "Line to archive :" write bl first . flush ! ####
    dup [ selection-index>> value>> dup ] [ model>> ] bi
    [ remove-nth ] change-model
    select-row
    ; inline
: archive ( table -- )
    dup (selected-row)
    [ (archive) ] [ 2drop "No item selected" i18n print flush ] if
    ;
: finish-manager ( gadget -- )
    save-all-data close-window
    ; inline
: (?move) ( table index flag direction -- )
    swap
    [ over + rot model>> [ [ exchange ] keep ] change-model ]
    [ 3drop "No movement possible" i18n print flush ]
    if
    ;
: move-down ( table -- )
    dup [ selection-index>> value>> dup ] [ control-value length 1 - ] bi <
    1 (?move)
    ;
: move-up ( table -- )
    dup selection-index>> value>> dup 0 > -1 (?move)
    ;
: open-manual ( table -- )
    dup manual-open?>> [
        drop "Manual already open" print flush
    ] [
        t >>manual-open?
        manual-gadget>>
        "Outline Manager" "Manual" i18n " - " glue
        open-window
    ] if
    ;
: init-editor ( editor -- )
    dup control-value first empty?
    [
        "item title"                    ! editor string
        0 over length 2array swap       ! editor array string
        pick user-input* drop           ! editor array
        swap caret>> set-model          !
    ] [                                 ! editor
        mark-all
        ]
    if
    ;
: selection-rect ( table -- rectangle )
    [ [ line-height ] [ target-index ] bi * 0 swap ]
    [ [ total-width>> ] [ line-height ] bi 2 + ]
    bi
    [ 2array ] 2bi@ <rect>
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
    { T{ key-down { sym "F1" } }                    [ open-manual ] }
    { T{ key-down { sym " " } }                     [ pop-editor ] }
    }
set-gestures

: <outline-table> ( model renderer -- table )
    outline-table new-table t >>selection-required? note-to-font-list
    ;
! ------------------------------------------------- manual
TUPLE: manual < pane font stylesheet
    ;
CONSTANT: manual-default
    H{
        { default-span-style H{
            { font-name "sans-serif" }
            { font-size 24 }
            } }
        { heading-style H{
            { font-name "sans-serif" }
            { font-size 32 }
            { font-style bold }
            } }
        { default-block-style H{
            { wrap-margin 1000 } ! Pixels between left margin and right margin
            } }
        { table-content-style H{
            { wrap-margin 900 } ! Pixels between left margin and right margin
            } }
        }
: default-size ( -- number )
    manual-default default-span-style swap at font-size swap at
    ; inline
: (update-stylesheet) ( stylesheet factor key -- stylesheet factor )
    dup manual-default at font-size swap ?at    ! ss factor key size flag
    [ pick *                                    ! ss factor key new-size
        [ pick at ] dip                         ! ss factor target new-size
        font-size rot set-at
        ]
    [ 2drop ] if
    ; inline
: update-stylesheet ( gadget -- )
    [ stylesheet>> ] [ font>> size>> default-size / ] bi
    over keys [ (update-stylesheet) ] each 2drop
    ;
M: manual set-font-size ( size gadget -- size )
    [ set-gadget-font-size ] [ update-stylesheet ] [ set-label-font-size ] tri
    ;
: manual-path ( filename -- path )
    "manual" prepend-path config-path
    ;
M: manual model-changed ( model observer -- ) ! #### called by open-window ?
    "manual=>model-changed has been called" print flush ! ####
    over value>>
    over parent>>
    children>> [ border? ] find nip children>> [ label? ] find nip
    text<<
    dup stylesheet>>                                ! model observer stylesheet
    [                                               ! model observer
        [                                           ! model
            [ value>> manual-path parse-file >array print-element ]
            with-default-style
            ]
        with-pane
        ]
    with-variables
    ;
: close-manual ( gadget -- )
    f outline-pointer get manual-open?<<
    close-window
    ;
manual
H{
    { T{ key-down { sym "ESC" } }   [ close-manual ] }
    { T{ key-down { sym "F1" } }    [ close-manual ] }
    }
set-gestures

: <manual> ( -- manual )
    f manual new-pane
    <font> "sans-serif" >>name >>font note-to-font-list
    manual-default clone >>stylesheet
    f <model> [ >>model ] [ "0.txt" swap set-model ] bi
    "initial connections :" print ! #### to be removed
    dup model>> connections>> [ class-of . ] each flush ! #### to be removed
    ! #### where are connections initialized ?
    ;
! ------------------------------------------------- configuration
: process-option ( array -- )
    line>words
    [   options swap [ second string>number ] [ first ] bi
        over number>string over write bl print
        set-word-prop
        ]
    [   drop "Syntax error :" write [ bl write ] each nl
        ]
    recover
    ;
: discard-comments ( lines -- lines' )
    [ ?first CHAR: # = not ] filter
    ;
: init-i18n ( -- )
    "translations.txt" config-path
    [ discard-comments lines>hash ]
    [ [ [ "" ] 2dip 3array ] { } assoc>map concat ]
    <file-observer> init-model i18n-pointer set
    ; inline
: read-options ( -- )
    "config.txt" config-path fetch-lines
    [ empty? not ] filter discard-comments
    dup empty?
    [ "No options found" i18n ] [ "Found options :" i18n ] if print nl flush
    [ process-option ] each nl flush
    ; inline
! ------------------------------------------------- main
: init-timer ( -- )
    "save-interval" options over word-prop
    [ minutes [ save-all-data ] swap delayed-every start-timer drop ]
    [   "Option \"" write write
        "\" not found. Data will not be saved periodically." print flush ]
    if*
    ; inline
: make-outline-table ( model -- outline-table )
    trivial-renderer <outline-table>
    dup outline-pointer set ! so that item-editor can find it
    <item-editor> >>editor-gadget
    <manual> "" <labeled-gadget> >>manual-gadget
    ; inline
: make-arrow-frame ( outline-table title -- arrow-frame )
    f <model> [ pick calls<< ] keep
    [   [ number>string " " prepend "count of calls :" i18n prepend ]
        [ "Quit : Esc    Manual : F1" i18n ]
        if* ]
    <arrow-frame> ! ( table title model quot -- frame )
    ; inline
: make-outline-manager ( -- arrow-frame )
    "outline.txt" [ [ 1array ] map ] [ [ first ] map ] <file-observer>
    [ init-model make-outline-table ] [ path>> normalize-path ] bi
    make-arrow-frame
    options "font-size" word-prop [ set-noted ] when*
    ; inline
: outline-manager ( -- )
    file-observers off note-font-list off
    init-i18n read-options init-timer
    make-outline-manager [ "Outline Manager" open-window ] curry with-ui
    ;
MAIN: outline-manager
