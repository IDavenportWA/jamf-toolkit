#!/bin/bash

###
#
#                    Author : Isaac Davenport
#                   Created : 08-25-2026
#             Last Modified : 08-29-2026
#                   Version : 1.1
#               Tested with : macOS 26.5.2
#
#   1.0: Initial versioned header. Downloads and installs the latest Google
#        Chrome release, warning the user before quitting/relaunching it.
#   1.1: Fixed ordering — the install previously ran BEFORE the "Chrome will
#        close" warning, so Chrome was replaced underneath a running instance
#        and the user was warned after the fact. Now warns, quits, installs,
#        then relaunches. User-facing dialogs and the relaunch run in the
#        user's session rather than as root. Added download/install error
#        handling and a quit fallback.
#
###

URL="https://dl.google.com/dl/chrome/mac/universal/stable/gcem/GoogleChrome.pkg"
PKG_PATH="/tmp/googlechrome.pkg"

# Logged-in user, so dialogs and the relaunch land in their session, not root's
loggedInUser=$(echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ { print $3 }')
loggedInUID=$(id -u "$loggedInUser" 2>/dev/null)

runAsUser() {
    if [ -n "$loggedInUser" ] && [ "$loggedInUser" != "root" ] && [ -n "$loggedInUID" ]; then
        launchctl asuser "$loggedInUID" sudo -u "$loggedInUser" "$@"
    fi
}

# Is Chrome running? Decide before we touch anything.
chromeWasRunning=false
if pgrep -x "Google Chrome" >/dev/null; then
    chromeWasRunning=true
fi

# Warn and quit BEFORE installing, not after
if [ "$chromeWasRunning" = true ]; then
    userChoice=$(runAsUser osascript -e 'button returned of (display dialog "Google Chrome will close in 60 seconds to apply the latest updates. Please save your work." buttons {"Update now", "OK"} default button "OK" with icon caution)' 2>/dev/null)

    if [ "$userChoice" = "Update now" ]; then
        waitTime=0
    else
        waitTime=60
    fi
    sleep "$waitTime"

    # Ask nicely first so open tabs are restored on relaunch
    runAsUser osascript -e 'tell application "Google Chrome" to quit' 2>/dev/null
    sleep 5

    # Fall back to a hard kill only if it ignored the quit
    if pgrep -x "Google Chrome" >/dev/null; then
        echo "Chrome did not quit cleanly, forcing"
        killall "Google Chrome" 2>/dev/null
        sleep 2
    fi
fi

# Download
echo "Downloading Google Chrome..."
if ! curl -L --fail --silent --show-error -o "$PKG_PATH" "$URL"; then
    echo "ERROR: Chrome download failed, nothing was changed"
    rm -f "$PKG_PATH"
    [ "$chromeWasRunning" = true ] && runAsUser open -a "Google Chrome"
    exit 1
fi

# Install (already running as root under a Jamf policy, so no sudo needed)
echo "Installing Google Chrome..."
if ! /usr/sbin/installer -pkg "$PKG_PATH" -target /; then
    echo "ERROR: Chrome install failed"
    rm -f "$PKG_PATH"
    [ "$chromeWasRunning" = true ] && runAsUser open -a "Google Chrome"
    exit 1
fi

rm -f "$PKG_PATH"
echo "Google Chrome updated successfully"

# Put the user back where they were
if [ "$chromeWasRunning" = true ]; then
    sleep 3
    runAsUser open -a "Google Chrome"
fi

exit 0
