#!/bin/bash
#
# Chromium startup script (Development - Headful mode)
#
# Runs without --headless flag to allow VNC-based visual debugging
# Uses socat for port forwarding (localhost:9223 -> external:9222)
#
# ## About --remote-debugging-address
#
# Originally, --remote-debugging-address=0.0.0.0 should allow external CDP connections,
# but this flag has been disabled or removed in recent Chromium versions for security reasons.
#
# Therefore, Chromium listens only on localhost (127.0.0.1),
# and external connections are achieved through socat port forwarding.
#
# References:
#   - https://issues.chromium.org/issues/40261787
#   - https://issues.chromium.org/issues/40279369
#

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
         --start-maximized \
         --disk-cache-size=2147483648 \
         --user-data-dir=/tmp/chrome-profile
