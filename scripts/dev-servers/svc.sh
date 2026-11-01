#!/usr/bin/env bash
# svc.sh: idle lifecycle for pm2-managed services.
#
# pm2 is the boundary of ownership: if pm2 runs it, this tool may stop it. A
# server started by hand in a terminal is the human's, and nothing here can
# reach it (user, 2026-08-06: "this is for the background pm2 stuff that is
# intended for claude's management").
#
# It applies at every tier. A tier-1 pinned port running under pm2 is still in
# scope, because the tier says who owns the PORT, not who owns the process.
#
# Unused means no person has used it, not "nothing is connected": health checks,
# API refreshes and parked tabs do not count. features/dev-servers.md holds the
# policy, and svc-sample.py decides each case.
#
# Stopping is never losing: reap records a revive line, and `up` brings the
# service straight back. Same principle as ports.sh reap/revive.
#
# Commands:
#   watch                sample activity, refresh lastseen
#   reap [--dry-run]     sample, then stop apps unused past their limit (launchd)
#   up <name>            start if stopped, wait for its port, mark used
#   down <name>          stop now and record it
#   hold <name> <len> <why>   keep it up for dedicated work, until the time runs out
#   release <name>       end a hold
#   touch <name|port>    say a person just used it
#   policy <name> ...    keep <why> | idle <minutes> [why] | default
#   status               table: state, ports, time unused, limit, verdict
#   ports <name>         the ports svc believes an app holds
#
# State sits beside the port ledger in ~/.claude/dev-servers/.
set -uo pipefail

DIR="$HOME/.claude/dev-servers"
EVENTS="$DIR/svc-events.jsonl"
STATE="$DIR/svc-state.json"
LOCK="$DIR/.svc.mutex"
POLICY="$DIR/svc-policy.json"
HOLDS="$DIR/svc-holds.json"
TOUCH_DIR="$DIR/svc-touch"
mkdir -p "$DIR" "$TOUCH_DIR"

PM2="${PM2_BIN:-$(command -v pm2 || echo /opt/homebrew/bin/pm2)}"
SAMPLER="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/svc-sample.py"
HOLDER="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/svc-holds.py"

# How long a service may sit unused by a person before it is stopped, unless
# svc-policy.json says otherwise for it. Short on purpose: the owner would rather
# restart a service than have forgotten ones running (2026-11-01).
IDLE_MIN="${SVC_IDLE_MIN:-120}"

# A service that just started has no traffic yet, so without this it could be
# reaped in the window between `up` and the first request.
GRACE_MIN="${SVC_GRACE_MIN:-30}"

# Names that must never be stopped however quiet they look. Meant for future
# background workers that hold no listening port and so read as idle forever.
NEVER_REAP="${SVC_NEVER_REAP:-}"
[ -f "$DIR/svc-never-reap" ] &&
  NEVER_REAP="$NEVER_REAP $(tr '\n' ' ' < "$DIR/svc-never-reap")"

SESSION="${CLAUDE_CODE_SESSION_ID:-manual}"
now_iso() { date -u '+%Y-%m-%dT%H:%M:%SZ'; }
emit() { printf '%s\n' "$1" >> "$EVENTS"; }

# mkdir is the atomic primitive available on macOS, which has no flock. The
# cron watch and an interactive `up` genuinely do collide on the state file.
lock() {
  local tries=0
  until mkdir "$LOCK" 2>/dev/null; do
    tries=$((tries + 1))
    [ "$tries" -gt 50 ] && { rm -rf "$LOCK"; continue; }
    sleep 0.1
  done
  trap 'rm -rf "$LOCK"' EXIT
}
unlock() { rm -rf "$LOCK"; trap - EXIT; }

# sample <watch|report> [json|table]
#   watch persists the new sample; report leaves state untouched.
sample() {
  # shellcheck disable=SC2086: NEVER_REAP is a deliberate word-split list
  "$PM2" jlist 2>/dev/null | python3 "$SAMPLER" \
    --state "$STATE" --mode "${1:-report}" --format "${2:-json}" \
    --idle-min "$IDLE_MIN" --grace-min "$GRACE_MIN" \
    --policy "$POLICY" --holds "$HOLDS" --touch-dir "$TOUCH_DIR" \
    --never $NEVER_REAP
}

# Read one app's field out of the persisted state, so callers avoid a second
# pm2 round trip (jlist takes tens of seconds on a loaded machine).
state_field() { # state_field <name> <field>
  python3 -c '
import json, sys
try:
    print(json.load(open(sys.argv[1])).get(sys.argv[2], {}).get(sys.argv[3], ""))
except Exception:
    print("")
' "$STATE" "$1" "$2" 2>/dev/null
}

pm2_status() { # pm2_status <name> -> online|stopped|...|missing
  "$PM2" jlist 2>/dev/null | python3 -c '
import json, sys
want = sys.argv[1]
try:
    apps = json.load(sys.stdin)
except Exception:
    apps = []
for a in apps:
    if a.get("name") == want:
        print((a.get("pm2_env") or {}).get("status", "?"))
        break
else:
    print("missing")
' "$1"
}

# Propagates the sampler's exit code so a failed run shows red in
# `launchctl list` instead of a silent green zero.
cmd_watch() {
  lock
  sample watch json > /dev/null
  local rc=$?
  unlock
  [ "$rc" -ne 0 ] && echo "svc watch: sampler failed (rc=$rc)" >&2
  return "$rc"
}

cmd_status() { sample report table; }

cmd_ports() { state_field "${1:-}" ports | tr -d '[],' | tr -s ' '; }

# Ports an app is known to use even while stopped: last-observed plus whatever
# pm2's config declares. This is what the pre-start squatter check reads.
known_ports() { state_field "${1:-}" known_ports | tr -d '[],' | tr -s ' '; }

restart_count() { # restart_count <name>
  "$PM2" jlist 2>/dev/null | python3 -c '
import json, sys
want = sys.argv[1]
try:
    apps = json.load(sys.stdin)
except Exception:
    apps = []
for a in apps:
    if a.get("name") == want:
        print((a.get("pm2_env") or {}).get("restart_time", 0))
        break
else:
    print(0)
' "$1"
}

cmd_reap() {
  local dry=0
  [ "${1:-}" = "--dry-run" ] && dry=1

  lock
  local rows; rows=$(sample watch json)
  unlock

  local targets
  targets=$(printf '%s' "$rows" | python3 -c '
import json, sys
try:
    rows = json.load(sys.stdin)
except Exception:
    sys.exit()
for r in rows:
    if r["verdict"] == "REAP":
        ports = ",".join(str(p) for p in r["ports"])
        print("{}\t{}\t{}".format(r["name"], r["idle_h"], ports))
')

  if [ -z "$targets" ]; then
    [ -n "${SVC_VERBOSE:-}" ] && echo "nothing unused past its limit"
    return 0
  fi

  printf '%s\n' "$targets" | while IFS=$'\t' read -r name idle ports; do
    [ -z "$name" ] && continue
    if [ "$dry" = 1 ]; then
      echo "would reap: $name (idle ${idle}h, ports ${ports:--})"
      continue
    fi
    if "$PM2" stop "$name" > /dev/null 2>&1; then
      emit "{\"ts\":\"$(now_iso)\",\"event\":\"reap\",\"name\":\"$name\",\"idle_h\":$idle,\"ports\":\"$ports\",\"revive\":\"svc up $name\",\"session\":\"$SESSION\"}"
      echo "reaped $name (idle ${idle}h): revive: svc up $name"
    else
      echo "svc: failed to stop $name" >&2
    fi
  done
  return 0
}

# Ensure a service is running and actually serving. Idempotent, so a caller can
# run it unconditionally rather than checking first.
cmd_up() {
  local name="${1:-}"
  [ -z "$name" ] && { echo "usage: svc up <name>" >&2; return 2; }

  local status; status=$(pm2_status "$name")

  if [ "$status" = "missing" ]; then
    echo "svc: no pm2 app named '$name'" >&2
    "$PM2" jlist 2>/dev/null | python3 -c '
import json, sys
try:
    apps = json.load(sys.stdin)
except Exception:
    apps = []
print("known:", ", ".join(sorted(a.get("name", "?") for a in apps)), file=sys.stderr)
'
    return 1
  fi

  if [ "$status" = "online" ]; then
    lock; sample watch json > /dev/null; unlock
    echo "$name already up"
    for p in $(cmd_ports "$name"); do echo "  http://127.0.0.1:$p"; done
    return 0
  fi

  # A stale listener on the target port is exactly what drove kanban into a
  # 22k-restart EADDRINUSE loop. Fail loudly here rather than hand pm2 a crash
  # loop that will churn silently for days.
  for p in $(known_ports "$name"); do
    if lsof -nP -iTCP:"$p" -sTCP:LISTEN > /dev/null 2>&1; then
      local holder
      holder=$(lsof -nP -iTCP:"$p" -sTCP:LISTEN 2>/dev/null | awk 'NR==2 {print $1" (pid "$2")"}')
      echo "svc: port $p is already held by $holder: not starting $name" >&2
      echo "     free that port first, or let the existing process serve it" >&2
      emit "{\"ts\":\"$(now_iso)\",\"event\":\"up_blocked\",\"name\":\"$name\",\"port\":$p,\"holder\":\"$holder\",\"session\":\"$SESSION\"}"
      return 1
    fi
  done

  local before; before=$(restart_count "$name")

  "$PM2" start "$name" > /dev/null 2>&1 ||
    { echo "svc: pm2 start $name failed" >&2; return 1; }
  emit "{\"ts\":\"$(now_iso)\",\"event\":\"up\",\"name\":\"$name\",\"session\":\"$SESSION\"}"

  # Wait for a real listening socket rather than trusting pm2's "online",
  # which only means the process was spawned.
  local waited=0
  while [ "$waited" -lt 30 ]; do
    lock; sample watch json > /dev/null; unlock
    local got; got=$(cmd_ports "$name")
    if [ -n "$got" ]; then
      echo "$name up"
      for p in $got; do echo "  http://127.0.0.1:$p"; done
      return 0
    fi

    # The squatter check above is blind to ports hardcoded in source, so catch
    # the crash loop by its signature instead: pm2 restarting the app while no
    # socket ever appears. Stopping beats letting it churn for days unnoticed.
    local after; after=$(restart_count "$name")
    if [ "$((after - before))" -ge 3 ]; then
      "$PM2" stop "$name" > /dev/null 2>&1
      echo "svc: $name is crash-looping ($((after - before)) restarts in ${waited}s): stopped it" >&2
      echo "     check: pm2 logs $name --err --lines 20" >&2
      emit "{\"ts\":\"$(now_iso)\",\"event\":\"crashloop\",\"name\":\"$name\",\"restarts\":$((after - before)),\"session\":\"$SESSION\"}"
      return 1
    fi

    sleep 2
    waited=$((waited + 2))
  done

  echo "svc: $name started but no listening port after ${waited}s (may still be booting)" >&2
  return 0
}

cmd_down() {
  local name="${1:-}"
  [ -z "$name" ] && { echo "usage: svc down <name>" >&2; return 2; }
  "$PM2" stop "$name" > /dev/null 2>&1 ||
    { echo "svc: pm2 stop $name failed" >&2; return 1; }
  emit "{\"ts\":\"$(now_iso)\",\"event\":\"down\",\"name\":\"$name\",\"revive\":\"svc up $name\",\"session\":\"$SESSION\"}"
  echo "stopped $name: revive: svc up $name"
  lock; sample watch json > /dev/null; unlock
}

# Record dedicated work on a service so reap leaves it alone until the time runs out.
cmd_hold() {
  local name="${1:-}" length="${2:-}" why="${3:-}"
  [ -z "$name" ] && { echo "usage: svc hold <name> <30m|4h|2d> <why>" >&2; return 2; }
  python3 "$HOLDER" hold "$HOLDS" "$name" "$length" "$why" "$SESSION" || return $?
  emit "$(python3 -c 'import json,sys; print(json.dumps({"ts":sys.argv[1],"event":"hold","name":sys.argv[2],"for":sys.argv[3],"why":sys.argv[4],"session":sys.argv[5]}))' "$(now_iso)" "$name" "$length" "$why" "$SESSION")"
  echo "held $name for $length: $why (end it early: svc release $name)"
}

cmd_release() {
  local name="${1:-}"
  [ -z "$name" ] && { echo "usage: svc release <name>" >&2; return 2; }
  python3 "$HOLDER" release "$HOLDS" "$name" || return $?
  emit "{\"ts\":\"$(now_iso)\",\"event\":\"release\",\"name\":\"$name\",\"session\":\"$SESSION\"}"
  echo "released $name"
}

# A person just used this service. Takes a pm2 name or a port, since a browser tab
# only knows the port.
cmd_touch() {
  local what="${1:-}"
  case "$what" in
    ""|*/*|.*) echo "usage: svc touch <name|port>" >&2; return 2 ;;
  esac
  touch "$TOUCH_DIR/$what"
}

cmd_policy() {
  local name="${1:-}"
  [ -z "$name" ] && { echo "usage: svc policy <name> keep <why> | idle <minutes> [why] | default" >&2; return 2; }
  shift
  python3 "$HOLDER" policy "$POLICY" "$name" "$@" || return $?
  cmd_status
}

usage() {
  cat <<'EOF'
svc: stop pm2 services nobody is using

  svc status                 what is running, how long unused, its limit, the verdict
  svc up <name>              start if stopped, wait for its port (idempotent)
  svc down <name>            stop now
  svc hold <name> <len> <why>   keep it up for dedicated work: 30m, 4h, up to 7d
  svc release <name>         end a hold
  svc touch <name|port>      say a person just used it
  svc policy <name> keep <why>            never stop it
  svc policy <name> idle <minutes> [why]  its own limit
  svc policy <name> default               back to the default limit
  svc reap [--dry-run]       stop anything unused past its limit (launchd)
  svc watch                  refresh activity state
  svc ports <name>           ports svc believes the app holds

Use means a person: the active Chrome tab (bfb reports it), another device on the
tailnet, or svc touch. Health checks, API refreshes and parked tabs do not count.

Scope: pm2-managed processes only. A server started by hand in a terminal is
untouched: svc cannot see it and will never stop it.

Tuning (env):
  SVC_IDLE_MIN     default limit, in minutes      (default 120)
  SVC_GRACE_MIN    protection after start         (default 30)
  SVC_NEVER_REAP   space-separated names to skip
                   (also ~/.claude/dev-servers/svc-never-reap, one per line)
EOF
}

case "${1:-}" in
  watch)  shift; cmd_watch "$@" ;;
  reap)   shift; cmd_reap "$@" ;;
  up)     shift; cmd_up "$@" ;;
  down)   shift; cmd_down "$@" ;;
  hold)   shift; cmd_hold "$@" ;;
  release) shift; cmd_release "$@" ;;
  touch)  shift; cmd_touch "$@" ;;
  policy) shift; cmd_policy "$@" ;;
  status) shift; cmd_status "$@" ;;
  ports)  shift; cmd_ports "$@" ;;
  ""|-h|--help|help) usage ;;
  *) echo "svc: unknown command '$1'" >&2; usage >&2; exit 2 ;;
esac
