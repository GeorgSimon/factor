! #### = todo
! #### for development and debugging only :
! #### refresh-all "kullulu" run
USING: classes ;

USING: accessors arrays assocs continuations
    io io.backend io.encodings.utf8 io.files io.pathnames
    kernel math math.parser models namespaces prettyprint sequences splitting
    ui ui.gadgets ui.gadgets.tables
    ui.gestures vectors words
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
: discard-comments ( lines -- lines' )
    [ CHAR: # over index [ head ] when* ] map
    ;
: line>words ( line -- array )
    " " split [ empty? not ] filter
    ;
! ------------------------------------------------- i18n
: store-translation ( seq hashtable translation index -- seq hashtable' )
    swap                        ! seq hashtable index value
    [ 1 - pick nth ] dip        ! seq hashtable key value
    swap pick set-at
    ; inline
: (init-translations) ( lines hashtable lines -- hashtable' )
    [ dup 3 mod 2 = [ store-translation ] [ 2drop ] if ] each-index nip
    ; inline
: init-translations ( lines -- hashtable )
    H{ } clone over (init-translations)
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
    translations get value>> ?at [
        nl
        "No translation found for following text line :" print-?translated
        dup .
        extend-translations
        nl flush
    ] unless
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
    discard-comments [ empty? not ] filter
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

: set-font-sizes ( -- )
    options "font-size" word-prop [
        fsm-members get [ set-font-size ] each drop
    ] when*
    ;
! ------------------------------------------------- table-editor
TUPLE: table-editor < table
    ;
: data-path ( filename -- path )
    options "data-dir" word-prop prepend-path
    ;
: <table-editor> ( -- gadget )
    [ [ 1array ] map ]
    options "list-file" word-prop data-path
    [ [ first ] map ]
    <persistent> trivial-renderer table-editor new-table fsm-subscribe
    ;
M: table-editor set-font-size ( size object -- size )
    [ dup ] dip font>> size<<
    ;
table-editor
H{
    { T{ key-down { sym "ESC" } }   [ save-persistents close-window ] }
    }
set-gestures

! ------------------------------------------------- main
: init-options ( -- )
    {   { ".kullulu"          "config-dir" }
        { "kullulu"           "data-dir" }
        { "options.txt"       "options-file" }
        { "translations.txt"  "translations-file" }
        { "list.txt"          "list-file" }
        }
    [ [ options ] dip [ first ] [ second ] bi set-word-prop ] each
    ! #### if you want to process any command line arguments then here
    ; inline
: config-path ( filename -- path )
    options "config-dir" word-prop prepend-path home prepend-path
    ;
: init-i18n ( -- )
    [ init-translations ]
    options "translations-file" word-prop config-path
    [ translations>lines ]
    <persistent> translations set
    ; inline
: <main-gadget> ( -- gadget )
    fsm-members off
    <table-editor>
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
