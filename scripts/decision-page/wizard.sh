#!/usr/bin/env bash
# wizard.sh — answer a decision page in the terminal instead of the browser.
#
# Same page, same config.json, same answer string, same POST endpoint the
# browser's Submit button uses. The only difference is the surface: this one
# stays inside the terminal, which matters for a session running fullscreen
# where opening a browser is a context switch.
#
# It is deliberately NOT a second source of truth. It reads the page the
# authoring agent already wrote and verified, and it submits through
# /_submit/<slug> so the server still writes .answer.json, clears the pending
# marker, and fires the origin notification. A page answered here and a page
# answered in the browser are indistinguishable downstream.
#
# usage: wizard.sh <slug> [--dry-run]
#          --dry-run   compose and print the answer string, submit nothing
set -uo pipefail

TUI="$HOME/.claude/scripts/tui"
# shellcheck source=/dev/null
. "$TUI/colors.sh"; . "$TUI/tty.sh"; . "$TUI/require.sh"; . "$TUI/pick.sh"
tui_colors_init

SLUG="${1:-}"; shift 2>/dev/null || true
DRY=0; PREVIEW=0
for a in "$@"; do
  [ "$a" = "--dry-run" ] && DRY=1
  [ "$a" = "--preview" ] && PREVIEW=1
done
[ -n "$SLUG" ] || { echo "usage: wizard.sh <slug> [--dry-run]" >&2; exit 2; }

# Real separator BYTES. Every downstream tool here (tr, awk) is the BSD build,
# which does not read \xNN escapes and would otherwise translate the literal
# characters instead, silently eating every "e" in a label.
US=$'\x1f'   # between fields of one option
RS=$'\x1e'   # between options
REG="$HOME/.claude/assets/decision-pages"
PAGE="$REG/$SLUG"
CFG="$PAGE/config.json"
[ -f "$CFG" ] || { echo "wizard: no page '$SLUG' (looked for $CFG)" >&2; exit 2; }

# One python pass produces everything the shell loop needs, tab-delimited, so the
# shell never parses JSON. Fields: id, group, question, context, then the options
# as code\x1flabel\x1frec triples joined by \x1e.
rows=$(python3 - "$CFG" <<'PY'
import json, sys
cfg = json.load(open(sys.argv[1]))
groups = cfg.get("groups") or {}
for d in cfg.get("decisions") or []:
    opts = []
    for o in d.get("options") or []:
        opts.append("\x1f".join([o.get("code",""), o.get("label",""), "1" if o.get("rec") else "0"]))
    print("\t".join([
        d.get("id",""),
        d.get("group",""),
        (groups.get(d.get("group",""), {}) or {}).get("context",""),
        d.get("question",""),
        d.get("context",""),
        "\x1e".join(opts),
    ]))
PY
) || { echo "wizard: could not read $CFG" >&2; exit 2; }

[ -n "$rows" ] || { echo "wizard: page '$SLUG' has no decisions" >&2; exit 2; }
total=$(printf '%s\n' "$rows" | wc -l | tr -d ' ')
header=$(python3 -c 'import json,sys;print((json.load(open(sys.argv[1])).get("copyHeader") or sys.argv[2]))' "$CFG" "$SLUG")
title=$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1])).get("title") or "")' "$CFG")

W=$(( ${COLUMNS:-100} > 100 ? 96 : ${COLUMNS:-100} - 4 ))
wrap() {  # wrap <indent> <text>   (always ends with a newline)
  local ind="$1"; shift
  printf '%s\n' "$*" | fold -s -w "$(( W > 20 ? W : 76 ))" | sed "s/^/$ind/"
}
fit() {   # fit <width> <text>  — one line, ellipsis when it will not fit
  local w="$1"; shift
  local t="$*"
  if [ "${#t}" -le "$w" ]; then printf '%s' "$t"
  else printf '%s…' "${t:0:$((w-1))}"; fi
}

if [ "$PREVIEW" = 1 ]; then
  # Show every frame the interactive walk would draw, without prompting for any
  # of them. This exists because "run this command" is not the same as showing
  # someone the thing: the owner asked twice before I understood that.
  printf '\n%s\n' "$title"
  printf 'Enter takes the recommendation. Esc on any row keeps it too.\n'
  n=0; lastg=""
  while IFS=$'\t' read -r id group gctx question qctx optblob; do
    n=$((n+1))
    if [ "$group" != "$lastg" ] && [ -n "$group" ]; then
      printf '\n── %s ──\n' "$group"
      [ -n "$gctx" ] && wrap "  " "$gctx"
      lastg="$group"
    fi
    printf '\n[%d/%d] %s\n' "$n" "$total" "$question"
    [ -n "$qctx" ] && wrap "      " "$qctx"
    while IFS= read -r opt; do
      [ -n "$opt" ] || continue
      ocode=${opt%%"$US"*}; rest=${opt#*"$US"}
      olabel=${rest%%"$US"*}; orec=${rest##*"$US"}
      mark=''; [ "$orec" = "1" ] && mark='  ‹recommended›'
      printf '      %s) %s%s\n' "$ocode" "$(fit $(( W - 22 )) "$olabel")" "$mark"
    done <<< "$(printf '%s' "$optblob" | tr "$RS" '\n')"
    printf '      %s> ▏\n' "$id"
  done <<< "$rows"
  printf '\n      add a note on <id>? [y/N]      (asked once per row, opt-in)\n'
  printf '      anything the form could not hold? [y/N]\n'
  printf '\n── the answer ──\n%s:\n' "$header"
  printf '%s\n' "$(printf '%s\n' "$rows" | awk -F'\t' -v U="$US" -v R="$RS" '{
    n=split($6,o,R); for(i=1;i<=n;i++){split(o[i],f,U); if(f[3]=="1") printf "%s%s ", $1, f[1]} }' | sed 's/ $//')"
  printf '\n      send this to the session? [y/N]\n'
  exit 0
fi

if ! tui_have_tty; then
  # Headless is not a failure, it is the all-recommended answer. Print it rather
  # than hanging on a picker nobody can see.
  echo "wizard: no tty; composing the all-recommended answer without prompting" >&2
  picks=$(printf '%s\n' "$rows" | awk -F'\t' -v RS_UNIT="$US" -v RS_REC="$RS" '{
    n=split($6, o, RS_REC); for (i=1;i<=n;i++) { split(o[i], f, RS_UNIT);
      if (f[3]=="1") printf "%s%s ", $1, f[1] } }')
  printf '%s:\n%s\n' "$header" "${picks% }"
  exit 0
fi

printf '\n%s%s%s\n' "${TUI_BOLD:-}" "$title" "${TUI_RESET:-}"
printf '%sEnter takes my recommendation. Esc on any row keeps it too.%s\n' "${TUI_DIM:-}" "${TUI_RESET:-}"

answers=""; notes=""; i=0; lastgroup=""
while IFS=$'\t' read -r id group gctx question qctx optblob; do
  i=$((i+1))
  if [ "$group" != "$lastgroup" ] && [ -n "$group" ]; then
    printf '\n%s── %s ──%s\n' "${TUI_CYAN:-}" "$group" "${TUI_RESET:-}"
    [ -n "$gctx" ] && wrap "  ${TUI_DIM:-}" "$gctx" && printf '%s' "${TUI_RESET:-}"
    lastgroup="$group"
  fi
  printf '\n%s[%d/%d] %s%s\n' "${TUI_BOLD:-}" "$i" "$total" "$question" "${TUI_RESET:-}"
  [ -n "$qctx" ] && { wrap "      ${TUI_DIM:-}" "$qctx"; printf '%s' "${TUI_RESET:-}"; }

  # code<TAB>label for tui_pick_key; the recommended row is marked and sorted first
  menu=$(printf '%s' "$optblob" | tr "$RS" '\n' | awk -F"$US" -v R="${TUI_GREEN:-}" -v Z="${TUI_RESET:-}" '
    { if ($3=="1") rec = $1 "\t" $2 "  " R "(recommended)" Z; else rest = rest $1 "\t" $2 "\n" }
    END { if (rec) print rec; printf "%s", rest }')
  pick=$(printf '%s\n' "$menu" | tui_pick_key --prompt "$id> " --non-tty first 2>/dev/null || true)
  if [ -z "$pick" ]; then
    pick=$(printf '%s' "$optblob" | tr "$RS" '\n' | awk -F"$US" '$3=="1"{print $1; exit}')
    printf '      %skept the recommendation: %s%s\n' "${TUI_DIM:-}" "$pick" "${TUI_RESET:-}"
  fi
  answers="$answers $id$pick"

  # a note is opt-in per row, never a required field
  if tui_confirm "      add a note on $id?" 2>/dev/null; then
    n=''; tui_read_tty -p "      $id note: " n || n=''
    [ -n "$n" ] && notes="$notes
$id note: $n"
  fi
done <<< "$rows"

end=''
if tui_confirm $'\nanything the form could not hold?' 2>/dev/null; then
  tui_read_tty -p "notes: " end || end=''
fi

answer="$header:
${answers# }"
[ -n "$notes" ] && answer="$answer$notes"
[ -n "$end" ] && answer="$answer
notes:
$end"

printf '\n%s── the answer ──%s\n%s\n\n' "${TUI_CYAN:-}" "${TUI_RESET:-}" "$answer"

if [ "$DRY" = 1 ]; then
  echo "(dry run: nothing submitted)"
  exit 0
fi
if ! tui_confirm "send this to the session?"; then
  echo "not sent. Re-run when ready, or answer in the browser: http://localhost:5197/$SLUG/"
  exit 1
fi

code=$(curl -s -o /dev/null -w '%{http_code}' -X POST \
  -H 'Content-Type: application/json' \
  --data "$(python3 -c 'import json,sys;print(json.dumps({"answer":sys.stdin.read()}))' <<< "$answer")" \
  "http://localhost:5197/_submit/$SLUG" 2>/dev/null)
if [ "$code" = "200" ]; then
  printf '%ssent.%s The session picks it up the same way it would a browser Submit.\n' "${TUI_GREEN:-}" "${TUI_RESET:-}"
else
  printf '%scould not reach the page server (HTTP %s).%s Paste this into the chat instead:\n\n%s\n' \
    "${TUI_YELLOW:-}" "${code:-000}" "${TUI_RESET:-}" "$answer"
  exit 1
fi
