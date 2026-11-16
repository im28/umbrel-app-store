# Runtime for the T3 Code server on umbrelOS (app im28-t3-code).
#
# The image holds only the operating system and tools. T3 Code and Claude Code are NOT baked in:
# both update themselves, so the entrypoint installs them into the home volume on first start and
# they keep themselves current there.
#
# node:24-trixie-slim (linux/amd64 index digest, 2026-11-12). Node is here for `npx` MCP servers.
FROM node:24-trixie-slim@sha256:af02d57b57719b9657a45199a79264a9437940cd55b3c7b3fc99615654f124a0

ENV DEBIAN_FRONTEND=noninteractive

# Tools agents expect on a dev box, then the libraries and fonts T3 Code's headless Chrome needs
# (the list `t3 browser setup` installs: apps/server/src/preview/PreviewBrowserHost.ts).
# `adb` is both the client agents use and the server the app's `adb` service runs for a USB Android phone.
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates curl wget git openssh-client gnupg \
      jq less procps unzip zip xz-utils bzip2 file ripgrep fd-find tree \
      python3 python3-venv python3-pip make \
      adb \
      tzdata locales \
      libnss3 libglib2.0-0t64 libatk1.0-0t64 libatk-bridge2.0-0t64 libatspi2.0-0t64 libdbus-1-3 \
      libx11-6 libxcb1 libxcomposite1 libxdamage1 libxext6 libxfixes3 libxrandr2 libxkbcommon0 \
      libgbm1 libasound2t64 libexpat1 fontconfig fonts-liberation fonts-noto-color-emoji \
 && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
 && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      > /etc/apt/sources.list.d/github-cli.list \
 && apt-get update \
 && apt-get install -y --no-install-recommends gh \
 && sed -i 's/^# *en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && locale-gen \
 && rm -rf /var/lib/apt/lists/*

# umbrelOS runs app data as uid/gid 1000. Reuse the base image's uid-1000 user under a clearer name.
RUN usermod --login t3 --home /home/t3 --move-home --shell /bin/bash node \
 && groupmod --new-name t3 node

COPY --chmod=755 entrypoint.sh /usr/local/bin/t3-entrypoint
COPY --chmod=755 t3-pair-url.sh /usr/local/bin/t3-pair-url

ENV HOME=/home/t3 \
    LANG=en_US.UTF-8 \
    T3CODE_HOME=/home/t3/.t3 \
    PATH=/home/t3/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

USER 1000:1000
WORKDIR /home/t3
EXPOSE 3773

ENTRYPOINT ["/usr/local/bin/t3-entrypoint"]
