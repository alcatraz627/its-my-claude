#!/usr/bin/env bash
# guard-structural-claim.sh — Stop hook that nudges when the agent's final
# message asserts how a subsystem works ("X is the authority on Y", "the source
# of truth", "the only writer", "the hot path") WITHOUT a file:line citation in
# the same message.
#
# Mechanical backstop for the atone pattern `structural-claim-without-reading-code`
# (S3). Despite a dedicated rule + a Tier-0 citation, i-dream reflect shows this
# pattern WORSENING (7d=5, ↑ as of 2026-06-19) — advisory text alone isn't
# binding it. A Stop hook is the only place that sees the completed turn's prose
# and can react to it.
#
# Posture: STAKES-SCALED (atone T2.2). Authority phrasing in prose is a heuristic
# with real false positives (a sentence can legitimately describe authority it
# cited elsewhere), so friction scales with how much a wrong claim actually costs
# (resolved by stakes-tier.sh from the turn's cwd):
#   - high-stakes repo (code that ships, or gcc itself): BLOCK once with a
#     DO-CONFIRM, then step aside (revert to a note) so a false positive costs at
#     most one extra turn and never traps the agent.
#   - low-stakes repo: the original behaviour — a non-blocking systemMessage note,
#     never a block.
# Either way it stays silent when the message already cites a file:line or has
# tagged the claim [UNVERIFIED]/[UNCONFIRMED]. Loop-safe: one action per claim
# signature. Mute: touch ~/.claude/.no-structural-claim-gate
#
# (This file used to be non-blocking in ALL repos. The MAGI atone-recurrence
# deliberation escalated it to a stakes-gated block: structural-claim is the #1
# recurring pattern (10×) and the advisory note alone was not binding it.)

set -uo pipefail
[ -f "$HOME/.claude/.no-structural-claim-gate" ] && exit 0

input=$(cat 2>/dev/null) || exit 0
command -v jq >/dev/null 2>&1 || exit 0

sid=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)
tp=$(printf '%s' "$input" | jq -r '.transcript_path // empty' 2>/dev/null)
[ -n "$sid" ] && [ -n "$tp" ] && [ -f "$tp" ] || exit 0
sid8="${sid:0:8}"

# Last assistant message text only — precise, avoids scanning the whole tail.
tail_json=$(tail -n 400 "$tp" 2>/dev/null) || exit 0
[ -n "$tail_json" ] || exit 0
last_asst=$(printf '%s\n' "$tail_json" | jq -rc 'select(.type=="assistant")' 2>/dev/null | tail -n 1)
[ -n "$last_asst" ] || exit 0
text=$(printf '%s' "$last_asst" | jq -r '.message.content[]? | select(.type=="text") | .text' 2>/dev/null)
[ -n "$text" ] || exit 0

# ── Detection: an authority / control-flow assertion in the prose ────────────
# Mirrors the phrasings the rule enumerates. Word-boundaried, case-insensitive.
# Last alternation = the reductive "Y is just a [jwt/cookie/cache hit/single
# function]" form the rule also names (uses is/are only — the apostrophe-s
# contraction is dropped to keep this single-quoted, and under-firing is the
# desired posture anyway).
AUTHORITY_RX='\bis the (authority|source of truth|final (check|word|authority|arbiter)|only (writer|owner|source)|hot path|canonical (source|owner)|single source of truth)\b|\b(owns|mints|minted|is the only thing that writes) the\b|\bis the only (writer|owner|authority) (of|for|on)\b|\b(is|are)\s+(just|merely|only)\s+a\s+(jwt|cookie|cache( hit| lookup)?|single (function|call|query)|thin wrapper|getter|setter|no-?op)\b'
printf '%s' "$text" | rg -qiP "$AUTHORITY_RX" 2>/dev/null || exit 0

# ── Carve-out: a file:line citation OR an explicit uncertainty tag in the same
# message → the claim is grounded or already honestly hedged; stay quiet.
# Matches file.ext:123 / backtick `path/file.rs:97`; [UNVERIFIED] / [UNCONFIRMED].
CITATION_RX='[A-Za-z0-9_./-]+\.[A-Za-z0-9]+:[0-9]+|\[UN(VERIFIED|CONFIRMED)\]'
if printf '%s' "$text" | rg -qP "$CITATION_RX" 2>/dev/null; then
  exit 0
fi

# ── Stakes: scale friction to how much a wrong claim costs here ───────────────
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)
[ -z "$cwd" ] && cwd="$PWD"
stakes=$(bash "$HOME/.claude/scripts/stakes-tier.sh" "$cwd" 2>/dev/null || echo low)

# ── Loop-safe: one action per claim signature ────────────────────────────────
MARK="/tmp/claude-structural-claim-${sid8}"
sig=$(printf '%s' "$text" | shasum 2>/dev/null | awk '{print $1}')
prev=""; [ -f "$MARK" ] && prev=$(cat "$MARK" 2>/dev/null)

NOTE="⚠ structural-claim-without-reading-code — your message asserts how a subsystem works (authority / source-of-truth / only-writer / hot-path / \"just a …\") but cites no file:line. Pattern-matching from prior projects is not evidence. Name the file:line that proves it, or read the code that decides it before stating the claim. False positive (you did cite/read elsewhere)? Carry on. Mute: touch ~/.claude/.no-structural-claim-gate"

if [ "$sig" = "$prev" ] && [ -n "$sig" ]; then
  # Same claim as the last Stop. High-stakes already blocked once — don't trap
  # the agent; surface the note non-blockingly and step aside. Low-stakes already
  # noted on the first Stop, so stay silent (preserves the original behaviour).
  [ "$stakes" = "high" ] && { jq -cn --arg m "$NOTE" '{systemMessage:$m}' 2>/dev/null || true; }
  exit 0
fi
printf '%s' "$sig" > "$MARK" 2>/dev/null || true

if [ "$stakes" = "high" ]; then
  reason="⛔ STRUCTURAL CLAIM WITHOUT A CITATION (high-stakes repo) — your message asserts how a subsystem works (authority / source-of-truth / only-writer / hot-path / \"just a …\") but names no file:line that proves it. This is the #1 recurring atone pattern (structural-claim-without-reading-code, S3, 10×); pattern-matching from prior projects is not evidence.

  Before ending the turn: cite the exact file:line that decides this, OR read the code that does and then state it, OR tag the sentence [UNVERIFIED] if you genuinely cannot confirm it.

This won't block again for the same claim — if you verified out-of-band or it's a false positive, say so and proceed. Mute: touch ~/.claude/.no-structural-claim-gate"
  jq -cn --arg r "$reason" '{decision:"block", reason:$r}' 2>/dev/null || true
  exit 0
fi

# low-stakes → original non-blocking note
jq -cn --arg m "$NOTE" '{systemMessage:$m}' 2>/dev/null || true
exit 0
