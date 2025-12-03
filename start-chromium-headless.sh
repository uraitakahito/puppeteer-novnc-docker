#!/bin/bash
#
# Chromium startup script (Production - Headless mode)
#
# Uses --headless flag for native headless execution without Xvfb
# Reference: https://developer.chrome.com/blog/headless-chrome/
#
# ## About --remote-debugging-address
#
# Originally, --remote-debugging-address=0.0.0.0 should allow external CDP connections,
# but this flag has been disabled or removed in recent Chromium versions for security reasons.
#
# According to Chromium Issue Tracker:
#   - "This switch presents a security issue and should not be used"
#   - "We are planning to remove it from the old headless and there are
#      no plans to implement it in the new headless"
#
# Therefore, Chromium listens only on localhost (127.0.0.1),
# and external connections are achieved through socat port forwarding.
#
# References:
#   - https://issues.chromium.org/issues/40261787
#   - https://issues.chromium.org/issues/40279369
#

chromium --headless \
         --remote-debugging-port=9223 \
         --remote-debugging-address=127.0.0.1 \
         --no-first-run \
         --no-default-browser-check \
         --disable-background-networking \
         --disable-dev-shm-usage \
         --disable-gpu \
         --no-sandbox \
         --disable-setuid-sandbox \
         --disk-cache-size=2147483648 \
         --user-data-dir=/tmp/chrome-profile
