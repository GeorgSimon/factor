! USE: outline-manager refresh-all "outline-manager" test

USING: accessors assocs classes models namespaces
    outline-manager sequences tools.test
    ui.gadgets.labeled ui.gestures words
    ;

{ labeled-gadget }
[ make-outline-manager class-of ]
unit-test

{ outline-table }
[ global-font-size get observers>> [ class-of ] map first ]
unit-test

{ [ finish-manager ] }
[ T{ key-down { sym "ESC" } } outline-table "gestures" word-prop at ]
unit-test

{ model }
[ outline-file get model>> class-of ]
unit-test

USING: prettyprint
    ;
