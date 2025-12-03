# Chromium Server Docker

A Docker environment for running Chromium with Chrome DevTools Protocol (CDP) support. Provides both production and development targets using multi-stage builds.

## Overview

This project provides a Docker environment for running Chromium with Chrome DevTools Protocol (CDP) support.

**Two build targets are available:**
- **Production**: Headless Chromium with minimal footprint (no Node.js, no VNC)
- **Development**: Full-featured environment with VNC, Node.js, and development tools

## Setup Instructions

**All build commands, run commands, and detailed environment setup instructions are documented at the beginning of the [`Dockerfile`](Dockerfile).**
