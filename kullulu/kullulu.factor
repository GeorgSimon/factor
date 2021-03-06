! #### = todo

! #### for development and debugging only :
! #### refresh-all "kullulu" run
USING: classes prettyprint ;

USING: accessors arrays assocs calendar colors colors.constants continuations
    fry help.markup help.stylesheet
    io io.backend io.encodings.utf8 io.files io.pathnames
    io.styles
    kernel math math.parser math.rectangles models models.arrow
    namespaces parser quotations
    sequences sets simple-flat-file timers
    ui ui.gadgets ui.gadgets.borders ui.gadgets.editors ui.gadgets.glass
    ui.gadgets.labeled ui.gadgets.labels ui.gadgets.line-support
    ui.gadgets.panes ui.gadgets.scrollers ui.gadgets.tables ui.gadgets.tracks
    ui.gestures ui.pens.gradient ui.pens.solid utilities vectors words
    ;
FROM: models => change-model ; ! to clear ambiguity
FROM: namespaces => set ; ! to clear ambiguity
FROM: sets => members ; ! to clear ambiguity
IN: kullulu

SYMBOLS: archive-table fsm-subscribers
    ;
! ------------------------------------------------- fsm
! fsm = font-size management
! -------------------------------------------------
: fsm-subscribe ( object -- object )
    [ fsm-subscribers [ ?push ] change ] keep
    ;
: fsm-unsubscribe ( object -- )
    fsm-subscribers [ remove ] change
    ;
GENERIC: set-font-size ( size object -- size )

M: gadget set-font-size ( size object -- size )
    [ dup ] dip font>> size<<
    ;
M: labeled-gadget set-font-size ( size object -- size )
    get-label font>> over >>size drop
    ;
: set-font-sizes ( -- )
    "font-size" get-option [
        fsm-subscribers get [ set-font-size ] each drop
    ] when*
    ;
! ------------------------------------------------- item-editor
TUPLE: item-editor < editor
    ;
: <item-editor> ( -- labeled-editor )
    item-editor new-editor fsm-subscribe
    COLOR: yellow [ over font>> background<< ] [ <solid> >>interior ] bi
    "Close editor : Esc"
    "Insert : ↩ or ⇧↩"
    "Insert and close editor : ↓ or ↑"
    3array [ i18n ] map " -------- " join
    <labeled-gadget> fsm-subscribe
    ;
: editor-owner ( editor -- owner )
    parent>> parent>> owner>>
    ;
: (jot) ( new table -- index )
    [ target-index swap over ] [ model>> ] bi   ! index new index model
    [ insert-nth ] change-model                 ! index
    ;
: jot ( editor -- index )
    [ control-value ] [ editor-owner ] bi (jot)
    ;
: jot-and-go ( editor -- )
    [ editor-owner ] [ jot ] bi select-row
    ;
: mark-all ( editor -- )
    { 0 0 } swap mark>> set-model
    ;
item-editor
H{
    { T{ key-down { sym "DOWN" } }  [ [ jot drop ] [ hide-glass ] bi ] }
    { T{ key-down { sym "UP" } }    [ [ jot-and-go ] [ hide-glass ] bi ] }
    { T{ key-down { sym "RET" } }   [ [ jot drop ] [ mark-all ] bi ] }
    { T{ key-down { mods { S+ } } { sym "RET" } }
                                    [ [ jot-and-go ] [ mark-all ] bi ] }
    }
set-gestures
: init-editor ( editor -- )
    dup control-value first empty? [
        "new item line" i18n            ! editor string
        0 over length 2array swap       ! editor array string
        pick user-input* drop           ! editor array
        swap caret>> set-model          !
    ] [                                 ! editor
        mark-all
    ] if
    ;
! -------------------------------------------------
: init-pref-dim ( gadget -- gadget' )
    "width" "height" [ get-option ] bi@ 2array >>pref-dim
    ;
! ------------------------------------------------- manual
SYMBOL: font-scale
TUPLE: manual < pane stylesheet
    ;
M: manual ungraft* ( gadget -- )
    [ fsm-unsubscribe ] [ parent>> fsm-unsubscribe ] bi
    ;
: adjust ( stylesheet size style scale -- stylesheet' size )
    pick * font-size rot set-at
    ;
M: manual set-font-size ( size gadget -- size )
    stylesheet>> swap over keys
    [ pick at font-scale over ?at [ adjust ] [ 2drop ] if ] each nip
    ;
: path>element ( path -- element )
    [ parse-file >array ] [ error>> error>message " : " rot 3array ] recover
    ; inline
M: manual model-changed ( model manual -- ) ! also called by open-window
    [ value>> manual-path ] dip dup stylesheet>>
    over dim>> . flush ! ####
    [ [ [ path>element print-element ] with-default-style ] with-pane ]
    with-variables
    ;
: switch ( manual-gadget filename -- )
    swap model>> set-model
    ;
M: manual handle-gesture ( gesture manual -- ? )
    2dup get-gesture-handler [
        call( manual -- ) drop f
    ] [
        swap gesture>string dup string>number [
            ".txt" append switch f
        ] [
            ?invalid. drop t
        ] if
    ] if*
    ;
manual
H{
    { T{ key-down { sym "ESC" } }   [ close-window ] }
    { T{ key-down { sym "F1" } }    [ "F1.txt" switch ] }
    { T{ key-down { sym " " } }     [ "editor.txt" switch ] }
    }
clone set-gestures

: page-theme ( gadget -- )
    { T{ rgba f 0.8 1.0 1.0 1.0 } T{ rgba f 0.8 0.8 1.0 1.0 } } <gradient>
    >>interior drop
    ; inline
: <manual> ( filename -- gadget )
    f manual new-pane fsm-subscribe dup page-theme
    swap <model> >>model
    H{
        { default-block-style H{
            { wrap-margin 400 } ! Pixels between left and right margin
            } }
        { default-span-style H{
            { font-name "sans-serif" }
            { font-scale 1 }
            } }
        { heading-style H{
            { font-name "sans-serif" }
            { font-scale 4/3 }
            { font-style bold }
            } }
        }
    >>stylesheet
    <scroller>
    "Close Manual : Esc    Help : F1" i18n <labeled-gadget>
    fsm-subscribe init-pref-dim set-font-sizes
    ;
! ------------------------------------------------- kullulu-renderer
SINGLETON: kullulu-renderer

M: kullulu-renderer row-columns
    drop
    ;
M: kullulu-renderer column-titles
    drop "Item Labeling" i18n 1array
    ;
! ------------------------------------------------- editor-track
TUPLE: editor-track < track
    ;
: <editor-track> ( -- track )
    vertical editor-track new-track
    ;
M: editor-track focusable-child* ( gadget -- child )
    children>> first
    ;
! ------------------------------------------------- table-editor
TUPLE: table-editor < table calls popup editor-gadget
    ;
: <list-table> ( constructor file-option -- labeled-gadget )
    get-option "data-dir" get-option prepend-path swap      ! path constr
    [ [ 1array ] map ] pick [ [ first ] map ] <persistent>  ! path constr model
    kullulu-renderer rot call( m r -- t ) fsm-subscribe     ! path table
    <scroller>
    swap normalize-path <labeled-gadget> fsm-subscribe      ! gadget
    init-pref-dim
    ;
: <table-editor> ( -- labeled-gadget )
    [   table-editor new-table
        t >>selection-required?
        <item-editor> >>editor-gadget
        ]
    "list-file" <list-table>
    ;
: <archive-table> ( -- labeled-gadget )
    [ <table> dup archive-table set ] "archive-file" <list-table>
    ;
: (handle-gesture) ( gesture table-editor handler -- f )
    over calls>> value>> [ 1 ] unless*
    [ 2dup call( table-editor -- ) ] times
    drop f swap calls>> set-model drop f
    ;
: update-calls ( table-editor number -- )
    swap calls>> [ [ 10 * + 100 mod ] when* ] change-model
    ;
: ?update-calls ( gesture table-editor -- propagate-flag )
    swap gesture>string ! dup [ dup empty? [ not ] when ] when ! #### better ?
    dup "BACKSPACE" = [
        drop calls>> f swap set-model f ! f = handled ! #### dip ?
    ] [
        dup string>number [ nip update-calls f ]
        [ ?invalid. drop t ]
        if*
    ] if
    ;
M: table-editor handle-gesture ( gesture table-editor -- ? )
    2dup get-gesture-handler [ (handle-gesture) ] [ ?update-calls ] if*
    ;
: (archive) ( table-editor selected-row -- )
    0 archive-table get model>> [ insert-nth ] change-model
    dup [ selection-index>> value>> dup ] [ model>> ] bi
    [ remove-nth ] change-model
    select-row
    ; inline
: archive ( table-editor -- )
    dup (selected-row)
    [ (archive) ] [ 2drop "No item selected" i18n print flush ] if
    ;
: go-down ( table-editor -- )
    dup renderer>> column-titles length "" <repetition>
    over selection-index>> value>> [        ! table new old-i
        1 +
        pick control-value length over = [  ! table new i
            pick (selected-row) drop        ! table new i value
            pick = [                        ! table new i
                3dup rot model>>            ! table new i new i model
                [ insert-nth ] change-model ! table new i
            ] unless                        ! table new i
        ] when                              ! table new i
        nip select-row
    ] [                                     ! table new
        over (jot) select-row
    ] if*
    ;
: ?move ( table-editor index flag direction -- )
    swap
    [ over + rot model>> [ [ exchange ] keep ] change-model ]
    [ 3drop "No movement possible" i18n print flush ]
    if
    ;
: move-down ( table-editor -- )
    dup [ target-index dup ] [ control-value length 1 - ] bi < 1 ?move
    ;
: move-up ( table-editor -- )
    dup target-index dup 0 > -1 ?move
    ;
: open-manual ( table-editor -- )
    [ manual "gestures" word-prop ] dip
    class-of "gestures" word-prop
    [ keys ]
    [ ]
    [ values duplicates members ]
    tri
    [                                   ! manual-g keys editor-g command
        pick                            ! manual-g keys editor-g command keys
        swap                            ! manual-g keys editor-g keys command
        '[                              ! manual-g keys editor-g key
            over at _ =                 ! manual-g keys editor-g =
            ]
        filter                          ! manual-g keys editor-g pointers
        [ key-down? ] partition first   ! manual-g keys editor-g targets string
        ".txt" append                   ! manual-g keys editor-g targets fname
        \ switch 2array >quotation      ! manual-g keys editor-g targets quot
        swap                            ! manual-g keys editor-g quot targets
        [ pick ] 2dip       ! manual-g keys editor-g manual-g quot targets
        [ swap over ] dip   ! manual-g keys editor-g quot manual-g quot targets
        [                   ! manual-g keys editor-g quot manual-g quot target
            pick set-at     ! manual-g keys editor-g quot manual-g
            over            ! manual-g keys editor-g quot manual-g quot
            ]
        each                ! manual-g keys editor-g quot manual-g quot
        3drop               ! manual-g keys editor-g
        ]
    each
    3drop
    "0.txt" <manual> "Kullulu" "Manual" i18n " - " glue open-window
    ;
: selection-rect ( table-editor -- rectangle )
    [ [ line-height ] [ target-index ] bi * 0 swap ]
    [ [ total-width>> ] [ line-height ] bi 2 + ]
    bi
    [ 2array ] 2bi@ <rect>
    ;
: pop-editor ( table-editor -- )
    dup editor-gadget>> dup content>> init-editor
    over selection-rect [ show-popup ] curry [ request-focus ] bi
    ;
: retrieve ( table-editor -- )
    0 archive-table get
    [   [ control-value nth ] [ model>> [ remove-nth ] change-model ] 2bi
        over (jot) select-row ]
    [ 4drop "Archive is empty" i18n print flush ]
    recover
    ;
: save-and-close ( table-editor -- )
    save-persistents close-window
    ;
table-editor
H{
    { T{ key-down { sym "DOWN" } }                  [ go-down ] }
    { T{ key-down { sym "DELETE" } }                [ archive ] }
    { "archive"                                     [ archive ] }
    { T{ key-down { mods { C+ } } { sym "DOWN" } }  [ move-down ] }
    { "move-down"                                   [ move-down ] }
    { T{ key-down { mods { C+ } } { sym "UP" } }    [ move-up ] }
    { "move-up"                                     [ move-up ] }
    { T{ key-down { sym "F1" } }                    [ open-manual ] }
    { T{ key-down { sym " " } }                     [ pop-editor ] }
    { "retrieve"                                    [ retrieve ] }
    { T{ key-down { sym "ESC" } }                   [ save-and-close ] }
    }
clone set-gestures

: (insert-key) ( hashtable array -- hashtable' )
    [ second ] [ first ] bi
    dup write bl over print             ! ht letter key
    pick keys [ over = ] find           ! ht letter key i elt
    2nip [                              ! ht letter elt
        pick at                         ! ht letter value
        key-down new rot >>sym          ! ht value new-key
        pick set-at                     ! ht
    ] [
        drop
    ] if*
    ;
: insert-key ( hashtable array -- hashtable' )
    [ (insert-key) ] [ syntax-error. ] recover
    ;
: insert-keys ( arrays -- )
    table-editor "gestures" [ swap [ insert-key ] each ] change-word-prop
    nl flush
    ;
! ------------------------------------------------- main
: init-options ( -- )
    {   { "kullulu"             "data-dir" }
        { "archive.txt"         "archive-file" }
        { "command-keys.txt"    "keys-file" }
        { "list.txt"            "list-file" }
        { "options.txt"         "options-file" }
        { 500                   "height" }
        { 5/4                   "quota" }
        { 450                   "width" }
        }
    [ [ options ] dip [ first ] [ second ] bi set-word-prop ] each
    ! #### if you want to process any command line arguments then here
    ; inline
: init-timer ( -- )
    "save-interval" dup get-option [
        minutes [ save-persistents ] swap delayed-every start-timer drop
    ] [
        "Option not found :" i18n write bl .
        "Periodic data saving disabled." i18n print flush
    ] if*
    ; inline
: get-table ( labeled-gadget -- table )
    content>> viewport>> gadget-child
    ;
: value>message ( number/f -- string )
    [ number>string " " prepend "count of calls :" i18n prepend ]
    [ "Quit : Esc    Manual : F1" i18n ]
    if*
    ;
: <arrow-bar> ( labeled-editor -- labeled-editor label-control )
    f <model> dup pick get-table calls<<
    [ value>message ] <arrow> <label-control> fsm-subscribe
    { 1 1 } <border>
    COLOR: LightCyan <solid> >>interior
    ; inline
: <main-gadget> ( -- gadget )
    fsm-subscribers off
    <editor-track>
    <table-editor> <arrow-bar>
    [ "quota" get-option track-add ] dip f track-add
    <archive-table> 1 track-add
    set-font-sizes
    ;
: kullulu ( -- )
    ".kullulu" init-background init-options
    "keys-file" "options-file"
    [ get-option config-path fetch-lines drop-comments [ line>words ] map ] bi@
    process-options insert-keys
    init-timer
    [ <main-gadget> "Kullulu" open-window ] with-ui
    ;
MAIN: kullulu
