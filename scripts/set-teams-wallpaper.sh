#!/bin/sh
###
#
#                    Author : Isaac Davenport
#                   Created : 05-16-2025
#             Last Modified : 08-29-2026
#                   Version : 1.2
#               Tested with : macOS 15.5
#
#   1.1: Prior version.
#   1.2: The cleanup step used ~ while running as root, so it targeted
#        /var/root and never removed anything. Now resolves the user's real
#        home via dscl. Generated images are chowned to the user — as
#        root-owned files Teams could not manage them. Image path is now a
#        Jamf parameter instead of a hardcoded site-specific path, and the
#        script verifies sips actually produced an image.
#
#   Jamf parameters:
#     $4  (optional) full path to the source image.
#         Defaults to /Library/Corp/Background.png
#
###
# This script copies a local image and sets it as a custom background
# image for Microsoft Teams.

### Source image — pass via Jamf parameter $4, or edit the default ###
LOCAL_IMAGE="${4:-/Library/Corp/Background.png}"

### Do not modify ###
CURRENT_USER=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ { print $3 }' )

if [ -z "$CURRENT_USER" ] || [ "$CURRENT_USER" = "root" ] || [ "$CURRENT_USER" = "_mbsetupuser" ]; then
    echo "No console user logged in, exiting"
    exit 0
fi

USER_HOME=$(/usr/bin/dscl . -read "/Users/$CURRENT_USER" NFSHomeDirectory 2>/dev/null | awk '{print $2}')

if [ -z "$USER_HOME" ] || [ ! -d "$USER_HOME" ]; then
    echo "Could not resolve home directory for $CURRENT_USER, exiting"
    exit 1
fi

BACKGROUND_FOLDER="$USER_HOME/Library/Containers/com.microsoft.teams2/Data/Library/Application Support/Microsoft/MSTeams/Backgrounds/Uploads"

### Remove old uploads ###
# Previously used ~, which expands to /var/root under a Jamf policy and
# therefore never matched the user's uploads.
if [ -d "$BACKGROUND_FOLDER" ]; then
    rm -rf "${BACKGROUND_FOLDER:?}/"*
fi

### Ensure Teams background folder exists ###
if [ ! -d "$BACKGROUND_FOLDER" ]; then
    mkdir -p "$BACKGROUND_FOLDER"
fi

### Process and copy image ###
if [ ! -f "$LOCAL_IMAGE" ]; then
    echo "Source image not found: $LOCAL_IMAGE"
    exit 1
fi

IMAGE_GUID=$(uuidgen)
IMAGE_PATH="$BACKGROUND_FOLDER/$IMAGE_GUID.png"
IMAGE_THUMB_PATH="$BACKGROUND_FOLDER/${IMAGE_GUID}_thumb.png"

# Convert to PNG
if ! sips -s format png "$LOCAL_IMAGE" -o "$IMAGE_PATH" >/dev/null 2>&1 || [ ! -f "$IMAGE_PATH" ]; then
    echo "Failed to convert $LOCAL_IMAGE to PNG"
    exit 1
fi

# Copy same image as thumbnail
cp "$IMAGE_PATH" "$IMAGE_THUMB_PATH"

# Resize/crop thumbnail
sips -Z 186 "$IMAGE_THUMB_PATH" -o "$IMAGE_THUMB_PATH" >/dev/null 2>&1
sips -z 186 238 "$IMAGE_THUMB_PATH" -o "$IMAGE_THUMB_PATH" >/dev/null 2>&1

# Hand ownership to the user — Teams runs as them and cannot manage
# root-owned files in its own container.
chown "$CURRENT_USER" "$IMAGE_PATH" "$IMAGE_THUMB_PATH"
chown -R "$CURRENT_USER" "$BACKGROUND_FOLDER"

echo "Background image set successfully: $IMAGE_PATH"
exit 0
