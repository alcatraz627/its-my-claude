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
| **Config sub-files** | STALE per `updated` + `stale_after_days` frontmatter | `/doctor`-only |
| **Runtime notes** | active `runtime-notes.md` >800 lines (archival overdue) | `/doctor`-only |

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

## Step 1b: Config hygiene canaries

Two staleness checks on `~/.claude/` itself: sub-file freshness and runtime-notes size.

```bash
source ~/.claude/skills/shared/gum-tui.sh 2>/dev/null
gum_divider "Config Hygiene"

# Stale sub-files. validate-triggers prints:
#   ⚠ <file>: STALE — <age>d since update (threshold <N>d)
stale_lines=$(bash ~/.claude/scripts/validate-triggers.sh 2>&1 | rg "STALE")
if [ -n "$stale_lines" ]; then
  echo "$stale_lines" | while IFS= read -r line; do gum_warn "$line"; done
  gum_info "Refresh each file's content (or just its 'updated:' field if still accurate)"
else
  gum_success "No stale rules/features/conventions sub-files"
fi

# Runtime-notes size: >800 lines means archival is overdue.
# Rule: features/context-retention.md · archiver: scripts/archive-runtime-notes.sh
for nf in ~/.claude/skills/runtime-notes.md "$PWD/.claude/skills/runtime-notes.md"; do
  [ -f "$nf" ] || continue
  lines=$(wc -l < "$nf" | tr -d ' ')
  if [ "$lines" -gt 800 ]; then
    gum_warn "runtime-notes over budget: $nf (${lines} lines > 800) — run /archive-notes or scripts/archive-runtime-notes.sh"
  else
    gum_success "runtime-notes within budget: $nf (${lines} lines)"
  fi
done
```

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

## Step 3.5: Hook health (last 7d)

Step 3 checks that hook scripts *exist*; this checks how they're *landing* — a
3-line read from the fire telemetry (`ledger/hook-health.sh`). A gate that is muted
but still firing is the signal worth surfacing here.

```bash
source ~/.claude/skills/shared/gum-tui.sh 2>/dev/null
gum_divider "Hook Health (last 7d)"

HH=$(bash ~/.claude/scripts/ledger/hook-health.sh --within 7 --json 2>/dev/null)
if [ -z "$HH" ] || [ "$(echo "$HH" | jq -r '.note // empty' 2>/dev/null)" = "no telemetry yet" ]; then
  gum_muted "no hook telemetry yet (~/.claude/hooks/warn-events.jsonl)"
else
  gum_kv "hooks fired" "$(echo "$HH" | jq -r '.total_hooks') ($(echo "$HH" | jq -r '.total_fires') fires)"
  gum_kv "hottest"     "$(echo "$HH" | jq -r '.hooks[0] | "\(.hook) (\(.fires))"')"
  muted=$(echo "$HH" | jq -r '.muted_but_firing | if length==0 then "none" else join(", ") end')
  if [ "$muted" = "none" ]; then
    gum_success "no muted-but-firing gates"
  else
    gum_warn "MUTED but still firing: $muted"
  fi
  gum_info "full view: bash ~/.claude/scripts/ledger/hook-health.sh"
fi
```

**What to look for:**
- **A hook with a huge fire count** → it may be noisy (a hint firing on every prompt) — drill in with `hook-health.sh --hook <id>`
- **MUTED but still firing** → the mute file is present yet the gate keeps tripping; either the mute is stale or the gate ignores it

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
  lints=$(jq -r 'select(.tier=="find") | select(.subject | test("-lint: ")) | .instruction' "$LED/alerts.jsonl" 2>/dev/null | tail -3)
  if [ -n "$lints" ]; then
    gum_error "Detector-lint findings (a broken detector goes silently quiet — fix):"
    echo "$lints" | sed 's/^/  /'
  fi
  findings=$(jq -r 'select(.tier=="find") | select(.subject | test("-lint: ") | not) | .instruction' "$LED/alerts.jsonl" 2>/dev/null | tail -3)
  if [ -n "$findings" ]; then
    gum_warn "Substantive find-tier alerts (real signals, not broken detectors):"
    echo "$findings" | sed 's/^/  /'
  fi
fi
```

### 5.8 Port discipline (three-tier policy, migration 0029)

Surface what `ports.sh scan` flags — untracked listeners and expired one-offs
are exactly the "losing track of what is where" failure the policy exists for:

```bash
PSCAN=$(bash ~/.claude/scripts/dev-servers/ports.sh scan 2>/dev/null)
untracked=$(echo "$PSCAN" | rg -c "UNTRACKED" || true)
expired=$(echo "$PSCAN" | rg -c "EXPIRED" || true)
if [ "${untracked:-0}" -gt 0 ] || [ "${expired:-0}" -gt 0 ]; then
  gum_warn "Ports: ${untracked:-0} untracked listener(s), ${expired:-0} expired one-off claim(s)"
  echo "$PSCAN" | rg "UNTRACKED|EXPIRED" | sed 's/^/  /'
  gum_muted "  claim: ports.sh claim <name> --tier 2|3 · kill expired: ports.sh reap"
else
  gum_success "Ports: every listener tracked, no expired one-offs"
fi
```

### 5.9 i-dream pipeline health (nightly jobs fail silently otherwise)

The nightly i-dream jobs can die with zero log output — a binary replaced
in place invalidates its Mach-O signature cache and launchd's next spawn is
SIGKILLed (OS_REASON_CODESIGNING) or exits 78/EX_CONFIG before writing a
byte (2026-07-12 incident: audit + daily + dreampass all lost). launchctl's
last-exit column and the digest date gap are the only observable traces:

```bash
gum_divider "i-dream pipeline"
bad=$(launchctl list 2>/dev/null | rg "i-dream|idream" | awk '$2 != 0 && $2 != "-" {print $3" (exit "$2")"}')
if [ -n "$bad" ]; then
  gum_warn "i-dream jobs with nonzero last exit:"
  echo "$bad" | sed 's/^/  /'
  gum_muted "  78/-9 right after a rebuild = in-place binary copy poisoned the signature cache."
  gum_muted "  Fix the install habit: bash ~/Code/Claude/i-dream/scripts/install.sh (tmp+mv, never cp-in-place)"
else
  gum_success "i-dream launchd jobs: all clean last exits"
fi
latest=$(ls ~/.claude/i-dream/daily/2*.md 2>/dev/null | sort | tail -1)
if [ -n "$latest" ]; then
  latest_date=$(basename "$latest" .md)
  days_old=$(( ( $(date +%s) - $(date -j -f "%Y-%m-%d" "$latest_date" +%s 2>/dev/null || echo 0) ) / 86400 ))
  if [ "$days_old" -ge 2 ]; then
    gum_warn "Daily digest stale: newest is $latest_date (${days_old}d old) — the 03:00 job is silently failing"
  else
    gum_success "Daily digest current ($latest_date)"
  fi
fi
```

---

## Step 5.8: Skills roster health (in-04)

Three checks on the skill roster itself: a stale index misroutes discovery, an
over-budget description gets dropped by the roster first, and a skill with no
recorded run has no efficacy evidence behind it.

```bash
source ~/.claude/skills/shared/gum-tui.sh 2>/dev/null
gum_divider "Skills roster"
SK=~/.claude/skills
newer=$(find "$SK" -name SKILL.md -newer "$SK/00-index.md" 2>/dev/null | wc -l | tr -d ' ')
if [ "$newer" = "0" ]; then gum_success "index current (no SKILL.md newer than 00-index.md)"
else gum_warn "index STALE: $newer SKILL.md newer than 00-index.md — run: bash ~/.claude/scripts/skills-index.sh"; fi
overs=$(python3 ~/.claude/scripts/skill-lint.py "$SK"/*/SKILL.md 2>/dev/null | rg -c "description-long"); overs=${overs:-0}
if [ "$overs" = "0" ]; then gum_success "description budget: no skill over the 300-char cap"
else gum_warn "description budget: $overs skill(s) over the 300-char cap (roster drops long ones first) — python3 ~/.claude/scripts/skill-lint.py to list"; fi
python3 - <<'PY'
import json, glob, os
names = {os.path.basename(os.path.dirname(f)) for f in glob.glob(os.path.expanduser('~/.claude/skills/*/SKILL.md'))}
ev = os.path.expanduser('~/.claude/skills/usage/events.jsonl')
used = set()
if os.path.exists(ev):
    for ln in open(ev):
        try: used.add(json.loads(ln).get('skill', ''))
        except Exception: pass
un = sorted(names - used)
head = ', '.join(un[:8]) + (' …' if len(un) > 8 else '')
print(f"  unrecorded: {len(un)} of {len(names)} skills have no skill-log run" + (f" ({head})" if un else ''))
PY
```

The unrecorded count is information, not an alarm: rarely-used skills are
legitimate. It feeds the same judgment the 2026-08-20 catalog eval used
(usage pyramid, zero-evidence skills), on demand instead of once.

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
- `/revive` (full rehydration) or `/catchup` (checkpoint briefing) for prior sessions. `/past-sessions` is parked
