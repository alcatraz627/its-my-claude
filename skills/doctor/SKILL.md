---
name: doctor
description: On-demand environment health check — worktrees, pm2 status, disk, WAL staleness, git dirtiness, plus hook/event-log integrity. Use when the user asks "what's wrong", "check health", "/doctor", or reports flaky hook/MCP behavior.
---

# Doctor — Environment Health Check

Wraps `~/.claude/scripts/health-check.sh` (which already runs silently at SessionStart)
and adds on-demand extended diagnostics that would be too noisy to emit on every session.

## When to use

- User types `/doctor` or asks "is my setup healthy?"
- Hooks appear to be firing but nothing happens
- `events.jsonl` looks empty / stale
- MCP servers are acting up
- Before a critical session, as a pre-flight

## What it checks

| Category | Check | Source |
|---|---|---|
| Worktrees | Stale (>3d) | `health-check.sh` |
| pm2 | Errored processes | `health-check.sh` |
| Disk | <2GB free on `/` | `health-check.sh` |
| WAL | Stale (>24h since update) | `health-check.sh` |
| Git | >10 uncommitted files | `health-check.sh` |
| **Events log** | exists, recent entries, size, 24h event-kind histogram, top projects, 10-line tail | `/doctor`-only |
| **Hook integrity** | all hook scripts referenced in `settings.json` exist and are executable | `/doctor`-only |
| **MCP config** | `.mcp.json` valid JSON, no obvious issues | `/doctor`-only |

---

## Step 0: Init — source gum and print header

Always run this first so gum helpers are available to all subsequent steps.

```bash
source ~/.claude/skills/shared/gum-tui.sh 2>/dev/null
gum_header "Doctor Report"
```

---

## Step 1: Run the shared health check

```bash
source ~/.claude/skills/shared/gum-tui.sh 2>/dev/null
gum_divider "Shared Health Check"
hc_output=$(echo "{\"cwd\": \"$PWD\"}" | bash ~/.claude/scripts/health-check.sh 2>&1)
if [ -z "$hc_output" ]; then
  gum_success "All baseline checks passed (worktrees, pm2, disk, WAL, git)"
else
  echo "$hc_output" | while IFS= read -r line; do
    gum_warn "$line"
  done
fi
```

If there are warnings, they will print here. If clean, one green success line.

---

## Step 2: Event log health

This step is the richest health signal — it tells you whether hooks are firing,
what's been active in the last 24h, and shows the most recent 10 events inline.

**Note:** Use `jq` for the "today" check — do NOT use `grep` (the `ugrep` alias on macOS
does not match POSIX grep flags and will fail silently, returning a false-positive zero count).

```bash
source ~/.claude/skills/shared/gum-tui.sh 2>/dev/null
gum_divider "Events Log"

LOG=$(bash ~/.claude/scripts/find-events-log.sh)
if [ ! -f "$LOG" ]; then
  gum_error "Events log not found at: $LOG"
  gum_info "emit-event.sh may have never fired — check settings.json hook entries"
else
  size=$(wc -c < "$LOG" | tr -d ' ')
  lines=$(wc -l < "$LOG" | tr -d ' ')
  last_ts=$(tail -1 "$LOG" | jq -r '.ts // "?"' 2>/dev/null)

  gum_kv "path"  "$LOG"  "$GUM_GRAY"
  gum_kv "size"  "${size}B"
  gum_kv "lines" "$lines"
  gum_kv "last"  "$last_ts"

  # Warn if >50MB
  if [ "$size" -gt 52428800 ]; then
    gum_warn "over 50MB — rotate-events.sh should archive this on next Stop"
  fi

  # Today check via jq (avoids ugrep alias issues with grep)
  # Check both UTC date and the 24h window to handle timezone edge cases
  cutoff=$(date -u -v-24H '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null \
           || date -u -d '24 hours ago' '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null)
  today_count=$(jq -r --arg cutoff "$cutoff" \
    'select(.ts >= $cutoff) | .ts' "$LOG" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$today_count" -eq 0 ]; then
    gum_warn "no events in last 24h — check emit-event.sh hooks"
  else
    gum_success "$today_count events in last 24h"
  fi

  # 24h histogram by event kind — rendered as a table
  echo
  gum_divider "Event Kinds (last 24h)"
  hist_data=$(jq -r --arg cutoff "$cutoff" \
    'select(.ts >= $cutoff) | .event // "unknown"' "$LOG" 2>/dev/null \
    | sort | uniq -c | sort -rn | head -10 \
    | awk '{ printf "%s,%s\n", $1, $2 }')
  if [ -n "$hist_data" ]; then
    gum_table "Count,Event" $hist_data
  else
    gum_muted "(no events found)"
  fi

  # Top 5 projects in last 24h
  echo
  gum_divider "Top Projects (last 24h)"
  proj_data=$(jq -r --arg cutoff "$cutoff" \
    'select(.ts >= $cutoff) | .project // (.cwd // "" | split("/") | last) // "unknown"' \
    "$LOG" 2>/dev/null \
    | sort | uniq -c | sort -rn | head -5 \
    | awk '{ count=$1; $1=""; sub(/^ /,""); printf "%s,%s\n", count, $0 }')
  if [ -n "$proj_data" ]; then
    gum_table "Count,Project" $proj_data
  else
    gum_muted "(no project data)"
  fi

  # Last 10 events as a table
  echo
  gum_divider "Last 10 Events"
  events_data=$(tail -10 "$LOG" 2>/dev/null | jq -r '
    (.ts // "-")[11:19] as $t
    | (.event // "?") as $e
    | (.project // (.cwd // "" | split("/") | last) // "-") as $p
    | (.prompt_preview // .tool // "") as $extra
    | "\($t),\($e),\($p),\($extra[0:40])"
  ' 2>/dev/null)
  if [ -n "$events_data" ]; then
    gum_table "Time,Event,Project,Detail" $events_data
  else
    gum_muted "(no events)"
  fi
fi
```

**What to look for:**
- **0 events in last 24h** → emitter is broken (hook missing, path wrong, or flock stuck)
- **Only `SessionStart` entries** → non-interactive sessions only; prompts/tools not firing
- **`last=` timestamp >1 hour old during active work** → emit-event.sh is silently failing
- **`project` column shows `unknown`** → cwd-to-project resolution fell through

---

## Step 3: Hook integrity

Parse `~/.claude/settings.json` hook commands; for each script path found, verify it
exists and is executable. Flag broken ones.

**Note:** Use `/usr/bin/grep` explicitly — the `ugrep` alias breaks `-oE` flag parsing.

```bash
source ~/.claude/skills/shared/gum-tui.sh 2>/dev/null
gum_divider "Hook Integrity"

broken=0
while IFS= read -r path; do
  expanded="${path/#\~/$HOME}"
  if [ ! -f "$expanded" ]; then
    gum_error "MISSING: $path"
    broken=$((broken+1))
  elif [ ! -x "$expanded" ]; then
    gum_warn "not executable: $path"
    broken=$((broken+1))
  fi
done < <(
  jq -r '.hooks | .. | objects | select(.command) | .command' \
    ~/.claude/settings.json 2>/dev/null \
    | /usr/bin/grep -oE '(/[^ ]+\.sh|~/[^ ]+\.sh)' \
    | sort -u
)

if [ "$broken" -eq 0 ]; then
  gum_success "All hook scripts present and executable"
fi
```

---

## Step 4: MCP config validity

```bash
source ~/.claude/skills/shared/gum-tui.sh 2>/dev/null
gum_divider "MCP Config"

for f in ~/.claude/.mcp.json ~/.claude/mcp-catalog.json; do
  if [ ! -f "$f" ]; then
    gum_muted "not found: $f"
    continue
  fi
  if ! jq empty "$f" 2>/dev/null; then
    gum_error "invalid JSON: $f"
  else
    gum_success "valid JSON: $(basename $f)"
  fi
done
```

---

## Step 5: Backup retention preview

Runs `prune-backups.sh --preview` (read-only — never deletes). Lists candidates older
than `BACKUP_RETENTION_DAYS` (default 180d) so the user can decide.

```bash
source ~/.claude/skills/shared/gum-tui.sh 2>/dev/null
gum_divider "Backup Retention"

preview=$(bash ~/.claude/scripts/rotation/prune-backups.sh --preview 2>&1 | head -30)
if echo "$preview" | /usr/bin/grep -q "nothing older"; then
  gum_success "Nothing older than 180 days"
else
  gum_warn "Prunable backups found:"
  echo "$preview"
  gum_info "Apply with: bash ~/.claude/scripts/rotation/prune-backups.sh --apply"
fi
```

---

## Step 5.7: Ledger alerts

Read-only view of the event-ledger alert layer (refreshed daily by the
`ledger-evaluate` cron at 03:15). Shows firing detectors, their latest actionable
instruction, and any detector-lint findings — a *misconfigured* detector is a
silent-failure risk, so surfacing it here is load-bearing.

```bash
source ~/.claude/skills/shared/gum-tui.sh 2>/dev/null
gum_divider "Ledger Alerts"

LED=~/.claude/ledger
if [ ! -f "$LED/detector-state.json" ]; then
  gum_muted "alert layer not yet evaluated (daily 03:15, or: bash ~/.claude/scripts/ledger/evaluate-detectors.sh)"
else
  firing=$(jq -r 'to_entries[] | select(.value.firing==true) | .key' "$LED/detector-state.json" 2>/dev/null)
  if [ -n "$firing" ]; then
    gum_warn "Detectors FIRING: $(echo "$firing" | tr '\n' ' ')"
    for d in $firing; do
      msg=$(jq -r --arg d "$d" 'select(.detector==$d and .actionable==true) | .instruction' "$LED/alerts.jsonl" 2>/dev/null | tail -1)
      [ -n "$msg" ] && gum_info "  $d: $msg"
    done
  else
    gum_success "No ledger detectors firing"
  fi
  lints=$(jq -r 'select(.tier=="find") | .instruction' "$LED/alerts.jsonl" 2>/dev/null | tail -3)
  if [ -n "$lints" ]; then
    gum_error "Detector-lint findings (a broken detector goes silently quiet — fix):"
    echo "$lints" | sed 's/^/  /'
  fi
fi
```

---

## Step 6: Summary

Collate all findings into a completion block. The severity summary should reflect
the worst issue found across all steps: error > warning > healthy.

```bash
source ~/.claude/skills/shared/gum-tui.sh 2>/dev/null
# Summarise what was checked — actual issue counts come from steps above
gum_complete "doctor" \
  "Baseline=health-check.sh" \
  "Events=events.jsonl" \
  "Hooks=settings.json scripts" \
  "MCP=.mcp.json + mcp-catalog.json" \
  "Backups=prune-backups.sh --preview"
```

---

## Notes

- This skill is **strictly read-only** — it never mutates config, never restarts processes, never deletes files.
- If a check reveals something fixable (stale WAL, errored pm2, missing script), suggest the fix but do not apply it.
- Quick turnaround: target <2s total. Skip expensive checks (network, full git log) by design.
- **grep alias hazard:** macOS ships with `ugrep` aliased as `grep` in some shells. All grep calls in this skill use `/usr/bin/grep` or are replaced by `jq` to avoid this.
- Complements SessionStart — that fires passively and quietly; `/doctor` is the loud, on-demand variant.

## Related

- `~/.claude/scripts/health-check.sh` — the underlying SessionStart check
- `~/.claude/scripts/find-events-log.sh` — event log path resolver
- `~/.claude/scripts/rotation/prune-backups.sh` — backup retention helper (Step 5 above)
- `~/.claude/scripts/validate-memory.sh` — deep-check memory for stale file references. Not run by default (scans every `memory/*.md`); run manually when auditing memory rot: `bash ~/.claude/scripts/validate-memory.sh`
- `~/.claude/scripts/propose.sh` — file a proposal for any improvement `/doctor` reveals but cannot fix
- `/past-sessions` — for inspecting prior conversation transcripts
