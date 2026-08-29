#!/bin/sh

###
#
#                    Author : Isaac Davenport
#                   Created : 08-25-2026
#             Last Modified : 08-29-2026
#                   Version : 1.1
#               Tested with : macOS 26.5.2
#
#   1.0: Initial versioned header. Promotes the currently logged-in user to
#        local admin rights and notifies them via Jamf Helper.
#   1.1: Replaced the 'dscl ... | grep -c $3' membership test, which
#        substring-matched usernames (bob matched bobby) and treated an
#        unset $3 as a match, silently exiting without promoting anyone.
#        Now uses dseditgroup checkmember, falls back to the console user
#        when $3 is not supplied, verifies the promotion succeeded, and
#        quotes expansions throughout.
#
#   Jamf parameters:
#     $3  username, passed automatically by Jamf. Falls back to the
#         currently logged-in console user when run outside a policy.
#
###

# jamfHelper location
jhelp="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"

# Jamf passes the username as $3; fall back to the console user if it is absent
targetUser="$3"
if [ -z "$targetUser" ]; then
    targetUser=$(echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ { print $3 }')
fi

# Refuse to act on an empty or system account rather than guessing
if [ -z "$targetUser" ] || [ "$targetUser" = "root" ] || [ "$targetUser" = "_mbsetupuser" ]; then
    echo "No valid user to promote, exiting"
    exit 0
fi

if ! /usr/bin/id "$targetUser" >/dev/null 2>&1; then
    echo "User $targetUser does not exist, exiting"
    exit 1
fi

# Exact group membership check, not a substring match against the member list
if /usr/sbin/dseditgroup -o checkmember -m "$targetUser" admin >/dev/null 2>&1; then
    echo "$targetUser is already in the admin group, exiting"
    exit 0
fi

echo "$targetUser is not an admin, promoting..."

if /usr/sbin/dseditgroup -o edit -a "$targetUser" -t user admin; then
    echo "$targetUser promoted to admin"
else
    echo "Failed to promote $targetUser"
    exit 1
fi

# Let the user know their rights changed
if [ -x "$jhelp" ]; then
    "$jhelp" -windowType utility \
             -title "Admin rights" \
             -description "You've been granted admin rights, please proceed with your installation." \
             -button1 "OK"
else
    echo "jamfHelper not found at $jhelp, skipping notification"
fi

exit 0
