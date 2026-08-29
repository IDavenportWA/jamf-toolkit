# VS Code Extensions

Inventories installed VS Code extensions and versions for the logged-in user.

Runs VS Code's own CLI to list every installed extension with its version.

Standard inventory sees VS Code as one application at one version, which says almost nothing — what a developer's editor actually does is determined by its extensions, which run with the user's privileges and read every file in the workspace. This also verifies that an extension allowlist is taking effect rather than merely being deployed.

**Notes:** extensions are per-user and extension attributes run as root, so the CLI is invoked with `sudo -u`. Run as root it enumerates root's profile, which is empty on every machine. Reports three distinct states — not installed, installed with no extensions, and the list — because collapsing them makes a missing install indistinguishable from a clean one.

**Pairs with** [VSCodeEnterpriseRestrictions](../../ConfigProfiles/VSCodeEnterpriseRestrictions).

**Data type:** String.
