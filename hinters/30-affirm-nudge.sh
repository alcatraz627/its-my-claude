#!/usr/bin/env bash
# 30-affirm-nudge.sh — fires when the user message contains an affirmation
# signal AND a 2nd-person pronoun nearby, to avoid false positives like
# "the user did a great job".
#
# Suggests /affirm for non-obvious choices the user explicitly approved.
# /affirm has a higher write bar than /atone — only fires when the choice was
# genuinely surprising or load-bearing. The hinter is just the prompt; the
# skill is where the bar gets enforced.
#
# Skip conditions:
#   - ~/.claude/atone/.affirm-nudge-off exists (mute)
#   - prompt has no affirmation keyword
#   - 3rd-person subject precedes the keyword (filter)
#   - hypothetical/question framing
#
# Latency budget: <100ms.

set -uo pipefail

[ -f "$HOME/.claude/atone/.affirm-nudge-off" ] && exit 0

PROMPT=$(cat)
[ -z "$PROMPT" ] && exit 0

HIT=$(ATONE_PROMPT="$PROMPT" python3 - <<'PY' 2>/dev/null
import os, re
text = os.environ.get("ATONE_PROMPT", "").lower()

# Hypothetical / question framing — never fire
if re.search(r'\b(is it (good|right|nice)|would (it )?be (good|right|nice)|might be)\b', text):
    raise SystemExit(0)

# Affirmation keywords (must be addressed at the agent)
kw_re = re.compile(
    r'\b(good call|nice catch|smart move|right call|well done|that.?s right|'
    r'perfect|exactly|yes exactly|brilliant|spot on|sharp|that worked|'
    r'love it|that.?s the move|yeah that|keep doing that|good thinking)\b',
    re.I,
)

# 3rd-person subject preceding the keyword — skip ("the user did well")
neg_subj_re = re.compile(
    r'\b(the user|users?\b|customer|client|visitor|the (data|csv|file|test)|'
    r'they|he|she|their|his|her)\s+(\w+\s+){0,4}$',
    re.I,
)

for m in kw_re.finditer(text):
    pre = text[max(0, m.start()-60):m.start()]
    if neg_subj_re.search(pre):
        continue
    print("hit"); break
PY
)

[ "$HIT" = "hit" ] || exit 0

cat <<'NUDGE'
[affirm-nudge] User language suggests affirmation. If the choice you just made was
non-obvious / surprising / counter to a default, consider /affirm:
  1. Identify what you did (one sentence) and what the default would have been.
  2. Invoke /affirm — the skill captures the trigger condition + at-action-time check.
Bar is HIGH — only log if a future agent might not repeat without an external nudge.
Mute: touch ~/.claude/atone/.affirm-nudge-off
NUDGE
