#! /bin/bash

# This script goes through the current directory,
# finds all the .dat files,
# and checks their last lines.
#
# If the last line doesn't start with "--", "--" is added.
#
# This is designed to make the .dat files Simutranslator-compliant.

FILES=`find . -name "*.dat" -print`
# First pass: remove trailing whitespace
# This rather unreadable sed program will do this.
# See https://stackoverflow.com/questions/7359527/removing-trailing-starting-newlines-with-sed-awk-tr-and-friends
for x in $FILES; do
    sed -n '/^[[:space:]]*$/ !{x;/\n/{s/^\n//;p;s/.*//;};x;p;}; /^[[:space:]]*$/H' -i $x
done
echo "Trailing whitespaces removed"

# Note, crucial to not use the quotes around $FILES, so that the file list gets split
for x in $FILES; do
    TAIL=`tail -1 "$x"`
    # Bash regular expression
    if [[ "$TAIL" =~ --.* ]]; then
        echo "$x: OK"
    else
        # Append to file
        echo "--" >> $x
        echo "$x: terminator added"
    fi
done
