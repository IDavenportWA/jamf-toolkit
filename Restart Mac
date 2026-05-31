#!/bin/bash

###
#
#                    Author : Isaac Davenport
#                   Created : 09-03-2025
#             Last Modified : 12-08-2025
#                   Version : 1.4
#               Tested with : macOS 15.7.2
#
###

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

if [ "$uptime_days" -le 6 ]; then
 echo "Uptime less than or equal to 6 days. Exit."
 exit 0

elif [ "$uptime_days" -ge 7 ] && [ "$uptime_days" -le 13 ]; then
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
