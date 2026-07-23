#!/bin/bash

###
#
#                    Author : Isaac Davenport
#                   Created : 09-03-2025
#             Last Modified : 07-23-2026
#                   Version : 1.5
#               Tested with : macOS 26.5.2
#
#   1.5: swiftDialog now self-installs/updates from GitHub (Team ID verified)
#        instead of relying on the Jamf policy package. The check only runs
#        when a dialog will actually be shown (uptime >= 7 days), so machines
#        under the threshold never touch the GitHub API.
#
###

###############################################################################
# swiftDialog install / update
###############################################################################

SW_DIALOG="/usr/local/bin/dialog"
DIALOG_RELEASES_API="https://api.github.com/repos/swiftDialog/swiftDialog/releases/latest"
EXPECTED_DIALOG_TEAM_ID="PWA5E9TQ59"

logMe () {
    echo "$(/bin/date '+%Y-%m-%d %H:%M:%S'): ${1}"
}

install_dialog () {
    # Downloads and installs the latest swiftDialog PKG from GitHub,
    # verifying the Apple Developer Team ID before install.
    # Returns 0 on success, 1 on failure.

    logMe "Installing/updating swiftDialog..."

    local dialogURL
    dialogURL=$(curl -L --silent --fail "${DIALOG_RELEASES_API}" \
        | awk -F '"' "/browser_download_url/ && /pkg\"/ { print \$4; exit }")

    if [[ -z "${dialogURL}" ]]; then
        logMe "ERROR: Could not determine swiftDialog download URL (no network or GitHub API unavailable)."
        return 1
    fi

    local workDirectory tempDirectory
    workDirectory=$( basename "$0" )
    tempDirectory=$( mktemp -d "/private/tmp/${workDirectory}.XXXXXX" )

    if ! curl --location --silent --fail "${dialogURL}" -o "${tempDirectory}/Dialog.pkg"; then
        logMe "ERROR: Failed to download swiftDialog PKG from ${dialogURL}"
        /bin/rm -rf "${tempDirectory}"
        return 1
    fi

    local teamID
    teamID=$(spctl -a -vv -t install "${tempDirectory}/Dialog.pkg" 2>&1 \
        | awk '/origin=/ {print $NF }' | tr -d '()')

    if [[ "${teamID}" != "${EXPECTED_DIALOG_TEAM_ID}" ]]; then
        logMe "ERROR: swiftDialog Team ID verification FAILED (expected ${EXPECTED_DIALOG_TEAM_ID}, got '${teamID}'). Aborting install."
        /bin/rm -rf "${tempDirectory}"
        return 1
    fi

    if ! /usr/sbin/installer -pkg "${tempDirectory}/Dialog.pkg" -target / >/dev/null 2>&1; then
        logMe "ERROR: swiftDialog installer failed."
        /bin/rm -rf "${tempDirectory}"
        return 1
    fi

    /bin/rm -rf "${tempDirectory}"

    if [[ ! -x "${SW_DIALOG}" ]]; then
        logMe "ERROR: swiftDialog install completed but binary not found at ${SW_DIALOG}"
        return 1
    fi

    logMe "swiftDialog installed: version $("${SW_DIALOG}" --version 2>/dev/null)"
    return 0
}

get_latest_dialog_version () {
    # Echoes the latest release tag (e.g. "2.5.5"), empty on failure
    curl -L --silent --fail "${DIALOG_RELEASES_API}" \
        | awk -F '"' '/"tag_name"/ { print $4; exit }' \
        | sed 's/^v//'
}

check_swift_dialog () {
    # Ensures swiftDialog is present and up to date with the latest GitHub release.
    # - Missing + install fails  -> hard fail (dialogs are required)
    # - Present but outdated + update fails (e.g. offline) -> continue with existing version
    logMe "Ensuring swiftDialog is installed and current..."

    local latest_ver installed_ver
    latest_ver=$(get_latest_dialog_version)

    if [[ ! -x "${SW_DIALOG}" ]]; then
        logMe "swiftDialog not found at ${SW_DIALOG}; installing latest..."
        if ! install_dialog; then
            logMe "ERROR: swiftDialog is required but could not be installed."
            exit 1
        fi
        return 0
    fi

    installed_ver=$("${SW_DIALOG}" --version 2>/dev/null)
    if [[ -z "${installed_ver}" ]]; then
        logMe "swiftDialog present but version unreadable; reinstalling latest..."
        if ! install_dialog; then
            logMe "ERROR: swiftDialog is required but could not be (re)installed."
            exit 1
        fi
        return 0
    fi

    if [[ -z "${latest_ver}" ]]; then
        logMe "WARNING: Could not query latest swiftDialog release (offline?). Continuing with installed version ${installed_ver}."
        return 0
    fi

    # installed_ver looks like "2.5.5.4802"; latest tag looks like "2.5.5"
    if [[ "${installed_ver}" == "${latest_ver}"* ]]; then
        logMe "swiftDialog is current (version ${installed_ver})"
    else
        logMe "swiftDialog ${installed_ver} is outdated (latest: ${latest_ver}); updating..."
        if ! install_dialog; then
            logMe "WARNING: swiftDialog update failed; continuing with existing version ${installed_ver}."
        fi
    fi
}

###############################################################################
# Main
###############################################################################

# Kill pending Dialog
killall Dialog 2>/dev/null

# Get current user
CURRENT_USER=$(stat -f %Su /dev/console)
USER_ID=$(id -u "$CURRENT_USER")

# 1. Ensure a real console user is logged into the GUI
if [ "$CURRENT_USER" = "loginwindow" ] || [ -z "$CURRENT_USER" ]; then
    echo "No logged-in user. Exiting."
    exit 0
fi

#  2. Ensure the Mac is awake (not sleeping)
# sleep_state="$(pmset -g assertions | grep -i 'PreventUserIdleSystemSleep' | awk '{print $NF}')"
# if [[ "$sleep_state" != "1" ]]; then
#     echo "Machine is likely asleep or not fully awake. Exiting."
#     exit 0
# fi

# Determine current Unix epoch time

current_unix_time="$(date '+%s')"

# This reports the unix epoch time that the kernel was booted
boot_unix_time="$(sysctl -n kern.boottime | awk -F 'sec = |, usec' '{ print $2; exit }')"

# Get uptime in seconds
uptime_seconds="$((current_unix_time - boot_unix_time))"

# Calculate uptime in days
uptime_minutes="$((uptime_seconds / 60))"

uptime_hours="$((uptime_minutes / 60))"

uptime_days="$((uptime_hours / 24))"

# Hardcoded uptime for testing on your own computer.
#uptime_days="13"

# Exit early before touching swiftDialog/GitHub if no dialog will be shown
if [ "$uptime_days" -le 6 ]; then
 echo "Uptime less than or equal to 6 days. Exit."
 exit 0
fi

# A dialog WILL be shown — make sure swiftDialog is installed and current
check_swift_dialog

if [ "$uptime_days" -ge 7 ] && [ "$uptime_days" -le 13 ]; then
 echo "Uptime between 7 and 13 days. Dialog."
 afplay "/System/Library/Sounds/Funk.aiff" & disown
 launchctl asuser "$USER_ID" sudo -u "$CURRENT_USER" /usr/local/bin/dialog \
 --title "Restart required" \
 --message "**${uptime_days} days without a reboot!** \n\nYour Mac needs to restart to stay within compliance. Important security updates may also be installed during the process. Please save your work and press Restart. If you press Defer, you'll be reminded again in 24 hours.\n\nPlease note that if the timer reaches zero, your computer will be automatically restarted. Thank you for your cooperation." \
 --icon "https://ontinue.jamfcloud.com/api/v1/branding-images/download/6" \
 --button1text "Restart now" \
 --button2text "Defer" \
 --timer 900 \
 --width 650 --height 280 \
 --messagefont size=13 \
 --position bottomright \
 --moveable \
 --ontop
 dialogResults=$?

elif [ "$uptime_days" -ge 14 ]; then
 echo "Uptime greater than 14 days. Last warning dialog."
 osascript -e "set volume output volume 80 --100%"
 afplay "/System/Library/Sounds/Sosumi.aiff" & disown
 sleep 0.2
 afplay "/System/Library/Sounds/Sosumi.aiff" & disown
 sleep 0.4
 afplay "/System/Library/Sounds/Sosumi.aiff" & disown

 launchctl asuser "$USER_ID" sudo -u "$CURRENT_USER" /usr/local/bin/dialog \
 --title "Restart required" \
 --message "**${uptime_days} days without a reboot!** \n\nYour Mac needs to restart to stay within compliance. Important security updates may also be installed during the process.\n\n**After pressing I understand, you will have 10 minutes to restart your computer.**" \
 --icon "https://ontinue.jamfcloud.com/api/v1/branding-images/download/6" \
 --button1text "I understand" \
 --width 650 --height 230 \
 --messagefont size=13 \
 --hidetimerbar \
 --blurscreen \
 --ontop

 launchctl asuser "$USER_ID" sudo -u "$CURRENT_USER" /usr/local/bin/dialog \
 --title none \
 --message "Your computer will restart when the timer reaches zero. Please save your work now." \
 --button1text "Restart now" \
 --timer 600 \
 --width 320 --height 115 \
 --messagefont size=13 \
 --position bottomright \
 --icon none \
 --ontop
 dialogResults=$?
fi

if [ "$dialogResults" = "0" ]; then
 # Button pressed. Graceful restart. Unsaved documents will stop the process.
 echo "Restart pressed"
 sleep 5
 shutdown -r now
elif [ "$dialogResults" = "2" ]; then
 # Dialog canceled.
 echo "Defer pressed"
 afplay "/System/Library/Sounds/Funk.aiff" & disown
 osascript -e 'display dialog "You will be reminded again in 24 hours." with title "Restart Deferred" buttons {"OK"} default button "OK"'
elif [ "$dialogResults" = "4" ]; then
 # Timer expired. Graceful restart only.
 echo "Timer expired, restarting now"
 afplay "/System/Library/Sounds/Sosumi.aiff"  & disown
 osascript -e 'display dialog "Your Mac will restart soon to stay within compliance and apply latest patches." with title "Restart Required" buttons {"OK"} default button "OK"'
 sleep 15
 shutdown -r now
else
 echo "${uptime_days}"
 echo "Could be an error in the dialog command"
 echo "Could be the process killed somehow."
 echo "Exit with an error code."
 exit "$dialogResults"
fi
