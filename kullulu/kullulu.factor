! #### = todo
! #### for development and debugging only :
! #### refresh-all "kullulu" run
USING: accessors classes kernel prettyprint sequences ;

USING: models namespaces
    ui ui.gadgets ui.gadgets.tables
    ui.gestures vectors
    ;
IN: kullulu

SYMBOLS: fsm-members
    ;
: init-globals ( -- )
    { fsm-members } [ off ] each
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
: <table-editor> ( model -- gadget )
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
    { { "a" } { "b" } { "c" } { "d" } } <model>
    <table-editor>
    set-font-sizes
    ;
: kullulu ( -- )
    init-globals
    [ <main-gadget> dup "Kullulu" open-window ] with-ui
    ;
MAIN: kullulu
