# Firefox Latest

Installs the current Firefox release straight from Mozilla.

Downloads the latest DMG from Mozilla's `firefox-latest` endpoint, stages the app, swaps it in, and relaunches Firefox in the user's session if it was running.

Removes the need to maintain a packaged installer that goes stale between releases.

**Safety:** the new copy is staged and verified before the existing install is touched, and the previous version is restored if the swap fails. The quit and relaunch run via `launchctl asuser` so session restore works and Firefox does not end up running as root.
