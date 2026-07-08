#!/bin/bash

declare -a secure_token_enabled_users=()

cat <<EOF >"/tmp/stylesheet.xslt"
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
  if [ "$(sysadminctl -secureTokenStatus "${username}" 2>&1 | awk -v user="${username}" '{if ($7=="ENABLED") print user}')" = "${username}" ]; then
    secure_token_enabled_users+=("${username}")
  fi
done < <(/usr/local/bin/jamf listUsers -showAll | xsltproc "/tmp/stylesheet.xslt" -)

rm -f "/tmp/stylesheet.xslt"

if [ ! "${#secure_token_enabled_users[@]}" -eq 0 ]; then
  expanded_secure_token_enabled_users="${secure_token_enabled_users[*]}"
  echo "<result>${expanded_secure_token_enabled_users// /, }</result>"
else
  echo "<result>No users have a secure token</result>"
fi
