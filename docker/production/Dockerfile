#
# Dockerfile for building a Chromium server environment (Production)
#
# ## Features of this Dockerfile
#
# ### Production
# - Headless Chromium execution (no display server required)
# - Minimal footprint without Node.js or development tools
# - Chrome DevTools Protocol access on port 9222 via socat
# - Use with external CDP client connecting remotely
# - Based on Debian slim variant for reduced image size
#
# ## From Docker build to login
#
# ### Build the Docker image
#
#   PROJECT=$(basename `pwd`) && docker image build -f docker/production/Dockerfile -t $PROJECT-image:production . --build-arg user_id=`id -u` --build-arg group_id=`id -g`
#
# ### Run the container
#
#   docker container run -d --rm --init --network chromium-network -p 9222:9222 --name chromium-server-1 $PROJECT-image:production
#
# ## Chrome DevTools Protocol
#
# Check CDP availability:
#
#   curl http://localhost:9222/json/version
#

# Debian 12.13 slim variant
FROM debian:bookworm-20260518-slim

ARG user_name=developer
ARG user_id
ARG group_id
# https://github.com/uraitakahito/features/releases/tag/2.0.1
ARG features_repository="https://github.com/uraitakahito/features.git"
ARG features_commit="9f7e672e27207f374d56e5da7f862b0b5b110b3f"

# Avoid warnings by switching to noninteractive for the build process
ENV DEBIAN_FRONTEND=noninteractive

ARG LANG=C.UTF-8
ENV LANG="$LANG"
ARG TZ=UTC
ENV TZ="$TZ"

#
# Git
#
RUN apt-get update -qq && \
    apt-get install -y -qq --no-install-recommends \
        ca-certificates \
        git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

#
# clone features
#
RUN cd /usr/src && \
    git clone ${features_repository} && \
    cd features && \
    git checkout ${features_commit}

#
# Add user and install common utils.
#
# For the list of installed packages, see:
#   https://github.com/uraitakahito/features/blob/9f7e672e27207f374d56e5da7f862b0b5b110b3f/src/common-utils/main.sh#L35-L79
#
RUN USERNAME=${user_name} \
    USERUID=${user_id} \
    USERGID=${group_id} \
    CONFIGUREZSHASDEFAULTSHELL=true \
    UPGRADEPACKAGES=false \
        /usr/src/features/src/common-utils/install.sh

# Install latest chrome dev package and fonts to support major charsets (Chinese, Japanese, Arabic, Hebrew, Thai and a few others)
# Note: this installs the necessary libs to make the bundled version of Chromium that Puppeteer
# installs, work.
# https://zenn.dev/tom1111/articles/0dc7cde5c8e9bf
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        chromium \
        chromium-sandbox \
        fonts-ipafont-gothic \
        fonts-wqy-zenhei \
        fonts-thai-tlwg \
        fonts-kacst \
        fonts-freefont-ttf && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

#
# dbus daemon for session-bus wrapping
#
# Chromium probes the dbus session bus at startup for several
# subsystems (Notifications, ScreenSaver, AT-SPI). Without any
# session bus reachable, each probe emits a "Failed to connect to
# the bus" line to stderr on every container launch.
#
# We install the `dbus` package because `start-chromium.sh` invokes
# `dbus-run-session chromium ...`. That helper, shipped in `dbus`,
# spawns a fresh per-process session bus, exports
# DBUS_SESSION_BUS_ADDRESS for the wrapped command, forwards
# SIGHUP/SIGTERM/SIGINT to the child, and tears the daemon down
# when chromium exits. No long-lived dbus daemon is needed in
# supervisord.
#
# Why NOT `dbus-x11` + DBUS_SESSION_BUS_ADDRESS=autolaunch:
# `dbus-launch --autolaunch` (from `dbus-x11`) requires $DISPLAY
# — it uses an X11 atom to coordinate daemons — and refuses to
# spawn without it. Empirically broken in fully-headless containers
# like this one, so `dbus-x11` is deliberately NOT installed.
#
# Scope: this silences SESSION-bus errors only. SYSTEM-bus probes
# (UPower, NetworkManager, BlueZ) still fail because
# `dbus-daemon --system` is intentionally not running — running it
# would require a long-lived root daemon and contradict this image's
# "thin CDP container" stance. Remaining system-bus stderr
# noise is acknowledged and left for log-aggregation-layer
# filtering.
#
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        dbus && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

#
# supervisor for process management
#
RUN apt-get update && \
    apt-get install -y --no-install-recommends supervisor && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

#
# socat for Chrome DevTools Protocol port forwarding
#
# Why socat is required:
#   Chromium's --remote-debugging-address=0.0.0.0 flag has been disabled or removed
#   in recent versions for security reasons. The Chromium team has stated this flag
#   "presents a security issue and should not be used" and there are "no plans to
#   implement it in the new headless mode."
#
#   As a workaround, we use socat to forward external connections (0.0.0.0:9222)
#   to Chromium's localhost-only debugging port (127.0.0.1:9223).
#
# References:
#   - https://issues.chromium.org/issues/40261787
#   - https://issues.chromium.org/issues/40279369
#
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        socat && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

USER ${user_name}

WORKDIR /app

# Copy supervisor configuration and startup script
# Note: --chmod=644 is required because:
#   - The container runs as 'developer' user (non-root)
#   - Without explicit chmod, COPY preserves the source file's permissions
#   - If the source file has 600 permissions, supervisord cannot read it
#
# WARNING: Files copied to /app will be overwritten if you use bind mount:
#   --mount type=bind,src=`pwd`,dst=/app
# In that case, the host's files are used instead of these copied files.
COPY --chmod=644 supervisord-headless.conf /etc/supervisor/conf.d/app.conf
COPY --chmod=755 start-chromium.sh /app/start-chromium.sh
COPY --chmod=644 chromium-headless.conf /app/chromium-headless.conf

# Health check for CDP availability
HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
    CMD curl -sf http://localhost:9222/json/version || exit 1

# Headless mode execution (Xvfb not required)
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/app.conf"]
