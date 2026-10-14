#!/usr/bin/env python3
"""ledger-prune: keep append-only JSONL ledgers from growing forever, without losing a line.

Old lines move into a compressed archive file and the live ledger is rebuilt
beside itself and swapped in with a rename. Nothing is truncated in place and
nothing is deleted. Which ledgers are touched, and how far back each keeps, is
declared in one file, ledger-retention.json, next to this script. A ledger that
no rule names is left alone.

It only reports unless you say `apply`. A kernel-sealed ledger (uappnd or uchg
flag) and any rule marked "protect" are never rewritten, whatever the age.

Usage:
  ledger-prune.py [plan]            dry run: what each ledger would lose (default)
  ledger-prune.py plan --json       the same, machine readable
  ledger-prune.py apply             do it (rotate to archive, then swap)
  ledger-prune.py discover          every ledger-shaped file and what covers it
Options: --config PATH, --root DIR (repeatable, default ~/.claude),
         --archive-dir DIR (default ~/.claude/ledger-archive), --now ISO (for tests)

Write order is archive first, swap second: a crash between the two leaves some
lines in both places, never in neither.
"""
import argparse
import datetime as dt
import fnmatch
import glob
import gzip
import json
import os
import stat
import subprocess
import sys
import tempfile

HOME = os.path.expanduser("~")
HERE = os.path.dirname(os.path.abspath(__file__))
DEFAULT_CONFIG = os.path.join(HERE, "ledger-retention.json")
DEFAULT_ARCHIVE = os.path.join(HOME, ".claude", "ledger-archive")
SKIP_DIRS = {"projects", "atone-snapshots", "node_modules", ".git", "worktrees", "ledger-archive", "_archive", "_archived"}
TS_KEYS = ("ts", "timestamp", "time", "at", "created_at", "received_at", "hook_ts")


def expand(p):
    return os.path.abspath(os.path.expanduser(p))


def read_ts(v):
    """A ledger timestamp as a UTC datetime, or None when it cannot be read."""
    try:
        if isinstance(v, (int, float)) and not isinstance(v, bool):
            if v > 1e11:
                v = v / 1000.0
            return dt.datetime.fromtimestamp(v, dt.timezone.utc)
        if isinstance(v, str) and v:
            t = dt.datetime.fromisoformat(v.strip().replace("Z", "+00:00"))
            if t.tzinfo is None:
                t = t.replace(tzinfo=dt.timezone.utc)
            return t.astimezone(dt.timezone.utc)
    except (ValueError, OverflowError, OSError):
        return None
    return None


def line_ts(raw):
    try:
        obj = json.loads(raw)
    except ValueError:
        return None
    if not isinstance(obj, dict):
        return None
    for k in TS_KEYS:
        if k in obj:
            return read_ts(obj[k])
    inner = obj.get("event")
    if isinstance(inner, dict) and "ts" in inner:
        return read_ts(inner["ts"])
    return None


def is_sealed(path):
    """True when the file carries a kernel append-only or immutable flag."""
    try:
        out = subprocess.run(["stat", "-f", "%Sf", path], capture_output=True, text=True, timeout=5).stdout
    except (OSError, subprocess.SubprocessError):
        return False
    return any(f in out for f in ("uappnd", "uchg", "sappnd", "schg"))


def read_policy(path):
    with open(path) as fh:
        cfg = json.load(fh)
    for r in cfg.get("rules", []):
        r["_pat"] = expand(r["path"])
    return cfg


def policy_for(cfg, path):
    for r in cfg.get("rules", []):
        if path == r["_pat"] or fnmatch.fnmatch(path, r["_pat"]):
            return r
    return None


def find_ledgers(cfg, roots):
    """Every .jsonl under the roots plus every file a rule names, deduplicated."""
    files = set()
    skip = [expand(s) for s in cfg.get("skip", [])]
    for root in roots:
        for d, dirs, names in os.walk(root):
            dirs[:] = [x for x in dirs if x not in SKIP_DIRS
                       and not any(fnmatch.fnmatch(os.path.join(d, x), s) for s in skip)]
            for f in names:
                p = os.path.join(d, f)
                if f.endswith(".jsonl") and not os.path.islink(p) and os.path.getsize(p) > 0:
                    files.add(p)
    for r in cfg.get("rules", []):
        for p in glob.glob(r["_pat"]):
            if p.endswith(".jsonl") and os.path.isfile(p) and not os.path.islink(p):
                files.add(os.path.abspath(p))
    return sorted(files)


def plan_ledger(path, rule, now):
    """What pruning would do to one ledger. Reads it once, changes nothing."""
    info = {"path": path, "rule": rule["path"] if rule else None}
    st = os.stat(path)
    info.update(size=st.st_size, mtime=st.st_mtime)
    if rule is None:
        info.update(action="untouched", reason="no rule names it")
        return info
    if rule.get("protect"):
        info.update(action="protected", reason=rule.get("why", "rule says protect"))
        return info
    if is_sealed(path):
        info.update(action="protected", reason="kernel flag (uappnd/uchg) set")
        return info
    max_age = rule.get("max_age_days")
    max_mb = rule.get("max_mb")
    cutoff = now - dt.timedelta(days=max_age) if max_age else None
    with open(path, "rb") as fh:
        lines = fh.read().splitlines(keepends=True)
    parsed = [line_ts(l) for l in lines]
    drop = [False] * len(lines)
    if cutoff is not None:
        for i, t in enumerate(parsed):
            if t is not None and t < cutoff:
                drop[i] = True
    if max_mb:
        budget = int(max_mb * 1024 * 1024)
        kept = sum(len(lines[i]) for i in range(len(lines)) if not drop[i])
        i = 0
        while kept > budget and i < len(lines):
            if not drop[i]:
                drop[i] = True
                kept -= len(lines[i])
            i += 1
    n_drop = sum(drop)
    stamps = [t for t in parsed if t is not None]
    info.update(
        lines=len(lines),
        unparsed=sum(1 for t in parsed if t is None),
        oldest=min(stamps).strftime("%Y-%m-%d") if stamps else None,
        newest=max(stamps).strftime("%Y-%m-%d") if stamps else None,
        would_archive=n_drop,
        would_archive_bytes=sum(len(lines[i]) for i in range(len(lines)) if drop[i]),
        action="rotate" if n_drop else "within-policy",
        max_age_days=max_age,
        max_mb=max_mb,
        _lines=lines,
        _drop=drop,
        _parsed=parsed,
    )
    return info


def archive_dir_for(archive_root, path):
    rel = os.path.relpath(path, HOME) if path.startswith(HOME + os.sep) else path.lstrip(os.sep)
    return os.path.join(archive_root, rel.replace(os.sep, "__"))


def rotate_ledger(info, archive_root, now):
    """Archive the dropped lines, then swap in the trimmed ledger. Returns a status string."""
    path = info["path"]
    lines, drop, parsed = info["_lines"], info["_drop"], info["_parsed"]
    base = archive_dir_for(archive_root, path)
    os.makedirs(base, exist_ok=True)
    by_month = {}
    for l, d, t in zip(lines, drop, parsed):
        if d:
            by_month.setdefault((t or now).strftime("%Y-%m"), []).append(l)
    for month, ls in by_month.items():
        with gzip.open(os.path.join(base, month + ".jsonl.gz"), "ab") as gz:
            gz.write(b"".join(ls))
    for month, ls in by_month.items():
        with gzip.open(os.path.join(base, month + ".jsonl.gz"), "rb") as gz:
            if b"".join(ls) not in gz.read():
                return "abort: archive read-back is missing lines, live ledger untouched"
    keep = b"".join(l for l, d in zip(lines, drop) if not d)
    fd, tmp = tempfile.mkstemp(prefix=".prune-", dir=os.path.dirname(path))
    try:
        with os.fdopen(fd, "wb") as fh:
            fh.write(keep)
            fh.flush()
            os.fsync(fh.fileno())
        st = os.stat(path)
        if st.st_size != info["size"] or st.st_mtime != info["mtime"]:
            os.unlink(tmp)
            return "skipped: ledger changed while pruning, archive kept, retry next run"
        os.chmod(tmp, stat.S_IMODE(st.st_mode))
        os.replace(tmp, path)
    except OSError as e:
        if os.path.exists(tmp):
            os.unlink(tmp)
        return "abort: " + str(e)
    moved = sum(drop)
    row = {"ts": now.strftime("%Y-%m-%dT%H:%M:%SZ"), "path": path, "archived_lines": moved,
           "kept_lines": len(lines) - moved, "archive": base}
    with open(os.path.join(archive_root, "_prune-log.jsonl"), "a") as fh:
        fh.write(json.dumps(row) + "\n")
    return "rotated %d lines to %s" % (moved, base)


def render_plan(infos):
    order = {"rotate": 0, "within-policy": 1, "protected": 2, "untouched": 3}
    rows = sorted(infos, key=lambda i: (order.get(i["action"], 9), -i.get("would_archive", 0)))
    out = ["%-14s %10s %9s %7s  %s" % ("action", "would-move", "lines", "MB", "ledger")]
    for i in rows:
        why = "   (" + i["reason"] + ")" if i["action"] == "protected" else ""
        out.append("%-14s %10s %9s %7.1f  %s%s" % (
            i["action"], i.get("would_archive", 0), i.get("lines", "-"),
            i["size"] / 1048576.0, i["path"].replace(HOME, "~"), why))
    total = sum(i.get("would_archive", 0) for i in infos)
    out.append("")
    out.append("lines that would move to archive: %d across %d ledgers" % (
        total, sum(1 for i in infos if i.get("would_archive"))))
    return "\n".join(out)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("cmd", nargs="?", default="plan", choices=["plan", "apply", "discover"])
    ap.add_argument("--config", default=DEFAULT_CONFIG)
    ap.add_argument("--root", action="append")
    ap.add_argument("--archive-dir", default=DEFAULT_ARCHIVE)
    ap.add_argument("--now")
    ap.add_argument("--json", action="store_true")
    a = ap.parse_args()
    cfg = read_policy(a.config)
    roots = [expand(r) for r in (a.root or [os.path.join(HOME, ".claude")])]
    now = read_ts(a.now) if a.now else dt.datetime.now(dt.timezone.utc)
    infos = [plan_ledger(p, policy_for(cfg, p), now) for p in find_ledgers(cfg, roots)]
    if a.cmd == "discover":
        for i in infos:
            print("%-14s %s" % (i["action"], i["path"]))
        return 0
    if a.cmd == "plan":
        if a.json:
            print(json.dumps([{k: v for k, v in i.items() if not k.startswith("_")} for i in infos], indent=1))
        else:
            print(render_plan(infos))
        return 0
    for i in infos:
        if i["action"] == "rotate":
            print("%s: %s" % (i["path"], rotate_ledger(i, expand(a.archive_dir), now)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
