! USE: outline-manager refresh-all "outline-manager" test


USING: accessors classes kernel outline-manager sequences tools.test
    ui.gadgets.labeled ui.gestures
    ;
IN: outline-manager.tests

: test-gadget ( -- test-gadget )
    "outline.txt" <table-model> [ <file-model> ] keep <outline-table>
    ;
: test-table ( -- test-table )
    <table-model> (outline-table)
    ;

{ labeled-gadget }
[ test-gadget class-of ]
unit-test

{ outline-table }
[ test-gadget content>> class-of ]
unit-test

{ [ finish-outline ] }
[ T{ key-down { sym "ESC" } } test-table get-gesture-handler ]
unit-test


USING: fry prettyprint quotations see ;
