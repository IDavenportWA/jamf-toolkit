# Sys Diagnose

Collects a sysdiagnose archive into the user's Downloads folder.

Runs `sysdiagnose -u` non-interactively and saves the archive to the logged-in user's Downloads.

**Notes:** the home directory is resolved via `dscl`, and the resulting archive is chowned to the user — as a root-owned file they cannot move, delete, or attach it to a ticket. Expect several minutes of runtime.
