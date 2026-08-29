# Privilege Elevation Reasons

Reports the last five admin elevation justifications from Jamf Connect.

Reads `/Library/Logs/JamfConnect/UserElevationReasons.log` and reports the five most recent entries.

Jamf Connect captures a justification at the moment of elevation and writes it to a local log — an audit trail scattered across every endpoint and readable from none of them. This surfaces it into inventory, making it a smart group criterion and a search term.

**Requirements:** Jamf Connect Temporary User Permissions configured with `UserPromotionReason` enabled — see [JamfConnectPrivilegeElevation](../../ConfigProfiles/JamfConnectPrivilegeElevation).

**Notes:** capped at five entries, since extension attributes land in every inventory record. Reports explicitly when the log is absent, so "nobody needed admin" and "the control was never deployed" stay distinguishable.

**Data type:** String.
