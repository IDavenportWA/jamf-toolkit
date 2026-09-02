#!/bin/bash

###
#
#                    Author : Isaac Davenport
#                   Created : 08-25-2026
#             Last Modified : 09-02-2026
#                   Version : 1.2
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
#   1.2: Verifies the staged Firefox.app has an intact code signature from
#        Mozilla's Apple Developer Team ID before the running copy is quit
#        or touched. A tampered or truncated download now fails closed with
#        the existing install untouched and the user never interrupted.
#        Working files live in a mktemp directory rather than fixed /tmp
#        paths, and the cleanup trap restores the previous Firefox if the
#        script is killed mid-swap.
#
###

URL="https://download.mozilla.org/?product=firefox-latest&os=osx&lang=en-US"
APP_PATH="/Applications/Firefox.app"
EXPECTED_TEAM_ID="43AQ936H96"   # Mozilla Corporation

WORK_DIR=$(mktemp -d "/private/tmp/FirefoxLatest.XXXXXX")
DMG_PATH="$WORK_DIR/Firefox.dmg"
STAGE_PATH="$WORK_DIR/Firefox-new.app"
BACKUP_PATH="$WORK_DIR/Firefox-previous.app"

loggedInUser=$(echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ { print $3 }')
loggedInUID=$(id -u "$loggedInUser" 2>/dev/null)

runAsUser() {
    if [ -n "$loggedInUser" ] && [ "$loggedInUser" != "root" ] && [ -n "$loggedInUID" ]; then
        launchctl asuser "$loggedInUID" sudo -u "$loggedInUser" "$@"
    fi
}

cleanup() {
    [ -n "$MOUNT_POINT" ] && [ -d "$MOUNT_POINT" ] && hdiutil detach "$MOUNT_POINT" -quiet 2>/dev/null
    # If we were interrupted between moving the old copy aside and moving the
    # new one in, put the old one back rather than leaving no Firefox at all.
    if [ ! -d "$APP_PATH" ] && [ -d "$BACKUP_PATH" ]; then
        mv "$BACKUP_PATH" "$APP_PATH"
    fi
    rm -rf "$WORK_DIR"
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
if ! cp -R "$MOUNT_POINT/Firefox.app" "$STAGE_PATH"; then
    echo "ERROR: Failed to copy Firefox from the DMG, existing install untouched"
    exit 1
fi

# Verify the staged copy before the running Firefox is quit or anything on
# the machine changes. Both checks must pass: the signature is intact, and
# it is Mozilla's.
echo "Verifying signature..."
if ! codesign --verify --deep --strict "$STAGE_PATH" 2>/dev/null; then
    echo "ERROR: Staged Firefox.app failed code signature verification, existing install untouched"
    exit 1
fi
teamID=$(codesign -dv --verbose=4 "$STAGE_PATH" 2>&1 | awk -F= '/^TeamIdentifier=/ {print $2}')
if [ "$teamID" != "$EXPECTED_TEAM_ID" ]; then
    echo "ERROR: Firefox.app failed Team ID verification (expected $EXPECTED_TEAM_ID, got '$teamID'), existing install untouched"
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
