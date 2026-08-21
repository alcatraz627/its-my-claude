#!/usr/bin/env bash
# bare-id-cluster-stop.sh — Stop hook: catch a run of bare task ids in prose,
# where the owner needed words.
#
# THE FAILURE. Asked "show me what is pending on me", an agent replies with
# "#59 #91 #39 #153 #130 #89" and four hundred words of bold-headed prose. Every
# fact correct, read from the store rather than memory, and completely unusable:
# an id is a lookup key, and the person reading has to open a file to learn what
# any of them is. Twice on 2026-08-20, by two different sessions, an hour apart:
# mist-20260819-222026-2a (gcc-work, 13th) and mist-20260820-092606-29
# (automation, 16th and the second in one session). Both S3, both juror
# very-wrong. The slug is dense-briefing-instead-of-a-direct-answer and it is the
# account's top recency blind spot.
#
# WHY A GATE AND NOT ANOTHER NUDGE. It has a hinter. The hinter was injected into
# automation's SessionStart briefing THAT SESSION, annotated "still recurring
# despite this reminder, this is a blind spot, slow down", and they committed it
# anyway. Sixteen occurrences is not a nudge problem. Owner ruled a gate on
# 2026-08-20.
#
# WHAT IT DOES NOT SAY. An earlier draft of this advice routed the agent to
# /decision-wizard. The owner HELD that on 2026-08-20: "I'm not sure about
# spamming decision pages every time I want a status update." So the remedy here
# is the gloss rule itself, which is what the owner actually asked for on
# 2026-08-15: every task number carries enough words that an out-of-context
# reader can follow, AND CHAT PROSE OBEYS THE SAME RULE.
#
# WARN, NOT BLOCK, per ruling D2a: every new gate ships warn-tier and is promoted
# on evidence. The trigger is a text shape and this account legitimately discusses
# ids while BUILDING id-rendering tools, this file's own provenance included.
#
# Code fences are stripped first, so a rendered /tasks table is never the trigger:
# its "done (98): #1 #2 #3 …" line is a deliberate, ruled collapse inside a block
# the reader can see is a table. The defect is a cluster loose in PROSE.
#
# Mute: touch ~/.claude/.no-bare-id-gate (machine-wide until removed).

set -uo pipefail
[ -f "$HOME/.claude/.no-bare-id-gate" ] && exit 0

input=$(cat 2>/dev/null) || exit 0
command -v jq >/dev/null 2>&1 || exit 0
command -v rg >/dev/null 2>&1 || exit 0

HOOK_COMMON="$HOME/.claude/scripts/hooks/hook-common.sh"
[ -r "$HOOK_COMMON" ] || exit 0
. "$HOOK_COMMON"

sid=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)
tp=$(printf '%s' "$input" | jq -r '.transcript_path // empty' 2>/dev/null)
[ -n "$sid" ] && [ -n "$tp" ] && [ -f "$tp" ] || exit 0
sid8=$(hook_sid8 "$sid")

# The final assistant message, fences and inline code removed.
prose=$(python3 - "$tp" <<'PY' 2>/dev/null
import json, re, sys
last = ""
for line in open(sys.argv[1], errors="replace"):
    try: d = json.loads(line)
    except Exception: continue
    if d.get("type") != "assistant": continue
    c = (d.get("message") or {}).get("content") or []
    t = "".join(b.get("text", "") for b in c if isinstance(b, dict) and b.get("type") == "text")
    if t.strip(): last = t
# A rendered table lives in a fence and its id collapse is ruled, not a defect.
# Backticks cannot appear literally here: this python lives inside a $(...)
# command substitution, where bash still treats a backtick as an open-quote even
# through a quoted heredoc. The file failed to parse at all until this was
# rewritten with chr(96), and `bash -n` is the check that catches it.
bt = chr(96)
last = re.sub(bt * 3 + ".*?" + bt * 3, " ", last, flags=re.S)
last = re.sub(bt + "[^" + bt + "]*" + bt, " ", last)
print(last)
PY
)
[ -n "${prose//[[:space:]]/}" ] || exit 0

# A CLUSTER: three or more id-shaped tokens with nothing but separators between
# them. One id followed by its subject is fine and is what the gloss rule asks
# for; three in a row cannot be carrying subjects.
hit=$(printf '%s\n' "$prose" | rg -o \
  '(#[0-9]{1,4}|\bD[0-9]{1,2}\b)([ ,·/]+(#[0-9]{1,4}|\bD[0-9]{1,2}\b)){2,}' 2>/dev/null | head -3)

MARK="/tmp/claude-bareid-${sid8}"
if [ -z "$hit" ]; then
  if [ -f "$MARK" ]; then
    bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook bare-id-cluster \
      --heed-of "bare-id:$sid8" --heeded true >/dev/null 2>&1 || true
    rm -f "$MARK" 2>/dev/null || true
  fi
  exit 0
fi

if ! hook_loop_check "$MARK" "$prose"; then
  bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook bare-id-cluster \
    --heed-of "bare-id:$sid8" --heeded false >/dev/null 2>&1 || true
  exit 0
fi

msg="⚠ bare id cluster in prose — a run of ids with no subjects, where the reader needs words.

In the final message:
$hit

An id is a lookup key, not information: the reader has to open a file to learn what any of these is. The owner's rule, 2026-08-15: every task number, proposal id or disposition code carries a gloss so an out-of-context reader can follow, AND CHAT PROSE OBEYS THE SAME RULE.

Give each one its subject in the sentence, or render the actual table (a fenced table is never flagged, its id collapse is the ruled shape). Do NOT reach for a decision page to dodge this: the owner held that idea on 2026-08-20 for status updates.

Slug dense-briefing-instead-of-a-direct-answer, 16x S3, two of them on 2026-08-20 by different sessions. Mute: touch ~/.claude/.no-bare-id-gate"

bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook bare-id-cluster --action nudge \
  --heeded unknown >/dev/null 2>&1 || true
jq -cn --arg m "$msg" '{systemMessage:$m}' 2>/dev/null || true
exit 0
