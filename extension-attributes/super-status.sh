#!/bin/bash
###################################################################################################
# Script Name:  super-status.sh
# Author:       Isaac Davenport
# Created:      07/09/2026
#
# Purpose:
#   Jamf Pro Extension Attribute (EA) that inventories the current Superman
#   (SUPER) workflow state on macOS by evaluating the latest status from the
#   SUPER local property list and audit log.
#
#   The script normalizes detailed SUPER status messages into simplified
#   categories for inventory reporting, compliance tracking, and Smart Group
#   criteria within Jamf Pro.
#
#   Returned categories include:
#     - Inactive
#     - Pending
#     - Running SoftwareUpdate
#     - Dialog Prompts
#     - Complete
#     - Resetting
#     - Error
#     - Unknown
#
# Requirements:
#   - Superman (SUPER) installed and configured
#   - SUPER status plist available at /Library/Management/super/
#   - SUPER audit log available at /Library/Management/super/logs/
#   - Script executed by Jamf Pro as root
###################################################################################################
###################################
# Path definitions (per standard format)
###################################
SUPER_FOLDER="/Library/Management/super"
SUPER_LOG_FOLDER="${SUPER_FOLDER}/logs"

# Note: SUPER_LOCAL_PLIST is the path to the plist file (no trailing ".plist")
SUPER_LOCAL_PLIST="${SUPER_FOLDER}/com.macjutsu.super"
SUPER_AUDIT_LOG="${SUPER_LOG_FOLDER}/super-audit.log"

# Enable case-insensitive matching for all string comparisons
shopt -s nocasematch

###################################
# Read the local status via defaults read from the plist key "SuperStatus"
###################################
super_status=$(defaults read "${SUPER_LOCAL_PLIST}" SuperStatus 2>/dev/null)

###################################
# Read the last line from the audit log (if it exists)
###################################
audit_line=""
if [[ -f "$SUPER_AUDIT_LOG" ]]; then
    audit_line=$(tail -n 1 "$SUPER_AUDIT_LOG")
fi

###################################
# If neither source produced a value, report that no super status was found.
###################################
if [[ -z "$super_status" && -z "$audit_line" ]]; then
    echo "<result>No super status found.</result>"
    exit 0
fi

# For the local source, we alias the status from the plist to a variable.
local_line="$super_status"

###################################
# Function: get_epoch_timestamp
#
# Extracts the first four fields from a status string, assumed to be in the format:
#   "Day Mon dd HH:MM:SS:"
# and converts it to epoch seconds (using macOS's date command).
###################################
get_epoch_timestamp() {
    ts=$(echo "$1" | awk '{print $1" "$2" "$3" "$4}')
    epoch=$(date -j -f "%a %b %d %T" "$ts" "+%s" 2>/dev/null)
    echo "$epoch"
}

###################################
# Determine the most recent status line based on its timestamp.
###################################
chosen_line=""
source_type=""

if [[ -n "$local_line" && -n "$audit_line" ]]; then
    local_epoch=$(get_epoch_timestamp "$local_line")
    audit_epoch=$(get_epoch_timestamp "$audit_line")
    # Favor the local status if its timestamp is equal to or newer than the audit log.
    if [[ "$local_epoch" -ge "$audit_epoch" ]]; then
         chosen_line="$local_line"
         source_type="local"
    else
         chosen_line="$audit_line"
         source_type="audit"
    fi
elif [[ -n "$local_line" ]]; then
    chosen_line="$local_line"
    source_type="local"
else
    chosen_line="$audit_line"
    source_type="audit"
fi

###################################
# Initialize the final_category as Unknown; we'll override it in the mapping logic.
###################################
final_category="Unknown"

###################################
# Mapping for statuses based on the source type.
###################################
if [[ "$source_type" == "local" ]]; then
    # --- Super Status EA (Local PLIST) Mapping ---
    #
    # 1. Any status containing "Inactive Error:" or other specific download/install error is mapped to Error.
    if [[ "$chosen_line" == *"failed"* ]] || \
       [[ "$chosen_line" == *"Inactive Error:"* ]]; then
        final_category="Error"
    # 2. For any status containing "Full super workflow complete!", map to Complete,
    #    even if the status also indicates a relaunch is scheduled.
    elif [[ "$chosen_line" == *"Full super workflow complete!"* ]]; then
        final_category="Complete"
    # 3. If the status contains "Inactive:" (and wasn’t already caught), map to Inactive.
    elif [[ "$chosen_line" == *"Inactive:"* ]]; then
        final_category="Inactive"
    # 4. For statuses beginning with "Running:", further check:
    elif [[ "$chosen_line" == *"Running:"* ]]; then
        # If the status contains "Dialog", map to Dialog Prompts.
        if [[ "$chosen_line" == *"Dialog"* ]]; then
            final_category="Dialog Prompts"
        else
            final_category="Running SoftwareUpdate"
        fi
    # 5. For statuses containing "Pending:" (if none of the above matched), map to Pending.
    elif [[ "$chosen_line" == *"Pending:"* ]]; then
        final_category="Pending"
    fi

elif [[ "$source_type" == "audit" ]]; then
    # --- Super Audit EA (Audit Log) Mapping ---
    #
    # 1. Resetting: For any status indicating resets, deletions, or migrations,
    #    or containing a log creation reference.
    if [[ "$chosen_line" == *"Status: Resetting"* ]] || \
       [[ "$chosen_line" == *"Status: Deleting"* ]] || \
       [[ "$chosen_line" == *"Status: Migrating"* ]] || \
       [[ "$chosen_line" == *"log_super_audit:"* ]]; then
        final_category="Resetting"
    # 2. Pending: If the status indicates a scheduled installation or a computer restart.
    elif [[ "$chosen_line" == *"Status: Setting new scheduled installation"* ]] || \
         [[ "$chosen_line" == *"Restarting computer"* ]]; then
        final_category="Pending"
    # 3. Running SoftwareUpdate: If the status is related to softwareupdate, MDM, or installation workflows.
    elif [[ "$chosen_line" == *"softwareupdate:"* ]] || \
         [[ "$chosen_line" == *"MDM:"* ]] || \
         [[ "$chosen_line" == *"Installation:"* ]]; then
        final_category="Running SoftwareUpdate"
    # 4. For full workflow completion messages, map to Complete,
    #    even if the status also indicates a relaunch is scheduled
    elif [[ "$chosen_line" == *"Status: Full super workflow complete!"* ]]; then
            final_category="Complete"
    # 5. Complete: If the status indicates that policies, installations or updates are complete.
    elif [[ "$chosen_line" == *"Completed installation"* ]] || \
         [[ "$chosen_line" == *"completed!"* ]] || \
         [[ "$chosen_line" == *"All Jamf Pro Policies completed."* ]] || \
         [[ "$chosen_line" == *"Jamf Pro Policy"* ]] || \
         [[ "$chosen_line" == *"all available"* ]]; then
        final_category="Complete"
    # 6. Inactive: If the status indicates inactivity.
    elif [[ "$chosen_line" == *"Inactive"* ]]; then
        final_category="Inactive"
    # 7. Error: If the status contains explicit "Error:" or "Warning:" messages.
    elif [[ "$chosen_line" == *"Error:"* ]] || [[ "$chosen_line" == *"Warning:"* ]]; then
        final_category="Error"
    fi
fi

###################################
# Output the determined category in the expected Jamf Pro format.
###################################
echo "<result>$final_category</result>"

exit 0
