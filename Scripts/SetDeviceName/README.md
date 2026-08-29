# Set Device Name

Names a Mac from its serial number.

Reads the serial from `ioreg`, sets `HostName`, `LocalHostName` and `ComputerName` to `<prefix>-<serial>`, then runs `jamf recon` so the console reflects the new name.

**Jamf parameters**

| Parameter | Purpose |
|---|---|
| `$4` | Name prefix. Defaults to `Mac`. |

**Notes:** the script aborts if the serial cannot be read — without that check an empty read names every affected Mac identically.
