#!/bin/bash

###################################################################################################
# Script Name:  app-version-google-chrome.sh
# Author:       Isaac Davenport
# Created:      07/09/2026
# Last Modified: 08/29/2026
# Version:      1.1
#
# Purpose:
#   Jamf Pro Extension Attribute (EA) that reports the installed version of
#   Google Chrome for inventory reporting and Smart Group criteria.
#
# Result values:
#    0  = app not installed
#   -1  = error determining app version
#
# Changelog:
#   1.0: Initial version.
#   1.1: Fixed the error check. '[ ! ${?} ]' is always false — [ ! string ]
#        tests whether a string is empty, and "0" and "1" are both non-empty
#        — so the -1 branch was unreachable and a failed read returned an
#        empty <result> instead. Now tests the exit status directly, treats
#        an empty-but-successful read as an error, and suppresses the
#        defaults stderr output so it does not land in the policy log.
###################################################################################################

APP_BUNDLE="/Applications/Google Chrome.app"
APP_PLIST="${APP_BUNDLE}/Contents/Info.plist"

# 0 means not installed
app_ver=0

if [ -e "${APP_BUNDLE}" ]; then
    if app_ver=$(/usr/bin/defaults read "${APP_PLIST}" CFBundleShortVersionString 2>/dev/null); then
        # A successful read that returned nothing is still an error
        if [ -z "${app_ver}" ]; then
            app_ver=-1
        fi
    else
        app_ver=-1
    fi
fi

echo "<result>${app_ver}</result>"

exit 0
