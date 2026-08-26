#!/bin/sh

###
#
#                    Author : Isaac Davenport
#                   Created : 08-25-2026
#             Last Modified : 08-25-2026
#                   Version : 1.0
#               Tested with : macOS 26.5.2
#
#   1.0: Initial versioned header. Demotes the logged-in user from admin to
#        standard rights (excluding a hardcoded account), then notifies them
#        via Jamf Helper.
#
###

currentUser=$(ls -l /dev/console | awk '{ print $3 }')

      if [ $currentUser != "sifi" ]; then
        IsUserAdmin=$(id -G $currentUser| grep 80)
            if [ -n "$IsUserAdmin" ]; then
              /usr/sbin/dseditgroup -o edit -n /Local/Default -d $currentUser -t "user" "admin"
              exit 0
            else
                echo "$currentuser is not a local admin"
            fi
      fi
      
"$jhelp" -windowType utility -title "Admin rights" -description "You've been granted standard rights." -button1 "OK"
