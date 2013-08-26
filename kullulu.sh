#!/bin/bash

if test $# -eq 0 ; then
    terminal.sh --title=Kullulu -x $0 dummy
    exit
    fi
echo Der Worte sind genug gewechselt,
echo Laßt mich auch endlich Daten sehn!
echo ------------------------------------------------------------------
factor-run -run=kullulu
echo ------------------------------------------------------------------
echo mit Enter wird dieses Terminal geschlossen
read
