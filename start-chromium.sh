#!/bin/bash
#
# Chromium unified startup script
#
# Reads options from a configuration file and starts Chromium.
#
# Environment variables:
#   CHROMIUM_CONFIG: Path to the config file (required)
#
# Customization:
#   Mount a custom config file when starting the container:
#   docker container run --mount type=bind,src=/path/to/custom.conf,dst=/app/chromium-headless.conf,readonly ...
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

set -e

if [[ -z "${CHROMIUM_CONFIG}" ]]; then
    echo "Error: CHROMIUM_CONFIG environment variable is not set" >&2
    exit 1
fi

CONFIG_FILE="${CHROMIUM_CONFIG}"

if [[ ! -f "${CONFIG_FILE}" ]]; then
    echo "Error: Configuration file not found: ${CONFIG_FILE}" >&2
    exit 1
fi

# Read options from config file (exclude comments and empty lines)
CHROMIUM_ARGS=$(grep -v '^[[:space:]]*#' "${CONFIG_FILE}" | grep -v '^[[:space:]]*$' | tr '\n' ' ')

echo "Starting Chromium with config: ${CONFIG_FILE}"
echo "Arguments: ${CHROMIUM_ARGS}"

# Wrap Chromium in `dbus-run-session` so a fresh per-process session
# dbus-daemon is spawned and DBUS_SESSION_BUS_ADDRESS is exported
# before chromium starts. This silences the session-bus probes
# Chromium emits at startup (Notifications, ScreenSaver, AT-SPI)
# without needing a long-lived dbus daemon in supervisord.
#
# Why dbus-run-session and not `dbus-launch --autolaunch`:
# autolaunch (from `dbus-x11`) refuses to spawn a daemon when
# $DISPLAY is not set — it uses an X11 atom to coordinate. Unusable
# in a fully-headless container. dbus-run-session (in the `dbus`
# package) has no such X11 dependency, forwards SIGHUP/SIGTERM/
# SIGINT to its child (so supervisord's graceful shutdown still
# reaches Chromium correctly), and tears the daemon down
# automatically when chromium exits.
#
# Scope: SESSION bus only. SYSTEM-bus probes (UPower,
# NetworkManager, BlueZ) remain unsuppressed by design — running
# `dbus-daemon --system` would require a long-lived root daemon
# and contradict this image's "thin CDP container" stance.
#
# Word splitting is intentional: each whitespace-separated token must become
# its own argv entry so chromium parses one flag per element.
# shellcheck disable=SC2086
exec dbus-run-session chromium ${CHROMIUM_ARGS}
