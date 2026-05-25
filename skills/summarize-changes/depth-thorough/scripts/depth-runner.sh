#!/usr/bin/env bash
# depth-runner.sh — orchestrate the thorough-depth multipass discovery flow.
#
# Usage:
#   depth-runner.sh discover <source-spec>
#   depth-runner.sh chunk
#   depth-runner.sh slice <range> [--include-worktree]
#   depth-runner.sh select-chunks <all|N|range>   # W3: prints chunk IDs to inventory
#   depth-runner.sh verify-coverage
#   depth-runner.sh normalize <dir>
#   depth-runner.sh progress "<phase>" "<note>"   # W7: append to _progress.log
#
# This script handles the DETERMINISTIC phases. LLM phases (inventory / themes /
# verify / incorporate / synthesize) are dispatched by the calling skill via
# the Agent tool with prompts from phases/*.md.
#
# DISPATCH NOTE: inventory sub-agents MUST be dispatched as `general-purpose`,
# not `Explore` (Explore hallucinates write-refusals — see phases/inventory.md).

set -euo pipefail
SKILL_DIR=~/.claude/skills/summarize-changes/depth-thorough
SCRIPTS="$SKILL_DIR/scripts"

progress() {
  # W7: append a timestamped line to _progress.log in CWD
  printf '%s  %-14s %s\n' "$(date -u +%H:%M:%S)" "$1" "${2:-}" >> _progress.log
}

cmd="${1:-}"; shift || true

case "$cmd" in
  discover)
    progress "discover" "start: $*"
    bash "$SCRIPTS/resolve-source.sh" "$@"
    python3 "$SCRIPTS/apply-filters.py"
    progress "discover" "done"
    ;;
  chunk)
    progress "chunk" "start"
    python3 "$SCRIPTS/chunk-files.py" "$@"
    progress "chunk" "done"
    ;;
  slice)
    progress "slice" "start"
    bash "$SCRIPTS/slice-diffs.sh" "$@"
    progress "slice" "done"
    ;;
  select-chunks)
    # W3: resolve a chunk-selection spec (all | N | range like 1-10,15,20-25)
    spec="${1:-all}"
    python3 - "$spec" <<'PY'
import json, sys
spec = sys.argv[1]
with open("04-chunks.json") as f: chunks = json.load(f)
# Skip binary-summary chunks from inventory dispatch (they're a count, not files).
inv = [c for c in chunks if not c.get("binary_summary")]
def parse(spec, n):
    if spec == "all": return list(range(1, n+1))
    out = set()
    for part in spec.split(","):
        if "-" in part:
            a, b = part.split("-"); out.update(range(int(a), int(b)+1))
        else:
            out.add(int(part))
    return sorted(i for i in out if 1 <= i <= n)
if spec.isdigit():
    idxs = list(range(1, min(int(spec), len(inv))+1))
else:
    idxs = parse(spec, len(inv))
for i in idxs:
    c = inv[i-1]
    print(f"{c['id']}\t{len(c['files'])}\t{c['total_bytes']//1024}")
PY
    ;;
  verify-coverage)
    python3 "$SCRIPTS/verify-coverage.py" inventory 04-chunks.json
    progress "verify-coverage" "done"
    ;;
  normalize)
    python3 "$SCRIPTS/normalize-inventory.py" "${1:-inventory/}"
    progress "normalize" "done"
    ;;
  validate-shas)
    # W6: replace any theme SHA not in commits.tsv with (post-cutoff)
    python3 "$SCRIPTS/validate-shas.py" "${1:-themes/THEMES.md}" "${2:-01-commits.tsv}"
    ;;
  progress)
    progress "$1" "${2:-}"
    ;;
  full)
    bash "$0" discover "$@"
    bash "$0" chunk
    echo ""
    echo "Deterministic prep done. Next steps:"
    echo "  1. depth-runner.sh slice <range> [--include-worktree]"
    echo "  2. depth-runner.sh select-chunks <all|N|range>   # which chunks to inventory"
    echo "  3. dispatch inventory sub-agents as GENERAL-PURPOSE (one per selected chunk)"
    echo "  4. depth-runner.sh normalize inventory/"
    echo "  5. depth-runner.sh verify-coverage"
    echo "  6. dispatch themes; then depth-runner.sh validate-shas; then verify / incorporate / synthesize"
    ;;
  *)
    echo "Usage: depth-runner.sh {discover|chunk|slice|select-chunks|verify-coverage|normalize|validate-shas|progress|full}" >&2
    exit 2
    ;;
esac
