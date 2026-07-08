# Jamf-Toolkit

Production-tested bash scripts for **Jamf Pro** administration, written for real enterprise macOS fleets. Each script is designed to run as a Jamf policy payload (Self Service or automated trigger) unless noted otherwise.

> These scripts come from managing macOS fleets of 2,800+ endpoints. They favor safety and logging over cleverness — the way fleet scripts should.

## Scripts

### Account Management

| Script | Purpose |
|---|---|
| `promote-user-to-admin.sh` | Temporarily elevates the logged-in user to admin (pair with the demote script for time-boxed elevation via Self Service) |
| `demote-admin.sh` | Returns a user to standard permissions, enforcing least privilege |

### App Deployment & Repair

| Script | Purpose |
|---|---|
| `firefox-latest.sh` | Downloads and installs the latest Firefox directly from Mozilla — no package repackaging needed |
| `google-chrome-latest.sh` | Same pattern for Chrome; always current without maintaining installers in Jamf |
| `office365-latest.sh` | Installs the latest Microsoft 365 suite from Microsoft's CDN |
| `microsoft-teams-repair.sh` | Clears Teams caches and reinstalls to resolve common client corruption |

### Device Maintenance

| Script | Purpose |
|---|---|
| `set-device-name.sh` | Standardizes computer names for inventory hygiene and smart group targeting |
| `recon-policy.sh` | Forces inventory update then triggers policy check-in — useful after config changes |
| `flush-dns-cache.sh` | Clears DNS cache without a restart (common help desk deflection) |
| `disable-ipv6.sh` | Disables IPv6 on network interfaces where required by network policy |
| `restart-mac.sh` | Graceful restart with user warning for maintenance windows |
| `sysdiagnose.sh` | Captures a sysdiagnose bundle for escalation to Apple or deep troubleshooting |

### End-User Communication

| Script | Purpose |
|---|---|
| `announcement-dialog.sh` | Displays a dialog to the logged-in user — maintenance notices, action prompts |
| `set-teams-wallpaper.sh` | Deploys corporate Teams background images to user profiles |

## Usage

Most scripts are designed to be uploaded to **Jamf Pro → Settings → Scripts** and attached to a policy. Typical pattern:

1. Add the script to Jamf Pro
2. Create a policy scoped to the target smart group
3. Set trigger (Self Service, check-in, or enrollment complete)
4. Test on a pilot group before fleet-wide deployment

Scripts that use Jamf script parameters (\$4–\$11) are commented at the top of the file.

## Requirements

- macOS 13+ (tested through current release)
- Jamf Pro (any recent version) for policy deployment
- Scripts run as root via the Jamf binary unless noted

## Disclaimer

Test in your own environment before production use. Scripts that modify user accounts or network settings should always be piloted first.

## Author

**Isaac Davenport** — IT Systems Engineer specializing in macOS fleet management and IAM
[isaacdavenportwa.com](https://isaacdavenportwa.com) · [LinkedIn](https://www.linkedin.com/in/isaacdavenportwa)
