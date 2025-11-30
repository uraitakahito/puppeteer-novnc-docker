#!/bin/bash

# Keep Chromium bound to localhost and forward externally with:
#
#   socat TCP-LISTEN:9222,reuseaddr,fork TCP:localhost:9223
#
# This lets you access the debugger via port 9222 while Chromium listens only on 127.0.0.1:9223.

chromium --remote-debugging-port=9223 \
         --remote-debugging-address=127.0.0.1 \
         --no-first-run \
         --no-default-browser-check \
         --disable-background-networking \
         --disable-dev-shm-usage \
         --disable-gpu \
         --no-sandbox \
         --disable-setuid-sandbox \
         --password-store=basic \
         --user-data-dir=/tmp/chrome-profile
