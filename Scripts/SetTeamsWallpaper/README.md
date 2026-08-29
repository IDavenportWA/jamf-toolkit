# Set Teams Wallpaper

Deploys a corporate Teams background image.

Clears existing uploads, converts the source image to PNG, generates a thumbnail, and places both in the user's Teams backgrounds folder.

**Jamf parameters**

| Parameter | Purpose |
|---|---|
| `$4` | Full path to the source image. Defaults to `/Library/Corp/Background.png`. |

**Notes:** the user's home is resolved via `dscl`, and the generated files are chowned to the user — as root-owned files Teams cannot manage them. Using `~` here would resolve to `/var/root` under a Jamf policy and silently do nothing.
