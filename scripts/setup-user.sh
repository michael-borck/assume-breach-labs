#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# No-sudo setup for running the labs on a Podman-only machine (e.g. the Ubuntu
# lab VMs). Fixes the one gap Podman leaves on Ubuntu 24.04: the bundled
# podman-compose (1.0.6) predates Compose profiles, which every lab module
# needs to switch on. Installs a current podman-compose into YOUR home
# directory — nothing system-wide, no root, no Docker.
#
#   bash scripts/setup-user.sh
#
# Afterwards: open a NEW terminal and run the lab as usual:  bash start.sh
#
# Lab staff imaging many machines: scripts/setup-vm.sh does this system-wide
# (plus the Podman network stack) in one sudo command.
#
# Fallback if python3-venv is missing: the script downloads the standalone
# Docker Compose v2 binary instead (a single static file, driven over Podman's
# own socket — the console wires that up itself, still with no sudo).
# ---------------------------------------------------------------------------
set -euo pipefail

BIN="$HOME/.local/bin"
VENV="$HOME/.local/podman-compose"

echo "==> Checking Podman ..."
command -v podman >/dev/null 2>&1 || { echo "Podman is not installed — ask lab staff."; exit 1; }
podman info >/dev/null 2>&1 || { echo "Podman is installed but not answering (try: podman info)."; exit 1; }

mkdir -p "$BIN"

compose_ok() { "$1" --help 2>&1 | grep -q -- '--profile'; }

# Already good (any podman-compose >= 1.2 on PATH)?
for candidate in "$BIN/podman-compose" "$(command -v podman-compose 2>/dev/null || true)"; do
    [ -n "$candidate" ] && [ -x "$candidate" ] && compose_ok "$candidate" && {
        echo "==> $candidate already supports profiles — nothing to do."
        exit 0
    }
done

installed=""
if python3 -m venv "$VENV" 2>/dev/null; then
    echo "==> Installing a current podman-compose (user-local) ..."
    "$VENV/bin/pip" install -q --upgrade pip
    "$VENV/bin/pip" install -q podman-compose
    ln -sfn "$VENV/bin/podman-compose" "$BIN/podman-compose"
    installed="$BIN/podman-compose"
else
    echo "==> python3-venv unavailable; falling back to the standalone Compose v2 binary ..."
    URL="https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64"
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL -o "$BIN/docker-compose" "$URL"
    elif command -v wget >/dev/null 2>&1; then
        wget -qO "$BIN/docker-compose" "$URL"
    else
        echo "Need curl or wget to download the fallback. Ask lab staff."; exit 1
    fi
    chmod +x "$BIN/docker-compose"
    installed="$BIN/docker-compose"
fi

case ":$PATH:" in
    *":$BIN:"*) : ;;
    *)  printf '\n# assume-breach labs: user-local compose\nexport PATH="$HOME/.local/bin:$PATH"\n' >> "$HOME/.bashrc"
        export PATH="$BIN:$PATH" ;;
esac

echo "==> Verifying ..."
compose_ok "$installed" || { echo "Something went wrong: $installed still lacks --profile."; exit 1; }
"$installed" --version 2>/dev/null || true

cat <<'EOF'

Ready. Open a NEW terminal, then from the lab folder:

    bash start.sh

The console finds Podman and this compose automatically — you type nothing else.
EOF
