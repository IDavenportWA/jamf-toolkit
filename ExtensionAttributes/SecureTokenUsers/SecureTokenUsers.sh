#!/bin/bash

###################################################################################################
# Script Name:  secure-token-enabled-users.sh
# Author:       Isaac Davenport
# Created:      07/09/2026
# Last Modified: 08/29/2026
# Version:      1.1
#
# Purpose:
#   Jamf Pro Extension Attribute (EA) that reports every local user holding a
#   secure token. On a FileVault volume only a secure-token-enabled account can
#   unlock the disk at pre-boot, and standard inventory does not expose this —
#   a device can report as encrypted and compliant while the person using it is
#   unable to unlock it after a restart.
#
# Notes:
#   - sysadminctl writes its status output to stderr, not stdout, so the 2>&1
#     redirect below is required. Without it every user tests as not-enabled
#     and the EA reports "No users have a secure token" across the whole fleet.
#
# Changelog:
#   1.0: Initial version.
#   1.1: Replaced the fixed /tmp/stylesheet.xslt path with mktemp. The old
#        path was predictable and world-writable while this runs as root:
#        two concurrent runs would clobber each other, and a pre-planted
#        symlink there would have had root write through it. Added a trap so
#        the temp file is removed even if the script exits early.
###################################################################################################

declare -a secure_token_enabled_users=()

# Unpredictable temp path, cleaned up on any exit
STYLESHEET=$(mktemp "/tmp/secure-token-stylesheet.XXXXXXXX") || {
    echo "<result>Error: could not create temporary stylesheet</result>"
    exit 0
}
trap 'rm -f "$STYLESHEET"' EXIT

cat <<EOF >"$STYLESHEET"
<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  <xsl:output method="text"/>
  <xsl:template match="/">
    <xsl:for-each select="users/user">
      <xsl:value-of select="name"/>
      <xsl:text>&#xa;</xsl:text>
    </xsl:for-each>
  </xsl:template>
</xsl:stylesheet>
EOF

while read -r username; do
  # 2>&1 is required — sysadminctl reports status on stderr
  if [ "$(sysadminctl -secureTokenStatus "${username}" 2>&1 | awk -v user="${username}" '{if ($7=="ENABLED") print user}')" = "${username}" ]; then
    secure_token_enabled_users+=("${username}")
  fi
done < <(/usr/local/bin/jamf listUsers -showAll | xsltproc "$STYLESHEET" -)

if [ ! "${#secure_token_enabled_users[@]}" -eq 0 ]; then
  expanded_secure_token_enabled_users="${secure_token_enabled_users[*]}"
  echo "<result>${expanded_secure_token_enabled_users// /, }</result>"
else
  echo "<result>No users have a secure token</result>"
fi
