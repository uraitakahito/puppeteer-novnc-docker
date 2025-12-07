# Chromium Server Docker

A Docker environment for running Chromium with Chrome DevTools Protocol (CDP) support.

## Overview

This project provides Docker environments for running Chromium with Chrome DevTools Protocol (CDP) support.

**Two separate Dockerfiles are available:**
- **Production** : Headless Chromium with minimal footprint
- **Development** : Full-featured environment with VNC, Node.js, and development tools

## Setup Instructions

⚠️ **Important**: All build commands, run commands, and detailed environment setup instructions are documented at the beginning of each Dockerfile. Please refer to the appropriate Dockerfile for complete instructions:

- **Production**: See [docker/production/Dockerfile](docker/production/Dockerfile)
- **Development**: See [docker/development/Dockerfile](docker/development/Dockerfile)

This ensures a single source of truth and prevents documentation from becoming outdated.
