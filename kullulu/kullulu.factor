! #### = todo
! #### for development and debugging only :
! #### refresh-all "kullulu" run
USING: classes io prettyprint ;

USING: accessors arrays kernel models
    ui ui.gadgets.status-bar ui.gadgets.tables ui.gadgets.worlds
    ;
IN: kullulu

: <main-gadget> ( -- gadget )
    { { "a" } { "b" } { "c" } { "d" } } <model> trivial-renderer <table>
    ;
: kullulu ( -- )
    [
        "status bar text" <main-gadget>
        [ "Kullulu" open-status-window ] [ show-status ] bi
        ]
    with-ui
    ;
MAIN: kullulu
