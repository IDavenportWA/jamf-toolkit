#!/bin/bash

function main() {

  declare -a jamf_connect_users=()

  for user in $(dscl . -list /Users uid | awk '$2 >= 501 { print $1 }'); do
    if [[ "$(dscl -plist . -read /Users/"${user}" dsAttrTypeStandard:NetworkUser | xmllint --xpath "boolean(//string[1])" -)" == "true" ]]; then
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
