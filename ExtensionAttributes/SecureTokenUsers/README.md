# Secure Token Users

**Reports every local account holding a secure token.**

On a FileVault volume only a secure-token-enabled account can unlock the disk at pre-boot. Standard inventory does not expose this, so a device can report encrypted and compliant while the person holding it cannot unlock it after a restart — discovered at the worst possible moment.

Enumerates local users via `jamf listUsers`, transformed through a generated XSLT stylesheet, and tests each with `sysadminctl -secureTokenStatus`.

---

## Notes

`sysadminctl` writes its status to **stderr**, so the `2>&1` redirect is required — without it every user tests as not-enabled and the attribute reports "No users have a secure token" across the whole fleet. The temp stylesheet is created with `mktemp` and removed by an exit trap.

## Data type

String.
