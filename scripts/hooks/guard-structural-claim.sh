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
# Posture: NON-BLOCKING by design. Authority phrasing in prose is a heuristic
# with real false positives (a sentence can legitimately describe authority it
# cited elsewhere). Blocking on that would punish the user; so this only ever
# surfaces a systemMessage note and NEVER blocks the turn. Stays silent when the
# message already contains a file:line citation. Loop-safe: one note per claim
# signature. Mute: touch ~/.claude/.no-structural-claim-gate

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
AUTHORITY_RX='\bis the (authority|source of truth|final (check|word|authority|arbiter)|only (writer|owner|source)|hot path|canonical (source|owner)|single source of truth)\b|\b(owns|mints|minted|is the only thing that writes) the\b|\bis the only (writer|owner|authority) (of|for|on)\b'
printf '%s' "$text" | rg -qiP "$AUTHORITY_RX" 2>/dev/null || exit 0

# ── Carve-out: a file:line citation in the same message → trust it, stay quiet ─
# Matches file.ext:123 and backtick `path/file.rs:97` forms.
CITATION_RX='[A-Za-z0-9_./-]+\.[A-Za-z0-9]+:[0-9]+'
if printf '%s' "$text" | rg -qP "$CITATION_RX" 2>/dev/null; then
  exit 0
fi

# ── Loop-safe: one note per claim signature ──────────────────────────────────
MARK="/tmp/claude-structural-claim-${sid8}"
sig=$(printf '%s' "$text" | shasum 2>/dev/null | awk '{print $1}')
prev=""; [ -f "$MARK" ] && prev=$(cat "$MARK" 2>/dev/null)
[ "$sig" = "$prev" ] && [ -n "$sig" ] && exit 0
printf '%s' "$sig" > "$MARK" 2>/dev/null || true

msg="⚠ structural-claim-without-reading-code — your message asserts how a subsystem works (authority / source-of-truth / only-writer / hot-path) but cites no file:line. Pattern-matching from prior projects is not evidence. Name the file:line that proves it, or read the code that decides it before stating the claim. False positive (you did cite/read elsewhere)? Carry on. Mute: touch ~/.claude/.no-structural-claim-gate"
jq -cn --arg m "$msg" '{systemMessage:$m}' 2>/dev/null || true
exit 0
