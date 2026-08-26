#!/bin/bash

###
#
#                    Author : Isaac Davenport
#                   Created : 08-25-2026
#             Last Modified : 08-25-2026
#                   Version : 1.0
#               Tested with : macOS 26.5.2
#
#   1.0: Initial versioned header. Quits Microsoft Teams, clears its cache
#        directories, and relaunches it to resolve common Teams issues.
#
###

# Quit Teams
osascript -e 'tell application "Microsoft Teams" to quit'
sleep 3

# Get current user
currentUser=$(/bin/ls -l /dev/console | /usr/bin/awk '{ print $3 }')
userHome="/Users/$currentUser"

echo "$currentUser"

# Remove caches

#Classic Cache
rm -rf "$userHome/Library/Application Support/Microsoft/Teams"
echo "Cleared $userHome/Library/Application Support/Microsoft/Teams"

#"New" Teams Cache
rm -rf "$userHome/Library/Group Containers/UBF8T346G9.com.microsoft.teams"
echo "Cleared $userHome/Library/Group Containers/UBF8T346G9.com.microsoft.teams"

rm -rf "$userHome/Library/Containers/com.microsoft.teams2"
echo "Cleared $userHome/Library/Containers/com.microsoft.teams2"

sleep 3

# Restart Teams
open -a "Microsoft Teams"

echo "Microsoft Teams cache cleared and restarted."
