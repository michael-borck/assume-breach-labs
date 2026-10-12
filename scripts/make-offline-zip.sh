#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Build an OFFLINE STUDENT ZIP: the labs repo plus the container images for one
# module (or all of them), loadable by the student with no root, no network
# and no registry access.
#
#   ./scripts/make-offline-zip.sh <module|all> [out-dir]
#   ./scripts/make-offline-zip.sh 01          # module 01 only (~small, LMS-friendly)
#   ./scripts/make-offline-zip.sh all         # every module (~5 GB, shared drive)
#
# Result: dist/offline/assume-breach-labs-offline-<mod>.zip
#
#   assume-breach-labs/
#   ├── (the whole repo — start.sh, modules, scripts, ...)
#   └── images/
#       ├── *.tar             one per image, linux/amd64
#       └── images.txt        "ref|file" pairs for load-images.sh
#
# On the VM the student unzips and runs `bash start.sh`: the console finds
# images/ and loads what is missing via `podman load` (user-space, bypasses
# registry policy) before starting the lab. Docker users are unaffected — the
# loader is a no-op when the images are already present or the dir is absent.
#
# Needs a live Docker or Podman to pull and save. Per-module zips exist
# because LMS upload/download limits make a single all-modules zip impractical.
# ---------------------------------------------------------------------------
set -euo pipefail
cd "$(dirname "$0")/.."

MODULE="${1:-}"
OUTDIR="${2:-dist/offline}"
PLATFORM=linux/amd64
[ -n "$MODULE" ] || { echo "usage: $0 <module|all> [out-dir]  (e.g. $0 01)"; exit 1; }

ENGINE="${CONTAINER_ENGINE:-}"
if [ -z "$ENGINE" ]; then
    if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then ENGINE=docker
    elif command -v podman >/dev/null 2>&1 && podman info >/dev/null 2>&1; then ENGINE=podman
    else echo "Need a running docker or podman to pull and save images."; exit 1
    fi
fi
echo "==> Engine: $ENGINE (packing for $PLATFORM)"

# Images for the chosen profile, plus every base the Dockerfiles build from
# (the build fallback on the VMs needs them local).
if [ "$MODULE" = "all" ]; then
    IMAGES="$(awk '/^[[:space:]]+image:/ {print $2}' docker-compose.yml | tr -d '"')"
else
    PROBE="$("$ENGINE" compose --profile "module-$MODULE" config --images 2>/dev/null || true)"
    if [ -n "$PROBE" ]; then
        IMAGES="$PROBE"
    else
        echo "==> (compose config unavailable; falling back to grep — check the list)"
        IMAGES="$(awk '/^[[:space:]]+image:/ {print $2}' docker-compose.yml | tr -d '"')"
    fi
fi
BASES="$(find . -name 'Dockerfile*' -not -path './dist/*' -not -path './.git/*' \
    -exec grep -hE '^FROM' {} + | awk '$2 !~ /\$/ {print $2}' | tr -d '"')"
IMAGES="$( { printf '%s\n%s\n' "$IMAGES" "$BASES"; } | sort -u )"
[ -n "$IMAGES" ] || { echo "No images found for module $MODULE?"; exit 1; }
echo "$IMAGES" | sed 's/^/    /'

STAGE="$(mktemp -d /tmp/offline-zip.XXXXXX)"
trap 'rm -rf "$STAGE"' EXIT
ROOT="$STAGE/assume-breach-labs"
mkdir -p "$ROOT/images"

echo "==> Staging the repo ..."
rsync -a --exclude .git --exclude dist --exclude '._*' ./ "$ROOT/"

echo "==> Pulling and saving images ..."
: > "$ROOT/images/images.txt"
while IFS= read -r ref; do
    [ -n "$ref" ] || continue
    file="$(printf '%s' "$ref" | tr '/:' '__').tar"
    "$ENGINE" pull --platform "$PLATFORM" "$ref" >/dev/null
    "$ENGINE" save -o "$ROOT/images/$file" "$ref"
    printf '%s|%s\n' "$ref" "$file" >> "$ROOT/images/images.txt"
    echo "    $ref"
done <<EOF
$IMAGES
EOF
( cd "$ROOT/images" && sha256sum *.tar > manifest.sha256 )

mkdir -p "$OUTDIR"
ZIP="$(cd "$OUTDIR" && pwd)/assume-breach-labs-offline-$MODULE.zip"
echo "==> Writing $ZIP ..."
( cd "$STAGE" && zip -rq "$ZIP" assume-breach-labs )

echo
echo "Offline zip ready: $ZIP"
du -sh "$ZIP"
echo "Upload to the LMS. Students: download, unzip, then 'bash start.sh' —"
echo "the console loads images/ automatically on first run."
