! #### = todo
! #### for development and debugging only :
! #### refresh-all "kullulu" run
USING: accessors classes kernel prettyprint sequences ;

USING: models namespaces
    ui ui.gadgets.status-bar ui.gadgets ui.gadgets.tables ui.gadgets.worlds
    ui.gestures vectors
    ;
IN: kullulu

SYMBOLS: fsm-members
    ;
! ------------------------------------------------- fsm
! fsm = font-size management
! -------------------------------------------------
: fsm-subscribe ( object -- object )
    [ fsm-members [ ?push ] change ] keep
    ;
! ------------------------------------------------- table-editor
TUPLE: table-editor < table
    ;
: <table-editor> ( model -- gadget )
    trivial-renderer table-editor new-table fsm-subscribe
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
    ;
: kullulu ( -- )
    [ <main-gadget> "Kullulu" open-status-window ] with-ui
    ;
MAIN: kullulu
