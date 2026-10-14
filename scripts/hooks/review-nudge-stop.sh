#!/usr/bin/env bash
# lifecycle: tune-able hook (owner D4, 2026-10-15; rebuilt from the retired review-gate-stop.sh)
# instrument: self (a review marker covering the files after the nudge records heeded:true)
# review-by: 2026-11-15
# retire-if: heed-rate < 30% over 40 fires
# review-nudge-stop.sh — Stop hook: when this session wrote a substantial amount of
# code and no /skeptical-review or /adversarial-review has covered it, tell the owner.
#
# The old review-gate-stop.sh blocked the turn, was retired on 2026-10-14 (zero
# fires, unregistered, and a marker nobody could write correctly), and the intent
# still holds: a fresh reader catches real bugs that the author's own checks miss.
# This version only warns. It shows the owner one line, once per set of unreviewed
# files, and never holds the turn open.
#
# "Substantial" is a count of lines this session ADDED to code files it edited:
# 50 or more in total (REVIEW_NUDGE_LINES overrides). The edit is measured against
# the session's own pre-edit snapshot (snapshot-pre-edit.sh), so another session's
# uncommitted lines in the same repo never count, and a new file counts whole.
# Docs, reports, generated and vendored paths and test files are not code here
# (review-marker.sh holds the path rules).
#
# Covered means review-marker.sh wrote the marker for these files: both review skills
# run `review-marker.sh write` at the end. The marker name is cut to the first 8
# characters of the session id on both sides now, which is the mismatch that made the
# old gate ask for reviews that had already happened.
#
# Loop-safe: a given set of unreviewed files warns once. The same set at a later Stop
# records heeded:false and stays quiet; a review that covers the set records
# heeded:true. A new unreviewed file starts a new set.
#
# Mute: touch ~/.claude/.no-review-nudge-gate (machine-wide until removed).
# Telemetry: warn-log.sh --hook review-nudge.

set -uo pipefail
[ -f "$HOME/.claude/.no-review-nudge-gate" ] && exit 0
command -v jq >/dev/null 2>&1 || exit 0

input=$(cat 2>/dev/null) || exit 0
HOOK_COMMON="$HOME/.claude/scripts/hooks/hook-common.sh"
[ -r "$HOOK_COMMON" ] || exit 0
. "$HOOK_COMMON"
hook_snoozed review-nudge && exit 0

sid=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)
[ -n "$sid" ] || exit 0
sid8=$(hook_sid8 "$sid")
[ -f "/tmp/claude-edited-files-${sid8}" ] || exit 0

MARKER="${REVIEW_MARKER_SH:-$HOME/.claude/scripts/review-marker.sh}"
[ -x "$MARKER" ] || exit 0
LOG="$HOME/.claude/scripts/hooks/warn-log.sh"
MARK="/tmp/claude-review-nudge-${sid8}"   # signature of the last unreviewed set we warned about
THRESH="${REVIEW_NUDGE_LINES:-50}"
case "$THRESH" in ''|*[!0-9]*) THRESH=50 ;; esac

unreviewed=$("$MARKER" edited-unreviewed "$sid8" 2>/dev/null | rg -v '(\.test\.|\.spec\.|_test\.|/tests?/|/__tests__/)' 2>/dev/null)

if [ -z "$unreviewed" ]; then
  # Nothing unreviewed. A lingering marker means we warned and a review has since
  # covered the files: the warning was heeded (unless it was already scored as not
  # heeded at a later Stop, which keeps its one verdict).
  if [ -s "$MARK" ]; then
    [ -f "$MARK.seen" ] || bash "$LOG" --hook review-nudge --heed-of "review-nudge:$sid8" --heeded true >/dev/null 2>&1 || true
    : > "$MARK"; rm -f "$MARK.seen" 2>/dev/null
  fi
  exit 0
fi

# Lines this session added to those files, against its own pre-edit snapshot.
added_in() {
  local f="$1" fr key snap
  fr=$(cd "$(dirname "$f")" 2>/dev/null && printf '%s/%s' "$(pwd -P)" "$(basename "$f")") || fr="$f"
  key=$(printf '%s' "$fr" | shasum 2>/dev/null | awk '{print $1}')
  snap="/tmp/claude-presnap-${sid8}/${key}"
  if [ -f "$snap" ]; then
    diff "$snap" "$f" 2>/dev/null | rg -c '^> ' 2>/dev/null || echo 0
  else
    # No snapshot (a resumed session, or the snapshotter was not wired yet): count
    # the whole file, capped, rather than guess nothing was added.
    local n; n=$(wc -l < "$f" 2>/dev/null | tr -d ' '); [ "${n:-0}" -gt 200 ] && n=200; echo "${n:-0}"
  fi
}
total=0; nfiles=0
while IFS= read -r f; do
  [ -n "$f" ] && [ -f "$f" ] || continue
  a=$(added_in "$f"); total=$((total + ${a:-0})); nfiles=$((nfiles + 1))
done <<< "$unreviewed"

if [ "$total" -lt "$THRESH" ]; then exit 0; fi

sig=$(printf '%s' "$unreviewed" | sort -u | shasum 2>/dev/null | awk '{print $1}')
prev=""; [ -s "$MARK" ] && prev=$(cat "$MARK" 2>/dev/null)
if [ -n "$sig" ] && [ "$sig" = "$prev" ]; then
  # Same set, still unreviewed, already told: the nudge did not move anyone. Scored
  # once per set, not once per Stop.
  if [ ! -f "$MARK.seen" ]; then
    bash "$LOG" --hook review-nudge --heed-of "review-nudge:$sid8" --heeded false >/dev/null 2>&1 || true
    : > "$MARK.seen"
  fi
  exit 0
fi
printf '%s' "$sig" > "$MARK" 2>/dev/null || true
rm -f "$MARK.seen" 2>/dev/null
bash "$LOG" --hook review-nudge --action nudge --heeded unknown --detail "${nfiles} files, ${total} lines unreviewed" >/dev/null 2>&1 || true
msg="ℹ review-nudge: this session added about ${total} lines across ${nfiles} code file(s) that no review has covered. /skeptical-review (or /adversarial-review) reads them with fresh eyes; either one records the marker that silences this. Mute: touch ~/.claude/.no-review-nudge-gate"
jq -cn --arg m "$msg" '{systemMessage:$m}' 2>/dev/null || true
exit 0
