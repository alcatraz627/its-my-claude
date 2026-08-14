#!/usr/bin/env bash
# box — compose callout boxes and line-tags in the account's one dialect.
#
# The single renderer behind conventions/callout-boxes.md v2. Emoji names the
# emitter, rail weight carries severity, the seal carries lifecycle, and refs
# (paths, ids) stay on their own unwrapped lines so the terminal keeps them
# clickable. Output is plain text: it is meant to be pasted into a reply or
# emitted as hook additionalContext, never styled with ANSI.
#
#   box list                     the vocabulary + compose recipes (start here)
#   box <kind> --template        fill-in skeleton for that kind
#   box <kind> <name> [flags]    render a box
#   box tag <kind> "<text>"      render a line-tag (tag-tier kinds)
#
# Body text may also arrive on stdin (hook-common.sh's hook_box_kind uses
# this); stdin mode wraps the body as-is and does not require --action.
set -uo pipefail

# Resolve through the ~/.local/bin symlink so the vocab is found beside the
# real script, not beside the link. readlink -f is present on this macOS.
SELF=$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || printf '%s' "${BASH_SOURCE[0]}")
SELF_DIR=$(cd "$(dirname "$SELF")" && pwd)
VOCAB="${BOX_VOCAB:-$SELF_DIR/vocab.tsv}"
WIDTH=72

die() {
  printf 'box: %s\n' "$1" >&2
  [ -n "${2:-}" ] && printf '%s\n' "$2" >&2
  exit 1
}

box_kinds() { awk -F'\t' '!/^#/ && $5=="box" {printf "%s ", $1}' "$VOCAB" 2>/dev/null; }
tag_kinds() { awk -F'\t' '!/^#/ && $5=="tag" {printf "%s ", $1}' "$VOCAB" 2>/dev/null; }

# vlookup <kind> — echoes "emoji<TAB>label<TAB>rail<TAB>tier", empty if unknown.
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

# wrap_rail <text> <rail> — fold on word boundaries behind the rail.
# The `|| [ -n "$l" ]` mirrors hook_box: without it a final line that printf
# left without a newline is silently dropped.
wrap_rail() {
  printf '%s\n' "$1" | fold -s -w $((WIDTH - 2)) | sed 's/[[:space:]]*$//' \
  | while IFS= read -r l || [ -n "$l" ]; do
      if [ -n "$l" ]; then printf '%s %s\n' "$2" "$l"; else printf '%s\n' "$2"; fi
    done
}

# emit_kv <pairs-joined-by-US> <rail> — two-column ledger rows, row-major.
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
        printf "%s %s\n", rail, line
      }
    }'
}

cmd_list() {
  printf 'callout vocabulary — conventions/callout-boxes.md v2\n\n'
  awk -F'\t' '!/^#/ {printf "  %-9s %s  %-6s %-4s %s\n", $1, $2, $4, $5, $6}' "$VOCAB"
  cat <<'EOF'

compose  box <kind> <name> --body "…" --action "…" [--ref <abs-path>]…
         [--attr "…"] [--kv "k:v"]… [--count N] [--seal "…"] [--block|--light]
tag      box tag <kind> "<text>"     tag-tier kinds never grow rails
skeleton box <kind> --template
rules    the → line is what makes it a box · body caps ~6 lines, digest +
         ▸ ref past that · paths absolute, one per line, nothing after them
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
  local kind="$1" attr=''
  case "$kind" in
    dispatch) attr='<model> · <effort>' ;;
    landing)  attr='landed <dur>' ;;
    ipc-in)   attr='reply-by <hh:mm>' ;;
    ipc-out)  attr='corr-<id>' ;;
    atone)    attr='S<sev> · <recency>' ;;
  esac
  render_box "$kind" "<name>" "<what happened, 1-6 lines>" \
    "<who does what next>" "$attr" '' '' '' "<absolute-path-or-id, drop if none>"
  printf '\nfill the placeholders; drop the rows you do not need\n'
}

# render_box kind name body action attr kv count seal ref...
render_box() {
  local kind="$1" name="$2" body="$3" action="$4" attr="$5" kv="$6" count="$7" seal="$8"
  shift 8
  local row emoji label rail
  row=$(vlookup "$kind")
  emoji=$(printf '%s' "$row" | cut -f1)
  label=$(printf '%s' "$row" | cut -f2)
  rail=$(printf '%s' "$row" | cut -f3)
  [ -n "${FORCE_RAIL:-}" ] && rail="$FORCE_RAIL"

  local TL H V BL
  if [ "$rail" = "heavy" ]; then TL='┏' H='━' V='┃' BL='┗'; else TL='┌' H='─' V='│' BL='└'; fi

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

  [ -n "$body" ] && wrap_rail "$body" "$V"
  [ -n "$kv" ] && emit_kv "$kv" "$V"
  local r
  for r in "$@"; do
    [ -n "$r" ] && printf '%s ▸ %s\n' "$V" "$r"
  done
  [ -n "$action" ] && wrap_rail "→ $action" "$V"

  if [ -n "$seal" ]; then
    local s="$BL$H ✅ $seal "
    fill=$(( WIDTH - $(dwidth "$s") ))
    [ "$fill" -lt 3 ] && fill=3
    printf '%s%s\n' "$s" "$(rep "$fill" "$H")"
  else
    printf '%s%s\n' "$BL" "$(rep $((WIDTH - 1)) "$H")"
  fi
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

BODY='' ACTION='' ATTR='' KV='' COUNT='' SEAL='' FORCE_RAIL=''
REFS=()
US=$(printf '\x1f')
while [ $# -gt 0 ]; do
  case "$1" in
    --body)   BODY="${BODY:+$BODY
}${2:-}"; shift 2 ;;
    --action) ACTION="${2:-}"; shift 2 ;;
    --attr)   ATTR="${2:-}"; shift 2 ;;
    --kv)     KV="${KV:+$KV$US}${2:-}"; shift 2 ;;
    --ref)    REFS[${#REFS[@]}]="${2:-}"; shift 2 ;;
    --count)  COUNT="${2:-}"; shift 2 ;;
    --seal)   SEAL="${2:-}"; shift 2 ;;
    --block)  FORCE_RAIL='heavy'; shift ;;
    --light)  FORCE_RAIL='light'; shift ;;
    --width)  WIDTH="${2:-72}"; shift 2 ;;
    *) die "unknown flag '$1'" "flags: --body --action --attr --kv --ref --count --seal --block --light --width" ;;
  esac
done

# stdin raw mode: a pre-built body (hook_box_kind pipes here). Only this mode
# waives the action requirement; the caller's body carries its own → line.
RAW=0
if [ -z "$BODY" ] && [ -z "$KV" ] && [ -z "$ACTION" ] && [ ! -t 0 ]; then
  BODY=$(cat); RAW=1
fi

if [ -z "$ACTION" ] && [ -z "$BODY" ] && [ -z "$KV" ]; then
  die "nothing to render: give --body/--kv/--action or pipe a body on stdin"
fi
if [ -z "$ACTION" ] && [ "$RAW" = "0" ]; then
  case "$BODY$KV" in
    *"→"*) : ;;  # body carries its own arrow line
    *) die "a box without an action line is ambient context in a costume" \
      "add --action \"<who does what next>\", or if nothing is owed compose a
line-tag:  box tag <tag-kind> \"<text>\"   (box list shows tag-tier kinds)" ;;
  esac
fi

render_box "$KIND" "$NAME" "$BODY" "$ACTION" "$ATTR" "$KV" "$COUNT" "$SEAL" \
  ${REFS[@]+"${REFS[@]}"}
