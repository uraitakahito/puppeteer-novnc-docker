#
# Dockerfile for building a Puppeteer development environment
#
# ## Features of this Dockerfile
#
# - You can verify Puppeteer operations via VNC using a browser
# - Claude Code is pre-installed
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
#   https://github.com/uraitakahito/hello-docker/blob/c942ab43712dde4e69c66654eac52d559b41cc49/README.md
#
# ### Download the files required to build the Docker container
#
#   curl -L -O https://raw.githubusercontent.com/uraitakahito/hello-novnc-puppeteer/refs/heads/main/Dockerfile
#
# ## From Docker build to login
#
# Build the Docker image:
#
#   PROJECT=$(basename `pwd`) && docker image build -t $PROJECT-image . --build-arg user_id=`id -u` --build-arg group_id=`id -g` --build-arg TZ=Asia/Tokyo
#
# Create a volume to persist the command history executed inside the Docker container.
# It is stored in the volume because the dotfiles configuration redirects the shell history there.
#   https://github.com/uraitakahito/dotfiles/blob/b80664a2735b0442ead639a9d38cdbe040b81ab0/zsh/myzshrc#L298-L305
#
#   docker volume create $PROJECT-zsh-history
#
# When starting two Docker containers:
#
#   docker container run --add-host=puppeteer-1:host-gateway -d --rm --init -v $SSH_AUTH_SOCK:/ssh-agent -p 5901:5901 -p 6080:6080 -p 9222:9222 -e NODE_ENV=development -e SSH_AUTH_SOCK=/ssh-agent --mount type=bind,src=`pwd`,dst=/app --mount type=volume,source=$PROJECT-zsh-history,target=/zsh-volume --name $PROJECT-container-1 $PROJECT-image
#   docker container run --add-host=puppeteer-2:host-gateway -d --rm --init -v $SSH_AUTH_SOCK:/ssh-agent -p 5902:5901 -p 6081:6080 -p 9223:9222 -e NODE_ENV=development -e SSH_AUTH_SOCK=/ssh-agent --mount type=bind,src=`pwd`,dst=/app --mount type=volume,source=$PROJECT-zsh-history,target=/zsh-volume --name $PROJECT-container-2 $PROJECT-image
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
ARG dotfiles_repository="https://github.com/uraitakahito/dotfiles.git"
ARG features_repository="https://github.com/uraitakahito/features.git"
ARG extra_utils_repository="https://github.com/uraitakahito/extra-utils.git"
# Refer to the following URL for Node.js versions:
#   https://nodejs.org/en/about/previous-releases
ARG node_version="24.4.0"

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

#
# Install extra utils.
#
RUN cd /usr/src && \
  git clone --depth 1 ${extra_utils_repository} && \
  ADDEZA=true \
  UPGRADEPACKAGES=false \
    /usr/src/extra-utils/utils/install.sh

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
      fonts-freefont-ttf \
      socat && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

#
# Xvfb (X Virtual Framebuffer)
# Provides a virtual display for headless browser testing
#
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      xvfb && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

#
# supervisor for process management
#
RUN apt-get update && \
    apt-get install -y --no-install-recommends supervisor && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

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

#
# Firefox is version 115.14(2024/08/15)
#
# RUN apt-get update -qq && \
#   apt-get install -y -qq --no-install-recommends \
#     firefox-esr \
#     firefox-esr-l10n-ja \
#     fonts-noto-cjk \
#     fonts-ipafont-gothic \
#     fonts-ipafont-mincho && \
#   apt-get clean && \
#   rm -rf /var/lib/apt/lists/*

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
ARG TZ
ENV TZ="$TZ"
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
# In projects where a server runs on the Mac host (e.g., Puppeteer server) and
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
ENV USERNAME=${user_name}
ENV VNC_PORT=5901
ENV NOVNC_PORT=6080
WORKDIR /app

# Copy supervisor configuration and startup script
# Note: --chmod=644 is required because:
#   - The container runs as 'developer' user (non-root)
#   - Without explicit chmod, COPY preserves the source file's permissions
#   - If the source file has 600 permissions, supervisord cannot read it
COPY --chmod=644 supervisord.conf /etc/supervisor/conf.d/app.conf
COPY --chmod=755 start-supervised.sh /usr/local/bin/start-supervised.sh

ENTRYPOINT ["/usr/local/share/desktop-init.sh"]
CMD ["/usr/local/bin/start-supervised.sh"]
##############################
#  VNC support ends here     #
##############################
