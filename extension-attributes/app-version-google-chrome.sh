#!/bin/bash

# result 0  = app not installed
# result -1 = error determining app version

APP_BUNDLE="/Applications/Google Chrome.app"
APP_PLIST="${APP_BUNDLE}/Contents/Info.plist"

app_ver=0

if [ -e "${APP_BUNDLE}" ]; then
    app_ver=$(/usr/bin/defaults read "${APP_PLIST}" CFBundleShortVersionString)
    if [ ! ${?} ]; then
	    app_ver=-1
    fi
fi

echo "<result>${app_ver}</result>"

exit 0
