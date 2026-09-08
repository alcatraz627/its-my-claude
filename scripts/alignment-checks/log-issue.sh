#!/usr/bin/env bash
# Record one friction with an alignment tool (/tasks, /goal, kanban, task.sh,
# decision pages, callouts, /catchup, /core-dump, the warden) to the append-only
# ledger at ~/.claude/logs/alignment-issues.jsonl. Any session appends; nothing
# edits. The owner reads the ledger to see what the alignment pass missed.
#
# Usage:
#   log-issue.sh --tool <tasks|goal|kanban|task.sh|decision-page|callouts|catchup|core-dump|warden|other> \
#                --issue "<what went wrong, one sentence>" \
#               [--context-had "<what the tool or agent demonstrably knew and ignored>"] \
#               [--cost "<what it cost the owner: a re-ask, a wrong report, a halt>"] \
#               [--evidence "<file:line, transcript turn, log line, message id>"]
#
# Each line: {"ts","session","alias","cwd","tool","issue","context_had","cost","evidence"}.
# Exit 2 on missing --tool or --issue. The ledger file is created on first write.
set -euo pipefail
LEDGER="$HOME/.claude/logs/alignment-issues.jsonl"
tool=""; issue=""; context_had=""; cost=""; evidence=""
while [ $# -gt 0 ]; do case "$1" in
  --tool) tool="${2:-}"; shift 2;;
  --issue) issue="${2:-}"; shift 2;;
  --context-had) context_had="${2:-}"; shift 2;;
  --cost) cost="${2:-}"; shift 2;;
  --evidence) evidence="${2:-}"; shift 2;;
  -h|--help) sed -n '2,15p' "$0"; exit 0;;
  *) echo "log-issue.sh: unknown flag $1" >&2; sed -n '2,15p' "$0" >&2; exit 2;;
esac; done
[ -n "$tool" ] && [ -n "$issue" ] || { echo "log-issue.sh: --tool and --issue are required" >&2; exit 2; }
mkdir -p "$(dirname "$LEDGER")"
sid="${CLAUDE_CODE_SESSION_ID:-}"
# The friendly alias from the ipc roster, keyed on the session id; the first 39
# entries carried the ipc help text after a lookup verb that did not exist.
alias_name="${CLAUDE_IPC_ALIAS:-}"
if [ -z "$alias_name" ] && [ -n "$sid" ] && command -v claude-ipc >/dev/null 2>&1; then
  alias_name=$(claude-ipc peers 2>/dev/null | jq -r --arg s "$sid" '[.peers[]? | select(.sessionId==$s) | .alias] | .[0] // empty' 2>/dev/null)
fi
jq -cn --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg session "${sid:0:8}" --arg alias "$alias_name" \
  --arg cwd "$PWD" --arg tool "$tool" --arg issue "$issue" --arg context_had "$context_had" \
  --arg cost "$cost" --arg evidence "$evidence" \
  '{ts:$ts,session:$session,alias:$alias,cwd:$cwd,tool:$tool,issue:$issue,context_had:$context_had,cost:$cost,evidence:$evidence}' >> "$LEDGER"
echo "logged to $LEDGER ($(wc -l < "$LEDGER" | tr -d ' ') lines)"
