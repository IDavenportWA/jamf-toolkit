#!/bin/bash

# Flush DNS, works on macOS 10.14-10.15
killall -HUP mDNSResponder
dscacheutil -flushcache
