# Force Platform SSO

Detects Macs that never completed Platform SSO registration and drives the user through it.

Apple's Platform SSO registration is user-initiated. On an already-enrolled Mac the configuration profile installs correctly while the registration prompt can go unseen — leaving the device with the profile present, registration incomplete and device trust never established. Nothing errors, and nothing in a dashboard shows it.

This script closes that gap without Jamf triggers, API calls or scope changes, so it runs on any device where the profile and Company Portal are already present.

**How it works**

1. Installs or updates swiftDialog from GitHub, verifying the developer Team ID before install
2. Optionally enforces Touch ID enrolment, and enables Company Portal extensions best-effort
3. Shows a status card and restarts `AppSSOAgent` to re-fire the registration prompt
4. Polls `app-sso platform -s` for `registrationCompleted`, updating the card
5. On success runs `jamfAAD` and exits 0; on timeout shows a failure modal and exits 1

**Jamf parameters**

| Parameter | Purpose |
|---|---|
| `$3` | Logged-in user (passed by Jamf) |
| `$4` | Check for Touch ID enrolment — default `yes` |
| `$5` | Run `jamfAAD` on error — default `yes` |
| `$6` | Maximum wait in seconds — default `300` |
| `$7` | Status card lifetime — defaults to `$6` + 30s |

**Deployment:** production use was against Microsoft Entra ID across a 300-device fleet; the flow was also validated against Okta in a developer tenant.

**Requirements:** Platform SSO configuration profile and Company Portal already deployed.
