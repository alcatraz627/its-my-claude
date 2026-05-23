#!/usr/bin/env bash
# tab-title.sh — Unified CLI for the Ghostty tab-title composer.
#
# Reads, writes, validates, and fixes the structured title:
#   ✻ <decorators> <base> [:<focus>]
#
# State is owned by ~/.claude/scripts/tab-title/lib.sh (KEY=VALUE files in
# /tmp). Every mutation goes through do_set → tab_save_state → tab_emit so
# behaviour stays identical whether one field or several are updated.

set -uo pipefail
LIB="${BASH_SOURCE%/*}/lib.sh"
# shellcheck disable=SC1090
source "$LIB"

PROG=$(basename "$0")

# ── Help ─────────────────────────────────────────────────────────────────────
print_help() {
  cat <<EOF
$PROG — Ghostty tab-title composer CLI

USAGE
  $PROG <command> [args]
  $PROG                       # prints this help

READING
  show                        Print the composed title for the active session
  get <field>                 Print one field. Fields:
                                star | mode | intent | base | focus
                                status | decorators | transient | depth
                                glyph_perm | glyph_ssh | session | tty | all

UPDATING
  set <field>=<value> ...     Update one or many fields atomically. Fields:
                                base | focus | transient | star
                                status | mode | intent
                                glyph_perm | glyph_ssh
                              Pass the empty string to clear: focus=
  focus <text>                Shorthand for: set focus="<text>"
  focus --clear               Shorthand for: set focus=
  status <name>               Named status (semantic icon). --list / --clear.
                                ok | warning | error | idle | info | blocked
  mode <name>                 Named action mode (verb). --list / --clear.
                                think | search | read | write | edit | build |
                                test | debug | fix | deploy | save | … (24 total)
                              NOTE: auto-set by PreToolUse from tool inspection;
                              call mode manually to override the auto-derivation.
  intent <name>               Session-level kind of work (noun). --list / --clear.
                                feature | bugfix | refactor | docs | chore | …
  glyph <perm|ssh> <name>     Configure a decorator's emoji. --options / --clear.
                              Persists per-session in state — no shell env
                              vars. Accepts named alias or raw emoji.
                              e.g.  glyph perm robot  /  glyph ssh 🐢
  refresh                     Re-run decorators + re-emit (no field changes)
  raw [-y --reason X] <text>  ESCAPE HATCH — bypass compose, emit literal
                              <text> as the OSC title. Without -y prints a
                              dissuade message and exits 1; with -y, a
                              PreToolUse hook prompts the user. Use ONLY
                              when the structured fields can't express it
                              (rare). Does not touch state.

VALIDATION
  check                       List issues with current state. Exit 0 = clean.
  fix                         Apply known auto-fixes (normalise base, strip
                              brackets in focus, clamp lengths, reset depth).
                              Idempotent.

SESSIONS
  Resolution order for the target session:
    1. \$CLAUDE_TAB_SESSION_ID
    2. /tmp/claude-tab-current (last hook to fire)
  If neither resolves, the command halts with a dim notice and exits 0
  (non-blocking for the caller — Claude won't see an error spam).

COMPOSE SHAPE (v3 — left identifier + right volatile flags)
  ✻ <mode?> <intent?> <base> [:<focus?>]    <status?> <decorators?>
  └────────── identifier (left) ───────┘    └──── volatile (right) ────┘
  Two-space separator. Ghostty truncates right side first; identifier sticks.

EXAMPLES
  $PROG show
  $PROG get focus                          # one field
  $PROG get all                            # full state dump
  $PROG focus "refactoring lib"            # set focus shorthand
  $PROG focus --clear
  $PROG status ok                          # named enum → ✅
  $PROG mode debug                         # named enum → 🐛
  $PROG intent feature                     # named enum → ✨
  $PROG status --list                      # show all named values
  $PROG glyph perm robot                   # config perm decorator → 🤖
  $PROG glyph ssh 🐢                       # raw emoji also accepted
  $PROG glyph perm --options               # list named aliases
  $PROG set base="Auth refactor" focus="csrf"   # multi-field atomic
  $PROG check                              # validate state
  $PROG fix && $PROG show                  # repair + reshow
  $PROG refresh                            # re-run decorators

NOTES
  • status / mode / intent are the three named-enum slots; LLMs can pick
    by name (run --list to discover values). Unknown names are stored but
    render no glyph — gives soft-validation feedback.
  • mode is AUTO-DERIVED by the PreToolUse hook from the running tool's
    name + command. Manual 'mode <x>' overrides until the next tool call.
  • Transient focus (watchdog) wins over manual focus while a tool is in
    flight. Don't write 'transient' directly unless you know what you're
    doing — the watchdog overwrites it.
  • Bracket chars in focus are stripped by 'fix' (would break round-trip).
    Keep focus text to 1-3 lowercase words.
  • Visible title refreshes once per turn at the Stop hook firing. Mid-turn
    state mutations accumulate; the compose renders at end of turn.
  • Glyph slots (perm/ssh) persist per-session in state — no shell env
    vars. Claude can flip them mid-session; user can override via this CLI.

SEE ALSO
  features/tab-title.md            usage + decorator extension guide
  scripts/tab-title/lib.sh         state I/O, compose, validate, fix
  scripts/tab-title/decorators.sh  registry of icon decorators
EOF
}

# ── Session resolution ───────────────────────────────────────────────────────
resolve_sid_or_warn() {
  local sid
  sid=$(tab_resolve_sid)
  if [[ -z "$sid" ]]; then
    tab_notice "no active session — has the Stop hook fired yet?"
    return 1
  fi
  printf '%s' "$sid"
}

# ── Central mutation router ──────────────────────────────────────────────────
# Every write path goes through this. Field name on LHS, value on RHS.
# Returns 0 / 1 (unknown field).
do_set() {
  local field="$1" value="$2"
  case "$field" in
    base)      BASE="$value" ;;
    focus)     FOCUS="$value" ;;
    transient) TRANSIENT_FOCUS="$value" ;;
    star)      STAR="${value:-$TAB_STAR}" ;;
    status)    STATUS="$value" ;;
    mode)      MODE="$value" ;;
    intent)    INTENT="$value" ;;
    glyph_perm|GLYPH_PERM) GLYPH_PERM="$value" ;;
    glyph_ssh|GLYPH_SSH)   GLYPH_SSH="$value" ;;
    *) tab_notice "unknown field '$field'"; return 1 ;;
  esac
}

# ── get: read one field ──────────────────────────────────────────────────────
cmd_get() {
  local field="${1:-}"
  [[ -n "$field" ]] || { echo "usage: $PROG get <field>"; return 2; }
  local sid; sid=$(resolve_sid_or_warn) || return 0
  tab_load_state "$sid" || { tab_notice "no state for $sid"; return 0; }
  case "$field" in
    star)       printf '%s\n' "${STAR:-$TAB_STAR}" ;;
    decorators) printf '%s\n' "${DECORATORS:-}" ;;
    base)       printf '%s\n' "${BASE:-}" ;;
    focus)      printf '%s\n' "${FOCUS:-}" ;;
    transient)  printf '%s\n' "${TRANSIENT_FOCUS:-}" ;;
    depth)      printf '%s\n' "${TRANSIENT_DEPTH:-0}" ;;
    session)    printf '%s\n' "$sid" ;;
    tty)        printf '%s\n' "${TTY_PATH:-}" ;;
    status)     printf '%s\n' "${STATUS:-}" ;;
    mode)       printf '%s\n' "${MODE:-}" ;;
    intent)     printf '%s\n' "${INTENT:-}" ;;
    glyph_perm) printf '%s\n' "${GLYPH_PERM:-}" ;;
    glyph_ssh)  printf '%s\n' "${GLYPH_SSH:-}" ;;
    all)
      printf 'session=%s\nstar=%s\nmode=%s\nintent=%s\nbase=%s\nfocus=%s\nstatus=%s\ndecorators=%s\ntransient=%s\ndepth=%s\ntty=%s\n' \
        "$sid" "${STAR:-}" "${MODE:-}" "${INTENT:-}" "${BASE:-}" \
        "${FOCUS:-}" "${STATUS:-}" "${DECORATORS:-}" \
        "${TRANSIENT_FOCUS:-}" "${TRANSIENT_DEPTH:-0}" "${TTY_PATH:-}" ;;
    *) echo "unknown field: $field" >&2; return 2 ;;
  esac
}

# ── show: composed title ─────────────────────────────────────────────────────
cmd_show() {
  local sid; sid=$(resolve_sid_or_warn) || return 0
  tab_load_state "$sid" || { tab_notice "no state for $sid"; return 0; }
  tab_compose; printf '\n'
}

# ── set: one or many field=value pairs (single = multi with N=1) ─────────────
cmd_set() {
  (( $# >= 1 )) || { echo "usage: $PROG set <field>=<value> [...]"; return 2; }
  local sid; sid=$(resolve_sid_or_warn) || return 0
  tab_load_state "$sid" || { tab_notice "no state for $sid — run a turn first"; return 0; }
  local arg field value
  for arg in "$@"; do
    if [[ "$arg" != *=* ]]; then
      tab_notice "skipping '$arg' (expected field=value)"; continue
    fi
    field="${arg%%=*}"
    value="${arg#*=}"
    do_set "$field" "$value" || true
  done
  tab_save_state "$sid"
  tab_emit "$(tab_compose)"
}

# ── focus: ergonomic shorthand around `set focus=...` ────────────────────────
cmd_focus() {
  case "${1:-}" in
    ""|--help|-h) echo "usage: $PROG focus <text> | $PROG focus --clear"; return 2 ;;
    --clear)      cmd_set "focus=" ;;
    *)            cmd_set "focus=$*" ;;
  esac
}

# ── status / mode / intent: ergonomic shorthands for named-enum slots ───────
# Each: <name>  → set; --clear  → empty; --list  → show enum table.
cmd_enum_slot() {
  local field="$1"; shift
  case "${1:-}" in
    ""|--help|-h) echo "usage: $PROG $field <name> | --clear | --list"; return 2 ;;
    --clear)      cmd_set "$field=" ;;
    --list)       tab_"${field}"_list ;;
    *)
      # Validate the name maps to a glyph; warn if not (still accept — enum
      # might grow later; better to render empty than refuse).
      local g; g=$(tab_"${field}"_glyph "$1")
      [[ -z "$g" ]] && tab_notice "unknown $field '$1' — run '$PROG $field --list'"
      cmd_set "$field=$1"
      ;;
  esac
}
cmd_status() { cmd_enum_slot status "$@"; }
cmd_mode()   { cmd_enum_slot mode   "$@"; }
cmd_intent() { cmd_enum_slot intent "$@"; }

# ── glyph: configure decorator emoji (perm / ssh) ───────────────────────────
# Persists per-session in state. Claude-settable AND user-settable; no env
# vars needed. Accepts a named alias (mapped via tab_glyph_*_resolve) or a
# raw emoji.
cmd_glyph() {
  local slot="${1:-}"
  if [[ -z "$slot" || "$slot" == "--list" || "$slot" == "-h" || "$slot" == "--help" ]]; then
    local sid; sid=$(resolve_sid_or_warn) || return 0
    tab_load_state "$sid" || true
    printf 'perm : %s\n' "${GLYPH_PERM:-🆓 (default)}"
    printf 'ssh  : %s\n' "${GLYPH_SSH:-🌐 (default)}"
    echo
    echo "usage: $PROG glyph <perm|ssh> <name-or-emoji> | --options | --clear"
    return 0
  fi
  case "$slot" in
    perm|ssh) ;;
    *) echo "unknown glyph slot: $slot (use: perm, ssh)" >&2; return 2 ;;
  esac
  case "${2:-}" in
    "")        echo "usage: $PROG glyph $slot <name-or-emoji> | --options | --clear" >&2; return 2 ;;
    --options) tab_glyph_"$slot"_options ;;
    --clear)
      if [[ "$slot" == perm ]]; then cmd_set "GLYPH_PERM="
      else                            cmd_set "GLYPH_SSH=";  fi
      ;;
    *)
      local resolved
      resolved=$(tab_glyph_"$slot"_resolve "$2")
      if [[ "$slot" == perm ]]; then cmd_set "GLYPH_PERM=$resolved"
      else                            cmd_set "GLYPH_SSH=$resolved";  fi
      ;;
  esac
}

# ── refresh: re-run decorators (e.g. after toggling SSH, perm mode) ──────────
cmd_refresh() {
  local sid; sid=$(resolve_sid_or_warn) || return 0
  tab_load_state "$sid" || { tab_notice "no state for $sid"; return 0; }
  TAB_SESSION_ID="$sid"
  tab_run_decorators
  tab_save_state "$sid"
  tab_emit "$(tab_compose)"
}

# ── check: list issues ───────────────────────────────────────────────────────
cmd_check() {
  local sid; sid=$(resolve_sid_or_warn) || return 0
  if ! tab_load_state "$sid"; then
    echo "issue: no state file for session $sid"; return 1
  fi
  if tab_validate; then
    echo "ok"; return 0
  fi
  local i
  for i in "${TAB_ISSUES[@]}"; do echo "issue: $i"; done
  return 1
}

# ── raw: bypass compose, emit a literal title (escape hatch) ─────────────────
# Dissuade unless -y is passed; with -y, the PreToolUse hook
# (scripts/tab-title/hooks/raw-guard.sh) asks the user for permission.
cmd_raw() {
  local confirmed=0 reason="" title=""
  while (( $# > 0 )); do
    case "$1" in
      -y|--yes) confirmed=1; shift ;;
      --reason) reason="$2"; shift 2 ;;
      --reason=*) reason="${1#--reason=}"; shift ;;
      *) title="$1"; shift ;;
    esac
  done
  [[ -n "$title" ]] || { echo "usage: $PROG raw [-y --reason \"why\"] <title>" >&2; return 2; }

  if (( ! confirmed )); then
    # Printed to stderr so it lands in Claude's tool-output, not the title.
    cat >&2 <<MSG
[tab-title:raw] ⚠️  raw mode bypasses the structured composer. The next Stop
hook will overwrite whatever you set, so this is almost always the wrong
tool. Prefer:  $PROG focus "..."  /  $PROG set base="..." focus="..."

If you're certain raw is needed (rare — e.g., emitting a custom OSC that
can't fit the ✻ <decorators> <base> [:focus] shape), re-call with:
    $PROG raw -y --reason "<one-line reason>" "$title"
The user will see a permission prompt before the write happens.
MSG
    return 1
  fi

  local sid; sid=$(resolve_sid_or_warn) || return 0
  tab_load_state "$sid" || true
  # Use the same emit machinery so we go through TTY_PATH; do not touch state.
  tab_emit "$title"
  printf 'raw title written (reason: %s)\n' "${reason:-<none>}"
}

# ── fix: apply auto-repairs, save, re-emit ───────────────────────────────────
cmd_fix() {
  local sid; sid=$(resolve_sid_or_warn) || return 0
  tab_load_state "$sid" || { tab_notice "no state for $sid"; return 0; }
  tab_fix
  tab_save_state "$sid"
  tab_emit "$(tab_compose)"
  cmd_check
}

# ── Dispatch ─────────────────────────────────────────────────────────────────
case "${1:-}" in
  ""|-h|--help|help) print_help ;;
  show)      shift; cmd_show "$@" ;;
  get)       shift; cmd_get "$@" ;;
  set)       shift; cmd_set "$@" ;;
  focus)     shift; cmd_focus "$@" ;;
  refresh)   shift; cmd_refresh "$@" ;;
  check)     shift; cmd_check "$@" ;;
  fix)       shift; cmd_fix "$@" ;;
  raw)       shift; cmd_raw "$@" ;;
  status)    shift; cmd_status "$@" ;;
  mode)      shift; cmd_mode "$@" ;;
  intent)    shift; cmd_intent "$@" ;;
  glyph)     shift; cmd_glyph "$@" ;;
  *) echo "unknown command: $1" >&2; print_help >&2; exit 2 ;;
esac
