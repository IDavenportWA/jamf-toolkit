#!/bin/zsh --no-rcs

#created by Isaac Davenport - April 15th 2026

set -uo pipefail
export PATH=/usr/bin:/bin:/usr/sbin:/sbin

appAutoPatchReceiptsFolder="/Library/Management/AppAutoPatch/receipts"

if [[ ! -d "$appAutoPatchReceiptsFolder" ]]; then
  echo "<result>No AAP receipts found</result>"
  exit 0
fi

jx() {
  /usr/bin/plutil -extract "$2" raw -o - "$1" 2>/dev/null || echo ""
}

success_lines=()
failure_lines=()

max_items=50
count=0

for f in "$appAutoPatchReceiptsFolder"/*/latest.json; do
  [[ -f "$f" ]] || continue

  label="$(basename "$(dirname "$f")")"

  version="$(jx "$f" version)"
  [[ -z "$version" ]] && version="unknown"

  timestamp="$(jx "$f" timestamp)"
  [[ -z "$timestamp" ]] && timestamp="unknown"

  exitCode="$(jx "$f" exitCode)"
  [[ "$exitCode" =~ ^[0-9]+$ ]] || exitCode=0

  patch_status="$(jx "$f" status)"
  if [[ -z "$patch_status" ]]; then
    if [[ "$exitCode" -eq 0 ]]; then
      patch_status="success"
    else
      patch_status="failed"
    fi
  fi

  line="$label | $version | $timestamp | $exitCode | $patch_status"

  if [[ "$patch_status" == "failed" ]]; then
    failure_lines+=("$line")
  else
    success_lines+=("$line")
  fi

  count=$((count+1))
  [[ $count -ge $max_items ]] && break
done

# Build result safely
result="Success:"

if [[ ${#success_lines[@]} -gt 0 ]]; then
  result+=$'\n'"$(printf "%s\n" "${success_lines[@]}")"
else
  result+=$'\nNone'
fi

result+=$'\n\nFailure:'

if [[ ${#failure_lines[@]} -gt 0 ]]; then
  result+=$'\n'"$(printf "%s\n" "${failure_lines[@]}")"
else
  result+=$'\nNone'
fi

# FINAL OUTPUT
echo "<result>$result</result>"
exit 0
