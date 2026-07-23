#!/bin/zsh --no-rcs

###
#
#                    Author : Isaac Davenport
#                   Created : 07-23-2026
#             Last Modified : 07-23-2026
#                   Version : 1.0
#               Tested with : macOS 26.5.2
#
#   1.0: Initial agnostic version.
#
###

################################################################################
# ForcePlatformSSO_Agnostic.sh
#
# Purpose:
#   No Jamf triggers, API calls, group/scope changes, or support files.
#   Assumes the Platform SSO profile + Company Portal are already deployed.
#
# Behavior:
#   1) Install/update swiftDialog from GitHub (Team ID verified)
#   2) Check Focus mode; optionally enforce Touch ID enrollment
#   3) Best-effort enable Company Portal extensions (PlugInKit)
#   4) Show bottom-right status card, restart AppSSOAgent to trigger prompt
#   5) Poll for registrationCompleted=true, updating the card
#   6) Success: run jamfAAD (best-effort), show checkmark, close, exit 0
#   7) Timeout: close card, show failure modal, exit 1
#
# UX notes:
#   - Card and Touch ID prompt open bottom-right (moveable, never repositioned)
#     to stay clear of the notification, Entra window, and System Settings.
#   - Timer bar hidden; card timer outlives polling so status updates land.
################################################################################

setopt pipefail
export PATH=/usr/bin:/bin:/usr/sbin:/sbin

SCRIPT_NAME="ForcePlatformSSO_Agnostic"
LOG_FILE="/var/log/${SCRIPT_NAME}.log"

SW_DIALOG="/usr/local/bin/dialog"
JAMF_AAD_BINARY="/usr/local/jamf/bin/jamfAAD"

# swiftDialog install/update settings
DIALOG_RELEASES_API="https://api.github.com/repos/swiftDialog/swiftDialog/releases/latest"
EXPECTED_DIALOG_TEAM_ID="PWA5E9TQ59"

# Company Portal extensions to enable (best-effort)
APP_EXTENSIONS=(
  "com.microsoft.CompanyPortalMac.ssoextension"
  "com.microsoft.CompanyPortalMac.Mac-Autofill-Extension"
)

# Jamf Parameters (optional)
# $3 is typically logged-in user passed by Jamf
JAMF_LOGGED_IN_USER="${3:-""}"
CHECK_FOR_TOUCHID="${4:-yes}"
RUN_JAMF_AAD_ON_ERROR="${5:-yes}"
MAX_WAIT_SECONDS="${6:-300}"

# Status card lifetime: must outlive the polling window so the success state
# can be shown in-card. Param 7 can override, otherwise MAX_WAIT + 30s.
SD_TIMER_SECONDS="${7:-$(( MAX_WAIT_SECONDS + 30 ))}"

# Determine logged-in console user + UID/home
LOGGED_IN_USER=$( scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }' )
USER_UID=$(id -u "$LOGGED_IN_USER" 2>/dev/null)
USER_DIR=$( dscl . -read "/Users/${LOGGED_IN_USER}" NFSHomeDirectory 2>/dev/null | awk '{ print $2 }' )

FOCUS_FILE="$USER_DIR/Library/DoNotDisturb/DB/Assertions.json"

# Greeting
HOUR=$(date +%H)
case $HOUR in
  0[0-9]|1[0-1]) GREET="morning" ;;
  1[2-7])        GREET="afternoon" ;;
  *)             GREET="evening" ;;
esac
SD_DIALOG_GREETING="Good $GREET"

# Derive a friendly first name (no zsh ${(C)...} expansions)
# If Jamf doesn't pass param 3, fall back to console user
if [[ -z "$JAMF_LOGGED_IN_USER" ]]; then
  JAMF_LOGGED_IN_USER="$LOGGED_IN_USER"
fi
SD_FIRST_NAME=$(echo "${JAMF_LOGGED_IN_USER}" | awk -F. '{print $1}' | awk '{print toupper(substr($0,1,1)) substr($0,2)}')

# Temp command file for dialog
DIALOG_COMMAND_FILE=$(mktemp "/var/tmp/${SCRIPT_NAME}_cmd.XXXXX")
chmod 666 "${DIALOG_COMMAND_FILE}"

############################################
# Logging / Utilities
############################################

create_log_file () {
  [[ ! -f "${LOG_FILE}" ]] && /usr/bin/touch "${LOG_FILE}"
  /bin/chmod 644 "${LOG_FILE}"
}

logMe () {
  echo "$(/bin/date '+%Y-%m-%d %H:%M:%S'): ${1}" | tee -a "${LOG_FILE}"
}

cleanup_and_exit () {
  [[ -f "${DIALOG_COMMAND_FILE}" ]] && /bin/rm -f "${DIALOG_COMMAND_FILE}"
  exit "${1}"
}

runAsUser () {
  # Run a command as the logged-in user (required for app-sso, pluginkit, bioutil)
  launchctl asuser "${USER_UID}" /usr/bin/sudo -u "${LOGGED_IN_USER}" -- "$@"
}

dialog_cmd () {
  # Send a command to the running status card via its command file
  echo "$1" >> "${DIALOG_COMMAND_FILE}"
}

############################################
# swiftDialog install / update
############################################

install_dialog () {
  # Downloads and installs the latest swiftDialog PKG from GitHub,
  # verifying the Apple Developer Team ID before install.
  # Returns 0 on success, 1 on failure.

  logMe "Installing/updating swiftDialog..."

  # Get the URL of the latest PKG from the swiftDialog GitHub repo
  local dialogURL
  dialogURL=$(curl -L --silent --fail "${DIALOG_RELEASES_API}" \
    | awk -F '"' "/browser_download_url/ && /pkg\"/ { print \$4; exit }")

  if [[ -z "${dialogURL}" ]]; then
    logMe "ERROR: Could not determine swiftDialog download URL (no network or GitHub API unavailable)."
    return 1
  fi

  # Create a temporary working directory
  local workDirectory tempDirectory
  workDirectory=$( basename "$0" )
  tempDirectory=$( mktemp -d "/private/tmp/${workDirectory}.XXXXXX" )

  # Download the installer package
  if ! curl --location --silent --fail "${dialogURL}" -o "${tempDirectory}/Dialog.pkg"; then
    logMe "ERROR: Failed to download swiftDialog PKG from ${dialogURL}"
    /bin/rm -rf "${tempDirectory}"
    return 1
  fi

  # Verify the download's Team ID
  local teamID
  teamID=$(spctl -a -vv -t install "${tempDirectory}/Dialog.pkg" 2>&1 \
    | awk '/origin=/ {print $NF }' | tr -d '()')

  if [[ "${teamID}" != "${EXPECTED_DIALOG_TEAM_ID}" ]]; then
    logMe "ERROR: swiftDialog Team ID verification FAILED (expected ${EXPECTED_DIALOG_TEAM_ID}, got '${teamID}'). Aborting install."
    /bin/rm -rf "${tempDirectory}"
    return 1
  fi

  # Install
  if ! /usr/sbin/installer -pkg "${tempDirectory}/Dialog.pkg" -target / >/dev/null 2>&1; then
    logMe "ERROR: swiftDialog installer failed."
    /bin/rm -rf "${tempDirectory}"
    return 1
  fi

  /bin/rm -rf "${tempDirectory}"

  # Confirm binary landed
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
      cleanup_and_exit 1
    fi
    return 0
  fi

  installed_ver=$("${SW_DIALOG}" --version 2>/dev/null)
  if [[ -z "${installed_ver}" ]]; then
    logMe "swiftDialog present but version unreadable; reinstalling latest..."
    if ! install_dialog; then
      logMe "ERROR: swiftDialog is required but could not be (re)installed."
      cleanup_and_exit 1
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

############################################
# Preflight
############################################

check_focus_status () {
  local results="off"
  if [[ -f "$FOCUS_FILE" ]] && grep -q '"storeAssertionRecords"' "$FOCUS_FILE" 2>/dev/null; then
    results="on"
  fi
  echo "${results}"
}

############################################
# Dialogs
############################################

display_failure_message () {
  local msg="$1"
  "${SW_DIALOG}" \
    --title "Platform SSO Registration" \
    --message "**Registration could not be completed**<br><br>${msg}" \
    --icon "SF=exclamationmark.triangle.fill,colour=auto" \
    --button1text "OK" \
    --ontop \
    --moveable \
    2>/dev/null
}

display_registration_card () {
  # Compact, live-updating status card. Progress text is updated by the
  # poll loop via the command file.
  local focus_status="$1"

  local message="${SD_DIALOG_GREETING} ${SD_FIRST_NAME} — a macOS notification will appear in the top right corner shortly. Click **Register** and sign in to complete Platform SSO registration."
  if [[ "${focus_status}" == "on" ]]; then
    message+="<br><br>**Focus Mode is on** — open Notification Center (click the clock, top-right) to find the prompt."
  fi

  # Opens in the bottom-right corner (moveable) and is never repositioned,
  # keeping it clear of the macOS notification (top-right) and the centered
  # Entra sign-in window.
  "${SW_DIALOG}" \
    --title "Register Platform Single Sign-on" \
    --message "${message}" \
    --messagefont "size=14" \
    --icon "SF=person.crop.circle.badge.checkmark,colour=auto" \
    --iconsize 96 \
    --button1text "Please wait…" \
    --button1disabled \
    --width 560 \
    --height 380 \
    --position "bottomright" \
    --moveable \
    --progress \
    --progresstext "Waiting for you to click Register…" \
    --timer "${SD_TIMER_SECONDS}" \
    --hidetimerbar \
    --ignorednd \
    --ontop \
    --commandfile "${DIALOG_COMMAND_FILE}" \
    2>/dev/null &
}

card_show_success () {
  # Transform the card into a success state, hold briefly, then close it.
  dialog_cmd "progress: complete"
  dialog_cmd "progresstext: Registration complete — you're all set."
  dialog_cmd "icon: SF=checkmark.circle.fill,colour=auto"
  dialog_cmd "message: Platform SSO registration finished successfully. You can close this window — it will close itself in a moment."
  dialog_cmd "button1text: Close"
  dialog_cmd "button1: enable"
  sleep 4
  dialog_cmd "quit:"
}

card_close () {
  dialog_cmd "quit:"
}

############################################
# Platform SSO helpers
############################################

getValueOf () {
  # Usage: getValueOf key "text block"
  echo "$2" | grep "$1" | awk -F ":" '{print $2}' | tr -d "," | xargs
}

get_sso_status () {
  runAsUser app-sso platform -s 2>/dev/null
}

kill_sso_agent () {
  pkill AppSSOAgent 2>/dev/null
  sleep 1
}

############################################
# Touch ID
############################################

touch_id_status () {
  local hw="Absent"
  local enrolled="false"
  local retval="Absent"

  local bioOutput
  bioOutput=$(ioreg -l 2>/dev/null)

  if [[ "${bioOutput}" == *"+-o AppleBiometricSensor"* ]]; then
    hw="Present"
  elif [[ "${bioOutput}" =~ '"AppleBiometricSensor"=([0-9]+)' && ${match[1]} -gt 0 ]]; then
    hw="Present"
  elif system_profiler SPUSBDataType 2>/dev/null | grep -q "Magic Keyboard.*Touch ID"; then
    hw="Present"
  fi

  if [[ "${hw}" == "Present" ]]; then
    local bioCount
    bioCount=$(runAsUser bioutil -c 2>/dev/null | awk '/biometric template/{print $3}' | grep -Eo '^[0-9]+$' || echo "0")
    [[ "${bioCount}" -gt 0 ]] && enrolled="true"

    if [[ "${enrolled}" == "true" ]]; then
      retval="Enabled"
    else
      retval="Not enabled"
    fi
  fi

  echo "${retval}"
}

force_touch_id () {
  while true; do
    open "x-apple.systempreferences:com.apple.Touch-ID-Settings.extension" 2>/dev/null

    # Opens in the bottom-right corner (moveable) and is never repositioned,
    # so it stays clear of the System Settings Touch ID pane.
    "${SW_DIALOG}" \
      --title "Touch ID required for Platform SSO" \
      --message "Touch ID needs to be enabled. Please add at least one fingerprint. Press next when completed." \
      --icon "SF=touchid,colour=auto" \
      --style mini \
      --position "bottomright" \
      --moveable \
      --button1text "Next" \
      --button2text "Abort" \
      --quitkey 0 \
      --ontop \
      2>/dev/null

    local buttonpress=$?
    local tid_status
    tid_status=$(touch_id_status)

    if [[ "${tid_status}" == "Enabled" ]]; then
      break
    fi

    if [[ "${buttonpress}" -eq 2 ]]; then
      killall "System Settings" >/dev/null 2>&1
      return 1
    fi
  done

  killall "System Settings" >/dev/null 2>&1
  return 0
}

############################################
# Extensions (best-effort)
############################################

enable_app_extensions () {
  for extension in "${APP_EXTENSIONS[@]}"; do
    logMe "Checking extension: ${extension}"

    local results
    results=$(runAsUser pluginkit -m 2>/dev/null | grep "${extension}")

    if [[ -z "${results}" ]]; then
      logMe "WARNING: Extension not found: ${extension} (skipping)"
      continue
    fi

    if [[ "$(echo "${results}" | awk '{print $1}')" == "+" ]]; then
      logMe "INFO: ${extension} already enabled"
    else
      logMe "INFO: Enabling ${extension}..."
      runAsUser pluginkit -e use -i "${extension}" 2>/dev/null
    fi
  done
}

############################################
# Jamf AAD compliance (best-effort)
############################################

jamf_check_aad () {
  # return 0 on success, 1 on failure
  if [[ ! -x "${JAMF_AAD_BINARY}" ]]; then
    logMe "WARNING: jamfAAD not found at ${JAMF_AAD_BINARY}"
    return 1
  fi

  logMe "Checking Jamf AAD compliance info (jamfAAD gatherAADInfo)..."
  local jamf_response
  jamf_response=$(runAsUser "${JAMF_AAD_BINARY}" gatherAADInfo 2>&1)

  if echo "${jamf_response}" | grep -q "AAD ID acquired"; then
    logMe "INFO: Jamf compliance updated ('AAD ID acquired')."
    return 0
  else
    logMe "WARNING: jamfAAD did not report 'AAD ID acquired'. Output:\n${jamf_response}"
    return 1
  fi
}

############################################
# Main
############################################

create_log_file

# Exit gracefully if no console user (common for recurring check-ins)
if [[ -z "${LOGGED_IN_USER}" || "${LOGGED_IN_USER}" == "root" || -z "${USER_UID}" ]]; then
  logMe "No console user detected. Exiting."
  cleanup_and_exit 0
fi

check_swift_dialog

FOCUS_STATUS=$(check_focus_status)
logMe "INFO: Focus mode is ${FOCUS_STATUS}"

# Optional Touch ID enforcement
if [[ "${CHECK_FOR_TOUCHID:l}" == "yes" ]]; then
  TOUCH_ID_STATUS=$(touch_id_status)
  logMe "INFO: Touch ID Status: ${TOUCH_ID_STATUS}"

  if [[ "${TOUCH_ID_STATUS}" == "Not enabled" ]]; then
    logMe "INFO: Forcing Touch ID enrollment..."
    force_touch_id || { logMe "ERROR: User aborted Touch ID enrollment."; cleanup_and_exit 1; }
  fi
fi

# Best-effort enable extensions
enable_app_extensions

# Check current Platform SSO registration state
ssoStatus="$(get_sso_status)"

if [[ -z "${ssoStatus}" ]]; then
  display_failure_message "Platform SSO status could not be read (app-sso returned no output). Ensure the Platform SSO profile is installed and Company Portal is present, then try again."
  cleanup_and_exit 1
fi

if [[ "$(getValueOf registrationCompleted "${ssoStatus}")" == "true" ]]; then
  logMe "INFO: Platform SSO is already registered. Exiting."
  cleanup_and_exit 0
fi

# Show status card + trigger registration notification
logMe "INFO: Showing registration status card..."
display_registration_card "${FOCUS_STATUS}"
sleep 1
dialog_cmd "activate:"

logMe "INFO: Restarting AppSSOAgent to trigger registration prompt..."
kill_sso_agent

# Wait for completion, updating the card as we go
interval=10
max_wait="${MAX_WAIT_SECONDS}"
start_ts=$(date +%s)

while true; do
  sleep "${interval}"

  ssoStatus="$(get_sso_status)"
  if [[ "$(getValueOf registrationCompleted "${ssoStatus}")" == "true" ]]; then
    logMe "INFO: Registration completed successfully."

    # Show "finalizing" in the card while the best-effort jamfAAD compliance
    # step runs, so everything happens before the success state is shown.
    dialog_cmd "progresstext: Finalizing…"

    if ! jamf_check_aad; then
      logMe "WARNING: jamfAAD did not reflect successful registration."
      if [[ "${RUN_JAMF_AAD_ON_ERROR:l}" == "yes" ]]; then
        logMe "INFO: Retrying jamfAAD gatherAADInfo after 5s..."
        sleep 5
        runAsUser "${JAMF_AAD_BINARY}" gatherAADInfo >/dev/null 2>&1
      fi
    fi

    # Mark complete, close the card, and end the script.
    card_show_success
    logMe "INFO: SCRIPT COMPLETE — Platform SSO registration finished."
    cleanup_and_exit 0
  fi

  now_ts=$(date +%s)
  elapsed=$(( now_ts - start_ts ))

  if (( elapsed >= max_wait )); then
    logMe "ERROR: Timed out after ${max_wait}s waiting for registration."
    card_close
    display_failure_message "Timed out waiting for Platform SSO registration. Please try again while connected to the network. If it still fails, contact Support."
    cleanup_and_exit 1
  fi

  # Gentle in-card status update (rotates so it doesn't look frozen)
  remaining=$(( max_wait - elapsed ))
  if (( elapsed % 30 < interval )); then
    dialog_cmd "progresstext: Still waiting — click Register on the macOS notification (top-right)."
  else
    dialog_cmd "progresstext: Waiting for registration to complete…"
  fi

  logMe "INFO: Device not registered yet; waiting (${elapsed}s elapsed)..."
done
