! #### = todo

USING: ui
    ;
IN: kullulu

! refresh-all "kullulu" run

USE: ui.gadgets ! ####

: kullulu ( -- )
    [ <gadget> "Kullulu" open-window ] with-ui
    ;
MAIN: kullulu
