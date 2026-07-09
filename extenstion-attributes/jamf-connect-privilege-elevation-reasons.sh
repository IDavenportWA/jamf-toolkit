#!/bin/zsh
###################################################################################################
# Script Name:  jamfConnectPrivilegeElevationReasons.sh
# Author:       Isaac Davenport
# Created:      07/09/2026
#
# Purpose:
#   Jamf Pro Extension Attribute (EA) that inventories the most recent admin
#   privilege elevation reasons submitted through Jamf Connect / Self Service+.
#   The script checks the local Jamf Connect elevation reason log, extracts the
#   last five user-provided justification messages, and returns them for
#   inventory reporting, auditing, and compliance review within Jamf Pro.
#
# Requirements:
#   - Jamf Connect Temporary User Permissions configured
#   - UserPromotionReason enabled in the Jamf Connect configuration profile
#   - Script executed by Jamf Pro
###################################################################################################

###################################
# Retrieve Jamf Connect Privilege Elevation Reasons
###################################

reasonLog="/Library/Logs/JamfConnect/UserElevationReasons.log"

if [[ -f "$reasonLog" ]]; then
    reasons=$(/usr/bin/tail -n 5 "$reasonLog")
else
    reasons="No Jamf Connect privilege elevation reasons found"
fi

###################################
# Output Result for Jamf Pro EA
###################################

echo "<result>"
echo "$reasons"
echo "</result>"
