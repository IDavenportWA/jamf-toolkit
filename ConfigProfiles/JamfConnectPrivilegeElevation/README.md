# Jamf Connect Privilege Elevation

**Time-boxed self-service admin rights with a mandatory justification.**

Configures Jamf Connect Temporary User Permissions so standard users can elevate themselves when they need to, for a fixed window, with a written reason.

| Key | Value | Effect |
|---|---|---|
| `TemporaryUserPromotion` | `true` | Self-service elevation, no ticket required |
| `UserPromotionTimer` | `true` | Rights expire automatically |
| `UserPromotionDuration` | `15` | Fifteen minutes |
| `UserPromotionReason` | `true` | Elevation requires a typed justification |
| `UserPromotionChoices` | list | Predefined reasons, for consistent logging |

Expiry is enforced by the OS rather than by a cleanup script or anyone's diligence. The reason field is what turns this from a convenience feature into an auditable control — it answers "what is admin being used for", not just "who has it".

Pairs with [PrivilegeElevationReasons](../../ExtensionAttributes/PrivilegeElevationReasons), which surfaces the justifications into inventory.

---

## Preference domain

`com.jamf.connect`
