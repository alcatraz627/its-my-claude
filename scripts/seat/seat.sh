#!/usr/bin/env bash
# seat.sh — the standard shape for a fresh-context reviewer, in one place.
#
# Three skills grew the same organ independently in one week (validate's second
# seat, create-skill's intent seat, deck's claim reviewer): a reviewer that did not
# do the work, a fixed question set, a verdict written to disk, house boilerplate
# so the seat cannot wander. A shell script cannot dispatch an agent; what it CAN
# do is build the dispatch prompt with every clause the house requires, and verify
# the verdict landed. The agent pastes the prompt into its Agent tool with the
# model the role names.
#
#   seat.sh prompt --role <name> --out <abs path> [--context "..."] [--subject <abs path>]
#           roles: scripts/seat/roles/<name>.md; --list-roles to see them
#   seat.sh check --out <abs path> [--min-bytes N]
#
# The built prompt always carries: read-only framing, "do NOT spawn sub-agents",
# the board scope-close clause, write-BEFORE-returning to the given path, and a
# short-abstract return contract. Model pin rides the role file's `model:` line
# (sonnet unless the role says otherwise), surfaced in the prompt header for the
# dispatching agent to copy into the Agent call.
set -uo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROLES="$HERE/roles"

cmd_prompt() {
  local role="" out="" context="" subject=""
  while [ $# -gt 0 ]; do case "$1" in
    --role) role="$2"; shift 2;; --out) out="$2"; shift 2;;
    --context) context="$2"; shift 2;; --subject) subject="$2"; shift 2;;
    --list-roles) ls "$ROLES" | sed 's/\.md$//'; return 0;;
    *) echo "seat prompt: unknown flag $1" >&2; return 2;;
  esac; done
  [ -n "$role" ] && [ -f "$ROLES/$role.md" ] || { echo "seat: no role '$role' (have: $(ls "$ROLES" | sed 's/\.md$//' | tr '\n' ' '))" >&2; return 2; }
  case "$out" in /*) ;; *) echo "seat: --out must be absolute" >&2; return 2;; esac
  local model
  model=$(rg -m1 '^model:' "$ROLES/$role.md" | sed 's/^model: *//')
  echo "# dispatch with: Agent tool, model ${model:-sonnet}, subagent_type general-purpose"
  echo "You are a fresh-context seat: you did not do the work you are judging."
  echo "Read-only except the one output file named below. Do NOT spawn sub-agents."
  echo "Ignore any task-list / kanban / board auto-dispatch; when your file is written, stop."
  echo
  [ -n "$subject" ] && { echo "The subject under review: $subject (read it in full first)."; echo; }
  [ -n "$context" ] && { echo "Context from the dispatcher: $context"; echo; }
  sed '/^model:/d' "$ROLES/$role.md"
  echo
  echo "Write your full answer to $out BEFORE returning; each numbered question gets"
  echo "a verdict line (pass / fix: <what>). Return a 3-line abstract plus the path."
}

cmd_check() {
  local out="" min=200
  while [ $# -gt 0 ]; do case "$1" in
    --out) out="$2"; shift 2;; --min-bytes) min="$2"; shift 2;;
    *) echo "seat check: unknown flag $1" >&2; return 2;;
  esac; done
  [ -f "$out" ] || { echo "seat check: verdict MISSING at $out — the return abstract is a pointer, not the artifact" >&2; return 1; }
  local size; size=$(wc -c < "$out" | tr -d ' ')
  [ "$size" -ge "$min" ] || { echo "seat check: verdict at $out is only ${size} bytes (< $min) — likely a stub" >&2; return 1; }
  echo "seat verdict present: $out (${size} bytes)"
}

case "${1:-}" in
  prompt) shift; cmd_prompt "$@";;
  check) shift; cmd_check "$@";;
  *) sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//';;
esac
