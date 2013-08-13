! #### = todo
! #### for development and debugging only :
! #### refresh-all "kullulu" run
USING: accessors classes kernel prettyprint sequences ;

USING: models
    ui ui.gadgets.status-bar ui.gadgets ui.gadgets.tables ui.gadgets.worlds
    ;
IN: kullulu

TUPLE: table-editor < table
    ;
: <table-editor> ( -- gadget )
    { { "a" } { "b" } { "c" } { "d" } } <model>
    trivial-renderer table-editor new-table
    ;
! ------------------------------------------------- main
: <main-gadget> ( -- gadget )
    <table-editor>
    ;
: kullulu ( -- )
    [ <main-gadget> "Kullulu" open-status-window ] with-ui
    ;
MAIN: kullulu
