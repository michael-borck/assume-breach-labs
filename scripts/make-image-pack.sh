#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Build the OFFLINE image pack for the assume-breach labs.
#
#   ./scripts/make-image-pack.sh [out-dir]      (default: dist/lab-images-pack)
#
# Pulls every image referenced in docker-compose.yml (plus the base images the
# repo's Dockerfiles build FROM) for linux/amd64, saves one tarball per image,
# and assembles a self-contained pack folder:
#
#   dist/lab-images-pack/
#   ├── *.tar                 one per image (docker-archive / OCI, podman-loadable)
#   ├── manifest.sha256       verified by the provision script
#   ├── provision-image-store.sh   what IT runs (see that file)
#   └── README-IT.txt         the one-page handover
#
# Run it on a machine with registry access (a normal Docker or Podman setup).
# The pack is then installed on lab VMs / the VDI golden image offline:
# no GHCR stampede at class start, no dependency on registry policy.
#
# CONTAINER_ENGINE=docker|podman overrides the engine; docker is auto-detected
# first, then podman. Both pull and save identically for our purposes.
# ---------------------------------------------------------------------------
set -euo pipefail
cd "$(dirname "$0")/.."

OUT="${1:-dist/lab-images-pack}"
PLATFORM=linux/amd64

ENGINE="${CONTAINER_ENGINE:-}"
if [ -z "$ENGINE" ]; then
    if command -v docker >/dev/null 2>&1; then ENGINE=docker
    elif command -v podman >/dev/null 2>&1; then ENGINE=podman
    else echo "Need docker or podman to pull and save images."; exit 1
    fi
fi
echo "==> Engine: $ENGINE (packing for $PLATFORM)"

# Every image the compose file references, plus every base its Dockerfiles
# start from. Bases matter: with registry pulls blocked on the VMs, the
# labs' build fallback can only work if the bases are already local.
IMAGES="$(
    {
        awk '/^[[:space:]]+image:/ {print $2}' docker-compose.yml
        find . -name 'Dockerfile*' -not -path './dist/*' -not -path './.git/*' \
            -exec grep -hE '^FROM' {} + | awk '$2 !~ /\$/ {print $2}'
    } | tr -d '"' | sort -u
)"
[ -n "$IMAGES" ] || { echo "No images found in docker-compose.yml?"; exit 1; }
echo "$IMAGES" | sed 's/^/    /'

mkdir -p "$OUT"

pull_and_save() {
    local ref="$1"
    local file
    file="$(printf '%s' "$ref" | tr '/:' '__').tar"
    echo "==> Pulling $ref"
    "$ENGINE" pull --platform "$PLATFORM" "$ref"
    echo "==> Saving  $OUT/$file"
    "$ENGINE" save -o "$OUT/$file" "$ref"
}

while IFS= read -r ref; do
    [ -n "$ref" ] && pull_and_save "$ref"
done <<EOF
$IMAGES
EOF

echo "==> Writing manifest ..."
( cd "$OUT" && sha256sum *.tar > manifest.sha256 )

cp scripts/provision-image-store.sh "$OUT"/

cat > "$OUT/README-IT.txt" <<'EOF'
ASSUME BREACH LABS - OFFLINE IMAGE PACK
=======================================
What this is: every container image the ISYS2012 labs use, for linux/amd64.
Why: lab VMs have registry pulls blocked by policy (/etc/containers/policy.json),
and a class start must not depend on 100+ simultaneous registry pulls anyway.
Nothing in this pack touches the network after it is built.

Install - one command on the golden image, as root:

    sudo ./provision-image-store.sh /path/to/this-folder

That verifies manifest.sha256, loads the images into a read-only Podman store
under /opt/, and registers the store in /etc/containers/storage.conf as an
additionalimagestore. Every (rootless) Podman user on machines running the
image then sees the images directly: no per-user load, no pull, nothing.

Verify afterwards, from a normal user account:

    podman images                       # the pack's images should be listed
    cd <extracted labs folder> && bash start.sh

Removing the pack later:
    rm -rf /opt/<store>-images   and drop its entry from additionalimagestores
    in /etc/containers/storage.conf.
EOF

echo
echo "Pack ready: $OUT"
du -sh "$OUT"
echo "Hand the whole folder to IT (or into the golden image build) with README-IT.txt."
