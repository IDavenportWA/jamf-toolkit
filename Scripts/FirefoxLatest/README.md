# Firefox Latest

**Installs the current Firefox release straight from Mozilla.**

Downloads the latest DMG from Mozilla's `firefox-latest` endpoint, stages the app, swaps it in, and relaunches Firefox in the user's session if it was running.

Removes the need to maintain a packaged installer that goes stale between releases.

---

## Safety

The new copy is staged, then verified — `codesign --verify --deep --strict` must pass and the app must carry Mozilla's Apple Developer Team ID (`43AQ936H96`) — before the running Firefox is quit or the existing install is touched. A tampered or truncated download fails closed with the user never interrupted.

The previous version is restored if the swap fails, and the cleanup trap restores it if the script is killed mid-swap, so there is no window where the Mac has no Firefox. Working files live in a `mktemp` directory. The quit and relaunch run via `launchctl asuser` so session restore works and Firefox does not end up running as root.
