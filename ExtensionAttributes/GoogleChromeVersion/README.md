# Google Chrome Version

Reports the installed Google Chrome version.

Reads `CFBundleShortVersionString` from the Chrome bundle.

| Result | Meaning |
|---|---|
| version string | Installed version |
| `0` | Not installed |
| `-1` | Error reading the version |

**Data type:** String.
