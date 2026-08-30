# Demote Admin

**Removes local admin rights from the logged-in user and notifies them.**

Checks admin group membership with `dseditgroup -o checkmember`, removes the user from `admin`, verifies the change, and notifies via jamfHelper.

Intended as a cleanup net for accounts that gained admin outside the normal path. Where Jamf Connect Temporary User Permissions is in use, expiry is handled natively by `UserPromotionDuration` and this is not the primary demotion mechanism.

---

## Jamf parameters

| Parameter | Purpose |
|---|---|
| `$4` | Optional account to exempt, e.g. a break-glass admin. Blank means no exemption. |

## Notes

Exits cleanly at the login window and for `_mbsetupuser`.
