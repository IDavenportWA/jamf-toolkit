#!/bin/bash

###
#
#                    Author : Isaac Davenport
#                   Created : 08-25-2026
#             Last Modified : 08-29-2026
#                   Version : 1.1
#               Tested with : macOS 26.5.2
#
#   1.0: Initial versioned header. Downloads and installs the latest
#        Microsoft 365 release, warning open Office apps before quitting
#        and relaunching them.
#   1.1: Fixed ordering — the install previously ran BEFORE the "apps will
#        close" warning, so Office was updated underneath running apps and
#        the user was warned after the fact. Now warns, quits, installs,
#        then relaunches only what was open. Dialogs and relaunches run in
#        the user's session rather than as root. Added download/install
#        error handling and a quit fallback.
#
###

URL="https://go.microsoft.com/fwlink/?linkid=2009112"
PKG_PATH="/tmp/Office365.pkg"

# Logged-in user, so dialogs and relaunches land in their session, not root's
loggedInUser=$(echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ { print $3 }')
loggedInUID=$(id -u "$loggedInUser" 2>/dev/null)

runAsUser() {
    if [ -n "$loggedInUser" ] && [ "$loggedInUser" != "root" ] && [ -n "$loggedInUID" ]; then
        launchctl asuser "$loggedInUID" sudo -u "$loggedInUser" "$@"
    fi
}

apps=("Microsoft Word" "Microsoft Excel" "Microsoft PowerPoint" "Microsoft Outlook" "Microsoft OneNote" "Microsoft Teams")
opened_apps=()

# Work out what is open BEFORE we change anything
for app in "${apps[@]}"; do
    if pgrep -x "$app" >/dev/null; then
        opened_apps+=("$app")
    fi
done

relaunch_apps() {
    for app in "${opened_apps[@]}"; do
        runAsUser open -a "$app"
    done
}

# Warn and quit BEFORE installing, not after
if [ ${#opened_apps[@]} -gt 0 ]; then
    userChoice=$(runAsUser osascript -e 'button returned of (display dialog "Microsoft 365 apps will close in 60 seconds to apply the latest updates. Please save your work." buttons {"Update now", "OK"} default button "OK" with icon caution)' 2>/dev/null)

    if [ "$userChoice" = "Update now" ]; then
        waitTime=0
    else
        waitTime=60
    fi
    sleep "$waitTime"

    for app in "${opened_apps[@]}"; do
        runAsUser osascript -e "tell application \"$app\" to quit" 2>/dev/null
    done
    sleep 5

    # Force only what ignored the quit — Office apps hold unsaved-work dialogs
    for app in "${opened_apps[@]}"; do
        if pgrep -x "$app" >/dev/null; then
            echo "$app did not quit cleanly, forcing"
            killall "$app" 2>/dev/null
        fi
    done
    sleep 2
fi

# Download
echo "Downloading Microsoft 365..."
if ! curl -L --fail --silent --show-error -o "$PKG_PATH" "$URL"; then
    echo "ERROR: Microsoft 365 download failed, nothing was changed"
    rm -f "$PKG_PATH"
    relaunch_apps
    exit 1
fi

# Install (already root under a Jamf policy, so no sudo needed)
echo "Installing Microsoft 365..."
if ! /usr/sbin/installer -pkg "$PKG_PATH" -target /; then
    echo "ERROR: Microsoft 365 install failed"
    rm -f "$PKG_PATH"
    relaunch_apps
    exit 1
fi

rm -f "$PKG_PATH"
echo "Microsoft 365 updated successfully"

# Put the user back where they were
if [ ${#opened_apps[@]} -gt 0 ]; then
    sleep 3
    relaunch_apps
fi

exit 0
