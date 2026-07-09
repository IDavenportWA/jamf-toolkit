#!/bin/bash

###################################################################################################
# Script Name:  installedVSCodeExtensions.sh
# Author:       Isaac Davenport
# Created:      07/09/2026
#
# Purpose:
#   Extension Attribute (EA) for Jamf Pro that enumerates all Visual Studio Code
#   extensions installed for the currently logged-in user on macOS. The output
#   includes each extension identifier and its installed version, formatted for
#   inventory collection in Jamf Pro.
#
# Requirements:
#   - Visual Studio Code installed in /Applications
#   - Script executed by Jamf Pro (root)
#   - Logged-in user must have a VS Code profile
###################################################################################################

# Set Initial Result
result="Not installed"

# Run as the current logged in user to grab their extensions
loggedInUser=$(echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ { print $3 }')
codePath="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"

# Check VS Code for installed extensions and include the current version installed
if [[ -e "${codePath}" ]]; then
    result=$(sudo -u "${loggedInUser}" "${codePath}" --list-extensions --show-versions)
fi

# If no extensions are found, return an appropriate value
if [[ -z "${result}" ]]; then
    result="No extensions found"
fi

# Return result for Jamf Pro EA
echo "<result>${result}</result>"
