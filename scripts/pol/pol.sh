#!/usr/bin/env bash
# pol.sh — the owner's policy switches for what agents may do, read live by hooks.
#
# One place holds every allow/block and every tunable the owner sets without
# typing a sentence: GitHub, Slack, commits, pushes, deploys, model seats, a few
# thresholds. Values are global, with an optional override per project, and any
# value can carry a snooze that flips it at a set time. Hooks call `get` on
# every relevant tool call, so a change lands in every running session at once.
#
# Files (POL_ROOT, default ~/.claude/policy):
#   registry.json  what exists: key, label, group, type, options or bounds,
#                  default, scopes, help. The panel renders from it.
#   policy.json    {"global": {key: entry}, "projects": {"<repo root>": {key: entry}}}
#                  entry = {"value": v, "at": iso, ["until": epoch, "then": v]}
#
# Only the owner changes policy. set, snooze, unsnooze and clear refuse to run
# from an agent's shell (CLAUDECODE, AI_AGENT, a Codex seat) against the real
# store; the owner's own terminal and the menu bar panel are not agent shells.
#
#   pol.sh get <key> [--cwd <dir>]            resolved value; exit 3 unknown key
#   pol.sh set <key> <value> [--global | --project <dir>]
#   pol.sh snooze <key> (--for 30m|4h|2d | --until today|<epoch>) --then <value> [--global | --project <dir>]
#   pol.sh unsnooze <key> [--global | --project <dir>]
#   pol.sh clear <key> (--global | --project <dir>)
#   pol.sh list [--cwd <dir>]                 table for a terminal
#   pol.sh json [--cwd <dir>]                 everything the panel needs
#   pol.sh inject                             SessionStart injector (payload on stdin)
#   pol.sh root <dir>                         the project key a directory maps to
#
# Test overrides: POL_ROOT, POL_NOW (epoch).
set -uo pipefail

DEFAULT_ROOT="$HOME/.claude/policy"
ROOT="${POL_ROOT:-$DEFAULT_ROOT}"
REG="$ROOT/registry.json"
STORE="$ROOT/policy.json"
NOW="${POL_NOW:-$(date +%s)}"
BACKUPS_KEPT=5

die() { printf 'pol: %s\n' "$1" >&2; exit "${2:-2}"; }
command -v jq >/dev/null 2>&1 || die "jq is required" 2

# The key a directory's policy overrides live under: the main checkout of its
# repository, so every worktree of one repo shares one override. Empty outside
# a repository, which means only global values apply there.
project_root() {
  local d="${1:-}" common top
  [ -n "$d" ] && [ -d "$d" ] || return 0
  common=$(git -C "$d" rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || return 0
  if [ "$(basename "$common")" = ".git" ]; then
    dirname "$common"
  else
    top=$(git -C "$d" rev-parse --show-toplevel 2>/dev/null) && printf '%s\n' "$top"
  fi
}

store_json() { # the store, or an empty one when absent or unreadable
  if [ -f "$STORE" ] && jq -e 'type == "object"' "$STORE" >/dev/null 2>&1; then cat "$STORE"
  else printf '{"global":{},"projects":{}}'; fi
}

registry_ok() { [ -f "$REG" ] && jq -e 'type == "array"' "$REG" >/dev/null 2>&1; }

# Shared jq: effective value of one stored entry, value validity, resolution.
JQ_LIB='
def entry_value($e; $now):
  if ($e | type) != "object" then null
  elif ($e.until != null) and ($e.until <= $now) then $e.then
  else $e.value end;
def valid($r; $v):
  if $v == null then false
  elif $r.type == "bool" then ($v == "allow" or $v == "block")
  elif $r.type == "enum" then any(($r.options // [])[]; . == $v)
  elif $r.type == "number" then (($v | type) == "number" and $v >= $r.min and $v <= $r.max)
  else false end;
def project_ok($r): any(($r.scopes // ["global"])[]; . == "project");
def snooze_of($e; $scope; $now):
  if ($e | type) == "object" and $e.until != null
  then {scope: $scope, until: $e.until, then: $e.then, expired: ($e.until <= $now)} else null end;
def resolve($r; $store; $proj; $now):
  ( if $proj != "" and project_ok($r) then ($store.projects[$proj][$r.key] // null) else null end ) as $pe
  | ($store.global[$r.key] // null) as $ge
  | entry_value($pe; $now) as $pv
  | entry_value($ge; $now) as $gv
  | if valid($r; $pv) then {value: $pv, source: "project"}
    elif valid($r; $gv) then {value: $gv, source: "global"}
    else {value: $r.default, source: "default"} end;
'

agent_shell() {
  [ -n "${CLAUDECODE:-}${AI_AGENT:-}${CODEX_SANDBOX:-}${CODEX_THREAD_ID:-}${GCC_DISPATCH:-}" ]
}

refuse_agent_writes() {
  local real
  real=$(cd "$ROOT" 2>/dev/null && pwd -P)
  if agent_shell && [ "$real" = "$(cd "$DEFAULT_ROOT" 2>/dev/null && pwd -P)" ]; then
    die "policy is owner-set only. Ask the owner to flip it in the menu bar policy panel, or to run this from their own terminal." 4
  fi
}

# Parse the shared scope flags. Sets SCOPE ("global" or a repo root) and ARGS.
parse_scope() {
  SCOPE="global"; ARGS=()
  while [ $# -gt 0 ]; do
    case "$1" in
      --global) SCOPE="global"; shift;;
      --project)
        [ -n "${2:-}" ] || die "--project needs a directory"
        SCOPE=$(project_root "$2")
        [ -n "$SCOPE" ] || die "not inside a git repository: $2"
        shift 2;;
      *) ARGS+=("$1"); shift;;
    esac
  done
}

reg_entry() { # key -> registry entry JSON, or exit 3
  local e
  registry_ok || die "registry missing or unreadable: $REG" 3
  e=$(jq -c --arg k "$1" 'first(.[] | select(.key == $k)) // empty' "$REG")
  [ -n "$e" ] || die "unknown policy: $1" 3
  printf '%s' "$e"
}

# Turn a CLI string into the JSON value its type stores, or fail.
typed_value() { # regentry value -> JSON literal
  jq -cn --argjson r "$1" --arg v "$2" "$JQ_LIB"'
    (if $r.type == "number" then ($v | tonumber? // null) else $v end) as $x
    | if valid($r; $x) then $x else error("invalid") end' 2>/dev/null
}

# Apply a jq transform to the store under a lock, atomically, with backups.
mutate() { # jq-filter [--arg ...]
  local filter="$1"; shift
  mkdir -p "$ROOT" || die "cannot create $ROOT"
  local lock="$ROOT/.lock" n=0
  until mkdir "$lock" 2>/dev/null; do
    n=$((n + 1)); [ "$n" -gt 60 ] && die "store is locked ($lock); remove it if no pol.sh is running"
    sleep 0.05
  done
  trap 'rmdir "$lock" 2>/dev/null' EXIT
  # The temp file sits beside the store so the final mv is a same-volume rename,
  # which is atomic: a reader sees the old file or the new one, never half.
  local tmp="$ROOT/.policy.json.tmp"
  if ! { store_json | jq "$@" '.global //= {} | .projects //= {} | '"$filter" > "$tmp" 2>/dev/null \
         && jq -e 'type == "object"' "$tmp" >/dev/null 2>&1; }; then
    rmdir "$lock" 2>/dev/null; trap - EXIT
    die "write failed; store unchanged"
  fi
  # Backups rotate through fixed slots (1 newest), so nothing is ever deleted.
  if [ -f "$STORE" ]; then
    local i=$BACKUPS_KEPT
    while [ "$i" -gt 1 ]; do
      [ -f "$STORE.bak.$((i - 1))" ] && mv -f "$STORE.bak.$((i - 1))" "$STORE.bak.$i"
      i=$((i - 1))
    done
    cp -f "$STORE" "$STORE.bak.1" 2>/dev/null
  fi
  mv -f "$tmp" "$STORE" || { rmdir "$lock" 2>/dev/null; trap - EXIT; die "write failed; store unchanged"; }
  rmdir "$lock" 2>/dev/null; trap - EXIT
}

scope_path() { # scope -> jq path expression for the entry map
  if [ "$1" = "global" ]; then printf '.global'; else printf '.projects[$scope]'; fi
}

scope_allowed() { # regentry scope
  [ "$2" = "global" ] && return 0
  jq -e 'any((.scopes // ["global"])[]; . == "project")' <<<"$1" >/dev/null \
    || die "$(jq -r .key <<<"$1") is global only; it has no per-project override"
}

duration_end() { # 30m|4h|2d|today|<epoch> -> epoch
  local s="$1"
  case "$s" in
    today) date -v23H -v59M -v59S +%s 2>/dev/null || date -d 'today 23:59:59' +%s;;
    *m) [[ "${s%m}" =~ ^[0-9]+$ ]] && echo $(( NOW + ${s%m} * 60 ));;
    *h) [[ "${s%h}" =~ ^[0-9]+$ ]] && echo $(( NOW + ${s%h} * 3600 ));;
    *d) [[ "${s%d}" =~ ^[0-9]+$ ]] && echo $(( NOW + ${s%d} * 86400 ));;
    *) [[ "$s" =~ ^[0-9]{9,}$ ]] && echo "$s";;
  esac
}

iso_now() { date -u -r "$NOW" +%FT%TZ 2>/dev/null || date -u +%FT%TZ; }

cmd_get() {
  local key="${1:-}" cwd=""; shift || true
  [ "${1:-}" = "--cwd" ] && cwd="${2:-}"
  [ -n "$key" ] || die "usage: pol.sh get <key> [--cwd <dir>]"
  registry_ok || exit 3
  local proj; proj=$(project_root "$cwd")
  local out
  out=$(store_json | jq -r --slurpfile reg "$REG" --arg k "$key" --arg p "$proj" --argjson now "$NOW" "$JQ_LIB"'
    . as $s | (first($reg[0][] | select(.key == $k)) // null) as $r
    | if $r == null then empty else resolve($r; $s; $p; $now).value end' 2>/dev/null)
  [ -n "$out" ] || exit 3
  printf '%s\n' "$out"
}

cmd_set() {
  parse_scope "$@"; set -- ${ARGS[@]+"${ARGS[@]}"}
  local key="${1:-}" val="${2:-}"
  [ -n "$key" ] && [ -n "$val" ] || die "usage: pol.sh set <key> <value> [--global | --project <dir>]"
  refuse_agent_writes
  local r; r=$(reg_entry "$key") || exit $?
  scope_allowed "$r" "$SCOPE"
  local v; v=$(typed_value "$r" "$val") || die "invalid value for $key: $val ($(jq -r 'if .type=="number" then "\(.min) to \(.max)" elif .type=="bool" then "allow or block" else (.options|join(", ")) end' <<<"$r"))"
  mutate "$(scope_path "$SCOPE")"'[$k] = {value: $v, at: $at}' \
    --arg scope "$SCOPE" --arg k "$key" --argjson v "$v" --arg at "$(iso_now)"
  printf '%s = %s (%s)\n' "$key" "$(jq -r 'tostring' <<<"$v")" "$SCOPE"
}

cmd_snooze() {
  parse_scope "$@"; set -- ${ARGS[@]+"${ARGS[@]}"}
  local key="${1:-}"; shift || true
  local when="" then=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --for|--until) when="${2:-}"; shift 2;;
      --then) then="${2:-}"; shift 2;;
      *) die "unknown argument: $1";;
    esac
  done
  [ -n "$key" ] && [ -n "$when" ] && [ -n "$then" ] || die "usage: pol.sh snooze <key> --for 4h --then <value> [--global | --project <dir>]"
  refuse_agent_writes
  local r; r=$(reg_entry "$key") || exit $?
  scope_allowed "$r" "$SCOPE"
  local until; until=$(duration_end "$when")
  [ -n "$until" ] && [ "$until" -gt "$NOW" ] || die "snooze time must be in the future: $when"
  local tv; tv=$(typed_value "$r" "$then") || die "invalid value for $key: $then"
  # The value that holds until the flip: this scope's own value if it has one,
  # otherwise whatever currently applies here, so setting a snooze never moves
  # the present value.
  local proj=""; [ "$SCOPE" != "global" ] && proj="$SCOPE"
  local cur
  cur=$(store_json | jq -c --argjson r "$r" --arg p "$proj" --arg scope "$SCOPE" --argjson now "$NOW" "$JQ_LIB"'
    . as $s
    | (if $scope == "global" then $s.global[$r.key] else ($s.projects[$scope] // {})[$r.key] end) as $own
    | entry_value($own; $now) as $ov
    | if valid($r; $ov) then $ov
      elif $scope == "global" then $r.default
      else resolve($r; $s; $p; $now).value end')
  [ "$cur" != "$tv" ] || die "$key is already $then here; a snooze to the same value would change nothing"
  mutate "$(scope_path "$SCOPE")"'[$k] = {value: $cur, at: $at, until: $until, then: $then}' \
    --arg scope "$SCOPE" --arg k "$key" --argjson cur "$cur" --argjson then "$tv" \
    --argjson until "$until" --arg at "$(iso_now)"
  printf '%s stays %s, flips to %s at %s (%s)\n' "$key" "$(jq -r tostring <<<"$cur")" "$then" \
    "$(date -r "$until" '+%a %H:%M' 2>/dev/null || echo "$until")" "$SCOPE"
}

cmd_unsnooze() {
  parse_scope "$@"; set -- ${ARGS[@]+"${ARGS[@]}"}
  local key="${1:-}"; [ -n "$key" ] || die "usage: pol.sh unsnooze <key> [--global | --project <dir>]"
  refuse_agent_writes
  reg_entry "$key" >/dev/null || exit $?
  # An expired snooze has already flipped: keep the flipped value, drop the timer.
  mutate "$(scope_path "$SCOPE")"'[$k] |= (if type == "object" and .until != null
      then (if .until <= $now then .value = .then else . end) | del(.until, .then) else . end)' \
    --arg scope "$SCOPE" --arg k "$key" --argjson now "$NOW"
  printf '%s snooze removed (%s)\n' "$key" "$SCOPE"
}

cmd_clear() {
  parse_scope "$@"; set -- ${ARGS[@]+"${ARGS[@]}"}
  local key="${1:-}"; [ -n "$key" ] || die "usage: pol.sh clear <key> (--global | --project <dir>)"
  refuse_agent_writes
  reg_entry "$key" >/dev/null || exit $?
  if [ "$SCOPE" = "global" ]; then
    mutate 'del(.global[$k])' --arg k "$key"
  else
    mutate 'del(.projects[$scope][$k]) | if (.projects[$scope] // {}) == {} then del(.projects[$scope]) else . end' \
      --arg scope "$SCOPE" --arg k "$key"
  fi
  printf '%s cleared (%s)\n' "$key" "$SCOPE"
}

# Everything the panel renders for one scope, resolved here so the panel and
# the hooks can never disagree about a value.
cmd_json() {
  local cwd=""; [ "${1:-}" = "--cwd" ] && cwd="${2:-}"
  registry_ok || die "registry missing or unreadable: $REG" 3
  local proj; proj=$(project_root "$cwd")
  store_json | jq --slurpfile reg "$REG" --arg p "$proj" --argjson now "$NOW" "$JQ_LIB"'
    . as $s
    | {
      now: $now,
      project: (if $p == "" then null else $p end),
      projects: ([$s.projects | keys[]] + (if $p == "" then [] else [$p] end) | unique),
      policies: [ $reg[0][] as $r
        | ($s.global[$r.key] // null) as $ge
        | (if $p != "" and project_ok($r) then ($s.projects[$p][$r.key] // null) else null end) as $pe
        | resolve($r; $s; $p; $now) as $res
        | $r + {
            value: $res.value, source: $res.source,
            global_value: (if valid($r; entry_value($ge; $now)) then entry_value($ge; $now) else null end),
            project_value: (if valid($r; entry_value($pe; $now)) then entry_value($pe; $now) else null end),
            snooze: (snooze_of($pe; "project"; $now) // snooze_of($ge; "global"; $now)),
            project_scoped: project_ok($r)
          } ]
    }'
}

cmd_list() {
  local cwd="${2:-}"; [ "${1:-}" = "--cwd" ] || cwd=""
  cmd_json --cwd "$cwd" | jq -r '
    (if .project then "scope: \(.project)" else "scope: global" end),
    (.policies[] | [ .group, .key, (.value | tostring), .source,
      (if .snooze and (.snooze.expired | not) then "→ \(.snooze.then) at \(.snooze.until | strflocaltime("%a %H:%M"))" else "" end) ]
      | @tsv)' | column -t -s $'\t'
}

# SessionStart injector: tells the session what the owner has set, and that
# an allowed action needs no approval request.
cmd_inject() {
  local payload cwd
  payload=$(cat 2>/dev/null || echo '{}')
  cwd=$(printf '%s' "$payload" | jq -r '.cwd // empty' 2>/dev/null)
  registry_ok || exit 0
  local j; j=$(cmd_json --cwd "$cwd" 2>/dev/null) || exit 0
  local changed codex
  changed=$(jq -r '[.policies[] | select(.value != .default) | "\(.key)=\(.value)\(if .source == "project" then " (this project)" else "" end)"] | join(", ")' <<<"$j")
  codex=$(jq -r '.policies[] | select(.key == "model.codex") | .value' <<<"$j")
  local msg="[policy] The owner sets agent permissions in the menu bar policy panel; hooks enforce them live. An action the policy allows needs no approval request: do it (asking out of real caution is still fine). A blocked action is switched off by the owner: say so, never ask them to approve it. Read a value: bash ~/.claude/scripts/pol/pol.sh get <key> --cwd <dir>."
  [ -n "$changed" ] && msg="$msg Set away from defaults: $changed."
  [ "$codex" = "encourage" ] && msg="$msg Codex is encouraged: prefer a Codex seat for implementation and review work it fits."
  jq -cn --arg c "$msg" '{additionalContext: $c}'
}

sub="${1:-}"; shift || true
case "$sub" in
  get) cmd_get "$@";;
  set) cmd_set "$@";;
  snooze) cmd_snooze "$@";;
  unsnooze) cmd_unsnooze "$@";;
  clear) cmd_clear "$@";;
  json) cmd_json "$@";;
  list) cmd_list "$@";;
  inject) cmd_inject;;
  root) project_root "${1:-$PWD}";;
  ""|-h|--help|help) sed -n '2,31p' "$0" | sed 's/^# \{0,1\}//';;
  *) die "unknown command: $sub (try pol.sh help)" 64;;
esac
