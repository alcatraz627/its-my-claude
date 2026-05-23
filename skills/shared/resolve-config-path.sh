#!/usr/bin/env bash
# resolve-config-path.sh — resolve a config path relative to i-dream data dir.
#
# Usage:
#   source ~/.claude/skills/shared/resolve-config-path.sh
#   resolve_config_path "state.json"   # sets $RESOLVED_PATH
#   echo "$RESOLVED_PATH"              # ~/.claude/subconscious/state.json
#
# Environment:
#   IDREAM_DATA_DIR  — override the base directory (default: ~/.claude/subconscious)
#
# The function echoes the resolved path AND sets $RESOLVED_PATH for callers
# that prefer variable access over command substitution.

IDREAM_DATA_DIR="${IDREAM_DATA_DIR:-$HOME/.claude/subconscious}"

resolve_config_path() {
    local rel="$1"
    if [[ "$rel" == /* ]]; then
        RESOLVED_PATH="$rel"
    else
        RESOLVED_PATH="$IDREAM_DATA_DIR/$rel"
    fi
    echo "$RESOLVED_PATH"
}
