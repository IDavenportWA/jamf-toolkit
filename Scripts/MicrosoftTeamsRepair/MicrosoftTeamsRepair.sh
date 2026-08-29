#!/bin/bash

###
#
#                    Author : Isaac Davenport
#                   Created : 08-25-2026
#             Last Modified : 08-29-2026
#                   Version : 1.1
#               Tested with : macOS 26.5.2
#
#   1.0: Initial versioned header. Quits Microsoft Teams, clears its cache
#        directories, and relaunches it to resolve common Teams issues.
#   1.1: Quit and relaunch now run in the user's session via launchctl
#        asuser — previously 'open -a' ran as root, launching Teams in the
#        wrong context. Home directory is read from dscl instead of assuming
#        /Users/<name>. Added a force-quit fallback so caches are not
#        deleted underneath a still-running Teams, and guards against
#        running with no console user.
#
###

# Logged-in user and their real home directory
loggedInUser=$(echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ { print $3 }')

if [ -z "$loggedInUser" ] || [ "$loggedInUser" = "root" ] || [ "$loggedInUser" = "_mbsetupuser" ]; then
    echo "No console user logged in, exiting"
    exit 0
fi

loggedInUID=$(id -u "$loggedInUser" 2>/dev/null)
userHome=$(/usr/bin/dscl . -read "/Users/$loggedInUser" NFSHomeDirectory 2>/dev/null | awk '{print $2}')

if [ -z "$userHome" ] || [ ! -d "$userHome" ]; then
    echo "Could not resolve home directory for $loggedInUser, exiting"
    exit 1
fi

runAsUser() {
    launchctl asuser "$loggedInUID" sudo -u "$loggedInUser" "$@"
}

echo "Repairing Teams for $loggedInUser ($userHome)"

# Quit Teams in the user's session, then force it if it ignores us.
# Deleting these caches under a running Teams is what causes it to rewrite
# them on exit and undo the repair.
runAsUser osascript -e 'tell application "Microsoft Teams" to quit' 2>/dev/null
sleep 3

if pgrep -x "Microsoft Teams" >/dev/null; then
    echo "Teams did not quit cleanly, forcing"
    killall "Microsoft Teams" 2>/dev/null
    sleep 2
fi

# Clear cache locations for both classic and new Teams
for cachePath in \
    "$userHome/Library/Application Support/Microsoft/Teams" \
    "$userHome/Library/Group Containers/UBF8T346G9.com.microsoft.teams" \
    "$userHome/Library/Containers/com.microsoft.teams2"
do
    if [ -e "$cachePath" ]; then
        rm -rf "$cachePath"
        echo "Cleared $cachePath"
    else
        echo "Not present, skipping: $cachePath"
    fi
done

sleep 2

# Relaunch in the user's session, not root's
runAsUser open -a "Microsoft Teams"

echo "Microsoft Teams cache cleared and restarted."
exit 0
