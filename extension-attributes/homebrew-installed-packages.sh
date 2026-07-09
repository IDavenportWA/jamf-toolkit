#!/bin/bash

loggedInUser=$(stat -f%Su /dev/console)

if [ "$loggedInUser" = "root" ] || [ -z "$loggedInUser" ]; then
    echo "<result>No logged-in user</result>"
    exit 0
fi

if [ -x "/opt/homebrew/bin/brew" ]; then
    BREW="/opt/homebrew/bin/brew"
elif [ -x "/usr/local/bin/brew" ]; then
    BREW="/usr/local/bin/brew"
else
    echo "<result>Homebrew not found</result>"
    exit 0
fi

UID_NUM=$(id -u "$loggedInUser")

###############################################################################
# Get formulas with versions (KEEP STRUCTURE)
###############################################################################
raw_formulas=$(
launchctl asuser "$UID_NUM" sudo -u "$loggedInUser" \
"$BREW" list --formula --versions 2>/dev/null
)

###############################################################################
# Get casks (no version field from brew)
###############################################################################
raw_casks=$(
launchctl asuser "$UID_NUM" sudo -u "$loggedInUser" \
"$BREW" list --cask 2>/dev/null
)

###############################################################################
# Format formulas correctly (name + version on SAME line)
###############################################################################
formulas=""
while read -r line; do
    [[ -z "$line" ]] && continue

    name=$(echo "$line" | awk '{print $1}')
    version=$(echo "$line" | awk '{print $2}')

    formulas+="${name} ${version}"$'\n'
done <<< "$raw_formulas"

###############################################################################
# Format casks (single column)
###############################################################################
casks=""
while read -r line; do
    [[ -z "$line" ]] && continue
    casks+="${line}"$'\n'
done <<< "$raw_casks"

###############################################################################
# Build output
###############################################################################
output=""

if [ -n "$formulas" ]; then
    output+="----- Homebrew Formulas -----"$'\n'
    output+="$formulas"$'\n'
fi

if [ -n "$casks" ]; then
    output+="----- Homebrew Casks -----"$'\n'
    output+="$casks"
fi

###############################################################################
# Output
###############################################################################
if [ -z "$formulas" ] && [ -z "$casks" ]; then
    echo "<result>No Homebrew packages installed</result>"
else
    echo "<result>${output}</result>"
fi

exit 0
