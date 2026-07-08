# jamf-toolkit

Production-tested bash scripts, Extension Attributes, and configuration profiles for Jamf Pro administration, written for real enterprise macOS fleets.

These tools come from managing macOS fleets of 3,000+ endpoints. They prioritize safety, reliability, clear logging, and real-world fleet operations over cleverness — the way production tooling should be built.

## Featured Scripts

These scripts represent some of my strongest examples of enterprise macOS workflows, automation, and fleet management practices:

| Script | Purpose |
|---|---|
| `restart-mac.sh` | Graceful restart workflow with user notifications and maintenance messaging — useful for patching, remediation, and scheduled maintenance |
| `announcement-dialog.sh` | Displays user-facing dialogs for maintenance notices, required actions, and IT communications |
| `set-teams-wallpaper.sh` | Deploys corporate Microsoft Teams background images to user profiles |
| `firefox-latest.sh` | Downloads and installs the latest Firefox release directly from Mozilla without maintaining package installers |
| `google-chrome-latest.sh` | Downloads and installs the latest Chrome release directly from Google |
| `office365-latest.sh` | Installs the latest Microsoft 365 applications directly from Microsoft's CDN |

# Extension Attributes & Configuration Profiles

These resources demonstrate endpoint visibility, software inventory automation, and application control using Jamf Pro.

| Resource | Purpose |
|---|---|
| `homebrew-installed-packages.sh` | Extension Attribute that inventories installed Homebrew packages and casks across managed macOS devices for software visibility, compliance reporting, and Smart Group targeting |
| `vscode-extension-allowlist.mobileconfig` | Configuration profile that manages Visual Studio Code extension access by enforcing an approved extension allowlist through managed preferences |

## Usage

Most scripts are designed to be uploaded to **Jamf Pro → Settings → Scripts** and attached to a policy. Typical pattern:

1. Add the script/profile to Jamf Pro
2. Create a policy/profile scoped to the target smart group
3. Set trigger (Self Service, check-in, or enrollment complete)
4. Test on a pilot group before fleet-wide deployment

*Scripts that use Jamf script parameters (\$4–\$11) are commented at the top of the file.*

## Requirements

- macOS 13+ (tested through current release)
- Jamf Pro (any recent version) for policy deployment
- Scripts run as root via the Jamf binary unless noted

## Disclaimer

Test in your own environment before production use. Scripts that modify user accounts or network settings should always be piloted first.

## Author

**Isaac Davenport** — IT Systems Engineer specializing in macOS fleet management and IAM
[isaacdavenportwa.com](https://isaacdavenportwa.com) · [LinkedIn](https://www.linkedin.com/in/isaacdavenportwa)
