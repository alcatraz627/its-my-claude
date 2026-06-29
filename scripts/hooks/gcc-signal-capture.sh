#!/usr/bin/env bash
# gcc-signal-capture.sh — SessionEnd hook, side-effect only.
#
# The /core-dump + /catchup "gcc-contribution" phase asks the agent to file an
# improvement proposal when a reusable ~/.claude friction surfaced this session.
# That phase is advisory: a stale-spec or rushed session skips it (the
# skill-spec-update-not-honored failure mode). This is its DATA-PATH safety net —
# when a session clearly worked on the gcc, hit a friction, and filed nothing, it
# auto-stubs ONE proposal so the signal reaches the backlog regardless of agent
# compliance. The weekly backlog-consolidate then triages it.
#
# Gated HARD to avoid churning the backlog (the user's explicit allergy). It fires
# only when ALL of these hold:
#   1. the session edited files under ~/.claude/   — it actually worked on the gcc
#   2. an atone event was filed this session       — a real friction occurred
#   3. no proposal carries this session_id         — nothing was contributed
#   4. it has not already stubbed this session     — idempotent
# The conjunction is deliberately narrow; each clause shrinks the firing set. It
# does NOT fire on S3/recurrence alone — atone-consolidate already drafts those,
# so stubbing on severity would duplicate that pipeline. The differentiator is
# clause 1 (the session was editing the global config).
#
# Why SessionEnd, not Stop: it must run AFTER any end-of-session /core-dump
# contribution (so clause 3 sees it) and exactly once. A hard crash that skips
# SessionEnd loses only S1/S2 gcc-edit frictions — S3/recurring ones are still
# picked up directly by the weekly consolidate, so nothing important is lost.
#
# Side-effect only: writes via propose.sh, prints nothing, always exit 0.
# Mute: touch ~/.claude/.no-gcc-signal-capture

set -uo pipefail
[ -f "$HOME/.claude/.no-gcc-signal-capture" ] && exit 0
command -v jq >/dev/null 2>&1 || exit 0

input=$(cat 2>/dev/null || echo "{}")
sid=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)
[ -z "$sid" ] && exit 0

GCC="$HOME/.claude"
edited="/tmp/claude-edited-files-${sid:0:8}"
counter="$GCC/.session-atone-slugs/${sid}.json"
# Read the same store propose.sh writes to, so gate 3 stays consistent (and the
# hook is testable via PROPOSE_STORE). Unset in production → the real backlog.
store="${PROPOSE_STORE:-$GCC/proposals.jsonl}"
marker="$GCC/.session-atone-slugs/${sid}.gcc-stub-emitted"

# 4. idempotent — at most one stub per session.
[ -f "$marker" ] && exit 0

# 1. did this session edit the global config? (a path under $HOME/.claude/)
[ -f "$edited" ] || exit 0
grep -q "^${GCC}/" "$edited" 2>/dev/null || exit 0

# 2. did a friction surface this session? (any atone event recorded)
[ -s "$counter" ] || exit 0

# 3. did the agent already contribute a proposal this session? if so, done.
if [ -s "$store" ]; then
  filed=$(jq -rs --arg s "$sid" '[.[] | select(.session_id == $s)] | length' "$store" 2>/dev/null)
  if [ "${filed:-0}" -gt 0 ]; then
    : > "$marker"
    exit 0
  fi
fi

# All gates pass → auto-stub one proposal, cross-linked to the session's atone
# slugs so the weekly consolidate can corroborate / dedupe it.
slugs=$(jq -rs '[.[].slug] | unique | .[]' "$counter" 2>/dev/null | head -3)
links="src:auto-stub needs-fleshing"
while IFS= read -r sg; do
  [ -n "$sg" ] && links="$links link:atone:$sg"
done <<EOF
$slugs
EOF
first_slug=$(printf '%s' "$slugs" | head -1)

bash "$GCC/scripts/propose.sh" add \
  --title "Flesh out gcc friction from session ${sid:0:8} (auto-stub: ${first_slug:-atone})" \
  --body "Auto-stubbed by gcc-signal-capture: this session edited ~/.claude/ and filed atone event(s) [${first_slug:-?}] but contributed no improvement proposal. A reusable gcc improvement likely applies — flesh this out from the linked atone slug(s), or reject at triage. (Stub: not yet reviewed.)" \
  --category other \
  --effort medium \
  --session "$sid" \
  --tags "$links" >/dev/null 2>&1 || true

bash "$GCC/scripts/ledger/plug-log.sh" --plug gcc-signal-capture --lifecycle end --outcome stubbed --session "$sid" --tags "$links" >/dev/null 2>&1 || true
: > "$marker"
exit 0
