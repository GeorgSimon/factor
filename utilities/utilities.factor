USING: accessors arrays assocs continuations
    io io.backend io.directories io.encodings.utf8 io.files io.pathnames
    kernel math math.parser models namespaces prettyprint
    sequences splitting ui.gadgets.borders ui.gadgets.labels vectors words
    ;
FROM: models => change-model ; ! to clear ambiguity
IN: utilities

SYMBOLS: config-dir options persistents translations
    ;
: error>message ( error -- string )
    ! Factor errors are strings in Windows and tuples in Linux
    [ message>> ] [ drop ] recover
    ;
: print-file-error ( path error -- )
    [ normalize-path ] dip error>message " : " append prepend print flush
    ;
: fetch-lines ( path -- lines )
    [ utf8 file-lines ] [ print-file-error { } ] recover
    ;
: line>words ( line -- array )
    " " split [ empty? not ] filter
    ;
: config-path ( filename -- path )
    config-dir get prepend-path home prepend-path
    ;
: manual-path ( filename -- path )
    "manual" prepend-path config-path
    ; inline
: target-index ( table -- index )
    selection-index>> value>> [ 0 ] unless*
    ;
: get-label ( labeled-gadget -- label )
    children>> [ border? ] find nip children>> [ label? ] find nip
    ;
! ------------------------------------------------- i18n
: store-translation ( seq hashtable translation index -- seq hashtable' )
    swap                        ! seq hashtable index value
    [ 1 - pick nth ] dip        ! seq hashtable key value
    swap pick set-at
    ; inline
: lines>translations ( lines -- hashtable )
    H{ } clone over
    [ dup 3 mod 2 = [ store-translation ] [ 2drop ] if ] each-index nip
    ; inline
: translations>lines ( hashtable -- lines )
    [ [ "" ] 2dip 3array ] { } assoc>map concat
    ; inline
: print-?translated ( line -- )
    translations get value>> ?at drop print
    ;
: extend-translations ( line -- line )
    translations get [ over dup pick set-at ] change-model
    "A template has been inserted into the translation table."
    print-?translated
    ; inline
: i18n ( line -- translation/line )
    translations get value>> ?at [
        nl
        "No translation found for following text line :" print-?translated
        dup .
        extend-translations
        nl flush
    ] unless
    ;
! ------------------------------------------------- utilities using i18n
: syntax-error. ( words error -- )
    drop "Syntax error :" i18n write [ bl write ] each nl
    ;
: ?invalid. ( string/f -- )
    [ ] [ "Not a command key :" i18n write bl print flush ] if-empty
    ;
! ------------------------------------------------- persistent models
! persistent models are
! - initialized from path using lines>
! - flushed to path using >line if dirty
! -------------------------------------------------
TUPLE: persistent path model >lines dirty
    ;
: <persistent> ( lines> path >lines -- model )
    persistent new swap >>>lines swap >>path            ! lines> object
    dup persistents [ ?push ] change                    ! lines> object
    dup path>> fetch-lines rot call( lines -- value )   ! object value
    <model> 2dup add-connection
    [ swap model<< ] keep
    ;
M: persistent model-changed ( model persistent -- )
    t swap dirty<< drop
    ;
: (save-persistent) ( object -- )
    f over dirty<<
    [ model>> value>> ] [ >lines>> call( value -- lines ) ] [ path>> ] tri
    [ utf8 set-file-lines ]
    [ drop dup parent-directory make-directory utf8 set-file-lines ]
    recover
    ; inline
: save-persistent ( object -- )
    dup dirty>> [ (save-persistent) ] [ drop ] if
    ;
: save-persistents ( -- ) ! to be called when finishing and also periodically
    persistents get [ save-persistent ] each
    ;
! -------------------------------------------------
: init-background ( config-dir -- )
    config-dir set persistents off
    [ lines>translations ]
    config-dir get home prepend-path "translations.txt" append-path
    [ translations>lines ]
    <persistent> translations set
    ;
! ------------------------------------------------- options
: option. ( value name -- value name )
    over number>string over write bl print
    ; inline
: process-option ( words -- )
    [   options swap
        [ second string>number ] [ first ] bi option.
        set-word-prop
        ]
    [   syntax-error.
        ]
    recover
    ; inline
: process-options ( lines -- )
    dup empty? [
        "No options found" i18n
    ] [
        "Found options :" i18n
    ] if
    print nl
    [ process-option ] each nl flush
    ; inline
: get-option ( option-name -- option-value )
    options swap word-prop
    ;
