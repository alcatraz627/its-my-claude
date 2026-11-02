#!/usr/bin/env bash
# credential-ask-stop.sh: Stop hook: no asking the owner to mint a credential
# the machine already holds.
#
# The owner, 2026-09-08, after a third lane in a week told him to generate a
# token: "I keep minting tokens lmao what the fuck". The tool that needed it
# (`gh`) already carried the scope; the consumer's variable was simply unset.
# Atone slug asked-owner-for-a-value-already-derivable, recurrence 2, and the
# precheck on file: before asking for a credential, run the tool's own auth
# status and grep the consumer's config for the variable name it reads.
#
# So a final message that tells the owner to mint, generate, create or rotate a
# token, key, secret or credential is blocked ONCE unless this turn ran an auth
# check first (gh auth, printenv/env, a TOKEN grep, a .npmrc or keychain read).
# Loop-safe: stop_hook_active steps aside, and a message is blocked once.
# Mute: touch ~/.claude/.no-credential-ask-gate  (machine-wide until removed)
# Advice for a person reading the reply: see hook_should_run.
. "$HOME/.claude/scripts/hooks/hook-common.sh" 2>/dev/null && { hook_should_run owner-turn || exit 0; }

set -uo pipefail
[ -f "$HOME/.claude/.no-credential-ask-gate" ] && exit 0
input=$(cat 2>/dev/null) || exit 0
command -v jq >/dev/null 2>&1 || exit 0
[ "$(printf '%s' "$input" | jq -r '.stop_hook_active // false')" = "true" ] && exit 0
tp=$(printf '%s' "$input" | jq -r '.transcript_path // empty'); sid=$(printf '%s' "$input" | jq -r '.session_id // empty')
[ -n "$tp" ] && [ -f "$tp" ] || exit 0

# The shared reader sits beside this hook when HOME has no copy (a test home).
type hook_last_assistant_text >/dev/null 2>&1 || . "$(dirname "$0")/hook-common.sh" 2>/dev/null || exit 0
# The reply comes from the Stop input (the transcript lags one message at Stop
# time, see hook_last_assistant_text). Every command this turn has run since the
# last real prompt still comes from the transcript.
text=$(hook_last_assistant_text "$input" "$tp")
[ -n "$text" ] || exit 0
cmds=$(tail -n 400 "$tp" | python3 -c '
import json, sys
recs = [json.loads(l) for l in sys.stdin if l.strip()]
start = 0
for i in range(len(recs) - 1, -1, -1):
    r = recs[i]
    c = (r.get("message") or {}).get("content")
    if r.get("type") == "user" and (isinstance(c, str) or (isinstance(c, list) and any(b.get("type") == "text" for b in c if isinstance(b, dict)))):
        start = i; break
cmds = []
for r in recs[start:]:
    if r.get("type") != "assistant": continue
    for b in (r.get("message") or {}).get("content", []):
        if b.get("type") == "tool_use":
            inp = b.get("input") or {}
            cmds.append(str(inp.get("command", "")) + " " + str(inp.get("file_path", "")))
print("\n".join(cmds))
' 2>/dev/null)
lower=$(printf '%s' "$text" | tr 'A-Z' 'a-z')
printf '%s' "$lower" | rg -q '(mint|generate|create|rotate|issue)( a| an| the| another| new| fresh)*( new| fresh| personal| access| api| github| classic| fine-grained)* ?(token|pat\b|api key|secret|credential)|personal access token|tokens \(classic\)' || exit 0
# An auth check this turn clears it.
printf '%s' "$cmds" | rg -qi 'gh auth|printenv|\benv\b|token|_authtoken|npmrc|security find|keychain|credential' && exit 0
h=$(printf '%s' "$text" | shasum | cut -c1-12)
STATE="/tmp/claude-credask-${sid:0:8}"
[ "$(cat "$STATE" 2>/dev/null)" = "$h" ] && exit 0
printf '%s' "$h" > "$STATE"
bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook credential-ask --action block --heeded unknown >/dev/null 2>&1 || true
jq -cn --arg r 'You are about to ask the owner to mint or generate a token, key or credential, and this turn ran no auth check. He has minted the same token three times this week for values the machine already held (atone asked-owner-for-a-value-already-derivable). Before asking: run the tool'"'"'s own auth status (gh auth status, gh auth token), printenv the variable the consumer reads, and grep its config (.npmrc, .env, keychain) for that name. If the scope exists and only the name is unset, the fix is one export line, not a mint. Then send the reply. This blocks once per message; mute: touch ~/.claude/.no-credential-ask-gate' '{decision:"block", reason:$r}'
