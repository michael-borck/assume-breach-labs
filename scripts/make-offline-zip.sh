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

# Images for the chosen profile, plus the base images ITS OWN Dockerfiles
# build from (the build fallback on the VMs needs them local). Scoping bases
# to the module's Dockerfiles keeps a module-01 zip from carrying module-06's
# wireshark: with `all` we still scan the whole repo.
CFG_JSON="$("$ENGINE" compose --profile "module-$MODULE" config --format json 2>/dev/null || true)"
if [ -n "$CFG_JSON" ]; then
    LINES="$(printf '%s' "$CFG_JSON" | python3 -c '
import json, sys
cfg = json.load(sys.stdin)
for svc in cfg.get("services", {}).values():
    if svc.get("image"):
        print("IMG\t" + svc["image"])
    b = svc.get("build") or {}
    if isinstance(b, dict) and b.get("dockerfile"):
        # dockerfile paths are relative to the service build CONTEXT
        ctx = (b.get("context") or ".").rstrip("/")
        print("DF\t" + ctx + "/" + b["dockerfile"])
')"
    IMAGES="$(printf '%s\n' "$LINES" | awk -F'\t' '$1=="IMG" {print $2}')"
    DOCKERFILES="$(printf '%s\n' "$LINES" | awk -F'\t' '$1=="DF" {print $2}')"
else
    echo "==> (compose config unavailable; falling back to grep — check the list)"
    IMAGES="$(awk '/^[[:space:]]+image:/ {print $2}' docker-compose.yml | tr -d '"')"
fi
if [ "$MODULE" = "all" ] || [ -z "${DOCKERFILES:-}" ]; then
    BASES="$(find . -name 'Dockerfile*' -not -path './dist/*' -not -path './.git/*' \
        -exec grep -hE '^FROM' {} + | awk '$2 !~ /\$/ {print $2}' | tr -d '"')"
else
    BASES="$(while IFS= read -r df; do
                 if [ -f "$df" ]; then
                     grep -hE '^FROM' "$df" || true
                 fi
             done <<< "$DOCKERFILES" | awk '$2 !~ /\$/ {print $2}' | tr -d '"')"
fi
IMAGES="$( { printf '%s\n%s\n' "${IMAGES:-}" "${BASES:-}"; } | sort -u )"
[ -n "$IMAGES" ] || { echo "No images found for module $MODULE?"; exit 1; }
echo "$IMAGES" | sed 's/^/    /'

# A pack full of arm64 images would load fine on the amd64 VMs and then
# refuse to run, so verify rather than trust --platform.
verify_arch() {
    local arch
    arch="$("$ENGINE" image inspect "$1" --format '{{.Architecture}}')"
    if [ "$arch" != "amd64" ]; then
        # A stale local tag (often an arm64 image built on this Mac) shadows
        # the registry's amd64 content, and pull-by-tag then says "up to
        # date" without fetching. Drop it and pull genuinely, once.
        "$ENGINE" image rm "$1" >/dev/null 2>&1 || true
        "$ENGINE" pull --platform "$PLATFORM" "$1" >/dev/null
        arch="$("$ENGINE" image inspect "$1" --format '{{.Architecture}}')"
    fi
    [ "$arch" = "amd64" ] \
        || { echo "!! $1 is '$arch', not amd64. Refusing to pack."; exit 1; }
}

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
    "$ENGINE" pull --platform "$PLATFORM" "$ref" >/dev/null \
        || { echo "!! pull failed: $ref"; exit 1; }
    # Docker's containerd store keeps the whole multi-arch index under the
    # tag and `image inspect` reports its PRIMARY (often arm64) architecture,
    # so for docker `save --platform` is the arch check; inspect is for podman.
    if [ "$ENGINE" = "docker" ]; then
        "$ENGINE" save --platform "$PLATFORM" -o "$ROOT/images/$file" "$ref" \
            || { echo "!! $ref: no usable $PLATFORM content. Refusing to pack."; exit 1; }
    else
        verify_arch "$ref"
        "$ENGINE" save -o "$ROOT/images/$file" "$ref"
    fi
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
