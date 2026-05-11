#!/usr/bin/env bash
# Count Tongula's Toolkit — Power Setup installer.
# Copies the statusline script into the user's ~/.claude/ directory and
# points Claude Code's settings.json at it. Idempotent — safe to re-run
# to pick up script updates.
#
# Usage:
#   bash install.sh --statusline
#
# Intended invocation is via /power-setup:install-statusline, which sets
# CLAUDE_PLUGIN_ROOT for the plugin path. Direct invocation also works:
#   bash plugins/power-setup/scripts/install.sh --statusline

set -euo pipefail

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
DEST_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
SETTINGS="$DEST_DIR/settings.json"

do_statusline=0
for arg in "$@"; do
  case "$arg" in
    --statusline) do_statusline=1 ;;
    *) echo "unknown arg: $arg" >&2; exit 2 ;;
  esac
done

if (( do_statusline == 0 )); then
  echo "nothing to do — pass --statusline" >&2
  exit 2
fi

preflight() {
  local missing=()
  command -v jq  >/dev/null 2>&1 || missing+=("jq")
  command -v git >/dev/null 2>&1 || missing+=("git")
  if (( ${#missing[@]} > 0 )); then
    echo "error: missing dependencies: ${missing[*]}" >&2
    echo "install with: brew install ${missing[*]}" >&2
    exit 1
  fi
}

install_statusline() {
  local src="$PLUGIN_ROOT/statusline/statusline-command.sh"
  local dest="$DEST_DIR/statusline-command.sh"

  if [[ ! -f "$src" ]]; then
    echo "error: statusline source not found at $src" >&2
    exit 1
  fi

  mkdir -p "$DEST_DIR"
  install -m 0755 "$src" "$dest"

  local entry
  entry=$(jq -n --arg cmd "bash $dest" \
    '{type: "command", command: $cmd, padding: 0}')

  if [[ -f "$SETTINGS" ]]; then
    cp "$SETTINGS" "$SETTINGS.bak.$(date +%Y%m%d%H%M%S)"
    local tmp
    tmp=$(mktemp)
    jq --argjson sl "$entry" '.statusLine = $sl' "$SETTINGS" > "$tmp"
    mv "$tmp" "$SETTINGS"
  else
    jq -n --argjson sl "$entry" '{statusLine: $sl}' > "$SETTINGS"
  fi

  local ver
  ver=$(grep -m1 '^# POWER_SETUP_VERSION=' "$dest" | cut -d= -f2 || echo "?")

  echo "✓ statusline installed (v$ver)"
  echo "  script:   $dest"
  echo "  settings: $SETTINGS"
  echo "  source:   $src"
  echo
  echo "The script lives in your ~/.claude/ — edit it freely, it's yours."
  echo "Restart Claude Code (or open a new session) to see it."
}

preflight
(( do_statusline )) && install_statusline
