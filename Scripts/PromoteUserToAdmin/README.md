# Promote User To Admin

**Grants local admin rights to the logged-in user and notifies them.**

Checks admin group membership with `dseditgroup -o checkmember`, adds the user to `admin`, verifies the change, and notifies via jamfHelper.

---

## Jamf parameters

| Parameter | Purpose |
|---|---|
| `$3` | Username, passed by Jamf. Falls back to the console user if absent. |

## Notes

Membership is tested by exact match rather than by grepping the member list, which would substring-match (`bob` against `bobby`) and treat an unset username as a match.
