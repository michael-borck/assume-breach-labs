#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# One-time setup for an Ubuntu (tested: 24.04) lab or exam VM image so the
# assume-breach labs run with ZERO container knowledge and ZERO extra typing:
# students download the ZIP and run  bash start.sh .
#
#   sudo bash scripts/setup-vm.sh        # once, at image build
#
# Podman-only by design — no Docker packages involved. Root is needed once,
# here, purely to install packages; nothing about running the labs needs it
# (rootless Podman runs everything as the logged-in student).
#
# What it does:
#   1. Podman + its modern network stack: netavark and aardvark-dns provide
#      custom networks and the container DNS that makes "ssh fileserver"
#      resolve; passt/slirp4netns cover rootless port publishing.
#   2. A profile-capable compose for every user: one shared venv in /opt,
#      symlinked into /usr/local/bin. (Ubuntu 24.04's stock podman-compose,
#      1.0.6, predates Compose profiles and cannot start the labs.)
#
# Offline or fast starts: pre-pull the module images — see
# docs/SERVER-DEPLOYMENT.md Part B. Individual users without admin rights can
# fix their own account with scripts/setup-user.sh (no sudo).
# ---------------------------------------------------------------------------
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
    echo "Run as root:  sudo bash $0"
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive

echo "==> Installing Podman + network stack + python venv ..."
apt-get update -qq
apt-get install -y \
    podman uidmap dbus-user-session \
    netavark aardvark-dns \
    passt slirp4netns catatonit \
    python3-venv

echo "==> Installing a profile-capable podman-compose for all users ..."
python3 -m venv /opt/podman-compose
/opt/podman-compose/bin/pip install -q --upgrade pip
/opt/podman-compose/bin/pip install -q podman-compose
ln -sfn /opt/podman-compose/bin/podman-compose /usr/local/bin/podman-compose

echo "==> Verifying ..."
podman info >/dev/null
/opt/podman-compose/bin/podman-compose --help 2>&1 | grep -q -- '--profile' || {
    echo "podman-compose is still too old — check the pip install above."; exit 1;
}
BACKEND="$(podman info --format '{{.Host.NetworkBackend}}')"
echo "Podman network backend: $BACKEND (want netavark)"
[ "$BACKEND" = "netavark" ] || echo "WARNING: not netavark — container DNS may not resolve on custom networks."

cat <<'EOF'

Done. Verify as a student account, from the extracted lab folder:

    bash start.sh

First module start per account pulls images from GHCR (~1-2 min on campus
network). For offline sittings, pre-pull per docs/SERVER-DEPLOYMENT.md Part B.
EOF
