#!/usr/bin/env bash
# affirm.sh — affirmed-good-behavior tracker (sibling of atone.sh).
#
# Schema is lighter: no severity, no RCA. Required fields:
#   slug, title, behavior, why_good, trigger_condition, instruction
#
# Append-only event log at ~/.claude/affirm/events.jsonl, mirrors atone's
# protection model (chflags uappnd via `affirm.sh lock`, git auto-commit).

set -o pipefail

# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/atone-common.sh"

AFFIRM_DIR="${AFFIRM_DIR:-$HOME/.claude/affirm}"   # env-overridable for isolated tests
STORE="$AFFIRM_DIR/events.jsonl"
LOCK_FILE="$AFFIRM_DIR/events.jsonl.lock"

[ -n "${AFFIRM_STORE_OVERRIDE:-}" ] && STORE="$AFFIRM_DIR/$AFFIRM_STORE_OVERRIDE"
mkdir -p "$AFFIRM_DIR" 2>/dev/null || true

show_help() {
  printf '\n  %s%saffirm%s %s—%s Affirmed-good-behavior tracker\n' \
    "$C_BOLD" "$C_GREEN" "$C_RESET" "$C_DIM" "$C_RESET"
  printf '  %sLog non-obvious approaches the user explicitly approved. Sibling of atone.sh.%s\n' \
    "$C_DIM" "$C_RESET"

  _section "USAGE"
  _cmd 'affirm add [...]'        'log a new affirmed behavior'
  _cmd 'affirm list'             'tabular listing'
  _cmd 'affirm search <query>'   'free-text search'
  _cmd 'affirm show <id>'        'full event'
  _cmd 'affirm slugs'            'list distinct slugs'
  _cmd 'affirm lock'             'apply chflags uappnd'
  _cmd 'affirm help'             'this help'

  _section "EXAMPLES"
  _ex  "affirm add --slug audit-file-character --title '...' --behavior '...' \\"
  _ex  "       --why-good '...' --trigger-condition '...' --instruction '...'"
  _exd 'Log a non-obvious good call'

  _section "ADD FLAGS (all required except --tags --cluster --files --project)"
  _opt '--slug S'              'kebab-case pattern name'
  _opt '--title T'             '≤80-char one-line summary'
  _opt '--behavior B'          'what was done well, 2-3 sentences'
  _opt '--why-good W'          'why it mattered (what bad outcome was avoided)'
  _opt '--trigger-condition C' 'when this approach should fire'
  _opt '--instruction I'       'the at-action-time check, ≤2 sentences'
  _opt '--tags "a b c"'        'space-separated tags (shared with atone/)'
  _opt '--cluster X'           'F-J (or empty)'
  _opt '--project PATH'        'absolute project path or empty'
  _opt '--files "p:N"'         'space-separated file:line locations'

  _section "FILES"
  _dim "raw log     ~/.claude/affirm/events.jsonl  (chflags uappnd post-lock)"
  _dim "git history ~/.claude/affirm/.git           (auto-commit on every add)"
  echo
}

_new_id() { ledger_id aff; }
_ts() { ledger_ts; }

_git_commit() { ledger_commit "$AFFIRM_DIR" "$1" events.jsonl; }

cmd_add() {
  local slug="" title="" behavior="" why_good=""
  local trigger_condition="" instruction=""
  local tags_str="" cluster="" project="" files_str=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --slug)               slug="$2"; shift 2 ;;
      --title)              title="$2"; shift 2 ;;
      --behavior)           behavior="$2"; shift 2 ;;
      --why-good)           why_good="$2"; shift 2 ;;
      --trigger-condition)  trigger_condition="$2"; shift 2 ;;
      --instruction)        instruction="$2"; shift 2 ;;
      --tags)               tags_str="$2"; shift 2 ;;
      --cluster)            cluster="$2"; shift 2 ;;
      --project)            project="$2"; shift 2 ;;
      --files)              files_str="$2"; shift 2 ;;
      -h|--help)            show_help; exit 0 ;;
      *) _die "add: unknown flag: $1" ;;
    esac
  done

  for f in slug title behavior why_good trigger_condition instruction; do
    if [ -z "${!f}" ]; then
      _die "add: --${f//_/-} required"
    fi
  done

  _require jq

  local id ts
  id=$(_new_id); ts=$(_ts)
  local line
  line=$(jq -cn \
    --arg id "$id" --arg ts "$ts" --arg slug "$slug" --arg title "$title" \
    --arg behavior "$behavior" --arg why_good "$why_good" \
    --arg trigger_condition "$trigger_condition" --arg instruction "$instruction" \
    --arg tags_str "$tags_str" --arg cluster "$cluster" --arg project "$project" \
    --arg files_str "$files_str" \
    '{
       id: $id, ts: $ts, slug: $slug, title: $title,
       behavior: $behavior, why_good: $why_good,
       trigger_condition: $trigger_condition, instruction: $instruction,
       cluster: (if $cluster == "" then null else $cluster end),
       project: (if $project == "" then null else $project end),
       tags:  ($tags_str  | split(" ") | map(select(length > 0))),
       files: ($files_str | split(" ") | map(select(length > 0)))
     }')

  ledger_append "$STORE" "$LOCK_FILE" "$line"

  _git_commit "affirm: $id $slug"

  # Fast-path: refresh triggers.json + _tldr.txt (background — don't wait).
  ( bash "$HOME/.claude/scripts/atone-consolidate.sh" --triggers-only \
      >/dev/null 2>&1 & ) &

  _ok "logged $id"
  gum_kv "slug" "$slug"
  [ -n "$cluster" ] && gum_kv "cluster" "$cluster"
}

cmd_list() {
  if [ ! -s "$STORE" ]; then _info "no affirms logged yet"; return 0; fi
  _require jq
  jq -r '[.ts[:10], .id, (.cluster // "-"), .slug, .title] | @tsv' "$STORE" | \
    awk -F'\t' '{
      slug=$4; if (length(slug)>44) slug=substr(slug,1,41)"…"
      title=$5; if (length(title)>50) title=substr(title,1,47)"…"
      printf "%-10s  %-26s  %-2s  %-44s  %s\n", $1, $2, $3, slug, title
    }'
}

cmd_search() {
  [ $# -lt 1 ] && _die "search: query required"
  local q="$1"
  if [ ! -s "$STORE" ]; then _info "no affirms logged yet"; return 0; fi
  _require jq
  jq -c --arg q "$q" '
    select(
      (.slug // "") + " " + (.title // "") + " " + (.behavior // "") + " " +
      (.why_good // "") + " " + (.trigger_condition // "") + " " +
      (.instruction // "") + " " + ((.tags // []) | join(" "))
      | ascii_downcase | contains($q | ascii_downcase)
    )' "$STORE" | jq -r '[.ts[:10], .id, .slug, .title] | @tsv'
}

cmd_show() {
  [ $# -lt 1 ] && _die "show: id required"
  _require jq
  jq -c --arg id "$1" 'select(.id == $id)' "$STORE" | jq .
}

cmd_slugs() {
  if [ ! -s "$STORE" ]; then _info "no affirms logged yet"; return 0; fi
  _require jq
  jq -r '.slug' "$STORE" | sort | uniq -c | sort -rn | \
    awk -v c="$C_DIM" -v r="$C_RESET" -v g="$C_GREEN" \
      '{ printf "  %s%4d×%s  %s%s%s\n", c, $1, r, g, $2, r }'
}

cmd_lock() {
  [ -f "$STORE" ] || _die "lock: $STORE does not exist yet"
  if chflags uappnd "$STORE" 2>/dev/null; then
    _ok "chflags uappnd applied to events.jsonl"
  else
    _warn "uappnd may already be set or chflags failed"
  fi
}

case "${1:-help}" in
  add)            shift; cmd_add "$@" ;;
  list)           shift; cmd_list "$@" ;;
  search)         shift; cmd_search "$@" ;;
  show)           shift; cmd_show "$@" ;;
  slugs)          shift; cmd_slugs "$@" ;;
  lock)           shift; cmd_lock "$@" ;;
  help|-h|--help) show_help ;;
  *) _err "unknown subcommand: $1"; show_help; exit 2 ;;
esac
