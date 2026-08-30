# Disable IPv6

**Turns IPv6 off on every network service.**

Enumerates network services with `networksetup -listallnetworkservices` and applies `-setv6off` to each.

Useful where an IPv6 path interferes with split-tunnel VPN behaviour or internal name resolution.
