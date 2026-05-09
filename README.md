# Chromium Server Docker

A Docker environment for running Chromium with Chrome DevTools Protocol (CDP) support.

## Overview

This project provides Docker environments for running Chromium with Chrome DevTools Protocol (CDP) support.

The image is intended to be driven externally over CDP (e.g. by
[BrowserHive](https://github.com/uraitakahito/browserhive)). Chromium
is launched with a small, opinionated set of flags chosen to make
this driving model predictable: each worker is expected to reuse one
tab for its lifetime, navigations to `about:blank` are expected to
fully tear down the previous document, and the container has no
desktop environment so OS-integration probes (keychain,
gnome-keyring, etc.) must be suppressed. See the inline comments in
`chromium-{headless,headful}.conf` for the per-flag rationale.

The image installs the `dbus` package and wraps Chromium in
`dbus-run-session` (see `start-chromium.sh`) so a fresh per-process
session bus is spawned for every Chromium launch. This suppresses
the session-bus probes Chromium emits at startup. The system bus is
intentionally left unreachable (no `dbus-daemon --system`); the
residual stderr noise from UPower / NetworkManager probes is treated
as known noise and filtered at the log-aggregation layer if needed.
`dbus-x11` and `DBUS_SESSION_BUS_ADDRESS=autolaunch:` are deliberately
NOT used — autolaunch requires `$DISPLAY` and is therefore unusable
in a fully-headless container.

**Two separate Dockerfiles are available:**
- **Production** : Headless Chromium with minimal footprint
- **Development** : Full-featured environment with VNC, Node.js, and development tools

## Setup Instructions

⚠️ **Important**: All build commands, run commands, and detailed environment setup instructions are documented at the beginning of each Dockerfile. Please refer to the appropriate Dockerfile for complete instructions:

- **Production**: See [docker/production/Dockerfile](docker/production/Dockerfile)
- **Development**: See [docker/development/Dockerfile](docker/development/Dockerfile)

This ensures a single source of truth and prevents documentation from becoming outdated.

## Related Projects

### BrowserHive

[BrowserHive](https://github.com/uraitakahito/browserhive) is a scalable web page capture server that uses this project as its browser backend. It provides:

- gRPC API for screenshot and HTML extraction
- Worker pool architecture for parallel processing
- Support for multiple remote Chromium instances via CDP
