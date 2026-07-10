#!/usr/bin/env bash
# Assume Breach Labs — one command to enter the lab. Hides Docker; drops you into
# an immersive security-workstation console. Optionally pass your name:
#   ./start.sh
#   ./start.sh "Alex Chen"
# Choose a different module with LAB_MODULE (default 07):
#   LAB_MODULE=07 ./start.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/scripts/lab-console" "$@"
