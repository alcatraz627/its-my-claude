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
  $PROG add     --name <slug> --at <YYYY-MM-DDTHH:MM> --command <shell> [opts]
  $PROG list    [--all]
  $PROG show    <name>             pretty-print details, state, next-fire countdown
  $PROG run     <name>             execute the user command now (no date guard, no self-unload)
  $PROG logs    <name> [--lines N] [--no-follow]   tail out + err logs
  $PROG enable  <name>             bootstrap a loaded-out plist
  $PROG disable <name>             bootout the launchd agent, keep plist on disk
  $PROG rm      <name>             retire fully (bootout + delete plist/script/Calendar event)

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
  local name="$1" entry cmd_str
  entry=$(_get_entry "$name")
  cmd_str=$(jq -r '.command' <<<"$entry")
  [[ -n "$cmd_str" && "$cmd_str" != "null" ]] || fail "registry has no command for '$name'"
  say "${BLD}running command for '$name' (test fire — no date guard, no self-unload)${RST}"
  say "${DIM}$ $cmd_str${RST}"
  bash -c "$cmd_str"
  local rc=$?
  if (( rc == 0 )); then ok "command exited 0"; else err "command exited $rc"; fi
  return $rc
}

# ── logs ───────────────────────────────────────────────────────────────────
cmd_logs() {
  local lines=50 follow=1
  while (( $# )); do
    case "$1" in
      --lines)     lines="$2"; shift 2 ;;
      --no-follow) follow=0; shift ;;
      -*) fail "unknown flag: $1" ;;
      *)  break ;;
    esac
  done
  [[ $# -ge 1 ]] || fail "usage: $PROG logs <name> [--lines N] [--no-follow]"
  local name="$1" entry outlog errlog
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

  # Next-fire time relative-to-now
  local epoch_fire epoch_now next_rel="(unknown)"
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

  # Log freshness
  local last_fired="never"
  if [[ -f "$outlog" ]]; then
    last_fired=$(date -r "$outlog" '+%F %T %Z' 2>/dev/null || echo unknown)
  fi

  printf '%s%s%s\n' "$BLD" "── $name ──" "$RST"
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
  printf '  %s\n' "${DIM}command:${RST}"
  printf '    %s%s%s\n' "$DIM" "$cmd_str" "$RST"
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
    ok "unloaded: $label (plist + script preserved — 'enable' to reload)"
  else
    fail "bootout failed"
  fi
}

# ── Dispatch ───────────────────────────────────────────────────────────────
sub="${1:-help}"; shift 2>/dev/null || true
case "$sub" in
  add)              cmd_add     "$@" ;;
  list|ls)          cmd_list    "$@" ;;
  rm|remove|retire) cmd_rm      "$@" ;;
  run)              cmd_run     "$@" ;;
  logs|log)         cmd_logs    "$@" ;;
  show|info)        cmd_show    "$@" ;;
  enable|on)        cmd_enable  "$@" ;;
  disable|off)      cmd_disable "$@" ;;
  help|--help|-h)   cmd_help ;;
  *) err "unknown subcommand: $sub"; cmd_help; exit 1 ;;
esac
