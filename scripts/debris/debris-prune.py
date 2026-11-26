#!/usr/bin/env python3
"""Clears old files that Claude sessions leave across this machine, so projects and
~/.claude do not fill up with checkpoints nobody will open again.

Files worth keeping go to one archive, ~/.claude/assets/checkpoints/, and /catchup can
still find them there because their pointers are rewritten. Files with no future use go
to the Trash. Nothing is removed outright, a git-tracked file is never touched, and every
action is recorded so a whole run can be undone.

Usage: debris-prune.py [--dry-run] [--list] | --undo RUN_ID
Policy, and how to change it: ~/.claude/features/debris-prune.md
"""
import argparse
import collections
import glob
import json
import os
import re
import subprocess
import sys
import time

HOME = os.path.expanduser("~")
CLAUDE = os.path.join(HOME, ".claude")
ARCHIVE = os.path.join(CLAUDE, "assets", "checkpoints")
MANIFEST = os.path.join(ARCHIVE, "manifest.jsonl")
POINTERS = os.path.join(CLAUDE, "checkpoints")
LAST_RUN = os.path.join(ARCHIVE, "last-run.txt")

CHECKPOINT_ROOTS = ("Code", ".claude", "Movies", "Documents", "Downloads", "Desktop")
DSSTORE_ROOTS = ("Code", ".claude")
SKIP_DIRS = {"node_modules", ".git", ".venv", "venv", "__pycache__", "dist", "build", ".next", "target",
             "Library", ".cache", "shell-snapshots", "file-history", "projects", "subconscious", ".Trash"}
# Places that are already archives or deliberate copies, as paths under the home folder.
KEEP_TREES = (".claude/assets/checkpoints", ".claude/assets/backups", ".claude/assets/reports", ".claude/archive",
              ".claude/backups", ".claude/skills-parked", ".claude/atone", ".claude/atone-snapshots",
              ".claude/kanban", "Code/Claude/its-my-config")
CHECKPOINT_NAME = re.compile(r"^_.*\.claude\.md$")
LATEST_LINK = "_checkpoint.claude.md"
HANDBACK = re.compile(r"^_codex-handback")
DATED = re.compile(r"^_\d{8}-")
WAL_NAME = re.compile(r"^wal(\.\w+)?\.(jsonl|lock)$")
BAK_NAME = re.compile(r".*\.(bak\d?|orig|rej)$|.*\.bak[-_.].*")

# Age in days past which each kind of file counts as stale.
DAYS = {"checkpoint": 30, "handback": 30, "wal": 60, "backup": 60, "dsstore": 30, "dead-pointer": 90, "temp": 1}


def days_old(mtime, now):
    return (now - mtime) / 86400.0


def rel(path):
    return os.path.relpath(path, HOME)


def kept_tree(path):
    r = rel(path)
    return any(r == k or r.startswith(k + "/") for k in KEEP_TREES)


def classify(name, dirpath):
    """Which kind of debris a filename is, or None when it is not debris at all."""
    if CHECKPOINT_NAME.match(name):
        if DATED.match(name) or "checkpoint" in name:
            return "checkpoint"
        # Any other _*.claude.md was named by hand and may be a living note, such as
        # a topic index, so age alone does not make it debris.
        return "handback" if HANDBACK.match(name) else None
    if WAL_NAME.match(name):
        return "wal" if os.path.basename(dirpath) == ".claude" and dirpath != CLAUDE else None
    if name == ".DS_Store":
        return "dsstore"
    # A backup is only ours inside a .claude folder; elsewhere it may be the owner's own,
    # and an .env backup holds secrets that have no business moving anywhere.
    if BAK_NAME.match(name) and not name.startswith(".env"):
        return "backup" if (os.sep + ".claude") in dirpath else None
    return None


def walk(root):
    for cur, dirs, files in os.walk(root, followlinks=False):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS and not kept_tree(os.path.join(cur, d))]
        for name in files:
            yield cur, name


def tracked_in_git(paths):
    """The subset of paths git tracks. Asked per folder, because one sweep crosses many repos."""
    by_dir = collections.defaultdict(list)
    for p in paths:
        by_dir[os.path.dirname(p)].append(os.path.basename(p))
    tracked = set()
    for d, names in by_dir.items():
        for start in range(0, len(names), 200):
            done = subprocess.run(["git", "-C", d, "ls-files", "--"] + names[start:start + 200],
                                  capture_output=True, text=True)
            if done.returncode == 0:
                tracked.update(os.path.join(d, os.path.basename(line)) for line in done.stdout.splitlines() if line)
    return tracked


def find_candidates(now):
    """Every stale file, as (kind, path). Fresh, tracked and already-archived files never appear."""
    found = []
    seen_roots = set()
    for top, kinds in ((t, None) for t in CHECKPOINT_ROOTS):
        root = os.path.join(HOME, top)
        if not os.path.isdir(root) or root in seen_roots:
            continue
        seen_roots.add(root)
        for cur, name in walk(root):
            kind = classify(name, cur)
            if kind is None or (kind == "dsstore" and top not in DSSTORE_ROOTS):
                continue
            path = os.path.join(cur, name)
            try:
                st = os.lstat(path)
            except OSError:
                continue
            if days_old(st.st_mtime, now) >= DAYS[kind]:
                found.append((kind, path, st.st_size))
    tracked = tracked_in_git([p for _k, p, _s in found if os.path.basename(p) != ".DS_Store"])
    return [row for row in found if row[1] not in tracked]


def archive_target(kind, path, now):
    month = time.strftime("%Y%m", time.localtime(os.lstat(path).st_mtime))
    slug = rel(os.path.dirname(path)).replace(os.sep, "__").lstrip("._") or "home"
    folder = os.path.join(ARCHIVE, "bak" if kind == "backup" else month, slug)
    target = os.path.join(folder, os.path.basename(path))
    n = 1
    while os.path.lexists(target):
        stem, ext = os.path.splitext(os.path.basename(path))
        target = os.path.join(folder, "%s.%d%s" % (stem, n, ext))
        n += 1
    return target


def load_pointers():
    rows = {}
    for p in glob.glob(os.path.join(POINTERS, "*.json")):
        try:
            with open(p) as f:
                rows[p] = json.load(f)
        except (OSError, ValueError):
            continue
    return rows


def atomic_write(path, text):
    tmp = "%s.%d.tmp" % (path, os.getpid())
    with open(tmp, "w") as f:
        f.write(text)
    os.replace(tmp, path)


def rewrite_paths(moved, pointers):
    """Point every checkpoint record at a file's new home. Returns how many records changed."""
    changed = 0
    for path, row in pointers.items():
        new = moved.get(row.get("checkpoint_path"))
        if new:
            row["checkpoint_path"] = new
            atomic_write(path, json.dumps(row, indent=2) + "\n")
            changed += 1
    index = os.path.join(POINTERS, "index.jsonl")
    if os.path.exists(index):
        size = os.path.getsize(index)
        lines = []
        with open(index) as f:
            for line in f:
                try:
                    row = json.loads(line)
                except ValueError:
                    lines.append(line)
                    continue
                new = moved.get(row.get("checkpoint_path"))
                if new:
                    row["checkpoint_path"] = new
                    line = json.dumps(row) + "\n"
                    changed += 1
                lines.append(line)
        # A session appending right now would lose its row to the replace. Leave the
        # index for the next run in that case: stale rows only cost a picker entry.
        if os.path.getsize(index) == size:
            atomic_write(index, "".join(lines))
    return changed


def to_trash(paths):
    """Send files to the Trash in batches. Returns the ones that made it."""
    done = []
    for start in range(0, len(paths), 100):
        batch = paths[start:start + 100]
        if subprocess.run(["/usr/bin/trash"] + batch, capture_output=True).returncode == 0:
            done += batch
        else:
            for p in batch:
                if subprocess.run(["/usr/bin/trash", p], capture_output=True).returncode == 0:
                    done.append(p)
    return done


def dead_pointers(pointers, now):
    """Records of checkpoints that no longer exist, once old enough that nobody is mid-resume."""
    dead = []
    for path, row in pointers.items():
        target = row.get("checkpoint_path")
        if target and not os.path.exists(target) and days_old(os.path.getmtime(path), now) >= DAYS["dead-pointer"]:
            dead.append(path)
    return dead


def leftover_temps(now):
    """Half-written files from a checkpoint write that was interrupted."""
    return [p for p in glob.glob(os.path.join(POINTERS, "tmp*"))
            if os.path.isfile(p) and days_old(os.path.getmtime(p), now) >= DAYS["temp"]]


def stale_links(now, candidates_dirs):
    """_checkpoint.claude.md links whose target is gone, or that are themselves stale."""
    links = []
    for d in candidates_dirs:
        p = os.path.join(d, LATEST_LINK)
        if os.path.islink(p) and (not os.path.exists(p) or days_old(os.lstat(p).st_mtime, now) >= DAYS["checkpoint"]):
            links.append(p)
    return links


def run(dry, show):
    now = time.time()
    run_id = time.strftime("%Y%m%d-%H%M%S", time.localtime(now))
    found = find_candidates(now)
    pointers = load_pointers()
    links = {p for _k, p, _s in found if os.path.basename(p) == LATEST_LINK and os.path.islink(p)}
    plan = [row for row in found if row[1] not in links]
    counts = collections.Counter()
    sizes = collections.Counter()
    for kind, _p, size in plan:
        counts[kind] += 1
        sizes[kind] += size

    temps = leftover_temps(now)
    moved, trashed, records = {}, [], []
    archive_kinds = {"checkpoint", "handback", "backup"}
    archive_rows = [r for r in plan if r[0] in archive_kinds]
    trash_rows = [r for r in plan if r[0] not in archive_kinds]

    if show:
        for kind, path, _size in sorted(plan):
            print("%-13s %s" % (kind, rel(path)))

    dead = []
    if not dry:
        os.makedirs(ARCHIVE, exist_ok=True)
        for kind, path, _size in archive_rows:
            target = archive_target(kind, path, now)
            try:
                os.makedirs(os.path.dirname(target), exist_ok=True)
                os.replace(path, target)
            except OSError as exc:
                print("could not archive %s: %s" % (rel(path), exc), file=sys.stderr)
                continue
            moved[path] = target
            records.append({"run": run_id, "action": "archive", "kind": kind, "from": path, "to": target})
        # A record may name the _checkpoint.claude.md link rather than the file behind it,
        # and that link is about to go, so send those records to the file's new home too.
        link_dirs = {os.path.dirname(p) for p in moved} | {os.path.dirname(p) for p in links}
        redirects = dict(moved)
        for d in link_dirs:
            link = os.path.join(d, LATEST_LINK)
            if os.path.islink(link) and os.path.join(d, os.readlink(link)) in moved:
                redirects[link] = moved[os.path.join(d, os.readlink(link))]
        repointed = rewrite_paths(redirects, pointers)
        for link in stale_links(now, link_dirs):
            target = os.readlink(link)
            os.unlink(link)
            records.append({"run": run_id, "action": "unlink", "kind": "latest-link", "from": link, "to": target})
        trashed = to_trash([p for _k, p, _s in trash_rows] + temps)
        dead = dead_pointers(pointers, now)
        dead_done = to_trash(dead)
        records += [{"run": run_id, "action": "trash", "from": p} for p in trashed + dead_done]
        with open(MANIFEST, "a") as f:
            for row in records:
                f.write(json.dumps(row) + "\n")
    else:
        repointed = sum(1 for row in pointers.values() if row.get("checkpoint_path") in {p for _k, p, _s in archive_rows})
        archived_set = {p for _k, p, _s in archive_rows}
        dead = [p for p in pointers
                if pointers[p].get("checkpoint_path") not in archived_set
                and not os.path.exists(pointers[p].get("checkpoint_path") or p)
                and days_old(os.path.getmtime(p), now) >= DAYS["dead-pointer"]]

    verb = "would " if dry else ""
    lines = ["%s debris-prune%s (run %s)" % (time.strftime("%Y-%m-%d %H:%M"), " dry run" if dry else "", run_id)]
    for kind in sorted(counts):
        action = "archive" if kind in archive_kinds else "trash"
        lines.append("  %s%-7s %5d %-13s %8.1f MB" % (verb, action, counts[kind], kind, sizes[kind] / 1e6))
    lines.append("  %strash   %5d dead pointers, %d leftover temp files" % (verb, len(dead), len(temps)))
    lines.append("  %srepoint %5d checkpoint records" % (verb, repointed))
    if not dry:
        lines.append("  undo with: debris-prune.py --undo %s" % run_id)
        atomic_write(LAST_RUN, "\n".join(lines) + "\n")
    print("\n".join(lines))
    return 0


def undo(run_id):
    """Put a run's archived files and links back. Files sent to the Trash stay there, for Finder's Put Back."""
    with open(MANIFEST) as f:
        rows = [json.loads(line) for line in f if line.strip()]
    rows = [r for r in rows if r.get("run") == run_id]
    if not rows:
        print("no run named %s in %s" % (run_id, MANIFEST), file=sys.stderr)
        return 1
    moved_back = {}
    for r in rows:
        if r["action"] == "archive" and os.path.exists(r["to"]) and not os.path.lexists(r["from"]):
            os.makedirs(os.path.dirname(r["from"]), exist_ok=True)
            os.replace(r["to"], r["from"])
            moved_back[r["to"]] = r["from"]
    for r in rows:
        if r["action"] == "unlink" and not os.path.lexists(r["from"]):
            os.symlink(r["to"], r["from"])
    changed = rewrite_paths(moved_back, load_pointers())
    in_trash = sum(1 for r in rows if r["action"] == "trash")
    print("restored %d files and repointed %d records; %d files stay in the Trash" % (len(moved_back), changed, in_trash))
    return 0


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--dry-run", action="store_true", help="say what would happen and change nothing")
    ap.add_argument("--list", action="store_true", help="also print every file the run would touch")
    ap.add_argument("--undo", metavar="RUN_ID", help="put back what a run archived")
    args = ap.parse_args()
    return undo(args.undo) if args.undo else run(args.dry_run, args.list)


if __name__ == "__main__":
    sys.exit(main())
