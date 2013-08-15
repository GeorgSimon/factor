! #### = todo

! #### for development and debugging only :
! #### refresh-all "kullulu" run
USING: classes ;

USING: accessors arrays assocs colors.constants continuations
    io io.backend io.encodings.utf8 io.files io.pathnames
    kernel math math.parser models models.arrow namespaces prettyprint
    sequences simple-flat-file splitting
    ui ui.gadgets ui.gadgets.borders ui.gadgets.labeled ui.gadgets.labels
    ui.gadgets.scrollers ui.gadgets.tables ui.gadgets.tracks
    ui.gestures ui.pens.solid vectors words
    ;
FROM: models => change-model ; ! to clear ambiguity
IN: kullulu

SYMBOLS: fsm-members options persistents translations
    ;
! ------------------------------------------------- utilities
: error>message ( error -- string )
    ! Factor errors are strings in Windows and tuples in Linux
    [ message>> ] [ drop ] recover
    ;
: print-file-error ( path error -- )
    [ normalize-path ] dip error>message " : " append prepend print flush
    ;
: fetch-lines ( path -- lines )
    [ utf8 file-lines ] [ print-file-error { } ] recover
    ;
: line>words ( line -- array )
    " " split [ empty? not ] filter
    ;
: config-path ( filename -- path )
    options "config-dir" word-prop prepend-path home prepend-path
    ;
: data-path ( filename -- path )
    options "data-dir" word-prop prepend-path
    ;
! ------------------------------------------------- i18n
: store-translation ( seq hashtable translation index -- seq hashtable' )
    swap                        ! seq hashtable index value
    [ 1 - pick nth ] dip        ! seq hashtable key value
    swap pick set-at
    ; inline
: lines>translations ( lines -- hashtable )
    H{ } clone over
    [ dup 3 mod 2 = [ store-translation ] [ 2drop ] if ] each-index nip
    ; inline
: translations>lines ( hashtable -- lines )
    [ [ "" ] 2dip 3array ] { } assoc>map concat
    ; inline
: print-?translated ( line -- )
    translations get value>> ?at drop print
    ;
: extend-translations ( line -- line )
    translations get [ over dup pick set-at ] change-model
    "A template has been inserted into the translation table."
    print-?translated
    ; inline
: i18n ( line -- translation/line )
    translations get [
        value>> ?at [
            nl
            "No translation found for following text line :" print-?translated
            dup .
            extend-translations
            nl flush
        ] unless
    ] when* ! #### only needed when run from listener
    ;
! ------------------------------------------------- persistent models
! persistent models are
! - initialized from path using lines>
! - flushed to path using >line if dirty
! -------------------------------------------------
TUPLE: persistent path model >lines dirty
    ;
: <persistent> ( lines> path >lines -- model )
    persistent new swap >>>lines swap >>path            ! lines> object
    dup persistents [ ?push ] change                    ! lines> object
    dup path>> fetch-lines rot call( lines -- value )   ! object value
    <model> 2dup add-connection
    [ swap model<< ] keep
    ;
M: persistent model-changed ( model persistent -- )
    t swap dirty<< drop
    ;
: (save-persistent) ( object -- )
    f over dirty<<
    [ model>> value>> ] [ >lines>> call( value -- lines ) ] [ path>> ] tri
    utf8 set-file-lines
    ; inline
: save-persistent ( object -- )
    dup dirty>> [ (save-persistent) ] [ drop ] if
    ;
: save-persistents ( -- ) ! to be called when finishing and also periodically
    persistents get [ save-persistent ] each
    ;
! ------------------------------------------------- options
: option. ( value name -- value name )
    over number>string over write bl print
    ; inline
: process-option ( line -- )
    line>words
    [   options swap
        [ second string>number ] [ first ] bi option.
        set-word-prop
        ]
    [   drop "Syntax error :" i18n write [ bl write ] each nl
        ]
    recover
    ; inline
: process-options ( lines -- )
    drop-comments
    dup empty? [
        "No options found" i18n
    ] [
        "Found options :" i18n
    ] if
    print nl
    [ process-option ] each nl flush
    ; inline
! ------------------------------------------------- fsm
! fsm = font-size management
! -------------------------------------------------
: fsm-subscribe ( object -- object )
    [ fsm-members [ ?push ] change ] keep
    ;
GENERIC: set-font-size ( size object -- size )

M: label-control set-font-size ( size object -- size )
    [ dup ] dip font>> size<<
    ;
M: table set-font-size ( size object -- size )
    [ dup ] dip font>> size<<
    ;
: set-font-sizes ( -- )
    options "font-size" word-prop [
        fsm-members get [ set-font-size ] each drop
    ] when*
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
: <list-table> ( constructor file-option -- labeled-gadget )
    options swap word-prop data-path swap                   ! path constr
    [ [ 1array ] map ] pick [ [ first ] map ] <persistent>  ! path constr model
    trivial-renderer rot call( m r -- t ) fsm-subscribe     ! path table
    t >>selection-required? ! saves the user one key press  ! path table
    <scroller>
    swap normalize-path <labeled-gadget> fsm-subscribe      ! gadget
    options "width" word-prop
    options "height" word-prop
    2array >>pref-dim
    ;
: <archive-table> ( -- labeled-gadget )
    [ <table> ] "archive-file" <list-table>
    ;
TUPLE: table-editor < table calls
    ;
: <table-editor> ( -- labeled-gadget )
    [ table-editor new-table ] "list-file" <list-table>
    ;
M: labeled-gadget set-font-size ( size object -- size )
    children>> [ border? ] find nip children>> [ label? ] find nip
    font>> over >>size drop
    ;
: get-table ( labeled-gadget -- table )
    content>> dup class-of . viewport>> gadget-child
    ;
: (handle-gesture) ( gesture table-editor handler -- f )
    over calls>> value>> [ 1 ] unless*
    [ 2dup call( table-editor -- ) ] times
    drop f swap calls>> set-model drop f
    ;
: update-calls ( table-editor number -- )
    swap calls>> [ [ 10 * + 100 mod ] when* ] change-model
    ;
: ?invalid. ( string/f -- )
    [ "Not a command key :" i18n write bl print flush ] when*
    ;
: ?update-calls ( gesture table-editor -- propagate-flag )
    swap gesture>string dup [ dup empty? [ not ] when ] when
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
: target-index ( table -- index )
    selection-index>> value>> [ 0 ] unless*
    ;
: ?move ( table index flag direction -- )
    swap
    [ over + rot model>> [ [ exchange ] keep ] change-model ]
    [ 3drop "No movement possible" i18n print flush ]
    if
    ;
: move-down ( table -- )
    dup [ target-index dup ] [ control-value length 1 - ] bi < 1 ?move
    ;
: move-up ( table -- )
    dup target-index dup 0 > -1 ?move
    ;
: save-and-close ( table-editor -- )
    save-persistents close-window
    ;
table-editor
H{
    { T{ key-down { sym "t" } }                     [ move-down ] }
    { T{ key-down { mods { C+ } } { sym "DOWN" } }  [ move-down ] }
    { T{ key-down { mods { C+ } } { sym "UP" } }    [ move-up ] }
    { T{ key-down { sym "h" } }                     [ move-up ] }
    { T{ key-down { sym "ESC" } }                   [ save-and-close ] }
    }
set-gestures

! ------------------------------------------------- main
: init-options ( -- )
    {   { ".kullulu"            "config-dir" }
        { "kullulu"             "data-dir" }
        { "archive.txt"         "archive-file" }
        { "list.txt"            "list-file" }
        { "options.txt"         "options-file" }
        { "translations.txt"    "translations-file" }
        { 500                   "height" }
        { 5/4                   "quota" }
        { 450                   "width" }
        }
    [ [ options ] dip [ first ] [ second ] bi set-word-prop ] each
    ! #### if you want to process any command line arguments then here
    ; inline
: init-i18n ( -- )
    [ lines>translations ]
    options "translations-file" word-prop config-path
    [ translations>lines ]
    <persistent> translations set
    ; inline
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
    fsm-members off
    <editor-track>
    <table-editor> <arrow-bar>
    [ options "quota" word-prop track-add ] dip f track-add
    <archive-table> 1 track-add
    set-font-sizes
    ;
: kullulu ( -- )
    init-options
    persistents off
    init-i18n
    options "options-file" word-prop config-path fetch-lines process-options
    [ <main-gadget> "Kullulu" open-window ] with-ui
    ;
MAIN: kullulu
