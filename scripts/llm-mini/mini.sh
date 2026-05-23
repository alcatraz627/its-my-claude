#!/usr/bin/env bash
# mini — DEPRECATED: renamed to llm-mini (2026-04-24).
# This shim forwards all calls. Update your scripts to use 'llm-mini'.

echo "mini: renamed to 'llm-mini'. Please update your usage." >&2
exec bash "${HOME}/.claude/scripts/llm-mini/llm-mini-core.sh" "$@"
