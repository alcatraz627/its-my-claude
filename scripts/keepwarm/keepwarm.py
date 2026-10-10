#!/usr/bin/env python3
"""Keep-warm: keep an idle Claude session's prompt cache alive while the owner
is away, and write its checkpoint while the cache is still warm.

A one-shot in-session cron sends "[keepwarm] idle check" when the session has
been idle long enough (40 minutes after the last turn). The UserPromptSubmit
hook below decides each one and always tells the model when to arm the next
one, so the chain continues without a recurring job. Due -> the prompt goes
through with the one piece of upkeep this wake should do. Not due yet (the
owner was active since the cron was armed) -> the prompt goes through with
nothing to do but re-arm at the right time; one short cached turn, at most
once per idle window. Off or finished -> blocked, and nothing re-arms.

The earlier design used a recurring 15-minute cron and blocked the not-due
fires. Claude Code prints every block ("operation blocked by hook") in the
owner's terminal, so an active session saw the notice at every pause. A chain
of one-shots never fires when it is not wanted, which is the only way to keep
the terminal quiet.

The Stop hook records when each turn ended; the owner typing anything resets
the count.

Plan and economics: ~/.claude/assets/reports/20261010-gcc-fix-list/keepwarm-plan.md

Usage (hooks pass their JSON on stdin):
  keepwarm.py hook-start     SessionStart: ask an interactive session to arm the cron
  keepwarm.py hook-prompt    UserPromptSubmit: decide a wake, or reset on owner input
  keepwarm.py hook-stop      Stop: record the end of a turn
  keepwarm.py status [--json]
On/off for every session: ~/.claude/.keepwarm-on (present = on).
"""
import datetime as dt
import glob
import json
import os
import subprocess
import sys
import time

HOME = os.path.expanduser("~")
DIR = os.environ.get("KEEPWARM_DIR", os.path.join(HOME, ".claude", "keepwarm"))
SWITCH = os.environ.get("KEEPWARM_SWITCH", os.path.join(HOME, ".claude", ".keepwarm-on"))
EVENTS = os.path.join(DIR, "events.jsonl")
DUE_MIN = float(os.environ.get("KEEPWARM_DUE_MIN", "40"))
PREFIX = "[keepwarm]"
WAKE_PROMPT = "[keepwarm] idle check"
# A one-shot cron is pinned to a minute; firing a little late is harmless, a
# little early would find the session not yet due, so pad by one minute.
ARM_PAD_S = 60
USAGE_GATE = os.path.join(HOME, ".claude", "scripts", "cron", "usage-gate.sh")

# Per context class: the upkeep for wake 1, 2, ... and the wake that is the last.
# Classes by context USED: light <15%, worked 15-50%, heavy 50-65%, full >65%.
PLAN = {
    "light":  {"wakes": ["note"], "last": 1},
    "worked": {"wakes": ["note", "dump"], "last": 10},
    "heavy":  {"wakes": ["note", "dump"], "last": 5},
    "full":   {"wakes": ["note", "dump"], "last": 2},
}
UPKEEP = {
    "note": ("Keep-warm wake {n}: the owner is away. Write three short lines to this session's "
             "workspace note ({note}): what is in flight, what waits on the owner, the next action. "
             "Then reply with one line. Start nothing else."),
    "dump": ("Keep-warm wake {n}: the owner is away and the cache is still warm. Run /core-dump "
             "(full) now so the owner can resume cheaply. Then reply with one line. Start nothing else."),
    "inbox": ("Keep-warm wake {n}: check this session's ipc inbox and background tasks; answer "
              "anything owed. If nothing is owed, reply only: still parked: <the next action>. "
              "Start nothing else."),
    "stop": ("Keep-warm wake {n}, the last: append one line 'parked at {now}: <the next action>' to "
             "this session's workspace note ({note}), then reply with one line. Keep-warm stops "
             "here until the owner returns."),
}


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


def context_used_pct(transcript):
    """Context used, in percent. Prefers the statusline's own reading for this
    Claude process; falls back to the last turn's token count over 200k."""
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
                tok = (u.get("input_tokens") or 0) + (u.get("cache_read_input_tokens") or 0) + \
                      (u.get("cache_creation_input_tokens") or 0)
                return 100.0 * tok / 200000.0
    except OSError:
        pass
    return 30.0   # unknown: treat as a worked session


def klass(pct):
    return "light" if pct < 15 else "worked" if pct < 50 else "heavy" if pct < 65 else "full"


def usage_gated():
    try:
        return subprocess.run(["bash", USAGE_GATE], capture_output=True, timeout=10).returncode == 1
    except Exception:
        return False


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


def rearm_text(last_activity):
    """What the model must do so the next wake lands when the session is due."""
    at = max(now_s() + ARM_PAD_S, last_activity + DUE_MIN * 60 + ARM_PAD_S)
    return ("Re-arm keep-warm: call CronCreate with recurring false, cron '%s', prompt '%s'."
            % (next_cron(at), WAKE_PROMPT))


def skip_wake(reason):
    """Stop this wake before it reaches the model: no turn, no cost."""
    return emit({"decision": "block", "reason": reason, "suppressOutput": True})


def hook_prompt(inp):
    sid = inp.get("session_id") or "unknown"
    prompt = (inp.get("prompt") or "").lstrip()
    st = load(sid)
    if not prompt.startswith(PREFIX):
        # The owner is back: reset the count and the clock.
        if st.get("stopped") or st.get("wakes"):
            log(sid, "owner-return", wakes=st.get("wakes", 0))
        st.update(last_activity=now_s(), wakes=0, stopped=False)
        save(sid, st)
        return 0
    if not os.path.exists(SWITCH):
        return skip_wake("keep-warm is off")
    if st.get("stopped"):
        return skip_wake("keep-warm finished for this absence")
    last = st.get("last_activity", now_s())
    idle_min = (now_s() - last) / 60.0
    if idle_min < DUE_MIN:
        # The owner worked after this wake was armed. Nothing to do but move
        # the next wake to where it belongs; a block here would print in the
        # terminal, which is the noise this branch exists to avoid.
        log(sid, "rearm", idle_min=round(idle_min))
        text = ("Keep-warm: not due, the owner was active %.0f min ago. %s Then reply with exactly "
                "one word: warm. Start nothing else." % (idle_min, rearm_text(last)))
        return emit({"hookSpecificOutput": {"hookEventName": "UserPromptSubmit", "additionalContext": text}})
    if usage_gated():
        st["stopped"] = True
        save(sid, st)
        log(sid, "stop", why="usage-gate")
        return skip_wake("keep-warm stopped: usage window nearly spent")
    n = st.get("wakes", 0) + 1
    pct = context_used_pct(inp.get("transcript_path") or "")
    k = klass(pct)
    plan = PLAN[k]
    if k == "light":
        action = "note"
        st["stopped"] = True
    elif n >= plan["last"]:
        action = "dump" if k == "full" else "stop"
        st["stopped"] = True
    else:
        action = plan["wakes"][n - 1] if n <= len(plan["wakes"]) else "inbox"
    st.update(wakes=n, last_activity=now_s())
    save(sid, st)
    log(sid, "wake", n=n, action=action, klass=k, ctx_pct=round(pct, 1), idle_min=round(idle_min))
    text = UPKEEP[action].format(n=n, note=note_path(inp.get("cwd"), sid),
                                 now=dt.datetime.now().strftime("%H:%M"))
    if not st["stopped"]:
        text += " " + rearm_text(now_s())
    return emit({"hookSpecificOutput": {"hookEventName": "UserPromptSubmit", "additionalContext": text}})


def hook_stop(inp):
    sid = inp.get("session_id") or "unknown"
    st = load(sid)
    st["last_activity"] = now_s()
    save(sid, st)
    return 0


def hook_start(inp):
    if not os.path.exists(SWITCH) or os.environ.get("CLAUDE_CODE_ENTRYPOINT") != "cli":
        return 0
    sid = inp.get("session_id") or "unknown"
    st = load(sid)
    st.update(last_activity=now_s(), wakes=0, stopped=False)
    save(sid, st)
    text = ("Keep-warm is on. Once, as part of your next reply and without mentioning it: run CronList; "
            "delete any job whose prompt starts with [keepwarm], then %s Prompts starting with [keepwarm] "
            "are keep-warm wakes: do only what they say." % rearm_text(now_s()))
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
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
