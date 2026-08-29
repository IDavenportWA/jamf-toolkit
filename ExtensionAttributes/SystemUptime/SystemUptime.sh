#!/bin/bash

###################################################################################################
# Script Name:  uptime.sh
# Author:       Isaac Davenport
# Created:      07/09/2026
# Version:      1.0
#
# Purpose:
#   Jamf Pro Extension Attribute (EA) that reports current system uptime.
#   Long uptime is a practical compliance signal on a Mac fleet: staged
#   updates are not applied until a restart, so a machine can report patched
#   while still running the old kernel and frameworks. Pairs with the reboot
#   prompting in scripts/restart-mac.sh, which acts on the same measure.
###################################################################################################

echo "<result>$(/usr/bin/uptime)</result>"
