#!/usr/bin/env bash
# gcc-schedule — manage user-level launchd schedules with Calendar companion.
#
# Why this exists: every one-shot we build needs a launchd plist + a shell
# script + a date-guard + self-unload + a Calendar event with retirement
# notes (per the calendar-companion contract in rules/scheduling-discipline.md).
# Doing that by hand is ~5
# files and ~30 lines of osascript every time. This tool collapses it to
# one command and guarantees the pieces stay in sync.
#
# Usage:
#   schedule.sh add  --name <slug> --at <YYYY-MM-DDTHH:MM> --command <shell> \
#                    [--description <text>] [--alert <minutes>] \
#                    [--no-calendar] [--no-bootstrap] [--force]
#   schedule.sh list [--all]
#   schedule.sh rm   <name>
#   schedule.sh help

set -uo pipefail

# ── Paths ──────────────────────────────────────────────────────────────────
SCHED_HOME="${GCC_SCHED_HOME:-$HOME/.claude/scheduled}"
LAUNCHAGENTS="${GCC_SCHED_LAUNCHAGENTS:-$HOME/Library/LaunchAgents}"
LOG_HOME="$HOME/.claude/logs/launchd"
REGISTRY="$SCHED_HOME/registry.json"
HIST="$SCHED_HOME/history.jsonl"
PROG="${0##*/}"
USER_UID=$(id -u)

mkdir -p "$SCHED_HOME" "$LOG_HOME"
[[ -f "$REGISTRY" ]] || echo '{}' > "$REGISTRY"

# ── Colors / output — std::claude::tui shared palette (both-fd TTY-gated) ────
# Sourcing colors.sh gives the BOTH-fd gate: every color var is blank whenever
# stdout OR stderr is not a real terminal (a pipe, a log, Claude's headless
# call), so no ANSI ever leaks into a captured stream. The fallback keeps the
# tool standalone if the shared lib is ever missing.
if [[ -r "$HOME/.claude/scripts/tui/colors.sh" ]]; then
  # shellcheck source=/dev/null
  . "$HOME/.claude/scripts/tui/colors.sh"; tui_colors_init
  YLW="$YEL"                                    # this tool's historical name for yellow
else
  if [[ -t 1 && -t 2 && -z "${NO_COLOR:-}" && "${TERM:-dumb}" != dumb ]]; then
    BLD=$'\033[1m'; RST=$'\033[0m'; DIM=$'\033[2m'
    RED=$'\033[31m'; GRN=$'\033[32m'; YLW=$'\033[1;33m'; CYN=$'\033[36m'
  else
    BLD=''; RST=''; DIM=''; RED=''; GRN=''; YLW=''; CYN=''
  fi
fi
say()  { printf '%s\n' "$*"; }
ok()   { printf '%s✓%s %s\n' "$GRN" "$RST" "$*"; }
warn() { printf '%s⚠%s %s\n' "$YLW" "$RST" "$*" >&2; }
err()  { printf '%s✗%s %s\n' "$RED" "$RST" "$*" >&2; }
fail() { err "$*"; exit 1; }

# ── Help ───────────────────────────────────────────────────────────────────
cmd_help() {
  cat <<HELP
${BLD}gcc-schedule${RST} — manage launchd schedules with Calendar companion

${DIM}Claude-facing usage contract: ~/.claude/scripts/schedule/INSTRUCTIONS.md${RST}

${BLD}USAGE${RST}
  $PROG ${CYN}-i${RST}${DIM}|--interactive${RST}          ${DIM}colored fuzzy browser — every command, for humans (needs a terminal)${RST}
  $PROG ${CYN}add${RST}     --name <slug> <schedule-mode> --command <shell> [opts]
                schedule-mode: --at <ISO> | --daily-at <HH:MM> | --weekly <dow> <HH:MM> | --monthly <day> <HH:MM>
  $PROG ${CYN}list${RST}    [--all]
  $PROG ${CYN}inventory${RST}                  survey ALL launchd plists + user crontab (read-only audit)
  $PROG ${CYN}doctor${RST} [--check-calendar]  drift audit (+ sweeps missed one-shots into history)
  $PROG ${CYN}history${RST} [--name N] [--outcome ok|failed|unknown|missed] [--ev added|modified|removed|run] [--limit N]
  $PROG ${CYN}status${RST}                     live count + all-time fire outcomes + recent fires
  $PROG ${CYN}reconcile${RST}                  log+retire one-shots that should have fired but never ran
  $PROG ${CYN}show${RST}    <name>             pretty-print details, state, next-fire countdown
  $PROG ${CYN}run${RST}     <name>             execute the user command now (no date guard, no self-unload)
  $PROG ${CYN}logs${RST}    <name> [--lines N] [--no-follow]   tail out + err logs
  $PROG ${CYN}enable${RST}  <name>             bootstrap a loaded-out plist (alias: resume)
  $PROG ${CYN}disable${RST} <name>             bootout the launchd agent, keep plist (alias: pause)
  $PROG ${CYN}duplicate${RST} <src> <new> [overrides...]  copy a schedule with optional --at/--command/etc.
  $PROG ${CYN}register${RST} <plist-path>      adopt an existing user LaunchAgent into the registry
  $PROG ${CYN}rm${RST}      <name>             retire fully (bootout + delete plist/script/Calendar event)

${BLD}add FLAGS${RST}
  --name <slug>            label = com.alcatraz.<slug> (required)
  --command <shell>        command to run, executed via bash -c (required)
  ── scheduling mode (exactly one required) ─────────────────────────────
  --at <ISO datetime>      one-shot: fire once at YYYY-MM-DDTHH:MM local
  --daily-at <HH:MM>       daily recurring: fire every day at HH:MM
  --weekly <dow> <HH:MM>   weekly recurring: fire every <dow> at HH:MM
  --monthly <day> <HH:MM>  monthly recurring: fire on <day> (1-31) of each month at HH:MM
                           dow ∈ {mon, tue, wed, thu, fri, sat, sun}
  ── optional ──────────────────────────────────────────────────────────
  --description <text>     Calendar event notes suffix
  --alert <minutes>        Calendar alarm minutes before (default 10; 0 = none)
  --env KEY=VAL            inject into plist EnvironmentVariables (repeatable)
  --working-dir <path>     plist WorkingDirectory (must be absolute)
  --no-calendar            skip Calendar event (against the calendar-companion contract)
  --no-bootstrap           write files but don't load into launchd
  --force                  overwrite existing schedule with same name
  --dry-run                print the PLANNED block + exit without creating anything

${BLD}NOTES${RST}
  Every 'add' prints a PLANNED block before any state mutation — Claude (and
  you) can verify the resolved spec before launchd takes the plist. --dry-run
  exits after the PLANNED block. --cron is intentionally absent: use the
  focused --daily-at / --weekly / --at flags instead (rationale + alternatives
  for non-fitting patterns in INSTRUCTIONS.md).

${BLD}EXAMPLES${RST}
  $PROG ${CYN}-i${RST}                                    ${DIM}# browse + act on schedules, or build one, interactively${RST}
  $PROG add --name backup-pull --at 2026-06-02T15:00 \\
    --command 'open -na Ghostty.app --args -e zsh -lc "rsync …"' \\
    --description 'Pull mac-migration backup before flight'

  $PROG add --name morning-digest --daily-at 09:00 \\
    --command 'i-dream digest >> ~/Documents/digests/\$(date +%F).md'

  $PROG add --name weekly-review --weekly fri 17:00 \\
    --command 'open ~/Documents/Reviews/template.md'

${BLD}NOTES${RST}
  One-shot schedules fire once, record the outcome to history.jsonl, then fully
  self-retire (no dead entry in the registry). Daily/weekly schedules record
  each fire and never retire — they run until '$PROG rm' or '$PROG disable'.
  Every lifecycle + fire event lands in history.jsonl (append-only); see
  '$PROG history' / '$PROG status'. Calendar companion is recurring (RRULE) for
  daily/weekly.

${BLD}DEFERRED (post-v0.4)${RST}
  Focused recurring flags if needed: --weekdays-at <HH:MM> (Mon-Fri),
  --every <duration> (interval / StartInterval).
  Add when a real use case appears, not pre-emptively.

${BLD}REGISTER NOTES${RST}
  'register <plist>' adopts an existing user LaunchAgent into the gcc-schedule
  registry without rewriting the plist. Constraints: file must live under
  $LAUNCHAGENTS, must lint clean, must have a Label starting with com.alcatraz.
  Adopted entries have command=null (the actual work lives in the external
  script we didn't author) and adopted=true. 'rm' of an adopted entry deletes
  the plist and our sched_dir but does NOT remove the external script or any
  Calendar event we didn't create — those are yours to clean up.

${BLD}FILES${RST}
  registry:    $REGISTRY
  history:     $HIST  (append-only ledger — rg/jq/Read directly)
  per-sched:   $SCHED_HOME/<name>/{script.sh, meta.json}
  plist:       $LAUNCHAGENTS/com.alcatraz.<name>.plist
  logs:        $LOG_HOME/<name>.{out,err}.log
HELP
}

# ── Helpers ────────────────────────────────────────────────────────────────
jq_inplace() {
  # jq_inplace <file> <filter>  — atomic in-place jq update
  local f="$1" filter="$2" tmp="${1}.tmp.$$"
  jq "$filter" "$f" > "$tmp" && mv "$tmp" "$f"
}

# ── History ledger (append-only) ───────────────────────────────────────────
# One JSON line per event in $HIST. Two small closed enums + open metadata:
#   ev      ∈ added | modified | removed | run
#   outcome ∈ ok | failed | unknown | missed   (only on `run` records)
# Everything else (reason, stage, exit, detail, cause) is free-form metadata —
# a new failure cause is a new reason STRING, never a schema change. Plain JSONL
# so a human or Claude can rg / jq / Read it directly. Never pruned.
ledger_append() {
  # ledger_append <ev> <name> [key value ...]
  local ev="$1" name="$2"; shift 2
  mkdir -p "$SCHED_HOME"
  local jqargs=(--arg ev "$ev" --arg name "$name" --arg ts "$(date -u '+%FT%TZ')")
  local filter='{ts:$ts,ev:$ev,name:$name'
  while [[ $# -ge 2 ]]; do
    jqargs+=(--arg "$1" "$2"); filter+=",$1:\$$1"; shift 2
  done
  filter+='}'
  jq -nc "${jqargs[@]}" "$filter" >> "$HIST"
}

# Record one scheduled occurrence. Called by the generated script.sh after the
# user command runs. The outcome derives from the exit code, but a command may
# override it (and add reason/stage/detail) by writing `key=value` lines to the
# file named in $GCC_SCHED_META — that's how a window launcher reports
# claude_missing (failed) or post_handoff (unknown) that a bare exit code can't.
cmd__record_run() {
  local name="$1" rc="${2:-0}" meta="${3:-}"
  local outcome reason="" stage="" detail=""
  if (( rc == 0 )); then outcome="ok"; else outcome="failed"; reason="cmd_error"; stage="cmd"; fi
  if [[ -n "$meta" && -f "$meta" ]]; then
    local k v
    while IFS='=' read -r k v; do
      case "$k" in
        outcome) outcome="$v" ;;
        reason)  reason="$v" ;;
        stage)   stage="$v" ;;
        detail)  detail="$v" ;;
      esac
    done < "$meta"
  fi
  local extra=(outcome "$outcome" exit "$rc")
  [[ -n "$reason" ]] && extra+=(reason "$reason")
  [[ -n "$stage"  ]] && extra+=(stage "$stage")
  [[ -n "$detail" ]] && extra+=(detail "$detail")
  ledger_append run "$name" "${extra[@]}"
}

# Full self-retire after a one-shot fires: log the removal, then tear down every
# surface EXCEPT the launchd bootout — the generated script issues that itself,
# last, because booting out the still-running job may terminate this process.
# Safe to delete our own sched_dir: the generated script wraps its body in
# main(), so the whole script is already in memory.
cmd__retire_self() {
  local name="$1" entry label plist cal_uid
  entry=$(jq -r --arg n "$name" '.[$n] // empty' "$REGISTRY")
  ledger_append removed "$name" cause fired-complete
  [[ -n "$entry" ]] || return 0
  plist=$(jq -r '.plist' <<<"$entry")
  cal_uid=$(jq -r '.calendar_uid // ""' <<<"$entry")
  [[ -e "$plist" ]] && rm -f "$plist"
  [[ -d "$SCHED_HOME/$name" ]] && rm -rf "$SCHED_HOME/$name"
  [[ -n "$cal_uid" ]] && calendar_delete "$cal_uid" >/dev/null 2>&1
  jq_inplace "$REGISTRY" "del(.[\"$name\"])"
  return 0
}

# Detect one-shots that should have fired but left no `run` record — the
# machine-was-off / launchd-gap class that cannot self-report (their script
# never ran). For each past-due one-shot with no run line: log outcome=missed
# and retire it. Recurring schedules are skipped (no single fire_at to be past).
# Echoes the count swept.
reconcile_missed() {
  local now name fire_at fe has_run swept=0
  now=$(date +%s)
  while IFS=$'\t' read -r name fire_at; do
    [[ -n "$name" ]] || continue
    fe=$(date -j -f '%Y-%m-%dT%H:%M' "$fire_at" '+%s' 2>/dev/null) || continue
    (( fe < now - 120 )) || continue
    has_run=0
    [[ -f "$HIST" ]] && has_run=$(jq -s --arg n "$name" '[.[]|select(.ev=="run" and .name==$n)]|length' "$HIST" 2>/dev/null || echo 0)
    (( has_run == 0 )) || continue
    ledger_append run "$name" outcome missed reason machine_off_or_stale detail "fire_at $fire_at passed with no run record"
    ledger_append removed "$name" cause missed-sweep
    _retire "$name" silent
    swept=$((swept+1))
  done < <(jq -r 'to_entries[]|select(.value.kind=="one-shot")|"\(.key)\t\(.value.fire_at)"' "$REGISTRY" 2>/dev/null)
  echo "$swept"
}

validate_name() {
  [[ "$1" =~ ^[a-z][a-z0-9-]{1,40}$ ]] || \
    fail "name '$1' must be kebab-case, start with letter, 2-41 chars"
}

# parse_at "<YYYY-MM-DDTHH:MM>" → sets PARSED_Y PARSED_MO PARSED_D PARSED_H PARSED_M.
# Global-var pattern (same reasoning as parse_hhmm — fail() must reach caller's shell).
parse_at() {
  local at="$1"
  [[ "$at" =~ ^([0-9]{4})-([0-9]{2})-([0-9]{2})T([0-9]{2}):([0-9]{2})$ ]] || \
    fail "--at must be YYYY-MM-DDTHH:MM (24-hour local time)"
  PARSED_Y="${BASH_REMATCH[1]}"
  PARSED_MO=$((10#${BASH_REMATCH[2]}))
  PARSED_D=$((10#${BASH_REMATCH[3]}))
  PARSED_H=$((10#${BASH_REMATCH[4]}))
  PARSED_M=$((10#${BASH_REMATCH[5]}))
  (( PARSED_MO >= 1 && PARSED_MO <= 12 )) || fail "month $PARSED_MO out of range"
  (( PARSED_D  >= 1 && PARSED_D  <= 31 )) || fail "day $PARSED_D out of range"
  (( PARSED_H  >= 0 && PARSED_H  <= 23 )) || fail "hour $PARSED_H out of range"
  (( PARSED_M  >= 0 && PARSED_M  <= 59 )) || fail "minute $PARSED_M out of range"
  local epoch now
  epoch=$(date -j -f '%Y-%m-%dT%H:%M' "$at" +%s 2>/dev/null) || \
    fail "could not parse --at '$at' as a date"
  now=$(date +%s)
  (( epoch > now - 60 )) || fail "--at $at is in the past"
}

# xml_escape <string> — escape &, <, > for safe embedding in a plist <string>.
# Apostrophes and double-quotes don't need escaping inside the XML body, only
# inside attribute values (which we don't produce). Keeps the body readable.
xml_escape() {
  local s="$1"
  s="${s//&/&amp;}"
  s="${s//</&lt;}"
  s="${s//>/&gt;}"
  printf '%s' "$s"
}

# AppleScript month names (Calendar.app expects English month constant)
month_name() {
  local arr=(January February March April May June July August September October November December)
  echo "${arr[$(( $1 - 1 ))]}"
}

# parse_hhmm "HH:MM" → sets PARSED_H + PARSED_M (no leading zeros).
# Global-var pattern (sister to _vlen → _VLEN) so fail() runs in the caller's
# shell, not a subshell — process-substitution capture would silently lose
# fail()'s exit and produce empty values downstream.
parse_hhmm() {
  local hhmm="$1"
  [[ "$hhmm" =~ ^([0-9]{2}):([0-9]{2})$ ]] || fail "expected HH:MM 24-hour, got '$hhmm'"
  PARSED_H=$((10#${BASH_REMATCH[1]}))
  PARSED_M=$((10#${BASH_REMATCH[2]}))
  (( PARSED_H >= 0 && PARSED_H <= 23 )) || fail "hour out of range: $PARSED_H"
  (( PARSED_M >= 0 && PARSED_M <= 59 )) || fail "minute out of range: $PARSED_M"
}

# parse_dow <mon|tue|...|sun> → sets PARSED_DOW (0=Sun..6=Sat) + PARSED_BYDAY (SU/MO/...).
# Uses `tr` for lowercase rather than ${var,,} — macOS bash is 3.2, which
# lacks bash-4 case-modification parameter expansion (per CLAUDE.md).
parse_dow() {
  local in_low
  in_low=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')
  case "$in_low" in
    sun|sunday)    PARSED_DOW=0; PARSED_BYDAY=SU ;;
    mon|monday)    PARSED_DOW=1; PARSED_BYDAY=MO ;;
    tue|tuesday)   PARSED_DOW=2; PARSED_BYDAY=TU ;;
    wed|wednesday) PARSED_DOW=3; PARSED_BYDAY=WE ;;
    thu|thursday)  PARSED_DOW=4; PARSED_BYDAY=TH ;;
    fri|friday)    PARSED_DOW=5; PARSED_BYDAY=FR ;;
    sat|saturday)  PARSED_DOW=6; PARSED_BYDAY=SA ;;
    *) fail "expected day-of-week mon|tue|wed|thu|fri|sat|sun, got '$1'" ;;
  esac
}

# next_daily_start <H> <M> → echoes "Y MO D H MI" — the first future occurrence
next_daily_start() {
  local h="$1" m="$2"
  local now_sod target_sod days=0
  now_sod=$(( $(date +%H | sed 's/^0//') * 3600 + $(date +%M | sed 's/^0//') * 60 + $(date +%S | sed 's/^0//') ))
  target_sod=$(( h * 3600 + m * 60 ))
  (( target_sod <= now_sod )) && days=1
  read y mo d <<< "$(date -j -v +"${days}"d "+%Y %m %d")"
  echo "$y $((10#$mo)) $((10#$d)) $h $m"
}

# next_weekly_start <target_dow 0-6> <H> <M> → echoes "Y MO D H MI"
next_weekly_start() {
  local tdow="$1" h="$2" m="$3"
  local today_dow now_sod target_sod days
  today_dow=$(date +%w)
  now_sod=$(( $(date +%H | sed 's/^0//') * 3600 + $(date +%M | sed 's/^0//') * 60 + $(date +%S | sed 's/^0//') ))
  target_sod=$(( h * 3600 + m * 60 ))
  days=$(( (tdow - today_dow + 7) % 7 ))
  # If "today" and the time is already past, push to next week.
  if (( days == 0 )) && (( target_sod <= now_sod )); then days=7; fi
  read y mo d <<< "$(date -j -v +"${days}"d "+%Y %m %d")"
  echo "$y $((10#$mo)) $((10#$d)) $h $m"
}

# next_monthly_start <day-of-month> <H> <M> → echoes "Y MO D H MI" — the first
# future occurrence on that day-of-month. Recurrence is carried by the plist's
# StartCalendarInterval Day key + the Calendar RRULE; this only seeds the first
# Calendar event.
next_monthly_start() {
  local td="$1" h="$2" m="$3"
  local cy cmo cd now_sod target_sod
  cy=$(date +%Y); cmo=$((10#$(date +%m))); cd=$((10#$(date +%d)))
  now_sod=$(( $(date +%H | sed 's/^0//') * 3600 + $(date +%M | sed 's/^0//') * 60 + $(date +%S | sed 's/^0//') ))
  target_sod=$(( h * 3600 + m * 60 ))
  if (( cd < td )) || { (( cd == td )) && (( target_sod > now_sod )); }; then
    echo "$cy $cmo $td $h $m"
  else
    cmo=$((cmo + 1)); (( cmo > 12 )) && { cmo=1; cy=$((cy + 1)); }
    echo "$cy $cmo $td $h $m"
  fi
}

# ── Calendar event ─────────────────────────────────────────────────────────
calendar_create() {
  # calendar_create <year> <month> <day> <hour> <minute> <summary> <notes> <alert_minutes> [rrule]
  # rrule (optional) — e.g. "FREQ=DAILY" or "FREQ=WEEKLY;BYDAY=MO". When empty,
  # creates a single non-recurring event (one-shot).
  local y="$1" mo="$2" d="$3" h="$4" mi="$5" sum="$6" notes="$7" alert="$8" rrule="${9:-}"
  local mname; mname=$(month_name "$mo")
  local alarm=""
  if (( alert > 0 )); then
    alarm="    make new sound alarm at end of newEvent with properties {trigger interval:-$alert}"
  fi
  local rec=""
  if [[ -n "$rrule" ]]; then
    # Calendar.app's `recurrence` property is set after the event is made.
    rec="    set recurrence of newEvent to \"$rrule\""
  fi
  osascript <<APPLESCRIPT 2>/dev/null
tell application "Calendar"
  if not (exists calendar "Automations") then
    make new calendar with properties {name:"Automations"}
  end if
  tell calendar "Automations"
    set startDate to (current date)
    set year of startDate to $y
    set month of startDate to $mname
    set day of startDate to $d
    set hours of startDate to $h
    set minutes of startDate to $mi
    set seconds of startDate to 0
    set newEvent to make new event with properties {summary:"$sum", start date:startDate, end date:(startDate + 15 * minutes), description:"$notes"}
$rec
$alarm
    return uid of newEvent
  end tell
end tell
APPLESCRIPT
}

calendar_delete() {
  # calendar_delete <event_uid>
  local uid="$1"
  [[ -z "$uid" ]] && return 0
  osascript <<APPLESCRIPT 2>/dev/null
tell application "Calendar"
  tell calendar "Automations"
    set evList to (every event whose uid is "$uid")
    repeat with ev in evList
      delete ev
    end repeat
  end tell
end tell
APPLESCRIPT
}

# ── Script + plist templates ───────────────────────────────────────────────
write_oneshot_script() {
  # write_oneshot_script <path> <iso_fire_date YYYY-MM-DD> <command> <label> <plist> <name>
  local out="$1" fire_date="$2" cmd="$3" label="$4" plist="$5" name="$6"
  cat > "$out" <<SCRIPT
#!/usr/bin/env bash
# Generated by gcc-schedule on $(date '+%F %T %Z').
# One-shot launchd target: fires once on $fire_date local time, records the
# outcome to history.jsonl, then fully retires itself — no dead entry left.
set -uo pipefail

# The body is wrapped in main() so bash reads the whole script into memory
# before running it — that makes deleting our own sched_dir during self-retire
# safe (the file can vanish mid-run without breaking the remaining lines).
main() {
  local LABEL="$label" NAME="$name" FIRE_DATE="$fire_date" USER_UID=$USER_UID
  local SCHED="\$HOME/.claude/scripts/schedule/schedule.sh"

  # Date guard: StartCalendarInterval has no Year key, so without this the plist
  # re-fires every year on the same date. A non-matching day is not a fire — no
  # history record, no retire.
  local today; today=\$(date '+%Y-%m-%d')
  if [[ "\$today" != "\$FIRE_DATE" ]]; then
    echo "[\$today] not the intended fire date \$FIRE_DATE — exiting"
    return 0
  fi

  echo "[\$(date '+%F %T')] running scheduled command"
  # A command can refine its own outcome (a window launcher reporting
  # claude_missing / post_handoff that a bare exit code can't) by writing
  # key=value lines to \$GCC_SCHED_META.
  local META; META=\$(mktemp 2>/dev/null || echo "/tmp/gcc-sched.\$\$")
  export GCC_SCHED_META="\$META"
  bash -c $(printf %q "$cmd")
  local rc=\$?

  "\$SCHED" _record-run "\$NAME" "\$rc" "\$META" 2>/dev/null || true
  rm -f "\$META" 2>/dev/null || true
  "\$SCHED" _retire-self "\$NAME" 2>/dev/null || true

  # bootout LAST: it may terminate this still-running job, so everything that
  # must persist (history, registry cleanup) is already done above.
  echo "[\$(date '+%F %T')] self-unloading \$LABEL"
  launchctl bootout "gui/\$USER_UID/\$LABEL" 2>/dev/null || true
  return 0
}
main "\$@"
SCRIPT
  chmod +x "$out"
}

write_plist() {
  # write_plist <path> <label> <script_path> <month> <day> <hour> <minute> <out_log> <err_log> [extra_xml]
  # extra_xml — optional pre-built XML chunk for EnvironmentVariables / WorkingDirectory.
  local plist="$1" label="$2" script="$3" mo="$4" d="$5" h="$6" mi="$7" outlog="$8" errlog="$9" extra="${10:-}"
  cat > "$plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key><string>$label</string>
    <key>ProgramArguments</key>
    <array>
        <string>$script</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Month</key><integer>$mo</integer>
        <key>Day</key><integer>$d</integer>
        <key>Hour</key><integer>$h</integer>
        <key>Minute</key><integer>$mi</integer>
    </dict>${extra:+
$extra}
    <key>StandardOutPath</key>
    <string>$outlog</string>
    <key>StandardErrorPath</key>
    <string>$errlog</string>
    <key>RunAtLoad</key><false/>
</dict>
</plist>
PLIST
}

# ── v0.3: recurring schedules (daily / weekly) ────────────────────────────
# Recurring scripts do NOT carry a date guard and do NOT self-unload — the
# whole point of recurring is "fire every time". The launchd plist's
# StartCalendarInterval carries the schedule (Hour+Minute for daily;
# Weekday+Hour+Minute for weekly).
write_recurring_script() {
  # write_recurring_script <path> <kind> <when_human> <command> <name>
  local out="$1" kind="$2" when="$3" cmd="$4" name="$5"
  cat > "$out" <<SCRIPT
#!/usr/bin/env bash
# Generated by gcc-schedule on $(date '+%F %T %Z').
# Recurring launchd target — kind=$kind, when=$when. Records each fire to
# history.jsonl; never self-retires (recurring fires until rm / disable).
set -uo pipefail
NAME="$name"
SCHED="\$HOME/.claude/scripts/schedule/schedule.sh"
echo "[\$(date '+%F %T')] running scheduled command ($kind)"
META=\$(mktemp 2>/dev/null || echo "/tmp/gcc-sched.\$\$")
export GCC_SCHED_META="\$META"
bash -c $(printf %q "$cmd")
rc=\$?
"\$SCHED" _record-run "\$NAME" "\$rc" "\$META" 2>/dev/null || true
rm -f "\$META" 2>/dev/null || true
exit \$rc
SCRIPT
  chmod +x "$out"
}

write_plist_recurring() {
  # write_plist_recurring <path> <label> <script> <sci_xml> <outlog> <errlog> [extra_xml]
  local plist="$1" label="$2" script="$3" sci="$4" outlog="$5" errlog="$6" extra="${7:-}"
  cat > "$plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key><string>$label</string>
    <key>ProgramArguments</key>
    <array>
        <string>$script</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
$sci
    </dict>${extra:+
$extra}
    <key>StandardOutPath</key>
    <string>$outlog</string>
    <key>StandardErrorPath</key>
    <string>$errlog</string>
    <key>RunAtLoad</key><false/>
</dict>
</plist>
PLIST
}

# ── add ────────────────────────────────────────────────────────────────────
cmd_add() {
  local name="" at="" daily_at="" weekly_dow="" weekly_at="" monthly_day="" monthly_at=""
  local cmd_str="" desc="" alert="10" working_dir=""
  local do_calendar=1 do_bootstrap=1 force=0 dry_run=0
  local env_pairs=()

  while (( $# )); do
    case "$1" in
      --name)         name="$2"; shift 2 ;;
      --at)           at="$2"; shift 2 ;;
      --daily-at)     daily_at="$2"; shift 2 ;;
      --weekly)       weekly_dow="$2"; weekly_at="$3"; shift 3 ;;
      --monthly)      monthly_day="$2"; monthly_at="$3"; shift 3 ;;
      --command)      cmd_str="$2"; shift 2 ;;
      --description)  desc="$2"; shift 2 ;;
      --alert)        alert="$2"; shift 2 ;;
      --env)          env_pairs+=("$2"); shift 2 ;;
      --working-dir)  working_dir="$2"; shift 2 ;;
      --no-calendar)  do_calendar=0; shift ;;
      --no-bootstrap) do_bootstrap=0; shift ;;
      --force)        force=1; shift ;;
      --dry-run)      dry_run=1; shift ;;
      --cron)         fail "--cron is intentionally absent — use --daily-at <HH:MM>, --weekly <dow> <HH:MM>, --monthly <day> <HH:MM>, or --at <ISO>. See 'help' or INSTRUCTIONS.md." ;;
      -h|--help)      cmd_help; exit 0 ;;
      *) fail "unknown flag: $1 (try '$PROG help')" ;;
    esac
  done

  [[ -n "$name"    ]] || fail "--name is required"
  [[ -n "$cmd_str" ]] || fail "--command is required"
  validate_name "$name"
  [[ "$alert" =~ ^[0-9]+$ ]] || fail "--alert must be a non-negative integer"

  # Mutual exclusion: exactly one scheduling mode required.
  local mode_count=0
  [[ -n "$at" ]]         && mode_count=$((mode_count + 1))
  [[ -n "$daily_at" ]]   && mode_count=$((mode_count + 1))
  [[ -n "$weekly_dow" ]] && mode_count=$((mode_count + 1))
  [[ -n "$monthly_day" ]] && mode_count=$((mode_count + 1))
  (( mode_count == 1 )) || fail "exactly one of --at <ISO>, --daily-at <HH:MM>, --weekly <dow> <HH:MM>, --monthly <day> <HH:MM> required (got $mode_count)"

  local kind
  if   [[ -n "$at" ]];         then kind="one-shot"
  elif [[ -n "$daily_at" ]];   then kind="daily"
  elif [[ -n "$weekly_dow" ]]; then kind="weekly"
  else                              kind="monthly"
  fi

  # ── Validate + build EnvironmentVariables / WorkingDirectory plist chunks ─
  # Done BEFORE mkdir so a bad --env or --working-dir doesn't litter sched_dir.
  local env_xml="" workdir_xml=""
  if (( ${#env_pairs[@]} > 0 )); then
    env_xml="    <key>EnvironmentVariables</key>
    <dict>"
    local pair pkey pval pval_x
    for pair in "${env_pairs[@]}"; do
      [[ "$pair" == *=* ]] || fail "--env '$pair' must be KEY=VALUE"
      pkey="${pair%%=*}"
      pval="${pair#*=}"
      [[ "$pkey" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || fail "--env key '$pkey' invalid (must match [A-Za-z_][A-Za-z0-9_]*)"
      pval_x=$(xml_escape "$pval")
      env_xml="$env_xml
        <key>$pkey</key><string>$pval_x</string>"
    done
    env_xml="$env_xml
    </dict>"
  fi
  if [[ -n "$working_dir" ]]; then
    [[ "$working_dir" == /* ]] || fail "--working-dir must be an absolute path, got '$working_dir'"
    [[ -d "$working_dir" ]] || warn "--working-dir '$working_dir' does not exist (will be a runtime error when the schedule fires)"
    local wd_x; wd_x=$(xml_escape "$working_dir")
    workdir_xml="    <key>WorkingDirectory</key><string>$wd_x</string>"
  fi
  local extra_xml=""
  [[ -n "$env_xml" ]] && extra_xml="$env_xml"
  [[ -n "$workdir_xml" ]] && extra_xml="${extra_xml:+$extra_xml
}$workdir_xml"

  local label="com.alcatraz.${name}"
  local sched_dir="$SCHED_HOME/$name"
  local script="$sched_dir/script.sh"
  local meta="$sched_dir/meta.json"
  local plist="$LAUNCHAGENTS/${label}.plist"
  local outlog="$LOG_HOME/${name}.out.log"
  local errlog="$LOG_HOME/${name}.err.log"

  if [[ -e "$plist" ]] || [[ -e "$sched_dir" ]]; then
    if (( force )); then
      warn "overwriting existing schedule '$name' (--force)"
      _retire "$name" silent
    else
      fail "schedule '$name' already exists. Use --force to overwrite, or '$PROG rm $name'."
    fi
  fi

  # ── Per-kind PARSE-ONLY block — set computed vars; no side effects ─────────
  # All file creation deferred until AFTER the PLANNED block prints, so Claude
  # and the user get a chance to read the resolved spec before launchd takes
  # the plist.
  local fire_at_meta="" cal_y cal_mo cal_d cal_h cal_mi cal_summary cal_notes cal_rrule=""
  local sci_xml="" when_human="" fire_date="" y mo d h mi tdow byday dow_low

  case "$kind" in
    one-shot)
      parse_at "$at"
      y=$PARSED_Y; mo=$PARSED_MO; d=$PARSED_D; h=$PARSED_H; mi=$PARSED_M
      fire_date="$y-$(printf '%02d' $mo)-$(printf '%02d' $d)"
      fire_at_meta="$at"
      when_human="ONCE on $fire_date $(printf '%02d:%02d' $h $mi) local time then self-unloads"
      cal_y="$y"; cal_mo="$mo"; cal_d="$d"; cal_h="$h"; cal_mi="$mi"
      cal_summary="[cron-once] $name — fires $fire_date $(printf '%02d:%02d' $h $mi)"
      ;;

    daily)
      parse_hhmm "$daily_at"
      h=$PARSED_H; mi=$PARSED_M
      sci_xml="        <key>Hour</key><integer>$h</integer>
        <key>Minute</key><integer>$mi</integer>"
      fire_at_meta="daily@$(printf '%02d:%02d' $h $mi)"
      when_human="DAILY at $(printf '%02d:%02d' $h $mi) local time (recurring; does not self-unload)"
      read -r cal_y cal_mo cal_d cal_h cal_mi < <(next_daily_start "$h" "$mi")
      cal_summary="[cron-daily] $name — fires daily at $(printf '%02d:%02d' $h $mi)"
      cal_rrule="FREQ=DAILY"
      ;;

    weekly)
      parse_dow "$weekly_dow"
      tdow=$PARSED_DOW; byday=$PARSED_BYDAY
      dow_low=$(printf '%s' "$weekly_dow" | tr '[:upper:]' '[:lower:]')
      parse_hhmm "$weekly_at"
      h=$PARSED_H; mi=$PARSED_M
      sci_xml="        <key>Weekday</key><integer>$tdow</integer>
        <key>Hour</key><integer>$h</integer>
        <key>Minute</key><integer>$mi</integer>"
      fire_at_meta="weekly@$dow_low@$(printf '%02d:%02d' $h $mi)"
      when_human="WEEKLY on $dow_low at $(printf '%02d:%02d' $h $mi) local time (recurring; does not self-unload)"
      read -r cal_y cal_mo cal_d cal_h cal_mi < <(next_weekly_start "$tdow" "$h" "$mi")
      cal_summary="[cron-weekly] $name — fires every $dow_low at $(printf '%02d:%02d' $h $mi)"
      cal_rrule="FREQ=WEEKLY;BYDAY=$byday"
      ;;

    monthly)
      [[ "$monthly_day" =~ ^[0-9]{1,2}$ ]] && (( monthly_day >= 1 && monthly_day <= 31 )) \
        || fail "--monthly day must be an integer 1-31, got '$monthly_day'"
      (( monthly_day <= 28 )) || warn "--monthly day $monthly_day is absent from some months; launchd skips those months (use 1-28 to fire every month)"
      parse_hhmm "$monthly_at"
      h=$PARSED_H; mi=$PARSED_M
      sci_xml="        <key>Day</key><integer>$monthly_day</integer>
        <key>Hour</key><integer>$h</integer>
        <key>Minute</key><integer>$mi</integer>"
      fire_at_meta="monthly@day$monthly_day@$(printf '%02d:%02d' $h $mi)"
      when_human="MONTHLY on day $monthly_day at $(printf '%02d:%02d' $h $mi) local time (recurring; does not self-unload)"
      read -r cal_y cal_mo cal_d cal_h cal_mi < <(next_monthly_start "$monthly_day" "$h" "$mi")
      cal_summary="[cron-monthly] $name — fires day $monthly_day at $(printf '%02d:%02d' $h $mi)"
      cal_rrule="FREQ=MONTHLY;BYMONTHDAY=$monthly_day"
      ;;
  esac

  # cal_notes shape is the same across kinds — keep it DRY here.
  cal_notes="label: $label
runs: $script
plist: $plist
out log: $outlog
err log: $errlog
fires: $when_human
managed-by: gcc-schedule
retire: '$PROG rm $name' or 'launchctl bootout gui/$USER_UID/$label' + delete this event${desc:+

$desc}"

  # ── PLANNED block — print BEFORE any state mutation ───────────────────────
  # Always prints (default-on). Claude can self-check the resolved spec; user
  # can read. --dry-run exits here, leaving zero artifacts.
  local plan_calendar="(skipped — --no-calendar)"
  if (( do_calendar )); then
    plan_calendar="yes${cal_rrule:+, recurrence: $cal_rrule}, alert ${alert}m before"
  fi
  local plan_bootstrap="(skipped — --no-bootstrap)"
  (( do_bootstrap )) && plan_bootstrap="yes (will be loaded into gui/$USER_UID)"
  printf '\n%s%s%s\n' "$BLD" "PLANNED:" "$RST"
  printf '  %-12s %s\n' "name:"    "$name"
  printf '  %-12s %s\n' "label:"   "$label"
  printf '  %-12s %s\n' "kind:"    "$kind"
  printf '  %-12s %s\n' "fires:"   "$when_human"
  printf '  %-12s %s\n' "fire_at:" "$fire_at_meta"
  if [[ -n "$working_dir" ]]; then
    printf '  %-12s %s\n' "workdir:" "$working_dir"
  fi
  if (( ${#env_pairs[@]} > 0 )); then
    printf '  %-12s %d var(s):\n' "env:" "${#env_pairs[@]}"
    printf '    %s\n' "${env_pairs[@]}"
  fi
  printf '  %-12s %s\n' "calendar:"  "$plan_calendar"
  printf '  %-12s %s\n' "bootstrap:" "$plan_bootstrap"
  printf '  %-12s\n    %s%s%s\n' "command:" "$DIM" "$cmd_str" "$RST"

  if (( dry_run )); then
    printf '\n%s[--dry-run set, NOT creating]%s\n\n' "$YLW" "$RST"
    return 0
  fi

  # ── Write phase: mkdir + script + plist (unified, kind-dispatched) ────────
  mkdir -p "$sched_dir"
  if [[ "$kind" == "one-shot" ]]; then
    write_oneshot_script "$script" "$fire_date" "$cmd_str" "$label" "$plist" "$name"
    write_plist "$plist" "$label" "$script" "$mo" "$d" "$h" "$mi" "$outlog" "$errlog" "$extra_xml"
  else
    # 2nd arg to write_recurring_script is the human label embedded as a
    # comment — first word of $when_human ("DAILY"/"WEEKLY") plus time.
    local when_short; when_short=$(printf '%s' "$when_human" | awk '{print tolower($1) " " $3}')
    write_recurring_script "$script" "$kind" "$when_short" "$cmd_str" "$name"
    write_plist_recurring "$plist" "$label" "$script" "$sci_xml" "$outlog" "$errlog" "$extra_xml"
  fi

  # ── Lint plist (same for all kinds) ───────────────────────────────────────
  if ! plutil -lint "$plist" >/dev/null; then
    rm -f "$plist"; rm -rf "$sched_dir"
    fail "plist lint failed — rolled back"
  fi

  # ── Calendar event ────────────────────────────────────────────────────────
  local cal_uid=""
  if (( do_calendar )); then
    cal_uid=$(calendar_create "$cal_y" "$cal_mo" "$cal_d" "$cal_h" "$cal_mi" "$cal_summary" "$cal_notes" "$alert" "$cal_rrule" | tail -1)
    if [[ -z "$cal_uid" ]]; then
      warn "Calendar event creation returned empty UID — Automations permission for osascript? (event NOT created)"
    else
      ok "Calendar event: $cal_uid${cal_rrule:+ (recurrence: $cal_rrule)}"
    fi
  else
    warn "Calendar event skipped per --no-calendar (against the calendar-companion contract)"
  fi

  # ── Bootstrap ─────────────────────────────────────────────────────────────
  if (( do_bootstrap )); then
    if launchctl bootstrap "gui/$USER_UID" "$plist" 2>&1; then
      ok "loaded into launchd (gui/$USER_UID/$label)"
    else
      warn "bootstrap failed — files written but agent not loaded"
    fi
  else
    warn "skipped bootstrap per --no-bootstrap (load later with: launchctl bootstrap gui/$USER_UID $plist)"
  fi

  # ── Meta + registry ───────────────────────────────────────────────────────
  # env_vars JSON: build via jq so KEY=VALUE strings are properly quoted, even
  # with characters that would break a here-doc-and-sed approach.
  local env_json="[]"
  if (( ${#env_pairs[@]} > 0 )); then
    env_json=$(printf '%s\n' "${env_pairs[@]}" | jq -Rs 'split("\n") | map(select(length > 0))')
  fi
  cat > "$meta" <<META
{
  "name": "$name",
  "label": "$label",
  "kind": "$kind",
  "fire_at": "$fire_at_meta",
  "command": $(printf '%s' "$cmd_str" | jq -Rs .),
  "description": $(printf '%s' "$desc" | jq -Rs .),
  "env_vars": $env_json,
  "working_dir": $(printf '%s' "$working_dir" | jq -Rs .),
  "calendar_uid": "$cal_uid",
  "created_at": "$(date -u '+%FT%TZ')",
  "plist": "$plist",
  "script": "$script",
  "out_log": "$outlog",
  "err_log": "$errlog"
}
META
  jq_inplace "$REGISTRY" ". + {\"$name\": $(cat "$meta")}"
  ledger_append added "$name" kind "$kind" fire_at "$fire_at_meta"
  ok "registered: $name"

  printf '\n%sscript: %s\n  plist:  %s\n  fires:  %s\n  retire: %s rm %s%s\n' \
    "$DIM" "$script" "$plist" "$fire_at_meta" "$PROG" "$name" "$RST"
}

# ── list ───────────────────────────────────────────────────────────────────
cmd_list() {
  local show_all=0
  [[ "${1:-}" == "--all" ]] && show_all=1

  say "${BLD}gcc-managed schedules${RST}"
  local count
  count=$(jq -r 'keys | length' "$REGISTRY")
  if (( count == 0 )); then
    say "  ${DIM}(none)${RST}"
  else
    jq -r 'to_entries[] | "  \(.key)\t\(.value.kind)\t\(.value.fire_at)\t\(.value.label)"' "$REGISTRY" | \
      column -t -s $'\t'
  fi

  if (( show_all )); then
    say
    say "${BLD}other com.alcatraz.* LaunchAgents${RST} ${DIM}(read-only — not managed by gcc-schedule)${RST}"
    local found=0
    for p in "$LAUNCHAGENTS"/com.alcatraz.*.plist; do
      [[ -e "$p" ]] || continue
      local lbl; lbl=$(basename "$p" .plist)
      local short="${lbl#com.alcatraz.}"
      # skip if in our registry
      if jq -e --arg n "$short" '.[$n]' "$REGISTRY" >/dev/null 2>&1; then continue; fi
      say "  $lbl"
      found=1
    done
    (( found )) || say "  ${DIM}(none)${RST}"
  fi
}

# ── rm ─────────────────────────────────────────────────────────────────────
_retire() {
  # _retire <name> [silent]
  local name="$1" mode="${2:-loud}"
  local entry; entry=$(jq -r --arg n "$name" '.[$n] // empty' "$REGISTRY")
  if [[ -z "$entry" ]]; then
    [[ "$mode" == silent ]] && return 0
    fail "no schedule named '$name' in registry. Try '$PROG list --all' to see unmanaged ones."
  fi
  local label plist sched_dir cal_uid adopted ext_script
  label=$(jq -r '.label' <<<"$entry")
  plist=$(jq -r '.plist' <<<"$entry")
  sched_dir="$SCHED_HOME/$name"
  cal_uid=$(jq -r '.calendar_uid // ""' <<<"$entry")
  adopted=$(jq -r '.adopted // false' <<<"$entry")
  ext_script=$(jq -r '.script // ""' <<<"$entry")
  # Adopted entries: warn loudly so the user knows what we're NOT cleaning up.
  # The plist itself we DO remove (we adopted ownership); the external script
  # and any existing Calendar event are the user's to clean up.
  if [[ "$adopted" == "true" && "$mode" != silent ]]; then
    warn "adopted entry — external script will NOT be removed: $ext_script"
    [[ -z "$cal_uid" ]] && warn "adopted entry — no Calendar event UID stored; clean up any companion event manually"
  fi

  # bootout
  if launchctl print "gui/$USER_UID/$label" >/dev/null 2>&1; then
    launchctl bootout "gui/$USER_UID/$label" 2>/dev/null && \
      { [[ "$mode" != silent ]] && ok "bootout: $label"; }
  fi
  # remove plist
  [[ -e "$plist" ]] && rm -f "$plist" && { [[ "$mode" != silent ]] && ok "removed: $plist"; }
  # remove sched dir
  [[ -e "$sched_dir" ]] && rm -rf "$sched_dir" && { [[ "$mode" != silent ]] && ok "removed: $sched_dir"; }
  # delete Calendar event
  if [[ -n "$cal_uid" ]]; then
    calendar_delete "$cal_uid" && { [[ "$mode" != silent ]] && ok "Calendar event deleted: $cal_uid"; }
  fi
  # registry
  jq_inplace "$REGISTRY" "del(.[\"$name\"])"
  [[ "$mode" != silent ]] && ok "unregistered: $name"
  return 0
}

cmd_rm() {
  [[ $# -ge 1 ]] || fail "usage: $PROG rm <name>"
  jq -e --arg n "$1" '.[$n]' "$REGISTRY" >/dev/null 2>&1 && ledger_append removed "$1" cause user
  _retire "$1"
}

# ── Helpers (v0.2) ─────────────────────────────────────────────────────────
_get_entry() {
  # Echo JSON for the registry entry, or fail with a clear message.
  local name="$1" entry
  entry=$(jq -r --arg n "$name" '.[$n] // empty' "$REGISTRY")
  [[ -n "$entry" ]] || fail "no schedule named '$name'. Try '$PROG list' or '$PROG list --all'."
  printf '%s' "$entry"
}

_is_loaded() {
  # Return 0 iff the launchd agent for <label> is currently bootstrapped.
  launchctl print "gui/$USER_UID/$1" >/dev/null 2>&1
}

# ── run ────────────────────────────────────────────────────────────────────
cmd_run() {
  [[ $# -ge 1 ]] || fail "usage: $PROG run <name>"
  local name="$1" entry cmd_str script_path
  entry=$(_get_entry "$name")
  cmd_str=$(jq -r '.command' <<<"$entry")
  if [[ -z "$cmd_str" || "$cmd_str" == "null" ]]; then
    # Adopted entries don't carry the command — point the user at the script.
    script_path=$(jq -r '.script' <<<"$entry")
    fail "no inline command for adopted entry '$name'. Test-fire its external script directly: bash '$script_path'"
  fi
  say "${BLD}running command for '$name' (test fire — no date guard, no self-unload)${RST}"
  say "${DIM}$ $cmd_str${RST}"
  bash -c "$cmd_str"
  local rc=$?
  if (( rc == 0 )); then ok "command exited 0"; else err "command exited $rc"; fi
  return $rc
}

# ── logs ───────────────────────────────────────────────────────────────────
cmd_logs() {
  local lines=50 follow=1 name=""
  # Walk ALL args; pull flags wherever they appear (order-insensitive — supports
  # 'logs NAME --no-follow' AND 'logs --no-follow NAME'). v0.2 bug-fix: the
  # break-on-positional parser silently dropped flags placed after the name.
  while (( $# )); do
    case "$1" in
      --lines)     lines="$2"; shift 2 ;;
      --no-follow) follow=0; shift ;;
      -h|--help)   fail "usage: $PROG logs <name> [--lines N] [--no-follow]" ;;
      -*) fail "unknown flag: $1" ;;
      *)  [[ -z "$name" ]] && name="$1" || fail "extra positional arg: $1"
          shift ;;
    esac
  done
  [[ -n "$name" ]] || fail "usage: $PROG logs <name> [--lines N] [--no-follow]"
  local entry outlog errlog
  entry=$(_get_entry "$name")
  outlog=$(jq -r '.out_log' <<<"$entry")
  errlog=$(jq -r '.err_log' <<<"$entry")
  local exists_out=0 exists_err=0
  [[ -f "$outlog" ]] && exists_out=1
  [[ -f "$errlog" ]] && exists_err=1
  if (( ! exists_out && ! exists_err )); then
    warn "no log files yet — the schedule hasn't fired (or wrote nothing)."
    say "${DIM}  expected: $outlog${RST}"
    say "${DIM}            $errlog${RST}"
    return 0
  fi
  say "${BLD}logs for '$name'${RST} ${DIM}(out=$outlog err=$errlog)${RST}"
  # Use a sed-prefixed tail so the user can tell which stream a line came from.
  # `tail -F` retries on missing files — safe even if only one log exists yet.
  if (( follow )); then
    tail -n "$lines" -F "$outlog" 2>/dev/null | sed -u 's/^/[out] /' &
    local tpid_out=$!
    tail -n "$lines" -F "$errlog" 2>/dev/null | sed -u 's/^/[err] /' &
    local tpid_err=$!
    trap "kill $tpid_out $tpid_err 2>/dev/null; trap - INT" INT
    wait
  else
    if (( exists_out )); then say "${DIM}── last $lines lines of $outlog ──${RST}"; tail -n "$lines" "$outlog" | sed 's/^/[out] /'; fi
    if (( exists_err )); then say "${DIM}── last $lines lines of $errlog ──${RST}"; tail -n "$lines" "$errlog" | sed 's/^/[err] /'; fi
  fi
}

# ── show ───────────────────────────────────────────────────────────────────
cmd_show() {
  [[ $# -ge 1 ]] || fail "usage: $PROG show <name>"
  local name="$1" entry
  entry=$(_get_entry "$name")

  local label fire_at kind cmd_str desc cal_uid created plist script outlog errlog
  label=$(jq -r '.label'        <<<"$entry")
  fire_at=$(jq -r '.fire_at'    <<<"$entry")
  kind=$(jq -r '.kind'          <<<"$entry")
  cmd_str=$(jq -r '.command'    <<<"$entry")
  desc=$(jq -r '.description'   <<<"$entry")
  cal_uid=$(jq -r '.calendar_uid // ""' <<<"$entry")
  created=$(jq -r '.created_at' <<<"$entry")
  plist=$(jq -r '.plist'        <<<"$entry")
  script=$(jq -r '.script'      <<<"$entry")
  outlog=$(jq -r '.out_log'     <<<"$entry")
  errlog=$(jq -r '.err_log'     <<<"$entry")

  # Launchd state
  local state="not loaded"
  if _is_loaded "$label"; then
    state="loaded"
    if launchctl print "gui/$USER_UID/$label" 2>/dev/null | grep -q 'state = running'; then
      state="running"
    fi
  fi

  # Next-fire time relative-to-now — format depends on kind.
  # one-shot: ISO datetime, compute exact countdown.
  # daily/weekly: fire_at is a synthetic tag (daily@HH:MM, weekly@dow@HH:MM);
  # show the schedule descriptively rather than a countdown.
  local next_rel="(unknown)"
  case "$fire_at" in
    daily@*)
      next_rel="every day at ${fire_at#daily@}"
      ;;
    weekly@*)
      local rest="${fire_at#weekly@}"
      local dow="${rest%%@*}" tm="${rest##*@}"
      next_rel="every $dow at $tm"
      ;;
    adopted-one-shot@*)
      # fire_at is "adopted-one-shot@MM-DD HH:MM" (no year — `register` couldn't
      # know what year the original author intended). Infer the next future
      # occurrence: this year if still ahead, else next year. Reports the
      # year so the user can sanity-check.
      local rest="${fire_at#adopted-one-shot@}"
      if [[ "$rest" =~ ^([0-9]{2})-([0-9]{2})\ ([0-9]{2}):([0-9]{2})$ ]]; then
        local fmo=$((10#${BASH_REMATCH[1]})) fd=$((10#${BASH_REMATCH[2]})) \
              fh=$((10#${BASH_REMATCH[3]})) fm=$((10#${BASH_REMATCH[4]}))
        local cur_y; cur_y=$(date +%Y)
        local epoch_now; epoch_now=$(date +%s)
        local epoch_try
        epoch_try=$(date -j -f '%Y-%m-%dT%H:%M' \
          "$(printf '%d-%02d-%02dT%02d:%02d' "$cur_y" "$fmo" "$fd" "$fh" "$fm")" +%s 2>/dev/null || echo 0)
        if (( epoch_try > 0 && epoch_try < epoch_now - 60 )); then
          # Past for this year — roll to next.
          cur_y=$((cur_y + 1))
          epoch_try=$(date -j -f '%Y-%m-%dT%H:%M' \
            "$(printf '%d-%02d-%02dT%02d:%02d' "$cur_y" "$fmo" "$fd" "$fh" "$fm")" +%s 2>/dev/null || echo 0)
        fi
        if (( epoch_try > 0 )); then
          local delta=$(( epoch_try - epoch_now ))
          if (( delta > 0 )); then
            local dd=$(( delta / 86400 )) dh=$(( (delta % 86400) / 3600 )) dm=$(( (delta % 3600) / 60 ))
            next_rel="in ${dd}d ${dh}h ${dm}m (inferred year $cur_y)"
          fi
        fi
      fi
      ;;
    *)
      local epoch_fire epoch_now
      epoch_fire=$(date -j -f '%Y-%m-%dT%H:%M' "$fire_at" +%s 2>/dev/null || echo 0)
      epoch_now=$(date +%s)
      if (( epoch_fire > 0 )); then
        local delta=$(( epoch_fire - epoch_now ))
        if (( delta > 0 )); then
          local d=$(( delta / 86400 )) h=$(( (delta % 86400) / 3600 )) m=$(( (delta % 3600) / 60 ))
          next_rel="in ${d}d ${h}h ${m}m"
        else
          next_rel="$(( -delta / 60 ))m AGO ${RED}(should have self-unloaded!)${RST}"
        fi
      fi
      ;;
  esac

  # Log freshness
  local last_fired="never"
  if [[ -f "$outlog" ]]; then
    last_fired=$(date -r "$outlog" '+%F %T %Z' 2>/dev/null || echo unknown)
  fi

  local adopted_tag=""
  if [[ "$(jq -r '.adopted // false' <<<"$entry")" == "true" ]]; then
    adopted_tag=" ${YLW}(adopted)${RST}"
  fi
  printf '%s%s%s%s\n' "$BLD" "── $name ──" "$adopted_tag" "$RST"
  printf '  %-12s %s\n' "label:"        "$label"
  printf '  %-12s %s\n' "kind:"         "$kind"
  printf '  %-12s %s (%s)\n' "fires:"   "$fire_at" "$next_rel"
  printf '  %-12s %s\n' "state:"        "$state"
  printf '  %-12s %s\n' "last fired:"   "$last_fired"
  printf '  %-12s %s\n' "created:"      "$created"
  printf '  %-12s %s\n' "calendar:"     "${cal_uid:-(none — --no-calendar)}"
  printf '  %-12s %s\n' "script:"       "$script"
  printf '  %-12s %s\n' "plist:"        "$plist"
  printf '  %-12s %s\n' "out log:"      "$outlog"
  printf '  %-12s %s\n' "err log:"      "$errlog"
  if [[ -n "$desc" && "$desc" != "null" ]]; then
    printf '  %-12s %s\n' "description:" "$desc"
  fi
  # Optional v0.3 fields — `// empty` so absence is silent rather than "null"
  local wd; wd=$(jq -r '.working_dir // empty' <<<"$entry")
  if [[ -n "$wd" ]]; then
    printf '  %-12s %s\n' "workdir:" "$wd"
  fi
  local env_count; env_count=$(jq -r '(.env_vars // []) | length' <<<"$entry")
  if (( env_count > 0 )); then
    printf '  %-12s %d var(s)\n' "env:" "$env_count"
    jq -r '(.env_vars // []) | .[] | "    " + .' <<<"$entry"
  fi
  if [[ "$cmd_str" == "null" || -z "$cmd_str" ]]; then
    printf '  %s\n' "${DIM}command:${RST}"
    printf '    %s(adopted — actual command lives in the external script: %s)%s\n' "$DIM" "$(jq -r '.script' <<<"$entry")" "$RST"
  else
    printf '  %s\n' "${DIM}command:${RST}"
    printf '    %s%s%s\n' "$DIM" "$cmd_str" "$RST"
  fi
}

# ── enable / disable ───────────────────────────────────────────────────────
cmd_enable() {
  [[ $# -ge 1 ]] || fail "usage: $PROG enable <name>"
  local name="$1" entry plist label
  entry=$(_get_entry "$name")
  label=$(jq -r '.label' <<<"$entry")
  plist=$(jq -r '.plist' <<<"$entry")
  [[ -f "$plist" ]] || fail "plist missing: $plist (registry desync — consider '$PROG rm $name')"
  if _is_loaded "$label"; then ok "already loaded: $label"; return 0; fi
  if launchctl bootstrap "gui/$USER_UID" "$plist" 2>&1; then
    ledger_append modified "$name" change enabled
    ok "loaded: $label"
  else
    fail "bootstrap failed (check plist)"
  fi
}

cmd_disable() {
  [[ $# -ge 1 ]] || fail "usage: $PROG disable <name>"
  local name="$1" entry label
  entry=$(_get_entry "$name")
  label=$(jq -r '.label' <<<"$entry")
  if ! _is_loaded "$label"; then ok "already not loaded: $label (plist still on disk)"; return 0; fi
  if launchctl bootout "gui/$USER_UID/$label" 2>&1; then
    ledger_append modified "$name" change disabled
    ok "unloaded: $label (plist + script preserved — 'enable' to reload)"
  else
    fail "bootout failed"
  fi
}

# ── doctor (v0.5) ──────────────────────────────────────────────────────────
# Audit every registry entry for drift between the four state surfaces:
# registry / filesystem (sched_dir + script + plist) / launchd / Calendar.
# Drift commonly appears after a one-shot self-unloads (plist gone, registry
# still listing the entry as loaded) or when the user manually deletes a
# Calendar event. Default: skip the Calendar check (slow osascript hop) —
# pass --check-calendar to include it.
cmd_doctor() {
  local check_cal=0
  while (( $# )); do
    case "$1" in
      --check-calendar) check_cal=1; shift ;;
      -*) fail "unknown flag: $1 (try 'help')" ;;
      *)  shift ;;
    esac
  done

  # Sweep one-shots that should have fired but never ran (machine off, launchd
  # gap) into history + retire them, so the drift audit below sees a clean slate.
  local _swept; _swept=$(reconcile_missed)
  (( _swept > 0 )) && printf '%s↻ reconciled %d missed one-shot(s) → history (outcome=missed)%s\n' "$DIM" "$_swept" "$RST"

  local total=0 healthy_count=0 drift_count=0
  local report=""
  local name entry label plist script sched_dir cal_uid adopted
  local entry_issues

  # Pass 1: walk every entry in the registry
  while IFS= read -r name; do
    [[ -z "$name" ]] && continue
    total=$((total+1))
    entry=$(jq --arg n "$name" '.[$n]' "$REGISTRY")
    label=$(jq -r '.label' <<<"$entry")
    plist=$(jq -r '.plist' <<<"$entry")
    script=$(jq -r '.script // ""' <<<"$entry")
    sched_dir="$SCHED_HOME/$name"
    cal_uid=$(jq -r '.calendar_uid // ""' <<<"$entry")
    adopted=$(jq -r '.adopted // false' <<<"$entry")
    entry_issues=""

    [[ -f "$plist" ]]      || entry_issues+="    plist missing: $plist  (probably post self-unload — '$PROG rm $name' to clean registry)"$'\n'
    [[ -d "$sched_dir" ]]  || entry_issues+="    sched_dir missing: $sched_dir"$'\n'
    if [[ -n "$script" && "$script" != "null" && ! -f "$script" ]]; then
      [[ "$adopted" == "true" ]] && \
        entry_issues+="    external script missing: $script  (it was the user's; safe to '$PROG rm $name' if intentionally deleted)"$'\n' || \
        entry_issues+="    script missing: $script"$'\n'
    fi
    # launchd state vs plist presence
    if [[ -f "$plist" ]] && ! _is_loaded "$label"; then
      entry_issues+="    plist present but launchd unaware: $label  (suggest: '$PROG enable $name')"$'\n'
    fi
    if [[ ! -f "$plist" ]] && _is_loaded "$label"; then
      entry_issues+="    plist gone but agent still loaded: $label  (suggest: 'launchctl bootout gui/$USER_UID/$label')"$'\n'
    fi
    # Calendar event existence (optional)
    if (( check_cal )) && [[ -n "$cal_uid" ]]; then
      local cal_exists; cal_exists=$(osascript -e "tell application \"Calendar\" to tell calendar \"Automations\" to return (count of (every event whose uid is \"$cal_uid\"))" 2>/dev/null || echo 0)
      if [[ "$cal_exists" == "0" ]]; then
        entry_issues+="    Calendar event missing (UID $cal_uid)  (manually deleted in Calendar.app?)"$'\n'
      fi
    fi

    if [[ -n "$entry_issues" ]]; then
      drift_count=$((drift_count+1))
      report+="${RED}✗${RST} $name"$'\n'"$entry_issues"
    else
      healthy_count=$((healthy_count+1))
    fi
  done < <(jq -r 'keys[]' "$REGISTRY" 2>/dev/null)

  # Pass 2: orphan sched_dirs (filesystem entry without registry knowledge)
  local d short
  for d in "$SCHED_HOME"/*/; do
    [[ -d "$d" ]] || continue
    short=$(basename "$d")
    if ! jq -e --arg n "$short" '.[$n]' "$REGISTRY" >/dev/null 2>&1; then
      report+="${YLW}⚠${RST} orphan sched_dir: $d  (filesystem present but no registry entry; safe to 'trash')"$'\n'
      drift_count=$((drift_count+1))
    fi
  done

  printf '%s%s%s\n' "$BLD" "── doctor — registry vs filesystem vs launchd${check_cal:+ vs Calendar} ──" "$RST"
  if (( drift_count == 0 )); then
    printf '%s✓%s all healthy: %d registry entr%s, no drift detected\n' \
      "$GRN" "$RST" "$total" "$([[ $total -eq 1 ]] && echo y || echo ies)"
  else
    printf '%b' "$report"
    printf '\n%ssummary:%s %d healthy, %d with drift, %d total\n' \
      "$BLD" "$RST" "$healthy_count" "$drift_count" "$total"
  fi
  (( check_cal )) || printf '%s(Calendar check skipped — pass --check-calendar to verify Automations events; slower)%s\n' "$DIM" "$RST"
}

# ── inventory (v0.4) ───────────────────────────────────────────────────────
# Survey ALL scheduling surfaces on this machine: user crontab + every plist
# in ~/Library/LaunchAgents/. Classify each LaunchAgent by management status
# so the user/Claude can see at a glance: "what's running, what owns it, what
# could be brought under gcc-schedule".
cmd_inventory() {
  printf '%s%s%s\n' "$BLD" "── LaunchAgents (~/Library/LaunchAgents/) ──" "$RST"
  local plist label short status loaded_state
  local managed=0 adopted=0 unmanaged_alc=0 other=0 loaded_count=0
  # tabular collect-then-print so the column widths are consistent
  local rows=""
  for plist in "$LAUNCHAGENTS"/*.plist; do
    [[ -f "$plist" ]] || continue
    label=$(basename "$plist" .plist)
    short="${label#com.alcatraz.}"
    # Loaded?
    if _is_loaded "$label"; then loaded_state="loaded"; loaded_count=$((loaded_count+1))
    else loaded_state="not-loaded"; fi
    # Classify
    if [[ "$label" != com.alcatraz.* ]]; then
      status="other-ns"; other=$((other+1))
    elif jq -e --arg n "$short" '.[$n]' "$REGISTRY" >/dev/null 2>&1; then
      if [[ "$(jq -r --arg n "$short" '.[$n].adopted // false' "$REGISTRY")" == "true" ]]; then
        status="adopted"; adopted=$((adopted+1))
      else
        status="managed"; managed=$((managed+1))
      fi
    else
      status="unmanaged"; unmanaged_alc=$((unmanaged_alc+1))
    fi
    rows+="$(printf '  %-12s  %-10s  %s' "$status" "$loaded_state" "$label")"$'\n'
  done
  if [[ -n "$rows" ]]; then printf '%s' "$rows"; else echo "  (none)"; fi
  printf '\n  %ssummary:%s %d managed, %d adopted, %d unmanaged-alcatraz, %d other-namespace; %d currently loaded\n' \
    "$DIM" "$RST" "$managed" "$adopted" "$unmanaged_alc" "$other" "$loaded_count"

  echo
  printf '%s%s%s\n' "$BLD" "── User crontab (crontab -l) ──" "$RST"
  if crontab -l 2>/dev/null | grep -q .; then
    crontab -l 2>/dev/null | sed 's/^/  /'
  else
    printf '  %s(no user crontab entries)%s\n' "$DIM" "$RST"
  fi

  echo
  printf '%s%s%s\n' "$DIM" "Notes: 'unmanaged' = com.alcatraz.* plist not in gcc-schedule registry; '$PROG register <plist>' to adopt." "$RST"
}

# ── duplicate (v0.4) ───────────────────────────────────────────────────────
# Copy an existing schedule with optional overrides. Inherits command, kind,
# fire_at, env_vars, working_dir, description from the source — anything you
# pass as an override replaces the inherited value. If you override the mode
# (--at / --daily-at / --weekly), the source's mode is dropped so we don't
# trip the mode_count==1 check in cmd_add.
cmd_duplicate() {
  [[ $# -ge 2 ]] || fail "usage: $PROG duplicate <src-name> <new-name> [add-overrides...]"
  local src="$1" new="$2"; shift 2
  local entry; entry=$(_get_entry "$src")

  # Adopted entries have command=null — we can't duplicate what we don't know.
  local src_cmd; src_cmd=$(jq -r '.command' <<<"$entry")
  [[ "$src_cmd" == "null" ]] && fail "cannot duplicate adopted entry '$src' — its command lives in an external script we don't track. Re-create from scratch with '$PROG add'."

  local src_kind src_fire_at src_desc src_workdir
  src_kind=$(jq -r '.kind' <<<"$entry")
  src_fire_at=$(jq -r '.fire_at' <<<"$entry")
  src_desc=$(jq -r '.description // ""' <<<"$entry")
  src_workdir=$(jq -r '.working_dir // ""' <<<"$entry")

  # Did the user override the schedule mode? If yes, skip inheriting source's.
  local override_has_mode=0
  local a
  for a in "$@"; do
    case "$a" in --at|--daily-at|--weekly) override_has_mode=1; break ;; esac
  done

  # Inherited mode args (only when user didn't override)
  local mode_args=()
  if (( ! override_has_mode )); then
    case "$src_kind" in
      one-shot) mode_args=(--at "$src_fire_at") ;;
      daily)    mode_args=(--daily-at "${src_fire_at#daily@}") ;;
      weekly)
        local rest="${src_fire_at#weekly@}"
        local dow="${rest%%@*}" tm="${rest##*@}"
        mode_args=(--weekly "$dow" "$tm")
        ;;
      *) warn "source kind '$src_kind' not directly supported — you'll need to pass a mode flag in the overrides" ;;
    esac
  fi

  # Inherited --env's (each pair becomes a separate --env flag pair)
  local env_args=() pair
  while IFS= read -r pair; do
    [[ -n "$pair" ]] && env_args+=(--env "$pair")
  done < <(jq -r '(.env_vars // []) | .[]' <<<"$entry")

  local wd_args=()
  [[ -n "$src_workdir" ]] && wd_args=(--working-dir "$src_workdir")
  local desc_args=()
  [[ -n "$src_desc" && "$src_desc" != "(adopted from existing plist on"* ]] && desc_args=(--description "$src_desc")

  say "${DIM}duplicating '$src' → '$new' (inherited: $src_kind, $((${#env_args[@]}/2)) env, workdir=${src_workdir:-none})${RST}"
  # Overrides ("$@") come AFTER the inherited args — cmd_add's parser
  # last-wins for scalar flags, so an override --command/--alert/etc. wins.
  cmd_add --name "$new" \
    "${mode_args[@]+${mode_args[@]}}" \
    --command "$src_cmd" \
    "${env_args[@]+${env_args[@]}}" \
    "${wd_args[@]+${wd_args[@]}}" \
    "${desc_args[@]+${desc_args[@]}}" \
    "$@"
}

# ── register (v0.3 Cluster D) ──────────────────────────────────────────────
# Adopt an existing user LaunchAgent plist into gcc-schedule's registry. Does
# NOT rewrite the plist — adopted schedules behave however the original
# script behaves (no auto-injected date guard, no self-unload, command=null
# because we don't know the user's intent). 'rm' of an adopted entry deletes
# the plist + sched_dir but warns about external scripts/Calendar events we
# didn't create.
_plutil_get() {
  # _plutil_get <plist> <keypath> → echo raw value, empty on miss
  plutil -extract "$2" raw -o - "$1" 2>/dev/null || true
}

cmd_register() {
  [[ $# -ge 1 ]] || fail "usage: $PROG register <plist-path>"
  local plist; plist=$(cd "$(dirname "$1")" 2>/dev/null && pwd)/$(basename "$1") || fail "bad path '$1'"
  [[ -f "$plist" ]]            || fail "plist not found: $plist"
  [[ "$plist" == *.plist ]]    || fail "must end in .plist, got '$plist'"
  [[ "$plist" == "$LAUNCHAGENTS"/* ]] || fail "only files under $LAUNCHAGENTS may be registered (got '$plist')"
  plutil -lint "$plist" >/dev/null    || fail "plist lint failed — refusing to register a malformed plist"

  local label; label=$(_plutil_get "$plist" Label)
  [[ -n "$label" ]] || fail "plist has no Label key"
  [[ "$label" == com.alcatraz.* ]] || fail "label '$label' is outside the com.alcatraz.* namespace gcc-schedule manages"

  local name="${label#com.alcatraz.}"
  validate_name "$name"
  jq -e --arg n "$name" '.[$n]' "$REGISTRY" >/dev/null 2>&1 && \
    fail "already in registry: '$name'. Use '$PROG show $name' or '$PROG rm $name' first."

  # Pull SCI keys — present/absent distinguishes kind
  local sci_month sci_day sci_weekday sci_hour sci_minute
  sci_month=$(_plutil_get   "$plist" StartCalendarInterval.Month)
  sci_day=$(_plutil_get     "$plist" StartCalendarInterval.Day)
  sci_weekday=$(_plutil_get "$plist" StartCalendarInterval.Weekday)
  sci_hour=$(_plutil_get    "$plist" StartCalendarInterval.Hour)
  sci_minute=$(_plutil_get  "$plist" StartCalendarInterval.Minute)

  local kind fire_at_meta
  if   [[ -n "$sci_month" && -n "$sci_day" ]]; then
    kind="one-shot"
    fire_at_meta="adopted-one-shot@$(printf '%02d-%02d %02d:%02d' "$sci_month" "$sci_day" "${sci_hour:-0}" "${sci_minute:-0}")"
  elif [[ -n "$sci_weekday" ]]; then
    kind="weekly"
    local dows=(sun mon tue wed thu fri sat)
    fire_at_meta="weekly@${dows[$sci_weekday]}@$(printf '%02d:%02d' "${sci_hour:-0}" "${sci_minute:-0}")"
  elif [[ -n "$sci_hour" ]]; then
    kind="daily"
    fire_at_meta="daily@$(printf '%02d:%02d' "${sci_hour:-0}" "${sci_minute:-0}")"
  else
    kind="custom"
    fire_at_meta="custom-schedule"
  fi

  # External paths (script, logs) — we record but don't touch
  local ext_script ext_outlog ext_errlog ext_workdir
  ext_script=$(plutil -extract ProgramArguments.0 raw -o - "$plist" 2>/dev/null || echo "")
  ext_outlog=$(_plutil_get "$plist" StandardOutPath)
  ext_errlog=$(_plutil_get "$plist" StandardErrorPath)
  ext_workdir=$(_plutil_get "$plist" WorkingDirectory)

  # Sched dir + meta — we DO create these for the adopted entry so show/rm work
  local sched_dir="$SCHED_HOME/$name"
  local meta="$sched_dir/meta.json"
  mkdir -p "$sched_dir"
  cat > "$meta" <<META
{
  "name": "$name",
  "label": "$label",
  "kind": "$kind",
  "fire_at": "$fire_at_meta",
  "command": null,
  "description": "(adopted from existing plist on $(date '+%F'))",
  "env_vars": [],
  "working_dir": $(printf '%s' "$ext_workdir" | jq -Rs .),
  "calendar_uid": "",
  "created_at": "$(date -u '+%FT%TZ')",
  "adopted": true,
  "plist": "$plist",
  "script": "$ext_script",
  "out_log": "$ext_outlog",
  "err_log": "$ext_errlog"
}
META
  jq_inplace "$REGISTRY" ". + {\"$name\": $(cat "$meta")}"
  ok "registered (adopted): $name"
  printf '  %slabel: %s%s\n' "$DIM" "$label" "$RST"
  printf '  %skind:  %s  fire_at: %s%s\n' "$DIM" "$kind" "$fire_at_meta" "$RST"
  printf '  %sext script: %s%s\n' "$DIM" "${ext_script:-(none)}" "$RST"
  if ! _is_loaded "$label"; then
    warn "label '$label' is NOT currently loaded — run '$PROG enable $name' to bootstrap"
  fi
}

# ── reconcile / history / status (v0.6) ────────────────────────────────────
cmd_reconcile() {
  local n; n=$(reconcile_missed)
  if (( n > 0 )); then
    ok "reconciled $n missed one-shot(s) — logged outcome=missed and retired"
  else
    ok "no missed one-shots to reconcile"
  fi
}

# Read the append-only ledger. Plain JSONL underneath — this is sugar; you can
# always `rg`/`jq`/Read $HIST directly.
cmd_history() {
  local name="" outcome="" ev="" limit=20
  while (( $# )); do
    case "$1" in
      --name)    name="$2";    shift 2 ;;
      --outcome) outcome="$2"; shift 2 ;;
      --ev)      ev="$2";      shift 2 ;;
      --limit)   limit="$2";   shift 2 ;;
      -*) fail "unknown flag: $1 (try '$PROG help')" ;;
      *) shift ;;
    esac
  done
  [[ -f "$HIST" ]] || { say "${DIM}(no history yet: $HIST)${RST}"; return 0; }
  jq -c --arg n "$name" --arg o "$outcome" --arg e "$ev" '
    select(($n=="" or .name==$n) and ($o=="" or .outcome==$o) and ($e=="" or .ev==$e))' "$HIST" \
    | tail -n "$limit" \
    | jq -r '"  \(.ts)  \(.ev)\(if .outcome then ":"+.outcome else "" end)  \(.name)" +
             (if .reason then "  (\(.reason)\(if .stage then "@"+.stage else "" end))" else "" end) +
             (if .cause then "  [\(.cause)]" else "" end)'
}

# One-glance health: live count + all-time fire outcomes + recent fires.
cmd_status() {
  printf '%s── gcc-schedule status ──%s\n' "$BLD" "$RST"
  local live; live=$(jq -r 'keys|length' "$REGISTRY" 2>/dev/null || echo 0)
  printf '  live schedules : %s\n' "$live"
  if [[ -f "$HIST" ]]; then
    printf '  fire outcomes  :\n'
    # Counts computed in bash so the color lives in printf (TTY-gated), not in
    # jq's output (which would emit raw ANSI into a pipe). failed/missed light up
    # only when non-zero; everything blanks when piped (Claude) or NO_COLOR.
    local _ok _fail _unk _miss cf="$DIM" cm="$DIM"
    _ok=$(jq -s -r   '[.[]|select(.ev=="run" and .outcome=="ok")]|length'      "$HIST" 2>/dev/null || echo 0)
    _fail=$(jq -s -r '[.[]|select(.ev=="run" and .outcome=="failed")]|length'  "$HIST" 2>/dev/null || echo 0)
    _unk=$(jq -s -r  '[.[]|select(.ev=="run" and .outcome=="unknown")]|length' "$HIST" 2>/dev/null || echo 0)
    _miss=$(jq -s -r '[.[]|select(.ev=="run" and .outcome=="missed")]|length'  "$HIST" 2>/dev/null || echo 0)
    [ "${_fail:-0}" -gt 0 ] && cf="$RED"
    [ "${_miss:-0}" -gt 0 ] && cm="$YLW"
    printf '    %sok=%s%s  %sfailed=%s%s  %sunknown=%s%s  %smissed=%s%s\n' \
      "$GRN" "$_ok" "$RST" "$cf" "$_fail" "$RST" "$DIM" "$_unk" "$RST" "$cm" "$_miss" "$RST"
    local recent; recent=$(jq -s -r '[.[]|select(.ev=="run")]|.[-5:]|reverse|.[]|"    \(.ts)  \(.outcome)  \(.name)\(if .reason then "  ("+.reason+")" else "" end)"' "$HIST" 2>/dev/null)
    [[ -n "$recent" ]] && { printf '  recent fires   :\n'; printf '%s\n' "$recent"; }
  else
    printf '  %s(no history yet — %s)%s\n' "$DIM" "$HIST" "$RST"
  fi
  printf '  %stip: '\''%s reconcile'\'' sweeps any missed one-shots into history%s\n' "$DIM" "$PROG" "$RST"
}

# ═══ Interactive mode (gcc-schedule -i) ══════════════════════════════════════
# A colored, fuzzy front-end to EVERY subcommand, for a human at a terminal.
# Design contract: this layer only PICKS and PROMPTS — every action routes back
# through the same cmd_* functions the text CLI uses, so the interactive path can
# never drift from the scripted one. The logic-bearing helpers (_i_schedule_rows,
# _i_do_action, _i_compose_add_args) are pure and unit-tested headless; the tty
# layer on top gets a non-tty refusal test plus a pty smoke test.

# Load the std::claude::tui libs -i needs. Returns 1 if the shared lib is missing.
_i_source_tui() {
  local d="$HOME/.claude/scripts/tui"
  [ -r "$d/tty.sh" ] && [ -r "$d/require.sh" ] && [ -r "$d/pick.sh" ] || return 1
  . "$d/tty.sh"; . "$d/require.sh"; . "$d/pick.sh"
}

# _i_recent_outcomes <name> — last 3 run outcomes from the ledger ("ok ok missed").
_i_recent_outcomes() {
  jq -r --arg n "$1" 'select(.name==$n and .ev=="run") | .outcome // "?"' "$HIST" 2>/dev/null \
    | tail -3 | tr '\n' ' ' | sed 's/[[:space:]]*$//'
}

# _i_outcomes_colored <name> — recent outcomes, each token semantically colored
# (ok green · missed yellow · failed red). Blank of color when piped (both-fd gate).
_i_outcomes_colored() {
  local o out=""
  for o in $(_i_recent_outcomes "$1"); do
    case "$o" in
      ok)     out="${out}${GRN}ok${RST} " ;;
      missed) out="${out}${YLW}missed${RST} " ;;
      failed) out="${out}${RED}failed${RST} " ;;
      *)      out="${out}${DIM}${o}${RST} " ;;
    esac
  done
  printf '%s' "${out% }"
}

# _i_schedule_rows — one row per schedule as `name<TAB>colored aligned display`,
# for tui_pick_key (shows the colored display, returns the clean name). Name cyan,
# kind dim, recent outcomes semantically colored. Pure: registry + ledger, no tty.
# Manual %-*s padding (not `column -t`) so ANSI codes don't skew the alignment.
_i_schedule_rows() {
  local name kind fire w=4
  while IFS=$'\t' read -r name kind fire; do [ "${#name}" -gt "$w" ] && w="${#name}"; done \
    < <(jq -r 'to_entries[] | "\(.key)\t\(.value.kind)\t\(.value.fire_at)"' "$REGISTRY" 2>/dev/null)
  while IFS=$'\t' read -r name kind fire; do
    [ -n "$name" ] || continue
    printf '%s\t%s%-*s%s  %s%-8s%s  %-18s  %s\n' \
      "$name" "$CYN" "$w" "$name" "$RST" "$DIM" "$kind" "$RST" "$fire" "$(_i_outcomes_colored "$name")"
  done < <(jq -r 'to_entries[] | "\(.key)\t\(.value.kind)\t\(.value.fire_at)"' "$REGISTRY" 2>/dev/null)
}

# _i_actions — per-schedule actions as `verb<TAB>colored display` for tui_pick_key.
# Field 1 (the verb) is the clean key _i_do_action routes on; field 2 is the
# colored label shown. Verb color carries meaning (rm red, disable yellow).
_i_actions() {
  printf '%s\t%sshow%s — details, state, next fire\n'      show      "$CYN" "$RST"
  printf '%s\t%slogs%s — tail out+err\n'                   logs      "$CYN" "$RST"
  printf '%s\t%srun%s — test-fire now (no date guard)\n'   run       "$CYN" "$RST"
  printf '%s\t%sdisable%s — bootout, keep plist (pause)\n' disable   "$YLW" "$RST"
  printf '%s\t%senable%s — reload plist (resume)\n'        enable    "$GRN" "$RST"
  printf '%s\t%sduplicate%s — copy to a new name\n'        duplicate "$CYN" "$RST"
  printf '%s\t%srm%s — retire fully (destructive)\n'       rm        "$RED" "$RST"
  printf '%s\t%sback%s\n'                                  back      "$DIM" "$RST"
}

# _i_do_action <name> <label> — route a chosen action to the SAME cmd_* the text
# CLI uses. Returns 2 for "back". ACTION_DRYRUN=1 prints the route and runs
# nothing, so routing is unit-testable headless.
_i_do_action() {
  local name="$1" label="$2" route="" nn=""
  case "$label" in
    show*)      route="show $name" ;;
    logs*)      route="logs $name --no-follow" ;;
    run*)       route="run $name" ;;
    disable*)   route="disable $name" ;;
    enable*)    route="enable $name" ;;
    duplicate*) route="duplicate $name <new>" ;;
    rm*)        route="rm $name" ;;
    *)          return 2 ;;
  esac
  if [ -n "${ACTION_DRYRUN:-}" ]; then printf 'ROUTE: %s\n' "$route"; return 0; fi
  case "$label" in
    show*)      cmd_show    "$name" ;;
    logs*)      cmd_logs    "$name" --no-follow ;;
    run*)       if tui_confirm "Test-fire '$name' now?"; then cmd_run "$name"; else warn "not fired"; fi ;;
    disable*)   cmd_disable "$name" ;;
    enable*)    cmd_enable  "$name" ;;
    duplicate*) if tui_read_tty -p "new name: " nn && [ -n "$nn" ]; then cmd_duplicate "$name" "$nn"; else warn "cancelled"; fi ;;
    rm*)        if tui_confirm "PERMANENTLY retire '$name' (plist + Calendar + registry)?"; then cmd_rm "$name"; else warn "kept"; fi ;;
  esac
}

# _i_compose_add_args — PURE. Emit the argv for cmd_add (one per line, NO leading
# 'add'), so an interactively-built schedule is identical to a hand-typed one.
#   $1 name  $2 mode(at|daily|weekly|monthly)  $3 when  $4 dow/day  $5 command  $6 desc  $7 nocal(1|"")
_i_compose_add_args() {
  local name="$1" mode="$2" when="$3" dow="$4" cmd="$5" desc="$6" nocal="$7"
  printf '%s\n' --name "$name"
  case "$mode" in
    at)      printf '%s\n' --at "$when" ;;
    daily)   printf '%s\n' --daily-at "$when" ;;
    weekly)  printf '%s\n' --weekly "$dow" "$when" ;;
    monthly) printf '%s\n' --monthly "$dow" "$when" ;;
  esac
  printf '%s\n' --command "$cmd"
  [ -n "$desc" ]  && printf '%s\n' --description "$desc"
  [ -n "$nocal" ] && printf '%s\n' --no-calendar
  return 0
}

# ── interactive sub-flows (tty only) ────────────────────────────────────────
_i_pause() { tui_read_tty -p "$(printf '%s↵ enter to continue%s ' "$DIM" "$RST")" _p 2>/dev/null || true; }

_i_browse() {
  local rows key act rc SELF
  SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)/$(basename "${BASH_SOURCE[0]}")"
  while :; do
    rows=$(_i_schedule_rows)
    [ -n "$rows" ] || { warn "no schedules yet — pick 'Create' from the main menu."; return 0; }
    # up/down to browse, live preview shows the schedule's `show`, enter opens
    # its details; tui_pick_key renders the colored row and returns the clean name.
    key=$(printf '%s\n' "$rows" | tui_pick_key --prompt 'schedule > ' \
          --preview "echo {} | cut -f1 | xargs $SELF show") || return 0
    [ -n "$key" ] || return 0
    say; cmd_show "$key"; say
    while :; do
      act=$(_i_actions | tui_pick_key --prompt "$key > ") || break
      _i_do_action "$key" "$act"; rc=$?
      [ "$rc" = 2 ] && break
      _i_pause
    done
  done
}

_i_add_wizard() {
  local name="" mode="" when="" dow="" cmd="" desc="" nocal="" line
  tui_read_tty -p "name (slug): " name || return 0; [ -n "$name" ] || { warn "cancelled"; return 0; }
  mode=$( { printf 'at\t%sone-shot%s — fires once at an ISO datetime\n' "$CYN" "$RST"
            printf 'daily\t%sdaily%s — every day at HH:MM\n'            "$CYN" "$RST"
            printf 'weekly\t%sweekly%s — every <dow> at HH:MM\n'        "$CYN" "$RST"
            printf 'monthly\t%smonthly%s — on day-of-month at HH:MM\n'  "$CYN" "$RST"; } \
          | tui_pick_key --prompt 'when > ') || return 0
  case "$mode" in
    at)      tui_read_tty -p "ISO datetime (YYYY-MM-DDTHH:MM): " when || return 0 ;;
    daily)   tui_read_tty -p "time (HH:MM): " when || return 0 ;;
    weekly)  dow=$(printf '%s\n' mon tue wed thu fri sat sun | tui_pick_one --prompt 'day > ') || return 0
             tui_read_tty -p "time (HH:MM): " when || return 0 ;;
    monthly) tui_read_tty -p "day of month (1-31): " dow || return 0
             tui_read_tty -p "time (HH:MM): " when || return 0 ;;
    *) return 0 ;;
  esac
  tui_read_tty -p "command (shell to run): " cmd || return 0; [ -n "$cmd" ] || { warn "cancelled"; return 0; }
  tui_read_tty -p "description (calendar note, optional): " desc || desc=""
  tui_confirm "Add a Calendar companion event?" || nocal=1
  local -a argv=()
  while IFS= read -r line; do argv+=("$line"); done < <(_i_compose_add_args "$name" "$mode" "$when" "$dow" "$cmd" "$desc" "$nocal")
  [ "${#argv[@]}" -gt 0 ] || { warn "nothing to create"; return 0; }
  say; say "${BLD}Preview (PLANNED):${RST}"
  cmd_add "${argv[@]}" --dry-run
  if tui_confirm "Create this schedule?"; then cmd_add "${argv[@]}"; else warn "cancelled"; fi
  _i_pause
}

_i_audit_menu() {
  local a
  a=$( { printf 'inventory\t%sinventory%s — all launchd plists + crontab\n' "$CYN" "$RST"
         printf 'doctor\t%sdoctor%s — drift audit\n'                        "$CYN" "$RST"
         printf 'reconcile\t%sreconcile%s — retire missed one-shots\n'      "$CYN" "$RST"
         printf 'back\t%sback%s\n'                                          "$DIM" "$RST"; } \
       | tui_pick_key --prompt 'audit > ') || return 0
  case "$a" in inventory) cmd_inventory ;; doctor) cmd_doctor ;; reconcile) cmd_reconcile ;; *) return 0 ;; esac
  _i_pause
}

_i_status_menu() {
  local a o
  a=$( { printf 'status\t%sstatus%s — live count + all-time outcomes\n' "$CYN" "$RST"
         printf 'history\t%shistory%s — recent events\n'                "$CYN" "$RST"
         printf 'filter\t%shistory%s — filter by outcome\n'             "$CYN" "$RST"
         printf 'back\t%sback%s\n'                                      "$DIM" "$RST"; } \
       | tui_pick_key --prompt 'status > ') || return 0
  case "$a" in
    status)  cmd_status ;;
    history) cmd_history ;;
    filter)  o=$( { printf 'ok\t%sok%s\n' "$GRN" "$RST";       printf 'failed\t%sfailed%s\n'   "$RED" "$RST"
                    printf 'missed\t%smissed%s\n' "$YLW" "$RST"; printf 'unknown\t%sunknown%s\n' "$DIM" "$RST"; } \
                 | tui_pick_key --prompt 'outcome > ') && [ -n "$o" ] && cmd_history --outcome "$o" ;;
    *) return 0 ;;
  esac
  _i_pause
}

# _i_plist_rows — existing com.alcatraz.*.plist under LaunchAgents as
# `fullpath<TAB>colored basename`, to seed the register picker. Pure (glob only).
_i_plist_rows() {
  local f
  for f in "$LAUNCHAGENTS"/com.alcatraz.*.plist; do
    [ -e "$f" ] || continue
    printf '%s\t%s%s%s\n' "$f" "$CYN" "$(basename "$f")" "$RST"
  done
}

_i_register_flow() {
  local p="" rows=""
  # tui_pick_or_add lets you arrow-pick a seeded plist OR type a brand-new path —
  # the typed query is returned when it matches nothing.
  rows=$(_i_plist_rows)
  if [ -n "$rows" ]; then
    p=$(printf '%s\n' "$rows" | tui_pick_or_add --prompt 'plist to adopt (pick or type a path) > ') || { warn "cancelled"; _i_pause; return 0; }
  else
    tui_read_tty -p "plist path to adopt: " p || { warn "cancelled"; _i_pause; return 0; }
  fi
  if [ -n "$p" ]; then cmd_register "$p"; else warn "cancelled"; fi
  _i_pause
}

# _i_main_menu — top-level options as `key<TAB>colored display`; every subcommand
# family is reachable from here. tui_pick_key returns the clean key.
_i_main_menu() {
  printf '%s\t%sBrowse%s & act on schedules\n'                  browse "$CYN" "$RST"
  printf '%s\t%sCreate%s a new schedule (wizard)\n'             create "$CYN" "$RST"
  printf '%s\t%sAdopt%s an existing plist (register)\n'         adopt  "$CYN" "$RST"
  printf '%s\t%sAudit%s & health (inventory/doctor/reconcile)\n' audit "$CYN" "$RST"
  printf '%s\t%sStatus%s & history\n'                           status "$CYN" "$RST"
  printf '%s\t%sHelp%s\n'                                       help   "$DIM" "$RST"
  printf '%s\t%sQuit%s\n'                                       quit   "$DIM" "$RST"
}

cmd_interactive() {
  local pick
  if ! _i_source_tui; then
    err "interactive mode needs ~/.claude/scripts/tui/ (colors/tty/require/pick)."
    say "Use the text subcommands instead: ${CYN}$PROG help${RST}"
    return 1
  fi
  if ! tui_have_tty; then
    err "gcc-schedule -i is the human front-end and needs a real terminal."
    say "Headless? Everything is a text subcommand: ${CYN}$PROG list${RST} · ${CYN}status${RST} · ${CYN}show <name>${RST} · ${CYN}add …${RST}  (${CYN}$PROG help${RST})"
    return 1
  fi
  say "${BLD}gcc-schedule${RST} ${DIM}interactive — ↑↓ to move, type to filter, enter to pick, esc/ctrl-c to leave${RST}"
  while :; do
    pick=$(_i_main_menu | tui_pick_key --prompt 'gcc-schedule > ') || break
    case "$pick" in
      browse)  _i_browse ;;
      create)  _i_add_wizard ;;
      adopt)   _i_register_flow ;;
      audit)   _i_audit_menu ;;
      status)  _i_status_menu ;;
      help)    cmd_help ;;
      quit|"") break ;;
      *)       break ;;
    esac
  done
  say "${DIM}bye${RST}"
}

# ── Dispatch ───────────────────────────────────────────────────────────────
# Guarded so the script can be SOURCED (test harness, shell completion) without
# executing a command: dispatch only when run directly, never when sourced.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
sub="${1:-help}"; shift 2>/dev/null || true
case "$sub" in
  -i|--interactive|i) cmd_interactive "$@" ;;
  add)              cmd_add      "$@" ;;
  list|ls)          cmd_list     "$@" ;;
  rm|remove|retire) cmd_rm       "$@" ;;
  run)              cmd_run      "$@" ;;
  logs|log)         cmd_logs     "$@" ;;
  show|info)        cmd_show     "$@" ;;
  enable|on|resume) cmd_enable   "$@" ;;
  disable|off|pause) cmd_disable "$@" ;;
  register|adopt)   cmd_register "$@" ;;
  duplicate|dup|copy) cmd_duplicate "$@" ;;
  inventory|audit)  cmd_inventory "$@" ;;
  doctor|health|drift) cmd_doctor "$@" ;;
  history|hist)     cmd_history  "$@" ;;
  status)           cmd_status   "$@" ;;
  reconcile)        cmd_reconcile "$@" ;;
  _record-run)      cmd__record_run "$@" ;;
  _retire-self)     cmd__retire_self "$@" ;;
  help|--help|-h)   cmd_help ;;
  *) err "unknown subcommand: $sub"; cmd_help; exit 1 ;;
esac
fi
