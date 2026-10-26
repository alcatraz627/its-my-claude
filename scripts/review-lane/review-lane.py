#!/usr/bin/env python3
"""Picks who reviews a change: codex first, then gemini-4-argon, then a Claude
sonnet seat, with opus when the work demands it (owner, 2026-10-24). Each outside
lane is probed with a one-word call before a seat is spent on it, so a lane that
is down, capped or refusing its model falls through instead of burning a dispatch.

  review-lane.py pick [--need opus] [--fresh]   print the first usable lane and how to run it
  review-lane.py probe [--fresh]                probe every lane, print each verdict
  review-lane.py ab                             two lanes to run on the same diff, to compare
  review-lane.py lead [<lane> | --reset]        put one lane first for now; --reset restores the default order
  review-lane.py record --lane L --change REF --found N --confirmed N --false-positive N [--note T]
  review-lane.py report [--days N]              findings per lane: found, confirmed, false positives

Probe results are cached for 30 minutes in /tmp/review-lane-probe.json.
Telemetry: ~/.claude/review-lane/telemetry.jsonl (gitignored: it names private repos).
"""
import argparse
import datetime as dt
import json
import os
import re
import subprocess
import sys
import time

HOME = os.path.expanduser("~")
CACHE = "/tmp/review-lane-probe.json"
TTL = 1800
TELEMETRY = os.path.join(HOME, ".claude", "review-lane", "telemetry.jsonl")
CODEX_CONFIG = os.path.join(HOME, ".codex", "config.toml")
# A temporary "this lane goes first" preference, kept out of the code so it is
# one command to set and one to undo.
LEAD = os.path.join(HOME, ".claude", "review-lane", "lead.json")
PROBE = "Reply with the single word OK and nothing else."


def codex_model():
    try:
        m = re.search(r'^model\s*=\s*"([^"]+)"', open(CODEX_CONFIG).read(), re.M)
        return m.group(1) if m else None
    except OSError:
        return None


def run(argv, timeout):
    try:
        p = subprocess.run(argv, capture_output=True, text=True, timeout=timeout, stdin=subprocess.DEVNULL)
        return p.returncode, (p.stdout or "") + (p.stderr or "")
    except FileNotFoundError:
        return 127, f"{argv[0]} is not installed"
    except subprocess.TimeoutExpired:
        return 124, f"no answer in {timeout}s"


def why(out):
    """The one line of a failed probe that says what went wrong."""
    for line in out.splitlines()[::-1]:
        if re.search(r"error|unsupported|not supported|limit|quota|refused|denied|not installed|no answer|429|401|403", line, re.I):
            return line.strip()[:200]
    return (out.strip().splitlines() or ["no output"])[-1][:200]


def probe_codex():
    model = codex_model()
    argv = ["codex", "exec", "--ephemeral", "--skip-git-repo-check", "-s", "read-only", "--color", "never"]
    if model:
        argv += ["-m", model]
    rc, out = run(argv + [PROBE], 90)
    ok = rc == 0 and re.search(r"\bOK\b", out) is not None
    return {"ok": ok, "detail": f"model {model or 'default'}" if ok else why(out)}


def probe_gemini():
    rc, out = run(["lm", "gemini", "-m", "gemini-4-argon", PROBE], 90)
    ok = rc == 0 and re.search(r"\bOK\b", out) is not None
    return {"ok": ok, "detail": "gemini-4-argon" if ok else why(out)}


LANES = [
    ("codex", probe_codex,
     "codex seat: Agent subagent_type codex:codex-rescue, then /codex-handback to review its work"),
    ("gemini-4-argon", probe_gemini,
     "lm gemini -m gemini-4-argon with the diff on stdin; untrusted output, sample-check every finding"),
    ("sonnet", None, "Claude seat: Agent model sonnet, built with /subagent (shape review)"),
    ("opus", None, "Claude seat: Agent model opus, effort medium, built with /subagent (shape review)"),
]


def probes(fresh):
    cache = {}
    if not fresh:
        try:
            cache = json.load(open(CACHE))
        except (OSError, ValueError):
            cache = {}
    now = time.time()
    out = {}
    for name, fn, _ in LANES:
        if fn is None:
            out[name] = {"ok": True, "detail": "always available", "at": now}
            continue
        c = cache.get(name)
        if c and now - c.get("at", 0) < TTL:
            out[name] = c
            continue
        r = fn()
        r["at"] = now
        out[name] = r
    try:
        json.dump(out, open(CACHE, "w"))
    except OSError:
        pass
    return out


def read_lead():
    try:
        return json.load(open(LEAD)).get("lead")
    except (OSError, ValueError):
        return None


def cmd_lead(a):
    if a.reset:
        try:
            os.remove(LEAD)
        except FileNotFoundError:
            pass
        print("lead reset: the default order applies (" + ", ".join(n for n, _, _ in LANES if n != "opus") + ")")
        return 0
    if not a.lane:
        cur = read_lead()
        print(f"lead: {cur}" if cur else "no lead set: the default order applies")
        return 0
    os.makedirs(os.path.dirname(LEAD), exist_ok=True)
    json.dump({"lead": a.lane, "set": dt.datetime.now().isoformat(timespec="seconds"), "note": a.note or ""},
              open(LEAD, "w"))
    print(f"lead: {a.lane} goes first until `review-lane.py lead --reset`")
    return 0


def cmd_pick(a):
    res = probes(a.fresh)
    order = [n for n, _, _ in LANES if n != "opus"]
    lead = read_lead()
    if lead and lead in order:
        order = [lead] + [n for n in order if n != lead]
        # The lead is a temporary preference, so say when the default leader is back.
        default = LANES[0][0]
        if lead != default and res[default]["ok"]:
            print(f"note: {default} is answering again; `review-lane.py lead --reset` puts it back first")
    if a.need == "opus":
        order = ["opus"]
    for name in order:
        if res[name]["ok"]:
            how = dict((n, h) for n, _, h in LANES)[name]
            print(f"lane: {name}\nhow: {how}")
            skipped = [f"{n} ({res[n]['detail']})" for n in order[:order.index(name)]]
            if skipped:
                print("skipped: " + "; ".join(skipped))
            return 0
    print("no lane available", file=sys.stderr)
    return 1


def cmd_probe(a):
    for name, r in probes(a.fresh).items():
        print(f"{'ok  ' if r['ok'] else 'DOWN'} {name:16} {r['detail']}")
    return 0


def cmd_ab(a):
    res = probes(False)
    up = [n for n, _, _ in LANES if res[n]["ok"] and n != "opus"]
    if len(up) < 2:
        up = up + ["opus"]
    print(f"A: {up[0]}\nB: {up[1]}\nRun both on the same diff, then record each with: review-lane.py record --lane <L> ...")
    return 0


def cmd_record(a):
    os.makedirs(os.path.dirname(TELEMETRY), exist_ok=True)
    row = {"ts": dt.datetime.now().isoformat(timespec="seconds"), "lane": a.lane, "change": a.change,
           "found": a.found, "confirmed": a.confirmed, "false_positive": a.false_positive, "note": a.note or ""}
    with open(TELEMETRY, "a") as f:
        f.write(json.dumps(row) + "\n")
    print(f"recorded {a.lane} on {a.change}")
    return 0


def cmd_report(a):
    cut = (dt.datetime.now() - dt.timedelta(days=a.days)).isoformat()
    agg = {}
    try:
        for line in open(TELEMETRY):
            r = json.loads(line)
            if r.get("ts", "") < cut:
                continue
            g = agg.setdefault(r["lane"], {"reviews": 0, "found": 0, "confirmed": 0, "false_positive": 0})
            g["reviews"] += 1
            for k in ("found", "confirmed", "false_positive"):
                g[k] += int(r.get(k) or 0)
    except (OSError, ValueError):
        pass
    if not agg:
        print(f"no reviews recorded in the last {a.days} days")
        return 0
    print(f"{'lane':16} reviews  found  confirmed  false+  precision")
    for lane, g in sorted(agg.items()):
        prec = f"{100 * g['confirmed'] / g['found']:.0f}%" if g["found"] else "-"
        print(f"{lane:16} {g['reviews']:7}  {g['found']:5}  {g['confirmed']:9}  {g['false_positive']:6}  {prec:>9}")
    return 0


def main(argv):
    p = argparse.ArgumentParser(prog="review-lane", description=__doc__.split("\n\n")[0])
    sub = p.add_subparsers(dest="cmd", required=True)
    pk = sub.add_parser("pick"); pk.add_argument("--need", choices=["opus"]); pk.add_argument("--fresh", action="store_true")
    pr = sub.add_parser("probe"); pr.add_argument("--fresh", action="store_true")
    sub.add_parser("ab")
    ld = sub.add_parser("lead"); ld.add_argument("lane", nargs="?", choices=[n for n, _, _ in LANES if n != "opus"])
    ld.add_argument("--reset", action="store_true"); ld.add_argument("--note")
    rc = sub.add_parser("record")
    rc.add_argument("--lane", required=True, choices=[n for n, _, _ in LANES]); rc.add_argument("--change", required=True)
    for k in ("--found", "--confirmed", "--false-positive"):
        rc.add_argument(k, type=int, required=True)
    rc.add_argument("--note")
    rp = sub.add_parser("report"); rp.add_argument("--days", type=int, default=30)
    a = p.parse_args(argv)
    return {"pick": cmd_pick, "probe": cmd_probe, "ab": cmd_ab, "record": cmd_record, "report": cmd_report,
            "lead": cmd_lead}[a.cmd](a)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
