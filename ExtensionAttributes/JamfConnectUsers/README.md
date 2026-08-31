# Jamf Connect Users

**Reports which local accounts were created by Jamf Connect.**

Checks every local account with a UID of 501 or above for the `NetworkUser` attribute that Jamf Connect sets on accounts it creates.

Useful for confirming Jamf Connect adoption and spotting machines still running purely local accounts after a rollout.

---

## Data type

String.
