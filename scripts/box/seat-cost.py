#!/usr/bin/env python3
"""What a subagent cost, or what one is likely to cost before it runs.

The fleet boxes show money rather than reminders (owner, 2026-10-28). A landed
seat is priced from its own transcript; a seat about to be dispatched is priced
at the median of recent seats on the same model, measured from the transcripts
on this machine rather than guessed.

Usage:
  seat-cost.py cost <agent-transcript.jsonl>   dollars, e.g. 0.31 (empty when unpriced)
  seat-cost.py estimate <model alias or id>    median dollars of recent seats on it
Rates come from usage-stats.py, the one price table in the gcc.
"""
import glob
import importlib.util
import json
import os
import statistics
import sys
import time

HERE = os.path.dirname(os.path.realpath(__file__))
STATS = os.path.join(HERE, "..", "usage-stats.py")
PROJECTS = os.path.expanduser("~/.claude/projects")
CACHE = os.environ.get("SEAT_COST_CACHE", "/tmp/claude-seat-cost-estimates.json")
CACHE_TTL = 6 * 3600
SAMPLE = 150
FAMILIES = ("fable", "opus", "sonnet", "haiku")


def rates_module():
    spec = importlib.util.spec_from_file_location("usage_stats", STATS)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def transcript_cost(path, us):
    """(dollars, model) for one seat; dollars is None when its model is unpriced."""
    seen, total, model, priced = set(), 0.0, "", True
    try:
        with open(path, errors="replace") as f:
            for line in f:
                if '"usage"' not in line:
                    continue
                try:
                    msg = json.loads(line).get("message") or {}
                except ValueError:
                    continue
                u = msg.get("usage")
                mid = msg.get("id")
                if not u or mid in seen:
                    continue
                seen.add(mid)
                model = msg.get("model") or model
                r = us.rate_for(model or "", True)
                if r is None:
                    priced = False
                    continue
                cc = u.get("cache_creation") or {}
                c5 = cc.get("ephemeral_5m_input_tokens", 0) if cc else 0
                c1 = cc.get("ephemeral_1h_input_tokens", 0) if cc else u.get("cache_creation_input_tokens", 0)
                total += us.turn_cost((u.get("input_tokens", 0), u.get("output_tokens", 0),
                                       u.get("cache_read_input_tokens", 0), c5, c1), r)
    except OSError:
        return None, model
    return (total if priced or total else None), model


def family(name):
    n = (name or "").lower()
    return next((f for f in FAMILIES if f in n), "")


def estimates(us):
    try:
        if time.time() - os.path.getmtime(CACHE) < CACHE_TTL:
            with open(CACHE) as f:
                return json.load(f)
    except (OSError, ValueError):
        pass
    files = glob.glob(os.path.join(PROJECTS, "*", "*", "subagents", "agent-*.jsonl"))
    files = sorted(files, key=lambda p: os.path.getmtime(p), reverse=True)[:SAMPLE]
    by = {}
    for p in files:
        d, m = transcript_cost(p, us)
        if d:
            by.setdefault(family(m), []).append(d)
    out = {k: round(statistics.median(v), 2) for k, v in by.items() if k and len(v) >= 3}
    try:
        with open(CACHE, "w") as f:
            json.dump(out, f)
    except OSError:
        pass
    return out


def main():
    if len(sys.argv) != 3 or sys.argv[1] not in ("cost", "estimate"):
        print(__doc__.strip(), file=sys.stderr)
        return 2
    us = rates_module()
    if sys.argv[1] == "cost":
        d, _ = transcript_cost(sys.argv[2], us)
        print("" if d is None else "%.2f" % d)
    else:
        v = estimates(us).get(family(sys.argv[2]))
        print("" if v is None else "%.2f" % v)
    return 0


if __name__ == "__main__":
    sys.exit(main())
