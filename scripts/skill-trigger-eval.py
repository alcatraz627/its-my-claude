#!/usr/bin/env python3
"""Does a skill's description make Claude reach for it? Measure, do not guess.

For each query you give it, runs `claude -p <query>` headless with streamed JSON
and watches for a Skill tool call naming the skill. A query marked `+` is one the
skill should catch; one marked `-` is one it should leave alone. The report is the
hit rate on each side and the misses by name, which is exactly what to edit in the
description. This is the one idea worth keeping from the official skill-creator
plugin's eval loop (its run_eval.py), rebuilt small so it reads installed skills
directly instead of writing temporary command files.

    python3 skill-trigger-eval.py <skill-name> --queries queries.txt [--model sonnet] [--timeout 90] [--cwd DIR]

queries.txt: one query per line, prefixed `+ ` (should trigger) or `- ` (should
not). Lines starting with # are comments. Each query is one `claude -p` run, so
keep the list to what you need (six to ten lines is a real eval; two is a smoke).
Costs tokens per line; say so before running it for someone.
"""
import argparse
import json
import os
import subprocess
import sys
import time
from pathlib import Path


def probe_query(query, skill, model, timeout, cwd):
    cmd = ["claude", "-p", query, "--output-format", "stream-json", "--verbose",
           "--include-partial-messages", "--max-turns", "2"]
    if model:
        cmd += ["--model", model]
    # The child must not think it is nested in this interactive session.
    env = {k: v for k, v in os.environ.items() if k != "CLAUDECODE"}
    t0 = time.time()
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout, cwd=cwd, env=env)
    except subprocess.TimeoutExpired:
        return None, time.time() - t0
    return hit_in_stream(proc.stdout.splitlines(), skill), time.time() - t0


def hit_in_stream(lines, skill):
    """True if any Skill tool_use in a stream-json transcript names this skill."""
    for line in lines:
        try:
            ev = json.loads(line)
        except json.JSONDecodeError:
            continue
        # A tool_use block may arrive as a stream event or inside the assembled
        # assistant message; either counts.
        blobs = []
        if ev.get("type") == "assistant":
            blobs = ev.get("message", {}).get("content", [])
        elif ev.get("type") == "stream_event":
            cb = ev.get("event", {}).get("content_block")
            if cb:
                blobs = [cb]
        for b in blobs:
            if b.get("type") == "tool_use" and b.get("name") in ("Skill", "skill"):
                inp = b.get("input") or {}
                if str(inp.get("skill", "")).strip("/") == skill:
                    return True
    return False
    return hit, time.time() - t0


def main(argv=None):
    ap = argparse.ArgumentParser(description="trigger eval for one skill")
    ap.add_argument("skill")
    ap.add_argument("--queries", required=True)
    ap.add_argument("--model", default=None)
    ap.add_argument("--timeout", type=int, default=90)
    ap.add_argument("--cwd", default=str(Path.home()))
    ap.add_argument("--json", action="store_true")
    a = ap.parse_args(argv)

    rows = []
    for ln in Path(a.queries).read_text(encoding="utf-8").splitlines():
        s = ln.strip()
        if not s or s.startswith("#"):
            continue
        if s[0] in "+-" and s[1:2] == " ":
            rows.append((s[0] == "+", s[2:].strip()))
        else:
            rows.append((True, s))
    if not rows:
        print("no queries", file=sys.stderr)
        return 2

    results = []
    for want, q in rows:
        hit, secs = probe_query(q, a.skill, a.model, a.timeout, a.cwd)
        results.append({"query": q, "want": want, "hit": hit, "secs": round(secs, 1)})
        if not a.json:
            mark = "?" if hit is None else ("ok " if hit == want else "MISS")
            print(f"  {mark}  {'+' if want else '-'}  {q[:80]}   ({secs:.0f}s)")

    pos = [r for r in results if r["want"]]
    neg = [r for r in results if not r["want"]]
    pos_hit = sum(1 for r in pos if r["hit"])
    neg_ok = sum(1 for r in neg if r["hit"] is False)
    summary = {"skill": a.skill, "should_trigger": f"{pos_hit}/{len(pos)}",
               "should_not": f"{neg_ok}/{len(neg)}", "timeouts": sum(1 for r in results if r["hit"] is None)}
    if a.json:
        print(json.dumps({"summary": summary, "results": results}))
    else:
        print(f"{a.skill}: triggered on {summary['should_trigger']} that should, stayed quiet on {summary['should_not']} that should not"
              + (f", {summary['timeouts']} timed out" if summary["timeouts"] else ""))
        misses = [r for r in results if r["hit"] is not None and r["hit"] != r["want"]]
        if misses:
            print("  misses name what the description must say or stop saying:")
            for r in misses:
                print(f"    {'+' if r['want'] else '-'} {r['query']}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
