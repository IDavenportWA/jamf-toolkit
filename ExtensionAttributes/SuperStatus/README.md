# Super Status

Reports the current S.U.P.E.R. workflow state.

Reads the SUPER local property list and audit log, takes whichever is most recent, and normalises the detailed status message into a simple category for reporting and smart group criteria.

Categories: `Inactive`, `Pending`, `Running SoftwareUpdate`, `Dialog Prompts`, `Complete`, `Resetting`, `Error`, `Unknown`.

**Requirements:** S.U.P.E.R. installed, with its plist and audit log under `/Library/Management/super/`.

**Data type:** String.
