#! /bin/bash

# This script goes through the current directory,
# finds all the .dat files,
# and checks their last lines.
#
# If the last line doesn't start with "--", "--" is added.
#
# This is designed to make the .dat files Simutranslator-compliant.

FILES=`find . -name "*.dat" -print`
# Note, crucial to not use the quotes around $FILES, so that the file list gets split
for x in $FILES; do
    TAIL=`tail -1 "$x"`
    # Bash regular expression
    if [[ "$TAIL" =~ --.* ]]; then
        echo "$x: OK"
    else
        # Append to file
        echo "--" >> $x
        echo "$x: fixed"
    fi
done
