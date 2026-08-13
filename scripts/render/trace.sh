#!/bin/bash
# Renders a session trace: the sealed record a /core-dump leaves behind, and the
# briefing /catchup reads back from it. One visual language, two rites.
#
# Usage:
#   trace.sh DATA.json [--kind dump|catchup] [--theme a|b|c|random] [--width N]
#
# Three regalia are kept and one is chosen at random per render, so the trace
# stays distinctive without a single costume going stale. TRACE_THEME pins one.
#
# Companion to the std::claude::tui library (~/.claude/scripts/tui/, catalogue:
# `bash ~/.claude/scripts/tui/list.sh`, guide: ~/.claude/conventions/tui-handbook.md).
# That library owns input, pickers, and the TTY probe. This owns wrap-and-align
# rendering, which the library has no primitive for.
#
# Two traps this file exists to route around, both learned the hard way:
#   * gum word-wraps at its box width and restarts continuations at column 0, so
#     one long row silently reads as two list items. Every line is pre-wrapped
#     here to a width gum could never overflow.
#   * printf's %-Ns pads by BYTES while box-drawing glyphs are multi-byte, so
#     padding a framed line under-counts by one column per glyph. All padding
#     goes through pad(), which measures characters.
set -o pipefail
export PATH="/opt/homebrew/bin:$PATH"

DATA=""; KIND="dump"; THEME="${TRACE_THEME:-random}"; WIDTH=""; NOSEAL=0
while [ $# -gt 0 ]; do
  case "$1" in
    --kind)  KIND="$2"; shift 2 ;;
    --theme) THEME="$2"; shift 2 ;;
    --width) WIDTH="$2"; shift 2 ;;
    # An announce ("loading this checkpoint") opens a run rather than closing
    # one, so it wants the header without the seal that says finished.
    --no-seal) NOSEAL=1; shift ;;
    -h|--help) sed -n '2,20p' "$0"; exit 0 ;;
    *) DATA="$1"; shift ;;
  esac
done
[ -n "$DATA" ] && [ -f "$DATA" ] || { echo "trace.sh: need a readable DATA.json" >&2; exit 1; }
command -v jq >/dev/null || { echo "trace.sh: jq required (brew install jq)" >&2; exit 1; }

# Width: the caller wins, else the terminal, else 80. Clamped so the layout
# neither cramps nor sprawls.
if [ -z "$WIDTH" ]; then WIDTH=$(tput cols 2>/dev/null || echo 80); fi
case "$WIDTH" in ''|*[!0-9]*) WIDTH=80 ;; esac
[ "$WIDTH" -lt 60 ] && WIDTH=60
[ "$WIDTH" -gt 100 ] && WIDTH=100
W="$WIDTH"

if [ "$THEME" = "random" ]; then
  case $((RANDOM % 3)) in 0) THEME=a ;; 1) THEME=b ;; *) THEME=c ;; esac
fi

# Colour is forced by default: gum and most tools strip it through a pipe, and a
# skill's output always goes through one, which is why the previous renderer's
# palette never once reached a human. NO_COLOR still wins.
E=$'\033'
if [ -n "${NO_COLOR:-}" ]; then
  GOLD=""; TEAL=""; RED=""; GRN=""; BLU=""; DIM=""; PARCH=""; B=""; R=""
else
  GOLD="$E[38;5;178m"; TEAL="$E[38;5;73m";  RED="$E[38;5;167m"
  GRN="$E[38;5;108m";  BLU="$E[38;5;110m"; DIM="$E[38;5;244m"
  PARCH="$E[38;5;223m"; B="$E[1m"; R="$E[0m"
fi
# catchup wears a cooler accent so a briefing is never mistaken for a dump.
ACCENT="$GOLD"; [ "$KIND" = "catchup" ] && ACCENT="$TEAL"

# OSC 8 hyperlinks stay off until confirmed to render here; Ghostty auto-links a
# plain absolute path anyway, so the fallback loses nothing.
LINKS="${TRACE_LINKS:-0}"

repeat() { local c="$1"; local n="${2:-0}"; local o=""; local i=0
  while [ "$i" -lt "$n" ]; do o="$o$c"; i=$((i+1)); done; printf '%s' "$o"; }
pad() { local t="$1"; local n="${2:-0}"; local i=${#t}; printf '%s' "$t"
  while [ "$i" -lt "$n" ]; do printf ' '; i=$((i+1)); done; }
center() {
  # Each assignment is its own statement: inside one `local` command every
  # $(( )) expands before the locals exist, so a caller's global of the same
  # name silently wins the arithmetic.
  local t="$1"
  local n="${2:-80}"
  local l=$(( (n - ${#t}) / 2 ))
  [ "$l" -lt 0 ] && l=0
  printf '%s' "$(repeat ' ' $l)$t"
}
wrap_hang() { printf '%s\n' "$1" | fold -s -w "$2" \
  | awk -v p="$(repeat ' ' "$3")" 'NR==1{print;next}{print p $0}'; }

jqa() { jq -r "$1" "$DATA" 2>/dev/null; }

# ── the regalia ──────────────────────────────────────────────────
# Themes differ only in header art, rule fill, and whether a seal closes the
# record. Everything below the header is shared.
case "$THEME" in
  a) FILL='═'; CAP='◆'; SEALED=1 ;;
  b) FILL='·'; CAP='◆'; SEALED=0 ;;
  c) FILL='─'; CAP='';  SEALED=0 ;;
esac

header() {
  local title="$1" l2="$2" l3="$3"
  case "$THEME" in
    a)
      local I=$((W-2))
      printf '%s╔%s╗%s\n' "$ACCENT" "$(repeat '═' $I)" "$R"
      printf '%s║%s%s%s║%s\n' "$ACCENT" "$B" "$(pad "$(center "◆  $title  ◆" $I)" $I)" "$ACCENT" "$R"
      printf '%s╟%s╢%s\n' "$ACCENT" "$(repeat '─' $I)" "$R"
      printf '%s║%s %s%s║%s\n' "$ACCENT" "$R" "$(pad "$l2" $((I-1)))" "$ACCENT" "$R"
      [ -n "$l3" ] && printf '%s║%s %s%s║%s\n' "$ACCENT" "$R" "$(pad "$l3" $((I-1)))" "$ACCENT" "$R"
      printf '%s╚%s╝%s\n' "$ACCENT" "$(repeat '═' $I)" "$R"
      ;;
    b)
      printf '%s◆%s◆%s\n' "$ACCENT" "$(repeat '─' $((W-2)))" "$R"
      printf '%s%s%s\n' "$ACCENT$B" "$(center "$title" $W)" "$R"
      printf '%s%s%s\n' "$DIM" "$(center "$l2" $W)" "$R"
      [ -n "$l3" ] && printf '%s%s%s\n' "$DIM" "$(center "$l3" $W)" "$R"
      printf '%s◆%s◆%s\n' "$ACCENT" "$(repeat '─' $((W-2)))" "$R"
      ;;
    c)
      # The title column is measured, not fixed: a long title would otherwise
      # butt straight against the metadata with no gap.
      local tw=$(( ${#title} + 2 ))
      [ "$tw" -lt 14 ] && tw=14
      printf '%s%s%s\n' "$ACCENT" "$(repeat '━' $W)" "$R"
      printf '  %s%s%s%s%s\n' "$B" "$(pad "$title" $tw)" "$R$DIM" "$l2" "$R"
      [ -n "$l3" ] && printf '  %s%s%s%s\n' "$(pad '' $tw)" "$DIM" "$l3" "$R"
      printf '%s%s%s\n' "$ACCENT" "$(repeat '━' $W)" "$R"
      ;;
  esac
}

seal() {
  [ "$NOSEAL" = "1" ] && return 0
  local text="$1"
  case "$THEME" in
    a)
      local I=$((W-2))
      printf '%s╔%s╗%s\n' "$ACCENT" "$(repeat '═' $I)" "$R"
      printf '%s║%s%s%s║%s\n' "$ACCENT" "$B" "$(pad "$(center "◆  $text  ◆" $I)" $I)" "$ACCENT" "$R"
      printf '%s╚%s╝%s\n' "$ACCENT" "$(repeat '═' $I)" "$R" ;;
    b)
      # The closing rule matters most on a bare receipt (header + seal, no
      # body): without it the seal reads as an unclosed box, not a footer.
      printf '%s◆%s◆%s\n' "$ACCENT" "$(repeat '─' $((W-2)))" "$R"
      printf '%s%s%s\n' "$DIM" "$(center "$text" $W)" "$R"
      printf '%s◆%s◆%s\n' "$ACCENT" "$(repeat '─' $((W-2)))" "$R" ;;
    c)
      printf '%s%s%s\n' "$DIM" "$(repeat '─' $W)" "$R"
      printf '  %s%s%s\n' "$DIM" "$text" "$R"
      printf '%s%s%s\n' "$DIM" "$(repeat '─' $W)" "$R" ;;
  esac
}

# Section rules are uniform by owner ruling: severity is carried by hue and by
# the item marks, never by a heavier bar. Under NO_COLOR the section word and
# the item glyph remain the signal.
rule() {
  local glyph="$1" label="$2" gloss="$3" count="$4" col="$5"
  local head="$glyph $label"
  [ -n "$gloss" ] && head="$head ($gloss)"
  local n
  if [ -n "$count" ]; then
    n=$(( W - ${#head} - ${#count} - 2 )); [ "$n" -lt 1 ] && n=1
    printf '%s%s%s%s %s%s%s %s%s%s\n' "$col" "$B" "$head" "$R" "$DIM" "$(repeat "$FILL" $n)" "$R" "$col" "$count" "$R"
  else
    n=$(( W - ${#head} - 1 )); [ "$n" -lt 1 ] && n=1
    printf '%s%s%s%s %s%s%s\n' "$col" "$B" "$head" "$R" "$DIM" "$(repeat "$FILL" $n)" "$R"
  fi
}

item() { # glyph, colour, text
  local first=1
  wrap_hang "$3" $((W - 6)) 0 | while IFS= read -r ln; do
    if [ "$first" = 1 ]; then printf '  %s%s%s %s\n' "$2" "$1" "$R" "$ln"; first=0
    else printf '    %s\n' "$ln"; fi
  done
}
flow() { wrap_hang "$1" $((W - 4)) 2 | sed 's/^/  /'; }

link() { # display, absolute target
  if [ "$LINKS" = "1" ]; then printf '%s]8;;file://%s%s%s%s]8;;%s' "$E" "$2" "$E\\" "$1" "$E" "$E\\"
  else printf '%s' "$1"; fi
}

section_list() { # jq path, glyph, colour
  local n; n=$(jqa "$1 | length"); [ "$n" = "null" ] || [ -z "$n" ] && n=0
  [ "$n" -eq 0 ] && return 1
  return 0
}

# ── render ───────────────────────────────────────────────────────
SID=$(jqa '.session_id // "unknown"')
TS=$(jqa '.timestamp // ""')
STATUS=$(jqa '.status // ""')
ROOT=$(jqa '.project_root // ""')
CKPT=$(jqa '.checkpoint_path // ""')

echo
if [ "$KIND" = "catchup" ]; then
  header "C A T C H U P" "$SID  ·  $TS  ·  $STATUS" "${ROOT:+$ROOT}"
else
  header "C O R E · D U M P" "$SID  ·  $TS  ·  $STATUS" "${ROOT:+$ROOT}"
fi
echo

# A briefing is a different document from a record: three tiers ordered by what
# the reader must DO with them, not six sections of what happened.
kv() { # label, value, colour — omitted entirely when the value is empty
  [ -z "$2" ] && return 0
  local lw=13
  wrap_hang "$2" $((W - lw - 4)) 0 | { first=1; while IFS= read -r ln; do
    if [ "$first" = 1 ]; then printf '  %s%s%s %s\n' "$3" "$(pad "$1" $lw)" "$R" "$ln"; first=0
    else printf '  %s %s\n' "$(pad '' $lw)" "$ln"; fi; done; }
}
kvlist() { # label, jq path, colour — one row per element, label on the first
  local n; n=$(jqa "$2 | length"); [ "$n" = "null" ] && n=0
  [ "$n" -eq 0 ] && return 0
  local lbl="$1"
  jqa "$2[]" | while IFS= read -r v; do kv "$lbl" "$v" "$3"; lbl=""; done
}

if [ "$KIND" = "catchup" ]; then
  # A tier prints only when it holds something, matching the dump side where an
  # empty section vanishes rather than leaving a bare rule.
  has() { local t; t=$(jqa "$1 // empty"); [ -n "$t" ] && return 0; return 1; }
  hasl() { local n; n=$(jqa "$1 | length"); [ "$n" = "null" ] && n=0; [ "$n" -gt 0 ]; }
  if has '.next_action' || has '.blocked_on' || hasl '.constraints' \
     || hasl '.caveats' || hasl '.expired_auth' || hasl '.decaying'; then
  rule "◆" "NOW" "act from this" "" "$ACCENT"
  kv "Next action" "$(jqa '.next_action // ""')" "$B"
  kv "Blocked on"  "$(jqa '.blocked_on // ""')" "$RED"
  # Constraints and caveats are reproduced verbatim. Paraphrasing them here is
  # how a constraint quietly stops binding between one session and the next.
  kvlist "Constraints" '.constraints' "$GOLD"
  kvlist "Caveats"     '.caveats'     "$GOLD"
  kvlist "Expired auth" '.expired_auth' "$RED"
  kvlist "Decaying"    '.decaying'    "$RED"
  echo
  fi
  if hasl '.pipeline' || hasl '.drift' || hasl '.running' || hasl '.mail'; then
  rule "≡" "STATE" "what moved" "" "$DIM"
  N=$(jqa '.pipeline | length'); [ "$N" = "null" ] && N=0
  if [ "$N" -gt 0 ]; then
    lbl="Pending"
    jqa '.pipeline | to_entries[] | "\(.key+1). \(.value)"' | while IFS= read -r v; do
      kv "$lbl" "$v" "$GRN"; lbl=""
    done
  fi
  kvlist "Drift"   '.drift'   "$GOLD"
  kvlist "Running" '.running' "$GRN"
  kvlist "Mail"    '.mail'    "$BLU"
  echo
  fi
  if has '.goal' || has '.expectation' || hasl '.learnings' || hasl '.files'; then
  rule "▤" "CONTEXT" "if unfamiliar" "" "$BLU"
  kv "Goal"        "$(jqa '.goal // ""')" "$DIM"
  kv "Expectation" "$(jqa '.expectation // ""')" "$DIM"
  kvlist "Learnings" '.learnings' "$PARCH"
  N=$(jqa '.files | length'); [ "$N" = "null" ] && N=0
  if [ "$N" -gt 0 ]; then
    lbl="Key files"
    jqa '.files[] | "\(.path)  \(.change)"' | while IFS= read -r v; do kv "$lbl" "$v" "$BLU"; lbl=""; done
  fi
  echo
  fi
  seal "restored from $CKPT"
  echo
  exit 0
fi

GOAL=$(jqa '.goal // ""')
if [ -n "$GOAL" ]; then rule "◆" "DECREE" "goal" "" "$ACCENT"; flow "$GOAL"; echo; fi

N=$(jqa '.pipeline | length'); [ "$N" = "null" ] && N=0
if [ "$N" -gt 0 ]; then
  rule "▸" "DOCKET" "next" "$N open" "$GRN"
  # jq numbers the rows. A shell counter here would live in the pipeline's
  # subshell and reset every iteration, printing "1." for every item.
  jqa '.pipeline | to_entries[] | "\(.key+1)\(.value)"' | while IFS= read -r row; do
    num="${row%%$'\001'*}"; txt="${row#*$'\001'}"
    wrap_hang "$txt" $((W - 7)) 0 | { first=1; while IFS= read -r ln; do
      if [ "$first" = 1 ]; then printf '  %s%s%s.%s %s\n' "$GRN" "$B" "$num" "$R" "$ln"; first=0
      else printf '     %s\n' "$ln"; fi; done; }
  done
  echo
fi

N=$(jqa '.interrupts | length'); [ "$N" = "null" ] && N=0
if [ "$N" -gt 0 ]; then
  rule "‡" "OBJECTION" "blocked" "$N open" "$RED"
  jqa '.interrupts[]' | while IFS= read -r t; do
    case "$t" in
      WARN*|warn*) item "▲" "$GOLD" "${t#*: }" ;;
      NOTE*|note*) item "·" "$DIM" "${t#*: }" ;;
      *)           item "‡" "$RED" "${t#*: }" ;;
    esac
  done
  echo
fi

N=$(jqa '.stack_trace | length'); [ "$N" = "null" ] && N=0
if [ "$N" -gt 0 ]; then
  rule "≡" "CHRONICLE" "done" "$N" "$DIM"
  jqa '.stack_trace[]' | while IFS= read -r t; do item "·" "$DIM" "$t"; done
  echo
fi

N=$(jqa '.files | length'); [ "$N" = "null" ] && N=0
if [ "$N" -gt 0 ]; then
  rule "▤" "AMENDMENTS" "files" "$N" "$BLU"
  # Column width is measured from the longest path, never faked with a fixed
  # dot-leader run that lines nothing up.
  PW=$(jqa '[.files[].path | length] | max')
  [ "$PW" -gt $((W - 22)) ] && PW=$((W - 22))
  jqa '.files[] | "\(.path)\(.change)"' | while IFS= read -r row; do
    p="${row%%$'\001'*}"; c="${row##*$'\001'}"
    disp="$p"; [ ${#disp} -gt "$PW" ] && disp="…${disp: -$((PW-1))}"
    col="$DIM"; case "$c" in new*|New*) col="$GRN" ;; esac
    printf '  %s  %s%s%s\n' "$(pad "$(link "$disp" "${ROOT:+$ROOT/}$p")" "$PW")" "$col" "$c" "$R"
  done
  echo
fi

NW=$(jqa '.coprocessor.worked | length'); [ "$NW" = "null" ] && NW=0
NF=$(jqa '.coprocessor.failed | length'); [ "$NF" = "null" ] && NF=0
if [ $((NW + NF)) -gt 0 ]; then
  rule "✓" "COUNSEL" "learned" "$((NW + NF))" "$PARCH"
  jqa '.coprocessor.worked[]?' | while IFS= read -r t; do item "✓" "$GRN" "$t"; done
  jqa '.coprocessor.failed[]?' | while IFS= read -r t; do item "✗" "$RED" "$t"; done
  echo
fi

if [ "$KIND" = "catchup" ]; then
  seal "restored from $CKPT"
else
  seal "sealed $TS  ·  revive with /catchup"
fi
echo
