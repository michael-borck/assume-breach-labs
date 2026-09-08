#!/usr/bin/env bash
# ISYS6014 Module 7: set up the Pi agent to use the Ollama models already on
# this machine (qwen3:8b / qwen3:4b from last week's install). Optionally also
# point Pi at the unit's shared server, using the key from the LMS announcement.
# Run once; safe to run again at any time. (macOS / Linux)
set -euo pipefail
mkdir -p "$HOME/.pi/agent"

if ! command -v pi >/dev/null 2>&1; then
  echo "NOTE: Pi is not installed yet. The settings file will still be written."
  echo "  1. Install Node.js LTS from https://nodejs.org (next, next, finish)"
  echo "  2. npm install -g @earendil-works/pi-coding-agent"
  echo "  3. Check with: pi --version"
  echo
fi

if ! command -v ollama >/dev/null 2>&1; then
  echo "NOTE: Ollama is not installed or not running. The local provider will not"
  echo "  respond until you install it (https://ollama.com) and start the app."
  echo "  The shared server (if you paste the key below) works regardless."
  echo
fi

KEY=""
read -r -p "Paste the shared-server key from the LMS announcement (Enter to skip): " KEY || true

REMOTE=""
if [ -n "${KEY}" ]; then
  REMOTE=', "ollama-curtin": { "baseUrl": "https://ollama.locollm.org/v1", "api": "openai-completions", "apiKey": "'"${KEY}"'", "compat": { "supportsDeveloperRole": false, "supportsReasoningEffort": false }, "models": [ { "id": "granite4.2:8b" }, { "id": "granite4.2:3b" }, { "id": "gemma4:e4b" }, { "id": "gemma4:12b" }, { "id": "llama3.1:latest" } ] }'
fi

printf '{\n  "providers": {\n    "ollama": { "baseUrl": "http://localhost:11434/v1", "api": "openai-completions", "apiKey": "ollama", "models": [ { "id": "qwen3:8b" }, { "id": "qwen3:4b" } ] }%s\n  }\n}\n' "$REMOTE" > "$HOME/.pi/agent/models.json"

echo "Done: $HOME/.pi/agent/models.json written."
echo "Make sure Ollama is running (menu-bar icon), then start Pi with:"
echo "  pi --provider ollama --model qwen3:8b"
echo "(If 'ollama list' shows qwen3:4b instead, use that as the model name.)"
[ -n "${KEY}" ] && echo "The shared server is in there too: pi --provider ollama-curtin --model granite4.2:3b"
