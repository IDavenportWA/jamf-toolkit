# Restart Mac

Prompts for a restart with pressure that escalates on uptime.

A patch that is downloaded but never restarted into is not applied, while inventory may still report the device compliant. This script drives the restart, escalating as uptime grows.

| Uptime | Behaviour |
|---|---|
| 6 days or less | Nothing — no prompt, no network calls |
| 7–13 days | *Restart now* / *Defer*, 15-minute timer, asks again in 24 hours |
| 14 days or more | No defer. Acknowledge, then a 10-minute countdown to an automatic restart |

Uptime is computed from `kern.boottime`. swiftDialog is only installed or updated once a dialog is actually warranted, so machines under the threshold never touch the GitHub API.

**Jamf parameters**

| Parameter | Purpose |
|---|---|
| `$4` | Dialog icon — a branding-image URL, file path, or SF Symbol spec. Defaults to a system restart glyph. |
