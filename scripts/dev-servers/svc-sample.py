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

  A connection is not the same as use. Health checks, API refreshes and parked
  tabs all connect without anyone being there, and a person on a kept-alive
  connection makes no new ones. So use means evidence of a person, listed in
  person_use(); features/dev-servers.md holds the policy in full.

Usage:
    pm2 jlist | svc-sample.py --state PATH --mode watch|report
                              [--idle-min M] [--grace-min M]
                              [--never NAME ...] [--format json|table]
                              [--policy PATH] [--holds PATH] [--touch-dir DIR]

--mode watch persists the new sample; --mode report leaves state untouched.
"""

import argparse
import json
import os
import re
import subprocess
import sys
import time

# Chrome for Testing is left out on purpose: that is an agent's browser run, and
# dedicated agent work says so with a hold.
BROWSERS = ("Google Chrome", "Safari", "com.apple.WebKit", "Arc", "Brave", "Microsoft Edge", "firefox")

# bfb reports the active tab about once a minute and a heartbeat every few. Past
# this it is not running, and browser connections become the fallback evidence.
TAB_REPORT_STALE_S = 600

# Keyboard or mouse within this long means someone is at the machine.
PRESENT_S = 300


def peer_kind(remote, client):
    """Say who is on the far end of a connection: a person's browser, a person on
    another device, or background work on this machine."""
    host = remote.rsplit(":", 1)[0].strip("[]")
    if host not in ("127.0.0.1", "::1", "localhost"):
        return "remote"
    client = (client or "").replace("\\x20", " ")
    if client.startswith("tailscaled"):
        return "remote"
    if "for Testing" not in client and client.startswith(BROWSERS):
        return "browser"
    return "background"


def person_use(new_kinds, touched_at, tab_report_at, idle_s, now):
    """The newest evidence that a person used this service in this sample.

    Returns (when, source), or (0, "") when there is none. Touches come from the
    active tab or the app itself. A new connection from another device counts,
    since nothing here polls over the tailnet. A browser connection only counts
    while bfb is not reporting tabs and someone is at the machine, because a
    parked tab connects too.
    """
    best, source = (touched_at, "touch") if touched_at else (0, "")
    if "remote" in new_kinds:
        best, source = now, "remote"
    elif "browser" in new_kinds and now - tab_report_at > TAB_REPORT_STALE_S and idle_s < PRESENT_S:
        best, source = now, "browser"
    return best, source


def machine_idle_seconds():
    """How long since the last keyboard or mouse input. Zero when it cannot be
    read, so a broken probe reads as present rather than stopping a service."""
    try:
        out = subprocess.run(["ioreg", "-c", "IOHIDSystem", "-r", "-d", "1", "-k", "HIDIdleTime"],
                             capture_output=True, text=True, timeout=10).stdout
        m = re.search(r'"HIDIdleTime"\s*=\s*(\d+)', out)
        return int(m.group(1)) / 1e9 if m else 0.0
    except Exception:
        return 0.0


def mtime(path):
    try:
        return os.stat(path).st_mtime
    except OSError:
        return 0


def load_json(path):
    try:
        with open(path) as fh:
            return json.load(fh)
    except Exception:
        return {}


def service_policy(policy, name):
    """One service's rule: its class, idle limit and reason, over the defaults."""
    merged = dict(policy.get("default") or {})
    merged.update((policy.get("services") or {}).get(name) or {})
    return merged


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
    """One lsof sweep: (ports each pid listens on, peers per local port, who owns
    each local endpoint).

    Peers are keyed by the remote "host:port" string because that is what
    distinguishes a reload from a websocket that has simply been left open. A
    loopback peer's own socket is in the same sweep, which is how a connection
    gets traced back to the program that made it.
    """
    listening, peers, owners = {}, {}, {}
    try:
        out = subprocess.run(
            ["lsof", "+c", "0", "-nP", "-iTCP"], capture_output=True, text=True, timeout=30
        ).stdout
    except Exception:
        return listening, peers, owners

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
            owners[local] = fields[0]

    return listening, peers, owners


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


def reap_verdict(online, protected, ports, age_min, idle_min, grace_min, idle_limit, held=False):
    """Decide what should happen to one app. Order matters: the skip cases come
    first so a boot in progress is never mistaken for an idle service."""
    if not online:
        return "stopped"
    if protected:
        return "protected"
    if held:
        return "held"
    if not ports:
        # Nothing listening anywhere in the tree. Either a background worker or
        # a server still starting. Neither is safe to stop on this evidence.
        return "no-port(skip)"
    # The grace period protects a fresh start, but never for longer than the
    # service's own limit, or a limit under 30 minutes would mean nothing.
    if age_min < min(grace_min, idle_limit):
        return "grace"
    if idle_min >= idle_limit:
        return "REAP"
    return "active"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--state", required=True)
    ap.add_argument("--mode", choices=["watch", "report"], default="report")
    ap.add_argument("--idle-min", type=float, default=120.0)
    ap.add_argument("--grace-min", type=float, default=30.0)
    ap.add_argument("--never", nargs="*", default=[])
    ap.add_argument("--format", choices=["json", "table"], default="json")
    ap.add_argument("--policy", default="")
    ap.add_argument("--holds", default="")
    ap.add_argument("--touch-dir", default="")
    args = ap.parse_args()

    now = time.time()
    never = set(args.never)
    policy = load_json(args.policy) if args.policy else {}
    holds = load_json(args.holds) if args.holds else {}
    touched = lambda key: mtime(os.path.join(args.touch_dir, str(key))) if args.touch_dir else 0
    tab_report_at = touched(".browser")
    idle_s = machine_idle_seconds()

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
    listening, peers, owners = socket_map()
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
        source = prior.get("source") or ""

        new_kinds = {peer_kind(r, owners.get(r)) for r in endpoints - prior_endpoints}
        touch_at = max([touched(name)] + [touched(p) for p in ports])
        when, why = person_use(new_kinds, touch_at, tab_report_at, idle_s, now)
        if online and when > lastseen:
            lastseen, source = when, why

        # Starting a service counts as use, whoever started it (svc up, Switchboard,
        # bfb), or a service reaped once keeps its old lastseen and is reaped again
        # every pass. pm2's own start time sees all of them, even between samples.
        began = (env.get("pm_uptime") or 0) / 1000.0 if online else 0
        if online and (began > lastseen or not lastseen):
            lastseen, source = began or now, "start"
        if online:
            started = began or started or now
        else:
            started = 0

        # Ports survive a stop: once the app goes down the live sweep sees
        # nothing, and that is exactly when `svc up` needs to know where to
        # look for a squatter.
        remembered = set(prior.get("known_ports", [])) | configured_ports(env) | ports

        state[name] = {
            "endpoints": sorted(endpoints),
            "lastseen": lastseen,
            "source": source,
            "started": started,
            "ports": sorted(ports),
            "known_ports": sorted(remembered),
            "status": status,
        }

        idle_min = (now - lastseen) / 60.0 if lastseen else 0.0
        age_min = (now - started) / 60.0 if started else 0.0

        rule = service_policy(policy, name)
        keep = name in never or rule.get("class") == "keep"
        limit = float(rule.get("idle_min") or args.idle_min)
        hold = holds.get(name) or {}
        held = (hold.get("until") or 0) > now

        rows.append(
            {
                "name": name,
                "status": status,
                "ports": sorted(ports),
                "known_ports": sorted(remembered),
                "conns": len(endpoints),
                "idle_h": round(idle_min / 60.0, 2),
                "idle_limit_min": None if keep else limit,
                "source": source,
                "why": hold.get("why") if held else rule.get("why"),
                "hold_until": hold.get("until") if held else None,
                "restarts": env.get("restart_time", 0),
                "verdict": reap_verdict(
                    online, keep, ports, age_min, idle_min,
                    args.grace_min, limit, held,
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
        print(f"{'APP':22} {'STATUS':9} {'PORTS':13} {'CONN':>4} {'UNUSED':>7} {'LIMIT':>7} {'LAST USE':9} VERDICT")
        print("-" * 92)
        for r in rows:
            ports_s = ",".join(str(p) for p in r["ports"]) or "-"
            unused = f"{r['idle_h']:.1f}h" if r["status"] == "online" else "-"
            lim = r["idle_limit_min"]
            lim_s = "never" if lim is None else f"{lim / 60:.0f}h" if lim >= 60 else f"{lim:.0f}m"
            verdict = r["verdict"]
            if r["hold_until"]:
                left = (r["hold_until"] - now) / 3600.0
                verdict += f" {left:.1f}h more"
            if r["why"]:
                verdict += f" ({r['why']})"
            print(
                f"{r['name']:22} {r['status']:9} {ports_s:13} "
                f"{r['conns']:>4} {unused:>7} {lim_s:>7} {(r['source'] or '-'):9} {verdict}"
            )
    else:
        print(json.dumps(rows))

    return 0


if __name__ == "__main__":
    sys.exit(main())
