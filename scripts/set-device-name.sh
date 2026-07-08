#!/bin/bash

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
