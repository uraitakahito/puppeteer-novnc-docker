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
# - Minimal dotfiles (vim, tmux) from dotfiles-production repository
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

# Debian 12.12 slim variant
FROM debian:bookworm-20251117-slim

ARG user_name=developer
ARG user_id
ARG group_id
ARG dotfiles_repository="https://github.com/uraitakahito/dotfiles-production.git"
ARG features_repository="https://github.com/uraitakahito/features.git"

# Avoid warnings by switching to noninteractive for the build process
ENV DEBIAN_FRONTEND=noninteractive

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
  git clone --depth 1 ${features_repository}

#
# Add user and install common utils.
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

#
# dotfiles (minimal configuration for production)
#
RUN cd /home/${user_name} && \
  git clone --depth 1 ${dotfiles_repository} dotfiles && \
  ln -sf ~/dotfiles/.vimrc ~/.vimrc && \
  ln -sf ~/dotfiles/.tmux.conf ~/.tmux.conf

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
COPY --chmod=644 chromium-headless.conf /app/chromium.conf

# Headless mode execution (Xvfb not required)
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/app.conf"]
