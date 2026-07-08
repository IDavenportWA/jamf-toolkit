#!/bin/bash

# Define the download URL
URL="https://go.microsoft.com/fwlink/?linkid=2009112"

# Define temporary download location
PKG_PATH="/tmp/Office365.pkg"

# Download the .pkg file
curl -L -o "$PKG_PATH" "$URL"

# Install the .pkg file
sudo installer -pkg "$PKG_PATH" -target /

# Clean up
rm "$PKG_PATH"

# List of Office 365 apps to check
apps=("Microsoft Word" "Microsoft Excel" "Microsoft PowerPoint" "Microsoft Outlook" "Microsoft OneNote" "Microsoft Teams")
opened_apps=()

# Check which apps are currently running
for app in "${apps[@]}"; do
    if pgrep -x "$app" > /dev/null; then
        opened_apps+=("$app")
    fi
done

# If no apps are open, exit
if [ ${#opened_apps[@]} -eq 0 ]; then
    exit 0
fi

# Display warning to user
userChoice=$(osascript <<EOF
button returned of (display dialog "Office 365 apps will close in 60 seconds to apply latest updates. Please save your work." buttons {"Update now", "OK"} default button "OK" with icon caution)
EOF
)

# If user clicked "Relaunch Now", skip wait
if [[ "$userChoice" == "Update now" ]]; then
    waitTime=0
else
    waitTime=60
fi

sleep $waitTime

# Close the apps that were open
for app in "${opened_apps[@]}"; do
    osascript -e "tell application \"$app\" to quit"
done

# Wait 5 seconds before relaunch
sleep 5

# Relaunch the apps that were originally open
for app in "${opened_apps[@]}"; do
    open -a "$app"
done
