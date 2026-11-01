#!/usr/bin/env python3
"""Keep a service up for dedicated work, and set how long each may sit unused.

A hold says "this must stay up, for this reason, until then", so it always has a
reason and an end. Something that should never stop gets the keep class instead.
Both are written beside the rest of svc's state, and svc-sample.py reads them.

    svc-holds.py hold <holds.json> <name> <duration> <why> <who>
    svc-holds.py release <holds.json> <name>
    svc-holds.py policy <policy.json> <name> keep <why>
    svc-holds.py policy <policy.json> <name> idle <minutes> [why]
    svc-holds.py policy <policy.json> <name> default
"""

import json
import os
import re
import sys
import time

MAX_HOLD_S = 7 * 24 * 3600
UNITS = {"m": 60, "h": 3600, "d": 86400}


def parse_duration(text):
    """Seconds in "30m", "4h" or "2d". None when it is anything else."""
    m = re.fullmatch(r"(\d+)([mhd])", str(text).strip())
    return int(m.group(1)) * UNITS[m.group(2)] if m else None


def load(path):
    try:
        with open(path) as fh:
            return json.load(fh)
    except FileNotFoundError:
        return {}


def save(path, data):
    tmp = path + ".tmp"
    with open(tmp, "w") as fh:
        json.dump(data, fh, indent=1, sort_keys=True)
    os.replace(tmp, path)


def hold(path, name, duration, why, who, now=None):
    now = time.time() if now is None else now
    seconds = parse_duration(duration)
    if not seconds:
        return f"svc: give the hold a length such as 30m, 4h or 2d, not '{duration}'"
    if seconds > MAX_HOLD_S:
        return "svc: a hold lasts at most 7d; a service that must never stop wants: svc policy <name> keep <why>"
    if not why.strip():
        return "svc: a hold needs a reason, so whoever sees it knows whether it still matters"
    holds = load(path)
    # Drop finished holds as we go, so the file cannot grow forever.
    holds = {k: v for k, v in holds.items() if (v.get("until") or 0) > now}
    holds[name] = {"until": now + seconds, "why": why.strip(), "by": who, "at": now}
    save(path, holds)
    return None


def release(path, name):
    holds = load(path)
    holds.pop(name, None)
    save(path, holds)


def set_policy(path, name, args):
    policy = load(path)
    services = policy.setdefault("services", {})
    kind = args[0] if args else ""
    if kind == "keep":
        if len(args) < 2 or not args[1].strip():
            return "svc: keep needs a reason: svc policy <name> keep <why>"
        services[name] = {"class": "keep", "why": args[1].strip()}
    elif kind == "idle":
        if len(args) < 2 or not args[1].isdigit() or int(args[1]) < 1:
            return "svc: idle needs whole minutes: svc policy <name> idle <minutes> [why]"
        services[name] = {"class": "idle", "idle_min": int(args[1])}
        if len(args) > 2 and args[2].strip():
            services[name]["why"] = args[2].strip()
    elif kind == "default":
        services.pop(name, None)
    else:
        return "svc: usage: svc policy <name> keep <why> | idle <minutes> [why] | default"
    save(path, policy)
    return None


def main(argv):
    if len(argv) < 3:
        print(__doc__, file=sys.stderr)
        return 2
    cmd, path, name, rest = argv[0], argv[1], argv[2], argv[3:]
    if cmd == "hold":
        if len(rest) < 2:
            err = "svc: usage: svc hold <name> <duration> <why>"
        else:
            err = hold(path, name, rest[0], rest[1], rest[2] if len(rest) > 2 else "manual")
    elif cmd == "release":
        err = release(path, name)
    elif cmd == "policy":
        err = set_policy(path, name, rest)
    else:
        err = f"svc: unknown command '{cmd}'"
    if err:
        print(err, file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
