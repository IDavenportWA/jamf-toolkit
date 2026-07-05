#!/bin/bash

# Define the download URL
URL="https://dl.google.com/dl/chrome/mac/universal/stable/gcem/GoogleChrome.pkg"

# Define temporary download location
PKG_PATH="/tmp/googlechrome.pkg"

# Download the .pkg file
curl -L -o "$PKG_PATH" "$URL"

# Installing the .pkg file
sudo installer -pkg "$PKG_PATH" -target /

# Clean up
rm "$PKG_PATH"

# Check if Chrome is running
chromeWasRunning=false
if pgrep -x "Google Chrome" > /dev/null; then
    chromeWasRunning=true

    # Display warning to user
    userChoice=$(osascript <<EOF
button returned of (display dialog "Google Chrome will close in 60 seconds to apply latest updates. Please save your work." buttons {"Update now", "OK"} default button "OK" with icon caution)
EOF
)

    # If user clicked "Update Now"
    if [[ "$userChoice" == "Update now" ]]; then
        waitTime=0
    else
        waitTime=60
    fi

    sleep $waitTime

    # Quit Chrome
    killall "Google Chrome"
fi


# Relaunch Chrome if it was running
if [ "$chromeWasRunning" = true ]; then
    sleep 3
    open -a "Google Chrome"
fi
