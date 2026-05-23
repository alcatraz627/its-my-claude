#!/usr/bin/env bash
# tab-title/hooks/raw-guard.sh — PreToolUse hook (Bash matcher).
#
# Intercepts `tab-title.sh raw -y …` calls and prompts the user for
# permission with the title + reason rendered inline. Lets every other
# Bash command pass through with no output.
#
# Hook contract: emit JSON `{"decision":"ask","reason":"..."}` to stdout to
# trigger a user prompt; emit nothing to allow.

set -uo pipefail
command -v jq &>/dev/null || exit 0

input=$(cat)
cmd=$(echo "$input" | jq -r '.tool_input.command // empty')
[[ -n "$cmd" ]] || exit 0

# Cheap pattern: must mention tab-title.sh, the `raw` subcommand, AND -y/--yes.
# (Without -y the script itself dissuades; no hook intervention needed.)
case "$cmd" in
  *tab-title.sh*raw*) ;;
  *) exit 0 ;;
esac
case "$cmd" in
  *' -y '*|*' --yes '*|*' -y'|*' --yes') ;;
  *) exit 0 ;;
esac

# Best-effort extraction of the literal title arg (the last positional)
# and the --reason flag. Falls back to the raw command line if parsing fails.
reason=$(printf '%s' "$cmd" | sed -nE 's/.*--reason[= ]+"([^"]+)".*/\1/p')
[[ -n "$reason" ]] || reason=$(printf '%s' "$cmd" | sed -nE "s/.*--reason[= ]+'([^']+)'.*/\\1/p")
title=$(printf '%s' "$cmd" | sed -nE 's/.* "([^"]+)"[[:space:]]*$/\1/p')
[[ -n "$title" ]] || title=$(printf '%s' "$cmd" | sed -nE "s/.* '([^']+)'[[:space:]]*$/\\1/p")

# JSON-escape (jq does this cleanly)
payload=$(jq -n \
  --arg title "${title:-<unparsed>}" \
  --arg reason "${reason:-<none provided>}" \
  --arg cmd "$cmd" \
  '{
    decision: "ask",
    reason: ("Claude is requesting RAW tab-title write (bypasses composer).\n\n"
              + "Title:  " + $title + "\n"
              + "Reason: " + $reason + "\n\n"
              + "Approve only if the structured fields (focus/base/set) cannot "
              + "express this. The next Stop hook will overwrite the raw value.\n\n"
              + "Full command:\n  " + $cmd)
  }')
printf '%s\n' "$payload"
