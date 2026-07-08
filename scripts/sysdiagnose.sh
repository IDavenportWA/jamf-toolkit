#!/bin/bash
#sudo sysdiagnose -f ~/Desktop/

#sudo sysdiagnose -u -f ~/Desktop/

#!/bin/sh

# Run SysDiagnose programatically and then reveal the file to the user
# sysD=`sysdiagnose -u`
# sysDFile=`echo $sysD | awk '{print $NF}' | awk '{ print substr( $0, 2 ) }' | awk '{ print substr( $0, 1, length($0)-2 ) }'`
# open -R $sysDFile

#!/bin/bash

#Find current logged in user
loggedInUser=$( scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }' )

#Runs SysDiagnose and places ZIP in Current User's Downloads folder
/usr/bin/sysdiagnose -u -f /Users/$loggedInUser/Downloads
