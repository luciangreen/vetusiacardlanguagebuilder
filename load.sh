#!/usr/bin/env bash

# Exit immediately if the Prolog file is missing
if [ ! -f "Dropbox/GitHub/vetusiacardlanguagebuilder/load.pl" ]; then
    echo "Error: load.pl not found in the current directory." >&2
    exit 1
fi

# Launch SWI-Prolog, load the file, and execute the entry predicate
swipl -q -s Dropbox/GitHub/vetusiacardlanguagebuilder/load.pl -g language_repl
