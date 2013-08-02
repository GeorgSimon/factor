! USE: outline-manager refresh-all "outline-manager" test

USING: accessors assocs classes namespaces outline-manager sequences tools.test
    ui.gestures words
    ;

{ outline-table }
[ make-outline-manager class-of ]
unit-test

{ outline-table }
[ global-font-size get observers>> [ class-of ] map first ]
unit-test

{ [ finish-manager ] }
[ T{ key-down { sym "ESC" } } outline-table "gestures" word-prop at ]
unit-test

USING: prettyprint
    ;
