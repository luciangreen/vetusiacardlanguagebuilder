#!/usr/bin/env bash
# Starts the VCLB folder loader REPL. Works from any directory.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ ! -f "$DIR/load.pl" ]; then
    echo "Error: load.pl not found in $DIR." >&2
    exit 1
fi

swipl -q -s "$DIR/load.pl" -g language_repl
