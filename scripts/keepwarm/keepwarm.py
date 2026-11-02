#!/usr/bin/env python3
"""Keep-warm: keep an idle Claude session's prompt cache alive while the owner
is away, and write its checkpoint while the cache is still warm.

A recurring in-session job sends "[keepwarm] idle check" every 20 minutes, and
next_step() decides each fire from plain numbers. A fire with nothing to do is
blocked before the model runs, so it costs no tokens and leaves a line or two in
the terminal. How it behaves and why: ~/.claude/features/keepwarm.md

Revert to the older chain of one-shot jobs: touch ~/.claude/.keepwarm-oneshot

Usage (hooks pass their JSON on stdin):
  keepwarm.py hook-start | hook-prompt | hook-stop
  keepwarm.py away 3h|21:30|done|soon [--soft] [why]
  keepwarm.py plan
  keepwarm.py status [--json]
On/off for every session: ~/.claude/.keepwarm-on (present = on).
"""
import datetime as dt
import glob
import json
import os
import re
import subprocess
import sys
import time

HOME = os.path.expanduser("~")
DIR = os.environ.get("KEEPWARM_DIR", os.path.join(HOME, ".claude", "keepwarm"))
SWITCH = os.environ.get("KEEPWARM_SWITCH", os.path.join(HOME, ".claude", ".keepwarm-on"))
EVENTS = os.path.join(DIR, "events.jsonl")
# The prompt cache lives one hour; wake just before it lapses.
DUE_MIN = float(os.environ.get("KEEPWARM_DUE_MIN", "55"))
PREFIX = "[keepwarm]"
WAKE_PROMPT = "[keepwarm] idle check"
# A one-shot cron is pinned to a minute; firing a little late is harmless, a
# little early would find the session not yet due, so pad by one minute.
ARM_PAD_S = 60
USAGE_GATE = os.path.join(HOME, ".claude", "scripts", "cron", "usage-gate.sh")
USAGE5H = os.path.join(HOME, ".claude", "scripts", "usage", "usage5h.py")
RESOLVE_STORE = os.path.join(HOME, ".claude", "scripts", "task-table", "resolve-store.sh")
# Prompts that reach the session without the owner typing them. They are not the
# owner coming back: Claude Code's own resume after a usage-limit reset once got
# a re-arm and a one-word "warm" reply on a cache it had just rebuilt cold
# (clanky-opus, 2026-10-21).
NOT_OWNER = ("<task-notification>", "Another Claude session sent", "Stop hook feedback:", "[usage-carry]",
             "[usage-resume]", "[fleet-watch]")
LIMIT_RESET = re.compile(r"usage limit has reset", re.I)

# The upkeep for wake 1, 2, ..., by context USED; the last wake writes a full
# core-dump and keep-warm stops. With wakes 55 min apart a small session stays
# warm about 3.5 hours, a large one about 2.75; either way the owner can return
# inside 2.5 hours for free, and later finds a dump instead of a cold cache.
LARGE_PCT = 50
# The sessions here run with the 1M-token window; only the fallback reading uses this.
CTX_WINDOW = float(os.environ.get("KEEPWARM_CTX_WINDOW", "1000000"))
PLAN = {
    "small": ["warm", "warm", "dump"],
    "large": ["warm", "dump"],
}
# Above this share of the 5h window a full dump might not finish, so write a short
# one that says how to build the full one later.
MINI_PCT = 95
# The window is gone at this point: Claude Code refuses the turn outright.
REFUSED_PCT = 100
# A wake while the window is this full comes sooner, so a sudden jump in usage from
# other sessions cannot carry it straight past the point where a dump still fits.
TIGHT_PCT = 85
TIGHT_REARM_MIN = 25
# A cached warm-up costs about 0.75 of a point of the window (measured 2026-10-22).
PING_COST_PCT = 0.75
WINDOW_MIN = 300
PACE_CHECK_PCT = 85
# Do not checkpoint a session out from under someone who was just typing in it.
OWNER_NEARBY_MIN = 15
ONESHOT = os.environ.get("KEEPWARM_ONESHOT_FILE", os.path.join(HOME, ".claude", ".keepwarm-oneshot"))
CADENCE_MIN = int(os.environ.get("KEEPWARM_CADENCE_MIN", "20"))
# A fire at this cache age or older pings, so with fires 20 minutes apart a ping
# always lands before the 1 hour cache lapses.
WARM_DUE_MIN = float(os.environ.get("KEEPWARM_WARM_DUE_MIN", "40"))
# A recurring job expires after 7 days; replace it a little before that.
JOB_LIFE_S = 6.5 * 86400
# How many times a session's Stop hook re-asks for a job the model has not created.
MAX_ARM_ASKS = 3
WAKE_DIR = os.environ.get("KEEPWARM_WAKE_DIR", "/tmp")
# Past this the cache has already lapsed (usually a sleeping laptop), so a ping would
# pay to rebuild it for nobody.
COLD_CACHE_MIN = float(os.environ.get("KEEPWARM_COLD_CACHE_MIN", "65"))
MAX_PINGS = 6
# Break-even, in cached-read tokens. A /catchup start measures 153k (median of 60
# sessions) at the 1 hour write price of 20 reads. Friction is what avoiding one is
# worth to the owner, the single knob for how eagerly sessions are held.
CATCHUP_COST = 153000 * 20
FRICTION = float(os.environ.get("KEEPWARM_FRICTION", 3e6))
# The cold-session gate.
COLD_GATE_MUTE = os.environ.get("KEEPWARM_COLD_GATE_MUTE", os.path.join(HOME, ".claude", ".no-cold-gate"))
COLD_MIN = float(os.environ.get("KEEPWARM_COLD_MIN", "60"))
COLD_TOKENS = float(os.environ.get("KEEPWARM_COLD_TOKENS", "100000"))
COLD_CONFIRM_S = 10 * 60
CHECKPOINT_INDEX = os.environ.get("KEEPWARM_CHECKPOINTS", os.path.join(HOME, ".claude", "checkpoints", "index.jsonl"))
# Commands that never reach the model, so they have nothing to rebuild.
LOCAL_COMMANDS = ("/clear", "/exit", "/quit", "/resume", "/help", "/status", "/config", "/model", "/login", "/logout",
                  "/cost", "/usage", "/fast", "/effort", "/hooks", "/mcp", "/permissions", "/plugin", "/doctor",
                  "/rewind", "/theme", "/vim", "/keybindings", "/agents", "/bug", "/feedback")
RETURN_MODEL = os.path.join(os.path.dirname(os.path.abspath(__file__)), "return_model.py")
MODEL_MAX_AGE_S = 7 * 86400
UPKEEP = {
    "warm": ("Keep-warm wake {n}: the owner is away and this turn only keeps the cache warm. "
             "Reply with exactly one word: warm. Start nothing else."),
    "dump": ("Keep-warm wake {n}, the last: the owner is away and the cache is still warm. Run the "
             "full /core-dump now (not mini), so the owner can /clear and /catchup later instead "
             "of paying a cold cache. Close with its Phase 4 dump box in a code fence, the two "
             "copy lines under it included, and nothing else. Start nothing else. Keep-warm "
             "stops here until the owner returns."),
    "mini": ("Keep-warm wake {n}, the last: the owner is away and the 5h usage window is nearly gone ({pct}% used), "
             "so a full dump may not fit. Run /core-dump mini now. Under its Resume line add this line, filling in "
             "the session id: **Build the full dump:** after the window resets, resume this session and say "
             "\"dump again\" to get the full /core-dump, or run /retro-dump on <session id> if it was closed. "
             "Close with its dump box in a code fence and nothing else. Start nothing else. Keep-warm stops here "
             "until the owner returns."),
    "dump-hold": ("Keep-warm wake {n}: the owner said they will be back later, but the usage window may not last until "
                  "then. Run the full /core-dump now (not mini) so a record exists. Close with its Phase 4 dump box in "
                  "a code fence and nothing else. Start nothing else. Keep-warm carries on if the window allows."),
}
DELETE_JOB = (" Before the dump, without mentioning it: run CronList and CronDelete any job whose prompt starts "
              "with [keepwarm].")


def now_s():
    return time.time()


def state_path(sid):
    return os.path.join(DIR, "%s.json" % sid)


def load(sid):
    try:
        with open(state_path(sid)) as f:
            return json.load(f)
    except (OSError, ValueError):
        return {"last_activity": now_s(), "wakes": 0, "stopped": False}


def save(sid, st):
    os.makedirs(DIR, exist_ok=True)
    tmp = state_path(sid) + ".tmp"
    with open(tmp, "w") as f:
        json.dump(st, f)
    os.replace(tmp, state_path(sid))


def log(sid, ev, **kw):
    os.makedirs(DIR, exist_ok=True)
    with open(EVENTS, "a") as f:
        f.write(json.dumps(dict(ts=dt.datetime.now().isoformat(timespec="seconds"), sid=sid, ev=ev, **kw)) + "\n")


def last_usage(transcript):
    """The token usage of the transcript's most recent model reply, or None."""
    try:
        size = os.path.getsize(transcript)
        with open(transcript, "rb") as f:
            f.seek(max(0, size - 400000))
            lines = f.read().decode("utf-8", "replace").splitlines()
        for line in reversed(lines):
            try:
                o = json.loads(line)
            except ValueError:
                continue
            msg = o.get("message")
            u = msg.get("usage") if isinstance(msg, dict) else None
            if u:
                return u
    except OSError:
        pass
    return None


def judge_ping(usage):
    """Did a keep-warm ping find the cache warm? Warm means the turn read from the
    cache and rewrote under a tenth of what it read; a turn that rebuilt the prefix
    paid full price, so the ping did not keep anything warm."""
    if not usage:
        return "unknown", None, None
    read = usage.get("cache_read_input_tokens") or 0
    create = usage.get("cache_creation_input_tokens") or 0
    return ("warm" if read > 0 and create < 0.1 * read else "cold"), read, create


def context_used_pct(transcript):
    """Context used, in percent. Prefers the statusline's own reading for this
    Claude process; falls back to the last turn's token count over the window."""
    pid = 0 if os.environ.get("KEEPWARM_NO_STATUSLINE") else os.getppid()   # tests: transcript only
    for _ in range(5 if pid else 0):   # the hook may run under a shell; climb to the Claude process
        try:
            with open("/tmp/claude-ctx-%d" % pid) as f:
                return 100.0 - float(f.read().strip())
        except (OSError, ValueError):
            pass
        try:
            pid = int(subprocess.run(["ps", "-o", "ppid=", "-p", str(pid)], capture_output=True,
                                     text=True, timeout=2).stdout.strip() or 0)
        except (ValueError, subprocess.SubprocessError):
            break
        if pid <= 1:
            break
    u = last_usage(transcript)
    if u:
        tok = (u.get("input_tokens") or 0) + (u.get("cache_read_input_tokens") or 0) + \
              (u.get("cache_creation_input_tokens") or 0)
        return 100.0 * tok / CTX_WINDOW
    return 30.0   # unknown: treat as a worked session


def klass(pct):
    return "large" if pct >= LARGE_PCT else "small"


def usage_gated():
    try:
        return subprocess.run(["bash", USAGE_GATE], capture_output=True, timeout=10).returncode == 1
    except Exception:
        return False


def usage5h():
    """The 5h-window module, or None when it cannot be loaded."""
    try:
        import importlib.util
        spec = importlib.util.spec_from_file_location("usage5h", USAGE5H)
        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)
        return mod
    except Exception:
        return None


def window_reading():
    """The 5h window's latest reading plus the point past which a ping is refused, or None."""
    mod = usage5h()
    r = mod.reading() if mod else None
    return dict(r, spent_pct=mod.SPENT_PCT) if r else None


def pending_chains():
    """How many sessions have a keep-warm wake still to come. Each one spends from
    the same window, so they decide together whether any of them gets across."""
    n = 0
    for p in glob.glob(os.path.join(DIR, "*.json")):
        try:
            with open(p) as f:
                st = json.load(f)
        except (OSError, ValueError):
            continue
        if not st.get("stopped") and (st.get("recurring_at") or (st.get("armed_at") or 0) > now_s() - 10 * 60):
            n += 1
    return n


def return_chance(away_min, hour):
    """The chance the owner is back within the hour; the Copernican rule if the model will not load."""
    try:
        import importlib.util
        spec = importlib.util.spec_from_file_location("return_model", RETURN_MODEL)
        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)
        return mod.chance(away_min, hour)
    except Exception:
        return 60.0 / (max(away_min, 1) + 60.0)


def next_step(ctx_tokens, pct, reset_min, spent_pct, gated, wakes, away_min, cache_age_min, hour, hint, now,
              chains, tasks_left, dumped):
    """What a keep-warm fire should do, given plain numbers. Returns (action, why).

    Actions: warm (a one-word turn), dump, mini, wait (blocked, no turn, the job fires
    again), stop (blocked, and finished until the owner returns). Same numbers, same
    answer; nothing here reads a file except the return model.
    """
    holding = bool(hint and (hint.get("until") or 0) > now)
    hard = holding and hint.get("kind") == "hard"
    finish = lambda why: ("stop", why) if dumped else ("dump", why)
    if cache_age_min >= COLD_CACHE_MIN:
        return "stop", "the cache has already gone cold"
    if away_min >= OWNER_NEARBY_MIN:
        reading = {"pct": pct, "reset_min": reset_min, "spent_pct": spent_pct} if pct is not None else None
        forced = window_dump(reading, chains) or ("dump" if gated else None)
        if forced:
            if not dumped:
                return forced, "the usage window will not last"
            if not (hard and forced == "dump"):
                return "stop", "the usage window will not last and a dump exists"
    if hint and hint.get("done"):
        return finish("the owner said they are done")
    if pct is not None and pct >= spent_pct:
        return "wait", "the window is spent"
    if cache_age_min < WARM_DUE_MIN:
        return "wait", "not due"
    if holding:
        return "warm", "holding until the owner's time"
    if tasks_left is False and wakes == 0:
        return finish("everything left is the owner's")
    if wakes >= MAX_PINGS:
        return finish("held as long as it is worth")
    chance = return_chance(away_min, hour)
    if chance * (CATCHUP_COST + FRICTION) > ctx_tokens:
        return "warm", "%.0f%% chance of return in the next hour" % (100 * chance)
    return finish("%.0f%% chance of return in the next hour is not worth a ping on %dk" % (100 * chance, ctx_tokens / 1000))


def local_hour():
    """This laptop's clock, so a timezone change carries over by itself."""
    forced = os.environ.get("KEEPWARM_HOUR")
    if forced:
        return float(forced)
    t = dt.datetime.now()
    return t.hour + t.minute / 60.0


def oneshot_mode():
    return os.path.exists(ONESHOT)


def cron_spec(sid):
    """Each session its own minute, so they do not all fire together."""
    if CADENCE_MIN <= 1:
        return "* * * * *"
    offset = 1 + sum(ord(c) for c in sid) % (CADENCE_MIN - 1)
    return "%d-59/%d * * * *" % (offset, CADENCE_MIN)


def arm_text(sid, st):
    """What the model must do to start the session's job. In one-shot mode, the old re-arm."""
    if oneshot_mode():
        return rearm_text(now_s(), st)
    st["recurring_at"] = now_s()
    st["armed_at"] = now_s() + WARM_DUE_MIN * 60
    st.pop("job_seen", None)
    return ("Arm keep-warm: run CronList; delete any job whose prompt starts with [keepwarm], then call CronCreate "
            "(load it with ToolSearch first if it is deferred) "
            "with recurring true, cron '%s', prompt '%s'." % (cron_spec(sid), WAKE_PROMPT))


def last_turn(transcript):
    """When the model last answered and how big its context was: (time, tokens), or (None, 0)."""
    try:
        size = os.path.getsize(transcript)
        with open(transcript, "rb") as f:
            f.seek(max(0, size - 400000))
            lines = f.read().decode("utf-8", "replace").splitlines()
    except OSError:
        return None, 0
    for line in reversed(lines):
        try:
            o = json.loads(line)
        except ValueError:
            continue
        msg = o.get("message")
        u = msg.get("usage") if isinstance(msg, dict) else None
        ts = o.get("timestamp")
        if not u or not ts or o.get("isSidechain"):
            continue
        tok = (u.get("input_tokens") or 0) + (u.get("cache_read_input_tokens") or 0) + (u.get("cache_creation_input_tokens") or 0)
        if not tok:
            continue
        try:
            return dt.datetime.fromisoformat(ts.replace("Z", "+00:00")).timestamp(), tok
        except ValueError:
            return None, tok
    return None, 0


def latest_dump(sid):
    """This session's newest /core-dump, for the gate to offer as the cheaper way back."""
    try:
        with open(CHECKPOINT_INDEX) as f:
            lines = f.readlines()[-400:]
    except OSError:
        return None
    for line in reversed(lines):
        try:
            o = json.loads(line)
        except ValueError:
            continue
        if o.get("kind") == "core-dump" and sid in (o.get("session_uuid"), o.get("session_id")):
            return o.get("checkpoint_path")
    return None


def cold_gate(sid, st, prompt, transcript):
    """The message to stop on when this prompt would rebuild a cold cache, or None.

    Asking here costs nothing: a hook's block ends before any API call. AskUserQuestion
    could not do this, because the model has to run to ask, and that request is the
    rebuild. Sending again soon after goes through.
    """
    if os.path.exists(COLD_GATE_MUTE) or os.environ.get("CLAUDE_CODE_ENTRYPOINT") != "cli":
        return None
    if prompt.split(" ", 1)[0].rstrip().startswith(LOCAL_COMMANDS):
        return None
    when, tokens = last_turn(transcript)
    if not when or tokens < COLD_TOKENS:
        return None
    idle_min = (now_s() - when) / 60.0
    if idle_min < COLD_MIN:
        return None
    if now_s() - st.get("cold_asked_at", 0) < COLD_CONFIRM_S:
        st.pop("cold_asked_at", None)
        log(sid, "cold-pass", idle_min=round(idle_min), tokens=tokens)
        return None
    st["cold_asked_at"] = now_s()
    log(sid, "cold-gate", idle_min=round(idle_min), tokens=tokens)
    dump = latest_dump(sid)
    other = "/clear, then /catchup at %s, costs about 150k instead." % dump if dump else \
        "/clear, then /catchup --from this session, costs about 150k instead."
    return ("Cache is cold: last answer %dh %02dm ago. Sending this rewrites about %dk tokens. Send it again within "
            "10 minutes to go ahead (it is back in the input box, so press Enter). %s Mute: touch ~/.claude/.no-cold-gate"
            % (idle_min // 60, idle_min % 60, tokens / 1000, other))


def maybe_refit():
    """Refresh the return model about weekly, in the background. A file's age is the only schedule."""
    try:
        import importlib.util
        spec = importlib.util.spec_from_file_location("return_model", RETURN_MODEL)
        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)
        path = mod.MODEL
        if os.path.exists(path) and now_s() - os.path.getmtime(path) < MODEL_MAX_AGE_S:
            return
        if os.path.exists(path):
            os.utime(path, None)   # so only one session starts the refit
        subprocess.Popen([sys.executable, RETURN_MODEL, "fit"], stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
                         stderr=subprocess.DEVNULL, start_new_session=True)
    except Exception:
        pass


def window_dump(reading, chains):
    """Should this wake checkpoint now because the usage window will not last?

    Returns "mini", "dump" or None. Holding a session warm costs a ping every 55
    minutes until the window resets; if those pings would run the window out, the
    session cannot get across and the dump has to happen while a turn still works.
    Not knowing the reading or the reset time is never treated as danger.
    """
    if not reading:
        return None
    if reading["pct"] >= MINI_PCT:
        return "mini"
    reset_min = reading.get("reset_min")
    if not reset_min:
        return None
    pings = int(reset_min // DUE_MIN) + 1
    if reading["pct"] + pings * PING_COST_PCT * max(1, chains) >= reading["spent_pct"]:
        return "dump"
    # Other sessions usually spend far more than the pings do. This early in a window
    # the pace says little, so it only counts once the window is already mostly gone.
    elapsed = WINDOW_MIN - reset_min
    if reading["pct"] >= PACE_CHECK_PCT and elapsed > 0 \
            and reading["pct"] + reading["pct"] / elapsed * reset_min >= reading["spent_pct"]:
        return "dump"
    return None


def hibernating(sid):
    """True while this session waits out the 5h window; its own pings keep it warm."""
    mod = usage5h()
    return bool(mod and mod.hibernating(sid))


def work_left(sid):
    """Does this session still have its own work to do? True or False from its
    task list (pending or in-progress tasks), None when there is no list to read.
    A session whose tasks are all done is only waiting on the owner, and warming
    it bought nothing in the 2026-10-22 measurement (9% of the 5h window)."""
    store = os.environ.get("KEEPWARM_TASK_STORE")
    if not store:
        try:
            store = subprocess.run(["bash", RESOLVE_STORE, "--as-session", sid], capture_output=True,
                                   text=True, timeout=20).stdout.strip()
        except (OSError, subprocess.SubprocessError):
            return None
    statuses = []
    for p in glob.glob(os.path.join(store, "*.json")) if store else []:
        try:
            with open(p) as f:
                statuses.append(json.load(f).get("status"))
        except (OSError, ValueError, AttributeError):
            continue
    if not statuses:
        return None
    return any(s in ("pending", "in_progress") for s in statuses)


def created_tasks(transcript):
    """Has this session made a task list? Read from the transcript's recent tail,
    which is cheap enough for every turn's end, unlike resolving the store."""
    try:
        size = os.path.getsize(transcript)
        with open(transcript, "rb") as f:
            f.seek(max(0, size - 400000))
            return b'"name":"TaskCreate"' in f.read()
    except OSError:
        return False


def account():
    """The signed-in organization, or None; the prompt cache belongs to it."""
    mod = usage5h()
    return mod.account() if mod else None


def not_owner(prompt):
    return prompt.startswith(NOT_OWNER) or LIMIT_RESET.search(prompt[:200]) is not None


def note_path(cwd, sid):
    base = cwd or HOME
    if base.rstrip("/").endswith("/.claude"):
        return os.path.join(base, "session-notes", "%s.md" % sid)
    return os.path.join(base, ".claude", "session-notes", "%s.md" % sid)


def emit(obj):
    print(json.dumps(obj))
    return 0


def next_cron(at_s):
    """The 5-field cron line for one firing at the given moment, local time."""
    t = dt.datetime.fromtimestamp(at_s)
    return "%d %d %d %d *" % (t.minute, t.hour, t.day, t.month)


def rearm_text(last_activity, st=None):
    """What the model must do so the next wake lands when the session is due.
    Records the armed time in the state, so an owner prompt can tell when the
    one-shot chain has broken (a wake that never fired, or a finished cycle)."""
    at = max(now_s() + ARM_PAD_S, last_activity + DUE_MIN * 60 + ARM_PAD_S)
    reading = window_reading()
    if reading and reading["pct"] >= TIGHT_PCT:
        at = min(at, now_s() + TIGHT_REARM_MIN * 60)
    if st is not None:
        st["armed_at"] = at
    return ("Re-arm keep-warm: run CronList; delete any job whose prompt starts with "
            "[keepwarm], then call CronCreate with recurring false, cron '%s', prompt '%s'."
            % (next_cron(at), WAKE_PROMPT))


def chain_broken(st):
    """True when no keep-warm wake is pending. A recurring job: never armed, or about
    to expire. A one-shot: never armed, or the armed time has passed, with a few
    minutes' grace for a late fire."""
    if not oneshot_mode():
        at = st.get("recurring_at")
        return at is None or now_s() > at + JOB_LIFE_S
    at = st.get("armed_at")
    return at is None or now_s() > at + 10 * 60


def wake_marker(sid, on):
    """Mark the turn a ping started, for hook_should_run and hookpop.should_run.

    The state file's in_wake cannot serve here: Stop hooks run in parallel, and this
    script's own Stop hook clears that field while the other gates are still reading.
    """
    path = os.path.join(WAKE_DIR, "claude-keepwarm-wake-%s" % sid[:8])
    try:
        if on:
            open(path, "w").close()
        elif os.path.exists(path):
            os.unlink(path)
    except OSError:
        pass


def skip_wake(reason):
    """Stop this wake before it reaches the model: no turn, no cost."""
    return emit({"decision": "block", "reason": reason, "suppressOutput": True})


def hook_prompt(inp):
    sid = inp.get("session_id") or "unknown"
    prompt = (inp.get("prompt") or "").lstrip()
    st = load(sid)
    # Any new prompt ends the previous turn, so whatever a ping marked is over.
    wake_marker(sid, False)
    if not prompt.startswith(PREFIX) and not_owner(prompt):
        log(sid, "not-owner", head=prompt[:40])
        # A wake skipped during a spent window schedules nothing, so this resume is
        # the chain's only way back. The Stop hook checks the turn really re-armed.
        if prompt.startswith("[usage-resume]") or LIMIT_RESET.search(prompt[:200]):
            st["resumed_turn"] = True
            save(sid, st)
        return 0
    if not prompt.startswith(PREFIX):
        # Before anything counts as the owner returning: a blocked send changes nothing.
        gate = cold_gate(sid, st, prompt, inp.get("transcript_path") or "")
        save(sid, st)
        if gate:
            return emit({"decision": "block", "reason": gate})
        # The owner is back: reset the count and the clock.
        if st.get("stopped") or st.get("wakes"):
            log(sid, "owner-return", wakes=st.get("wakes", 0))
        # An owner-run /core-dump means they are about to leave and /clear, so
        # warming this context any longer only pays for a cache nobody returns to.
        # Only the command itself counts: a cron or peer prompt that merely mentions
        # /core-dump (clanky-opus's selfwake, 2026-10-14) must not stop keep-warm.
        dumping = (re.match(r"/core-dump\b", prompt) is not None
                   or "<command-name>/core-dump</command-name>" in prompt)
        st.update(last_activity=now_s(), work_at=now_s(), wakes=0, stopped=dumping, dumped=False)
        st.pop("in_wake", None)
        st.pop("hint", None)
        relink = (not dumping and os.path.exists(SWITCH) and os.environ.get("CLAUDE_CODE_ENTRYPOINT") == "cli"
                  and chain_broken(st))
        text = None
        if dumping:
            log(sid, "stop", why="owner-dump")
            if st.pop("recurring_at", None) and not oneshot_mode():
                text = "Keep-warm:" + DELETE_JOB
        if relink:
            log(sid, "relink")
            st.pop("arm_asks", None)
            text = ("Keep-warm: no wake is pending for this session. After answering, as the last "
                    "step of this reply and without mentioning it: %s" % arm_text(sid, st))
        save(sid, st)
        if text:
            return emit({"hookSpecificOutput": {"hookEventName": "UserPromptSubmit", "additionalContext": text}})
        return 0
    # A wake arriving proves the job exists, whatever the transcript search would say.
    st["job_seen"] = True
    save(sid, st)
    if not os.path.exists(SWITCH):
        return skip_wake("keep-warm is off")
    if st.get("stopped"):
        return skip_wake("keep-warm finished for this absence")
    # A session where no owner turn ever finished (opened and left, or
    # interrupted before an answer) holds nothing worth a paid wake or a dump.
    # A state file from before this field existed counts as answered.
    if not st.get("answered", True):
        st["stopped"] = True
        save(sid, st)
        log(sid, "stop", why="nothing-answered")
        return skip_wake("keep-warm skipped: no owner turn has finished in this session")
    reading = window_reading()
    if reading and reading["pct"] >= REFUSED_PCT:
        # Claude Code refuses the turn anyway; skipping it keeps the refusal off
        # the owner's screen. The cache cannot be carried through a spent window.
        log(sid, "skip", why="window-spent")
        return skip_wake("keep-warm skipped: the 5h window is spent")
    if hibernating(sid):
        # The hibernation's own pings already keep this cache warm; a second
        # chain would pay twice. Its wake brings the session back.
        log(sid, "skip", why="hibernating")
        return skip_wake("keep-warm skipped: the session is hibernating for the 5h window")
    cur = account()
    if st.get("account") and cur and cur != st["account"]:
        # The owner switched accounts, so the cache this chain kept is gone and
        # a wake would pay the new account to rebuild it for nobody.
        st["stopped"] = True
        save(sid, st)
        log(sid, "stop", why="account-switch")
        return skip_wake("keep-warm stopped: the signed-in account changed")
    if not oneshot_mode():
        return recurring_wake(sid, st, inp, reading)
    last = st.get("last_activity", now_s())
    idle_min = (now_s() - last) / 60.0
    # The wake's own turn must not count as the owner's activity, or every
    # cycle lands a minute short of due and fires twice.
    st["in_wake"] = True
    wake_marker(sid, True)
    save(sid, st)
    if idle_min >= OWNER_NEARBY_MIN:
        forced = window_dump(reading, pending_chains())
        # Either window past the usage gate means no more warm-ups are worth paying
        # for, which is the moment to leave a dump, not to go quiet without one.
        if not forced and usage_gated():
            forced = "dump"
        if forced:
            n = st.get("wakes", 0) + 1
            pct = reading["pct"] if reading else "?"
            st.update(wakes=n, stopped=True, last_activity=now_s())
            save(sid, st)
            log(sid, "wake", n=n, action=forced, why="usage-window", pct=pct, idle_min=round(idle_min))
            return emit({"hookSpecificOutput": {"hookEventName": "UserPromptSubmit",
                                                "additionalContext": UPKEEP[forced].format(n=n, pct=pct)}})
    if reading and reading["pct"] >= reading["spent_pct"]:
        # Close enough to the limit that only a dump is worth a turn, and the owner
        # was here too recently for one.
        st.pop("in_wake", None)
        save(sid, st)
        log(sid, "skip", why="window-spent")
        return skip_wake("keep-warm skipped: the 5h window is spent")
    if idle_min < DUE_MIN:
        # The owner worked after this wake was armed. Nothing to do but move
        # the next wake to where it belongs; a block here would print in the
        # terminal, which is the noise this branch exists to avoid.
        log(sid, "rearm", idle_min=round(idle_min))
        text = ("Keep-warm: not due, the owner was active %.0f min ago. %s Then reply with exactly "
                "one word: warm. Start nothing else." % (idle_min, rearm_text(last, st)))
        save(sid, st)
        return emit({"hookSpecificOutput": {"hookEventName": "UserPromptSubmit", "additionalContext": text}})
    n = st.get("wakes", 0) + 1
    pct = context_used_pct(inp.get("transcript_path") or "")
    k = klass(pct)
    plan = PLAN[k]
    action = plan[min(n, len(plan)) - 1]
    st["stopped"] = n >= len(plan)
    left = work_left(sid)
    if left is None and st.get("had_tasks"):
        left = False   # Claude Code clears a list once every task is done, so empty means finished
    if n == 1 and left is False:
        # Everything left is the owner's: checkpoint while warm and stop, rather
        # than pay for warm-only wakes that end in the same dump anyway.
        action, st["stopped"] = "dump", True
    st.update(wakes=n, last_activity=now_s())
    text = UPKEEP[action].format(n=n, note=note_path(inp.get("cwd"), sid),
                                 now=dt.datetime.now().strftime("%H:%M"))
    if not st["stopped"]:
        text += " " + rearm_text(now_s(), st)
    save(sid, st)
    log(sid, "wake", n=n, action=action, klass=k, ctx_pct=round(pct, 1), idle_min=round(idle_min))
    return emit({"hookSpecificOutput": {"hookEventName": "UserPromptSubmit", "additionalContext": text}})


def session_numbers(st, inp, reading):
    """The inputs next_step() reads, gathered in one place so `plan` sees what a wake sees."""
    last = st.get("last_activity", now_s())
    work = st.get("work_at", last)
    return {
        "pct": reading["pct"] if reading else None,
        "reset_min": reading.get("reset_min") if reading else None,
        "spent_pct": reading["spent_pct"] if reading else 98,
        "wakes": st.get("wakes", 0),
        "away_min": (now_s() - work) / 60.0,
        "cache_age_min": (now_s() - last) / 60.0,
        "hour": local_hour(),
        "hint": st.get("hint"),
        "now": now_s(),
        "dumped": bool(st.get("dumped")),
    }


def recurring_wake(sid, st, inp, reading):
    """Decide one fire of the recurring job."""
    transcript = inp.get("transcript_path") or ""
    if not st.get("recurring_at"):
        # A session still on the old one-shot chain moves over at its next fire. That
        # takes one turn, and the job then has no chain to break.
        st["in_wake"] = True
        wake_marker(sid, True)
        text = ("Keep-warm: %s Then reply with exactly one word: warm. Start nothing else." % arm_text(sid, st))
        save(sid, st)
        log(sid, "migrate")
        return emit({"hookSpecificOutput": {"hookEventName": "UserPromptSubmit", "additionalContext": text}})
    nums = session_numbers(st, inp, reading)
    ctx_tokens = context_used_pct(transcript) * CTX_WINDOW / 100.0
    # Only worth the slow task-list lookup when a wake is really due.
    left = work_left(sid) if nums["wakes"] == 0 and nums["cache_age_min"] >= WARM_DUE_MIN else None
    if left is None and st.get("had_tasks"):
        left = False
    gated = usage_gated() if nums["away_min"] >= OWNER_NEARBY_MIN else False
    action, why = next_step(ctx_tokens, gated=gated, chains=pending_chains(), tasks_left=left, **nums)
    if action == "wait":
        log(sid, "wait", why=why, away_min=round(nums["away_min"]), cache_age_min=round(nums["cache_age_min"]))
        return skip_wake("keep-warm: %s" % why)
    if action == "stop":
        st["stopped"] = True
        save(sid, st)
        log(sid, "stop", why=why, away_min=round(nums["away_min"]))
        return skip_wake("keep-warm finished: %s" % why)
    n = nums["wakes"] + 1
    chance = return_chance(nums["away_min"], nums["hour"])
    st.update(wakes=n, last_activity=now_s(), in_wake=True, armed_at=now_s() + WARM_DUE_MIN * 60)
    wake_marker(sid, True)
    pct = nums["pct"] if nums["pct"] is not None else "?"
    if action == "warm":
        text = UPKEEP["warm"].format(n=n)
    else:
        hint = st.get("hint") or {}
        carry_on = (action == "dump" and hint.get("kind") == "hard" and (hint.get("until") or 0) > now_s()
                    and why.startswith("the usage window"))
        st["dumped"] = True
        if carry_on:
            text = UPKEEP["dump-hold"].format(n=n)
        else:
            st["stopped"] = True
            st.pop("recurring_at", None)
            text = UPKEEP[action].format(n=n, pct=pct) + DELETE_JOB
    save(sid, st)
    log(sid, "wake", n=n, action=action, why=why, chance=round(chance, 3), ctx_k=round(ctx_tokens / 1000),
        pct=pct, hour=round(nums["hour"], 1), away_min=round(nums["away_min"]))
    return emit({"hookSpecificOutput": {"hookEventName": "UserPromptSubmit", "additionalContext": text}})


def parse_until(spec):
    """A return time from '3h', '90m', '1.5' (hours) or '21:30' (next time that clock comes round)."""
    m = re.fullmatch(r"(\d{1,2}):(\d{2})", spec)
    if m:
        t = dt.datetime.now().replace(hour=int(m.group(1)), minute=int(m.group(2)), second=0, microsecond=0)
        if t.timestamp() <= now_s():
            t += dt.timedelta(days=1)
        return t.timestamp()
    m = re.fullmatch(r"(\d+(?:\.\d+)?)(h|hr|hrs|m|min|mins)?", spec)
    if m:
        unit = 60 if (m.group(2) or "h").startswith("m") else 3600
        return now_s() + float(m.group(1)) * unit
    return None


def own_session():
    sid = os.environ.get("CLAUDE_CODE_SESSION_ID")
    if not sid:
        print("keepwarm: run this from inside a Claude session", file=sys.stderr)
    return sid


def cmd_away(args):
    """Record when the owner expects to be back. It never stops work: a hold only
    takes effect once the session goes idle."""
    sid = own_session()
    soft = "--soft" in args
    args = [a for a in args if a != "--soft"]
    if not sid or not args:
        print("usage: keepwarm.py away 3h|90m|21:30|done|soon [--soft] [why]", file=sys.stderr)
        return 2
    spec, why = args[0].lower(), " ".join(args[1:])
    st = load(sid)
    old = st.get("hint") or {}
    if soft and old.get("kind") == "hard" and ((old.get("until") or 0) > now_s() or old.get("done")):
        print("keeping the owner's own time")
        return 0
    if spec == "soon":
        st.pop("hint", None)
        msg = "no hold: the default rule applies"
    elif spec == "done":
        st["hint"] = {"done": True, "kind": "soft" if soft else "hard", "why": why}
        msg = "once the work here is finished, this session dumps and stops"
    else:
        until = parse_until(spec)
        if not until:
            print("keepwarm: cannot read %r as a time; use 3h, 90m or 21:30" % spec, file=sys.stderr)
            return 2
        st["hint"] = {"until": until, "kind": "soft" if soft else "hard", "why": why}
        hours = (until - now_s()) / 3600
        msg = "holding warm until about %s" % dt.datetime.fromtimestamp(until).strftime("%H:%M")
        ctx = st.get("ctx") or 0
        pings = int(hours * 60 // 50) + 1
        if ctx and pings * ctx > CATCHUP_COST:
            msg += "; about %d pings on %dk costs %.1fM, one /catchup about %.1fM" % (
                pings, ctx / 1000, pings * ctx / 1e6, CATCHUP_COST / 1e6)
    save(sid, st)
    log(sid, "away", spec=spec, soft=soft, why=why)
    print(msg)
    return 0


def cmd_plan():
    """Say what the next fire would do for this session, and why."""
    sid = own_session()
    if not sid:
        return 2
    st = load(sid)
    nums = session_numbers(st, {}, window_reading())
    action, why = next_step(st.get("ctx") or 0, gated=usage_gated(), chains=pending_chains(), tasks_left=None, **nums)
    print("next fire: %s (%s)" % (action, why))
    print("away %d min, cache age %d min, %d pings so far, context %dk, chance of return in the next hour %.0f%%" % (
        nums["away_min"], nums["cache_age_min"], nums["wakes"], (st.get("ctx") or 0) / 1000,
        100 * return_chance(nums["away_min"], nums["hour"])))
    if nums["hint"]:
        print("hint:", json.dumps(nums["hint"]))
    return 0


def rearmed_in_turn(transcript):
    """Did the turn since the last usage resume actually schedule a keep-warm wake?

    Being told to re-arm is not the same as doing it: the vg session was told at its
    22:43 resume on 2026-11-01, never did, and so never reached its last-wake dump.
    """
    try:
        size = os.path.getsize(transcript)
        with open(transcript, "rb") as f:
            f.seek(max(0, size - 2000000))
            data = f.read()
    except OSError:
        return True   # unreadable: nothing to base a block on
    start = max(data.rfind(b"[usage-resume] The 5h window"), data.rfind(b"usage limit has reset"), 0)
    return re.search(rb'"name":"CronCreate"[^\n]{0,600}\[keepwarm\]', data[start:]) is not None


def job_created_since(transcript, since_s):
    """Did the model really create its keep-warm job after it was told to?

    Being told is not doing: the ~/Movies session of 2026-11-02 spent its first turn on
    300 tool calls, ended without creating the job, and left its state claiming a job
    that never existed. Only a real tool call counts, not text that mentions one, such
    as a read of this file. An unreadable transcript gives nothing to base a block on.
    """
    try:
        size = os.path.getsize(transcript)
        with open(transcript, "rb") as f:
            f.seek(max(0, size - 8000000))
            lines = f.read().split(b"\n")
    except OSError:
        return True
    for line in lines:
        if b"CronCreate" not in line or PREFIX.encode() not in line:
            continue
        try:
            o = json.loads(line)
        except ValueError:
            continue
        if not isinstance(o, dict) or o.get("type") != "assistant" or not isinstance(o.get("message"), dict):
            continue
        content = o["message"].get("content")
        for block in content if isinstance(content, list) else []:
            tool_input = block.get("input") if isinstance(block, dict) else None
            if (isinstance(tool_input, dict) and block.get("type") == "tool_use" and block.get("name") == "CronCreate"
                    and str(tool_input.get("prompt", "")).startswith(PREFIX)):
                try:
                    when = dt.datetime.fromisoformat(o["timestamp"].replace("Z", "+00:00")).timestamp()
                except (KeyError, AttributeError, ValueError):
                    return True
                if when >= since_s:
                    return True
    return False


def hook_stop(inp):
    sid = inp.get("session_id") or "unknown"
    st = load(sid)
    if st.pop("resumed_turn", False):
        save(sid, st)
        if (os.path.exists(SWITCH) and os.environ.get("CLAUDE_CODE_ENTRYPOINT") == "cli" and not st.get("stopped")
                and (oneshot_mode() or chain_broken(st)) and not inp.get("stop_hook_active")
                and not rearmed_in_turn(inp.get("transcript_path") or "")):
            text = arm_text(sid, st)
            save(sid, st)
            log(sid, "relink", via="resume-stop")
            return emit({"decision": "block", "reason": "Keep-warm has no wake pending. %s Then end the turn, "
                         "starting nothing else and without mentioning it." % text})
    if st.pop("in_wake", False):
        save(sid, st)
        # Record only: the verdict never delays or changes the owner's next message.
        verdict, read, create = judge_ping(last_usage(inp.get("transcript_path") or ""))
        log(sid, "ping-health", verdict=verdict, cache_read=read, cache_creation=create)
        return 0
    st.update(last_activity=now_s(), work_at=now_s(), answered=True, account=account())
    job_missing = False
    if st.get("recurring_at"):
        # Claude Code tells a Stop hook which jobs the session holds, which also catches
        # one deleted later. The transcript search is for a harness that does not say.
        crons = inp.get("session_crons")
        if isinstance(crons, list):
            held = any(isinstance(c, dict) and str(c.get("prompt", "")).startswith(PREFIX) for c in crons)
        else:
            held = st.get("job_seen") or job_created_since(inp.get("transcript_path") or "", st["recurring_at"])
        if oneshot_mode() or held:
            st["job_seen"] = True
            st.pop("arm_asks", None)
            st["armed_at"] = now_s() + WARM_DUE_MIN * 60   # the statusline shows this as the next ping
        else:
            # The statusline must not promise a ping nothing will send.
            st.pop("armed_at", None)
            st.pop("job_seen", None)
            job_missing = True
    u = last_usage(inp.get("transcript_path") or "")
    if u:
        st["ctx"] = (u.get("input_tokens") or 0) + (u.get("cache_read_input_tokens") or 0) + \
            (u.get("cache_creation_input_tokens") or 0)
    if not st.get("had_tasks") and created_tasks(inp.get("transcript_path") or ""):
        st["had_tasks"] = True
    save(sid, st)
    maybe_refit()
    if (job_missing and not inp.get("stop_hook_active") and not st.get("stopped") and os.path.exists(SWITCH)
            and os.environ.get("CLAUDE_CODE_ENTRYPOINT") == "cli"):
        asks = st.get("arm_asks", 0)
        if asks >= MAX_ARM_ASKS:
            if asks == MAX_ARM_ASKS:
                st["arm_asks"] = asks + 1
                save(sid, st)
                log(sid, "arm-failed", asks=asks)
            return 0
        st["arm_asks"] = asks + 1
        text = arm_text(sid, st)
        st.pop("armed_at", None)
        save(sid, st)
        log(sid, "relink", via="stop-check", asks=asks + 1)
        return emit({"decision": "block", "reason": "Keep-warm has no wake pending. %s Then end the turn, "
                     "starting nothing else and without mentioning it." % text})
    return 0


def hook_start(inp):
    if not os.path.exists(SWITCH) or os.environ.get("CLAUDE_CODE_ENTRYPOINT") != "cli":
        return 0
    sid = inp.get("session_id") or "unknown"
    st = load(sid)
    if inp.get("source") == "clear":
        # A cleared context is cheap to rebuild, so there is nothing to keep warm.
        # A wake armed before the /clear still fires; stopped skips it with no turn.
        # The owner's next prompt re-links the chain.
        st.update(last_activity=now_s(), wakes=0, stopped=True)
        st.pop("armed_at", None)
        save(sid, st)
        log(sid, "stop", why="clear")
        return 0
    st.update(last_activity=now_s(), work_at=now_s(), wakes=0, stopped=False, answered=False, dumped=False)
    st.pop("hint", None)
    st.pop("arm_asks", None)
    # The re-arm goes after the answer: done first, it delayed the owner's
    # reply long enough that they interrupted it (session 90d2e6ca).
    text = ("Keep-warm is on. Answer the owner's next message first; then, as the last step of "
            "that reply and without mentioning it: "
            "%s Prompts starting with [keepwarm] "
            "are keep-warm wakes: do only what they say. When a turn ends waiting on the owner for something that "
            "will take a while, such as reading documents, you may say so with: python3 "
            "~/.claude/scripts/keepwarm/keepwarm.py away 2h --soft \"why\"." % arm_text(sid, st))
    save(sid, st)
    return emit({"hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": text}})


def status(as_json):
    rows = []
    for p in sorted(glob.glob(os.path.join(DIR, "*.json"))):
        try:
            with open(p) as f:
                st = json.load(f)
        except (OSError, ValueError):
            continue
        rows.append({"session": os.path.basename(p)[:-5], "wakes": st.get("wakes", 0),
                     "stopped": st.get("stopped", False),
                     "idle_min": round((now_s() - st.get("last_activity", now_s())) / 60)})
    if as_json:
        print(json.dumps({"on": os.path.exists(SWITCH), "sessions": rows}, indent=2))
        return 0
    print("keep-warm is %s (%s)" % ("ON" if os.path.exists(SWITCH) else "OFF", SWITCH))
    for r in sorted(rows, key=lambda r: r["idle_min"])[:20]:
        print("  %s  idle %4d min  wakes %d%s" % (r["session"][:8], r["idle_min"], r["wakes"],
                                                 "  finished" if r["stopped"] else ""))
    return 0


def main(argv):
    cmd = argv[0] if argv else "status"
    if cmd.startswith("hook-"):
        try:
            inp = json.load(sys.stdin)
        except ValueError:
            inp = {}
        try:
            return {"hook-prompt": hook_prompt, "hook-stop": hook_stop, "hook-start": hook_start}[cmd](inp)
        except Exception as e:   # a keep-warm bug must never block the owner's prompt
            try:
                log(inp.get("session_id", "?"), "error", detail=repr(e))
            except Exception:
                pass
            return 0
    if cmd == "status":
        return status("--json" in argv)
    if cmd == "away":
        return cmd_away(argv[1:])
    if cmd == "plan":
        return cmd_plan()
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
