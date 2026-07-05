#!/bin/sh

########## Variables #########
JHELPER="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"

MsgTitle="IT Announcement"
# The message title

MsgIcon="/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AlertStopIcon.icns"
# The message icon to use. System icons can be found /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources.

MsgIconSize="100"
# The size of the icon to use.  It will also be needed to change up to the size of the message box.

MsgButton1="OK"
# The button(s) name.  Can add -button2... for mutliple buttons

######## Message Body ########
MsgBody="Dear employee..."
# The body of the message.  Use like a text editor for line breaks."

######## Message Launcher ########
WELCOME=$("$JHELPER" -windowType utility -heading "$MsgTitle" -iconSize $MsgIconSize -icon "$MsgIcon" -alignDescription natural -description "$MsgBody" -button1 "$MsgButton1")

exit 0
