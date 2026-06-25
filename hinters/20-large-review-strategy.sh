#!/usr/bin/env bash
# 20-large-review-strategy.sh — surfaces the reusable "large review strategy"
# report when a prompt is about reviewing a big / distributed / restructure-y
# change. Reads prompt from stdin; emits ONE hint line or nothing. <100ms.
#
# Report: ~/.claude/assets/reports/20260621-large-review-strategy/REPORT.md
# Rationale: the user can't always remember this exists; this is the nudge so an
# agent designing a review approach discovers the prior research on its own.

set -uo pipefail

REPORT="${HOME}/.claude/assets/reports/20260621-large-review-strategy/REPORT.md"
[[ -f "$REPORT" ]] || exit 0

PROMPT=$(cat 2>/dev/null || echo "")
[[ -z "$PROMPT" ]] && exit 0

# Gate: must carry a REVIEW signal AND a SCALE/strategy signal, so it doesn't
# fire on "review this one function".
review_re='review|reviewing|reviewer|merge this|approve'
scale_re='strateg|approach|playbook|checklist|how (do|to|should|much).{0,25}review|where (do|to|should).{0,20}(look|start)|large|big( |-)?(pr|diff|change)|huge|enormous|massive|monstrous|giant|hundreds|thousands|[0-9]{2,} ?(files|docs|changes|commits)|restructure|migration|bulk|sweep|distributed|grab.?bag|too (big|large|many)|chunk|prioriti|effort.{0,25}(spend|review)'

if echo "$PROMPT" | grep -qiE "$review_re" && echo "$PROMPT" | grep -qiE "$scale_re"; then
  printf '%s' "[review-strategy] Reviewing a large / distributed / restructure change? A reusable calibrated playbook (review by transformation-TYPE not file order, trust green CI, stakes-order, cheap agent pre-flag greps) + a 6-discipline research panel lives at ~/.claude/assets/reports/20260621-large-review-strategy/REPORT.md — read it before designing the review approach."
fi
