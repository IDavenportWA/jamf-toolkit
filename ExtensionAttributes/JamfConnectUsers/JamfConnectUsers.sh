#!/bin/bash

###################################################################################################
# Script Name:  jamf-connect-users.sh
# Author:       Isaac Davenport
# Created:      07/09/2026
# Last Modified: 08/29/2026
# Version:      1.1
#
# Purpose:
#   Jamf Pro Extension Attribute (EA) that reports which local accounts were
#   created by Jamf Connect — that is, accounts backed by an identity provider
#   rather than created locally. Useful for confirming Jamf Connect adoption
#   across a fleet and for spotting machines still running purely local
#   accounts after a rollout.
#
# How it works:
#   Local accounts with a UID of 501 or above are real user accounts, so system
#   and service accounts are skipped. Each is checked for the NetworkUser
#   attribute, which Jamf Connect sets on the accounts it creates.
#
# Changelog:
#   1.0: Initial version.
#   1.1: Added the standard author header. Suppressed stderr on the dscl and
#        xmllint calls — accounts without the NetworkUser attribute (the
#        normal case for locally created users) made both commands write
#        errors into the policy log on every inventory run.
###################################################################################################

function main() {

  declare -a jamf_connect_users=()

  for user in $(dscl . -list /Users uid | awk '$2 >= 501 { print $1 }'); do
    # Accounts without the NetworkUser attribute are expected, not errors
    if [[ "$(dscl -plist . -read /Users/"${user}" dsAttrTypeStandard:NetworkUser 2>/dev/null | xmllint --xpath "boolean(//string[1])" - 2>/dev/null)" == "true" ]]; then
      jamf_connect_users+=("${user}")
    fi
  done

  if [[ ! "${#jamf_connect_users[@]}" -eq 0 ]]; then
    expanded_jamf_connect_users="${jamf_connect_users[*]}"
    echo "<result>${expanded_jamf_connect_users// /, }</result>"
  else
    echo "<result>No Jamf Connect Users</result>"
  fi

}

main "${@}"
