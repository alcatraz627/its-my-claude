#!/usr/bin/env bash
# ports.sh — the port ledger for every dev server an agent (or the human) runs.
#
# Three tiers, three postures (features/dev-servers.md):
#   1 mature   — user-owned ports, declared with `pin`; nothing may squat them.
#   2 local    — persistent local services (pm2 lane); allocated from 5100-5399.
#   3 one-off  — ephemeral demos/dashboards; allocated from 6200-6499 with a TTL
#                (default 24h). Expired one-offs are killed by `reap`, which
#                records the exact revive command; `revive` brings one back and
#                a second revival auto-flags the claim as mis-tiered.
#
# State: append-only events at ~/.claude/dev-servers/port-events.jsonl (flock'd);
# current state is a fold over events. The old hand-edited
# scratchpad/global/port-registry.md is replaced by the derived view this tool
# regenerates at ~/.claude/dev-servers/port-registry.md (migration 0029).
#
# Commands:
#   scan               live listeners vs claims — the "what is where" table
#   list               folded claim/pin state (no lsof)
#   claim <name> --tier 2|3 [--port N] [--ttl-h H] [--note S]   allocate + record
#   pin <port> <name> [--note S]                                 tier-1 declaration
#   free <port|name>                                             release a claim
#   reap [--dry-run] [--yes]     kill expired tier-3 listeners (+ record revive info)
#   revive <name|port>           print (and record) the revive for a reaped claim
#   next --tier 2|3              print next free port in band (used by the guard hook)
#   check <port> [cwd]           policy verdict for a port: ok|blocked|pinned (hook API)
#
# Always exits 0 on read commands; mutating commands exit non-zero on misuse.
set -uo pipefail

DIR="$HOME/.claude/dev-servers"
EVENTS="$DIR/port-events.jsonl"
DERIVED="$DIR/port-registry.md"
LOCK="$DIR/.events.lock"
mkdir -p "$DIR"

TIER2_LO=5100 TIER2_HI=5399
TIER3_LO=6200 TIER3_HI=6499
TTL_DEFAULT_H=24
# Framework defaults agents must never squat (pinned tier-1 entries override
# for their own project): vite 5173+, CRA/next 3000/3001, angular 4200,
# flask/simple 5000/8000, misc catch-alls.
BLOCKLIST="3000 3001 4200 5000 5173 5174 5175 5176 5177 5178 5179 8000 8080 8888"

SESSION="${CLAUDE_CODE_SESSION_ID:-manual}"
NOW() { date -u '+%Y-%m-%dT%H:%M:%SZ'; }

emit() { # emit <json-line>  (append is O_APPEND-atomic for these line sizes)
  printf '%s\n' "$1" >> "$EVENTS"
}

# Allocation mutex — macOS has no flock, and the race is check-then-act anyway
# (read `next`, THEN append), so the whole compute+emit must be one critical
# section. mkdir is the portable atomic primitive. Skeptical-review finding 1
# proved the unprotected version hands the SAME port to concurrent claimers
# (8/8 collisions). skills/shared/lock-file.sh exists but carries a per-skill
# ownership registry — too heavy for a sub-second CLI hot path; this local
# 8-liner is the deliberate right-size (documented in the architecture doc).
MUTEX="$DIR/.claim.mutex"
lock_alloc() {
  local i=0
  until mkdir "$MUTEX" 2>/dev/null; do
    i=$((i + 1))
    if [ "$i" -ge 50 ]; then
      echo "ports: allocation mutex busy 5s — if no other claim is running, clear a stale lock: rmdir $MUTEX" >&2
      return 1
    fi
    sleep 0.1
  done
  trap 'rmdir "$MUTEX" 2>/dev/null' EXIT INT TERM
}
unlock_alloc() { rmdir "$MUTEX" 2>/dev/null || true; trap - EXIT INT TERM; }

# Fold events + optionally join live lsof state. One python does all the logic;
# bash stays a thin argv/lock/kill layer.
py() {
  python3 - "$EVENTS" "$@" <<'PY'
import json, os, subprocess, sys, datetime

events_path = sys.argv[1]
mode = sys.argv[2] if len(sys.argv) > 2 else "list"
args = sys.argv[3:]

def now():
    return datetime.datetime.now(datetime.timezone.utc)

def parse_ts(s):
    try:
        return datetime.datetime.strptime(s, "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=datetime.timezone.utc)
    except Exception:
        return None

# ── fold ──────────────────────────────────────────────────────────────────
state = {}   # port -> claim dict
events = []
if os.path.exists(events_path):
    for line in open(events_path):
        line = line.strip()
        if not line:
            continue
        try:
            e = json.loads(line)
        except Exception:
            continue
        events.append(e)

for e in events:
    port = e.get("port")
    op = e.get("op")
    if port is None:
        continue
    if op in ("pin", "claim", "revive"):
        prev = state.get(port, {})
        cur = {
            "port": port, "name": e.get("name") or prev.get("name") or "?",
            "tier": 1 if op == "pin" else (e.get("tier") or prev.get("tier") or 3),
            "status": "pinned" if op == "pin" else "claimed",
            "ts": e.get("ts"), "session": e.get("session"),
            "note": e.get("note") or prev.get("note") or "",
            "ttl_h": e.get("ttl_h") or prev.get("ttl_h"),
            "cwd": e.get("cwd") or prev.get("cwd") or "",
            "cmd": e.get("cmd") or prev.get("cmd") or "",
            "revives": prev.get("revives", 0) + (1 if op == "revive" else 0),
        }
        state[port] = cur
    elif op == "free":
        state.pop(port, None)
    elif op == "reap":
        if port in state:
            state[port]["status"] = "reaped"
            state[port]["reap"] = {"ts": e.get("ts"), "cmd": e.get("cmd"), "cwd": e.get("cwd")}

def expires(c):
    if c.get("tier") == 3 and c.get("status") == "claimed" and c.get("ttl_h"):
        t = parse_ts(c.get("ts") or "")
        if t:
            return t + datetime.timedelta(hours=float(c["ttl_h"]))
    return None

def is_expired(c):
    e = expires(c)
    return bool(e and now() > e)

# ── live listeners (scan/reap need them) ─────────────────────────────────
def listeners():
    out = {}
    try:
        r = subprocess.run(["lsof", "-iTCP", "-sTCP:LISTEN", "-P", "-n"],
                           capture_output=True, text=True, timeout=8)
    except Exception:
        return out
    for ln in r.stdout.splitlines()[1:]:
        f = ln.split()
        if len(f) < 9:
            continue
        try:
            port = int(f[8].rsplit(":", 1)[-1])
        except Exception:
            continue
        if port in out:
            continue
        out[port] = {"proc": f[0], "pid": int(f[1])}
    return out

def proc_detail(pid):
    cmd, cwd = "", ""
    try:
        r = subprocess.run(["ps", "-o", "args=", "-p", str(pid)], capture_output=True, text=True, timeout=3)
        cmd = r.stdout.strip()
    except Exception:
        pass
    try:
        r = subprocess.run(["lsof", "-p", str(pid)], capture_output=True, text=True, timeout=4)
        for ln in r.stdout.splitlines():
            f = ln.split()
            if len(f) >= 9 and f[3] == "cwd":
                cwd = f[-1]
                break
    except Exception:
        pass
    return cmd, cwd

SYSTEMISH = ("postgres", "redis-ser", "mongod", "nginx", "ollama", "ControlCe",
             "rapportd", "adb", "llama-ser", "Code\\x20H", "Python.app")

if mode == "list":
    rows = sorted(state.values(), key=lambda c: c["port"])
    for c in rows:
        exp = expires(c)
        extra = f" expires:{exp.strftime('%m-%d %H:%MZ')}{' EXPIRED' if is_expired(c) else ''}" if exp else ""
        rv = f" revives:{c['revives']}" if c.get("revives") else ""
        print(f"{c['port']}\tT{c['tier']}\t{c['status']}\t{c['name']}{extra}{rv}\t{c.get('note','')}")

elif mode == "next":
    tier = int(args[0])
    lo, hi = (5100, 5399) if tier == 2 else (6200, 6499)
    live = listeners()
    for p in range(lo, hi + 1):
        c = state.get(p)
        if c and c["status"] in ("pinned", "claimed"):
            continue
        if p in live:
            continue
        print(p)
        break

elif mode == "check":
    # verdict for the guard hook: OK | BLOCKED <why> | PINNED <name>
    port = int(args[0])
    cwd = args[1] if len(args) > 1 else ""
    block = {int(x) for x in os.environ.get("PORTS_BLOCKLIST", "").split()}
    c = state.get(port)
    if c and c["status"] == "pinned":
        # The pinned project itself may use its port; anyone else is blocked.
        # Boundary-aware match (/Code/app must not own /Code/app-v2), and an
        # unscoped pin gets its own verdict so the hook can give the OWNER
        # remedy (rescope the pin) instead of telling the owner to claim
        # tier-3 (skeptical-review finding 2).
        pin_cwd = c.get("cwd", "").rstrip("/")
        if not pin_cwd:
            print(f"PINNED-UNSCOPED {c['name']}")
        elif cwd.rstrip("/") == pin_cwd or cwd.startswith(pin_cwd + "/"):
            print("OK pinned-owner")
        else:
            print(f"PINNED {c['name']}")
    elif c and c["status"] == "claimed":
        # Same owner semantics for claims: the claiming project may relaunch
        # on its own port (config-pinned bare `npm run dev` included).
        claim_cwd = c.get("cwd", "").rstrip("/")
        if claim_cwd and (cwd.rstrip("/") == claim_cwd or cwd.startswith(claim_cwd + "/")):
            print("OK claimed-owner")
        else:
            print(f"CLAIMED {c['name']} T{c['tier']}")
    elif port in block:
        print("BLOCKED framework-default")
    else:
        print("OK")

elif mode == "scan":
    live = listeners()
    print(f"{'PORT':>5}  {'STATE':<10} {'TIER':<4} {'NAME/PROC':<28} DETAIL")
    for port in sorted(live):
        info = live[port]
        c = state.get(port)
        if c:
            exp = " EXPIRED" if is_expired(c) else ""
            print(f"{port:>5}  {'live+' + c['status']:<10} T{c['tier']:<3} {c['name']:<28} {c.get('note','')}{exp}")
        elif info["proc"].startswith(SYSTEMISH) or info["proc"] in ("launchd",):
            print(f"{port:>5}  {'system':<10} {'-':<4} {info['proc']:<28} pid {info['pid']}")
        else:
            cmd, cwd = proc_detail(info["pid"])
            print(f"{port:>5}  {'UNTRACKED':<10} {'?':<4} {info['proc']:<28} pid {info['pid']} · {cwd or '?'} · {cmd[:60]}")
    dead = [c for p, c in sorted(state.items()) if p not in live and c["status"] in ("pinned", "claimed")]
    if dead:
        print("\nClaims with no live listener (fine for pins; stale for tier 3):")
        for c in dead:
            print(f"{c['port']:>5}  {c['status']:<10} T{c['tier']:<3} {c['name']:<28} {'EXPIRED' if is_expired(c) else ''}")

elif mode == "reap-candidates":
    live = listeners()
    out = []
    for port, c in state.items():
        if c["tier"] == 3 and c["status"] == "claimed" and is_expired(c) and port in live:
            pid = live[port]["pid"]
            cmd, cwd = proc_detail(pid)
            out.append({"port": port, "name": c["name"], "pid": pid, "cmd": cmd, "cwd": cwd})
    print(json.dumps(out))

elif mode == "revive-info":
    # Read reap records from the RAW event log, not the folded view: once a
    # reaped port is re-claimed by a new tenant, the fold overwrites the entry
    # and the revive promise silently breaks (review finding 4). The log keeps
    # every reap forever; the newest matching one wins.
    key = args[0]
    reap_ev = None
    for e in events:
        if e.get("op") == "reap" and (e.get("name") == key or str(e.get("port")) == key):
            reap_ev = e
    if not reap_ev:
        sys.exit(1)
    port = reap_ev.get("port")
    revives = sum(1 for e in events if e.get("op") == "revive" and e.get("name") == reap_ev.get("name"))
    cur = state.get(port)
    occupied = bool(cur and cur.get("status") in ("pinned", "claimed") and cur.get("name") != reap_ev.get("name"))
    tier = 3
    for e in events:
        if e.get("op") in ("claim", "revive") and e.get("name") == reap_ev.get("name") and e.get("tier"):
            tier = e.get("tier")
    print(json.dumps({"port": port, "name": reap_ev.get("name"), "tier": tier,
                      "cmd": reap_ev.get("cmd") or "", "cwd": reap_ev.get("cwd") or "",
                      "revives": revives, "occupied": occupied,
                      "occupant": (cur or {}).get("name", "")}))

elif mode == "resolve":
    # Exact-name (or port) → port, from folded state. Replaces the old awk
    # parse of `list` display output, which broke on tier-3 rows because the
    # expiry suffix defeated the match (review finding 6).
    key = args[0]
    for c in state.values():
        if c["name"] == key or str(c["port"]) == key:
            print(c["port"])
            break

elif mode == "derived":
    rows = sorted(state.values(), key=lambda c: (c["tier"], c["port"]))
    print("# Port Registry (DERIVED — regenerate via `ports.sh scan`; never hand-edit)")
    print(f"\n_Source: dev-servers/port-events.jsonl · regenerated {now().strftime('%Y-%m-%d %H:%M')}Z_\n")
    print("| Port | Tier | Status | Name | Note |")
    print("|------|------|--------|------|------|")
    for c in rows:
        print(f"| {c['port']} | {c['tier']} | {c['status']} | {c['name']} | {c.get('note','')} |")
PY
}

usage() { sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'; }

cmd="${1:-}"; shift || true
case "$cmd" in
  scan)
    PORTS_BLOCKLIST="$BLOCKLIST" py scan
    py derived > "$DERIVED" 2>/dev/null || true
    ;;
  list) py list ;;
  next)
    tier=""; while [ $# -gt 0 ]; do case "$1" in --tier) tier="$2"; shift 2;; *) shift;; esac; done
    [ "$tier" = 2 ] || [ "$tier" = 3 ] || { echo "ports next --tier 2|3" >&2; exit 2; }
    py next "$tier"
    ;;
  check)
    PORTS_BLOCKLIST="$BLOCKLIST" py check "$@"
    ;;
  claim)
    name="${1:-}"; shift || true
    [ -n "$name" ] || { echo "ports claim <name> --tier 2|3 [--port N] [--ttl-h H] [--note S]" >&2; exit 2; }
    # cwd is recorded so the claiming project can relaunch on its own port
    # (owner semantics in `check`); claim from the project root, or pass --cwd.
    tier="" port="" ttl="" note="" cwd="$PWD"
    while [ $# -gt 0 ]; do case "$1" in
      --tier) tier="$2"; shift 2 ;; --port) port="$2"; shift 2 ;;
      --ttl-h) ttl="$2"; shift 2 ;; --note) note="$2"; shift 2 ;;
      --cwd) cwd="$2"; shift 2 ;;
      *) echo "claim: unknown flag $1" >&2; exit 2 ;;
    esac; done
    [ "$tier" = 2 ] || [ "$tier" = 3 ] || { echo "claim: --tier 2|3 required (tier 1 uses pin)" >&2; exit 2; }
    lock_alloc || exit 1
    [ -n "$port" ] || port=$(py next "$tier")
    [ -n "$port" ] || { unlock_alloc; echo "claim: band exhausted" >&2; exit 1; }
    [ "$tier" = 3 ] && [ -z "$ttl" ] && ttl="$TTL_DEFAULT_H"
    emit "$(jq -cn --arg ts "$(NOW)" --arg n "$name" --arg s "$SESSION" --arg note "$note" --arg cwd "$cwd" \
      --argjson p "$port" --argjson t "$tier" --argjson ttl "${ttl:-null}" \
      '{ts:$ts, op:"claim", port:$p, name:$n, tier:$t, ttl_h:$ttl, session:$s, note:$note, cwd:$cwd}')"
    unlock_alloc
    echo "$port"
    ;;
  pin)
    port="${1:-}"; name="${2:-}"; shift 2 || true
    # cwd defaults to where the pin is made from — an unscoped pin blocks even
    # its own owner (dead exemption, review finding 2). Pass --cwd "" only if
    # you deliberately want an owner-less reservation.
    note=""; cwd="$PWD"
    while [ $# -gt 0 ]; do case "$1" in
      --note) note="$2"; shift 2 ;; --cwd) cwd="$2"; shift 2 ;;
      *) echo "pin: unknown flag $1" >&2; exit 2 ;;
    esac; done
    [ -n "$port" ] && [ -n "$name" ] || { echo "ports pin <port> <name> [--cwd DIR] [--note S]" >&2; exit 2; }
    emit "$(jq -cn --arg ts "$(NOW)" --arg n "$name" --arg s "$SESSION" --arg note "$note" --arg cwd "$cwd" \
      --argjson p "$port" '{ts:$ts, op:"pin", port:$p, name:$n, session:$s, note:$note, cwd:$cwd}')"
    echo "pinned $port → $name"
    ;;
  free)
    key="${1:-}"; [ -n "$key" ] || { echo "ports free <port|name>" >&2; exit 2; }
    port=$(py resolve "$key")
    [ -n "$port" ] || { echo "free: no claim matching '$key'" >&2; exit 1; }
    emit "$(jq -cn --arg ts "$(NOW)" --arg s "$SESSION" --argjson p "$port" '{ts:$ts, op:"free", port:$p, session:$s}')"
    echo "freed $port"
    ;;
  reap)
    dry=0; yes=0
    while [ $# -gt 0 ]; do case "$1" in --dry-run) dry=1; shift;; --yes) yes=1; shift;; *) shift;; esac; done
    cands=$(py reap-candidates)
    n=$(printf '%s' "$cands" | jq 'length')
    [ "$n" -gt 0 ] || { echo "nothing to reap (no expired tier-3 listeners)"; exit 0; }
    printf '%s' "$cands" | jq -r '.[] | "  :\(.port)  \(.name)  pid \(.pid)  \(.cwd)"'
    [ "$dry" = 1 ] && exit 0
    if [ "$yes" != 1 ]; then
      # shellcheck disable=SC1091
      source "$HOME/.claude/scripts/tui/pick.sh" 2>/dev/null || true
      if command -v tui_confirm >/dev/null 2>&1; then
        tui_confirm "Kill these $n expired one-off server(s)? (revive info is recorded)" || exit 0
      else
        echo "re-run with --yes to confirm (no TTY confirm available)"; exit 0
      fi
    fi
    printf '%s' "$cands" | jq -c '.[]' | while IFS= read -r c; do
      pid=$(printf '%s' "$c" | jq -r '.pid'); port=$(printf '%s' "$c" | jq -r '.port')
      kill "$pid" 2>/dev/null || true
      emit "$(printf '%s' "$c" | jq -c --arg ts "$(NOW)" --arg s "$SESSION" \
        '{ts:$ts, op:"reap", port:.port, name:.name, cmd:.cmd, cwd:.cwd, session:$s}')"
      echo "reaped :$port (pid $pid) — revive later: ports.sh revive $port"
    done
    py derived > "$DERIVED" 2>/dev/null || true
    ;;
  revive)
    key="${1:-}"; [ -n "$key" ] || { echo "ports revive <name|port>" >&2; exit 2; }
    info=$(py revive-info "$key") || { echo "revive: no reaped claim matching '$key'" >&2; exit 1; }
    port=$(printf '%s' "$info" | jq -r '.port'); cmd=$(printf '%s' "$info" | jq -r '.cmd')
    cwd=$(printf '%s' "$info" | jq -r '.cwd'); revives=$(printf '%s' "$info" | jq -r '.revives')
    tier=$(printf '%s' "$info" | jq -r '.tier'); name=$(printf '%s' "$info" | jq -r '.name')
    occupied=$(printf '%s' "$info" | jq -r '.occupied'); occupant=$(printf '%s' "$info" | jq -r '.occupant')
    ttl="$TTL_DEFAULT_H"
    lock_alloc || exit 1
    if [ "$occupied" = "true" ]; then
      # The old port found a new tenant while this claim was dead — revival
      # gets a fresh band port instead of evicting anyone.
      newport=$(py next "$tier")
      [ -n "$newport" ] || { unlock_alloc; echo "revive: band exhausted" >&2; exit 1; }
      echo "note: :$port is now held by '$occupant' — reviving '$name' on :$newport instead (adjust the port flag in the command below)."
      port="$newport"
    fi
    emit "$(jq -cn --arg ts "$(NOW)" --arg n "$name" --arg s "$SESSION" --arg cmd "$cmd" --arg cwd "$cwd" \
      --argjson p "$port" --argjson t "$tier" --argjson ttl "$ttl" \
      '{ts:$ts, op:"revive", port:$p, name:$n, tier:$t, ttl_h:$ttl, cmd:$cmd, cwd:$cwd, session:$s}')"
    unlock_alloc
    echo "revive :$port ($name) — run:"
    echo "  (cd $cwd && $cmd)"
    if [ "$((revives + 1))" -ge 2 ]; then
      echo "⚑ MIS-TIERED: '$name' has now been revived $((revives + 1))×. A one-off that keeps"
      echo "  coming back is a tier-2 service — promote it: ports.sh free $port &&"
      echo "  ports.sh claim $name --tier 2, then run it under pm2 (features/dev-servers.md)."
    fi
    ;;
  -h|--help|help|"") usage ;;
  *) echo "ports.sh: unknown command '$cmd' (see ports.sh help)" >&2; exit 2 ;;
esac
exit 0
