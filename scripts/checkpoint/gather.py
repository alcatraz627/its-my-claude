#!/usr/bin/env python3
"""Collect every fact a core-dump needs in one pass, so the model copies instead of recalling.

Prints one block of `key: value` lines. Each field degrades to `unknown (why)`
on failure; gathering never stops the dump. The transcript is streamed once while
the slow lookups (goal, task store, git, ipc) run beside it.

Usage: gather.sh [--session-id SID] [--uuid UUID] [--cwd DIR]
Test seams: HOME decides where ~/.claude lives; CK_IPC_CMD replaces claude-ipc.
"""
import argparse
import glob
import json
import os
import re
import shlex
import shutil
import subprocess
import sys
import time
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import ckutil as ck  # noqa: E402

SCRIPTS = os.path.dirname(HERE)
LIGHT_MAX_PROMPTS, LIGHT_MAX_FILES = 3, 3
# Seconds after the dump file is written in which the agent's own finalize and verify calls do not count as new work.
WORK_GRACE = 120


def run(cmd, timeout, cwd=None):
    """(rc, stdout, stderr), or (None, '', reason) when the command could not run."""
    try:
        p = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout, cwd=cwd)
        return p.returncode, p.stdout, p.stderr
    except FileNotFoundError:
        return None, "", "command not found: " + cmd[0]
    except subprocess.TimeoutExpired:
        return None, "", "timed out after %ss" % timeout
    except OSError as e:
        return None, "", str(e)


def unknown(why):
    return "unknown (%s)" % re.sub(r"\s+", " ", str(why)).strip()[:160]


def resolve_uuid(arg):
    if arg:
        return arg, "--uuid"
    if os.environ.get("CLAUDE_CODE_SESSION_ID"):
        return os.environ["CLAUDE_CODE_SESSION_ID"], "CLAUDE_CODE_SESSION_ID"
    f = os.path.join(ck.claude_home(), ".current-session-id")
    try:
        v = ck.read_text(f).strip()
        if v:
            return v, ".current-session-id (a shared file, may belong to another session)"
    except OSError:
        pass
    return "", ""


def index_rows(uuid):
    """Index entries for this session uuid, oldest first."""
    f = os.path.join(ck.claude_home(), "checkpoints", "index.jsonl")
    rows = []
    try:
        with open(f, errors="replace") as fh:
            for line in fh:
                if uuid not in line:
                    continue
                try:
                    r = json.loads(line)
                except ValueError:
                    continue
                if r.get("session_uuid") == uuid:
                    rows.append(r)
    except OSError:
        pass
    return rows


def dot_claude_root(cwd):
    """Nearest directory at or above cwd that holds a .claude/ folder."""
    d = os.path.abspath(cwd)
    while True:
        if os.path.isdir(os.path.join(d, ".claude")):
            return d
        parent = os.path.dirname(d)
        if parent == d:
            return None
        d = parent


def working_surface(cwd):
    rc, out, _ = run(["git", "-C", cwd, "rev-parse", "--show-toplevel"], 5)
    if rc != 0:
        return unknown("not a git repo at %s" % cwd)
    top = out.strip()
    _, br, _ = run(["git", "-C", cwd, "branch", "--show-current"], 5)
    rc2, ab, _ = run(["git", "-C", cwd, "rev-list", "--left-right", "--count", "@{upstream}...HEAD"], 5)
    if rc2 == 0 and len(ab.split()) == 2:
        behind, ahead = ab.split()
        track = "ahead %s behind %s" % (ahead, behind)
    else:
        track = "no upstream"
    _, st, _ = run(["git", "-C", cwd, "status", "--porcelain"], 8)
    dirty = len([ln for ln in st.splitlines() if ln.strip()])
    return "%s · branch %s · %s · %d dirty files" % (top, br.strip() or "(detached)", track, dirty)


def goal_lines(uuid, cwd):
    if not uuid:
        return unknown("no session uuid"), unknown("no session uuid")
    rc, out, err = run(["bash", os.path.join(SCRIPTS, "goal", "goal.sh"), "show", "--sid", uuid, "--cwd", cwd], 15)
    if rc is None:
        return unknown(err), unknown(err)
    harness = gcc = None
    for ln in out.splitlines():
        if ln.startswith("harness /goal") and harness is None:
            harness = ln
        elif ln.startswith("gcc goal") and gcc is None:
            gcc = ln
    first = (out.strip().splitlines() or [err.strip() or "no output"])[0]
    return harness or unknown("goal.sh: " + first), gcc or "none"


def goal_record(uuid):
    f = os.path.join(ck.claude_home(), "goals", uuid + ".json")
    try:
        d = json.loads(ck.read_text(f))
    except OSError:
        return "none (no goal pointer for this session)"
    except ValueError:
        return unknown("goal pointer unreadable: " + f)
    return d.get("goal_id") or unknown("goal pointer has no goal_id")


def task_store(uuid):
    if not uuid:
        return unknown("no session uuid")
    rc, out, err = run(["bash", os.path.join(SCRIPTS, "task-table", "resolve-store.sh"), "--as-session", uuid], 30)
    if rc == 0 and out.strip():
        return out.strip()
    first = (err.strip().splitlines() or ["no output"])[0]
    return unknown("resolve-store rc=%s: %s" % (rc, first))


def wake_state(uuid):
    f = os.path.join(ck.claude_home(), ".turn-state", uuid + ".json")
    try:
        d = json.loads(ck.read_text(f))
    except OSError:
        return unknown("no turn-state file for this session")
    except ValueError:
        return unknown("turn-state file unreadable")
    w = d.get("wake")
    return json.dumps(w, separators=(",", ":")) if w else "none"


def deadline_state():
    f = os.path.join(ck.claude_home(), "skills", "deadline", "runtime-notes.md")
    try:
        for ln in ck.read_text(f).splitlines():
            if ln.startswith("## deadline"):
                return ln.strip()
    except OSError:
        return "none (no deadline runtime notes)"
    return "none"


def ipc_alias(uuid):
    cmd = shlex.split(os.environ.get("CK_IPC_CMD") or "claude-ipc") + ["peers", "--by-session"]
    rc, out, err = run(cmd, 8)
    if rc is None:
        return unknown(err)
    try:
        peers = json.loads(out).get("peers", [])
    except (ValueError, AttributeError):
        return unknown("claude-ipc peers output not JSON (rc=%s)" % rc)
    for p in peers:
        if p.get("sessionId") == uuid:
            return "%s (%s)" % (", ".join(p.get("aliases") or ["?"]), p.get("status", "?"))
    return "none (session not registered)"


def atone_ids(uuid, start, end):
    f = os.path.join(ck.claude_home(), "atone", "events.jsonl")
    if start is None:
        return unknown("no transcript start time to bound the window")
    mine, other = [], 0
    try:
        with open(f, errors="replace") as fh:
            for line in fh:
                if '"ts"' not in line:
                    continue
                try:
                    e = json.loads(line)
                except ValueError:
                    continue
                t = ck.iso_to_epoch(e.get("ts", ""))
                if t is None or t < start or t > end + 600:
                    continue
                if e.get("session_id") in (uuid, "", None):
                    mine.append("%s (%s, %s)" % (e.get("id", "?"), e.get("slug", "?"), e.get("severity", "?")))
                else:
                    other += 1
    except OSError:
        return "none (no atone event log)"
    s = ", ".join(mine) if mine else "none"
    if other:
        s += " · %d event(s) from other sessions in the same window, not listed" % other
    return s


def pending_codes(uuid):
    home = ck.claude_home()
    safe = re.sub(r"[^A-Za-z0-9._-]", "_", uuid) or "nosession"
    found = []
    nf = os.path.join(home, ".push-nonce-" + safe)
    if os.path.isfile(nf):
        try:
            d = json.loads(ck.read_text(nf))
            found.append("%s · nonce %s" % (d.get("target") or "git push", d.get("nonce", "?")))
        except ValueError:
            found.append(unknown("push nonce file unreadable"))
    if os.path.isfile(os.path.join(home, ".push-approved-" + safe)):
        found.append("git push · approved by the owner, not yet used")
    for pf in sorted(glob.glob(os.path.join(home, ".policy-ask", safe + "--*.nonce"))):
        try:
            d = json.loads(ck.read_text(pf))
        except (OSError, ValueError):
            continue
        key = d.get("key") or os.path.basename(pf)[len(safe) + 2:-len(".nonce")]
        approved = os.path.isfile(pf[:-len(".nonce")] + ".approved")
        found.append("%s (policy %s) · nonce %s%s" % (d.get("what") or key, key, d.get("nonce", "?"),
                                                      " · approved, not yet used" if approved else ""))
    return "; ".join(found) if found else "none"


def previous_same_stem(root, sid, default_file, uuid):
    """(path, note): the last dump with this session's name stem, never the newest of any stem."""
    pat = re.compile(r"^_\d{8}-" + re.escape(sid) + r"\.claude\.md$")
    cands = [p for p in glob.glob(os.path.join(root, "_*.claude.md")) if pat.match(os.path.basename(p))]
    if not cands:
        return "none", ""
    newest = max(cands, key=os.path.getmtime)
    if os.path.abspath(newest) != os.path.abspath(default_file):
        return newest, ""
    # Today's file is about to be overwritten by the Write, so keep a copy to diff against.
    snap = ck.prev_snapshot(uuid, sid)
    os.makedirs(os.path.dirname(snap), exist_ok=True)
    shutil.copyfile(newest, snap)
    return snap, "the path above is a copy of today's %s, which the Write will overwrite" % newest


def existing_dump(uuid, scan):
    if not uuid or scan is None:
        return unknown("needs the session uuid and its transcript")
    cands = [r.get("checkpoint_path") for r in index_rows(uuid) if r.get("kind", "core-dump") == "core-dump"]
    cands.extend(scan["dumps"])
    cands = [c for c in cands if c and os.path.isfile(c)]
    if not cands:
        return "none"
    best = max(cands, key=os.path.getmtime)
    mt = os.path.getmtime(best)
    turns = [t for t, txt in scan["owner"] if not ck.is_handoff_command(txt) and t is not None]
    last_owner = max(turns) if turns else 0
    if mt >= last_owner:
        if any(t > mt + WORK_GRACE for t in scan["work"]):
            return "none (agent work since the dump)"
        stamp = datetime.fromtimestamp(mt, timezone.utc).strftime("%Y-%m-%dT%H:%MZ")
        return "%s · no owner turn since (written %s)" % (best, stamp)
    return "none"


def collect(fut, fallback):
    try:
        return fut.result()
    except Exception as e:  # a field must never stop the dump
        return fallback(unknown("lookup failed: %s" % e))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--session-id")
    ap.add_argument("--uuid")
    ap.add_argument("--cwd")
    a = ap.parse_args()
    t0 = time.monotonic()

    cwd = os.path.abspath(a.cwd or os.getcwd())
    uuid, uuid_src = resolve_uuid(a.uuid)
    sid, sid_src = a.session_id, "--session-id"
    if not sid:
        rows = index_rows(uuid) if uuid else []
        sid = rows[-1].get("session_id") if rows else None
        sid_src = "the checkpoint index entry for this uuid"
        if not sid and uuid:
            sid, sid_src = uuid[:8], "first 8 of the uuid (no name given, none indexed)"
    sid = sid or "unknown"
    root = dot_claude_root(cwd)
    root_note = "" if root else " (no .claude/ above cwd; using cwd)"
    root = root or cwd
    default_file = os.path.join(root, "_%s-%s.claude.md" % (datetime.now().strftime("%Y%m%d"), sid))
    tpath = ck.session_transcript_path(uuid, cwd)

    scan = scan_err = None
    with ThreadPoolExecutor(max_workers=4) as pool:
        f_surface = pool.submit(working_surface, cwd)
        f_goal = pool.submit(goal_lines, uuid, cwd)
        f_store = pool.submit(task_store, uuid)
        f_ipc = pool.submit(ipc_alias, uuid) if uuid else None
        if tpath:
            try:
                scan = ck.scan_transcript(tpath)
            except Exception as e:
                scan_err = "transcript unreadable: %s" % e
        surface = collect(f_surface, lambda s: s)
        harness, gcc = collect(f_goal, lambda s: (s, s))
        store = collect(f_store, lambda s: s)
        ipc = collect(f_ipc, lambda s: s) if f_ipc else unknown("no session uuid")

    lines = []

    def put(k, v):
        """Add a field; a callable is evaluated here so one bad lookup costs one field, not the block."""
        try:
            v = v() if callable(v) else v
        except Exception as e:
            v = unknown("%s failed: %s: %s" % (k, type(e).__name__, e))
        lines.append("%s: %s" % (k, v))

    put("session_id", "%s (from %s)" % (sid, sid_src))
    put("uuid", "%s (from %s)" % (uuid, uuid_src) if uuid
        else unknown("no --uuid, no CLAUDE_CODE_SESSION_ID, no .current-session-id"))
    put("now", datetime.now().astimezone().strftime("%a %b %d %Y, %I:%M %p %Z"))
    put("project_root", root + root_note)
    put("working_surface", surface)
    put("default_file", default_file)
    put("transcript", tpath or unknown("no transcript for %s under ~/.claude/projects/" % (uuid or "?")))

    if scan:
        prompts = [x for t, x in scan["owner"] if not ck.is_handoff_command(x)]
        n_files = len(scan["files"])
        depth = "light" if len(prompts) <= LIGHT_MAX_PROMPTS and n_files <= LIGHT_MAX_FILES else "full"
        put("session_size", "%d owner prompts · %d assistant turns · %d files written or edited · depth %s"
            % (len(prompts), scan["assistant_msgs"], n_files, depth))
        put("depth_hint", depth)
        shown = ", ".join(scan["files"][:25]) + (" … +%d more" % (n_files - 25) if n_files > 25 else "")
        put("files_touched", shown or "none")
    else:
        why = scan_err or "no transcript"
        for k in ("session_size", "depth_hint", "files_touched"):
            put(k, unknown(why))

    put("existing_dump", lambda: existing_dump(uuid, scan))
    try:
        prev_path, prev_note = previous_same_stem(root, sid, default_file, uuid)
    except Exception as e:
        prev_path, prev_note = unknown("previous_dump_same_stem failed: %s: %s" % (type(e).__name__, e)), ""
    put("previous_dump_same_stem", prev_path)
    if prev_note:
        put("previous_dump_note", prev_note)
    put("goal_harness", harness)
    put("goal_gcc", gcc)
    put("goal_record", (lambda: goal_record(uuid)) if uuid else unknown("no session uuid"))
    put("task_store", store)
    put("wake", (lambda: wake_state(uuid)) if uuid else unknown("no session uuid"))
    put("deadline", deadline_state)
    put("ipc_alias", ipc)
    put("atone_ids", lambda: atone_ids(uuid, scan["first_ts"] if scan else None, scan["last_ts"] if scan else 0))
    put("pending_codes", (lambda: pending_codes(uuid)) if uuid else unknown("no session uuid"))
    put("gather_seconds", "%.1f" % (time.monotonic() - t0))
    print("\n".join(lines))


if __name__ == "__main__":
    try:
        main()
    except SystemExit:
        raise
    except Exception as e:  # last resort: gathering never fails the dump
        print("gather: unknown (%s)" % e)
