#!/usr/bin/env python3
"""zrecover sessions: everything needed to pick a Claude session back up.

Three jobs, all read-only against Claude's own files. `transcript_tail` pulls
the last prompt and reply out of a session transcript without reading the
whole file. `sessions_before_crash` works out which sessions were open before
a crash when zrecover was not yet running, from transcript mtimes and the IPC
registry. `write_bundle` writes the periodic resume bundle: one markdown file
with every live session's resume command, cwd, git state, last exchange,
checkpoint and screen capture. The daemon calls it every bundle_every_s.
"""
import json, os, re, shlex, subprocess, time

HOME = os.path.expanduser("~")
PROJECTS = os.path.join(HOME, ".claude", "projects")
CHECKPOINTS = os.path.join(HOME, ".claude", "checkpoints")
TASKS = os.path.join(HOME, ".claude", "tasks")
ROOT = os.path.join(HOME, ".claude", "zrecover")
BUNDLES = os.path.join(ROOT, "bundles")
TAIL_BYTES = 1024 * 1024   # a long tool-heavy turn can push the last prompt past 256 KB
SWEEP_MAX_BYTES = 600 * 1024   # the automated per-file sweeps all land near 430 KB with no tty


def project_dir(cwd):
    return os.path.join(PROJECTS, cwd.replace("/", "-"))


def transcript_path(cwd, session_id):
    if not cwd or not session_id:
        return None
    p = os.path.join(project_dir(cwd), f"{session_id}.jsonl")
    return p if os.path.exists(p) else None


def _text_of(content):
    """A message's human-readable text; tool results and command noise dropped."""
    if isinstance(content, str):
        s = content
    elif isinstance(content, list):
        s = "\n".join(b.get("text", "") for b in content if isinstance(b, dict) and b.get("type") == "text")
    else:
        return ""
    s = s.strip()
    if re.match(r"<(local-command|command-|system-reminder|bash-input|bash-stdout)", s):
        return ""
    return s


def transcript_tail(path, max_bytes=TAIL_BYTES):
    """Last user prompt and assistant reply (text only), plus activity figures."""
    out = {"path": path, "mtime": None, "bytes": None, "last_user": None, "last_user_ts": None,
           "last_assistant": None, "last_assistant_ts": None, "turns_in_tail": 0}
    try:
        st = os.stat(path)
    except OSError:
        return out
    out["mtime"], out["bytes"] = st.st_mtime, st.st_size
    with open(path, "rb") as f:
        if st.st_size > max_bytes:
            f.seek(st.st_size - max_bytes)
            f.readline()   # drop the partial line
        chunk = f.read().decode("utf-8", "replace")
    for ln in chunk.splitlines():
        try:
            rec = json.loads(ln)
        except ValueError:
            continue
        t = rec.get("type")
        if t not in ("user", "assistant") or rec.get("isSidechain"):
            continue
        txt = _text_of((rec.get("message") or {}).get("content"))
        if not txt:
            continue
        if t == "user":
            out["turns_in_tail"] += 1
            out["last_user"], out["last_user_ts"] = txt, rec.get("timestamp")
        else:
            out["last_assistant"], out["last_assistant_ts"] = txt, rec.get("timestamp")
    return out


def excerpt(s, n=220):
    if not s:
        return ""
    s = " ".join(s.split())
    return s if len(s) <= n else s[: n - 1] + "…"


def _git(cwd, *args, timeout=5):
    try:
        return subprocess.run(["git", "-C", cwd, *args], capture_output=True, text=True, timeout=timeout).stdout
    except (OSError, subprocess.TimeoutExpired):
        return None


def git_state(cwd):
    if not cwd or (_git(cwd, "rev-parse", "--is-inside-work-tree", timeout=3) or "").strip() != "true":
        return None
    br = (_git(cwd, "rev-parse", "--abbrev-ref", "HEAD", timeout=3) or "").strip()
    dirty = _git(cwd, "status", "--porcelain") or ""
    return {"branch": br, "dirty": len([ln for ln in dirty.splitlines() if ln.strip()])}


def checkpoint_for(session_id):
    try:
        with open(os.path.join(CHECKPOINTS, f"{session_id}.json")) as f:
            c = json.load(f)
        return {"path": c.get("checkpoint_path"), "name": c.get("name"), "ts": c.get("ts"), "kind": c.get("kind")}
    except (OSError, ValueError):
        return None


def tasks_for(session_id):
    d = os.path.join(TASKS, f"session-{session_id[:8]}")
    if not os.path.isdir(d):
        return None
    return {"store": d, "rows": len([x for x in os.listdir(d) if x.endswith(".json")])}


def resume_command(cwd, session_id):
    resume = f" --resume {session_id}" if session_id else ""
    return f"cd {shlex.quote(cwd or '~')} && zrecover run claude{resume}"


def find_transcript(session_id):
    try:
        for d in os.listdir(PROJECTS):
            p = os.path.join(PROJECTS, d, f"{session_id}.jsonl")
            if os.path.exists(p):
                return p
    except OSError:
        pass
    return None


def cwd_from_project_dir(d):
    """Best-effort inverse of project_dir: the slug loses the / vs - distinction,
    so walk the filesystem choosing the longest existing prefix at each step."""
    parts = os.path.basename(d).lstrip("-").split("-")
    path, i = "/", 0
    while i < len(parts):
        hit = None
        for j in range(len(parts), i, -1):
            cand = os.path.join(path, "-".join(parts[i:j]))
            if os.path.isdir(cand):
                hit, i = cand, j
                break
        if not hit:
            return None
        path = hit
    return path


def enrich(row):
    """Add transcript tail, git, checkpoint and tasks to a session row (in place)."""
    sid, cwd = row.get("session_id"), row.get("cwd")
    tp = transcript_path(cwd, sid) if cwd and cwd != "/" else None
    if not tp and sid:
        tp = find_transcript(sid)
        if tp and (not cwd or cwd == "/"):
            row["cwd"] = cwd = cwd_from_project_dir(os.path.dirname(tp))
    row["transcript"] = transcript_tail(tp) if tp else None
    row["git"] = git_state(cwd) if cwd and cwd != "/" else None
    row["checkpoint"] = checkpoint_for(sid) if sid else None
    row["tasks"] = tasks_for(sid) if sid else None
    row["resume"] = resume_command(cwd, sid)
    return row


# crash reconstruction
def sessions_before_crash(before_ts, hours=12.0, ipc_rows=None, exclude_sids=()):
    """Sessions that were probably open at before_ts: interactive-sized transcripts
    written in the preceding window, joined to IPC aliases, minus any excluded."""
    lo = before_ts - hours * 3600
    rows = []
    try:
        dirs = os.listdir(PROJECTS)
    except OSError:
        return rows
    by_sid = {r["session_id"]: r for r in (ipc_rows or {}).values() if r.get("session_id")}
    for d in dirs:
        pd = os.path.join(PROJECTS, d)
        try:
            names = os.listdir(pd)
        except OSError:
            continue
        for n in names:
            if not n.endswith(".jsonl"):
                continue
            p = os.path.join(pd, n)
            try:
                st = os.stat(p)
            except OSError:
                continue
            if not (lo <= st.st_mtime <= before_ts + 60):
                continue
            sid = n[:-6]
            if sid in exclude_sids:
                continue
            ipc = by_sid.get(sid, {})
            if not (ipc.get("tty") or st.st_size > SWEEP_MAX_BYTES):
                continue
            cwd = ipc.get("cwd") if ipc.get("cwd") not in (None, "/") else cwd_from_project_dir(pd)
            rows.append(enrich({"session_id": sid, "alias": ipc.get("alias"), "cwd": cwd, "tty": ipc.get("tty"),
                                "last_activity": st.st_mtime, "transcript_bytes": st.st_size, "reconstructed": True}))
    rows.sort(key=lambda r: -r["last_activity"])
    return rows


def latest_panic_ts():
    """When the kernel last panicked, from the newest panic report; None if none."""
    try:
        names = [n for n in os.listdir("/Library/Logs/DiagnosticReports") if n.startswith("panic")]
    except OSError:
        return None
    best = None
    for n in names:
        m = re.search(r"(\d{4})-(\d{2})-(\d{2})-(\d{2})(\d{2})(\d{2})", n)
        if m:
            ts = time.mktime(time.strptime("".join(m.groups()), "%Y%m%d%H%M%S"))
            best = max(best or 0, ts)
    return best


# the resume bundle
def write_bundle(sessions, boot, keep_days=14):
    """One markdown + json pair under bundles/, plus latest.md. Returns the md path."""
    os.makedirs(BUNDLES, exist_ok=True)
    now = time.time()
    rows = [enrich(dict(s)) for s in sessions]
    stamp = time.strftime("%Y%m%d-%H%M", time.localtime(now))
    md, js = os.path.join(BUNDLES, f"{stamp}.md"), os.path.join(BUNDLES, f"{stamp}.json")
    with open(js + ".tmp", "w") as f:
        json.dump({"ts": now, "boot": boot, "sessions": rows}, f, indent=1)
    os.replace(js + ".tmp", js)
    with open(md + ".tmp", "w") as f:
        f.write(render_bundle(rows, now, boot))
    os.replace(md + ".tmp", md)
    latest, tmp = os.path.join(BUNDLES, "latest.md"), os.path.join(BUNDLES, "latest.md.tmp")
    if os.path.lexists(tmp):
        os.remove(tmp)
    os.symlink(os.path.basename(md), tmp)
    os.replace(tmp, latest)
    cutoff = now - keep_days * 86400
    for n in os.listdir(BUNDLES):
        p = os.path.join(BUNDLES, n)
        if n != "latest.md" and os.path.isfile(p) and os.stat(p).st_mtime < cutoff:
            os.remove(p)
    return md


def render_bundle(rows, ts, boot):
    out = [f"# zrecover resume bundle · {time.strftime('%Y-%m-%d %H:%M', time.localtime(ts))}",
           f"boot {time.strftime('%Y-%m-%d %H:%M', time.localtime(boot))} · {len(rows)} live session(s) · "
           f"`zrecover restore` replays the newest bundle from before the current boot", ""]
    for i, s in enumerate(rows, 1):
        out += [f"## {i}. {s.get('alias') or (s.get('session_id') or '?')[:8]}", "", f"    {s.get('resume')}", ""]
        out.append(f"- cwd: `{s.get('cwd') or '?'}`" + (f" · tty {s['tty']}" if s.get("tty") else ""))
        if s.get("git"):
            out.append(f"- git: `{s['git']['branch']}`, {s['git']['dirty']} uncommitted file(s)")
        t = s.get("transcript") or {}
        if t.get("mtime"):
            out.append(f"- last activity: {time.strftime('%Y-%m-%d %H:%M', time.localtime(t['mtime']))} "
                       f"({(t['bytes'] or 0) // 1024} KB transcript)")
        if t.get("last_user"):
            out.append(f"- last prompt: {excerpt(t['last_user'], 300)}")
        if t.get("last_assistant"):
            out.append(f"- last reply: {excerpt(t['last_assistant'], 300)}")
        if s.get("checkpoint") and s["checkpoint"].get("path"):
            out.append(f"- checkpoint: `{s['checkpoint']['path']}` ({s['checkpoint'].get('kind')}, {s['checkpoint'].get('ts')})")
        if s.get("tasks"):
            out.append(f"- tasks: {s['tasks']['rows']} row(s) in `{s['tasks']['store']}`")
        if s.get("screen") and os.path.exists(s["screen"]):
            out += [f"- screen: `{s['screen']}`", "", "  ```"] + ["  " + ln for ln in screen_tail(s["screen"])] + ["  ```"]
        out.append("")
    if not rows:
        out.append("_no interactive claude sessions were running_")
    return "\n".join(out) + "\n"


def screen_tail(path, lines=14):
    try:
        with open(path) as f:
            body = [ln.rstrip("\n") for ln in f if not ln.startswith("# ")]
    except OSError:
        return []
    while body and not body[-1].strip():
        body.pop()
    return body[-lines:]


def list_bundles():
    try:
        names = sorted(n for n in os.listdir(BUNDLES) if n.endswith(".json"))
    except OSError:
        return []
    out = []
    for n in names:
        p = os.path.join(BUNDLES, n)
        try:
            with open(p) as f:
                b = json.load(f)
            out.append({"path": p, "md": p[:-5] + ".md", "ts": b["ts"], "boot": b["boot"], "count": len(b["sessions"])})
        except (OSError, ValueError, KeyError):
            pass
    return out


def last_bundle_before_boot(boot):
    cands = [b for b in list_bundles() if b["boot"] != boot and b["ts"] < boot]
    return cands[-1] if cands else None
