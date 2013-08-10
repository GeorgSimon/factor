USE: tools.test

USING: accessors arrays classes io.pathnames
    math.rectangles models namespaces outline-manager sequences
    ui.gadgets ui.gadgets.frames ui.gadgets.grids
    ;
FROM: models => change-model ; ! to clear ambiguity
IN: outline-manager.tests

USING: libc kernel
    ;
! "touch outline.txt" system drop

! ------------------------------------------------- file-observer
! TUPLE: file-observer path model lines> >lines dirty ;
! initializes model from path using lines>
! flushes model to path using >line if dirty
! -------------------------------------------------

{ array t } [
file-observers off
"outline.txt" [ ] [ ] <file-observer> init-model
[ [ dup class-of swap ] change-model ]
[ connections>> first dirty>> ]
bi
] unit-test

! ------------------------------------------------- arrow-frame

! ------------------------------------------------- main

".kullulu/translations.txt" home prepend-path "outline.txt" 2array [
file-observers off init-i18n make-outline-manager drop
file-observers get [ path>> ] each
] unit-test

! ------------------------------------------------- sandbox

USING: prettyprint
    ;



! USE: outline-manager refresh-all "outline-manager" test
