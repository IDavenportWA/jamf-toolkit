#!/bin/bash

# Disable IPv6 on all network services on macOS

services=$(networksetup -listallnetworkservices | tail -n +2)

echo "Disabling IPv6 on:"
echo "$services"
echo

while IFS= read -r service; do
    if [ -n "$service" ]; then
        echo "→ Disabling IPv6 for: $service"
        networksetup -setv6off "$service" 2>/dev/null
    fi
done <<< "$services"

echo
echo "IPv6 has been disabled on all network services."
