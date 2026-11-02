#!/usr/bin/env python3
"""How much of what the paid style critic found would the free checks have found too?

Replays each finding a critic session recorded (ledger id, quoted text) through the same
free checks the watcher can run with no model. The answer decides whether the model can
leave the stop path, so it is reported per ledger entry and never as one flattering total.

    critic_recall.py [--since 2026-10-25T00:00:00] [--until 2026-11-01T14:40:00]
"""
import argparse
import collections
import glob
import json
import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.expanduser("~/.claude/projects")
PROSE_LINT = os.path.expanduser("~/.claude/scripts/style/prose-lint.py")
DETECT = os.path.expanduser("~/.claude/skills/cleanup-comments/detect.py")
WORKER = os.path.expanduser("~/.claude/scripts/style/style-watch-worker.sh")
FINDING = re.compile(r"^(thes-[\w-]+)\|([^|]*)\|", re.M)


def worker_screen():
    """The free screen the watcher runs before any judgment, read from the watcher itself."""
    with open(WORKER) as f:
        pattern = re.search(r'rg -q "([^"]+)"', f.read()).group(1)
    return re.compile(pattern.replace("\\x{2014}", "—"))


def findings(since, until):
    """Every (ledger id, quote) a critic session wrote in the window."""
    rows = []
    for path in glob.glob(ROOT + "/**/*.jsonl", recursive=True):
        with open(path, errors="replace") as handle:
            first = ""
            for raw in handle:
                if '"type":"user"' in raw:
                    first = raw
                    break
            if "You enforce a style ledger" not in first:
                continue
            handle.seek(0)
            for raw in handle:
                if '"type":"assistant"' not in raw or "thes-" not in raw:
                    continue
                try:
                    row = json.loads(raw)
                except ValueError:
                    continue
                if not since <= str(row.get("timestamp", "")) < until:
                    continue
                for part in (row.get("message") or {}).get("content") or []:
                    if isinstance(part, dict) and part.get("type") == "text":
                        rows.extend(FINDING.findall(part["text"]))
    return rows


def lint_findings(path, surface):
    r = subprocess.run([sys.executable, PROSE_LINT, "--profile", surface, path], capture_output=True, text=True, timeout=30)
    try:
        data = json.loads(r.stdout)
    except ValueError:
        return []
    return data if isinstance(data, list) else data.get("findings") or []


def free_check_hits(quote, screen):
    """Would a free check flag this quote? Returns the name of the first one that does."""
    if screen.search(quote):
        return "screen"
    with tempfile.NamedTemporaryFile("w", suffix=".md", delete=False) as f:
        f.write(quote + "\n")
    try:
        if lint_findings(f.name, "doc"):
            return "prose-lint"
    finally:
        os.unlink(f.name)
    with tempfile.NamedTemporaryFile("w", suffix=".py", delete=False) as f:
        f.write("# " + quote + "\n")
    try:
        r = subprocess.run([sys.executable, DETECT, f.name], capture_output=True, text=True, timeout=30)
        try:
            totals = json.loads(r.stdout).get("totals") or {}
        except ValueError:
            totals = {}
        if sum(v for v in totals.values() if isinstance(v, int)) > 0:
            return "detect"
    finally:
        os.unlink(f.name)
    return None


def main():
    parser = argparse.ArgumentParser(description="Replay critic findings through the free checks.")
    parser.add_argument("--since", default="2026-10-25T00:00:00")
    parser.add_argument("--until", default="2026-11-01T14:40:00")
    args = parser.parse_args()
    rows = findings(args.since, args.until)
    screen = worker_screen()
    per = collections.defaultdict(lambda: [0, 0])
    via = collections.Counter()
    missed = collections.defaultdict(list)
    for entry, quote in rows:
        per[entry][0] += 1
        hit = free_check_hits(quote.strip(), screen)
        if hit:
            per[entry][1] += 1
            via[hit] += 1
        elif len(missed[entry]) < 2:
            missed[entry].append(quote.strip()[:70])
    total = len(rows)
    caught = sum(v[1] for v in per.values())
    print("critic findings: %d, caught by free checks: %d (%.0f%%)" % (total, caught, 100 * caught / max(1, total)))
    print("caught via:", dict(via))
    for entry, (n, c) in sorted(per.items(), key=lambda kv: -kv[1][0]):
        print("%-28s %4d found, %4d caught  %s" % (entry, n, c, missed.get(entry, "")))
    return 0


if __name__ == "__main__":
    sys.exit(main())
