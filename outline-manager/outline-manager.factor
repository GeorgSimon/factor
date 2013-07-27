! Copyright (C) 2013 Georg Simon.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays colors.constants continuations fry
    io io.files io.encodings.utf8 kernel math.rectangles models
    namespaces sequences
    ui ui.gadgets.glass ui.gadgets ui.gadgets.editors
    ui.gadgets.labeled ui.gadgets.tables ui.gestures ui.pens.solid
    ;
FROM: models => change-model ; ! to clear ambiguity
IN: outline-manager

USE: prettyprint ! todo for debugging only

SYMBOL: outline-model
! ---------
! utilities
! ---------
: error>message ( error -- string )
    ! Factor errors are strings in Windows and tuples in Linux
    [ message>> ] [ drop ] recover
    ;
: default-font ( gadget -- gadget ) 16 over font>> size<<
    ;
! --------
! renderer
! --------
SINGLETON: short-line ! renderer
M: short-line row-columns ( line object -- line )
    drop
    ;
! -----------
! item-editor
! -----------
TUPLE: item-editor < editor
    ;
GENERIC: make-item ( editor -- )
M: item-editor make-item
    [ control-value outline-model get [ swap prefix ] change-model ]
    [ hide-glass ]
    bi
    ;
item-editor
H{
    { T{ key-down { sym "RET" } }   [ make-item ] }
    }
set-gestures
: <item-editor> ( -- editor )
    item-editor new-editor
    default-font
    COLOR: yellow [ over font>> background<< ] [ <solid> >>interior ] bi
    "new item line" <labeled-gadget>
    ;
! -------------
! outline-table
! -------------
TUPLE: outline-table < table popup
    ;
GENERIC: init-selection ( table -- )
M: outline-table init-selection
    selection-index>> [ [ ] [ 0 ] if* ] change-model
    ;
GENERIC: finish-outline ( table -- )
M: outline-table finish-outline
    close-window
    ;
GENERIC: jot ( table -- )
M: outline-table jot
    <item-editor>
    { 0 0 } { 0 0 } <rect> '[ _ show-popup ]
    [ request-focus ]
    bi
    ;
outline-table
H{
    { gain-focus                    [ init-selection ] }
    { T{ key-down { sym "ESC" } }   [ finish-outline ] }
    { T{ key-down { sym " " } }     [ jot ] }
    }
set-gestures
: <outline-table> ( model renderer -- table )
    outline-table new-table
    { 333 666 } >>pref-dim
    default-font
    ;
! ----
! main
! ----
: outline-manager ( -- )
    "outline.txt"
    [ utf8 file-lines [ empty? not ] filter [ 1array ] map ]
    [ error>message " : " append write print flush { } ]
    recover
    <model> outline-model set
    [
        outline-model get short-line <outline-table>
        "Outline Manager"
        open-window
        ]
    with-ui
    ;
MAIN: outline-manager
