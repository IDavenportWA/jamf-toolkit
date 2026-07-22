#!/bin/bash

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
# Designed to run from a Jamf Pro policy as root.
################################################################################

###############################################################################
# Configuration
###############################################################################

DIALOG="/usr/local/bin/dialog"
JAMF="/usr/local/bin/jamf"

COMMAND_FILE="/var/tmp/jamf-maintenance-dialog.log"
OUTPUT_FILE="/var/tmp/jamf-maintenance-output.log"

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

if [[ ! -x "$DIALOG" ]]; then
    osascript -e 'display dialog "swiftDialog is not installed." buttons {"OK"} default button 1'
    exit 1
fi

if [[ ! -x "$JAMF" ]]; then
    osascript -e 'display dialog "The Jamf binary was not found at /usr/local/bin/jamf." buttons {"OK"} default button 1'
    exit 1
fi

if [[ -z "$LOGGED_IN_USER" ]] || [[ -z "$USER_UID" ]]; then
    echo "No logged-in user session was found."
    exit 1
fi

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
# Jamf policies run as root. Launching swiftDialog through the logged-in user's
# GUI session makes the window behave like a normal macOS window.
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
        "message: **Jamf maintenance finished successfully.**  \n\nAll three commands completed without errors."
else
    send_dialog_command \
        "message: **Jamf maintenance finished with $FAILURE_COUNT error(s).**  \n\nReview the command statuses below."
fi

send_dialog_command "button1: enable"

###############################################################################
# Keep Script Running Until Window Closes
###############################################################################

wait "$DIALOG_PID"

if [[ "$FAILURE_COUNT" -eq 0 ]]; then
    exit 0
else
    exit 1
fi
