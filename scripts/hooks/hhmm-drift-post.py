#!/usr/bin/env python3
"""Warns when a line just added to a log starts with a clock time that is far from
the real time.

A hand-typed HH:MM in a shared log looks exactly like a real one, and the ordering
of the log depends on it. On 2026-08-27 one agent wrote a dozen entries six hours
fast and a peer wrote its own an hour fast, in the same file on the same evening,
and neither noticed (prop-20260827-153626-1c). Reading the clock is one date call.

PostToolUse on Edit, Write and MultiEdit. Warns, never blocks: a deliberate
backdated entry and a correction that quotes old times are legitimate. It looks
only at lines this call added (new_string lines not already in old_string; for a
Write, the last five lines, since a rewrite that appends puts the entry at the
end), and only in a file that really is a time-stamped log (three or more lines
that begin with HH:MM), so a schedule written into a plan does not trip it.

The gap is the shorter way round the clock, so 23:55 against 00:05 is ten minutes.
Mute: touch ~/.claude/.no-hhmm-drift-gate. Test override: HHMM_DRIFT_NOW=HH:MM.
Heed: the next edit to the same file with no off-clock line records heeded true.
"""
import hashlib, json, os, re, subprocess, sys, datetime

HOME = os.path.expanduser("~")
LIMIT_MIN = 15
if os.path.exists(os.path.join(HOME, ".claude", ".no-hhmm-drift-gate")):
    sys.exit(0)
try:
    inp = json.load(sys.stdin)
except ValueError:
    sys.exit(0)
if not isinstance(inp, dict) or inp.get("tool_name") not in ("Edit", "Write", "MultiEdit", "Bash"):
    sys.exit(0)
ti = inp.get("tool_input") or {}
fp = ti.get("file_path") or ""
cmd = ""
if inp["tool_name"] == "Bash":
    # A shell append (printf ... >> NIGHT-CHANNEL.md) is how most channel entries land.
    # The append has already run, so the entry is the file's tail.
    cmd = ti.get("command") or ""
    m = re.search(r">>\s*(\"[^\"]+\"|'[^']+'|[^\s;&|<>]+)", cmd)
    if not m:
        sys.exit(0)
    fp = os.path.expanduser(m.group(1).strip("\"'"))
    if not os.path.isabs(fp):
        fp = os.path.join(inp.get("cwd") or os.getcwd(), fp)
if not fp:
    sys.exit(0)
# Test fixtures backdate on purpose.
if re.search(r"(\.test\.|_test\.|\.spec\.|/tests?/|/fixtures?/)", fp):
    sys.exit(0)

# A line that opens with a clock time: "14:32 did x", "- 14:32 did x", "[14:32] did x",
# "**14:32** did x", "14:32:05 did x". Optional am/pm.
STAMP = re.compile(r"^\s*(?:[-*>]\s+)?(?:\*\*|\[)?(\d{1,2}):(\d{2})(?::\d{2})?(?:\*\*|\])?\s*(am|pm)?(?=$|[\s\-:)\]|.,])", re.I)


def stamp_minutes(line):
    m = STAMP.match(line)
    if not m:
        return None
    h, mi, ap = int(m.group(1)), int(m.group(2)), (m.group(3) or "").lower()
    if mi > 59:
        return None
    if ap:
        if not 1 <= h <= 12:
            return None
        h = h % 12 + (12 if ap == "pm" else 0)
    elif h > 23:
        return None
    return h * 60 + mi


def lines_added():
    if inp["tool_name"] == "Bash":
        # Only tail lines whose stamp text appears in the command, so an older
        # entry already in the file is never blamed on this append.
        try:
            with open(fp, errors="replace") as fh:
                tail = [l.rstrip("\n") for l in fh if l.strip()][-5:]
        except OSError:
            return []
        out = []
        for l in tail:
            s = STAMP.match(l)
            if s and ("%s:%s" % (s.group(1), s.group(2))) in cmd:
                out.append(l)
        return out
    if inp["tool_name"] == "Write":
        body = [l for l in (ti.get("content") or "").split("\n") if l.strip()]
        return body[-5:]
    pairs = [(ti.get("old_string") or "", ti.get("new_string") or "")] if inp["tool_name"] == "Edit" else \
        [(e.get("old_string") or "", e.get("new_string") or "") for e in (ti.get("edits") or []) if isinstance(e, dict)]
    out = []
    for old, new in pairs:
        before = set(old.split("\n"))
        out += [l for l in new.split("\n") if l not in before]
    return out


now_s = os.environ.get("HHMM_DRIFT_NOW")
if now_s and re.fullmatch(r"\d{1,2}:\d{2}", now_s):
    now_min = int(now_s.split(":")[0]) * 60 + int(now_s.split(":")[1])
else:
    n = datetime.datetime.now()
    now_min, now_s = n.hour * 60 + n.minute, n.strftime("%H:%M")


def minutes_off_clock(m):
    d = abs(m - now_min) % 1440
    return min(d, 1440 - d)


stamped = [(l, stamp_minutes(l)) for l in lines_added()]
stamped = [(l, m) for l, m in stamped if m is not None]

state = "/tmp/claude-hhmm-%s-%s" % ((inp.get("session_id") or "nosid")[:8], hashlib.sha1(fp.encode()).hexdigest()[:10])
log = os.path.join(HOME, ".claude/scripts/hooks/warn-log.sh")


def warnlog(*args):
    subprocess.run(["bash", log, "--hook", "hhmm-drift", *args], capture_output=True)


if not stamped:
    sys.exit(0)

# Only a file that is a time-stamped log: read it back (PostToolUse, so it is written).
try:
    with open(fp, errors="replace") as fh:
        n_stamped = sum(1 for l in fh if stamp_minutes(l) is not None)
except OSError:
    n_stamped = len(stamped)
if n_stamped < 3:
    sys.exit(0)

off = [(l, m, minutes_off_clock(m)) for l, m in stamped if minutes_off_clock(m) > LIMIT_MIN]
if not off:
    if os.path.exists(state):
        warnlog("--heed-of", "hhmm-drift:" + os.path.basename(state), "--heeded", "true")
        os.remove(state)
    sys.exit(0)

if os.path.exists(state):
    warnlog("--heed-of", "hhmm-drift:" + os.path.basename(state), "--heeded", "false")
open(state, "w").write("1")
worst = max(off, key=lambda t: t[2])
shown = worst[0].strip()[:70]
warnlog("--action", "nudge", "--heeded", "unknown", "--target", fp, "--detail", "%s vs %s, %d min" % (shown.split()[0], now_s, worst[2]))
msg = ("[hhmm-drift] The line you just added to %s starts with a time that is %d minutes from the clock "
       "(\"%s\"; it is %s now, local). In a shared log the ordering depends on that field, and a typed time reads "
       "the same as a real one. Read the clock (`date +%%H:%%M`) and correct the entry, unless the backdating is "
       "deliberate. Mute: touch ~/.claude/.no-hhmm-drift-gate") % (fp, worst[2], shown, now_s)
print(json.dumps({"hookSpecificOutput": {"hookEventName": "PostToolUse", "additionalContext": msg}}))
