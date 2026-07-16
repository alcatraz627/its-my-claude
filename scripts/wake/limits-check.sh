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

# State what a reading LOOKS like, and reject everything else. Not the reverse.
#
# Nothing below can run on a value that is not an integer: `[` errors on an operand
# it cannot parse, which reads as false, and control falls through to the OPEN at
# the bottom — confident headroom off a comparison that never happened. So the shape
# check has to come first and has to be positive.
#
# It was briefly a list of prohibitions instead, on the strength of a measurement
# that jq's shortest non-digit output is "1e+16" (5 chars) and a length bound could
# therefore cover it. That measurement enumerated large integers and generalised to
# every input. It is false: `jq -rn 'nan|floor'` emits `null` — four characters,
# under the bound — and `{"5h":{"pct":"nan"}}` fell straight through to exit 0.
# A deny-list is only ever as good as the author's imagination; an allow-list says
# what is true. (Skeptical review, 2026-07-17.)
[[ "$pct" =~ ^-?[0-9]+$ ]] || {
  say UNKNOWN "" "5h.pct in $LIMITS is not an integer (got '${pct}')"; exit 2; }

# Four characters covers every real percentage ("-0".."100"); longer is a broken
# writer, and also what would overflow the comparison below.
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
# String comparison, not `$((pct))`: arithmetic context evaluates a variable's
# CONTENTS as an expression, so a value that happens to be a name dereferences it
# (`pct=evil; evil=7; echo $((pct))` prints 7). The shape check above makes that
# unreachable today, which is not a reason to leave the construct sitting here.
[ "$pct" = "-0" ] && pct=0

if [ "$pct" -ge "$THRESHOLD" ]; then
  say NEAR-FULL "$pct" "5h window ${pct}% spent (>= ${THRESHOLD}%) — leave the rest for real work"
  exit 1
fi

say OPEN "$pct" "5h window ${pct}% spent (< ${THRESHOLD}%) — headroom to wake"
exit 0
