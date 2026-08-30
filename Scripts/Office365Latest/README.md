# Office 365 Latest

**Installs the current Microsoft 365 suite from Microsoft's CDN.**

Detects which Office apps are open, warns the user, waits, quits them, installs, then relaunches only what was originally running.

---

## Notes

As with the Chrome script, the warning and quit precede the install. Dialogs and relaunches run in the user's session, with a `killall` fallback for apps holding unsaved-work dialogs.
