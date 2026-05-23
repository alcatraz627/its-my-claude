#!/usr/bin/env bash
# depth-runner.sh — orchestrate the thorough-depth multipass discovery flow.
#
# Usage:
#   depth-runner.sh discover <source-spec>
#   depth-runner.sh chunk
#   depth-runner.sh slice <range> [--include-worktree]
#   depth-runner.sh verify-coverage
#   depth-runner.sh normalize <dir>
#
# This script handles the DETERMINISTIC phases. LLM phases (inventory / themes /
# verify / incorporate / synthesize) are dispatched by the calling skill via
# the Agent tool with prompts from phases/*.md.

set -euo pipefail
SKILL_DIR=~/.claude/skills/summarize-changes/depth-thorough
SCRIPTS="$SKILL_DIR/scripts"

cmd="${1:-}"; shift || true

case "$cmd" in
  discover)
    bash "$SCRIPTS/resolve-source.sh" "$@"
    python3 "$SCRIPTS/apply-filters.py"
    ;;
  chunk)
    python3 "$SCRIPTS/chunk-files.py"
    ;;
  slice)
    bash "$SCRIPTS/slice-diffs.sh" "$@"
    ;;
  verify-coverage)
    python3 "$SCRIPTS/verify-coverage.py" inventory 04-chunks.json
    ;;
  normalize)
    python3 "$SCRIPTS/normalize-inventory.py" "${1:-inventory/}"
    ;;
  full)
    # full deterministic prep — leaves you ready to dispatch inventory sub-agents
    bash "$0" discover "$@"
    bash "$0" chunk
    # caller passes the range as first arg; we need to pluck it out from "$@"
    # for slice-diffs we want the range + --include-worktree if it was set.
    # In v1 the caller is expected to invoke `slice` separately with the resolved range.
    echo ""
    echo "Deterministic prep done. Next steps:"
    echo "  1. depth-runner.sh slice <range> [--include-worktree]"
    echo "  2. dispatch inventory sub-agents (one per chunk in 04-chunks.json)"
    echo "  3. depth-runner.sh normalize inventory/"
    echo "  4. depth-runner.sh verify-coverage"
    echo "  5. dispatch themes / verify / incorporate / synthesize"
    ;;
  *)
    echo "Usage: depth-runner.sh {discover|chunk|slice|verify-coverage|normalize|full}" >&2
    exit 2
    ;;
esac
