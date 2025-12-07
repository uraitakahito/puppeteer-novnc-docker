#
# Dockerfile for building a Chromium server environment (Development)
#
# ## Features of this Dockerfile
#
# ### Development
# - You can verify Chromium operations via VNC using a browser
# - Node.js and Claude Code are pre-installed
# - Includes dotfiles and extra utilities
# - Assumes host OS is Mac
#
# ## Preparation
#
# ### SSH Agent
#
# Uses ssh-agent. After a restart, if you have not yet initiated an SSH login from your Mac, run the following command on the Mac.
#
#   ssh-add --apple-use-keychain ~/.ssh/id_ed25519
#
# For more details about ssh-agent, see:
#
#   https://github.com/uraitakahito/hello-docker/blob/1893a1d98ecd4646bc9c570574d1708586f44bec/README.md
#
# ## From Docker build to login
#
# ### Build the Docker image
#
#   PROJECT=$(basename `pwd`) && docker image build -f docker/development/Dockerfile -t $PROJECT-image:development . --build-arg user_id=`id -u` --build-arg group_id=`id -g` --build-arg TZ=Asia/Tokyo
#
# ### Run the container
#
# Create a volume to persist the command history executed inside the Docker container.
# It is stored in the volume because the dotfiles configuration redirects the shell history there.
#   https://github.com/uraitakahito/dotfiles/blob/b80664a2735b0442ead639a9d38cdbe040b81ab0/zsh/myzshrc#L298-L305
#
#   docker volume create $PROJECT-zsh-history
#
# (First time only) Create the network:
#
#   docker network create chromium-network
#
# When starting two Docker containers:
#
#   docker container run -d --rm --init -v /run/host-services/ssh-auth.sock:/run/host-services/ssh-auth.sock -e SSH_AUTH_SOCK=/run/host-services/ssh-auth.sock -e NODE_ENV=development --mount type=bind,src=`pwd`,dst=/app --mount type=volume,source=$PROJECT-zsh-history,target=/zsh-volume -p 5901:5901 -p 6080:6080 -p 9222:9222 --network chromium-network --name chromium-server-1 $PROJECT-image:development
#   docker container run -d --rm --init -v /run/host-services/ssh-auth.sock:/run/host-services/ssh-auth.sock -e SSH_AUTH_SOCK=/run/host-services/ssh-auth.sock -e NODE_ENV=development --mount type=bind,src=`pwd`,dst=/app --mount type=volume,source=$PROJECT-zsh-history,target=/zsh-volume -p 5902:5901 -p 6081:6080 -p 9223:9222 --network chromium-network --name chromium-server-2 $PROJECT-image:development
#
# Log in to Docker:
#
#   fdshell /bin/zsh
#
# About fdshell:
#   https://github.com/uraitakahito/dotfiles/blob/37c4142038c658c468ade085cbc8883ba0ce1cc3/zsh/myzshrc#L93-L101
#
# Only for the first startup, change the owner of the command history folder:
#
#   sudo chown -R $(id -u):$(id -g) /zsh-volume
#
# ## Launch Claude
#
#   claude --dangerously-skip-permissions
#
# ## Process Management
#
# Chromium and socat are managed by supervisord. To check status:
#
#   supervisorctl -c /etc/supervisor/conf.d/app.conf status
#
# To restart Chromium:
#
#   supervisorctl -c /etc/supervisor/conf.d/app.conf restart chromium
#
# ## Chrome DevTools Protocol
#
# Check CDP availability:
#
#   curl http://localhost:9222/json/version
#
# ## Connect from Visual Studio Code
#
# 1. Open **Command Palette (Shift + Command + p)**
# 2. Select **Dev Containers: Attach to Running Container**
# 3. Open the `/app` directory
#
# For details:
#   https://code.visualstudio.com/docs/devcontainers/attach-container#_attach-to-a-docker-container
#

# Debian 12.12
FROM debian:bookworm-20251117

ARG user_name=developer
ARG user_id
ARG group_id
ARG features_repository="https://github.com/uraitakahito/features.git"
ARG dotfiles_repository="https://github.com/uraitakahito/dotfiles.git"
ARG extra_utils_repository="https://github.com/uraitakahito/extra-utils.git"
# Refer to the following URL for Node.js versions:
#   https://nodejs.org/en/about/previous-releases
ARG node_version="24.4.0"
ARG TZ

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

#
# Install Node
#   https://github.com/uraitakahito/features/blob/develop/src/node/install.sh
#
RUN INSTALLYARNUSINGAPT=false \
    NVMVERSION="latest" \
    PNPM_VERSION="none" \
    USERNAME=${user_name} \
    VERSION=${node_version} \
      /usr/src/features/src/node/install.sh

# Puppeteer environment variables (development only, for running automation scripts)
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

#
# Xvfb (X Virtual Framebuffer)
# Provides a virtual display for VNC-based visual debugging
#
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      xvfb && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

#
# Install extra utils.
#
RUN cd /usr/src && \
  git clone --depth 1 ${extra_utils_repository} && \
  ADDEZA=true \
  UPGRADEPACKAGES=false \
    /usr/src/extra-utils/utils/install.sh

##############################
#  VNC support starts here   #
##############################
#
# desktop-lite
# installsAfter: common-utils
# https://github.com/uraitakahito/features/blob/0e14fce20c1008c837ac6b31b04297bd35108f9e/src/desktop-lite/devcontainer-feature.json#L58
#
RUN /usr/src/features/src/desktop-lite/install.sh
##############################
#  VNC support ends here     #
##############################

RUN usermod -aG audio ${user_name} && \
  usermod -aG video ${user_name}

USER ${user_name}

#
# dotfiles
#
RUN cd /home/${user_name} && \
  git clone --depth 1 ${dotfiles_repository} && \
  dotfiles/install.sh

#
# Claude Code
#
# Discussion about using nvm during Docker container build:
#   https://stackoverflow.com/questions/25899912/how-to-install-nvm-in-docker
#
# There is an official devcontainer. You may use the official one instead of this Dockerfile.
#   https://github.com/anthropics/claude-code/blob/main/.devcontainer/Dockerfile
#
ENV NVM_DIR=/usr/local/share/nvm
RUN bash -c "source $NVM_DIR/nvm.sh && \
             nvm use ${node_version} && \
             npm install -g @anthropic-ai/claude-code"

####################################
#  Puppeteer support starts here   #
####################################
#
# WARNING: Do NOT expose port 9222 here.
#
# When VS Code's "Attach to Running Container" feature connects to this container,
# it automatically detects exposed ports and sets up port forwarding from the Mac's
# localhost to the container. This is called "Auto Forward Ports" feature.
#
# In projects where a server runs on the Mac host (e.g., CDP server) and
# the container connects to it via `--add-host=<hostname>:host-gateway`, exposing
# the same port here causes a conflict.
#
# If this port is exposed, VS Code will forward Mac's localhost:<port> to the
# container's localhost:<port>, which intercepts connections intended for the
# Mac host server. This causes WebSocket or HTTP connections to hang indefinitely.
#
# Symptoms:
#   - TCP connection succeeds (handshake completes)
#   - But no data is received and the connection eventually times out
#   - Works fine before VS Code attaches, fails after attaching
#
# To disable VS Code's auto port forwarding, you can also add this to settings.json:
#   "remote.autoForwardPorts": false
# Or ignore specific ports:
#   "remote.portsAttributes": { "3000": { "onAutoForward": "ignore" } }
#
# EXPOSE 9222
#
####################################
#  Puppeteer support ends here     #
####################################

##############################
#  VNC support starts here   #
##############################
#
# desktop-lite
# https://github.com/uraitakahito/features/blob/0e14fce20c1008c837ac6b31b04297bd35108f9e/src/desktop-lite/install.sh#L296-L417
#
ENV TZ="$TZ"
ENV USERNAME=${user_name}
ENV VNC_PORT=5901
ENV NOVNC_PORT=6080
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
COPY --chmod=644 supervisord-headful.conf /etc/supervisor/conf.d/app.conf
COPY --chmod=755 start-chromium.sh /app/start-chromium.sh
COPY --chmod=644 chromium-headful.conf /app/chromium.conf
COPY --chmod=755 start-supervised.sh /usr/local/bin/start-supervised.sh

ENTRYPOINT ["/usr/local/share/desktop-init.sh"]
CMD ["/usr/local/bin/start-supervised.sh"]
##############################
#  VNC support ends here     #
##############################
