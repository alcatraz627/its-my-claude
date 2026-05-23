#!/usr/bin/env bash
# resolve-claude-path.sh — resolve a path relative to the correct .claude/ dir.
#
# Prevents the ".claude/.claude/" double-nesting bug when CWD is ~/.claude itself.
# Source this file, then call resolve_claude_path with a relative path.
#
# Usage:
#   source ~/.claude/skills/shared/resolve-claude-path.sh
#   TARGET=$(resolve_claude_path "wal.jsonl")        # → ./.claude/wal.jsonl or ~/.claude/wal.jsonl
#   TARGET=$(resolve_claude_path "scratchpad/plan")   # → ./.claude/scratchpad/plan or ~/.claude/scratchpad/plan
#
# Resolution order:
#   1. If the path is already absolute (starts with /), return as-is
#   2. If CWD is ~/.claude (or any .claude dir), return $HOME/.claude/<path>
#   3. If CWD has a .claude/ subdirectory, return ./.claude/<path>
#   4. Fallback: return $HOME/.claude/<path>
#
# Environment:
#   CLAUDE_CONFIG_DIR — override the global config dir (default: $HOME/.claude)

CLAUDE_CONFIG_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

resolve_claude_path() {
    local rel="$1"

    # Absolute paths pass through untouched
    if [[ "$rel" == /* ]]; then
        echo "$rel"
        return
    fi

    # Detect if CWD is already a .claude dir (prevents double-nesting)
    local cwd_real
    cwd_real=$(cd "$PWD" 2>/dev/null && pwd -P || echo "$PWD")
    if [[ "$(basename "$cwd_real")" == ".claude" ]]; then
        echo "$CLAUDE_CONFIG_DIR/$rel"
        return
    fi

    # Project-local .claude/ exists — use it
    if [[ -d "./.claude" ]]; then
        echo "./.claude/$rel"
        return
    fi

    # Fallback to global
    echo "$CLAUDE_CONFIG_DIR/$rel"
}
