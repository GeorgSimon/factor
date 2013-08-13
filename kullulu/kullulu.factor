! #### = todo
! #### for development and debugging only :
! #### refresh-all "kullulu" run
USING: accessors classes kernel prettyprint sequences ;

USING: continuations io io.backend io.encodings.utf8 io.files io.pathnames
    models namespaces
    ui ui.gadgets ui.gadgets.tables
    ui.gestures vectors
    ;
IN: kullulu

SYMBOLS: fsm-members options
    ;
: init-globals ( -- )
    { fsm-members } [ off ] each
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
! ------------------------------------------------- options
: config-path ( filename -- path )
    ".kullulu" prepend-path home prepend-path
    ;
: read-options ( -- )
    "options.txt" config-path fetch-lines
    . flush
    ;
! ------------------------------------------------- fsm
! fsm = font-size management
! -------------------------------------------------
: fsm-subscribe ( object -- object )
    [ fsm-members [ ?push ] change ] keep
    ;
GENERIC: set-font-size ( size object -- size )

: set-font-sizes ( -- )
    ! options "font-size" word-prop [ set-noted ] when*
    24 fsm-members get [ set-font-size ] each
    drop
    ;
! ------------------------------------------------- table-editor
TUPLE: table-editor < table
    ;
: <table-editor> ( -- gadget )
    {   { "Das \"model\" wird später" }
        { "mit Hilfe des \"file-observers\" initialisiert." }
        { "Der Dateiname für dieses Gadget" }
        { "kann nur über eine Option geändert werden." } }
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
    init-globals read-options
    [ <main-gadget> "Kullulu" open-window ] with-ui
    ;
MAIN: kullulu
