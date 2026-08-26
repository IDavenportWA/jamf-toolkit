#!/bin/bash

###
#
#                    Author : Isaac Davenport
#                   Created : 08-25-2026
#             Last Modified : 08-25-2026
#                   Version : 1.0
#               Tested with : macOS 26.5.2
#
#   1.0: Initial versioned header. Sets the Mac's HostName, LocalHostName,
#        and ComputerName based on its serial number.
#
###

#get serial number
serial=$(system_profiler SPHardwareDataType | awk '/Serial/ {print $4}')

# Set Hostname using variable created above
scutil --set HostName "Company-$serial"
sleep 1
scutil --set LocalHostName "Company-$serial"
sleep 1
scutil --set ComputerName "Company-$serial"
sleep 1


exit 0
