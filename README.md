# Jamf Toolkit

Production-tested scripts, Extension Attributes, and configuration profiles for Jamf Pro administration, written for real enterprise macOS fleets.

These tools come from managing macOS fleets from 300 to 2,800+ endpoints. They prioritize safety, reliability, clear logging, and real-world fleet operations over cleverness — the way production tooling should be built.

Each tool lives in its own folder with a README covering what it does, its Jamf parameters, and the details worth knowing before you deploy it.

---

## Scripts

Policy-attached and Self Service scripts.

| Script | Purpose |
|---|---|
| [ForcePlatformSSO](Scripts/ForcePlatformSSO) | Detects Macs that never completed Platform SSO registration and re-prompts the user via swiftDialog — closes the enrollment gap left by Apple's user-initiated flow |
| [RestartMac](Scripts/RestartMac) | Restart prompting that escalates on uptime: silent under 7 days, deferrable to 13, forced at 14+ |
| [ReconPlusPolicy](Scripts/ReconPlusPolicy) | Runs recon and policy with live output in a single swiftDialog window |
| [PromoteUserToAdmin](Scripts/PromoteUserToAdmin) | Grants local admin rights to the logged-in user and notifies them |
| [DemoteAdmin](Scripts/DemoteAdmin) | Removes local admin rights, with an optional exempt account |
| [MicrosoftTeamsRepair](Scripts/MicrosoftTeamsRepair) | Clears classic and new-Teams caches and relaunches |
| [SetTeamsWallpaper](Scripts/SetTeamsWallpaper) | Deploys a corporate Teams background image |
| [FirefoxLatest](Scripts/FirefoxLatest) | Installs the current Firefox from Mozilla, staged so a failed copy cannot leave the machine without a browser |
| [GoogleChromeLatest](Scripts/GoogleChromeLatest) | Installs the current Chrome from Google's CDN, warning and quitting before installing |
| [Office365Latest](Scripts/Office365Latest) | Installs the current Microsoft 365 suite, relaunching only what was open |
| [SetDeviceName](Scripts/SetDeviceName) | Names a Mac from its serial number and updates Jamf inventory |
| [SysDiagnose](Scripts/SysDiagnose) | Collects a sysdiagnose archive into the user's Downloads |
| [AnnouncementDialog](Scripts/AnnouncementDialog) | Branded IT announcement via jamfHelper |
| [FlushDNSCache](Scripts/FlushDNSCache) | Clears the macOS DNS cache |
| [DisableIPv6](Scripts/DisableIPv6) | Turns IPv6 off on every network service |

## Extension Attributes

Inventory collection — endpoint visibility, software inventory, and verification that controls are actually working.

| Extension Attribute | Purpose |
|---|---|
| [SecureTokenUsers](ExtensionAttributes/SecureTokenUsers) | Which accounts can actually unlock a FileVault volume — the state FileVault depends on and inventory does not expose |
| [AppAutoPatchStatus](ExtensionAttributes/AppAutoPatchStatus) | App Auto-Patch results per title, split into successes and failures |
| [PrivilegeElevationReasons](ExtensionAttributes/PrivilegeElevationReasons) | The last five admin elevation justifications from Jamf Connect |
| [VSCodeExtensions](ExtensionAttributes/VSCodeExtensions) | Installed VS Code extensions and versions, per user |
| [HomebrewPackages](ExtensionAttributes/HomebrewPackages) | Homebrew formulas and casks — unmanaged software that standard inventory misses |
| [SuperStatus](ExtensionAttributes/SuperStatus) | Current S.U.P.E.R. workflow state, normalised into simple categories |
| [JamfConnectUsers](ExtensionAttributes/JamfConnectUsers) | Which local accounts were created by Jamf Connect |
| [GoogleChromeVersion](ExtensionAttributes/GoogleChromeVersion) | Installed Chrome version |
| [SystemUptime](ExtensionAttributes/SystemUptime) | Current uptime — a practical patch-compliance signal |

## Config Profiles

| Profile | Purpose |
|---|---|
| [JamfConnectPrivilegeElevation](ConfigProfiles/JamfConnectPrivilegeElevation) | 15-minute self-service admin rights with a mandatory written justification |
| [VSCodeEnterpriseRestrictions](ConfigProfiles/VSCodeEnterpriseRestrictions) | VS Code extension allowlist and telemetry controls |

## Helpful Notes

[HelpfulNotes](HelpfulNotes) — operational context and reference links that usually go undocumented.

---

## Controls and their evidence

Several of these are designed as pairs — a control that enforces something, and an Extension Attribute that proves it is working. "The profile is scoped" and "the thing is actually happening on this device" are different claims, and only the second one is evidence.

| Control | Verified by |
|---|---|
| [JamfConnectPrivilegeElevation](ConfigProfiles/JamfConnectPrivilegeElevation) | [PrivilegeElevationReasons](ExtensionAttributes/PrivilegeElevationReasons) |
| [VSCodeEnterpriseRestrictions](ConfigProfiles/VSCodeEnterpriseRestrictions) | [VSCodeExtensions](ExtensionAttributes/VSCodeExtensions) |
| FileVault enforcement | [SecureTokenUsers](ExtensionAttributes/SecureTokenUsers) |
| App Auto-Patch | [AppAutoPatchStatus](ExtensionAttributes/AppAutoPatchStatus) |
| [RestartMac](Scripts/RestartMac) | [SystemUptime](ExtensionAttributes/SystemUptime) |

---

## Usage

Scripts are uploaded to **Jamf Pro → Settings → Scripts** and attached to a policy:

1. Add the script to Jamf Pro
2. Create a policy scoped to the target smart group
3. Set the trigger — Self Service, check-in, or enrollment complete
4. Test on a pilot group before fleet-wide deployment

Extension Attributes are added under **Settings → Computer Management → Extension Attributes** with input type *Script* and data type *String*.

Scripts taking Jamf parameters document them in their own README and at the top of the file. Parameters `$1`–`$3` are reserved by Jamf (mount point, computer name, username), so custom values start at `$4`.

## Notes

These run as root via the Jamf binary. Anything touching user-owned state — home directories, per-user application data, GUI dialogs — drops to the console user with `launchctl asuser` and `sudo -u`, because a root-context script acting on user state fails silently rather than loudly.

---

**Isaac Davenport** — IT Systems Engineer specializing in macOS fleet management and IAM
[github.com/IDavenportWA](https://github.com/IDavenportWA)
