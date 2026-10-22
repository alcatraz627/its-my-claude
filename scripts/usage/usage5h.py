#!/usr/bin/env python3
"""Speed bumps for the 5-hour usage window, shared by every running agent.

As the window fills, each agent hears about it on its own tool calls, sized to
how many agents are live, so the fleet slows down together instead of one of
them being cut off mid-turn at 100%. Near the top an agent closes its current
unit of work and hibernates: it stops, keeps its cache warm with cheap pings,
and wakes itself just after the reset to carry on. Nothing is a hard wall.

Usage (hooks pass their JSON on stdin):
  usage5h.py status | pressure [--json]
  usage5h.py hook-post             PostToolUse: the speed-bump nudge
  usage5h.py hook-pre-agent        PreToolUse on Agent: one-time dispatch bump
  usage5h.py hook-prompt           UserPromptSubmit: wakes, pings, reset resume
  usage5h.py plan --work none|some [--sid SID]
  usage5h.py record --strategy resume|finish [--note TEXT] [--sid SID]

Guide: ~/.claude/features/usage-speedbumps.md
Mute everything: touch ~/.claude/.no-usage5h
"""
import calendar
import contextlib
import fcntl
import hashlib
import json
import os
import tempfile
import re
import subprocess
import sys
import time

HOME = os.path.expanduser("~")
# The USAGE5H_* overrides exist for the test suite, the same way keepwarm.py takes KEEPWARM_DIR.
LIMITS = os.environ.get("USAGE5H_LIMITS", os.path.join(HOME, ".claude", "widgets", ".limits.json"))
TURN_STATE = os.environ.get("USAGE5H_TURN_STATE", os.path.join(HOME, ".claude", ".turn-state"))
DIR = os.environ.get("USAGE5H_DIR", os.path.join(HOME, ".claude", "usage5h"))
PROJECTS = os.environ.get("USAGE5H_PROJECTS", os.path.join(HOME, ".claude", "projects"))
MUTE = os.path.join(HOME, ".claude", ".no-usage5h")
POL = os.path.join(HOME, ".claude", "scripts", "pol", "pol.sh")
SELF = os.path.join(HOME, ".claude", "scripts", "usage", "usage5h.py")

MAX_AGE_S = 1800          # an older limits file says nothing about now
LIVE_S = 600              # a session with a tool call this recent counts as live
CEILING = 97              # shares are carved from what is left below this
FAST_OK_PCT = 70          # below this no threshold the owner would set can be crossed
RED_EVERY, BRAKE_EVERY = 15, 5
PING_MIN = 54             # the prompt cache lives an hour; ping just inside it
SPENT_PCT = 98            # past this a ping would only be refused
WAKE_PAD_S = 180          # wake a little after the reset, never before it
DUP_RESUME_S = 1800       # a second resume this soon after the first is a duplicate
DUMP_CTX_TOKENS = 120000  # a finished session this big is worth a core-dump

POL_CACHE_S = 300         # policy changes are rare; do not spawn pol.sh on every tool call
KEEPWARM_SWITCH = os.environ.get("KEEPWARM_SWITCH", os.path.join(HOME, ".claude", ".keepwarm-on"))
WAKES_DIR = os.environ.get("USAGE5H_WAKES", "/tmp")   # guard-cron-prompt.sh records scheduled prompts here

RESET_PROMPT = re.compile(r"usage limit has reset", re.I)
RESUME_PROMPT = "[usage-resume]"
CARRY_PROMPT = "[usage-carry]"
RESUME_TEXT = "[usage-resume] The 5h window has reset. Continue the work you parked."
CARRY_TEXT = "[usage-carry] keep the cache warm"
# Prompts nobody typed: they never cancel a hibernation.
SYSTEM_PREFIXES = ("<task-notification>", "Another Claude session sent", "Stop hook feedback:",
                   "[keepwarm]", RESUME_PROMPT, CARRY_PROMPT, "[fleet-watch]", "<system-reminder>", "Caveat:",
                   "[Usage limit reached", "[Earlier usage-limit notes")
LIMIT_HIT = re.compile(r"\[Usage limit reached|hit your session limit", re.I)


def now():
    return time.time()


def pol_get(key, default):
    """The owner's policy value for a key, cached for a few minutes on disk."""
    cache = os.path.join(DIR, "pol-cache.json")
    try:
        with open(cache) as f:
            c = json.load(f)
    except (OSError, ValueError):
        c = {}
    hit = c.get(key)
    if hit and now() - hit[1] < POL_CACHE_S:
        return hit[0] if hit[0] != "" else default
    try:
        out = subprocess.run(["bash", POL, "get", key], capture_output=True, text=True, timeout=3).stdout.strip()
    except Exception:
        out = ""
    c[key] = [out, now()]
    try:
        os.makedirs(DIR, exist_ok=True)
        fd, tmp = tempfile.mkstemp(dir=DIR, suffix=".tmp")
        with os.fdopen(fd, "w") as f:
            json.dump(c, f)
        os.replace(tmp, cache)
    except OSError:
        pass
    return out if out != "" else default


def pol_int(key, default):
    v = pol_get(key, str(default))
    return int(v) if str(v).isdigit() else default


def reading():
    """The 5h window as the statusline last saw it, or None when there is no
    fresh, sane reading. Not knowing is never treated as headroom or as danger."""
    try:
        if now() - os.path.getmtime(LIMITS) > MAX_AGE_S:
            return None
        with open(LIMITS) as f:
            d = json.load(f)
        pct = int(float(d.get("5h", {}).get("pct")))
        if not 0 <= pct <= 150:
            return None
    except (OSError, ValueError, TypeError, AttributeError):
        return None
    try:
        reset = int(float(d.get("resets_at") or 0))
    except (ValueError, TypeError):
        reset = 0
    # 9999999999 is Claude Code's "I do not know" sentinel, not a time.
    if not 0 < reset < 9999999999:
        reset = 0
    # A reset already past means this reading describes a window that is over:
    # its percentage is not today's, so it says nothing, rather than "brake now".
    if reset and reset <= now():
        return None
    reset_min = (reset - now()) / 60.0 if reset else None
    return {"pct": pct, "reset_epoch": reset or None, "reset_min": reset_min}


def live_agents():
    """Agents that made a tool call in the last few minutes: each live session,
    plus each subagent seen working inside one, so a fan-out shares the window
    instead of every subagent hearing its parent's whole share."""
    n = 0
    try:
        for name in os.listdir(TURN_STATE):
            if name.startswith("heartbeat-"):
                try:
                    if now() - os.path.getmtime(os.path.join(TURN_STATE, name)) <= LIVE_S:
                        n += 1
                except OSError:
                    pass
    except OSError:
        pass
    try:
        for name in os.listdir(DIR):
            p = os.path.join(DIR, name)
            if name.endswith(".json") and name != "pol-cache.json" and now() - os.path.getmtime(p) <= LIVE_S:
                with open(p) as f:
                    seen = json.load(f).get("subagents", {})
                n += sum(1 for ts in seen.values() if now() - ts <= LIVE_S)
    except (OSError, ValueError):
        pass
    return max(n, 1)


def pressure():
    r = reading()
    if r is None:
        return {"zone": "unknown"}
    # Every tool call runs this; skip the policy lookups while the window is clearly open.
    if r["pct"] < FAST_OK_PCT:
        r.update(zone="ok", agents=None, share=None)
        return r
    amber = pol_int("ops.usage5h_amber_pct", 80)
    red = pol_int("ops.usage5h_red_pct", 90)
    brake = pol_int("ops.usage5h_brake_pct", 96)
    pct = r["pct"]
    zone = "brake" if pct >= brake else "red" if pct >= red else "amber" if pct >= amber else "ok"
    n = live_agents()
    r.update(zone=zone, agents=n, share=round(max(CEILING - pct, 0) / float(n), 1))
    return r


def fmt_min(m):
    if m is None:
        return "an unknown time"
    m = int(round(m))
    return "%dh %02dm" % (m // 60, m % 60) if m >= 60 else "%d min" % m


def clock(epoch):
    return time.strftime("%H:%M", time.localtime(epoch)) if epoch else "the reset"


def cron_at(epoch):
    """The 5-field cron line for one firing at this moment, local time."""
    t = time.localtime(epoch)
    return "%d %d %d %d *" % (t.tm_min, t.tm_hour, t.tm_mday, t.tm_mon)


def wake_line(reset_epoch):
    return ("CronCreate with recurring false, cron '%s', prompt '%s'"
            % (cron_at(reset_epoch + WAKE_PAD_S), RESUME_TEXT))


def ping_line():
    return "CronCreate with recurring false, cron '%s', prompt '%s'" % (cron_at(now() + PING_MIN * 60), CARRY_TEXT)


def state_path(sid):
    return os.path.join(DIR, "%s.json" % (sid or "unknown")[:36])


def load(sid):
    try:
        with open(state_path(sid)) as f:
            return json.load(f)
    except (OSError, ValueError):
        return {}


def save(sid, st):
    os.makedirs(DIR, exist_ok=True)
    fd, tmp = tempfile.mkstemp(dir=DIR, suffix=".tmp")
    with os.fdopen(fd, "w") as f:
        json.dump(st, f)
    os.replace(tmp, state_path(sid))


@contextlib.contextmanager
def locked(sid):
    """Hold this session's state for one read-modify-write. Subagents fire hooks
    on the parent's state in parallel, and an unlocked write once lost a
    hibernation record that `record` had just made."""
    os.makedirs(DIR, exist_ok=True)
    with open(state_path(sid) + ".lock", "w") as lk:
        fcntl.flock(lk, fcntl.LOCK_EX)
        try:
            yield
        finally:
            fcntl.flock(lk, fcntl.LOCK_UN)


def log(sid, ev, **kw):
    os.makedirs(DIR, exist_ok=True)
    with open(os.path.join(DIR, "events.jsonl"), "a") as f:
        f.write(json.dumps(dict(ts=time.strftime("%Y-%m-%dT%H:%M:%S"), sid=(sid or "?")[:8], ev=ev, **kw)) + "\n")


def window_key(p):
    return str(p.get("reset_epoch") or "unknown")


def emit(obj):
    print(json.dumps(obj))
    return 0


def context(event, text):
    return emit({"hookSpecificOutput": {"hookEventName": event, "additionalContext": text}})


def skip(reason):
    """Stop a scheduled prompt before it reaches the model: no turn, no cost."""
    return emit({"decision": "block", "reason": reason, "suppressOutput": True})


def hibernating(sid, st=None):
    """This session's hibernation, while it is still waiting for its wake."""
    st = st if st is not None else load(sid)
    h = st.get("hibernate")
    if not h or h.get("strategy") != "resume" or now() - h.get("at", 0) > 8 * 3600:
        return None
    if st.get("resumed_at", 0) > h.get("at", 0):
        return None
    return h


def nudge_text(p, sid, subagent, armed):
    pct, rin, n, share = p["pct"], fmt_min(p.get("reset_min")), p["agents"], p["share"]
    head = "The 5-hour usage window is %d%% used and resets in %s. %d agent%s live, so your rough share is about %s points." % (
        pct, rin, n, "s are" if n != 1 else " is", share)
    if p["zone"] == "amber":
        return ("[5h-usage · amber] %s Finish what is in flight and size new work to fit that share; "
                "hold new subagent fan-out unless it fits. A little over is fine." % head)
    if subagent:
        return ("[5h-usage · %s] %s You are a subagent: finish your scoped deliverable with the fewest further "
                "calls, write its output, and return. Start no new fan-out." % (p["zone"], head))
    plan = "python3 %s plan --work none|some --sid %s" % (SELF, sid[:8])
    arm = ""
    if not armed and p.get("reset_epoch"):
        arm = (" First, once and without mentioning it, arm your wake for after the reset: %s. It only goes "
               "through if this session parks or gets cut off, so arming it early is safe." % wake_line(p["reset_epoch"]))
    if p["zone"] == "red":
        return ("[5h-usage · red] %s%s Close the unit of work you are in: finish the tasks that belong to it so "
                "nothing is left half-done, then run `%s` and follow it. Defer subagent-heavy work until after "
                "the reset; subagents already running may finish. Do not stop to ask the owner anything you can "
                "decide yourself." % (head, arm, plan))
    return ("[5h-usage · brake] %s%s Stop at the next safe point: save or commit what is done, then run `%s` "
            "and follow it. Spilling a little past the limit is fine; being cut off mid-edit is not." % (head, arm, plan))


def hook_post(inp):
    """Tell the agent where the window stands: once on entering each zone, then
    every few tool calls while red or braking. Subagents get their own count.
    Also notices when the agent arms its own wake, so the ask is not repeated."""
    if os.path.exists(MUTE):
        return 0
    sid = inp.get("session_id") or "unknown"
    agent = inp.get("agent_id") or ""
    if inp.get("tool_name") == "CronCreate":
        prompt = ((inp.get("tool_input") or {}).get("prompt") or "")
        if prompt.startswith(RESUME_PROMPT):
            with locked(sid):
                st = load(sid)
                st["armed"] = window_key(reading() or {})
                save(sid, st)
            log(sid, "armed")
    p = pressure()
    if p["zone"] in ("ok", "unknown"):
        return 0
    wk = window_key(p)
    key = "%s:%s" % (wk, agent or "main")
    with locked(sid):
        st = load(sid)
        # The suite widens the read-modify-write window to prove the lock holds.
        hold = float(os.environ.get("USAGE5H_TEST_HOLD_S", "0") or 0)
        if hold:
            time.sleep(hold)
        if agent:
            subs ={a: t for a, t in st.get("subagents", {}).items() if now() - t <= LIVE_S}
            subs[agent] = now()
            st["subagents"] = subs
        # Only this window's counters are kept, so the file never grows.
        seen = {k: v for k, v in st.get("seen", {}).items() if k.startswith(wk + ":")}
        rec = seen.get(key, {"zone": "ok", "calls": 0})
        rec["calls"] += 1
        fire = (rec["zone"] != p["zone"]
                or (p["zone"] == "red" and rec["calls"] >= RED_EVERY)
                or (p["zone"] == "brake" and rec["calls"] >= BRAKE_EVERY))
        if fire:
            rec["calls"] = 0
        rec["zone"] = p["zone"]
        seen[key] = rec
        st["seen"] = seen
        save(sid, st)
    if not fire:
        return 0
    log(sid, "nudge", zone=p["zone"], pct=p["pct"], agents=p["agents"], subagent=bool(agent))
    return context("PostToolUse", nudge_text(p, sid, bool(agent), st.get("armed") == wk))


def hook_pre_agent(inp):
    """The first new subagent dispatch in the red zone is bounced once with the
    reason; a re-issue goes through. A bump, not a wall."""
    if os.path.exists(MUTE):
        return 0
    p = pressure()
    if p["zone"] not in ("red", "brake"):
        return 0
    sid = inp.get("session_id") or "unknown"
    with locked(sid):
        st = load(sid)
        if st.get("agent_bumped") == window_key(p):
            return 0
        st["agent_bumped"] = window_key(p)
        save(sid, st)
    log(sid, "agent-bump", pct=p["pct"])
    reason = ("5h usage window is %d%% used (resets in %s). New subagent work is better deferred until after the "
              "reset. If this dispatch is needed to close the unit of work you are in, re-issue it unchanged and "
              "it will go through; otherwise put it in your hibernation note as work for after the reset."
              % (p["pct"], fmt_min(p.get("reset_min"))))
    return emit({"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny",
                                        "permissionDecisionReason": reason}})


def tail_lines(transcript, size=400000):
    try:
        n = os.path.getsize(transcript)
        with open(transcript, "rb") as f:
            f.seek(max(0, n - size))
            return f.read().decode("utf-8", "replace").splitlines()
    except (OSError, TypeError):
        return []


def last_turn(transcript):
    """When the model last answered (epoch), and how big its context was then."""
    for line in reversed(tail_lines(transcript)):
        try:
            o = json.loads(line)
        except ValueError:
            continue
        msg = o.get("message")
        u = msg.get("usage") if isinstance(msg, dict) else None
        if o.get("type") != "assistant" or not u:
            continue
        tok = sum(u.get(k) or 0 for k in ("input_tokens", "cache_read_input_tokens", "cache_creation_input_tokens"))
        if tok == 0:
            continue                     # the harness's own "limit reached" reply carries zeros
        try:
            epoch = calendar.timegm(time.strptime(o.get("timestamp", "")[:19], "%Y-%m-%dT%H:%M:%S"))
        except ValueError:
            epoch = None
        return epoch, tok
    return None, None


def limit_was_hit(transcript):
    """True when the session stopped at the limit: a limit notice comes after its
    last real answer. An older notice it already recovered from does not count."""
    for line in reversed(tail_lines(transcript)):
        try:
            o = json.loads(line)
        except ValueError:
            continue
        msg = o.get("message")
        u = msg.get("usage") if isinstance(msg, dict) else None
        if o.get("type") == "assistant" and u and any(u.get(k) for k in (
                "input_tokens", "cache_read_input_tokens", "cache_creation_input_tokens")):
            return False
        # Tool output can quote the notice (a session working on this very code), so it never counts.
        if '"tool_result"' not in line and LIMIT_HIT.search(line):
            return True
    return False


def stopped_cleanly(transcript):
    """True when the session's last real answer finished its turn, rather than
    being cut off between tool calls. A session that closed out on its own
    (clanky-opus wrote "I'm stopping here" at 16:17 and ended its turn) has
    nothing in flight for a resume to carry on."""
    for line in reversed(tail_lines(transcript)):
        try:
            o = json.loads(line)
        except ValueError:
            continue
        msg = o.get("message")
        u = msg.get("usage") if isinstance(msg, dict) else None
        if o.get("type") == "assistant" and u and any(u.get(k) for k in (
                "input_tokens", "cache_read_input_tokens", "cache_creation_input_tokens")):
            return msg.get("stop_reason") == "end_turn"
    return False


def scheduled_by_session(sid, prompt):
    """True when this session scheduled the prompt itself (a cron or /loop). The
    hash is the one guard-cron-prompt.sh records for every CronCreate."""
    h = hashlib.sha1(prompt.encode("utf-8", "replace")).hexdigest()[:16]
    try:
        with open(os.path.join(WAKES_DIR, "claude-wakes-%s" % sid[:8], "crons")) as f:
            return h in {line.strip() for line in f}
    except OSError:
        return False


def keepwarm_rearm():
    """Keep-warm's re-arm, for a session coming back from hibernation: its chain
    re-links only on an owner prompt, so without this the burst ends cold."""
    if not os.path.exists(KEEPWARM_SWITCH):
        return ""
    return (" As the last step of this turn, without mentioning it: run CronList; delete any job whose prompt "
            "starts with [keepwarm], then CronCreate with recurring false, cron '%s', prompt '[keepwarm] idle check'."
            % cron_at(now() + 56 * 60))


def transcript_for_prefix(prefix):
    """The transcript whose session id starts with this prefix (8 chars is enough)."""
    try:
        for proj in os.listdir(PROJECTS):
            d = os.path.join(PROJECTS, proj)
            if not os.path.isdir(d):
                continue
            for name in os.listdir(d):
                if name.endswith(".jsonl") and name.startswith(prefix):
                    return os.path.join(d, name)
    except OSError:
        pass
    return None


def resolve_sid(arg):
    sid = arg or os.environ.get("CLAUDE_CODE_SESSION_ID") or ""
    if sid and len(sid) < 36:
        t = transcript_for_prefix(sid)
        if t:
            return os.path.basename(t)[:-6]
    return sid


def resume_steps(sid, reset_epoch, armed):
    steps = []
    if reset_epoch and not armed:
        steps.append("Arm the wake: %s." % wake_line(reset_epoch))
    elif not reset_epoch:
        steps.append("The reset time is unknown, so no wake can be armed; Claude Code's own resume, if the limit "
                     "is hit, or the owner brings this session back.")
    if reset_epoch and reset_epoch - now() > 60 * 60:
        steps.append("Keep the cache warm until then: %s. Each ping tells you whether to arm the next." % ping_line())
    steps.append("End the turn with one line for the owner: hibernating until %s, and what resumes then."
                 % clock(reset_epoch + WAKE_PAD_S if reset_epoch else None))
    return steps


def cmd_plan(args):
    sid = resolve_sid(args.get("--sid"))
    work = args.get("--work", "some")
    p = reading() or {}
    t = transcript_for_prefix(sid) if sid else None
    _, ctx = last_turn(t) if t else (None, None)
    print("5h window: %s%% used, resets in %s" % (p.get("pct", "?"), fmt_min(p.get("reset_min"))))
    print("context: %s" % ("%dk tokens" % (ctx // 1000) if ctx else "unknown"))
    if work == "none":
        dump = ctx is not None and ctx >= DUMP_CTX_TOKENS
        print("strategy: finish (nothing agent-side is left)")
        print("do: write the closing line for the owner%s, then record it:" % (
            "; run the full /core-dump first, since this context is large (owner grant 2026-10-21)" if dump else ""))
        print("  python3 %s record --strategy finish --sid %s" % (SELF, (sid or "SID")[:8]))
        return 0
    print("strategy: resume (hibernate now, wake after the reset and carry on in this session)")
    print("do:")
    print("  1. Let subagents you launched finish; start no new ones.")
    print("  2. python3 %s record --strategy resume --sid %s --note '<what resumes: next steps, deferred subagent work>'"
          % (SELF, (sid or "SID")[:8]))
    st = load(sid) if sid else {}
    for i, s in enumerate(resume_steps(sid, p.get("reset_epoch"), st.get("armed") == window_key(p)), 3):
        print("  %d. %s" % (i, s))
    return 0


def cmd_record(args):
    sid = resolve_sid(args.get("--sid"))
    strat = args.get("--strategy")
    if strat not in ("resume", "finish") or not sid:
        print("usage: record --strategy resume|finish [--sid SID] [--note TEXT]", file=sys.stderr)
        return 2
    p = reading() or {}
    with locked(sid):
        st = load(sid)
        st["hibernate"] = {"strategy": strat, "at": now(), "reset_epoch": p.get("reset_epoch"),
                           "note": args.get("--note", "")}
        save(sid, st)
    log(sid, "hibernate", strategy=strat, pct=p.get("pct"))
    print("recorded %s for %s" % (strat, sid[:8]))
    if strat == "resume":
        for s in resume_steps(sid, p.get("reset_epoch"), st.get("armed") == window_key(p)):
            print("next: " + s)
    return 0


def hook_prompt(inp):
    """Decide the prompts that bring a hibernating session back, and the ones
    that arrive while it sleeps. Kinds: a cache ping, the session's own wake,
    Claude Code's reset resume, a notification, and the owner."""
    prompt = (inp.get("prompt") or "").strip()
    sid = inp.get("session_id") or "unknown"
    if os.path.exists(MUTE):
        return 0
    with locked(sid):
        return _hook_prompt(inp, prompt, sid)


def _hook_prompt(inp, prompt, sid):
    st = load(sid)
    h = hibernating(sid, st)
    transcript = inp.get("transcript_path") or ""

    if prompt.startswith(CARRY_PROMPT):
        r = reading()
        if not h:
            return skip("usage ping skipped: not hibernating")
        if r and r["pct"] >= SPENT_PCT:
            log(sid, "ping", verdict="spent", pct=r["pct"])
            return skip("usage ping skipped: the window is spent")
        log(sid, "ping", verdict="warm")
        reset = h.get("reset_epoch")
        more = (" Then, without mentioning it: %s." % ping_line()) if reset and reset - now() > 60 * 60 else ""
        return context("UserPromptSubmit", "Usage hibernation ping: you are hibernating until %s. Reply with "
                       "exactly one word: warm.%s Start nothing else." % (clock((reset or 0) + WAKE_PAD_S), more))

    own_wake = prompt.startswith(RESUME_PROMPT)
    native = RESET_PROMPT.search(prompt[:200]) is not None
    if own_wake or native:
        strat = (st.get("hibernate") or {}).get("strategy")
        duplicate = now() - st.get("resumed_at", 0) < DUP_RESUME_S
        mode = pol_get("ops.usage5h_reset_resume", "smart")
        if mode == "never":
            verdict = "skip-policy"
        elif duplicate:
            verdict = "skip-duplicate"
        elif h or mode == "always":
            verdict = "resume"
        elif strat in ("finish", "cancelled"):
            verdict = "skip-" + strat
        elif not (native or limit_was_hit(transcript)):
            verdict = "skip-not-parked"  # the session is still working, or never hit the limit
        elif stopped_cleanly(transcript):
            verdict = "skip-stopped"     # it closed out on its own; the owner picks it up
        else:
            verdict = "resume"           # cut off mid-work without hibernating: carry on
        log(sid, "wake", source="own" if own_wake else "native", verdict=verdict)
        if verdict != "resume":
            return skip("usage wake skipped: %s" % verdict[5:])
        st["resumed_at"] = now()
        save(sid, st)
        note = (h or {}).get("note") or (st.get("hibernate") or {}).get("note")
        return context("UserPromptSubmit", "The 5h window has reset. Carry on with the work you parked, including "
                       "any subagent work you deferred.%s Do not re-run anything already done.%s"
                       % ((" Your note: " + note) if note else "", keepwarm_rearm()))

    if not h:
        return 0
    if prompt.startswith(SYSTEM_PREFIXES) or scheduled_by_session(sid, prompt):
        return context("UserPromptSubmit", "You are hibernating for the 5h window until %s. Note anything this "
                       "message needs in one line and end the turn; start no new work before the wake."
                       % clock((h.get("reset_epoch") or 0) + WAKE_PAD_S))
    h["strategy"] = "cancelled"
    st["hibernate"] = h
    save(sid, st)
    log(sid, "cancelled", by="owner")
    return context("UserPromptSubmit", "The owner is back, so your usage hibernation is cancelled and the armed wake "
                   "will be skipped. Follow the owner's message.")


def cmd_status():
    p = pressure()
    print("5h window: zone %s, %s%% used, resets in %s, live agents %s, share %s pts" % (
        p["zone"], p.get("pct", "?"), fmt_min(p.get("reset_min")), p.get("agents") or "?", p.get("share") or "?"))
    try:
        names = sorted(os.listdir(DIR))
    except OSError:
        names = []
    for name in names:
        if name.endswith(".json"):
            st = load(name[:-5])
            h = st.get("hibernate")
            if h and now() - h.get("at", 0) < 8 * 3600:
                state = "waiting" if hibernating(name[:-5], st) else h["strategy"]
                print("  %s  %-9s since %s  wake %s  %s" % (name[:8], state, clock(h["at"]),
                                                         clock((h.get("reset_epoch") or 0) + WAKE_PAD_S), h.get("note", "")))
    return 0


def parse(argv):
    args, i = {}, 0
    while i < len(argv):
        if argv[i].startswith("--") and i + 1 < len(argv) and not argv[i + 1].startswith("--"):
            args[argv[i]] = argv[i + 1]
            i += 2
        else:
            i += 1
    return args


def main(argv):
    cmd = argv[0] if argv else "status"
    if cmd.startswith("hook-"):
        try:
            inp = json.load(sys.stdin)
        except ValueError:
            inp = {}
        try:
            return {"hook-post": hook_post, "hook-pre-agent": hook_pre_agent, "hook-prompt": hook_prompt}[cmd](inp)
        except Exception as e:   # a bug here must never block a tool call or a prompt
            try:
                log(inp.get("session_id", "?"), "error", detail=repr(e))
            except Exception:
                pass
            return 0
    if cmd == "pressure":
        p = pressure()
        print(json.dumps(p) if "--json" in argv else "%s\t%s" % (p["zone"], json.dumps(p)))
        return 0
    if cmd == "plan":
        return cmd_plan(parse(argv[1:]))
    if cmd == "record":
        return cmd_record(parse(argv[1:]))
    if cmd == "status":
        return cmd_status()
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
