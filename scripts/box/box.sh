#!/usr/bin/env bash
# box: compose callout boxes and line-tags in the account's one dialect.
#
# The single renderer behind conventions/callout-boxes.md v3. Emoji names the
# emitter, rail weight carries severity, and every body row starts with a
# coloured marker so no line reads as loose text. Anything the owner copies
# (a command, a path) prints bare under the box, where a triple-click takes
# the whole line. Output is plain text: it is meant to be pasted into a reply
# or emitted as hook additionalContext, never styled with ANSI.
#
#   box list                     the vocabulary, the row roles and the flags
#   box <kind> --template        fill-in skeleton for that kind
#   box <kind> <name> [flags]    render a box
#   box tag <kind> "<text>"      render a line-tag (tag-tier kinds)
#
# Body text may also arrive on stdin (hook-common.sh's hook_box_kind uses
# this); stdin lines render as unmarked body text.
set -uo pipefail

# Resolve through the ~/.local/bin symlink so the vocab is found beside the
# real script, not beside the link. readlink -f is present on this macOS.
SELF=$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || printf '%s' "${BASH_SOURCE[0]}")
SELF_DIR=$(cd "$(dirname "$SELF")" && pwd)
VOCAB="${BOX_VOCAB:-$SELF_DIR/vocab.tsv}"
WIDTH="${BOX_WIDTH:-84}"

die() {
  printf 'box: %s\n' "$1" >&2
  [ -n "${2:-}" ] && printf '%s\n' "$2" >&2
  exit 1
}

# A row's role picks its marker. Every marker is a two-column emoji, so the
# label column starts at the same place on every row. The set was picked from
# a Fira Code render (owner, 2026-10-28): single-width glyphs read too small
# beside the colour dots, and 💬 / ⚖️ render faint.
role_marker() {
  case "$1" in
    next)    printf '➡️' ;;
    you)     printf '🟠' ;;
    done)    printf '🟢' ;;
    note)    printf '🟡' ;;
    blocked) printf '🔴' ;;
    info)    printf '🔵' ;;
    juror)   printf '🟣' ;;
    ref)     printf '🔗' ;;
    wait)    printf '⏳' ;;
    *)       return 1 ;;
  esac
}
ROLES="next you done note blocked info juror ref wait"

box_kinds() { awk -F'\t' '!/^#/ && $5=="box" {printf "%s ", $1}' "$VOCAB" 2>/dev/null; }
tag_kinds() { awk -F'\t' '!/^#/ && $5=="tag" {printf "%s ", $1}' "$VOCAB" 2>/dev/null; }

# vlookup <kind>: echoes "emoji<TAB>label<TAB>rail<TAB>tier", empty if unknown.
vlookup() {
  awk -F'\t' -v k="$1" '!/^#/ && $1==k {printf "%s\t%s\t%s\t%s", $2, $3, $4, $5; exit}' "$VOCAB" 2>/dev/null
}

# Display columns, not bytes: emoji and blocked-sign symbols are two columns
# wide, and bash's ${#s} cannot see that. Python's east_asian_width is the
# honest measure; the char-count fallback only runs if python3 is absent.
dwidth() {
  python3 -c '
import sys, unicodedata
w = 0
for ch in sys.argv[1]:
    if unicodedata.combining(ch) or ch in "️‍":
        continue
    w += 2 if unicodedata.east_asian_width(ch) in ("W", "F") else 1
print(w, end="")' "$1" 2>/dev/null || printf '%s' "${#1}"
}

rep() {
  local n="$1" c="$2" out='' i=0
  while [ "$i" -lt "$n" ]; do out="$out$c"; i=$((i + 1)); done
  printf '%s' "$out"
}

# wrap_indent <text> <first-prefix> <rest-prefix> <cols>: fold on word
# boundaries, the first line behind one prefix and the rest behind another,
# so a wrapped value stays under its own column. The `|| [ -n "$l" ]` keeps a
# final line that printf left without a newline.
wrap_indent() {
  local first=1
  printf '%s\n' "$1" | fold -s -w "$4" | sed 's/[[:space:]]*$//' \
  | while IFS= read -r l || [ -n "$l" ]; do
      if [ "$first" = 1 ]; then printf '%s%s\n' "$2" "$l"; first=0
      else printf '%s%s\n' "$3" "$l"; fi
    done
}

# emit_kv <pairs-joined-by-US> <rail>: two-column ledger rows, row-major.
# Keys split on the first ':'; widths computed per column so values align.
emit_kv() {
  printf '%s' "$1" | awk -v RS="$(printf '\x1f')" -v rail="$2" '
    NF {
      n++
      i = index($0, ":")
      if (i == 0) { k[n] = $0; v[n] = "" } else { k[n] = substr($0, 1, i - 1); v[n] = substr($0, i + 1) }
      sub(/^ +/, "", v[n])
    }
    END {
      for (i = 1; i <= n; i++) {
        c = (i % 2 == 1) ? 1 : 2
        if (length(k[i]) > kw[c]) kw[c] = length(k[i])
        if (length(v[i]) > vw[c]) vw[c] = length(v[i])
      }
      for (i = 1; i <= n; i += 2) {
        f1 = "%-" kw[1] "s  %-" vw[1] "s"
        line = sprintf(f1, k[i], v[i])
        if (i + 1 <= n) {
          f2 = "   %-" kw[2] "s  %s"
          line = line sprintf(f2, k[i + 1], v[i + 1])
        }
        sub(/[ \t]+$/, "", line)
        printf "%s  %s\n", rail, line
      }
    }'
}

cmd_list() {
  printf 'callout vocabulary: conventions/callout-boxes.md v3\n\n'
  awk -F'\t' '!/^#/ {printf "  %-9s %s  %-6s %-4s %s\n", $1, $2, $4, $5, $6}' "$VOCAB"
  printf '\nrow roles (marker, then the default label)\n  '
  local r
  for r in $ROLES; do printf '%s %s   ' "$(role_marker "$r")" "$r"; done
  cat <<'EOF'


compose  box <kind> <name> --row <role>[:<label>] "<text>"... [--attr "…"] [--foot "…"]
         [--copy "<line printed bare under the box>"]... [--ref <abs-path>]...
         [--count N] [--seal "…"] [--block|--light] [--width N]
         legacy: --body "…" (unmarked lines), --kv "k:v", --action "…" (= --row next)
tag      box tag <kind> "<text>"     tag-tier kinds never grow rails
skeleton box <kind> --template
rules    one marker per row · ~6 rows, past that digest and --ref the file ·
         commands and paths go under the box with --copy / --ref, never inside it
EOF
}

cmd_tag() {
  local kind="${1:-}" text="${2:-}"
  [ -n "$kind" ] && [ -n "$text" ] || die 'usage: box tag <kind> "<text>"'
  local row emoji label
  row=$(vlookup "$kind")
  [ -n "$row" ] || die "unknown kind '$kind'" "tag-tier kinds: $(tag_kinds)"
  emoji=$(printf '%s' "$row" | cut -f1)
  label=$(printf '%s' "$row" | cut -f2)
  printf '%s %s · %s\n' "$emoji" "$label" "$text"
}

cmd_template() {
  local kind="$1"
  printf 'box %s "<name>" --attr "<right-hand attribute, drop if none>" \\\n' "$kind"
  printf '  --row next "<what happens next>" \\\n'
  printf '  --row you "<what waits on the owner, drop if nothing>" \\\n'
  printf '  --row note "<caveat, drop if none>" \\\n'
  printf '  --copy "<command or path to copy, drop if none>"\n'
  printf '\nroles: %s\n' "$ROLES"
}

# render_box kind name attr count seal: reads ROWS, BODY, KV, COPIES, REFS.
render_box() {
  local kind="$1" name="$2" attr="$3" count="$4" seal="$5"
  local row emoji label rail
  row=$(vlookup "$kind")
  emoji=$(printf '%s' "$row" | cut -f1)
  label=$(printf '%s' "$row" | cut -f2)
  rail=$(printf '%s' "$row" | cut -f3)
  [ -n "${FORCE_RAIL:-}" ] && rail="$FORCE_RAIL"

  local TL H V BL
  if [ "$rail" = "heavy" ]; then TL='┏' H='━' V='┃' BL='┗'; else TL='┌' H='─' V='│' BL='└'; fi

  # A long name is shortened so the header never runs past the width; the
  # attribute on the right is the part the reader scans for.
  local tail_w=4 room
  [ -n "$attr" ] && tail_w=$(( tail_w + $(dwidth "$attr") + 4 ))
  [ -n "$count" ] && tail_w=$(( tail_w + ${#count} + 2 ))
  room=$(( WIDTH - $(dwidth "$TL$H $emoji $label · ") - tail_w - 3 ))
  if [ "$(dwidth "$name")" -gt "$room" ] && [ "$room" -gt 8 ]; then
    name="$(printf '%s' "$name" | cut -c1-$((room - 1)))…"
  fi
  local title="$emoji $label · $name"
  [ -n "$count" ] && title="$title ×$count"
  local head="$TL$H $title " fill
  if [ -n "$attr" ]; then
    fill=$(( WIDTH - $(dwidth "$head") - $(dwidth "$attr") - 4 ))
    [ "$fill" -lt 3 ] && fill=3
    printf '%s%s %s %s\n' "$head" "$(rep "$fill" "$H")" "$attr" "$H$H"
  else
    fill=$(( WIDTH - $(dwidth "$head") ))
    [ "$fill" -lt 3 ] && fill=3
    printf '%s%s\n' "$head" "$(rep "$fill" "$H")"
  fi

  # A blank rail line above and below the rows gives them room to read as a
  # list rather than a paragraph glued to the rules.
  printf '%s\n' "$V"
  if [ -n "$BODY" ]; then
    printf '%s\n' "$BODY" | while IFS= read -r l || [ -n "$l" ]; do
      if [ -n "$l" ]; then wrap_indent "$l" "$V  " "$V  " $((WIDTH - 3)); else printf '%s\n' "$V"; fi
    done
  fi
  [ -n "$KV" ] && emit_kv "$KV" "$V"

  local i n=${#ROWS[@]} lw=0 r role lab text w
  for ((i = 0; i < n; i++)); do
    lab=$(printf '%s' "${ROWS[$i]}" | cut -f2)
    w=${#lab}; [ "$w" -gt "$lw" ] && lw=$w
  done
  for ((i = 0; i < n; i++)); do
    r="${ROWS[$i]}"
    role=$(printf '%s' "$r" | cut -f1)
    lab=$(printf '%s' "$r" | cut -f2)
    text=$(printf '%s' "$r" | cut -f3-)
    local mk lead pad
    mk=$(role_marker "$role")
    lead=$(printf '%s  %s %-*s  ' "$V" "$mk" "$lw" "$lab")
    pad=$(printf '%s  %*s' "$V" $((3 + lw + 2)) '')
    wrap_indent "$text" "$lead" "$pad" $((WIDTH - 3 - 3 - lw - 2))
  done
  printf '%s\n' "$V"

  if [ -n "$seal" ]; then
    local s="$BL$H ✅ $seal "
    fill=$(( WIDTH - $(dwidth "$s") ))
    [ "$fill" -lt 3 ] && fill=3
    printf '%s%s\n' "$s" "$(rep "$fill" "$H")"
  elif [ -n "$FOOT" ]; then
    local f="$BL$H $FOOT "
    fill=$(( WIDTH - $(dwidth "$f") ))
    [ "$fill" -lt 3 ] && fill=3
    printf '%s%s\n' "$f" "$(rep "$fill" "$H")"
  else
    printf '%s%s\n' "$BL" "$(rep $((WIDTH - 1)) "$H")"
  fi

  # Copy lines and paths sit below the box with no rail, after one blank line,
  # so a triple-click in the terminal selects the command or path alone and
  # Ghostty keeps a path clickable.
  local c
  if [ ${#COPIES[@]} -gt 0 ] || [ ${#REFS[@]} -gt 0 ]; then printf '\n'; fi
  for c in ${COPIES[@]+"${COPIES[@]}"} ${REFS[@]+"${REFS[@]}"}; do
    [ -n "$c" ] && printf '%s\n' "$c"
  done
}

# ── main ────────────────────────────────────────────────────────────────────

[ -f "$VOCAB" ] || die "vocabulary not found: $VOCAB"
[ $# -ge 1 ] || { cmd_list; exit 0; }

case "$1" in
  list|-h|--help) cmd_list; exit 0 ;;
  tag) shift; cmd_tag "$@"; exit $? ;;
esac

KIND="$1"; shift
ROW=$(vlookup "$KIND")
[ -n "$ROW" ] || die "unknown kind '$KIND'" "box kinds: $(box_kinds)
tag-tier (never boxed): $(tag_kinds)"
TIER=$(printf '%s' "$ROW" | cut -f4)
if [ "$TIER" = "tag" ]; then
  EMOJI=$(printf '%s' "$ROW" | cut -f1); LABEL=$(printf '%s' "$ROW" | cut -f2)
  die "'$KIND' is tag-tier: ambient context never grows rails" \
    "paste a line-tag instead:  $EMOJI $LABEL · <your text>
or:                        box tag $KIND \"<your text>\""
fi

if [ "${1:-}" = "--template" ]; then cmd_template "$KIND"; exit 0; fi

NAME="${1:-}"; [ -n "$NAME" ] || die "usage: box $KIND <name> [flags]" "box $KIND --template shows the shape"
shift

BODY='' ATTR='' KV='' COUNT='' SEAL='' FOOT='' FORCE_RAIL=''
ROWS=()
REFS=()
COPIES=()
US=$(printf '\x1f')

# add_row <role[:label]> <text>: a row is stored as role<TAB>label<TAB>text.
add_row() {
  local spec="$1" role label
  role="${spec%%:*}"
  if [ "$spec" = "$role" ]; then label="$role"; else label="${spec#*:}"; fi
  role_marker "$role" >/dev/null || die "unknown row role '$role'" "roles: $ROLES"
  ROWS[${#ROWS[@]}]="$role	$label	$2"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --row)    add_row "${2:-}" "${3:-}"; shift 3 ;;
    --body)   BODY="${BODY:+$BODY
}${2:-}"; shift 2 ;;
    --action) add_row next "${2:-}"; shift 2 ;;
    --attr)   ATTR="${2:-}"; shift 2 ;;
    --kv)     KV="${KV:+$KV$US}${2:-}"; shift 2 ;;
    --ref)    REFS[${#REFS[@]}]="${2:-}"; shift 2 ;;
    --copy)   COPIES[${#COPIES[@]}]="${2:-}"; shift 2 ;;
    --foot)   FOOT="${2:-}"; shift 2 ;;
    --count)  COUNT="${2:-}"; shift 2 ;;
    --seal)   SEAL="${2:-}"; shift 2 ;;
    --block)  FORCE_RAIL='heavy'; shift ;;
    --light)  FORCE_RAIL='light'; shift ;;
    --width)  WIDTH="${2:-84}"; shift 2 ;;
    *) die "unknown flag '$1'" "flags: --row --body --action --attr --kv --ref --copy --foot --count --seal --block --light --width" ;;
  esac
done

# stdin mode: a pre-built body (hook_box_kind pipes here) when no flag gave one.
if [ -z "$BODY" ] && [ -z "$KV" ] && [ ${#ROWS[@]} -eq 0 ] && [ ! -t 0 ]; then
  BODY=$(cat)
fi

if [ -z "$BODY" ] && [ -z "$KV" ] && [ ${#ROWS[@]} -eq 0 ]; then
  die "nothing to render: give --row, --body or --kv, or pipe a body on stdin"
fi

render_box "$KIND" "$NAME" "$ATTR" "$COUNT" "$SEAL"
