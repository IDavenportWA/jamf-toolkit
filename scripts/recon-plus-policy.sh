#!/bin/bash

# Run Jamf recon
sudo jamf recon
osascript -e 'display dialog "✅ jamf recon completed" buttons {"OK"} default button 1 giving up after 5'

# Kill Jamf processes
sudo killall jamf
osascript -e 'display dialog "✅ jamf processes stopped" buttons {"OK"} default button 1 giving up after 5'

# Run Jamf policy
sudo jamf policy
osascript -e 'display dialog "✅ jamf policy completed" buttons {"OK"} default button 1 giving up after 5'
