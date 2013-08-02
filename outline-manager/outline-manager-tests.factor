! USE: outline-manager refresh-all "outline-manager" test

USING: assocs outline-manager tools.test ui.gestures words
    ;

{ [ finish-manager ] }
[ T{ key-down { sym "ESC" } } outline-table "gestures" word-prop at ]
unit-test

USING: prettyprint
    ;
