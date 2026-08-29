#!/bin/sh

###
#
#                    Author : Isaac Davenport
#                   Created : 08-25-2026
#             Last Modified : 08-29-2026
#                   Version : 1.1
#               Tested with : macOS 26.5.2
#
#   1.0: Initial versioned header. Demotes the logged-in user from admin to
#        standard rights (excluding a hardcoded account), then notifies them
#        via Jamf Helper.
#   1.1: Defined jamfHelper path (was undefined, so the notification never
#        displayed). Removed the early exit that made the notification
#        unreachable on the demotion path. Replaced the hardcoded exempt
#        account with an optional Jamf parameter. Replaced the GID substring
#        match with dseditgroup checkmember. Fixed an undefined variable in
#        the non-admin log line, and quoted expansions throughout.
#
#   Jamf parameters:
#     $4  (optional) account to exempt from demotion, e.g. a local admin
#         break-glass account. Leave blank to demote any admin user.
#
###

# jamfHelper location
jhelp="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"

# Account to leave alone, passed from the Jamf policy rather than hardcoded
exemptUser="$4"

# Currently logged-in console user
currentUser=$(echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ { print $3 }')

# Nothing to do at the login window or before setup completes
if [ -z "$currentUser" ] || [ "$currentUser" = "root" ] || [ "$currentUser" = "_mbsetupuser" ]; then
    echo "No console user logged in, exiting"
    exit 0
fi

# Skip the exempt account if one was supplied
if [ -n "$exemptUser" ] && [ "$currentUser" = "$exemptUser" ]; then
    echo "$currentUser is exempt from demotion, exiting"
    exit 0
fi

# Check admin group membership directly rather than substring-matching GIDs
if ! /usr/sbin/dseditgroup -o checkmember -m "$currentUser" admin >/dev/null 2>&1; then
    echo "$currentUser is not a local admin, nothing to do"
    exit 0
fi

# Demote to standard rights
if /usr/sbin/dseditgroup -o edit -n /Local/Default -d "$currentUser" -t user admin; then
    echo "$currentUser demoted to standard rights"
else
    echo "Failed to demote $currentUser"
    exit 1
fi

# Let the user know their rights changed
if [ -x "$jhelp" ]; then
    "$jhelp" -windowType utility \
             -title "Admin rights" \
             -description "Your administrator rights have expired. You now have standard rights." \
             -button1 "OK"
else
    echo "jamfHelper not found at $jhelp, skipping notification"
fi

exit 0
