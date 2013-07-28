! Copyright (C) 2013 Georg Simon.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays colors.constants continuations fry
    io io.backend io.files io.encodings.utf8
    kernel math math.rectangles models namespaces sequences
    ui ui.gadgets.borders ui.gadgets.glass ui.gadgets ui.gadgets.editors
    ui.gadgets.labeled ui.gadgets.labels ui.gadgets.line-support
    ui.gadgets.tables
    ui.gestures ui.pens.solid
    ;
FROM: models => change-model ; ! to clear ambiguity
IN: outline-manager

USE: prettyprint ! todo for development and debugging only

SYMBOL: current-file
SYMBOL: outline-model ! for M: item-editor prefix-item
! ----------------------------------------------- utilities
: error>message ( error -- string )
    ! Factor errors are strings in Windows and tuples in Linux
    [ message>> ] [ drop ] recover
    ;
: default-font ( gadget -- ) 16 swap font>> size<<
    ;
: <labeled-gadget-with-default-font> ( gadget title -- gadget' )
    <labeled-gadget>
    dup children>> [ border? ] find nip
    children>> [ label? ] find nip
    default-font
    ;
! ----------------------------------------------- item-editor
TUPLE: item-editor < editor
    ;
GENERIC: prefix-item ( editor -- )
M: item-editor prefix-item
    [ control-value outline-model get [ swap prefix ] change-model ]
    [ hide-glass ]
    bi
    ;
item-editor
H{
    { T{ key-down { sym "RET" } }   [ prefix-item ] }
    }
set-gestures
: <item-editor> ( -- editor )
    item-editor new-editor
    dup default-font
    COLOR: yellow [ over font>> background<< ] [ <solid> >>interior ] bi
    "new item line" <labeled-gadget-with-default-font>
    ;
! ----------------------------------------------- outline-table
TUPLE: outline-table < table popup
    ;
GENERIC: init-selection ( table -- )
M: outline-table init-selection
    dup dup
    selection-index>> [ [ ] [ 0 ] if* ] change-model
    selection-index>> value>> select-row
    ;
GENERIC: finish-outline ( table -- )
M: outline-table finish-outline
    close-window
    ;
GENERIC: outline-index ( table -- index )
M: outline-table outline-index
    selection-index>> value>> [ 0 ] unless*
    ;
GENERIC: selection-rect ( table -- rectangle )
M: outline-table selection-rect
    [ [ line-height ] [ outline-index ] bi * 0 swap ]
    [ [ total-width>> ] [ line-height ] bi 2 + ]
    bi
    [ 2array ] 2bi@ <rect>
    ;
GENERIC: jot ( table -- )
M: outline-table jot
    <item-editor>
    over selection-rect '[ _ show-popup ]
    [ request-focus ]
    bi
    ;
outline-table
H{
    { T{ key-down { sym "ESC" } }   [ finish-outline ] }
    { T{ key-down { sym " " } }     [ jot ] }
    }
set-gestures
: <outline-table> ( -- table )
    outline-model get trivial-renderer outline-table new-table
    t >>selection-required? ! better behaviour before first cursor move
    dup default-font
    current-file get normalize-path <labeled-gadget-with-default-font>
    { 333 666 } >>pref-dim
    ;
! ----------------------------------------------- main
: init-outline-model ( -- )
    current-file get
    [ utf8 file-lines [ empty? not ] filter [ 1array ] map ]
    [ error>message " : " append write print flush { } ]
    recover
    <model> outline-model set
    ;
: outline-manager ( -- )
    "outline.txt" current-file set
    init-outline-model
    [ <outline-table> "Outline Manager" open-window ] with-ui
    ;
MAIN: outline-manager
