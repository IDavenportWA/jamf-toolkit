#!/bin/bash

###
#
#                    Author : Isaac Davenport
#                   Created : 07-22-2026
#             Last Modified : 07-23-2026
#                   Version : 1.1
#               Tested with : macOS 26.5.2
# 
#   1.1: swiftDialog now self-installs/updates from GitHub (Team ID verified)
#        instead of bailing out when not installed. Runs before the status
#        window launches. Window auto-closes 15 seconds after all steps complete (user can
#        still press Close sooner); guaranteed teardown so the script always
#        ends.
#   1.0: Initial version — jamf recon, killall jamf, jamf policy with live
#        command output and per-step status in one swiftDialog window.
#
###

################################################################################
# Jamf Maintenance — swiftDialog
#
# Runs:
#   1. jamf recon
#   2. killall jamf
#   3. jamf policy
#
# Displays live command output and success/failure status in one movable window.
#
# NOTE: Run manually (sudo) or via Self Service. Do NOT deploy as a
# check-in-triggered policy — killall jamf kills the policy's own parent
# process and the policy log will stick at "Pending".
################################################################################

###############################################################################
# Configuration
###############################################################################

DIALOG="/usr/local/bin/dialog"
JAMF="/usr/local/bin/jamf"

COMMAND_FILE="/var/tmp/jamf-maintenance-dialog.log"
OUTPUT_FILE="/var/tmp/jamf-maintenance-output.log"

###############################################################################
# swiftDialog install / update
###############################################################################

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

    if [[ ! -x "${DIALOG}" ]]; then
        logMe "ERROR: swiftDialog install completed but binary not found at ${DIALOG}"
        return 1
    fi

    logMe "swiftDialog installed: version $("${DIALOG}" --version 2>/dev/null)"
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

    if [[ ! -x "${DIALOG}" ]]; then
        logMe "swiftDialog not found at ${DIALOG}; installing latest..."
        if ! install_dialog; then
            logMe "ERROR: swiftDialog is required but could not be installed."
            osascript -e 'display dialog "swiftDialog could not be installed. Check network access and try again." buttons {"OK"} default button 1' 2>/dev/null
            exit 1
        fi
        return 0
    fi

    installed_ver=$("${DIALOG}" --version 2>/dev/null)
    if [[ -z "${installed_ver}" ]]; then
        logMe "swiftDialog present but version unreadable; reinstalling latest..."
        if ! install_dialog; then
            logMe "ERROR: swiftDialog is required but could not be (re)installed."
            osascript -e 'display dialog "swiftDialog could not be reinstalled. Check network access and try again." buttons {"OK"} default button 1' 2>/dev/null
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
# Logged-in User
###############################################################################

LOGGED_IN_USER=$(stat -f "%Su" /dev/console 2>/dev/null)
USER_UID=""

if [[ -n "$LOGGED_IN_USER" ]] &&
   [[ "$LOGGED_IN_USER" != "root" ]] &&
   [[ "$LOGGED_IN_USER" != "loginwindow" ]]; then

    USER_UID=$(id -u "$LOGGED_IN_USER" 2>/dev/null)
fi

###############################################################################
# Cleanup
###############################################################################

cleanup() {
    rm -f "$COMMAND_FILE" "$OUTPUT_FILE"
}

trap cleanup EXIT

###############################################################################
# Validation
###############################################################################

if [[ ! -x "$JAMF" ]]; then
    osascript -e 'display dialog "The Jamf binary was not found at /usr/local/bin/jamf." buttons {"OK"} default button 1'
    exit 1
fi

if [[ -z "$LOGGED_IN_USER" ]] || [[ -z "$USER_UID" ]]; then
    echo "No logged-in user session was found."
    exit 1
fi

# Ensure swiftDialog is installed and up to date (replaces the old
# "swiftDialog is not installed" bail-out)
check_swift_dialog

rm -f "$COMMAND_FILE" "$OUTPUT_FILE"
touch "$COMMAND_FILE" "$OUTPUT_FILE"

# The logged-in user only needs to read the command file.
chmod 644 "$COMMAND_FILE" "$OUTPUT_FILE"

###############################################################################
# Helper Functions
###############################################################################

send_dialog_command() {
    echo "$1" >> "$COMMAND_FILE"
}

sanitize_output() {
    local text="$1"

    # Remove carriage returns, line breaks, and backticks that may interfere
    # with swiftDialog's command file or Markdown rendering.
    printf '%s' "$text" |
        tr '\r\n' '  ' |
        sed 's/`/'"'"'/g'
}

update_message() {
    local command_name="$1"
    local output_line="$2"

    command_name=$(sanitize_output "$command_name")
    output_line=$(sanitize_output "$output_line")

    send_dialog_command \
        "message: **Currently running:** \`$command_name\`  \n\n**Latest output:**  \n\`$output_line\`"
}

set_list_status() {
    local list_index="$1"
    local status="$2"
    local status_text="$3"

    send_dialog_command \
        "listitem: index: $list_index, status: $status, statustext: $status_text"
}

run_command() {
    local list_index="$1"
    local display_name="$2"
    shift 2

    local output_line=""
    local exit_code=0
    local exit_file=""

    exit_file=$(mktemp "/var/tmp/jamf-maintenance-exit.XXXXXX")

    set_list_status "$list_index" "wait" "Running"
    update_message "$display_name" "Starting command..."

    ############################################################################
    # Run the command and stream output
    #
    # The command runs in a subshell so its exit code can be written separately.
    # This avoids relying on pipeline behavior in the older Bash version
    # included with macOS.
    ############################################################################

    (
        "$@"
        echo "$?" > "$exit_file"
    ) 2>&1 |
        while IFS= read -r output_line || [[ -n "$output_line" ]]; do
            echo "$output_line" >> "$OUTPUT_FILE"
            update_message "$display_name" "$output_line"
        done

    if [[ -s "$exit_file" ]]; then
        exit_code=$(cat "$exit_file")
    else
        exit_code=1
    fi

    rm -f "$exit_file"

    if [[ "$exit_code" -eq 0 ]]; then
        set_list_status "$list_index" "success" "Completed"
        update_message "$display_name" "Command completed successfully."
    else
        set_list_status "$list_index" "fail" "Failed — exit code $exit_code"
        update_message "$display_name" "Command failed with exit code $exit_code."
    fi

    return "$exit_code"
}

###############################################################################
# Launch swiftDialog
#
# Root context: launching swiftDialog through the logged-in user's GUI
# session makes the window behave like a normal macOS window.
###############################################################################

launchctl asuser "$USER_UID" \
    sudo -u "$LOGGED_IN_USER" \
    "$DIALOG" \
        --title "Jamf Maintenance" \
        --message "**Currently running:** Preparing...\n\n**Latest output:** Waiting to begin." \
        --icon "SF=gearshape.2" \
        --width 750 \
        --height 500 \
        --moveable \
        --resizable \
        --windowbuttons "min,max" \
        --ontop \
        --listitem "Jamf Recon,status=pending" \
        --listitem "Stop Jamf Processes,status=pending" \
        --listitem "Jamf Policy,status=pending" \
        --button1text "Close" \
        --button1disabled \
        --commandfile "$COMMAND_FILE" &

DIALOG_PID=$!

sleep 2

###############################################################################
# Confirm Dialog Started
###############################################################################

if ! kill -0 "$DIALOG_PID" 2>/dev/null; then
    echo "swiftDialog failed to launch."
    exit 1
fi

###############################################################################
# 1. Jamf Recon
###############################################################################

run_command 0 "jamf recon" "$JAMF" recon
RECON_EXIT_CODE=$?

###############################################################################
# 2. Stop Jamf Processes
###############################################################################

set_list_status 1 "wait" "Running"
update_message "killall jamf" "Checking for running Jamf processes..."

if pgrep -x "jamf" >/dev/null 2>&1; then

    KILL_OUTPUT=$(killall jamf 2>&1)
    KILL_EXIT_CODE=$?

    if [[ -n "$KILL_OUTPUT" ]]; then
        echo "$KILL_OUTPUT" >> "$OUTPUT_FILE"
        update_message "killall jamf" "$KILL_OUTPUT"
    fi

    if [[ "$KILL_EXIT_CODE" -eq 0 ]]; then
        set_list_status 1 "success" "Stopped"
        update_message "killall jamf" "Jamf processes stopped successfully."
    else
        set_list_status 1 "fail" "Failed — exit code $KILL_EXIT_CODE"
        update_message "killall jamf" \
            "${KILL_OUTPUT:-Unable to stop one or more Jamf processes.}"
    fi

else
    KILL_EXIT_CODE=0

    set_list_status 1 "success" "No processes running"
    update_message "killall jamf" "No running Jamf processes were found."
fi

###############################################################################
# 3. Jamf Policy
###############################################################################

run_command 2 "jamf policy" "$JAMF" policy
POLICY_EXIT_CODE=$?

###############################################################################
# Finish
###############################################################################

FAILURE_COUNT=0

[[ "$RECON_EXIT_CODE" -ne 0 ]] && ((FAILURE_COUNT++))
[[ "$KILL_EXIT_CODE" -ne 0 ]] && ((FAILURE_COUNT++))
[[ "$POLICY_EXIT_CODE" -ne 0 ]] && ((FAILURE_COUNT++))

if [[ "$FAILURE_COUNT" -eq 0 ]]; then
    send_dialog_command \
        "message: **Jamf maintenance finished successfully.**  \n\nAll three commands completed without errors. This window will close automatically in 15 seconds."
else
    send_dialog_command \
        "message: **Jamf maintenance finished with $FAILURE_COUNT error(s).**  \n\nReview the command statuses below. This window will close automatically in 15 seconds."
fi

send_dialog_command "button1: enable"

###############################################################################
# Auto-close 15 seconds after completion
#
# The user can press Close sooner; if the window is still open after 15
# seconds, it is told to quit, with a force-kill fallback so the script
# always ends.
###############################################################################

for (( i = 0; i < 15; i++ )); do
    kill -0 "$DIALOG_PID" 2>/dev/null || break
    sleep 1
done

if kill -0 "$DIALOG_PID" 2>/dev/null; then
    send_dialog_command "quit:"

    for (( i = 0; i < 10; i++ )); do
        kill -0 "$DIALOG_PID" 2>/dev/null || break
        sleep 1
    done

    kill "$DIALOG_PID" 2>/dev/null
fi

wait "$DIALOG_PID" 2>/dev/null

if [[ "$FAILURE_COUNT" -eq 0 ]]; then
    exit 0
else
    exit 1
fi
