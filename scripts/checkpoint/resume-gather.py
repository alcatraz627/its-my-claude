#!/usr/bin/env python3
"""Gathers the facts /catchup needs before it briefs the owner.

A resume used to cost a dozen tool calls: find the checkpoint, validate it,
compare it with git, peek at mail, list background jobs, read the goal. This
does all of it at once and prints one block, led by what is done, what waits on
the agent, what waits on the owner, and whether the agent can just continue.

Called through resume-gather.sh. Read-only against the world, with one
exception: it registers this session with claude-ipc unless told not to.
Only commands the checkpoint marks `check:` are ever executed, each capped at
ten seconds, and only when they pass a read-only allowlist (see check_allowed);
a fix command is never run. This session's own identity is always
$CLAUDE_CODE_SESSION_ID (or --self-uuid); --session-id only names the
checkpoint to resolve.

Test hooks (environment): HOME relocates every ~/.claude path; RG_IPC, RG_GH,
RG_LEFT, RG_SHELL_MEM replace the external tools.
"""
import concurrent.futures as cf
import json
import os
import re
import shlex
import signal
import subprocess
import sys
import time
from datetime import datetime, timezone

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import ckutil  # noqa: E402  (shared checkpoint parsing, beside this file)

HOME = os.path.expanduser("~")
IPC = os.environ.get("RG_IPC", "claude-ipc")
GH = os.environ.get("RG_GH", "gh")
LEFT = os.environ.get("RG_LEFT", os.path.join(HERE, "..", "goals", "views", "left.py"))
SHELL_MEM = os.environ.get("RG_SHELL_MEM", os.path.join(HOME, ".claude", "scripts", "shell-mem.sh"))
CHECK_TIMEOUT = 10
ABS_PATH = re.compile(r"(?<![\w/.])(/[A-Za-z0-9_.+~@-]+(?:/[A-Za-z0-9_.+~@-]+)+)")
STOPWORDS = set("the a an and or of to in on for with this that is are be it its their from by at as not no do does".split())


def run(argv, timeout=5, cwd=None, env=None):
    """Run a command and kill its whole process group on timeout. Returns (rc, out, err); rc None means timed out."""
    try:
        p = subprocess.Popen(argv, cwd=cwd, env=env, stdin=subprocess.DEVNULL,
                             stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True,
                             start_new_session=True)
    except (OSError, ValueError) as e:
        return 127, "", str(e)
    try:
        out, err = p.communicate(timeout=timeout)
        return p.returncode, out, err
    except subprocess.TimeoutExpired:
        try:
            os.killpg(p.pid, signal.SIGKILL)
        except OSError:
            pass
        p.communicate()
        return None, "", "timeout"


def clip(s, n):
    s = re.sub(r"\s+", " ", s or "").strip()
    return s if len(s) <= n else s[: n - 1].rstrip() + "…"


def ago(secs):
    secs = int(max(secs, 0))
    if secs < 90:
        return f"{secs}s"
    if secs < 5400:
        return f"{secs // 60}m"
    if secs < 172800:
        return f"{secs // 3600}h{(secs % 3600) // 60:02d}m"
    return f"{secs // 86400}d"


def unk(why):
    return f"unknown ({why})"


def is_none(v):
    return v is None or re.sub(r"[\s`*.]", "", v).lower() in ("", "none", "-", "—", "n/a")


def sig_words(s):
    return {w for w in re.findall(r"[a-z]{4,}", (s or "").lower()) if w not in STOPWORDS}


class Checkpoint:
    """A parsed checkpoint: Resume Contract fields by lower-cased label, plus the H2 sections."""

    def __init__(self, path):
        self.path = path
        self.text = ckutil.read_text(path)
        self.mini = self.text.lstrip().startswith("# Mini Core Dump")
        self.fields, self.raw_fields = {}, {}
        for raw, (val, _s, _e) in ckutil.contract_fields(self.text).items():
            label = re.sub(r"\s*\(.*\)\s*$", "", raw).strip().lower()
            if not label.startswith("update ") and label not in self.fields:
                self.fields[label] = re.sub(r"\s+", " ", val).strip()
                self.raw_fields[label] = val
        self.legacy_auth = "standing authorizations" not in self.fields and "expired authorizations" in self.fields
        self.mini_fields = {}
        if self.mini:
            cur = None
            for ln in self.text.splitlines():
                m = re.match(r"^\*\*(Goal|Resume|Done|Not Done|Next Steps):\*\*[ \t]*(.*)$", ln)
                if m:
                    cur = m.group(1)
                    self.mini_fields[cur] = m.group(2)
                elif cur and ln.strip() and not ln.startswith("#"):
                    self.mini_fields[cur] += "\n" + ln

    def f(self, *labels):
        for lb in labels:
            if lb in self.fields:
                return self.fields[lb]
        return None

    def items(self, heading):
        return ckutil.bullets(ckutil.section(self.text, heading))

    def working_surface(self):
        m = re.search(r"\*\*Working surface:\*\*(.*(?:\n(?!\n|#|- \*\*).*)*)", self.text)
        return m.group(1).strip() if m else ""


# Git drift

def git(repo, *args, timeout=5):
    rc, out, _ = run(["git", "-C", repo] + list(args), timeout=timeout)
    return out.strip() if rc == 0 else None


def surface_repos(ck, project_root):
    """Repo directories the Working surface names, plus the branch it claims for each (the `on `x`` after the path)."""
    ws = ck.working_surface()
    repos, claims = [], {}
    for m in ABS_PATH.finditer(ws):
        p = m.group(1).rstrip(".,;:)")
        if p in repos or not os.path.isdir(p) or not git(p, "rev-parse", "--show-toplevel"):
            continue
        repos.append(p)
        nxt = ABS_PATH.search(ws, m.end())
        c = re.search(r"\bon `([^`]+)`", ws[m.end(): nxt.start() if nxt else len(ws)])
        if c:
            claims[p] = c.group(1)
    if not repos and project_root and git(project_root, "rev-parse", "--show-toplevel"):
        repos.append(project_root)
    shared = re.search(r"\beach on `([^`]+)`", ws)
    for p in repos:
        if shared and p not in claims:
            claims[p] = shared.group(1)
    return repos[:8], claims


def sec_drift(ctx):
    lines = []
    if not ctx["repos"]:
        lines.append(unk("no git working surface found in the checkpoint"))
    for p in ctx["repos"]:
        branch = git(p, "branch", "--show-current") or "(detached)"
        dirty = git(p, "status", "--porcelain")
        ab = git(p, "rev-list", "--left-right", "--count", "@{u}...HEAD")
        behind, ahead = (ab.split() + ["?", "?"])[:2] if ab else ("?", "?")
        since = git(p, "rev-list", "--count", f"--since={int(ctx['dump_epoch'])}", "HEAD")
        newest = git(p, "log", "-1", "--format=%h %s (%cr)") or "no commits"
        claim = ctx["claims"].get(p)
        verdict = "claimed branch not stated" if claim is None else ("matches claim" if claim == branch else f"MOVED, claimed {claim}")
        lines.append(f"{p}: {branch} ({verdict}); ahead {ahead} behind {behind}; "
                     f"dirty {len(dirty.splitlines()) if dirty is not None else '?'}; "
                     f"{since if since is not None else '?'} commit(s) since the dump; newest {clip(newest, 90)}")
    return lines + ctx["pr_lines"]


def pr_refs(ck):
    """(number, word before it) for each #N in Pending Items and the authorizations, first six."""
    refs, seen = [], set()
    text = " ".join(ck.items("Pending Items")) + " " + (ck.f("standing authorizations", "expired authorizations") or "")
    for m in re.finditer(r"(?:([A-Za-z-]+)\s+)?(?<![\w&])#(\d{1,6})\b", text):
        if m.group(2) not in seen:
            seen.add(m.group(2))
            refs.append((m.group(2), (m.group(1) or "").lower()))
    return refs[:6]


def repo_slug(repo):
    url = git(repo, "remote", "get-url", "origin") or ""
    m = re.search(r"github\.com[:/](.+?)(?:\.git)?$", url)
    return m.group(1) if m else None


def pr_view(slug, n):
    """(json or None, why) for one PR in one GitHub repo."""
    rc, o, e = run([GH, "pr", "view", n, "-R", slug, "--json", "state,isDraft,title,headRefOid"], timeout=8)
    if rc != 0:
        return None, clip(e, 60) if rc is not None else "gh timed out"
    try:
        return json.loads(o), ""
    except ValueError:
        return None, "gh output not JSON"


def sec_prs(ctx):
    """Read-only PR lookups. A bare #N names no repo, so it is tried in every working-surface repo
    (narrowed by a word like "extractor" before it) and each answer says which repo gave it."""
    refs, repos = ctx["prs"], ctx["repos"]
    if not refs:
        return []
    slugs = sorted({s for s in (repo_slug(r) for r in repos) if s})
    if not slugs:
        return [unk("PR numbers named but no GitHub remote among the working surfaces")]
    if run([GH, "--version"], timeout=3)[0] != 0:
        return [unk("gh not available")]
    jobs = []
    for n, word in refs:
        near = [s for s in slugs if word and word in s.lower()]
        jobs += [(s, n) for s in (near or slugs)]

    def one(job):
        slug, n = job
        j, why = pr_view(slug, n)
        if j is None:
            return None
        return (f"PR #{n} in {slug}: {j.get('state')}{' draft' if j.get('isDraft') else ''} "
                f"\"{clip(j.get('title', ''), 70)}\"")
    with cf.ThreadPoolExecutor(max_workers=6) as ex:
        found = [x for x in ex.map(one, jobs) if x]
    note = [f"(a bare #N matches PRs in more than one repo; check the repo named on each line)"] if len(slugs) > 1 and len(found) > len(refs) else []
    return found + note if found else [unk(f"PR(s) {', '.join('#' + n for n, _ in refs)} not found in {', '.join(slugs)}")]


# Decaying-prerequisite checks

def parse_checks(val):
    """Decaying prerequisites as (label, check command or None). Only a `check:` command is ever returned for running."""
    if is_none(val):
        return []
    entries = []
    for seg in re.split(r"\s·\s", val):
        seg = seg.strip()
        if not seg:
            continue
        m = re.search(r"\bcheck:\s*(.+)$", seg)
        if m and seg.startswith("check:") and entries:
            entries[-1][1] = m.group(1).strip().strip("`").strip()
        elif seg.startswith("fix:") and entries:
            continue
        elif m:
            entries.append([seg[: m.start()].strip(" ,;"), m.group(1).strip().strip("`").strip()])
        else:
            entries.append([seg, None])
    return [tuple(e) for e in entries]


_UNSAFE_CHARS = re.compile(r"[;&|<>`\n]|\$\(")
_CURL_BAD_LONG = ("--request", "--data", "--form", "--upload-file", "--remote-name", "--output-dir", "--config",
                  "--cookie-jar", "--json", "--create-dirs", "--dump-header", "--trace", "--stderr", "--libcurl")
_CURL_BAD_SHORT = set("XdFTOcKDJ")
_GIT_OK = ("status", "rev-parse", "log")


def _curl_ok(tok):
    for i, t in enumerate(tok):
        nxt = tok[i + 1] if i + 1 < len(tok) else ""
        if t.startswith("--"):
            name, _, val = t.partition("=")
            if name in ("--output", "-o"):
                if (val or nxt) != "/dev/null":
                    return False
            elif name.startswith(_CURL_BAD_LONG):
                return False
        elif t.startswith("-") and len(t) > 1:
            flags = t[1:]
            if set(flags) & _CURL_BAD_SHORT:
                return False
            if "o" in flags and (flags.split("o", 1)[1] or nxt) != "/dev/null":
                return False
    return True


def check_allowed(cmd):
    """True only for a single read-only command; anything that could write, send or chain is refused."""
    if _UNSAFE_CHARS.search(cmd):
        return False
    try:
        tok = shlex.split(cmd)
    except ValueError:
        return False
    if not tok:
        return False
    w = tok[0]
    if w in ("test", "[", "ls", "stat", "pgrep"):
        return True
    if w == "curl":
        return _curl_ok(tok[1:])
    if w == "gcloud":
        return tok[1:3] in (["auth", "print-access-token"], ["auth", "list"])
    if w == "gh":
        return tok[1:3] == ["auth", "status"]
    if w == "pm2":
        return len(tok) > 1 and tok[1] in ("list", "describe")
    if w == "lsof":
        return len(tok) > 1 and re.match(r"^-t?i", tok[1]) is not None
    if w == "nc":
        return len(tok) > 1 and tok[1].startswith("-z") and not {"-e", "-c", "-l", "-k"} & set(tok)
    if w == "git":
        rest = tok[3:] if tok[1:2] == ["-C"] and len(tok) > 3 else tok[1:]
        return bool(rest) and rest[0] in _GIT_OK and not any(
            t.startswith(("--output", "--ext-diff", "--textconv")) for t in rest)
    return False


def sec_checks(ctx):
    val = ctx["ck"].f("decaying prerequisites")
    if val is None:
        return [unk("no Decaying prerequisites field")]
    entries = parse_checks(val)
    if not entries:
        return ["none"]

    def one(e):
        label, cmd = e
        if cmd is None:
            return f"not run (no check: command)  {clip(label, 90)}"
        if not check_allowed(cmd):
            return f"not run (not a read-only check; fix it by hand: {clip(cmd, 160)})  {clip(label, 60)}"
        rc, _o, _e = run(["bash", "-c", cmd], timeout=CHECK_TIMEOUT, cwd=ctx["project_root"] or None)
        verdict = "TIMEOUT 10s" if rc is None else ("pass" if rc == 0 else f"FAIL rc={rc}")
        return f"{verdict}  {clip(label, 60)}  [check: {clip(cmd, 70)}]"
    with cf.ThreadPoolExecutor(max_workers=6) as ex:
        return list(ex.map(one, entries))


# Standing authorizations

def parse_auths(ck):
    val = ck.f("standing authorizations", "expired authorizations")
    if val is None:
        return None
    if is_none(val):
        return []
    if ck.legacy_auth:
        return [{"raw": val, "legacy": True}]
    raw = ck.raw_fields.get("standing authorizations") or val
    entries = []
    for s0, e0 in ckutil.auth_entries(raw):
        text = ckutil.flat(raw[s0:e0])
        m = ckutil.AUTH_SHAPE_RE.match(text)
        entries.append({"raw": text, "unverified": text.startswith("UNVERIFIED:"), "shaped": m is not None,
                        "target": m.group("target").strip() if m else None})
    return entries


def target_now(ctx, target):
    m = re.match(r"^(.+?)\s*@\s*(\S+)$", target or "")
    if not m:
        return unk("target has no @sha")
    where, sha = m.group(1).strip(), m.group(2).strip("`.,;")
    if not re.fullmatch(r"[0-9a-f]{6,40}", sha):
        return unk(f"@{sha} is an artifact, not a commit; check it by hand")
    cands = list(ctx["repos"])
    if ctx["project_root"] and ctx["project_root"] not in cands:
        cands.append(ctx["project_root"])
    repo, rest = None, ""
    for c in cands:
        names = {os.path.basename(c.rstrip("/")), (repo_slug(c) or "").rsplit("/", 1)[-1]} - {""}
        hit = next((nm for nm in names if where == nm or where.startswith(nm + "/")), None)
        if hit:
            repo, rest = c, where[len(hit) + 1:]
            break
        if where.startswith(c):
            repo, rest = c, where[len(c):].lstrip("/")
            break
    if repo is None:
        return unk(f'repo "{where.split("/")[0]}" is not among the checkpoint\'s working surfaces')
    pr = re.fullmatch(r"(?:PR\s*|#|pull/)(\d+)", rest)
    if pr:
        j, why = pr_view(repo_slug(repo) or "", pr.group(1)) if repo_slug(repo) else (None, "no GitHub remote")
        now = (j or {}).get("headRefOid")
        if not now:
            return unk(f"PR #{pr.group(1)} head not fetched: {why}")
    else:
        now = git(repo, "rev-parse", "--verify", "-q", (rest or "HEAD") + "^{commit}")
        if not now:
            return unk(f"ref {rest or 'HEAD'} not found in {os.path.basename(repo)}")
    if now.startswith(sha) or sha.startswith(now[: len(sha)]):
        return "matches"
    n = git(repo, "rev-list", "--count", f"{sha}..{now}")
    return "moved (" + (f"{n} commit(s) since @{sha[:8]}, now @{now[:8]}" if n is not None else f"now @{now[:8]}, @{sha[:8]} not found locally") + ")"


def sec_auth(ctx):
    auths = ctx["auths"]
    if auths is None:
        return [unk("no Standing/Expired authorizations field")]
    if not auths:
        return ["none"]
    out = []
    for a in auths:
        if a.get("legacy"):
            out.append(f"LEGACY (expired; needs fresh owner confirmation, not actionable): {clip(a['raw'], 200)}")
        elif a["unverified"]:
            out.append(f"NOT ACTIONABLE (UNVERIFIED): {clip(a['raw'], 160)}")
        elif not a["shaped"]:
            out.append(f"NOT ACTIONABLE (not a full grant: needs \"words\" (date) · target: … · one-shot|standing): "
                       f"{clip(a['raw'], 130)}")
        else:
            out.append(f"{clip(a['raw'], 150)}\n      target now: {target_now(ctx, a['target'])}")
    return out


# Pending approval codes

def sec_codes(ctx):
    val, sid = ctx["ck"].f("pending approval codes"), ctx["self"]
    out, listed = [], []
    if val is None:
        out.append(unk("checkpoint has no Pending approval codes field"))
    elif is_none(val):
        out.append("none listed")
    else:
        for m in re.finditer(r"(.+?)\s*·\s*nonce\s+([0-9A-Za-z]+)", val):
            tgt = m.group(1).strip(" ·")
            listed.append(tgt)
            out.append(f"{clip(tgt, 80)} -> nonce {m.group(2)} (issued to the old session)")
    if not sid:
        return out + [unk("no CLAUDE_CODE_SESSION_ID or --self-uuid, cannot look for this session's nonce file")]
    nf = os.path.join(HOME, ".claude", ".push-nonce-" + re.sub(r"[^A-Za-z0-9._-]", "_", sid))
    try:
        cur = json.load(open(nf))
    except (OSError, ValueError):
        cur = None
    if cur and cur.get("nonce"):
        out.append(f"this session has a pending nonce: {cur['nonce']} for {clip(cur.get('target', '?'), 60)}")
    elif listed:
        for tgt in listed:
            out.append(f"this session has no nonce file; re-issue: re-run {clip(tgt, 60)}'s push once to print a fresh code")
    else:
        out.append("this session has no pending nonce")
    return out


# claude-ipc

def jrun(argv, timeout=4):
    rc, o, e = run(argv, timeout=timeout)
    if rc is None:
        return None, "timed out"
    if rc != 0:
        return None, clip(e or o, 60) or f"rc={rc}"
    try:
        return json.loads(o), ""
    except ValueError:
        return None, "output not JSON"


def sec_ipc(ctx):
    sid = ctx["self"]
    raw = ctx["ck"].f("ipc alias") or ""
    m = None if is_none(raw) else re.search(r"[A-Za-z0-9][A-Za-z0-9._-]*", re.sub(r"[`*]", "", raw))
    alias = m.group(0) if m else None
    env = dict(os.environ)
    if sid:
        env["CLAUDE_CODE_SESSION_ID"] = sid
    out, mine = [], None
    if alias:
        who, why = jrun([IPC, "who", alias, "--json"])
        if who is None:
            return [unk(f"claude-ipc who: {why}")]
        ms = [x for x in who.get("matches", []) if x.get("alias") == alias or alias in x.get("sessionAliases", [])]
        if any(x.get("sessionId") == sid for x in ms):
            mine = alias
            out.append(f"already registered as {alias}")
        elif any(x.get("status") == "live" for x in ms):
            out.append(f"alias {alias} is held by a live session; not taking it over")
        elif ctx["no_ipc"] or not sid:
            out.append(f"not registered ({'--no-ipc' if ctx['no_ipc'] else 'this session has no id of its own'}); alias {alias} is free")
        else:
            rc, _o, e = run([IPC, "register", alias], timeout=5, env=env)
            mine = alias if rc == 0 else None
            out.append(f"registered as {alias}" if rc == 0 else unk(f"register {alias}: {clip(e, 50)}"))
    else:
        out.append("checkpoint names no ipc alias")
    if mine is None and sid and not ctx["no_ipc"]:
        rc, _o, e = run([IPC, "register", sid], timeout=5, env=env)
        mine = sid if rc == 0 else None
        out.append(f"registered as {sid}" if rc == 0 else unk(f"register {sid}: {clip(e, 50)}"))
    for name, label in ((mine, "inbox"), (alias if alias != mine else None, "predecessor's inbox")):
        if not name:
            continue
        rc, o, e = run([IPC, "count", name], timeout=4)
        n = o.split()[0] if rc == 0 and o.strip() else None
        out.append(f"{label} ({name}): {n} pending" if n is not None else f"{label} ({name}): " + unk(clip(e, 50) or "count failed"))
    if ctx["project_root"]:
        j, why = jrun([IPC, "inbox", "--project", ctx["project_root"]])
        out.append(f"project mailbox: {len(j.get('messages', []))} message(s)" if isinstance(j, dict) else "project mailbox: " + unk(why))
    return out


# Background commands

def sec_shell(ctx):
    if not os.path.isfile(SHELL_MEM):
        return [unk("shell-mem.sh not found")]
    rc, o, e = run(["bash", SHELL_MEM, "shell-log-active"], timeout=6)
    if rc != 0:
        return [unk(clip(e, 60) or "shell-mem failed")]
    root = ctx["project_root"] or ""
    needles = [n for n in (root, root.replace("/", "-")) if n]
    mine, other = [], 0
    for ln in o.splitlines():
        if not ln.strip():
            continue
        if any(n in ln for n in needles):
            mine.append(clip(re.sub(r"^- \[\d\d:\d\d:\d\d\] \[sid:([0-9a-f]{8})[^\]]*\] ", r"[\1] ", ln), 150))
        else:
            other += 1
    out = mine[:8] + ([f"... +{len(mine) - 8} more for this project"] if len(mine) > 8 else [])
    if not mine:
        out.append("none for this project")
    if other:
        out.append(f"({other} active background command(s) from other projects hidden; the log has no cwd, so verify before trusting any)")
    return out


# Goal record

def ckpt_goal_id(ck):
    v = ck.f("goal record")
    if is_none(v):
        return None
    m = re.search(r"\b[0-9a-f]{6,}\b", v or "")
    return m.group(0) if m else None


def load_goal(gid):
    rc, o, e = run(["python3", LEFT, "--goal", gid, "--json"], timeout=10)
    if rc != 0:
        return None, clip(e, 70) if rc is not None else "left.py timed out"
    try:
        return json.loads(o), ""
    except ValueError:
        return None, "left.py output not JSON"


def sec_goal(ctx):
    gid = ctx["gid"]
    if not gid:
        return [unk("checkpoint names no goal record")]
    # The plain view consumes unread handoff notes by design; catchup is the reader they wait for.
    rc, o, e = run(["python3", LEFT, "--goal", gid], timeout=10)
    if rc != 0:
        return [unk(clip(e, 70) if rc is not None else "left.py timed out")]
    lines = [("[OWNER] " if ("\U0001F534" in ln or "needs you" in ln) else "") + ln.rstrip() for ln in o.splitlines()]
    if len(lines) > 40:
        lines = lines[:40] + [f"... +{len(lines) - 40} more lines (python3 {LEFT} --goal {gid})"]
    return lines


# The three lists and the verdict

def build_status(ctx):
    ck, goal = ctx["ck"], ctx["goal"]
    done, agent, owner = [], [], []
    if ck.mini:
        for k, dst in (("Done", done), ("Not Done", agent), ("Next Steps", agent)):
            dst.extend(clip(b, 120) for b in (x.strip(" -*") for x in ck.mini_fields.get(k, "").splitlines()) if b)
    else:
        ver = ck.f("verification state")
        vitems = [] if is_none(ver) else [v for v in re.split(r"\s·\s", ver) if v.strip()]
        done = [clip(a, 120) for a in ck.items("Agent Actions")[-5:]]
        if vitems:
            more = f" (+{len(vitems) - 1} more in Verification state)" if len(vitems) > 1 else ""
            done.append("verified: " + clip(vitems[0], 100) + more)
        for b in ck.items("Pending Items"):
            (owner if re.match(r"(?i)^(\*\*)?(owner|user)\b", b) else agent).append(clip(b, 150))
    um = re.search(r"USER:\s*(.*?)(?=AGENT:|$)", ck.f("blocked on") or "", re.S)
    if um:
        blocked_words = sig_words(um.group(1))
        # a Pending Items owner bullet that only restates Blocked on adds nothing
        owner = [b for b in owner if len(sig_words(b) & blocked_words) < 0.6 * max(len(sig_words(b)), 1)]
        owner = [clip(it, 120) for it in re.split(r";\s*", um.group(1).strip().rstrip(".")) if it.strip()] + owner
    if goal:
        eff = goal.get("effective", {})
        for t in goal.get("tasks", []):
            st = eff.get(t["id"], t.get("state"))
            if st == "owner-gate":
                g = t.get("gate") or {}
                owner.append(f"#{t['id']} {clip(t['subject'], 60)}: {clip(g.get('do') or g.get('text', ''), 70)}")
            elif st in ("ready", "active", "review", "unassigned"):
                agent.append(f"#{t['id']} {clip(t['subject'], 90)} [{st}]")

    def cap(xs, n):
        return xs[:n] + ([f"... +{len(xs) - n} more"] if len(xs) > n else [])
    return done[-6:], cap(agent, 8), cap(owner, 8)


def continue_line(ck):
    if ck.mini:
        um = re.search(r"USER:\s*([^\n]*)", "\n".join(ck.mini_fields.get(k, "") for k in ("Resume", "Not Done", "Next Steps")))
        return f"no (needs the owner: {clip(um.group(1), 110)})" if um else "yes"
    nxt =ck.f("next action") if not ck.mini else (ck.mini_fields.get("Resume") or None)
    blocked = ck.f("blocked on")
    if nxt is None or blocked is None:
        return unk("checkpoint has no " + ("Next action" if nxt is None else "Blocked on") + " field")
    am = re.search(r"AGENT:\s*(.*)$", blocked, re.S)
    agent_part = am.group(1).strip() if am else None
    if agent_part is not None and not re.match(r"(?i)^(none|nothing)\b", agent_part):
        return f"no (agent is blocked: {clip(agent_part, 100)})"
    um = re.search(r"USER:\s*(.*?)(?=AGENT:|$)", blocked, re.S)
    if um:
        nw = sig_words(nxt)
        hits = [it.strip() for it in re.split(r";\s*", um.group(1).strip().rstrip(".")) if len(sig_words(it) & nw) >= 2]
        if hits:
            return f"no (needs the owner: {clip('; '.join(hits), 110)})"
    elif agent_part is None and not is_none(blocked):
        return f"no ({clip(blocked, 100)})"
    return "yes"


# Entry point

def find_checkpoint(args):
    sh = os.path.join(HERE, "resolve.sh")
    if args["path"]:
        p = os.path.abspath(os.path.expanduser(args["path"]))
        return (p, {}, 0) if os.path.isfile(p) else (None, {}, 3)
    if args["pick"]:
        argv = ["bash", sh, "--pick", args["pick"]]
    elif args["sid_given"]:
        argv = ["bash", sh, "--session-id", args["sid"]]
    else:
        argv = ["bash", sh, "--auto", "--cwd", args["cwd"]]
    rc, o, _e = run(argv, timeout=10)
    if rc != 0:
        return None, {}, (rc if rc in (2, 3) else 3)
    try:
        j = json.loads(o[o.index("{"):])
    except ValueError:
        return None, {}, 3
    p = j.get("checkpoint_path", "")
    return (p, j, 0) if p and os.path.isfile(p) else (None, j, 3)


def read_cli(argv):
    args = {"path": None, "sid": "", "self": os.environ.get("CLAUDE_CODE_SESSION_ID", ""), "sid_given": False,
            "pick": None, "cwd": os.getcwd(), "no_ipc": False}
    i = 0
    while i < len(argv):
        a = argv[i]
        if a in ("--session-id", "--pick", "--cwd", "--self-uuid") and i + 1 < len(argv):
            key = {"--session-id": "sid", "--pick": "pick", "--cwd": "cwd", "--self-uuid": "self"}[a]
            args[key] = argv[i + 1]
            args["sid_given"] = args["sid_given"] or a == "--session-id"
            i += 1
        elif a == "--no-ipc":
            args["no_ipc"] = True
        elif a in ("-h", "--help"):
            print(__doc__)
            sys.exit(0)
        elif not a.startswith("-") and args["path"] is None:
            args["path"] = a
        else:
            print(f"resume-gather: unknown argument: {a}", file=sys.stderr)
            sys.exit(2)
        i += 1
    return args


def validate_file(path, mini):
    rc, o, e = run(["bash", os.path.join(HERE, "validate-checkpoint.sh"), path] + (["--mini"] if mini else []), timeout=10)
    if rc is None:
        return unk("validator timed out")
    if rc == 0:
        warns = [ln for ln in o.splitlines() if ln.startswith("warn:")]
        return "valid" + (f" ({len(warns)} warning(s): {clip(warns[0], 110)})" if warns else "")
    msg = (e or o).strip()
    return "INVALID: " + clip(msg.splitlines()[0] if msg else f"rc={rc}", 160)


def main(argv):
    args = read_cli(argv)
    path, entry, rc = find_checkpoint(args)
    if path is None:
        if rc == 2:
            print("checkpoint: ambiguous (several or only stale entries); pick one, then re-run with its path")
            print(run(["bash", os.path.join(HERE, "list.sh"), "--limit", "8", "--cwd", args["cwd"]], timeout=10)[1].rstrip())
            return 2
        print("checkpoint: not found (no index entry, no file at that path)")
        return 3

    ck = Checkpoint(path)
    dump_epoch = os.path.getmtime(path)
    if entry.get("ts"):
        try:
            dump_epoch = datetime.strptime(entry["ts"], "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=timezone.utc).timestamp()
        except ValueError:
            pass
    project_root = entry.get("project_root") or os.path.dirname(path)
    repos, claims = surface_repos(ck, project_root)
    ctx = {"ck": ck, "self": args["self"], "no_ipc": args["no_ipc"], "project_root": project_root,
           "repos": repos, "claims": claims, "dump_epoch": dump_epoch,
           "prs": pr_refs(ck), "gid": ckpt_goal_id(ck), "auths": parse_auths(ck), "pr_lines": [], "goal": None}

    def settle(fut, name):
        try:
            return fut.result(timeout=14)
        except Exception as e:  # one failed section must not take the others down
            return [unk(f"{name} failed: {clip(str(e), 60)}")]

    with cf.ThreadPoolExecutor(max_workers=8) as ex:
        goal_f = ex.submit(load_goal, ctx["gid"]) if ctx["gid"] else None
        pr_f, ipc_f, shell_f = ex.submit(sec_prs, ctx), ex.submit(sec_ipc, ctx), ex.submit(sec_shell, ctx)
        checks_f, view_f, codes_f = ex.submit(sec_checks, ctx), ex.submit(sec_goal, ctx), ex.submit(sec_codes, ctx)
        verdict_f = ex.submit(validate_file, path, ck.mini)
        goal, gwhy = goal_f.result(timeout=14) if goal_f else (None, "no goal record")
        ctx["goal"] = goal if isinstance(goal, dict) else None
        ctx["pr_lines"] = settle(pr_f, "prs")
        drift, auth = sec_drift(ctx), sec_auth(ctx)
        checks, ipc, shell = settle(checks_f, "checks"), settle(ipc_f, "ipc"), settle(shell_f, "shell")
        codes, view = settle(codes_f, "pending_codes"), settle(view_f, "goal_record")
        verdict = settle(verdict_f, "validate")

    done, agent, owner = build_status(ctx)

    def block(title, items):
        print(f"{title}:")
        for it in items or ["none"]:
            print("  " + it)

    print(f"checkpoint: {path}")
    print(f"  name {entry.get('name') or os.path.basename(path)} · age {ago(time.time() - dump_epoch)} · project {project_root}")
    print(f"  validate: {verdict}")
    print()
    block("status.done", done)
    block("status.pending_on_agent", agent)
    block("status.pending_on_owner", owner)
    print(f"continue: {continue_line(ck)}")
    print()
    block("drift", drift)
    block("checks", checks)
    block("authorizations", auth)
    block("pending_codes", codes)
    block("ipc", ipc)
    block("shell", shell)
    if ctx["gid"] and ctx["goal"] is None:
        view = [unk(f"goal {ctx['gid']}: {gwhy}")]
    elif ctx["goal"]:
        eff = ctx["goal"].get("effective", {})
        gated = [t["id"] for t in ctx["goal"].get("tasks", []) if eff.get(t["id"]) == "owner-gate"]
        view = ["owner-gated rows: " + (", ".join("#" + i for i in gated) or "none")] + view
    block("goal_record" + (f" ({ctx['gid']})" if ctx["gid"] else ""), view)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
