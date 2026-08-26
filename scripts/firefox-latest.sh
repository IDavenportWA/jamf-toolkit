#!/bin/bash

###
#
#                    Author : Isaac Davenport
#                   Created : 08-25-2026
#             Last Modified : 08-25-2026
#                   Version : 1.0
#               Tested with : macOS 26.5.2
#
#   1.0: Initial versioned header. Downloads and installs the latest Firefox
#        release from Mozilla, relaunching it afterward if it was running.
#
###

# Variables
URL="https://download.mozilla.org/?product=firefox-latest&os=osx&lang=en-US"
DMG_PATH="/tmp/Firefox.dmg"
APP_PATH="/Applications/Firefox.app"

# Check if Firefox is currently running
FIREFOX_RUNNING=false
if pgrep -x "firefox" > /dev/null || pgrep -x "Firefox" > /dev/null; then
    FIREFOX_RUNNING=true
    echo "Firefox is currently running. It will be relaunched after update."
fi

# Download latest Firefox DMG
echo "Downloading Firefox..."
curl -L -o "$DMG_PATH" "$URL"

# Mount the DMG
echo "Mounting DMG..."
MOUNT_POINT=$(hdiutil attach "$DMG_PATH" -nobrowse | grep -o '/Volumes/Firefox[^"]*')

# Check if mount succeeded
if [ ! -d "$MOUNT_POINT/Firefox.app" ]; then
    echo "Failed to mount or locate Firefox.app"
    hdiutil detach "$MOUNT_POINT"
    rm -f "$DMG_PATH"
    exit 1
fi

# Gracefully close Firefox
echo "Closing Firefox if it's open..."
osascript -e 'tell application "Firefox" to quit' 2>/dev/null
sleep 3

# Remove old Firefox
echo "Removing old Firefox..."
rm -rf "$APP_PATH"

# Copy new Firefox
echo "Installing new Firefox..."
cp -R "$MOUNT_POINT/Firefox.app" "$APP_PATH"
sleep 2

# Unmount the DMG
echo "Unmounting DMG..."
hdiutil detach "$MOUNT_POINT"

# Clean up
rm -f "$DMG_PATH"

# Relaunch Firefox if it was running before
if [ "$FIREFOX_RUNNING" = true ]; then
    echo "Relaunching Firefox..."
    open -a "$APP_PATH"
else
    echo "Firefox was not running before. Not launching."
fi
