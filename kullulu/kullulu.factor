! #### = todo
! #### for development and debugging only :
! #### refresh-all "kullulu" run
USING: classes ;

USING: accessors assocs continuations
    io io.backend io.encodings.utf8 io.files io.pathnames
    kernel math math.parser models namespaces prettyprint sequences splitting
    ui ui.gadgets ui.gadgets.tables
    ui.gestures vectors words
    ;
FROM: models => change-model ; ! to clear ambiguity
IN: kullulu

SYMBOLS: fsm-members options translations
    ;
: config-path ( filename -- path )
    ".kullulu" prepend-path home prepend-path
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
: init-translations ( lines -- )
    H{ } clone over (init-translations) <model> translations set
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
        dup . extend-translations
        nl flush
    ] unless
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
: <table-editor> ( -- gadget )
    {   { "Das \"model\" für den \"table-editor\" wird später" }
        { "mit Hilfe des \"file-observers\" initialisiert." }
        { "Der Dateiname für dieses Gadget" }
        { "kann nur über eine Option geändert werden." }
        { "Diese Option ist noch nicht implementiert." } }
    <model>
    trivial-renderer table-editor new-table fsm-subscribe
    ;
M: table-editor set-font-size ( size object -- size )
    [ dup ] dip font>> size<<
    ;
table-editor
H{
    { T{ key-down { sym "ESC" } }   [ close-window ] }
    }
set-gestures

! ------------------------------------------------- main
: <main-gadget> ( -- gadget )
    <table-editor>
    set-font-sizes
    ;
: kullulu ( -- )
    fsm-members off
    "translations.txt" config-path fetch-lines init-translations
    "options.txt" config-path fetch-lines process-options
    [ <main-gadget> "Kullulu" open-window ] with-ui
    ;
MAIN: kullulu
