# App Auto Patch Status

**Reports App Auto-Patch results per title, split into successes and failures.**

Reads every `latest.json` under `/Library/Management/AppAutoPatch/receipts/` and reports one line per title: `label | version | timestamp | exitCode | status`.

Output is grouped under **Success:** and **Failure:** so a smart group can target devices with any failing title, rather than requiring someone to read a long success list carefully enough to spot the exceptions. Silent partial failure — one title failing on some machines for weeks — is the realistic failure mode of automated patching.

---

## Notes

Status is derived from the exit code when a receipt omits it, output is capped at 50 titles to keep inventory records manageable, and a missing receipts folder reports explicitly rather than returning empty.

## Data type

String.
