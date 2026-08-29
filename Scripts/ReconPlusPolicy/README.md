# Recon Plus Policy

Runs inventory and policy checks with live output in a swiftDialog window.

Runs `jamf recon`, `killall jamf`, then `jamf policy`, showing live command output and per-step status in a single movable window.

**Run manually with sudo, or from Self Service.** Do not attach it to a check-in trigger: `killall jamf` terminates the policy's own parent process and the policy log will sit at *Pending*.

Installs or updates swiftDialog from GitHub with Team ID verification, and cleans up its temp files via an exit trap.
