#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Load packaged container images (from an offline pack or offline zip) into
# the LOCAL engine store.
#
#   bash scripts/load-images.sh [images-dir] [-q]
#
# Reads <dir>/images.txt (one "ref|file" pair per line), skips refs already
# present, and loads the rest. No root, no network, no registry policy:
# `load` imports a file, so it works on VMs where pulls are blocked entirely.
# Idempotent — safe to run on every start.
# ---------------------------------------------------------------------------
set -euo pipefail
cd "$(dirname "$0")/.."

DIR="images"
QUIET=0
for a in "$@"; do
    case "$a" in
        -q|--quiet) QUIET=1 ;;
        *) DIR="$a" ;;
    esac
done

LIST="$DIR/images.txt"
[ -f "$LIST" ] || { [ "$QUIET" -eq 1 ] || echo "No $LIST — nothing to load."; exit 0; }

ENGINE=""
if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then ENGINE=docker
elif command -v podman >/dev/null 2>&1 && podman info >/dev/null 2>&1; then ENGINE=podman
else echo "Neither a running Docker nor Podman was found."; exit 1
fi

loaded=0
skipped=0
while IFS='|' read -r ref file; do
    [ -n "${ref:-}" ] || continue
    if "$ENGINE" image inspect "$ref" >/dev/null 2>&1; then
        skipped=$((skipped + 1))
        continue
    fi
    [ -f "$DIR/$file" ] || { echo "Missing $DIR/$file (for $ref) — pack incomplete?"; exit 1; }
    # policy.json governs ARCHIVE loads too, not just registry pulls: on
    # machines that allow pulls but not archives (a common policy shape),
    # every load fails with "rejected by policy". That is not an error — the
    # image comes from the registry (or a baked store) instead — so skip it
    # quietly and let compose_up's pull do its job.
    if ! err="$("$ENGINE" load -i "$DIR/$file" 2>&1)"; then
        case "$err" in
            *"rejected by policy"*)
                skipped=$((skipped + 1))
                continue ;;
            *)
                printf '%s\n' "$err" >&2
                echo "!! loading $DIR/$file (for $ref) failed."; exit 1 ;;
        esac
    fi
    loaded=$((loaded + 1))
done < "$LIST"

[ "$QUIET" -eq 1 ] || printf "Images ready: %d loaded, %d skipped (already present or policy-blocked).\n" "$loaded" "$skipped"
