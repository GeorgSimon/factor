! Copyright (C) 2013 Your name.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors command-line continuations fry
    io io.backend io.directories io.encodings.utf8
    io.files io.files.types io.pathnames
    kernel libc math math.parser namespaces nested-comments prettyprint
    regexp sequences system ;
IN: regression

(*
Test:   cd /opt/pub/mDS/factor096/work/regression/test/
        factor ../regression.factor
*)

SYMBOLS: compare-command compile-command view-command
    results-dir sources-dir targets-dir ;

TUPLE: external-command command-string error-table
    ;
: <external-command> ( command-string error-table -- object )
    external-command boa
    ;
: quote ( string -- string' )
     "\"" dup rot glue
     ;
: make-path-string ( filename subdir-variable -- path )
    get prepend-path normalize-path quote
    ;
: prepend-with-space ( word2 word1 -- string )
    swap " " glue
    ;
: process-sources ( path -- returncodes )
    directory-entries
    [ type>> +regular-file+ = ] filter
    [ name>> ] map
    [ [ results-dir make-path-string ] map ]
    [ [ sources-dir make-path-string ] map ]
    bi
    [ compile-command get prepend-with-space prepend-with-space system ] 2map
    ;
: (statistic) ( returncode returncodes -- )
    over
    '[ _ = ] filter length dup 0 =
    [ 2drop ] [ number>string write " times return code " write . ] if
    ;
: statistic ( returncodes -- )
    "compare results" print
    256 iota [ over (statistic) ] each
    drop
    ;
: test-results ( path -- returncodes ) ! compare results with targets
    directory-entries
    [ type>> +regular-file+ = ] filter
    [ name>> ] map
    [ [ results-dir make-path-string ] map ]
    [ [ targets-dir make-path-string ] map ]
    bi
    [ compare-command get prepend-with-space prepend-with-space system ] 2map
    ;
: set-defaults ( -- )
    "commands.txt" utf8 file-lines .
    "diff" compare-command set  ! Windows: fc
    "cp" compile-command set
    "less" view-command set
    "results" results-dir set
    "sources" sources-dir set
    "targets" targets-dir set
    ;
: regression ( -- )
    set-defaults
    results-dir get [ [ delete-file ] each ] with-directory-files
    sources-dir get [ process-sources . ] [ . . ] recover
    results-dir sources-dir [ get directory-files length ] bi@
    =
    [ results-dir get [ test-results statistic ] [ . . ] recover ]
    [ "source and result files count differ" print ]
    if
    ;
MAIN: regression
