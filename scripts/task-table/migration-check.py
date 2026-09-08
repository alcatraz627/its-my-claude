#!/usr/bin/env python3
"""Prove a task-store migration changed only what it meant to change.

A migration is safe when you can say, field by field, what it touched. The
check this replaces asserted row count, id set, and completed count, and all
three passed while 156 rows silently changed status and the owner's open count
collapsed from 178 to 22.

Run it with the before and after copies of a store:

    migration-check.py BEFORE_DIR AFTER_DIR --allow metadata.state,metadata.milestone

It reports every row that lost, gained, or changed a field, groups the changes
by field path so a mass rewrite shows up as one line rather than 156, and exits
non-zero when any field changed that was not listed in --allow. The digest
comparison is separate and stricter: the rendered open count must not move
unless --allow-digest-drift says so, because that number is what every agent
reads out of task-table-inject.sh.
"""

import argparse
import json
import os
import subprocess
import sys
from collections import defaultdict

HERE = os.path.dirname(os.path.abspath(__file__))


def load_store(d):
    """Every row in a store directory, keyed by id. Non-row files are skipped."""
    rows = {}
    for name in sorted(os.listdir(d)):
        if not name.endswith(".json"):
            continue
        p = os.path.join(d, name)
        try:
            with open(p) as fh:
                obj = json.load(fh)
        except (json.JSONDecodeError, OSError):
            continue
        if isinstance(obj, dict) and "id" in obj:
            rows[str(obj["id"])] = obj
    return rows


def flatten(obj, prefix=""):
    """Row to {dotted.path: value}. Lists compare whole, so order changes show."""
    out = {}
    for k, v in obj.items():
        path = f"{prefix}{k}"
        if isinstance(v, dict):
            out.update(flatten(v, path + "."))
        else:
            out[path] = json.dumps(v, sort_keys=True) if isinstance(v, list) else v
    return out


def digest(store_parent, sid):
    """The compact digest line, rendered the way the injector renders it."""
    env = dict(os.environ)
    env["HOME"] = store_parent
    try:
        r = subprocess.run(
            ["bash", os.path.join(HERE, "task-table.sh"), "--session", sid, "--compact"],
            capture_output=True, text=True, env=env, timeout=60,
        )
    except (subprocess.SubprocessError, OSError) as e:
        return f"DIGEST FAILED: {e}"
    line = (r.stdout or r.stderr).strip().splitlines()
    return line[0] if line else "DIGEST EMPTY"


def open_count(digest_line):
    """The integer the owner reads first. None when the line is not a digest."""
    parts = digest_line.split()
    if len(parts) >= 2 and parts[0] == "tasks:":
        try:
            return int(parts[1])
        except ValueError:
            return None
    return None


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("before")
    ap.add_argument("after")
    ap.add_argument("--allow", default="",
                    help="comma-separated field paths the migration is permitted to add or change")
    ap.add_argument("--allow-digest-drift", action="store_true",
                    help="permit the rendered open count to move; say why in the plan")
    ap.add_argument("--before-home", help="parent of .claude/tasks for the before copy, enables the digest check")
    ap.add_argument("--after-home", help="parent of .claude/tasks for the after copy")
    ap.add_argument("--session", help="store id (sid8) both homes hold")
    ap.add_argument("--quiet", action="store_true", help="verdict lines only")
    a = ap.parse_args()

    allowed = {x.strip() for x in a.allow.split(",") if x.strip()}
    before, after = load_store(a.before), load_store(a.after)

    problems = []

    lost = sorted(set(before) - set(after))
    gained = sorted(set(after) - set(before))
    if lost:
        problems.append(f"{len(lost)} row(s) disappeared: {', '.join(lost[:8])}")
    if gained:
        problems.append(f"{len(gained)} row(s) appeared: {', '.join(gained[:8])}")

    # Field-level, grouped by path. A mass rewrite is one line with a count and
    # a sample, because 156 identical findings hide the one that is different.
    changed = defaultdict(list)
    added = defaultdict(list)
    removed = defaultdict(list)
    for rid in sorted(set(before) & set(after), key=lambda x: (len(x), x)):
        fb, fa = flatten(before[rid]), flatten(after[rid])
        for path in sorted(set(fb) | set(fa)):
            if path not in fa:
                removed[path].append(rid)
            elif path not in fb:
                added[path].append(rid)
            elif fb[path] != fa[path]:
                changed[path].append((rid, fb[path], fa[path]))

    if not a.quiet:
        print(f"rows: {len(before)} before, {len(after)} after")
        for path in sorted(added):
            mark = "ok " if path in allowed else "NEW"
            print(f"  {mark} added   {path:<34} on {len(added[path])} row(s)")
        for path in sorted(removed):
            print(f"  DEL removed {path:<34} from {len(removed[path])} row(s)")
        for path in sorted(changed):
            mark = "ok " if path in allowed else "CHG"
            rid, was, now = changed[path][0]
            print(f"  {mark} changed {path:<34} on {len(changed[path])} row(s)"
                  f"   e.g. #{rid} [{was}] to [{now}]")

    for path in sorted(removed):
        problems.append(f"field {path} removed from {len(removed[path])} row(s)")
    for path in sorted(changed):
        if path not in allowed:
            n = len(changed[path])
            rid, was, now = changed[path][0]
            problems.append(f"field {path} changed on {n} row(s), e.g. #{rid} [{was}] to [{now}]")
    for path in sorted(added):
        if path not in allowed:
            problems.append(f"field {path} added to {len(added[path])} row(s), not in --allow")

    # The digest is the number every agent reads. It gets its own verdict because
    # a field diff can be clean while the renderer's bucketing swallows rows.
    if a.before_home and a.after_home and a.session:
        db, da = digest(a.before_home, a.session), digest(a.after_home, a.session)
        ob, oa = open_count(db), open_count(da)
        if not a.quiet:
            print(f"digest before: {db}")
            print(f"digest after : {da}")
        if ob is None or oa is None:
            problems.append("digest did not render on one side, so the count is unproven")
        elif ob != oa and not a.allow_digest_drift:
            problems.append(f"rendered open count moved from {ob} to {oa}")

    if problems:
        print(f"FAIL: {len(problems)} problem(s)")
        for p in problems:
            print(f"  - {p}")
        return 1
    print("PASS: every difference is one the migration declared")
    return 0


if __name__ == "__main__":
    sys.exit(main())
