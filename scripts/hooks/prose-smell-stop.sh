#!/usr/bin/env bash
# prose-smell-stop.sh — Stop hook: flag default-LLM "AI-smell" register in the
# final assistant message before it ends the turn.
#
# The user reads reply tone as a UI surface and has S3'd this twice (atone
# ai-smell-prose-against-stored-voice · flattery-and-unrequested-agenda; rule:
# rules/audience-aware-writing.md). Both RCAs asked for exactly this hook.
#
# Tells, tiered by confidence (fenced code, inline code, and blockquotes are
# stripped first; messages under 200 prose chars are skipped):
#   block-tier: em-dash in prose · decoration-emoji headers/status lines ·
#               ≥3 "**Label**: fragment" rows · >5 bold spans ·
#               praise-without-evidence opener
#   warn-tier:  ★ insight boxes (NOTE: the Explanatory output style legitimately
#               produces one per message — hence warn, never block) ·
#               option-menu closer (legitimate forks exist)
#
# Consequence (features/hook-design.md — matched to cost-of-false-fire):
#   ≥2 block-tier categories → a WOULD-BLOCK systemMessage by default; a real
#     decision:block only when PROSE_SMELL_ENFORCE=1. Measure-first rollout:
#     both source RCAs asked to "flag", cost-of-miss is one LLM-voiced message
#     (recoverable), and the active Explanatory output style produces em-dashes
#     legitimately — so blocking waits for fire-rate telemetry (review verdict
#     2026-07-10, assets/reports/20260710-queue-reviews/1.5a-prose-smell.md).
#   any tells at all → systemMessage note (non-blocking, visible)
# Loop-safe like filename-dot-stop.sh: identical message never re-fires.
#
# Mute: PROSE_SMELL_OFF=1 (this process) · touch ~/.claude/.no-prose-smell-gate
# (machine-wide, ALL sessions until removed). Telemetry: warn-log.sh --hook prose-smell.

set -uo pipefail
[ "${PROSE_SMELL_OFF:-0}" = "1" ] && exit 0
[ -f "$HOME/.claude/.no-prose-smell-gate" ] && exit 0

input=$(cat 2>/dev/null) || exit 0
command -v jq >/dev/null 2>&1 || exit 0
command -v rg >/dev/null 2>&1 || exit 0
command -v shasum >/dev/null 2>&1 || exit 0

HOOK_COMMON="$HOME/.claude/scripts/hooks/hook-common.sh"
[ -r "$HOOK_COMMON" ] || exit 0
. "$HOOK_COMMON"

sid=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)
tp=$(printf '%s' "$input" | jq -r '.transcript_path // empty' 2>/dev/null)
[ -n "$sid" ] && [ -n "$tp" ] && [ -f "$tp" ] || exit 0
sid8="${sid:0:8}"

# Last assistant message text (same extraction as filename-dot-stop.sh).
tail_json=$(tail -n 400 "$tp" 2>/dev/null) || exit 0
last_asst=$(printf '%s\n' "$tail_json" | jq -rc 'select(.type=="assistant")' 2>/dev/null | tail -n 1)
[ -n "$last_asst" ] || exit 0
text=$(printf '%s' "$last_asst" | jq -r '.message.content[]? | select(.type=="text") | .text' 2>/dev/null)
[ -n "$text" ] || exit 0

# Prose = text minus fenced code blocks, inline code spans, blockquotes, and
# markdown table rows (a table with a bolded first column is a legitimate doc
# shape, not bold-spam — confirmed FP in review).
prose=$(printf '%s\n' "$text" \
  | awk 'BEGIN{f=0} /^[[:space:]]*```/{f=!f; next} !f{print}' \
  | sed -e 's/`[^`]*`//g' -e '/^[[:space:]]*>/d' -e '/^[[:space:]]*|/d')
[ "$(printf '%s' "$prose" | wc -c | tr -d ' ')" -ge 200 ] || exit 0

tells=""        # human-readable list of what fired
block_hits=0    # count of block-tier categories

# 1 · em-dash in prose (stored preference: budget zero — audience-aware-writing).
emdash_n=$(printf '%s' "$prose" | rg -c '—' 2>/dev/null || true)
if [ "${emdash_n:-0}" -ge 1 ] 2>/dev/null; then
  tells="${tells}\n- em-dash ×${emdash_n} (budget is zero — use commas, periods, parentheses, or 'and')"
  block_hits=$((block_hits + 1))
fi

# 2 · decoration-emoji headers / traffic-light status lines.
if printf '%s\n' "$prose" | rg -q '^[[:space:]]*(#{1,6}[[:space:]]*)?(🔴|🟡|🟢|🟠|🚦|🎯|🚀|🔥|💡|📊|🧠|✨|🛑|📌|⚡|❗|✅|⚠️|❌)' 2>/dev/null; then
  tells="${tells}\n- decoration-emoji header/status lines (traffic-lights, section emoji — decoration is not rigor)"
  block_hits=$((block_hits + 1))
fi

# 3 · "**Label**: fragment" bullet armies (≥3 rows; genuine key/value pairs
# rarely stack that high outside a table).
label_n=$(printf '%s\n' "$prose" | rg -c '^[[:space:]]*[-*•]?[[:space:]]*\*\*[^*]{2,40}\*\*[[:space:]]*:' 2>/dev/null || true)
if [ "${label_n:-0}" -ge 3 ] 2>/dev/null; then
  tells="${tells}\n- Label:fragment rows ×${label_n} (write sentences; reserve Label: for real key/value data)"
  block_hits=$((block_hits + 1))
fi

# 4 · bold-spam (>5 bold spans — if everything is emphasized, nothing is).
bold_n=$(printf '%s' "$prose" | rg -o '\*\*[^*]+\*\*' 2>/dev/null | wc -l | tr -d ' ')
if [ "${bold_n:-0}" -gt 5 ] 2>/dev/null; then
  tells="${tells}\n- bold spans ×${bold_n} (cap emphasis near one phrase per message)"
  block_hits=$((block_hits + 1))
fi

# 5 · praise-without-evidence opener (first non-empty prose line).
first_line=$(printf '%s\n' "$prose" | rg -m1 '\S' 2>/dev/null | head -1)
if printf '%s' "$first_line" | rg -qi "^(you'?re (absolutely |completely |exactly )?right|great (question|point|idea|catch)|excellent|perfect[.!]|fair question|what a )" 2>/dev/null; then
  tells="${tells}\n- praise opener (\"${first_line:0:60}…\") — open with substance, praise only with evidence"
  block_hits=$((block_hits + 1))
fi

# 6 · ★ insight boxes (warn-tier only — Explanatory style produces one legitimately).
star_n=$(printf '%s' "$prose" | rg -c '★' 2>/dev/null || true)
if [ "${star_n:-0}" -ge 1 ] 2>/dev/null; then
  tells="${tells}\n- ★ decoration ×${star_n} (warn-tier: fine under the Explanatory output style, decoration otherwise)"
fi

# 8 · a short question answered with a structural opener instead of a sentence.
#
# The `dense-briefing-instead-of-a-direct-answer` shape: 10 events, S3, and every
# one of their prechecks names the SAME discriminator, which is not length. "Is my
# first sentence the answer, or is it setup?" A long answer to a short question is
# often correct (a todo list, a report). Opening with a title when someone asked a
# question never is.
#
# Measured over 1138 real prompt/reply pairs: raw length ratio alone flags 1.93%
# and is mostly wrong (harness injections, image-paste boilerplate, legitimately
# long lists, and replies that DO lead with the answer). Adding the opener test
# drops it to 0.35% and 3 of 4 hits are real: `**Task: Root-folder census**`,
# `**Formulating Central Config Design**`, `**Identifying Model-Specific
# Capabilities**` — two of which are thinking-block titles that leaked into prose.
#
# The fourth was `**Six done, one in flight, two untouched.**`, which IS the answer
# wearing bold. A header is a noun phrase; that is a sentence. Trailing sentence
# punctuation inside the bold separates them and costs one character class.
#
# Warn-tier per ruling D2a. Length is the gate here, never the signal.
# Two stages on purpose. `jq -r` prints a multi-line string as multiple LINES, so
# a single `jq -r … | tail -n 1` keeps only the prompt's last line: a pasted
# <system-reminder> block arrived as "</system-reminder>" and slipped past the
# exclusion, and any multi-line prompt measured as just its final line, making a
# long prompt read as short. Select the last matching OBJECT first, decode after.
# Slurped on purpose, for two reasons that each cost a real bug on the way here.
# `jq -r` prints a multi-line string as multiple LINES, so a `jq -r … | tail -n 1`
# keeps only the prompt's final line: a pasted <system-reminder> block arrived as
# "</system-reminder>" and slipped the exclusion below, and every multi-line prompt
# measured as its last line only, which makes a long prompt read as short. And the
# obvious `any(.[]?; .type=="text")` guard iterates the ROOT object's values, so it
# tries to index the string "user" and dies. Decode every candidate, drop the
# empties, take the last.
last_user=$(printf '%s\n' "$tail_json" | jq -c 'select(.type=="user")' 2>/dev/null | jq -rs '
  map(if (.message.content|type)=="string" then .message.content
      elif (.message.content|type)=="array"
      then ([.message.content[]? | select(.type=="text") | .text] | join(""))
      else "" end)
  | map(select(length > 0)) | last // ""' 2>/dev/null)
# A harness injection is not something the user typed, and neither is the
# coordinate boilerplate that rides along with a pasted image. Both read as a
# short prompt and produced 7 of the 22 raw-ratio hits.
if [ -n "$last_user" ] \
   && ! printf '%s' "$last_user" | rg -q '^[[:space:]]*(<system-reminder>|\[Image:|<command-name>|<local-command|Caveat:)' 2>/dev/null \
   && [ "${#last_user}" -le 200 ] \
   && [ "$(printf '%s' "$prose" | wc -c | tr -d ' ')" -ge 1200 ]; then
  opener=$(printf '%s\n' "$prose" | rg -m1 '\S' 2>/dev/null | head -1)
  if printf '%s' "$opener" | rg -qP '^\s*(#{1,6}\s|\*\*[^*]{2,60}\*\*\s*:?\s*$)' 2>/dev/null \
     && ! printf '%s' "$opener" | rg -qP '[.!?]\s*\*{0,2}\s*$' 2>/dev/null; then
    tells="${tells}\n- opened a ${#prose}-char reply to a ${#last_user}-char question with a title, not the answer (\"${opener:0:48}…\") — lead with the sentence that answers, then explain"
  fi
fi

# 7 · option-menu closer (warn-tier — genuine forks are legitimate).
closer=$(printf '%s\n' "$prose" | rg '\S' 2>/dev/null | tail -3)
if printf '%s' "$closer" | rg -qi '(would you like me to|do you want me to|shall i|want me to) .+ or .+\?' 2>/dev/null; then
  tells="${tells}\n- option-menu closer — if the task is done, report and stop; offer forks only at genuine decision points"
fi

MARK="/tmp/claude-prose-smell-${sid8}"

# Fully-clean message: the best outcome. A lingering marker means a prior fire
# was heeded — record that BEFORE exiting (review C1: the original ordering made
# exactly this case invisible to the heed metric and left the marker stale).
if [ -z "$tells" ]; then
  if [ -f "$MARK" ]; then
    bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook prose-smell --heed-of "prose-smell:$sid8" --heeded true >/dev/null 2>&1 || true
    rm -f "$MARK" 2>/dev/null || true
  fi
  exit 0
fi

sig=$(printf '%s' "$prose" | shasum 2>/dev/null | awk '{print $1}')

if [ "$block_hits" -ge 2 ]; then
  prev=""; [ -f "$MARK" ] && prev=$(cat "$MARK" 2>/dev/null)
  if [ "$sig" = "$prev" ] && [ -n "$sig" ]; then
    # Already fired on this exact message once — step aside with a visible note.
    bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook prose-smell --heed-of "prose-smell:$sid8" --heeded false >/dev/null 2>&1 || true
    jq -cn --arg t "$(printf '⚠ prose-smell (not re-firing): tells remain:%b\nMute: touch ~/.claude/.no-prose-smell-gate' "$tells")" '{systemMessage:$t}' 2>/dev/null || true
    exit 0
  fi
  printf '%s' "$sig" > "$MARK" 2>/dev/null || true
  # The block channel renders `reason` as a one-line "Stop hook error:" string
  # and CLIPS it, so a multi-line box arrives truncated mid-word and the
  # actionable half never reaches anyone. Boxes are for channels that render a
  # block (systemMessage, agent-composed replies); a block reason stays compact
  # and single-line. Learned 2026-08-15 from a live fire that cut off at "atone".
  tells_flat=$(printf '%b' "$tells" | tr '\n' ' ' | tr -s ' ' | sed 's/^ *//;s/ *$//')
  reason="prose-smell: default-LLM register vs stored voice. Tells: ${tells_flat}. Re-emit plain: meaning first, no em-dashes, minimal bold, no decoration, no praise opener, answer-and-stop. See rules/audience-aware-writing.md. Mute: touch ~/.claude/.no-prose-smell-gate (machine-wide) or PROSE_SMELL_OFF=1 (this process)."
  if [ "${PROSE_SMELL_ENFORCE:-0}" = "1" ]; then
    bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook prose-smell --action block --heeded unknown >/dev/null 2>&1 || true
    jq -cn --arg r "$reason" '{decision:"block", reason:$r}' 2>/dev/null || true
  else
    # Measure-first default: record the would-block, surface it visibly, never
    # stop the turn. Promote to enforcement only when telemetry justifies it.
    bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook prose-smell --action block-dry --heeded unknown >/dev/null 2>&1 || true
    jq -cn --arg t "$(printf '⚠ prose-smell WOULD-BLOCK (dry-run):%b\nEnforce: PROSE_SMELL_ENFORCE=1 · Mute: touch ~/.claude/.no-prose-smell-gate' "$tells")" '{systemMessage:$t}' 2>/dev/null || true
  fi
  exit 0
fi

# Single-category (or warn-tier-only) fire: visible note. A partially-cleaned
# message after a prior fire still counts as heeded — record + clear.
if [ -f "$MARK" ]; then
  bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook prose-smell --heed-of "prose-smell:$sid8" --heeded true >/dev/null 2>&1 || true
  rm -f "$MARK" 2>/dev/null || true
fi
bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook prose-smell --action nudge --heeded unknown >/dev/null 2>&1 || true
jq -cn --arg t "$(printf 'ℹ prose-smell:%b' "$tells")" '{systemMessage:$t}' 2>/dev/null || true
exit 0
