# Microsoft Teams Repair

**Clears Teams caches and restarts it.**

Quits Teams, removes the classic and new-Teams cache directories, and relaunches in the user's session.

Covers `Application Support/Microsoft/Teams`, `Group Containers/UBF8T346G9.com.microsoft.teams` and `Containers/com.microsoft.teams2`.

---

## Notes

The home directory is resolved via `dscl` rather than assuming `/Users/<name>`, and a force-quit fallback ensures Teams is not running while its caches are deleted — otherwise it rewrites them on exit and undoes the repair.
