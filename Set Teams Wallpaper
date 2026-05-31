#!/bin/sh
###
#
#                    Author : Isaac Davenport
#                   Created : 05-16-2025
#             Last Modified : 05-18-2025
#                   Version : 1.1
#               Tested with : macOS 15.5
#
###
# This script copies a local image and sets it as a custom background
# image for Microsoft Teams.
#
## Removes old uploads
rm -r ~/Library/Containers/com.microsoft.teams2/Data/Library/Application\ Support/Microsoft/MSTeams/Backgrounds/Uploads/*
### Do not modify ###
CURRENT_USER=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ { print $3 }' )
USER_HOME=$(dscl . -read /users/${CURRENT_USER} NFSHomeDirectory | cut -d " " -f 2)
BACKGROUND_FOLDER="$USER_HOME/Library/Containers/com.microsoft.teams2/Data/Library/Application Support/Microsoft/MSTeams/Backgrounds/Uploads"

### Local file path (replace if needed) ###
LOCAL_IMAGE="/Library/Ontinue/Background.png"

### Ensure Teams background folder exists ###
if [ ! -d "$BACKGROUND_FOLDER" ]; then
    mkdir -p "$BACKGROUND_FOLDER"
fi

### Process and copy image ###
if [ -f "$LOCAL_IMAGE" ]; then
    IMAGE_GUID=$(uuidgen)
    IMAGE_PATH="$BACKGROUND_FOLDER/$IMAGE_GUID.png"
    IMAGE_THUMB_PATH="$BACKGROUND_FOLDER/${IMAGE_GUID}_thumb.png"

    # Convert to PNG
    sips -s format png "$LOCAL_IMAGE" -o "$IMAGE_PATH" >/dev/null

    # Copy same image as thumbnail
    cp "$IMAGE_PATH" "$IMAGE_THUMB_PATH"

    # Resize/crop thumbnail
    sips -Z 186 "$IMAGE_THUMB_PATH" -o "$IMAGE_THUMB_PATH" >/dev/null 2>&1
    sips -z 186 238 "$IMAGE_THUMB_PATH" -o "$IMAGE_THUMB_PATH" >/dev/null 2>&1

    echo "Background image set successfully: $IMAGE_PATH"
else
    echo "Local image not found: $LOCAL_IMAGE"
    exit 1
fi

exit 0
