#!/bin/bash

###
#
#                    Author : Isaac Davenport
#                   Created : 08-25-2026
#             Last Modified : 08-29-2026
#                   Version : 1.1
#               Tested with : macOS 26.5.2
#
#   1.0: Initial versioned header. Downloads and installs the latest Firefox
#        release from Mozilla, relaunching it afterward if it was running.
#   1.1: No longer deletes /Applications/Firefox.app before the replacement
#        is known to be good — a failed copy previously left the machine
#        with no browser. Now stages the new copy, swaps it in, and restores
#        the original on failure. Added a curl failure check, fixed
#        'hdiutil detach' being called with an empty mount point on the
#        error path, and moved the quit/relaunch into the user's session.
#
###

URL="https://download.mozilla.org/?product=firefox-latest&os=osx&lang=en-US"
DMG_PATH="/tmp/Firefox.dmg"
APP_PATH="/Applications/Firefox.app"
STAGE_PATH="/tmp/Firefox-new.app"
BACKUP_PATH="/tmp/Firefox-previous.app"

loggedInUser=$(echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ { print $3 }')
loggedInUID=$(id -u "$loggedInUser" 2>/dev/null)

runAsUser() {
    if [ -n "$loggedInUser" ] && [ "$loggedInUser" != "root" ] && [ -n "$loggedInUID" ]; then
        launchctl asuser "$loggedInUID" sudo -u "$loggedInUser" "$@"
    fi
}

cleanup() {
    [ -n "$MOUNT_POINT" ] && [ -d "$MOUNT_POINT" ] && hdiutil detach "$MOUNT_POINT" -quiet 2>/dev/null
    rm -rf "$DMG_PATH" "$STAGE_PATH"
}
trap cleanup EXIT

# Was it running? Decide before we touch anything.
FIREFOX_RUNNING=false
if pgrep -x "firefox" >/dev/null; then
    FIREFOX_RUNNING=true
    echo "Firefox is currently running. It will be relaunched after the update."
fi

# Download
echo "Downloading Firefox..."
if ! curl -L --fail --silent --show-error -o "$DMG_PATH" "$URL"; then
    echo "ERROR: Firefox download failed, nothing was changed"
    exit 1
fi

# Mount
echo "Mounting DMG..."
MOUNT_POINT=$(hdiutil attach "$DMG_PATH" -nobrowse -noverify | grep -o '/Volumes/.*' | tail -1)

if [ -z "$MOUNT_POINT" ] || [ ! -d "$MOUNT_POINT/Firefox.app" ]; then
    echo "ERROR: Failed to mount DMG or locate Firefox.app inside it"
    exit 1
fi

# Stage the new copy first, so a failed copy cannot leave us with no browser
echo "Staging new Firefox..."
rm -rf "$STAGE_PATH"
if ! cp -R "$MOUNT_POINT/Firefox.app" "$STAGE_PATH"; then
    echo "ERROR: Failed to copy Firefox from the DMG, existing install untouched"
    exit 1
fi

# Quit in the user's session so session restore works
if [ "$FIREFOX_RUNNING" = true ]; then
    echo "Closing Firefox..."
    runAsUser osascript -e 'tell application "Firefox" to quit' 2>/dev/null
    sleep 3
    if pgrep -x "firefox" >/dev/null; then
        echo "Firefox did not quit cleanly, forcing"
        killall firefox 2>/dev/null
        sleep 2
    fi
fi

# Swap: keep the old copy until the new one is in place
rm -rf "$BACKUP_PATH"
if [ -d "$APP_PATH" ] && ! mv "$APP_PATH" "$BACKUP_PATH"; then
    echo "ERROR: Could not move the existing Firefox aside, aborting"
    exit 1
fi

if mv "$STAGE_PATH" "$APP_PATH"; then
    echo "Firefox updated successfully"
    rm -rf "$BACKUP_PATH"
else
    echo "ERROR: Failed to install the new Firefox, restoring the previous version"
    [ -d "$BACKUP_PATH" ] && mv "$BACKUP_PATH" "$APP_PATH"
    exit 1
fi

# Relaunch in the user's session if it was running
if [ "$FIREFOX_RUNNING" = true ]; then
    echo "Relaunching Firefox..."
    sleep 2
    runAsUser open -a "$APP_PATH"
fi

exit 0
