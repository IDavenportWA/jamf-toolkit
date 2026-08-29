#!/bin/bash

###
#
#                    Author : Isaac Davenport
#                   Created : 08-25-2026
#             Last Modified : 08-29-2026
#                   Version : 1.1
#               Tested with : macOS 26.5.2
#
#   1.0: Initial versioned header. Runs sysdiagnose for the logged-in user
#        and saves the output to their Downloads folder.
#   1.1: Home directory now resolved via dscl instead of assuming
#        /Users/<name>. Output is chowned to the user, who previously could
#        not move or delete the root-owned archive left in their Downloads.
#        Added a console-user guard and removed commented-out dead code.
#
###

# Logged-in user and their real home directory
loggedInUser=$(echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ && ! /loginwindow/ { print $3 }')

if [ -z "$loggedInUser" ] || [ "$loggedInUser" = "root" ] || [ "$loggedInUser" = "_mbsetupuser" ]; then
    echo "No console user logged in, exiting"
    exit 0
fi

userHome=$(/usr/bin/dscl . -read "/Users/$loggedInUser" NFSHomeDirectory 2>/dev/null | awk '{print $2}')

if [ -z "$userHome" ] || [ ! -d "$userHome" ]; then
    echo "Could not resolve home directory for $loggedInUser, exiting"
    exit 1
fi

outputDir="$userHome/Downloads"
mkdir -p "$outputDir"

echo "Running sysdiagnose for $loggedInUser, output to $outputDir"

# -u runs without the interactive prompt; this takes several minutes
if ! /usr/bin/sysdiagnose -u -f "$outputDir"; then
    echo "ERROR: sysdiagnose failed"
    exit 1
fi

# Hand the archive to the user — as root-owned it cannot be moved,
# deleted or attached to a ticket without admin rights.
find "$outputDir" -maxdepth 1 -name 'sysdiagnose_*' -newermt '-10 minutes' \
    -exec chown -R "$loggedInUser" {} \; 2>/dev/null

echo "sysdiagnose complete, archive saved to $outputDir"
exit 0
