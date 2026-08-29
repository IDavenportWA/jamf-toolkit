# VS Code Enterprise Restrictions

Enforces an extension allowlist and disables telemetry in Visual Studio Code.

Manages Visual Studio Code through the `com.microsoft.VSCode` preference domain, permitting extensions broadly while denying AI coding assistants that would send source code to unreviewed vendors.

| Key | Value |
|---|---|
| `AllowedExtensions` | `"*": true` plus 28 named denials |
| `TelemetryLevel` | `off` |
| `ExtensionsAutoUpdate` | `on` |
| `UpdateMode` | `start` |

**The shape is deliberate.** A pure allowlist — deny everything, permit by name — is unworkable, because developers use hundreds of legitimate extensions and IT becomes a bottleneck on every linter and theme. Denying by name keeps the default permissive so nobody's workflow breaks, while the specific tools that route source code offsite do not load.

Locally-hosted assistants are denied too. A local model solves data egress but not the second risk: unreviewed code entering the codebase. The approval question is "has this been reviewed", not "does it phone home".

The sanctioned assistant is deliberately absent from the deny list — one approved, licensed tool available to everyone is what makes the denials reasonable rather than obstructive.

**Caveat:** enforcement is by extension identifier, so it is evadable by a determined person and is not a hard security boundary. What it removes is *accidental* adoption, which is the bulk of the actual risk.

**Pairs with** [VSCodeExtensions](../../ExtensionAttributes/VSCodeExtensions), which reports what is actually installed.

**Preference domain:** `com.microsoft.VSCode`
