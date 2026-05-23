#!/usr/bin/env bash
# tab-title/lib.sh — Shared state, composition, and emission for Ghostty
# tab titles. Sourced by update-tab-title.sh (Stop hook) and set-focus.sh
# (Claude-facing CLI).
#
# Title shape:  ✻ <icons> <base> [:<focus>]
#                ^star    ^decorators ^suffix
#
# State lives in /tmp/claude-tab-state-<session_id> as KEY=VALUE lines
# (bash-sourceable). A pointer /tmp/claude-tab-current names the most
# recently active session so set-focus.sh can find it without an arg.

TAB_STATE_DIR="${TAB_STATE_DIR:-/tmp}"
TAB_STAR="${CLAUDE_TAB_STAR:-✻}"

# ── Paths ────────────────────────────────────────────────────────────────────
tab_state_path() { printf '%s/claude-tab-state-%s' "$TAB_STATE_DIR" "$1"; }
tab_pointer_path() { printf '%s/claude-tab-current' "$TAB_STATE_DIR"; }

# ── State I/O ────────────────────────────────────────────────────────────────
# Load state into STAR / DECORATORS / BASE / FOCUS shell vars. Returns 1 if
# the state file is absent — caller decides whether that is fatal.
tab_load_state() {
  local sid="$1" path
  path=$(tab_state_path "$sid")
  STAR=""; DECORATORS=""; BASE=""; FOCUS=""; TRANSIENT_FOCUS=""; TRANSIENT_DEPTH=0; TTY_PATH=""
  STATUS=""; MODE=""; INTENT=""; GLYPH_PERM=""; GLYPH_SSH=""
  [[ -f "$path" ]] || return 1
  # shellcheck disable=SC1090
  source "$path"
  return 0
}

tab_save_state() {
  local sid="$1" path detected
  path=$(tab_state_path "$sid")
  # Auto-capture controlling tty when the caller has one (hooks do; Bash-tool
  # callers do not — they're setsid'd). Preserve the previous TTY_PATH
  # otherwise: the hook seeds it once, mid-turn callers reuse it.
  detected=$(tab_detect_tty)
  [[ -n "$detected" ]] && TTY_PATH="$detected"
  {
    printf 'STAR=%q\n'              "${STAR:-$TAB_STAR}"
    printf 'DECORATORS=%q\n'        "${DECORATORS:-}"
    printf 'BASE=%q\n'              "${BASE:-}"
    printf 'FOCUS=%q\n'             "${FOCUS:-}"
    printf 'TRANSIENT_FOCUS=%q\n'   "${TRANSIENT_FOCUS:-}"
    printf 'TRANSIENT_DEPTH=%q\n'   "${TRANSIENT_DEPTH:-0}"
    printf 'TTY_PATH=%q\n'          "${TTY_PATH:-}"
    printf 'STATUS=%q\n'            "${STATUS:-}"
    printf 'MODE=%q\n'              "${MODE:-}"
    printf 'INTENT=%q\n'            "${INTENT:-}"
    printf 'GLYPH_PERM=%q\n'        "${GLYPH_PERM:-}"
    printf 'GLYPH_SSH=%q\n'         "${GLYPH_SSH:-}"
  } > "$path"
  printf '%s' "$sid" > "$(tab_pointer_path)"
}

# Detect the device path of the visible terminal we should write to.
# Order:
#   1. $CLAUDE_TAB_TTY env override.
#   2. /dev/tty resolution (the ONLY reliable way to get the outer Ghostty
#      pty — Claude inherits it as controlling tty but spawns hooks under
#      an *inner* pty; ps -o tty= returns the inner one, which is WRONG).
#      `tty 0</dev/tty` opens /dev/tty as fd 0 and prints the resolved path.
#      This works in any context where /dev/tty is openable (hooks: yes;
#      setsid'd Bash-tool subprocesses: no).
#   3. Process-tree walk (fallback — may return the inner pty, still wrong
#      for title writes, but better than nothing for some setups).
tab_detect_tty() {
  if [[ -n "${CLAUDE_TAB_TTY:-}" ]]; then
    printf '%s' "$CLAUDE_TAB_TTY"
    return
  fi
  # Resolve /dev/tty to its concrete /dev/ttysNNN. macOS `tty(1)` returns
  # the literal string "/dev/tty" when fed /dev/tty as stdin (doesn't call
  # ttyname through), so we use python's os.ttyname which does.
  # Group with braces so the redirect-error from a failed open(/dev/tty) is
  # also captured by 2>/dev/null. Bash reports its own redirect failures
  # outside the command's stderr by default.
  local t
  if t=$( { python3 -c 'import os,sys; sys.stdout.write(os.ttyname(0))' 0</dev/tty; } 2>/dev/null ); then
    if [[ "$t" == /dev/* && "$t" != "/dev/tty" && -w "$t" ]]; then
      printf '%s' "$t"
      return
    fi
  fi
  local pid=$$ pp i
  for ((i=0; i<10; i++)); do
    [[ "$pid" -le 1 ]] && return 0
    t=$(ps -p "$pid" -o tty= 2>/dev/null | LC_ALL=C tr -d ' ')
    case "$t" in
      /dev/*)            printf '%s' "$t"; return ;;
      ttys*|ttyp*|pts*)  printf '/dev/%s' "$t"; return ;;
    esac
    pp=$(ps -p "$pid" -o ppid= 2>/dev/null | LC_ALL=C tr -d ' ')
    [[ -z "$pp" || "$pp" == "$pid" ]] && return 0
    pid="$pp"
  done
}

# ── Normalisation ────────────────────────────────────────────────────────────
# Strip any leading stars (so a single canonical one can be re-prepended) and
# absorb a trailing [:focus] suffix the LLM may have emitted into BASE.
# Sets globals TAB_NORMALISED_BASE and TAB_EMBEDDED_FOCUS (do NOT call via
# $(...) — command substitution runs in a subshell and globals would be lost).
tab_normalise_base() {
  local s="$1"
  # Strip leading stars + whitespace (handle multiple)
  while [[ "$s" =~ ^[[:space:]]*${TAB_STAR}[[:space:]]* ]]; do
    s="${s#*${TAB_STAR}}"
    s="${s# }"
  done
  # Pull trailing [:something] off into a side channel via global.
  # Use globs (bash 3.2-safe) instead of =~ regex.
  TAB_EMBEDDED_FOCUS=""
  # Tolerate optional trailing whitespace
  local trimmed="${s%"${s##*[![:space:]]}"}"
  if [[ "$trimmed" == *" [:"*"]" ]]; then
    local tail="${trimmed##* [:}"   # after the LAST " [:"
    TAB_EMBEDDED_FOCUS="${tail%]}"
    s="${trimmed% \[:*\]}"
  fi
  TAB_NORMALISED_BASE="$s"
}

# ── Decorators ───────────────────────────────────────────────────────────────
# Sources decorators.sh, which defines TAB_DECORATORS=(name1 name2 ...) and
# a `dec_<name>` function for each. Each function prints an icon glyph or
# nothing. The composed DECORATORS string is space-separated.
tab_run_decorators() {
  local script="${BASH_SOURCE%/*}/decorators.sh"
  [[ -f "$script" ]] || { DECORATORS=""; return 0; }
  # shellcheck disable=SC1090
  source "$script"
  # Decorators may read $TAB_SESSION_ID / $TAB_CWD via env-style access.
  export TAB_SESSION_ID="${TAB_SESSION_ID:-}"
  export TAB_CWD="${TAB_CWD:-}"
  local out="" name glyph
  for name in "${TAB_DECORATORS[@]:-}"; do
    glyph=$(dec_"$name" 2>/dev/null || true)
    [[ -n "$glyph" ]] && out+="$glyph "
  done
  DECORATORS="$out"
}

# Resolve the active session id for non-hook callers (watchdog scripts).
# Order: explicit env > pointer file > empty.
tab_resolve_sid() {
  if [[ -n "${CLAUDE_TAB_SESSION_ID:-}" ]]; then
    printf '%s' "$CLAUDE_TAB_SESSION_ID"
  elif [[ -f "$(tab_pointer_path)" ]]; then
    cat "$(tab_pointer_path)" 2>/dev/null || true
  fi
}

# ── Enum → glyph maps ────────────────────────────────────────────────────────
# Each map function: input = enum name (case-insensitive), output = single
# glyph (or empty if unknown). Tab-title CLI exposes these via `--list`.

# Slot 1 — STATUS (semantic icons; ✅⚠️❌💤ℹ️🛑 — GitHub/CI convention).
tab_status_glyph() {
  case "${1:-}" in
    ok|pass|passing|success)        printf '✅' ;;
    warning|warn|caution)           printf '⚠️' ;;
    error|err|fail|failing|failed)  printf '❌' ;;
    idle|sleep|waiting)             printf '💤' ;;
    info|note|notice)               printf 'ℹ️' ;;
    blocked|stop|stopped|halted)    printf '🛑' ;;
  esac
}
tab_status_list() {
  cat <<'EOF'
ok       ✅   task succeeded, tests green, no problems
warning  ⚠️   non-blocking issue, lint warning
error    ❌   build broken, exception, test failing
idle     💤   waiting for user, nothing happening
info     ℹ️   neutral notification, FYI
blocked  🛑   needs external action, paused
EOF
}

# Slot 2 — MODE (24 action-verbs; what KIND of work is happening now).
tab_mode_glyph() {
  case "${1:-}" in
    think|plan|planning)          printf '🤔' ;;
    reason|analyze|analyzing)     printf '🧠' ;;
    search|grep|explore)          printf '🔍' ;;
    read|reading)                 printf '📖' ;;
    study|research|learning)      printf '📚' ;;
    write|writing|draft)          printf '✏️' ;;
    edit|editing|refactor-action) printf '✂️' ;;
    build|building|compile)       printf '🛠️' ;;
    config|configure|setup)       printf '⚙️' ;;
    test|testing|validate)        printf '🧪' ;;
    debug|debugging|investigate)  printf '🐛' ;;
    fix|fixing|repair)            printf '🔧' ;;
    deploy|deploying|ship)        printf '🚀' ;;
    package|packaging|bundle)     printf '📦' ;;
    network|net|http|api)         printf '🌐' ;;
    save|saving|commit|persist)   printf '💾' ;;
    clean|cleanup|delete)         printf '🗑️' ;;
    review|reviewing|check)       printf '📋' ;;
    chat|talk|discuss)            printf '💬' ;;
    design|designing|style)       printf '🎨' ;;
    sync|syncing|refresh)         printf '🔄' ;;
    target|focused|aim)           printf '🎯' ;;
    wait|waiting|pending)         printf '⏳' ;;
    pair|pairing|collab)          printf '🤝' ;;
  esac
}
tab_mode_list() {
  cat <<'EOF'
think    🤔   planning / pre-action analysis
reason   🧠   reasoning / analyzing
search   🔍   grepping / exploring
read     📖   reading code/docs
study    📚   research / learning context
write    ✏️   drafting code/text
edit     ✂️   refactoring existing
build    🛠️   compiling / bundling
config   ⚙️   setup / configuration
test     🧪   running tests
debug    🐛   investigating bug
fix      🔧   repairing
deploy   🚀   shipping / releasing
package  📦   bundling / dist
network  🌐   HTTP / API / SSH
save     💾   persisting / committing
clean    🗑️   deleting / removing
review   📋   reviewing / checking
chat     💬   conversational, no tools
design   🎨   UI / UX / styling
sync     🔄   syncing / fetching / refreshing
target   🎯   focused execution
wait     ⏳   blocked on external
pair     🤝   collaborating
EOF
}

# Slot 3 — INTENT (session-level NOUN; what kind of work overall).
# Mirrors conventional-commit prefixes so the LLM already knows the vocabulary.
tab_intent_glyph() {
  case "${1:-}" in
    feature|feat|new)              printf '✨' ;;
    bugfix|fix-intent|bug)         printf '🐛' ;;
    refactor|restructure)          printf '🔄' ;;
    docs|doc|documentation)        printf '📝' ;;
    chore|cleanup|maintenance)     printf '🧹' ;;
    research|explore-intent|study) printf '📚' ;;
    design-intent|ui|ux)           printf '🎨' ;;
    release|ship|publish)          printf '🚀' ;;
    discussion|chat-intent|talk)   printf '💬' ;;
    test-intent|qa)                printf '🧪' ;;
    perf|optimize|optimization)    printf '⚡' ;;
    security|sec|audit)            printf '🔒' ;;
  esac
}
tab_intent_list() {
  cat <<'EOF'
feature    ✨   new feature work
bugfix     🐛   fixing a known bug
refactor   🔄   restructuring (no behavior change)
docs       📝   documentation
chore      🧹   cleanup / housekeeping
research   📚   exploration / learning
design     🎨   UI / UX design
release    🚀   shipping / cutting release
discussion 💬   conversational, no code
test       🧪   adding/improving tests
perf       ⚡   performance optimization
security   🔒   security audit / hardening
EOF
}

# ── Decorator glyph slots (state-driven, claude-settable) ────────────────────
# Slot accepts either a named alias (mapped below) or a raw emoji. Stored
# per-session in state as GLYPH_PERM / GLYPH_SSH. Default applies if unset.

tab_glyph_perm_options() {
  cat <<'EOF'
free      🆓   positive framing of unlocked permissions (default)
lock      🔓   unlocked padlock — "guards are down"
robot     🤖   delegated to AI / autopilot
bolt      ⚡   fast / auto mode
alarm     🚨   be careful, unsafe-by-default
warning   ⚠️   elevated permissions, take care
fire      🔥   danger zone
EOF
}
tab_glyph_perm_resolve() {
  case "${1:-}" in
    free)    printf '🆓' ;;
    lock)    printf '🔓' ;;
    robot)   printf '🤖' ;;
    bolt)    printf '⚡' ;;
    alarm)   printf '🚨' ;;
    warning) printf '⚠️' ;;
    fire)    printf '🔥' ;;
    *)       printf '%s' "$1" ;;
  esac
}
tab_glyph_ssh_options() {
  cat <<'EOF'
globe      🌐   remote / networked (default)
turtle     🐢   remote (probably slower)
satellite  🛰️   uplinked
antenna    📡   broadcasting
link       🔗   connected to elsewhere
EOF
}
tab_glyph_ssh_resolve() {
  case "${1:-}" in
    globe)     printf '🌐' ;;
    turtle)    printf '🐢' ;;
    satellite) printf '🛰️' ;;
    antenna)   printf '📡' ;;
    link)      printf '🔗' ;;
    *)         printf '%s' "$1" ;;
  esac
}

# ── Compose & emit (v3 — left/right split) ───────────────────────────────────
# Shape:  <star> <mode?> <intent?> <base> [:<focus?>]  <status?> <decorators?>
#         └─────── left: stable identifier ────────┘   └── right: volatile ──┘
# Truncation in Ghostty hits the right side first, preserving the identifier.
tab_compose() {
  local star="${STAR:-$TAB_STAR}" decs="${DECORATORS:-}" base="${BASE:-}"
  local focus="${TRANSIENT_FOCUS:-${FOCUS:-}}"
  local mode_g intent_g status_g
  mode_g=$(tab_mode_glyph "${MODE:-}")
  intent_g=$(tab_intent_glyph "${INTENT:-}")
  status_g=$(tab_status_glyph "${STATUS:-}")

  local left="$star"
  [[ -n "$mode_g"   ]] && left+=" $mode_g"
  [[ -n "$intent_g" ]] && left+=" $intent_g"
  left+=" $base"
  [[ -n "$focus" ]] && left+=" [:${focus}]"

  local right=""
  [[ -n "$status_g" ]] && right+="$status_g"
  if [[ -n "$decs" ]]; then
    # decs already has a trailing space; trim
    local decs_trim="${decs% }"
    right+="${right:+ }${decs_trim}"
  fi

  local out="$left"
  [[ -n "$right" ]] && out+="  $right"
  printf '%s' "$out"
}

tab_emit() {
  local safe
  safe=$(printf '%s' "$1" | LC_ALL=C tr -d '\000-\031\177')
  # Write to BOTH paths and log every attempt. Why both:
  #   - /dev/tty works from hook contexts that inherit a controlling tty
  #   - TTY_PATH (captured outer Ghostty pty) works when /dev/tty is severed
  #     (setsid'd Bash-tool subprocesses, or hooks Claude spawns detached)
  # The debug log proves which path is firing — without it, every error is
  # silently swallowed by `2>/dev/null || true` and the bug is invisible.
  local log="${HOME}/.claude/logs/tab-title-emit.log"
  local ts; ts=$(date "+%Y-%m-%d %H:%M:%S")
  local tty_ok=0 path_ok=0
  if ( printf '\033]0;%s\007' "$safe" > /dev/tty ) 2>/dev/null; then tty_ok=1; fi
  if [[ -n "${TTY_PATH:-}" && -w "$TTY_PATH" && "$TTY_PATH" != "/dev/tty" ]]; then
    if ( printf '\033]0;%s\007' "$safe" > "$TTY_PATH" ) 2>/dev/null; then path_ok=1; fi
  fi
  mkdir -p "${log%/*}" 2>/dev/null
  printf '[%s] tty=%d path=%d TTY_PATH=%q title=%q\n' \
    "$ts" "$tty_ok" "$path_ok" "${TTY_PATH:-}" "$safe" >> "$log" 2>/dev/null || true
}

# ── User-visible notice (dim, single-line, non-blocking) ─────────────────────
tab_notice() {
  ( printf '\033[2;3;90m[tab-title] %s\033[0m\n' "$1" > /dev/tty ) 2>/dev/null || true
}

# ── Validation ───────────────────────────────────────────────────────────────
# Populates TAB_ISSUES (global array) with one human-readable issue per
# element. Caller must have loaded state first. Returns 0 if clean, 1 if any.
tab_validate() {
  TAB_ISSUES=()
  if [[ -n "${STAR:-}" && "$STAR" != "$TAB_STAR" ]]; then
    TAB_ISSUES+=("non-canonical STAR ('$STAR' != '$TAB_STAR')")
  fi
  if [[ "${BASE:-}" == *"$TAB_STAR"* ]]; then
    TAB_ISSUES+=("BASE contains a star glyph (should be stripped)")
  fi
  if [[ "${BASE:-}" == *" [:"*"]"* ]]; then
    TAB_ISSUES+=("BASE contains embedded [:focus] (should move to FOCUS)")
  fi
  if [[ "${FOCUS:-}" == *"]"* || "${FOCUS:-}" == *"["* ]]; then
    TAB_ISSUES+=("FOCUS contains bracket char (would break round-trip)")
  fi
  if (( ${#FOCUS} > 40 )); then
    TAB_ISSUES+=("FOCUS exceeds 40 chars (${#FOCUS})")
  fi
  if (( ${#TRANSIENT_FOCUS} > 40 )); then
    TAB_ISSUES+=("TRANSIENT_FOCUS exceeds 40 chars (${#TRANSIENT_FOCUS})")
  fi
  if ! [[ "${TRANSIENT_DEPTH:-0}" =~ ^[0-9]+$ ]]; then
    TAB_ISSUES+=("TRANSIENT_DEPTH not a non-negative integer ('$TRANSIENT_DEPTH')")
  fi
  (( ${#TAB_ISSUES[@]} == 0 ))
}

# ── Automatic fixes ──────────────────────────────────────────────────────────
# Applies the inverse of every check in tab_validate. Caller must save+emit
# after. Returns 0 always; idempotent.
tab_fix() {
  STAR="$TAB_STAR"
  tab_normalise_base "${BASE:-}"
  BASE="$TAB_NORMALISED_BASE"
  # If the LLM left a [:focus] inside BASE and no manual focus exists, adopt it.
  if [[ -n "${TAB_EMBEDDED_FOCUS:-}" && -z "${FOCUS:-}" ]]; then
    FOCUS="$TAB_EMBEDDED_FOCUS"
  fi
  # Strip brackets + control chars from focus fields, clamp to 40.
  FOCUS=$(printf '%s' "${FOCUS:-}" | LC_ALL=C tr -d '][\000-\031\177')
  TRANSIENT_FOCUS=$(printf '%s' "${TRANSIENT_FOCUS:-}" | LC_ALL=C tr -d '][\000-\031\177')
  FOCUS="${FOCUS:0:40}"
  TRANSIENT_FOCUS="${TRANSIENT_FOCUS:0:40}"
  # Reset transient runtime state. Calling `fix` implies "make the manual
  # focus visible now"; if a tool truly is in flight, its PostToolUse will
  # decrement to -1 → clamp 0 with no harm done.
  TRANSIENT_FOCUS=""
  TRANSIENT_DEPTH=0
}
