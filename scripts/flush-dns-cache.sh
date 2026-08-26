#!/bin/bash

###
#
#                    Author : Isaac Davenport
#                   Created : 08-25-2026
#             Last Modified : 08-25-2026
#                   Version : 1.0
#               Tested with : macOS 26.5.2
#
#   1.0: Initial versioned header. Flushes the macOS DNS cache.
#
###

# Flush DNS, works on macOS 10.14-10.15
killall -HUP mDNSResponder
dscacheutil -flushcache
