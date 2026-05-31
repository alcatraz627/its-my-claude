#!/usr/bin/env bash
# gcc-schedule — manage user-level launchd schedules with Calendar companion.
#
# Why this exists: every one-shot we build needs a launchd plist + a shell
# script + a date-guard + self-unload + a Calendar event with retirement
# notes (per rules/cron-calendar-companion.md). Doing that by hand is ~5
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
SCHED_HOME="$HOME/.claude/scheduled"
LAUNCHAGENTS="$HOME/Library/LaunchAgents"
LOG_HOME="$HOME/.claude/logs/launchd"
REGISTRY="$SCHED_HOME/registry.json"
PROG="${0##*/}"
USER_UID=$(id -u)

mkdir -p "$SCHED_HOME" "$LOG_HOME"
[[ -f "$REGISTRY" ]] || echo '{}' > "$REGISTRY"

# ── Colors / output ────────────────────────────────────────────────────────
if [[ -t 1 ]]; then
  BLD=$'\033[1m'; RST=$'\033[0m'; DIM=$'\033[2m'
  RED=$'\033[31m'; GRN=$'\033[32m'; YLW=$'\033[33m'; CYN=$'\033[36m'
else
  BLD=''; RST=''; DIM=''; RED=''; GRN=''; YLW=''; CYN=''
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

${BLD}USAGE${RST}
  $PROG add  --name <slug> --at <YYYY-MM-DDTHH:MM> --command <shell> [opts]
  $PROG list [--all]
  $PROG rm   <name>

${BLD}add FLAGS${RST}
  --name <slug>           label = com.alcatraz.<slug> (required)
  --at <ISO datetime>     fire ONCE at local datetime (required for v0.1)
  --command <shell>       command to run, executed via bash -c (required)
  --description <text>    Calendar event notes suffix
  --alert <minutes>       Calendar alarm minutes before (default 10; 0 = none)
  --no-calendar           skip Calendar event (against cron-calendar-companion rule)
  --no-bootstrap          write files but don't load into launchd
  --force                 overwrite existing schedule with same name

${BLD}EXAMPLE${RST}
  $PROG add --name backup-pull --at 2026-06-02T15:00 \\
    --command 'open -na Ghostty.app --args -e zsh -lc "rsync …"' \\
    --description 'Pull mac-migration backup before flight'

${BLD}DEFERRED (v0.2)${RST}
  recurring (--daily-at / --weekly), logs, run, show, enable/disable

${BLD}FILES${RST}
  registry:    $REGISTRY
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

validate_name() {
  [[ "$1" =~ ^[a-z][a-z0-9-]{1,40}$ ]] || \
    fail "name '$1' must be kebab-case, start with letter, 2-41 chars"
}

# parse_at "<YYYY-MM-DDTHH:MM>" → echoes "year month day hour minute"
parse_at() {
  local at="$1"
  [[ "$at" =~ ^([0-9]{4})-([0-9]{2})-([0-9]{2})T([0-9]{2}):([0-9]{2})$ ]] || \
    fail "--at must be YYYY-MM-DDTHH:MM (24-hour local time)"
  # Drop leading zeros for arithmetic comparison
  local y="${BASH_REMATCH[1]}" mo=$((10#${BASH_REMATCH[2]})) \
        d=$((10#${BASH_REMATCH[3]})) h=$((10#${BASH_REMATCH[4]})) \
        mi=$((10#${BASH_REMATCH[5]}))
  (( mo >= 1 && mo <= 12 )) || fail "month $mo out of range"
  (( d  >= 1 && d  <= 31 )) || fail "day $d out of range"
  (( h  >= 0 && h  <= 23 )) || fail "hour $h out of range"
  (( mi >= 0 && mi <= 59 )) || fail "minute $mi out of range"
  # Reject past datetimes (more than 1 minute ago)
  local epoch now
  epoch=$(date -j -f '%Y-%m-%dT%H:%M' "$at" +%s 2>/dev/null) || \
    fail "could not parse --at '$at' as a date"
  now=$(date +%s)
  (( epoch > now - 60 )) || fail "--at $at is in the past"
  echo "$y $mo $d $h $mi"
}

# AppleScript month names (Calendar.app expects English month constant)
month_name() {
  local arr=(January February March April May June July August September October November December)
  echo "${arr[$(( $1 - 1 ))]}"
}

# ── Calendar event ─────────────────────────────────────────────────────────
calendar_create() {
  # calendar_create <year> <month> <day> <hour> <minute> <summary> <notes> <alert_minutes>
  local y="$1" mo="$2" d="$3" h="$4" mi="$5" sum="$6" notes="$7" alert="$8"
  local mname; mname=$(month_name "$mo")
  local alarm=""
  if (( alert > 0 )); then
    alarm="    make new sound alarm at end of newEvent with properties {trigger interval:-$alert}"
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
  # write_oneshot_script <path> <iso_fire_date YYYY-MM-DD> <command> <label> <plist>
  local out="$1" fire_date="$2" cmd="$3" label="$4" plist="$5"
  cat > "$out" <<SCRIPT
#!/usr/bin/env bash
# Generated by gcc-schedule on $(date '+%F %T %Z').
# One-shot launchd target: fires once on $fire_date local time, then self-unloads.
set -uo pipefail

LABEL="$label"
PLIST="$plist"
FIRE_DATE="$fire_date"
USER_UID=$USER_UID

# Date guard: launchd StartCalendarInterval has no Year key, so without this
# the plist would re-fire every year on the same date. The guard exits clean
# on any non-matching day.
today=\$(date '+%Y-%m-%d')
if [[ "\$today" != "\$FIRE_DATE" ]]; then
  echo "[\$today] not the intended fire date \$FIRE_DATE — exiting"
  exit 0
fi

echo "[\$(date '+%F %T')] running scheduled command"
# ── User command ──
bash -c $(printf %q "$cmd")

# ── Self-clean ──
echo "[\$(date '+%F %T')] self-unloading \$LABEL"
launchctl bootout "gui/\$USER_UID/\$LABEL" 2>/dev/null || true
rm -f "\$PLIST"
exit 0
SCRIPT
  chmod +x "$out"
}

write_plist() {
  # write_plist <path> <label> <script_path> <month> <day> <hour> <minute> <out_log> <err_log>
  local plist="$1" label="$2" script="$3" mo="$4" d="$5" h="$6" mi="$7" outlog="$8" errlog="$9"
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
    </dict>
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
  local name="" at="" cmd_str="" desc="" alert="10"
  local do_calendar=1 do_bootstrap=1 force=0

  while (( $# )); do
    case "$1" in
      --name)         name="$2"; shift 2 ;;
      --at)           at="$2"; shift 2 ;;
      --command)      cmd_str="$2"; shift 2 ;;
      --description)  desc="$2"; shift 2 ;;
      --alert)        alert="$2"; shift 2 ;;
      --no-calendar)  do_calendar=0; shift ;;
      --no-bootstrap) do_bootstrap=0; shift ;;
      --force)        force=1; shift ;;
      -h|--help)      cmd_help; exit 0 ;;
      *) fail "unknown flag: $1 (try '$PROG help')" ;;
    esac
  done

  [[ -n "$name"    ]] || fail "--name is required"
  [[ -n "$at"      ]] || fail "--at is required"
  [[ -n "$cmd_str" ]] || fail "--command is required"
  validate_name "$name"
  [[ "$alert" =~ ^[0-9]+$ ]] || fail "--alert must be a non-negative integer"

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

  # Parse fire datetime
  read -r y mo d h mi < <(parse_at "$at")
  local fire_date="$y-$(printf '%02d' $mo)-$(printf '%02d' $d)"

  # Materialise files
  mkdir -p "$sched_dir"
  write_oneshot_script "$script" "$fire_date" "$cmd_str" "$label" "$plist"
  write_plist "$plist" "$label" "$script" "$mo" "$d" "$h" "$mi" "$outlog" "$errlog"

  # Lint plist
  if ! plutil -lint "$plist" >/dev/null; then
    rm -f "$plist"; rm -rf "$sched_dir"
    fail "plist lint failed — rolled back"
  fi

  # Calendar
  local cal_uid=""
  if (( do_calendar )); then
    local summary notes
    summary="[cron-once] $name — fires $fire_date $(printf '%02d:%02d' $h $mi)"
    notes="label: $label
runs: $script
plist: $plist
out log: $outlog
err log: $errlog
fires: ONCE on $fire_date $(printf '%02d:%02d' $h $mi) local time then self-unloads
managed-by: gcc-schedule
retire: '$PROG rm $name' or 'launchctl bootout gui/$USER_UID/$label' + delete this event${desc:+

$desc}"
    cal_uid=$(calendar_create "$y" "$mo" "$d" "$h" "$mi" "$summary" "$notes" "$alert" | tail -1)
    if [[ -z "$cal_uid" ]]; then
      warn "Calendar event creation returned empty UID — Automations permission for osascript? (event NOT created)"
    else
      ok "Calendar event: $cal_uid"
    fi
  else
    warn "Calendar event skipped per --no-calendar (against cron-calendar-companion rule)"
  fi

  # Bootstrap
  if (( do_bootstrap )); then
    if launchctl bootstrap "gui/$USER_UID" "$plist" 2>&1; then
      ok "loaded into launchd (gui/$USER_UID/$label)"
    else
      warn "bootstrap failed — files written but agent not loaded"
    fi
  else
    warn "skipped bootstrap per --no-bootstrap (load later with: launchctl bootstrap gui/$USER_UID $plist)"
  fi

  # Meta + registry
  cat > "$meta" <<META
{
  "name": "$name",
  "label": "$label",
  "kind": "one-shot",
  "fire_at": "$at",
  "command": $(printf '%s' "$cmd_str" | jq -Rs .),
  "description": $(printf '%s' "$desc" | jq -Rs .),
  "calendar_uid": "$cal_uid",
  "created_at": "$(date -u '+%FT%TZ')",
  "plist": "$plist",
  "script": "$script",
  "out_log": "$outlog",
  "err_log": "$errlog"
}
META
  jq_inplace "$REGISTRY" ". + {\"$name\": $(cat "$meta")}"
  ok "registered: $name"

  printf '\n%sscript: %s\n  plist:  %s\n  fires:  %s\n  retire: %s rm %s%s\n' \
    "$DIM" "$script" "$plist" "$at" "$PROG" "$name" "$RST"
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
  local label plist sched_dir cal_uid
  label=$(jq -r '.label' <<<"$entry")
  plist=$(jq -r '.plist' <<<"$entry")
  sched_dir="$SCHED_HOME/$name"
  cal_uid=$(jq -r '.calendar_uid // ""' <<<"$entry")

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
  _retire "$1"
}

# ── Dispatch ───────────────────────────────────────────────────────────────
sub="${1:-help}"; shift 2>/dev/null || true
case "$sub" in
  add)              cmd_add  "$@" ;;
  list|ls)          cmd_list "$@" ;;
  rm|remove|retire) cmd_rm   "$@" ;;
  help|--help|-h)   cmd_help ;;
  *) err "unknown subcommand: $sub"; cmd_help; exit 1 ;;
esac
