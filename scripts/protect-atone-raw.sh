#!/usr/bin/env bash
# protect-atone-raw.sh — PreToolUse hook.
#
# Blocks modifications to ~/.claude/atone/events.jsonl and
# ~/.claude/atone/rca/*.md unless invoked via a whitelisted atone script.
#
# Matchers (configured in settings.json): Bash | Edit | Write | MultiEdit
#
# Strategy:
#   - For Edit/Write/MultiEdit: deny outright if file_path touches raw paths.
#   - For Bash: parse command string. Block destructive operations against raw
#     paths (rm, mv into, > truncate, chflags clear, truncate, dd of=, etc).
#     Read-only operations (cat, head, tail, grep, jq, wc, ls, du, git log,
#     git diff, git show) are always allowed.
#     Whitelisted scripts can do anything.
#
# Exit codes:
#   0 — allow
#   2 — block (Claude Code prints stderr to user)

set -uo pipefail

INPUT=$(cat)

# Defensive: if jq missing or input not JSON, fail open (don't block valid work).
command -v jq >/dev/null 2>&1 || exit 0
echo "$INPUT" | jq empty 2>/dev/null || exit 0

TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')

# Protected path regex (note: $ delimited to avoid matching events.jsonl.draft)
RAW_FILE='atone/(events|judgments)\.jsonl(\.lock)?'
RAW_RCA='atone/rca/'

case "$TOOL" in
  Edit|Write|MultiEdit|NotebookEdit)
    FP=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
    # Block if path matches raw file OR rca dir, but NOT events.jsonl.draft
    if [[ "$FP" == *atone/events.jsonl ]] || \
       [[ "$FP" == *atone/events.jsonl.lock ]] || \
       [[ "$FP" == *atone/judgments.jsonl ]] || \
       [[ "$FP" == *atone/judgments.jsonl.lock ]] || \
       [[ "$FP" == *atone/rca/*.md ]]; then
      cat >&2 <<EOF
[protect-atone-raw] BLOCKED — $TOOL targets raw atone path
  path:   $FP
  reason: raw atone data is append-only

Use the CLI for any modification:
  bash ~/.claude/scripts/atone.sh add ...
Migration draft (events.jsonl.draft) is writable via Edit/Write — that's by design.
Escape hatch (phrase-gated): bash ~/.claude/scripts/atone-unsafe-unlock.sh
EOF
      exit 2
    fi
    exit 0
    ;;
  Bash)
    CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

    # Empty command — allow
    [ -z "$CMD" ] && exit 0

    # If command doesn't mention any raw path, allow
    if ! echo "$CMD" | grep -qE 'atone/(events|judgments)\.jsonl|atone/rca/'; then
      exit 0
    fi

    # Whitelist: if it's an atone-suite script, allow
    if echo "$CMD" | grep -qE '(^|[[:space:]]|;|&&|\|\|)bash[[:space:]]+(~|/Users/[^/]+|\$HOME)/\.claude/scripts/atone(\.sh|-[a-z-]+\.sh)'; then
      exit 0
    fi
    # Whitelist: invocation without explicit `bash` (e.g., direct exec)
    if echo "$CMD" | grep -qE '(^|[[:space:]]|;|&&|\|\|)(~|/Users/[^/]+|\$HOME)/\.claude/scripts/atone(\.sh|-[a-z-]+\.sh)([[:space:]]|$)'; then
      exit 0
    fi

    # Check if ONLY references the .draft variant (not the protected file)
    # Strip .draft references and re-check
    STRIPPED=$(echo "$CMD" | sed 's|atone/events\.jsonl\.draft|<DRAFT>|g; s|atone/judgments\.jsonl\.draft|<DRAFT>|g')
    if ! echo "$STRIPPED" | grep -qE 'atone/(events|judgments)\.jsonl|atone/rca/'; then
      # Only .draft mentioned — allow
      exit 0
    fi

    # Read-only operations: allow if command leads with a read-only tool
    # AND has no shell-redirection that could write to a raw path.
    # echo/printf/test/[ are explicitly safe leaders (used to summarize state
    # via $(read-only-cmd) substitutions).
    if echo "$CMD" | grep -qE '^[[:space:]]*(echo|printf|test|\[|cat|head|tail|less|more|grep|rg|jq|wc|ls|du|file|stat|find|git[[:space:]]+(log|diff|show|status|cat-file|ls-files))[[:space:]]'; then
      # Ensure no write redirection AGAINST a raw path. We allow >/tmp,
      # >/dev/null, etc., but block "> ~/.claude/atone/events.jsonl".
      if ! echo "$CMD" | grep -qE '(>|>>)[[:space:]]*[^>][^|]*atone/(events\.jsonl|judgments\.jsonl|rca/)|\|[[:space:]]*tee[[:space:]]+[^|]*atone/(events\.jsonl|judgments\.jsonl|rca/)|\bchflags\b|\bchmod\b'; then
        exit 0
      fi
    fi

    # Otherwise — block
    cat >&2 <<EOF
[protect-atone-raw] BLOCKED — Bash command targets raw atone path
  reason: raw atone data is append-only; modifications must go through atone.sh

Use the CLI for any modification:
  bash ~/.claude/scripts/atone.sh add ...
  bash ~/.claude/scripts/atone.sh list | search | show | slugs

Read-only inspection allowed: cat, head, tail, less, grep, rg, jq, wc, ls, du,
  git log, git diff, git show, git status.

Escape hatch (phrase-gated): bash ~/.claude/scripts/atone-unsafe-unlock.sh
EOF
    exit 2
    ;;
  *)
    # Not a tool we filter — allow
    exit 0
    ;;
esac
