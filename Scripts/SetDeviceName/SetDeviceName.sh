#!/bin/bash

###
#
#                    Author : Isaac Davenport
#                   Created : 08-25-2026
#             Last Modified : 08-29-2026
#                   Version : 1.1
#               Tested with : macOS 26.5.2
#
#   1.0: Initial versioned header. Sets the Mac's HostName, LocalHostName,
#        and ComputerName based on its serial number.
#   1.1: Serial number is now read from ioreg and validated — an empty read
#        previously produced a device named just the prefix, applied to every
#        affected Mac. Prefix is a Jamf parameter rather than hardcoded, and
#        Jamf inventory is updated so the new name is reflected server-side.
#
#   Jamf parameters:
#     $4  (optional) name prefix. Defaults to "Mac".
#
###

# Name prefix — pass via Jamf parameter $4
PREFIX="${4:-Mac}"

# Serial number, read directly from the IO registry
serial=$(/usr/sbin/ioreg -c IOPlatformExpertDevice -d 2 \
    | awk -F'"' '/IOPlatformSerialNumber/ { print $4 }')

# Refuse to name the machine after nothing — without this an empty read
# names every affected Mac identically.
if [ -z "$serial" ]; then
    echo "ERROR: Could not determine serial number, leaving names unchanged"
    exit 1
fi

deviceName="${PREFIX}-${serial}"
echo "Setting device name to $deviceName"

/usr/sbin/scutil --set HostName "$deviceName"
/usr/sbin/scutil --set LocalHostName "$deviceName"
/usr/sbin/scutil --set ComputerName "$deviceName"

# Update Jamf inventory so the console reflects the new name
if [ -x /usr/local/bin/jamf ]; then
    /usr/local/bin/jamf recon >/dev/null 2>&1
fi

echo "Device name set to $deviceName"
exit 0
