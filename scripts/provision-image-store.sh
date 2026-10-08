#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Install a packaged image set (built by make-image-pack.sh) as a read-only
# Podman image store on a lab VM or golden image.
#
#   sudo ./provision-image-store.sh /path/to/pack-dir [/destination/dir]
#
# What it does:
#   1. verifies the pack's sha256 manifest
#   2. loads every *.tar into a fresh Podman store at the destination
#      (default: /opt/<pack-name>-images)
#   3. makes the store world-readable and registers it in
#      /etc/containers/storage.conf as an additionalimagestore
#   4. verifies the store contents
#
# Why: with the store registered, every ROOTLESS Podman user on machines
# running this image sees the images as their own — podman images lists them,
# docker compose (via Podman's Docker-compatible socket) uses them — with no
# pull, no network, and no registry policy involved. 100 students starting a
# lab cost nothing in egress and nothing in wait time.
#
# Idempotent: re-running tops up the same destination and never duplicates the
# storage.conf entry. To withdraw a pack: delete the destination directory and
# remove its entry from additionalimagestores.
#
# Canonical copy: assume-breach-labs/scripts/. Copies in the mock-exam and
# ISYS2012 exam repos are kept in step; if they drift, this file wins.
# ---------------------------------------------------------------------------
set -euo pipefail

[ "$#" -ge 1 ] || { echo "usage: sudo $0 /path/to/pack-dir [/destination/dir]"; exit 1; }
[ "$(id -u)" -eq 0 ] || { echo "Run as root:  sudo $0 /path/to/pack-dir"; exit 1; }
command -v podman >/dev/null 2>&1 || { echo "podman is not installed."; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "python3 is required for the storage.conf merge."; exit 1; }

PACK="$(cd "$1" && pwd)"
STORE_NAME="$(basename "$PACK")"
DEST="${2:-/opt/$(printf '%s' "$STORE_NAME" | sed 's/-pack$//')-images}"
CONF=/etc/containers/storage.conf

[ -f "$PACK/manifest.sha256" ] || { echo "No manifest.sha256 in $PACK (is this a pack dir?)"; exit 1; }

echo "==> Verifying the pack (sha256) ..."
( cd "$PACK" && sha256sum -c --quiet manifest.sha256 )
echo "    all tarballs match."

echo "==> Loading images into $DEST ..."
mkdir -p "$DEST"
n=0
for tar in "$PACK"/*.tar; do
    [ -e "$tar" ] || { echo "No *.tar in $PACK"; exit 1; }
    n=$((n + 1))
    echo "    [$n] $(basename "$tar")"
    podman --root "$DEST" load --input "$tar"
done

echo "==> Making the store world-readable ..."
chmod -R a+rX "$DEST"

echo "==> Registering $DEST in $CONF ..."
touch "$CONF"
python3 - "$CONF" "$DEST" <<'PY'
import pathlib, re, sys

conf, dest = pathlib.Path(sys.argv[1]), sys.argv[2]
text = conf.read_text() if conf.exists() else '[storage]\n'
line = re.compile(r'^\s*additionalimagestores\s*=\s*\[(.*)\]\s*$', re.M)
m = line.search(text)
if m:
    have = [e.strip().strip('"\'') for e in m.group(1).split(',') if e.strip()]
    if dest not in have:
        have.append(dest)
        text = line.sub('additionalimagestores = [' + ', '.join('"%s"' % e for e in have) + ']', text, count=1)
    else:
        print('    already registered, leaving as is')
elif 'additionalimagestores' not in text:
    text = re.sub(r'^\[storage\]\s*$',
                  '[storage]\nadditionalimagestores = ["%s"]' % dest,
                  text, count=1, flags=re.M)
else:
    sys.exit('storage.conf mentions additionalimagestores but not as one line; merge by hand')
conf.write_text(text)
PY

echo "==> Verifying ..."
loaded="$(podman --root "$DEST" images --format '{{.Repository}}:{{.Tag}}' | sort -u)"
[ -n "$loaded" ] || { echo "Store is empty — load step failed?"; exit 1; }
echo "$loaded" | sed 's/^/    /'

cat <<EOF

Done. $n image pack(s) installed from $STORE_NAME into $DEST and registered.

Check from a (non-root) user account on a machine running this image:
    podman images          # the images above should appear
    cd <lab folder> && bash start.sh

To withdraw this pack later:
    rm -rf $DEST
    and drop its entry from additionalimagestores in $CONF
EOF
