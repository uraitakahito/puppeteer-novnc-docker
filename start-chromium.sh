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
#   docker container run -v /path/to/custom.conf:/app/chromium.conf:ro ...
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

exec chromium ${CHROMIUM_ARGS}
