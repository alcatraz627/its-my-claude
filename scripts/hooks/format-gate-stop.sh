#!/usr/bin/env bash
# lifecycle: tune-able hook (owner rulings D6 and D7, 2026-10-19)
# instrument: warn-log.sh rows per class (same hook_id as the old gates) plus a format-gate row
# review-by: 2026-11-19
# retire-if: heed-rate < 50% over 100 fires
# format-gate-stop.sh: one Stop pass that checks how the final reply is written,
# and sends it back once with every fix listed, instead of six gates sending it
# back one after another.
#
# It replaces filename-dot-stop.sh, emdash-stop.sh, terse-reply-stop.sh,
# prose-smell-stop.sh, relpath-stop.sh and dense-briefing-shapes-stop.sh. Those
# scripts stay on disk, unregistered. The pattern bodies below are moved from
# them, not rewritten, except where a ruling changed the rule (marked D7).
#
# Blocking classes (one block, one reason line, every span and its fix):
#   filename-dot  a file path that CONTAINS A SLASH directly followed by a period.
#                 A bare filename such as settings.json no longer blocks (D7).
#   emdash        one or more em-dashes in prose.
#   terse-reply   prose over the cap (TERSE_LIMIT, default 2600) unless the owner
#                 asked for length.
#   relpath       (D7) the reply names a file this turn wrote or edited, or a
#                 deliverable under docs/ assets/ .claude/output, and the full
#                 absolute path of it appears nowhere in the reply.
#   prose-smell   two or more block-tier tells, only while policy gates.prose_smell
#                 is enforce; fewer tells, or policy warn, only advise.
# Advisory classes (systemMessage only): dense-briefing, the remaining prose-smell
# tells, and the terse-reply warn tier between TERSE_WARN (1500) and the cap.
#
# Loop safety: marker /tmp/claude-format-gate-<sid8> holds "<signature> <blocks> <classes>".
# An identical reply, three blocks in a row, or stop_hook_active (a block already
# happened this turn) all step aside with a note, so a turn can always end.
# A clean reply clears the marker and records heeded:true for each open class.
# On every block the gate writes /tmp/claude-format-tripped-<sid8>, which
# format-reminder-ups.sh reads to remind the next two turns.
#
# Mutes: each old gate's own mute file and env var still work; so do the policy
# keys gates.terse_reply and gates.prose_smell and the hook snoozes. New:
# FORMAT_GATE_OFF=1 (process) or touch ~/.claude/.no-format-gate (machine-wide,
# ALL sessions until removed). Never exits non-zero.

set -uo pipefail
[ "${FORMAT_GATE_OFF:-0}" = "1" ] && exit 0
[ -f "$HOME/.claude/.no-format-gate" ] && exit 0

input=$(cat 2>/dev/null) || exit 0
command -v jq >/dev/null 2>&1 || exit 0
command -v rg >/dev/null 2>&1 || exit 0
command -v shasum >/dev/null 2>&1 || exit 0

HOOK_COMMON="$HOME/.claude/scripts/hooks/hook-common.sh"
[ -r "$HOOK_COMMON" ] || exit 0
. "$HOOK_COMMON"

HERE="$(cd "$(dirname "$0")" && pwd)"
LOG="$HOME/.claude/scripts/hooks/warn-log.sh"
POL="${POL_SH:-$HOME/.claude/scripts/pol/pol.sh}"

sid=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)
tp=$(printf '%s' "$input" | jq -r '.transcript_path // empty' 2>/dev/null)
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)
active=$(printf '%s' "$input" | jq -r '.stop_hook_active // false' 2>/dev/null)
[ -n "$sid" ] || exit 0
sid8=$(hook_sid8 "$sid")

# The reply that just ended the turn, taken from the Stop input (the transcript
# lags one message at Stop time, see hook_last_assistant_text).
text=$(hook_last_assistant_text "$input" "$tp")
[ -n "$text" ] || exit 0

# Three views of the reply, each the exact strip an old gate used.
#   P1 fenced code removed            (filename-dot, relpath)
#   P2 P1 minus inline code, quotes   (emdash)
#   P3 P2 minus table rows            (terse-reply, prose-smell)
P1=$(printf '%s\n' "$text" | awk 'BEGIN{f=0} /^[[:space:]]*```/{f=!f; next} !f{print}')
P2=$(printf '%s\n' "$P1" | sed -e 's/`[^`]*`//g' -e '/^[[:space:]]*>/d')
P3=$(printf '%s\n' "$P2" | sed -e '/^[[:space:]]*|/d')

CLASSES=""      # blocking classes found, space separated, each surrounded by single spaces when tested
ITEMS=""        # one reason fragment per class, joined with " | "
NSPANS=0
ADV=""          # advisory lines, newline separated
TERSE_SOFT=""   # terse-reply warn-tier text, emitted only as an advisory
TLIMIT="${TERSE_LIMIT:-2600}"

add_block() { # add_block <class> <fragment> <span count>
  CLASSES="$CLASSES $1"
  if [ -z "$ITEMS" ]; then ITEMS="$2"; else ITEMS="$ITEMS | $2"; fi
  NSPANS=$((NSPANS + ${3:-1}))
}
add_adv() { if [ -z "$ADV" ]; then ADV="$1"; else ADV="$ADV
$1"; fi; }
# snoozed <hook-id>: 0 when a live snooze row matches. The once-per-session
# "[snoozed]" notice hook_snoozed prints is folded into the advisory text.
snoozed() {
  local out rc
  out=$(hook_snoozed "$1" "$sid8" 2>/dev/null); rc=$?
  if [ "$rc" -eq 0 ]; then
    [ -n "$out" ] && add_adv "$(printf '%s' "$out" | jq -r '.systemMessage // empty' 2>/dev/null)"
    return 0
  fi
  return 1
}
trunc() { printf '%s' "$1" | cut -c1-"$2"; }

# ---------------------------------------------------------------- filename-dot
EXT='md|markdown|py|sh|bash|ts|tsx|js|jsx|mjs|cjs|html|htm|css|scss|json|jsonl|ya?ml|toml|swift|go|rs|rb|c|h|hpp|cpp|cc|java|kt|sql|txt|log|plist|xml|svg|conf|cfg|ini|env'
# Terminals link `foo.ts:42` and `foo.ts:42:8` as ONE target, so a :line[:col]
# tail can sit between the extension and the period.
LC='(:[0-9]+){0,2}'
# D7: only a path that contains a slash. A bare filename followed by a period is
# no longer a defect worth a rewrite.
FD_BT='`[^`]*/[^`]*\.('"$EXT"')'"$LC"'`\.'
FD_BARE='(?<![A-Za-z0-9])[A-Za-z0-9_.@~-]*/[A-Za-z0-9_./@~-]*\.('"$EXT"')'"$LC"'\.(\s|$|[)\]"])'
FD_PAT="($FD_BT)|($FD_BARE)"

chk_filename_dot() {
  [ -f "$HOME/.claude/.no-filename-dot-gate" ] && return
  local spans n s a b frag
  spans=$(printf '%s\n' "$P1" | rg -oP "$FD_PAT" 2>/dev/null | head -3)
  [ -n "$spans" ] || return
  snoozed filename-dot && return
  n=$(printf '%s\n' "$spans" | wc -l | tr -d ' ')
  # Show each span without the closer the pattern swallowed after the period.
  a=$(printf '%s\n' "$spans" | sed -n '1p' | sed -e 's/[[:space:])"]*$//' -e 's/\]$//')
  b=$(printf '%s\n' "$spans" | sed -n '2p' | sed -e 's/[[:space:])"]*$//' -e 's/\]$//')
  s="$(trunc "$a" 60)"
  [ -n "$b" ] && s="$s ; $(trunc "$b" 60)"
  frag="filename-dot: [${s}] put a word or comma after the path, not a period"
  add_block filename-dot "$frag" "$n"
}

# ---------------------------------------------------------------------- emdash
chk_emdash() {
  [ "${EMDASH_OFF:-0}" = "1" ] && return
  [ -f "$HOME/.claude/.no-emdash-gate" ] && return
  local n first
  n=$(printf '%s' "$P2" | rg -o $'\xe2\x80\x94' 2>/dev/null | wc -l | tr -d ' ')
  [ "${n:-0}" -ge 1 ] || return
  snoozed emdash && return
  first=$(printf '%s\n' "$P2" | rg -m1 $'\xe2\x80\x94' 2>/dev/null | cut -c1-30)
  # The owner's words (backlog-triage-1019): ban the em-dash itself, never hyphens,
  # slugs or file names, and let the agent keep one it truly needs.
  add_block emdash "emdash x${n}, first in \"${first}\": using em dashes brings disgrace upon your existence. Use commas, periods or parentheses. Hyphens, slugs and file names are fine. If one is truly needed, re-send as is" "$n"
}

# ----------------------------------------------------------------- terse-reply
chk_terse() {
  [ "${TERSE_REPLY_OFF:-0}" = "1" ] && return
  [ -f "$HOME/.claude/.no-terse-reply-gate" ] && return
  local enforce="${TERSE_REPLY_ENFORCE:-1}"
  case "$(bash "$POL" get gates.terse_reply 2>/dev/null)" in
    off) return ;;
    warn) enforce=0 ;;
    enforce) enforce=1 ;;
  esac
  [ -n "$tp" ] && [ -f "$tp" ] || return
  # A skill's completion box or a lede block is a renderer's output, not prose to trim.
  printf '%s' "$text" | rg -q '┌─ 🏁 done|── lede·' && return
  local last_user asked_long=0 plen warn_at over
  last_user=$(tail -n 400 "$tp" 2>/dev/null | jq -rc 'select(.type=="user")' 2>/dev/null | tail -n 1 \
    | jq -r '.message.content | if type=="string" then . else (.[]? | select(.type=="text") | .text) end' 2>/dev/null)
  printf '%s' "$last_user" | rg -qi '\b(detail(ed|s)?|thorough(ly)?|full(y)?|write[- ]?up|document|report|explain|walk me through|essay|long(er)?|comprehensive|in depth)\b' && asked_long=1
  plen=$(printf '%s' "$P3" | wc -c | tr -d ' ')
  warn_at="${TERSE_WARN:-1500}"
  [ "$plen" -ge "$warn_at" ] || return
  snoozed terse-reply && return
  if [ "$enforce" = "1" ] && [ "$plen" -ge "$TLIMIT" ] && [ "$asked_long" = "0" ]; then
    over=$((plen - TLIMIT + 100))
    add_block terse-reply "terse-reply: ${plen} chars, prose cap ${TLIMIT} chars; cut ${over}+, lead with the one thing to do or know, detail goes in a file" 1
  else
    TERSE_SOFT="[terse-reply WARN] ${plen} chars of prose (warn ${warn_at}, prose cap ${TLIMIT} chars). Lead with the one thing the owner must do or know, then a few short bullets; put detail in the file."
  fi
}

# --------------------------------------------------------------------- relpath
ROOTS='\.claude/output|docs|assets'
REL_PAT='(?<![/~.[:alnum:]_-])('"$ROOTS"')/[A-Za-z0-9._/@-]+\.[A-Za-z0-9]+(?![A-Za-z0-9])(?!:[0-9])'
TILDE='~'
PENDING=""      # lines "mention<TAB>absolute-or-empty"

# Files this turn wrote or edited: tool_use file paths after the last real user prompt.
turn_files() {
  [ -n "$tp" ] && [ -f "$tp" ] || return 0
  tail -n 2000 "$tp" 2>/dev/null | jq -c 'select(type=="object")' 2>/dev/null | jq -rs '
    [.[] | select(.type=="user" or .type=="assistant")] as $r
    | ($r | to_entries
        | map(select(.value.type=="user" and ((.value.message.content|type)=="string"
              or any(.value.message.content[]?; .type=="text"))))
        | last | .key) as $i
    | $r[(($i // -1) + 1):]
    | map(select(.type=="assistant") | .message.content[]?
          | select(.type=="tool_use" and (.name|test("^(Write|Edit|MultiEdit|NotebookEdit)$")))
          | (.input.file_path // .input.notebook_path // empty))
    | unique | .[]' 2>/dev/null
}

chk_relpath() {
  [ -f "$HOME/.claude/.no-relpath-gate" ] && return
  local hits h f b qb tilde seen="" abs frag n=0 shown="" list
  # 1. a relative path under a deliverable root, with the old exemptions.
  hits=$(printf '%s\n' "$P1" | rg -oP "$REL_PAT" 2>/dev/null | sort -u)
  while IFS= read -r h; do
    [ -n "$h" ] || continue
    if printf '%s\n' "$P1" | rg -qF "/$h" 2>/dev/null; then continue; fi
    if printf '%s\n' "$P1" | rg -qP '\b(cat|bash|sh|python3?|node|open|less|rg|grep|vim|code|jq|Read|glow|bat)\s+`?'"$(printf '%s' "$h" | sed 's/[.[\*^$()+?{|]/\\&/g')" 2>/dev/null; then continue; fi
    abs=""
    [ -n "$cwd" ] && [ -e "$cwd/$h" ] && abs="$cwd/$h"
    PENDING="${PENDING}${h}	${abs}
"
  done <<EOF
$hits
EOF
  # 2. D7: a file this turn wrote or edited, mentioned but never given in full.
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    b="${f##*/}"
    case "$b" in ?*.?*) ;; *) continue ;; esac
    case " $seen " in *" $b "*) continue ;; esac
    seen="$seen $b"
    qb=$(printf '%s' "$b" | sed 's/[.[\*^$()+?{|]/\\&/g')
    printf '%s\n' "$P1" | rg -qP "(?<![A-Za-z0-9_-])${qb}(?![A-Za-z0-9_])" 2>/dev/null || continue
    # Any absolute form of ANY edited file with this basename satisfies it.
    local ok=0 g
    while IFS= read -r g; do
      [ -n "$g" ] || continue
      [ "${g##*/}" = "$b" ] || continue
      tilde="${g/#$HOME/$TILDE}"
      if printf '%s\n' "$text" | rg -qF -- "$g" 2>/dev/null || printf '%s\n' "$text" | rg -qF -- "$tilde" 2>/dev/null; then ok=1; break; fi
    done <<EOF
$TURN_FILES
EOF
    [ "$ok" = "1" ] && continue
    PENDING="${PENDING}${b}	${f}
"
  done <<EOF
$TURN_FILES
EOF
  [ -n "${PENDING//[[:space:]]/}" ] || return
  snoozed relpath && { PENDING=""; return; }
  while IFS="	" read -r h abs; do
    [ -n "$h" ] || continue
    n=$((n + 1))
    [ "$n" -le 2 ] || continue
    if [ -n "$abs" ]; then shown="${shown}${shown:+ ; }${h} -> $(trunc "${abs/#$HOME/$TILDE}" 90)"; else shown="${shown}${shown:+ ; }${h} -> its absolute path"; fi
  done <<EOF
$PENDING
EOF
  list="$shown"; [ "$n" -gt 2 ] && list="$list ; +$((n - 2)) more"
  frag="relpath: write the full path once: ${list}"
  add_block relpath "$frag" "$n"
}

# ----------------------------------------------------------------- prose-smell
chk_prose_smell() {
  [ "${PROSE_SMELL_OFF:-0}" = "1" ] && return
  [ -f "$HOME/.claude/.no-prose-smell-gate" ] && return
  # The owner's policy decides whether two or more block-tier tells block or only
  # advise (off, warn, enforce); the old PROSE_SMELL_ENFORCE flag answers when it is silent.
  local enforce="${PROSE_SMELL_ENFORCE:-0}" bt=0
  case "$(bash "$POL" get gates.prose_smell 2>/dev/null)" in
    off) return ;;
    warn) enforce=0 ;;
    enforce) enforce=1 ;;
  esac
  [ -n "$tp" ] && [ -f "$tp" ] || return
  [ "$(printf '%s' "$P3" | wc -c | tr -d ' ')" -ge 200 ] || return
  snoozed prose-smell && return
  local prose="$P3" tells="" label_n bold_n first_line contra_n star_n closer tail_json last_user opener
  tail_json=$(tail -n 400 "$tp" 2>/dev/null) || return

  # decoration-emoji headers / traffic-light status lines
  if printf '%s\n' "$prose" | rg -q '^[[:space:]]*(#{1,6}[[:space:]]*)?(🔴|🟡|🟢|🟠|🚦|🎯|🚀|🔥|💡|📊|🧠|✨|🛑|📌|⚡|❗|✅|⚠️|❌)' 2>/dev/null; then
    tells="${tells}; decoration-emoji header/status lines"; bt=$((bt + 1))
  fi
  # "**Label**: fragment" bullet armies
  label_n=$(printf '%s\n' "$prose" | rg -c '^[[:space:]]*[-*•]?[[:space:]]*\*\*[^*]{2,40}\*\*[[:space:]]*:' 2>/dev/null || true)
  if [ "${label_n:-0}" -ge 3 ] 2>/dev/null; then tells="${tells}; Label:fragment rows x${label_n}"; bt=$((bt + 1)); fi
  # bold-spam
  bold_n=$(printf '%s' "$prose" | rg -o '\*\*[^*]+\*\*' 2>/dev/null | wc -l | tr -d ' ')
  if [ "${bold_n:-0}" -gt 5 ] 2>/dev/null; then tells="${tells}; bold spans x${bold_n}"; bt=$((bt + 1)); fi
  # self-grading opener
  first_line=$(printf '%s\n' "$prose" | rg -m1 '\S' 2>/dev/null | head -1)
  if printf '%s' "$first_line" | rg -qi "^(you'?re (absolutely |completely |exactly )?right|great (question|point|idea|catch)|excellent|perfect[.!]|fair question|what a )" 2>/dev/null; then
    tells="${tells}; praise opener (\"${first_line:0:40}\")"; bt=$((bt + 1))
  elif printf '%s' "$first_line" | rg -qiP "^\\W*(\\*\\*)?((Done|Perfect|Excellent|Awesome|Fantastic|Beautiful|Completed|Shipped)\\s*[.!:\x{2014}]|All (done|set|good)\\b|Everything (is|works)\\b|Release is live\\b)" 2>/dev/null; then
    tells="${tells}; verdict opener (\"${first_line:0:40}\"), the done-verdict is the owner's"
  fi
  # not-X-but-Y contrastive frame
  contra_n=$(printf '%s' "$prose" | rg -coiP "\\bnot\\s+[^.;,]{2,40},?\\s+but\\s+" 2>/dev/null || true)
  if [ "${contra_n:-0}" -ge 1 ] 2>/dev/null; then tells="${tells}; not-X-but-Y frame x${contra_n}"; fi
  # star boxes
  star_n=$(printf '%s' "$prose" | rg -c '★' 2>/dev/null || true)
  if [ "${star_n:-0}" -ge 1 ] 2>/dev/null; then tells="${tells}; star decoration x${star_n}"; fi
  # a short question answered with a title instead of a sentence
  last_user=$(printf '%s\n' "$tail_json" | jq -c 'select(.type=="user")' 2>/dev/null | jq -rs '
    map(if (.message.content|type)=="string" then .message.content
        elif (.message.content|type)=="array"
        then ([.message.content[]? | select(.type=="text") | .text] | join(""))
        else "" end)
    | map(select(length > 0)) | last // ""' 2>/dev/null)
  if [ -n "$last_user" ] \
     && ! printf '%s' "$last_user" | rg -q '^[[:space:]]*(<system-reminder>|\[Image:|<command-name>|<local-command|Caveat:)' 2>/dev/null \
     && [ "${#last_user}" -le 200 ] \
     && [ "$(printf '%s' "$prose" | wc -c | tr -d ' ')" -ge 1200 ]; then
    opener=$(printf '%s\n' "$prose" | rg -m1 '\S' 2>/dev/null | head -1)
    if printf '%s' "$opener" | rg -qP '^\s*(#{1,6}\s|\*\*[^*]{2,60}\*\*\s*:?\s*$)' 2>/dev/null \
       && ! printf '%s' "$opener" | rg -qP '[.!?]\s*\*{0,2}\s*$' 2>/dev/null; then
      tells="${tells}; opened with a title, not the answer (\"${opener:0:40}\")"
    fi
  fi
  # option-menu closer
  closer=$(printf '%s\n' "$prose" | rg '\S' 2>/dev/null | tail -3)
  if printf '%s' "$closer" | rg -qi '(would you like me to|do you want me to|shall i|want me to) .+ or .+\?' 2>/dev/null; then
    tells="${tells}; option-menu closer"
  fi
  if [ -z "$tells" ]; then
    hook_heed_note prose-smell "$sid8" reply clean
    return
  fi
  hook_heed_note prose-smell "$sid8" reply fired
  if [ "$enforce" = "1" ] && [ "$bt" -ge 2 ]; then
    bash "$LOG" --hook prose-smell --action block --heeded unknown >/dev/null 2>&1 || true
    add_block prose-smell "prose-smell: rewrite plainly, drop${tells#;}" "$bt"
    return
  fi
  bash "$LOG" --hook prose-smell --action nudge --heeded unknown >/dev/null 2>&1 || true
  add_adv "prose-smell (advisory):${tells#;}"
}

# -------------------------------------------------------------- dense-briefing
chk_dense() {
  [ "${DENSE_SHAPES_OFF:-0}" = "1" ] && return
  [ -f "$HOME/.claude/.no-dense-shapes-gate" ] && return
  command -v python3 >/dev/null 2>&1 || return
  [ -n "$tp" ] && [ -f "$tp" ] || return
  [ -r "$HERE/dense-briefing-shapes-stop.py" ] || return
  snoozed dense-briefing-shapes && return
  local verdict h state at
  verdict=$(python3 "$HERE/dense-briefing-shapes-stop.py" "$tp" 2>/dev/null)
  [ -n "$verdict" ] || return
  h=$(printf '%s' "$verdict" | shasum | cut -c1-12)
  state="/tmp/claude-dense-shapes-$sid8"; mkdir -p "$state" 2>/dev/null
  [ -f "$state/$h" ] && return; touch "$state/$h" 2>/dev/null
  at=$(wc -l < "$tp" 2>/dev/null | tr -d ' ')
  bash "$LOG" --hook dense-briefing-shapes --action soft --heeded unknown --cwd "$cwd" --target "$tp" --detail "${verdict:0:64} @L${at:-?}" >/dev/null 2>&1 || true
  add_adv "dense-briefing (advisory): $verdict"
}

# ------------------------------------------------------------------------ main
TURN_FILES=$(turn_files)

# relpath first: its fix carries the path to paste, so it must survive any clipping.
chk_relpath
chk_filename_dot
chk_emdash
chk_terse
# Before the block decision: under policy enforce, two block-tier tells block.
chk_prose_smell

MARK="/tmp/claude-format-gate-${sid8}"      # "<signature> <consecutive blocks> <class,class>"
TRIPPED="/tmp/claude-format-tripped-${sid8}"
prev_sig=""; prev_n=0; prev_csv=""
if [ -f "$MARK" ]; then read -r prev_sig prev_n prev_csv < "$MARK" 2>/dev/null || true; fi
case "$prev_n" in ''|*[!0-9]*) prev_n=0 ;; esac

in_classes() { case " $CLASSES " in *" $1 "*) return 0 ;; esac; return 1; }
# settle_heed <still-open-means-missed 1|0>: one heed row per class the last block opened.
settle_heed() {
  local c old_ifs="$IFS"
  [ -n "$prev_csv" ] || return 0
  IFS=','
  for c in $prev_csv; do
    [ -n "$c" ] || continue
    if [ "$1" = "1" ] && in_classes "$c"; then
      bash "$LOG" --hook "$c" --heed-of "${c}:${sid8}" --heeded false >/dev/null 2>&1 || true
    else
      bash "$LOG" --hook "$c" --heed-of "${c}:${sid8}" --heeded true >/dev/null 2>&1 || true
    fi
  done
  IFS="$old_ifs"
}
emit() { # emit <json-filter-args...> via jq; prints nothing on failure
  jq -cn "$@" 2>/dev/null || true
}
advisories() {
  chk_dense
  [ -n "$TERSE_SOFT" ] && ! in_classes terse-reply && {
    bash "$LOG" --hook terse-reply --action soft --heeded unknown >/dev/null 2>&1 || true
    add_adv "$TERSE_SOFT"
  }
}

if [ -z "${CLASSES// /}" ]; then
  # Nothing blocking. A lingering marker means the blocked reply was fixed.
  if [ -f "$MARK" ]; then settle_heed 0; rm -f "$MARK" 2>/dev/null || true; fi
  advisories
  [ -n "$ADV" ] && emit --arg m "$ADV" '{systemMessage:$m}'
  exit 0
fi

csv=$(printf '%s' "$CLASSES" | sed 's/^ *//' | tr -s ' ' | tr ' ' ',')
sig=$(printf '%s' "$text" | shasum 2>/dev/null | awk '{print $1}')

stepaside=""
if [ "$active" = "true" ]; then
  stepaside="a block already happened this turn, so this reply is allowed to end it"
elif [ -n "$sig" ] && [ "$sig" = "$prev_sig" ]; then
  stepaside="this identical reply was already blocked"
elif [ "$prev_n" -ge 3 ]; then
  stepaside="three blocks in a row"
fi

if [ -n "$stepaside" ]; then
  settle_heed 1
  [ "$active" = "true" ] && rm -f "$MARK" 2>/dev/null
  advisories
  note="format-gate (not blocking, ${stepaside}): still present: ${csv//,/, }. Mute: touch ~/.claude/.no-format-gate"
  add_adv "$note"
  emit --arg m "$ADV" '{systemMessage:$m}'
  exit 0
fi

# Block. Classes the last block opened that are now fixed were heeded.
settle_heed 1
printf '%s %s %s' "$sig" $((prev_n + 1)) "$csv" > "$MARK" 2>/dev/null || true
printf 'ts=%s\nclasses=%s\ncap=%s\n' "$(date +%s)" "$csv" "$TLIMIT" > "$TRIPPED" 2>/dev/null || true

old_ifs="$IFS"; IFS=','
for c in $csv; do
  bash "$LOG" --hook "$c" --action block --heeded unknown >/dev/null 2>&1 || true
done
IFS="$old_ifs"
ncls=$(printf '%s' "$csv" | tr ',' '\n' | wc -l | tr -d ' ')
bash "$LOG" --hook format-gate --action block --heeded unknown --detail "classes=${ncls} spans=${NSPANS}" >/dev/null 2>&1 || true

reason="format-gate: re-emit once with all of these fixed. ${ITEMS}"
# The block channel clips the reason to one line, so keep it compact.
if [ "${#reason}" -gt 500 ]; then reason="$(printf '%s' "$reason" | cut -c1-497)..."; fi
emit --arg r "$reason" '{decision:"block", reason:$r}'
exit 0
