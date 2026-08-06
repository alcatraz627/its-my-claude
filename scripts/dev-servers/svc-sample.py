#!/usr/bin/env python3
"""Work out which pm2 services are actually being used, and which are just running.

The distinction matters because a dev server costs the same whether someone is
using it or not. This reads `pm2 jlist` on stdin and answers, per app: what
ports does it really hold, has anyone touched it lately, and should it be
stopped.

Two things make that harder than it sounds, and both are handled here:

  Ports hide one level down. pm2 tracks the process it spawned, which for an
  npm-wrapped app is the `npm run dev` shell, not the server. The listening
  socket belongs to a child. Asking only about pm2's pid finds nothing, so we
  walk the whole descendant tree.

  A connection is not the same as use. Vite holds an HMR websocket open to any
  browser tab left sitting there, so "is anything connected" answers yes for as
  long as the tab exists. Real traffic keeps arriving on new ephemeral source
  ports; a parked websocket keeps the one it started with. So use is measured
  as peer endpoints that were not present at the previous sample.

Usage:
    pm2 jlist | svc-sample.py --state PATH --mode watch|report
                              [--idle-hours H] [--grace-min M]
                              [--never NAME ...] [--format json|table]

--mode watch persists the new sample; --mode report leaves state untouched.
"""

import argparse
import json
import os
import subprocess
import sys
import time


def process_tree():
    """Map every pid to its direct children, for walking down from a pm2 pid."""
    children = {}
    try:
        out = subprocess.run(
            ["ps", "-Ao", "pid,ppid"], capture_output=True, text=True, timeout=15
        ).stdout
    except Exception:
        return children
    for line in out.splitlines()[1:]:
        parts = line.split()
        if len(parts) < 2:
            continue
        try:
            pid, ppid = int(parts[0]), int(parts[1])
        except ValueError:
            continue
        children.setdefault(ppid, []).append(pid)
    return children


def descendants(children, root):
    seen, stack = set(), [root]
    while stack:
        for child in children.get(stack.pop(), []):
            if child not in seen:
                seen.add(child)
                stack.append(child)
    return seen


def socket_map():
    """One lsof sweep, returned as (ports each pid listens on, peers per local port).

    Peers are keyed by the remote "host:port" string because that is what
    distinguishes a reload from a websocket that has simply been left open.
    """
    listening, peers = {}, {}
    try:
        out = subprocess.run(
            ["lsof", "-nP", "-iTCP"], capture_output=True, text=True, timeout=30
        ).stdout
    except Exception:
        return listening, peers

    for line in out.splitlines()[1:]:
        fields = line.split()
        if len(fields) < 9:
            continue
        try:
            pid = int(fields[1])
        except ValueError:
            continue
        name = fields[8]

        if "(LISTEN)" in line:
            if ":" in name:
                try:
                    listening.setdefault(pid, set()).add(int(name.rsplit(":", 1)[1]))
                except ValueError:
                    pass
        elif "(ESTABLISHED)" in line and "->" in name:
            local, remote = name.split("->", 1)
            try:
                local_port = int(local.rsplit(":", 1)[1])
            except ValueError:
                continue
            peers.setdefault(local_port, set()).add(remote)

    return listening, peers


def configured_ports(env):
    """Ports declared in pm2's own config (args or env).

    A stopped app holds no socket, so this is the only way `svc up` can know
    which port to check for a squatter. Blind to ports hardcoded in source.
    """
    found = set()

    args = env.get("args") or []
    if isinstance(args, str):
        args = args.split()
    for i, a in enumerate(args):
        a = str(a)
        if a in ("--port", "-p") and i + 1 < len(args):
            try:
                found.add(int(str(args[i + 1])))
            except ValueError:
                pass
        elif a.startswith("--port="):
            try:
                found.add(int(a.split("=", 1)[1]))
            except ValueError:
                pass

    for key in ("PORT", "SERVER_PORT", "VITE_PORT"):
        val = (env.get("env") or {}).get(key)
        if val:
            try:
                found.add(int(str(val)))
            except ValueError:
                pass

    return found


def load_state(path):
    try:
        with open(path) as fh:
            return json.load(fh)
    except Exception:
        return {}


def save_state(path, state):
    tmp = path + ".tmp"
    with open(tmp, "w") as fh:
        json.dump(state, fh, indent=1, sort_keys=True)
    os.replace(tmp, path)


def reap_verdict(online, protected, ports, age_min, idle_h, grace_min, idle_limit):
    """Decide what should happen to one app. Order matters: the skip cases come
    first so a boot in progress is never mistaken for an idle service."""
    if not online:
        return "stopped"
    if protected:
        return "protected"
    if not ports:
        # Nothing listening anywhere in the tree. Either a background worker or
        # a server still starting. Neither is safe to stop on this evidence.
        return "no-port(skip)"
    if age_min < grace_min:
        return "grace"
    if idle_h >= idle_limit:
        return "REAP"
    return "active"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--state", required=True)
    ap.add_argument("--mode", choices=["watch", "report"], default="report")
    ap.add_argument("--idle-hours", type=float, default=12.0)
    ap.add_argument("--grace-min", type=float, default=30.0)
    ap.add_argument("--never", nargs="*", default=[])
    ap.add_argument("--format", choices=["json", "table"], default="json")
    args = ap.parse_args()

    now = time.time()
    never = set(args.never)

    # An unreadable pm2 response is a failure, not an empty estate: writing {}
    # over real state loses every known_port.
    try:
        apps = json.load(sys.stdin)
    except Exception as exc:
        print(f"svc-sample: cannot read pm2 output ({exc}); state left untouched",
              file=sys.stderr)
        return 3

    if not isinstance(apps, list):
        print("svc-sample: pm2 output was not a list; state left untouched",
              file=sys.stderr)
        return 3

    children = process_tree()
    listening, peers = socket_map()
    previous = load_state(args.state)

    state, rows = {}, []

    for app in apps:
        env = app.get("pm2_env") or {}
        name = app.get("name")
        if not name:
            continue

        status = env.get("status", "?")
        online = status == "online"
        pid = app.get("pid") or env.get("pid") or 0

        ports = set()
        if online and pid:
            for proc in [pid] + sorted(descendants(children, pid)):
                ports |= listening.get(proc, set())

        endpoints = set()
        for port in ports:
            endpoints |= peers.get(port, set())

        prior = previous.get(name, {})
        prior_endpoints = set(prior.get("endpoints", []))
        lastseen = prior.get("lastseen") or 0
        started = prior.get("started") or 0

        # The load-bearing line: a peer we had not seen means someone made a
        # new connection, which is the only reliable evidence of real use.
        touched = bool(endpoints - prior_endpoints)

        if online and (touched or not lastseen):
            lastseen = now
        if online and not started:
            started = now
        if not online:
            started = 0

        # Ports survive a stop: once the app goes down the live sweep sees
        # nothing, and that is exactly when `svc up` needs to know where to
        # look for a squatter.
        remembered = set(prior.get("known_ports", [])) | configured_ports(env) | ports

        state[name] = {
            "endpoints": sorted(endpoints),
            "lastseen": lastseen,
            "started": started,
            "ports": sorted(ports),
            "known_ports": sorted(remembered),
            "status": status,
        }

        idle_h = (now - lastseen) / 3600.0 if lastseen else 0.0
        age_min = (now - started) / 60.0 if started else 0.0

        rows.append(
            {
                "name": name,
                "status": status,
                "ports": sorted(ports),
                "conns": len(endpoints),
                "idle_h": round(idle_h, 2),
                "restarts": env.get("restart_time", 0),
                "verdict": reap_verdict(
                    online, name in never, ports, age_min, idle_h,
                    args.grace_min, args.idle_hours,
                ),
            }
        )

    rows.sort(key=lambda r: r["name"])

    if args.mode == "watch":
        save_state(args.state, state)

    if args.format == "table":
        if not rows:
            print("no pm2 apps")
            return
        print(f"{'APP':22} {'STATUS':9} {'PORTS':13} {'CONN':>4} {'IDLE':>7}  VERDICT")
        print("-" * 74)
        for r in rows:
            ports_s = ",".join(str(p) for p in r["ports"]) or "-"
            idle_s = f"{r['idle_h']:.1f}h" if r["status"] == "online" else "-"
            print(
                f"{r['name']:22} {r['status']:9} {ports_s:13} "
                f"{r['conns']:>4} {idle_s:>7}  {r['verdict']}"
            )
    else:
        print(json.dumps(rows))

    return 0


if __name__ == "__main__":
    sys.exit(main())
