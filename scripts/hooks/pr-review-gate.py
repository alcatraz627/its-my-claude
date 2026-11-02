#!/usr/bin/env python3
"""Makes sure every finding Clanky raises on a versable-git PR gets an answer.

Rules alone never made agents read the review bot (rules/read-the-comments-on-
a-pr-you-raised.md). Once a session pushes to a PR, the turn may not end until
Clanky's review of the head is in and each finding has a disposition with a
one-line reason.

Runtime contract:
  pr-review-gate.py track        PostToolUse on Bash and the GitHub MCP's PR and
                                 push tools: remember PRs this session created or
                                 pushed to
  pr-review-gate.py stop         Stop: block while the head's review has findings
                                 with no disposition; otherwise keep the wait
                                 going and tell the owner what is happening
  pr-review-gate.py wait <pr> [seconds] [--wake SESSION --marker FILE]
                                 poll until the review for the head lands
                                 (default 6 min), then print its findings; with
                                 --wake, message that session when it ends
  pr-review-gate.py dispose <pr> [--sha S] "1=fixed:reason" "2=optional:reason" ...
  pr-review-gate.py summary <pr> [--sha S]  one line per finding for the owner
--sha names an earlier head's review, so findings fixed in the same push that
moved the head can still be answered against the review that raised them.
<pr> is a PR URL, owner/repo#N or repo#N (org defaults to versable-git).

Waiting is the hook's chore, not the model's. Stop starts one detached `wait` per PR, head and session, which wakes the
session over claude-ipc when it ends. If ipc is down the next Stop still blocks
on the findings. A headless run has no watcher to wake it, so it alone is still
told to run `wait`.

No review five minutes after the push, with no wait running, is reported to the
owner and never acted on: a retrigger needs the owner's approval. Clanky being
out of usage or paused on the PR is read from the PR's comments and reported
the same way. Skipped: closed, merged and draft PRs, and titles carrying [nobot]
or [no-bot]. Each block fires at most twice per PR, head and phase, then becomes
a note to the owner.

Mute: touch ~/.claude/.no-pr-review-gate · One-shot: PR_REVIEW_GATE_OFF=1
Test: bash ~/.claude/scripts/hooks/pr-review-gate.test.sh
"""
import json
import os
import re
import subprocess
import sys
import time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import hookpop  # noqa: E402

ORG = "versable-git"
SETTLE_S = 300
WAIT_MAX_S = 360
POLL_S = float(os.environ.get("PR_REVIEW_GATE_POLL_S", 20))
AUTO_WAIT_S = int(os.environ.get("PR_REVIEW_GATE_AUTO_WAIT_S", WAIT_MAX_S))
# A wait that runs this far past its limit is dead, even if its pid now belongs to something else.
AUTO_WAIT_GRACE_S = 60
AUTO_WAIT_RESTARTS = 1
IPC_TIMEOUT_S = 10
MAX_BLOCKS = 2
CONCERN_MAX = 140
GH_TIMEOUT_S = 10
# stop-arbiter.py gives each gate 55 s; stay well inside it so
# a slow GitHub never gets the hook killed with every block lost.
STOP_BUDGET_S = 40
DISPOSITIONS = ("fixed", "will-fix", "large", "optional", "not-worth-it", "other")

STATE = os.environ.get("PR_REVIEW_GATE_STATE", os.path.expanduser("~/.claude/state/pr-review-gate"))
GH = os.environ.get("PR_REVIEW_GATE_GH", "gh")
IPC = os.environ.get("PR_REVIEW_GATE_IPC", "claude-ipc")
IPC_SENDER = "pr-review"
MUTE = os.path.expanduser("~/.claude/.no-pr-review-gate")
SELF = "python3 ~/.claude/scripts/hooks/pr-review-gate.py"
LOCAL_TRIGGER = "python3 ~/Code/Versable/slack-automation/scripts/clanky-review.py"

PR_URL = re.compile(r"https://github\.com/([\w.-]+)/([\w.-]+)/pull/(\d+)")
PR_SHORT = re.compile(r"^(?:([\w.-]+)/)?([\w.-]+)#(\d+)$")
# Matched only where a command starts, on the command with quoted text blanked,
# so `git stash push`, `echo git push` and commit messages never fire.
CMD_START = r"(?:^|[;&|(\n]\s*)"
GIT_PUSH = re.compile(CMD_START + r"git((?:\s+-[Cc]\s+\S+)*)\s+push\b")
GH_PR = re.compile(CMD_START + r"(?:\S*/)?gh\b(?:\s+(?:-R|--repo)\s+\S+)?\s+pr\s+(?:create|edit|ready|reopen)\b")
QUOTED = re.compile(r"'[^']*'|\"(?:\\.|[^\"\\])*\"")
MCP_PR_TOOLS = ("mcp__github__create_pull_request", "mcp__github__push_files",
                "mcp__github__create_or_update_file", "mcp__github__update_pull_request_branch")
# The bot's marker opens a line of its own comment; a quote-reply (`> <!--`) does not count.
REVIEW_MARK = re.compile(r"^<!-- pr-claude:review", re.MULTILINE)
REVIEW_SHA = re.compile(r"<!--\s*pr-claude:review:sha=([0-9a-f]+)\s*-->")
FINDING = re.compile(r"^###\s+\S+\s+(\d+)\.\s+(.+)$", re.MULTILINE)
MD_LINK = re.compile(r"\[([^\]]*)\]\([^)]*\)")
NOBOT = re.compile(r"\[no-?bot\]", re.IGNORECASE)
# What Clanky says about itself on the PR. The sticky comment is rewritten when a
# review dies with nothing to keep; when older findings are kept, only the status
# reply says so, naming the head it stood down on.
REVIEW_OUTCOME = re.compile(r"<!--\s*pr-claude:review:outcome=([\w.]+)\s*-->")
OUT_OF_USAGE = "review.not_run.out_of_usage"
USAGE_RESET = re.compile(r"Claude's usage resets ([^,\n]+),")
STOOD_DOWN = re.compile(r"Review stood down on `([0-9a-f]{7,40})`: Claude usage exhausted")
AUTO_PAUSED = re.compile(r"^⏸️?\s*Automatic reviews are paused on this PR", re.MULTILINE)


def gh(*args, cwd=None):
    try:
        r = subprocess.run([GH, *args], capture_output=True, text=True, timeout=GH_TIMEOUT_S, cwd=cwd)
    except (OSError, subprocess.TimeoutExpired):
        return None
    return r.stdout if r.returncode == 0 else None


def parse_ref(ref):
    """Turn a URL or repo#N into (owner, repo, number), or None."""
    m = PR_URL.search(ref)
    if m:
        return m.group(1), m.group(2), int(m.group(3))
    m = PR_SHORT.match(ref.strip())
    if m:
        return m.group(1) or ORG, m.group(2), int(m.group(3))
    return None


def key(ref):
    return f"{ref[0]}/{ref[1]}#{ref[2]}"


def url(ref):
    return f"https://github.com/{ref[0]}/{ref[1]}/pull/{ref[2]}"


def load(path, default):
    try:
        with open(path) as f:
            return json.load(f)
    except (OSError, ValueError):
        return default


def save(path, data):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    tmp = path + ".tmp"
    with open(tmp, "w") as f:
        json.dump(data, f)
    os.replace(tmp, path)


def session_path(sid):
    return os.path.join(STATE, "sessions", f"{sid[:8]}.json")


def ledger_path():
    return os.path.join(STATE, "ledger.jsonl")


def parse_review(review):
    """(reviewed sha, [(n, "file:line · concern")]) from one Clanky review comment."""
    m = REVIEW_SHA.search(review)
    findings = []
    heads = list(FINDING.finditer(review))
    for i, h in enumerate(heads):
        # The heading is only file:line · symbol; the concern is the first
        # paragraph under it, which is what the owner needs to read.
        end = heads[i + 1].start() if i + 1 < len(heads) else len(review)
        body = [l.strip() for l in review[h.end():end].splitlines()]
        concern = next((l for l in body if l and not l.startswith(("#", "<!--", "-", ">"))), "")
        if len(concern) > CONCERN_MAX:
            concern = concern[:CONCERN_MAX - 1].rstrip() + "…"
        where = MD_LINK.sub(r"\1", h.group(2)).strip()
        findings.append((int(h.group(1)), f"{where} · {concern}" if concern else where))
    return (m.group(1) if m else None), findings


def fetch(ref):
    """The PR as the gate needs it: state, head, title, Clanky's latest review and every earlier one."""
    out = gh("pr", "view", url(ref), "--json", "state,isDraft,title,headRefOid,mergeable,comments")
    if not out:
        return None
    pr = json.loads(out)
    pr["reviews"] = {}
    pr["review_sha"], pr["findings"] = None, []
    pr["outcome"], pr["usage_reset"], pr["stood_down"], pr["auto_paused"] = None, None, [], False
    for c in pr.get("comments") or []:
        body = c.get("body") or ""
        pr["stood_down"] += STOOD_DOWN.findall(body)
        pr["auto_paused"] = pr["auto_paused"] or bool(AUTO_PAUSED.search(body))
        if REVIEW_MARK.search(body):
            sha, findings = parse_review(body)
            pr["review_sha"], pr["findings"] = sha, findings
            if sha:
                pr["reviews"][sha] = findings
            outcome, reset = REVIEW_OUTCOME.search(body), USAGE_RESET.search(body)
            pr["outcome"] = outcome.group(1) if outcome else None
            pr["usage_reset"] = reset.group(1).strip() if reset else None
    pr.pop("comments", None)
    return pr


def out_of_usage(pr):
    """Whether the PR says Clanky ran out of Claude usage on its latest attempt.

    The comments carry no edit time, so this can lag a reset that has already
    passed. It only ever words a note to the owner, and the wait runs regardless.
    """
    head = pr.get("headRefOid") or ""
    return pr.get("outcome") == OUT_OF_USAGE or any(head.startswith(s) for s in pr.get("stood_down") or [])


def review_for(pr, sha):
    """(full reviewed sha, findings) for an earlier review named by a prefix, or None."""
    hits = [k for k in pr.get("reviews", {}) if k.startswith(sha) or sha.startswith(k)]
    return (hits[-1], pr["reviews"][hits[-1]]) if len(hits) == 1 else None


def wait_path(ref, head):
    return os.path.join(STATE, "waits", f"{ref[0]}-{ref[1]}-{ref[2]}@{head[:7]}.json")


def live_wait(ref, head):
    """The marker of a wait still polling for this PR and head, or None."""
    w = load(wait_path(ref, head), None)
    if not isinstance(w, dict) or time.time() > w.get("deadline", 0):
        return None
    try:
        os.kill(int(w.get("pid", 0)), 0)
    except (OSError, ValueError):
        return None
    return w


def review_current(pr):
    sha = pr.get("review_sha")
    return bool(sha) and (pr.get("headRefOid") or "").startswith(sha)


def auto_wait_path(ref, head, sid):
    return os.path.join(STATE, "autowaits", f"{ref[0]}-{ref[1]}-{ref[2]}@{head[:7]}-{sid[:8]}.json")


def auto_wait_state(path):
    """How the wait this hook started is doing, as (live | ended | dead | None, its marker).

    Ended means it ran its course, so it is not started again at this head. Dead
    means it stopped without saying so, or outran its limit by more than any slow
    poll could explain.
    """
    w = load(path, None)
    if not isinstance(w, dict):
        return None, {}
    if w.get("ended"):
        return "ended", w
    try:
        os.kill(int(w.get("pid", 0)), 0)
    except (OSError, ValueError):
        return "dead", w
    return ("live", w) if time.time() <= w.get("deadline", 0) else ("dead", w)


def watched_for(ref, head, sid):
    """Whether a live wait on this head will reach this session: one it ran itself, or one that wakes it.

    Another session's background wait wakes that session only, so it does not count here.
    """
    w = live_wait(ref, head)
    return bool(w) and w.get("wake") in (None, sid)


def ensure_auto_wait(ref, head, sid):
    """Keep exactly one background wait on this PR's head for this session; says what it found or did."""
    if watched_for(ref, head, sid):
        return "live"
    path = auto_wait_path(ref, head, sid)
    state, w = auto_wait_state(path)
    if state in ("live", "ended"):
        return state
    restarts = w.get("restarts", 0) + 1 if state == "dead" else 0
    if restarts > AUTO_WAIT_RESTARTS:
        return "dead"
    now = time.time()
    # The wait replaces this pid with its own as soon as it runs. Nothing here writes
    # to the marker after the spawn, so it can never overwrite a wait that already ended.
    save(path, {"pid": os.getpid(), "sid": sid, "started": now, "restarts": restarts,
                "deadline": now + AUTO_WAIT_S + AUTO_WAIT_GRACE_S})
    # A Stop hook has to return at once: the wait gets no stream of the hook's, or the
    # harness would sit on the open pipe until it ended, and its own session so that
    # cleaning up the hook's process group does not take it down.
    with open(os.path.join(STATE, "autowait.log"), "a") as log:
        subprocess.Popen([sys.executable, os.path.abspath(__file__), "wait", key(ref), str(AUTO_WAIT_S),
                          "--wake", sid, "--marker", path],
                         stdin=subprocess.DEVNULL, stdout=log, stderr=log, start_new_session=True, close_fds=True)
    return "started"


def dispositions(ref, sha):
    """Finding number -> (disposition, reason, finding text) recorded against this review.

    Callers compare the finding text too: a re-run of the review on the same
    head can renumber or replace findings, and an old answer must not cover a
    new finding.
    """
    got = {}
    try:
        with open(ledger_path()) as f:
            for line in f:
                try:
                    row = json.loads(line)
                except ValueError:
                    continue
                if row.get("pr") == key(ref) and row.get("sha") == sha:
                    got[row["n"]] = (row["disposition"], row["reason"], row.get("finding"))
    except OSError:
        pass
    return got


def cmd_track(inp):
    tool = inp.get("tool_name")
    tin = inp.get("tool_input") or {}
    cwd = inp.get("cwd") or None
    if tool == "Bash":
        bare = QUOTED.sub("''", tin.get("command") or "")
        push = GIT_PUSH.search(bare)
        if not push and not GH_PR.search(bare):
            return
        if push:
            # `git -C <dir> push` pushes another repo; ask gh about that one.
            c = re.findall(r"-C\s+(\S+)", push.group(1) or "")
            if c:
                cwd = os.path.join(cwd or os.getcwd(), os.path.expanduser(c[-1]))
    elif tool not in MCP_PR_TOOLS:
        return
    resp = inp.get("tool_response")
    # URLs come from the result only: a command can quote some other PR's URL.
    text = json.dumps(resp) if not isinstance(resp, str) else resp
    refs = {parse_ref(m.group(0)) for m in PR_URL.finditer(text)}
    refs.discard(None)
    if not refs and tool == "Bash":
        # A plain push to a branch that already has a PR names no URL; ask gh which PR it is.
        out = gh("pr", "view", "--json", "url", cwd=cwd)
        ref = parse_ref(json.loads(out).get("url") or "") if out else None
        if ref:
            refs.add(ref)
    elif not refs and tin.get("owner") and tin.get("repo") and tin.get("branch"):
        out = gh("pr", "list", "--repo", f"{tin['owner']}/{tin['repo']}", "--head", tin["branch"], "--json", "url")
        for row in (json.loads(out) if out else []):
            ref = parse_ref(row.get("url") or "")
            if ref:
                refs.add(ref)
    refs = {r for r in refs if r[0].lower() == ORG}
    if not refs:
        return
    path = session_path(str(inp.get("session_id") or "nosid"))
    st = load_state(path)
    for r in refs:
        st["prs"][key((r[0].lower(), r[1], r[2]))] = {"pushed_at": time.time()}
    save(path, st)


def load_state(path):
    """This session's tracked PRs, or a fresh record when the file is missing or malformed."""
    st = load(path, None)
    if not isinstance(st, dict) or not isinstance(st.get("prs"), dict) or not isinstance(st.get("blocks"), dict) \
            or not all(isinstance(v, dict) for v in st["prs"].values()):
        return {"prs": {}, "blocks": {}, "noted": {}}
    if not isinstance(st.get("noted"), dict):
        st["noted"] = {}
    return st


def cmd_stop(inp):
    sid = str(inp.get("session_id") or "nosid")
    path = session_path(sid)
    st = load_state(path)
    if not st["prs"]:
        return
    # Keep-warm pings already left in main, so what fails this test is a headless run.
    headless = not hookpop.should_run("owner-turn")
    reasons, notes, started = [], [], time.time()
    for k, info in list(st["prs"].items()):
        if time.time() - started > STOP_BUDGET_S:
            notes.append(f"{k}: not checked this turn, GitHub was too slow.")
            continue
        try:
            msg, phase, head7 = check_pr(k, info, st, sid, headless, notes)
        except Exception as e:  # one bad PR must not stop the others being checked
            print(f"pr-review-gate: {k}: {e}", file=sys.stderr)
            continue
        if not msg:
            continue
        sig = f"{k}@{head7}:{phase}"
        count = st["blocks"].get(sig, 0)
        if count >= MAX_BLOCKS:
            notes.append(f"{k}: Clanky review for {head7} still unresolved ({phase}); the agent ended the turn anyway.")
            continue
        st["blocks"][sig] = count + 1
        reasons.append(msg)
    save(path, st)
    out = {}
    if reasons:
        warn_log("block")
        out.update(decision="block", reason="PR review gate\n" + "\n\n".join(reasons))
    if notes:
        out["systemMessage"] = "PR review gate: " + " ".join(notes)
    if out:
        print(json.dumps(out, ensure_ascii=False))


def note_once(st, notes, sig, text):
    """Say this to the owner the first time it is true for this head, not on every Stop."""
    if not st["noted"].get(sig):
        st["noted"][sig] = 1
        notes.append(text)


def check_pr(k, info, st, sid, headless, notes):
    """What this PR still needs: a block as (message, phase, head), or (None, None, None) with any notes added."""
    ref = parse_ref(k)
    pr = fetch(ref)
    if not pr:
        return None, None, None
    if pr.get("state") != "OPEN":
        st["prs"].pop(k, None)  # merged or closed: stop paying a GitHub call for it every turn
        return None, None, None
    if pr.get("isDraft") or NOBOT.search(pr.get("title") or ""):
        return None, None, None
    head = pr.get("headRefOid") or ""
    head7 = head[:7]
    if review_current(pr):
        done = dispositions(ref, pr["review_sha"])
        missing = [(n, t) for n, t in pr["findings"] if n not in done or done[n][2] not in (None, t)]
        if not missing:
            return None, None, None
        lines = "\n".join(f"  {n}. {t}" for n, t in missing)
        return (f"{k}: Clanky's review of {head7} has {len(missing)} finding(s) with no disposition:\n{lines}\n"
                f"Read each one, act, then record it: {SELF} dispose {k} \"N=<{'|'.join(DISPOSITIONS)}>:<one-line reason>\" ...\n"
                f"Then give the owner {SELF} summary {k} (one line per finding)."), "dispose", head7
    if pr.get("mergeable") == "CONFLICTING":
        # The bot skips a conflicted PR, so there is nothing to wait for until this is fixed.
        note_once(st, notes, f"{k}@{head7}:conflict",
                  f"{k}: head {head7} has merge conflicts, so Clanky will not review it and it cannot merge until it is rebased.")
        return None, None, None
    age = time.time() - info.get("pushed_at", 0)
    usage_out = out_of_usage(pr)
    if headless:
        # Nothing can wake a run that has exited, so it has to sit through the wait itself.
        if age < SETTLE_S and not usage_out and not watched_for(ref, head, sid):
            return (f"{k}: Clanky has not reviewed head {head7} yet. Run {SELF} wait {k} "
                    f"(polls up to {WAIT_MAX_S // 60} min), then disposition what it raises."), "wait", head7
        wait_state = "ended"
    else:
        wait_state = ensure_auto_wait(ref, head, sid)
    if usage_out:
        reset = pr.get("usage_reset")
        when = f"it says usage resets {reset}" if reset else "it does not say when usage comes back"
        note_once(st, notes, f"{k}@{head7}:usage",
                  f"{k}: Clanky's last attempt ran out of Claude usage, so head {head7} has no review yet ({when}). "
                  f"It re-runs by itself; any findings block a later Stop.")
    elif wait_state == "started":
        notes.append(f"waiting for Clanky on {k} at {head7}, in the background. This session gets a message when it ends.")
    elif wait_state == "live":
        pass
    elif pr.get("auto_paused"):
        note_once(st, notes, f"{k}@{head7}:paused",
                  f"{k}: Clanky has paused automatic reviews on this PR after repeated failures, so head {head7} gets none "
                  f"unless someone asks. Starting one needs your approval, and the local run posts nothing to the PR: "
                  f"{LOCAL_TRIGGER} {k} --notify <ipc alias>")
    elif age >= SETTLE_S:
        note_once(st, notes, f"{k}@{head7}:retrigger",
                  f"{k}: no Clanky review for head {head7} {int(age // 60)} min after the push. A retrigger needs your "
                  f"approval, and the local run posts nothing to the PR: {LOCAL_TRIGGER} {k} --notify <ipc alias>")
    return None, None, None


def ipc(*args):
    """One claude-ipc call. Its result, or None if it could not run: a wake is never worth an exception."""
    try:
        return subprocess.run([IPC, *args], capture_output=True, text=True, timeout=IPC_TIMEOUT_S)
    except (OSError, subprocess.SubprocessError) as e:
        print(f"pr-review-gate: claude-ipc {args[0]} did not run: {e}", file=sys.stderr)
        return None


def ipc_address(sid):
    """The name this session's mail goes to: the broker does not know sessions by id, only by alias."""
    r = ipc("peers", "--by-session")
    try:
        peers = json.loads(r.stdout).get("peers", []) if r else []
    except ValueError:
        peers = []
    # A session that was cleared while the wait ran has a successor, which is the one reading mail now.
    row = next((p for p in peers if p.get("succeededSid") == sid), None) \
        or next((p for p in peers if p.get("sessionId") == sid), None)
    return (row.get("aliases") or [sid])[0] if row else sid


def wake_body(ref, pr, code):
    """The one line a woken session reads, with what matters first: the watcher shows only the opening."""
    k = key(ref)
    if code != 0:
        head = (pr or {}).get("headRefOid", "")[:7] or "the current head"
        return (f"{k}: no Clanky review for {head} after the background wait. Nothing to disposition yet. "
                f"Tell the owner; a retrigger needs their approval. No reply needed.")
    n = len(pr["findings"])
    if not n:
        return f"{k}: Clanky reviewed {pr['review_sha'][:7]} with no findings. Nothing to disposition. No reply needed."
    return (f"{k}: Clanky reviewed {pr['review_sha'][:7]} with {n} finding(s). Read them with {SELF} summary {k}, "
            f"act, then record each with {SELF} dispose {k}. No reply needed.")


def wake_session(sid, ref, pr, code):
    """Turn a finished wait into a new turn for the session that was waiting, at most once per outcome.

    The kind is `request` because the session's inbox watcher only wakes an idle
    session for mail that asks something; an inform waits for the owner's next turn.
    A failure here loses nothing, since the next Stop still blocks on any findings.
    """
    if muted():
        return
    if pr and pr.get("state") not in (None, "OPEN"):
        return
    if code != 0 and pr and out_of_usage(pr):
        return  # the owner was already told, and nothing new has happened
    head7 = ((pr or {}).get("headRefOid") or "unknown")[:7]
    claim = os.path.join(STATE, "autowaits", f"{ref[0]}-{ref[1]}-{ref[2]}@{head7}-{sid[:8]}.woken-{code}")
    try:
        os.makedirs(os.path.dirname(claim), exist_ok=True)
        os.close(os.open(claim, os.O_CREAT | os.O_EXCL | os.O_WRONLY))
    except OSError:
        return
    # The broker refuses a sender it does not know, and registering again is harmless.
    ipc("register", IPC_SENDER, "--service")
    sent = ipc("send", "--from", IPC_SENDER, "--to", ipc_address(sid), "--kind", "request", "--no-reply-expected",
               wake_body(ref, pr, code))
    if sent is not None and sent.returncode != 0:
        print(f"pr-review-gate: wake not sent: {(sent.stderr or sent.stdout).strip()[:300]}", file=sys.stderr)


def muted():
    return os.path.exists(MUTE) or os.environ.get("PR_REVIEW_GATE_OFF") == "1"


def resolve_or_die(arg):
    ref = parse_ref(arg)
    if not ref:
        sys.exit(f"not a PR reference: {arg} (use a URL, owner/repo#N or repo#N)")
    return ref


def cmd_wait(args):
    positional, wake_sid, auto_marker = [], None, None
    it = iter(args)
    for a in it:
        if a == "--wake":
            wake_sid = next(it, None)
        elif a == "--marker":
            auto_marker = next(it, None)
        else:
            positional.append(a)
    ref = resolve_or_die(positional[0])
    if len(positional) > 1 and not positional[1].isdigit():
        sys.exit(f"wait limit must be whole seconds, got {positional[1]!r}")
    limit = int(positional[1]) if len(positional) > 1 else WAIT_MAX_S
    if auto_marker:
        save(auto_marker, {**(load(auto_marker, None) or {}), "pid": os.getpid()})
    code, pr = poll_for_review(ref, limit, wake_sid)
    if wake_sid:
        wake_session(wake_sid, ref, pr, code)
    if auto_marker:
        save(auto_marker, {**(load(auto_marker, None) or {}), "ended": time.time()})
    return code


def poll_for_review(ref, limit, wake_sid=None):
    """Watch the PR until its head has a review or the limit runs out: (0 or 1, the PR as last read)."""
    deadline = time.time() + limit
    marker = None
    try:
        while True:
            pr = fetch(ref)
            if pr and review_current(pr):
                print(f"{key(ref)}: Clanky reviewed {pr['review_sha']} with {len(pr['findings'])} finding(s).")
                for n, t in pr["findings"]:
                    print(f"  {n}. {t}")
                return 0, pr
            if time.time() >= deadline:
                head = (pr or {}).get("headRefOid", "")[:7]
                print(f"{key(ref)}: no review for head {head} after {limit // 60} min.")
                return 1, pr
            head = (pr or {}).get("headRefOid") or ""
            if head and (marker is None or not marker.endswith(f"@{head[:7]}.json")):
                if marker:
                    _drop(marker)
                marker = wait_path(ref, head)
                save(marker, {"pid": os.getpid(), "head": head, "started": time.time(), "deadline": deadline, "wake": wake_sid})
            time.sleep(POLL_S)
    finally:
        if marker:
            _drop(marker)


def _drop(path):
    try:
        os.remove(path)
    except OSError:
        pass


def pick_review(ref, args):
    """(pr, reviewed sha, findings, remaining args): the current head's review, or the one --sha names."""
    rest, sha = [], None
    it = iter(args)
    for a in it:
        if a == "--sha":
            sha = next(it, "")
        elif a.startswith("--sha="):
            sha = a.split("=", 1)[1]
        else:
            rest.append(a)
    pr = fetch(ref)
    if not pr:
        sys.exit(f"{key(ref)}: could not read the PR from GitHub")
    if sha is not None:
        hit = review_for(pr, sha) if sha else None
        if not hit:
            known = ", ".join(k[:7] for k in pr.get("reviews", {})) or "none"
            sys.exit(f"{key(ref)}: no single Clanky review matches --sha {sha!r} (reviews on: {known})")
        return pr, hit[0], hit[1], rest
    if not review_current(pr):
        sys.exit(f"{key(ref)}: no Clanky review for the current head yet; run wait first, "
                 f"or answer an earlier head's review with --sha <reviewed head>")
    return pr, pr["review_sha"], pr["findings"], rest


def cmd_dispose(args):
    ref = resolve_or_die(args[0])
    pr, sha, findings, items = pick_review(ref, args[1:])
    titles = dict(findings)
    rows = []
    for item in items:
        m = re.match(r"^(\d+)=([\w-]+):\s*(.+)$", item, re.DOTALL)
        if not m or m.group(2) not in DISPOSITIONS or len(m.group(3).strip()) < 3:
            sys.exit(f"bad item {item!r}: want N=<{'|'.join(DISPOSITIONS)}>:<a real one-line reason>")
        n = int(m.group(1))
        if n not in titles:
            sys.exit(f"{key(ref)}: the review has no finding {n}")
        rows.append({"ts": time.time(), "pr": key(ref), "sha": sha, "n": n,
                     "finding": titles[n], "disposition": m.group(2), "reason": m.group(3).strip()})
    os.makedirs(STATE, exist_ok=True)
    with open(ledger_path(), "a") as f:
        for row in rows:
            f.write(json.dumps(row) + "\n")
    return cmd_summary(args[:1] + ([f"--sha={sha}"] if sha != pr.get("review_sha") else []))


def cmd_summary(args):
    ref = resolve_or_die(args[0])
    pr, sha, findings, _ = pick_review(ref, args[1:])
    done = dispositions(ref, sha)
    print(f"{key(ref)} · Clanky on {sha} · {len(findings)} finding(s)")
    for n, t in findings:
        d = done.get(n)
        print(f"  {n}. {t} · " + (f"{d[0]}: {d[1]}" if d else "OPEN"))
    return 0


def warn_log(action):
    """Record this fire in the hook ledger. Telemetry never gets to break the hook."""
    try:
        subprocess.run(["bash", os.path.expanduser("~/.claude/scripts/hooks/warn-log.sh"), "--hook", "pr-review", "--action", action],
                       capture_output=True, timeout=5)
    except (OSError, subprocess.SubprocessError):
        pass


def main():
    argv = sys.argv[1:]
    mode = argv[0] if argv else ""
    if mode in ("wait", "dispose", "summary"):
        if len(argv) < 2:
            sys.exit(__doc__)
        return {"wait": cmd_wait, "dispose": cmd_dispose, "summary": cmd_summary}[mode](argv[1:])
    if mode not in ("track", "stop"):
        sys.exit(__doc__)
    if muted():
        return 0
    # A headless run that opened a PR still owes its findings, so only a keep-warm ping is excused.
    if mode == "stop" and not hookpop.should_run("no-wake"):
        return 0
    try:
        inp = json.load(sys.stdin)
    except ValueError:
        return 0
    try:
        (cmd_track if mode == "track" else cmd_stop)(inp)
    except Exception as e:  # a hook must never wedge the session
        print(f"pr-review-gate: {e}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
