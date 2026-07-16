#!/usr/bin/env bash
# limits-check.sh — is the 5h usage window open enough to be worth waking into?
#
# What this is, in human terms: the wake monitor pokes an idle session every N
# minutes to see if an outage cut it off. Each poke costs a little of the same 5h
# budget the user's real work draws from. When that budget is nearly spent, the
# polite thing is to stop poking and let the user have what's left.
#
# Why it reads a percentage and not a reset time: Claude Code sends
# resets_at=9999999999 when it does not know when the window resets — the sentinel
# IS the message, and no amount of parsing conjures a clock out of it (see
# rules-free note in statusline.sh:_rl_to_epoch, and dcd49a5). So there is nothing
# to schedule against. How full the window already is, is the only honest signal.
#
# Prints one TAB-separated line and mirrors the verdict in the exit code, so a
# caller can branch on either:
#
#   OPEN<TAB><pct><TAB><detail>       exit 0   headroom left; wake away
#   NEAR-FULL<TAB><pct><TAB><detail>  exit 1   nearly spent; stop poking
#   UNKNOWN<TAB><TAB><detail>         exit 2   no usable reading
#
# UNKNOWN is deliberately its own verdict rather than being folded into OPEN. A
# missing reading is not evidence of headroom, and a check that reports "plenty of
# room" when it actually knows nothing is the plausible-looking default that keeps
# biting this account. The caller decides what to do with not-knowing.
#
# Env:
#   WAKE_LIMITS_FILE    override the source file (tests)
#   WAKE_NEAR_FULL_PCT  the near-full threshold, default 90

set -uo pipefail

LIMITS="${WAKE_LIMITS_FILE:-$HOME/.claude/widgets/.limits.json}"
THRESHOLD="${WAKE_NEAR_FULL_PCT:-90}"

say() { printf '%s\t%s\t%s\n' "$1" "$2" "$3"; }

# A bad threshold must not reach the `-ge` below. When `[` cannot parse an operand
# it errors and returns non-zero, the `if` reads as false, and control falls past
# NEAR-FULL to the unconditional OPEN at the bottom — so a comparison that never
# resolved gets reported as confident headroom. Fail-open, from a typo.
#
# Two ways in, and the length check must come FIRST: a digit string too long for a
# 64-bit int (19+ digits) aborts `-gt` exactly like the junk it is meant to catch,
# so testing its size arithmetically would die on the same rock.
_bad_threshold() {
  printf 'limits-check: ignoring WAKE_NEAR_FULL_PCT=%s (%s) — using 90\n' \
    "${WAKE_NEAR_FULL_PCT:-<empty>}" "$1" >&2
  THRESHOLD=90
}
case "$THRESHOLD" in
  ''|*[!0-9]*) _bad_threshold "want a plain integer" ;;
esac
# Three digits is the whole range a percentage can occupy; longer is a typo, and
# also the overflow case. Length first, arithmetic second.
[ "${#THRESHOLD}" -gt 3 ] && _bad_threshold "a percentage has at most 3 digits"
[ "$THRESHOLD" -gt 100 ] && _bad_threshold "a percentage cannot exceed 100"

command -v jq >/dev/null 2>&1 || {
  say UNKNOWN "" "jq unavailable — cannot read $LIMITS"; exit 2; }

[ -f "$LIMITS" ] || {
  say UNKNOWN "" "no limits file at $LIMITS (written by every statusline render — is the statusline running?)"; exit 2; }

# `."5h".pct` is the field the statusline writes. Take anything that is honestly a
# number — int or float, quoted or bare — and floor it, because bash `-ge` cannot
# compare "43.5" and would abort. `tonumber?` swallows everything that is not a
# number (absent, null, true, "abc", a malformed file), leaving pct empty.
pct=$(jq -r '(."5h".pct | tonumber? | floor) // empty' "$LIMITS" 2>/dev/null)
[ -n "$pct" ] || { say UNKNOWN "" "no numeric 5h.pct in $LIMITS"; exit 2; }

# Length is the only other filter needed, and it must run before any arithmetic:
# an operand `[` cannot parse makes it error, the `if` reads false, and control
# falls through to the OPEN at the bottom — confident headroom off a comparison
# that never ran. Four characters covers every real percentage ("-0".."100").
#
# It also subsumes shape-checking. Measured what jq can actually emit here: the
# shortest non-digit output it produces is "1e+16" (5 chars) — it renders >=16-digit
# numbers in scientific notation and huge floats as 1.79…e+308 (23). So there is no
# reachable input that is non-numeric-looking AND short. An earlier character-class
# check sat here alongside this one and was pure shadow: nothing could reach it, so
# no test could pin it, which is exactly how the validator found it (2026-07-17).
if [ "${#pct}" -gt 4 ]; then
  say UNKNOWN "" "implausible 5h.pct '${pct}' in $LIMITS — a percentage has at most 3 digits"
  exit 2
fi

# A percentage below zero is not a reading, it is a broken writer. Say so rather
# than let it sail under the threshold and read as headroom. Above 100 is different
# — over-spent is still spent, so it falls through to NEAR-FULL below.
if [ "$pct" -lt 0 ]; then
  say UNKNOWN "" "implausible 5h.pct '${pct}' in $LIMITS — a percentage cannot be negative"
  exit 2
fi

# Normalise -0 (a real jq output) to 0 so the detail line doesn't read "-0%".
pct=$((pct))

if [ "$pct" -ge "$THRESHOLD" ]; then
  say NEAR-FULL "$pct" "5h window ${pct}% spent (>= ${THRESHOLD}%) — leave the rest for real work"
  exit 1
fi

say OPEN "$pct" "5h window ${pct}% spent (< ${THRESHOLD}%) — headroom to wake"
exit 0
