#!/bin/sh
# Download coordinator-curated, real-world sample captures into /pcaps on demand.
# We link to these rather than redistribute them. Edit /pcaps/.samples.txt (baked
# from samples.txt) to change the list.
set -u
MAN="${1:-/pcaps/.samples.txt}"

if [ ! -f "$MAN" ]; then
    echo "No sample list found at $MAN"; exit 1
fi

echo "Downloading sample captures into /pcaps ..."
count=0
# lines: "<url> | <optional filename>", '#' comments and blanks ignored
grep -vE '^[[:space:]]*(#|$)' "$MAN" | while IFS='|' read -r url name; do
    url=$(printf '%s' "$url" | tr -d '[:space:]')
    name=$(printf '%s' "$name" | tr -d '[:space:]')
    [ -n "$url" ] || continue
    [ -n "$name" ] || name=$(basename "$url")
    if wget -q -O "/pcaps/$name" "$url"; then
        echo "  [ok]      $name"
        count=$((count + 1))
    else
        echo "  [failed]  $url"
        rm -f "/pcaps/$name"
    fi
done
echo "Done. Open the new files in Wireshark from /pcaps."
