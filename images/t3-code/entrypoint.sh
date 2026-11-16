#!/bin/sh
# Starts the T3 Code server for the umbrelOS app im28-t3-code.
#
# $HOME is the app's data volume. On first start this installs T3 Code and Claude Code into it with
# their official installers. After that both keep themselves up to date inside the volume, so a
# new image is only needed for operating-system tools.
#
# The server runs under T3 Code's own service launcher (what `t3 service install` puts in a
# systemd unit). The launcher is what lets the T3 apps update this server remotely and roll a bad
# update back. There is no systemd in a container, so this script starts the launcher directly.
set -eu

log() { printf '[t3-entrypoint] %s\n' "$*" >&2; }

: "${HOME:=/home/t3}"
export HOME
export T3CODE_HOME="${T3CODE_HOME:-$HOME/.t3}"
export PATH="$HOME/.local/bin:$PATH"
channel="${T3CODE_CHANNEL:-nightly}"
runtime="$T3CODE_HOME/runtime"
state="$runtime/service-state.json"

[ -w "$HOME" ] || { log "$HOME is not writable by uid $(id -u). Fix the owner of the data folder."; exit 1; }
cd "$HOME"
mkdir -p "$HOME/.local/bin" "$HOME/projects"

# Download an installer to a file, then run it, so a failed download never runs a half script.
# Tries 5 times: the network can still be coming up right after the Umbrel boots.
run_installer() {
  name="$1" url="$2" shell="$3"
  script="$(mktemp)"
  attempt=1
  while :; do
    if curl -fsSL --retry 2 --connect-timeout 20 "$url" -o "$script" && "$shell" "$script"; then
      rm -f "$script"
      return 0
    fi
    if [ "$attempt" -ge 5 ]; then
      rm -f "$script"
      return 1
    fi
    log "Installing $name failed (attempt $attempt of 5). Retrying in $((attempt * 10)) s."
    sleep "$((attempt * 10))"
    attempt=$((attempt + 1))
  done
}

complete() { [ -x "$runtime/versions/$1/t3" ] && [ -f "$runtime/versions/$1/.install-complete" ]; }

# The version the launcher last selected. A remote update changes it.
active=""
if [ -f "$state" ]; then
  active="$(jq -r '.activeVersion // empty' "$state" 2>/dev/null || true)"
  if [ -n "$active" ] && ! complete "$active"; then
    log "service-state.json selects t3 $active, but that version is not on disk. Starting over."
    active=""
    rm -f "$state"
  fi
fi

# A remote update moves the `t3` command along with the server. The command is only ahead of
# the server after someone ran `t3 update` by hand in the container, so follow it then. Never
# follow it backwards (the database may already be migrated), and never while an update is
# pending: the launcher must finish or roll that one back first.
if [ -n "$active" ] && [ "$(jq -r '.update.status // empty' "$state" 2>/dev/null)" != pending ]; then
  cli="$("$HOME/.local/bin/t3" --version 2>/dev/null | sed -n 's/^t3 v//p' || true)"
  if [ -n "$cli" ] && [ "$cli" != "$active" ] && complete "$cli" &&
    [ "$(printf '%s\n%s\n' "$active" "$cli" | sort -V | tail -n 1)" = "$cli" ]; then
    log "The t3 command is at $cli and the server at $active. Switching the server to $cli."
    active=""
    rm -f "$state"
  fi
fi

if [ -z "$active" ]; then
  if ! [ -x "$HOME/.local/bin/t3" ] || ! "$HOME/.local/bin/t3" --version >/dev/null 2>&1; then
    log "Installing T3 Code ($channel channel)."
    rm -f "$HOME/.local/bin/t3"
    T3CODE_CHANNEL="$channel" run_installer "T3 Code" https://t3.codes/install.sh sh ||
      { log "Could not install T3 Code. Check the network and restart the app."; exit 1; }
  fi
  active="$("$HOME/.local/bin/t3" --version | sed -n 's/^t3 v//p')"
  if ! complete "$active"; then
    log "Cannot find the runtime for t3 '$active' under $runtime/versions. Running 't3 serve' without the launcher."
    exec "$HOME/.local/bin/t3" serve
  fi
  mkdir -p "$runtime"
  printf '{"protocol":4,"activeVersion":"%s"}\n' "$active" > "$state.tmp"
  mv "$state.tmp" "$state"
fi

if ! [ -x "$HOME/.local/bin/claude" ]; then
  log "Installing Claude Code."
  run_installer "Claude Code" https://claude.ai/install.sh bash ||
    log "Could not install Claude Code. T3 Code starts without it; restart the app to try again."
fi

log "Starting T3 Code $active on port ${T3CODE_PORT:-3773}."
exec "$runtime/versions/$active/t3" __service-launcher
