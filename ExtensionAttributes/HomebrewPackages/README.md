# Homebrew Packages

Inventories Homebrew formulas and casks for the logged-in user.

Lists installed formulas with versions and installed casks, grouped under headings.

Homebrew is a common route for unmanaged software to enter a fleet and is invisible to standard application inventory.

**Notes:** Homebrew installs per-user while extension attributes run as root, so `brew` is invoked via `launchctl asuser` + `sudo -u`. Run as root it would read root's installation, which is empty on every managed Mac — a clean and entirely wrong answer. Supports Apple silicon (`/opt/homebrew`) and Intel (`/usr/local`) paths.

**Data type:** String.
