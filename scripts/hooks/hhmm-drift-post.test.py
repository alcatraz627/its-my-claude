#!/usr/bin/env python3
"""Checks hhmm-drift-post: a line added to a time-stamped log whose HH:MM is more
than 15 minutes off the clock warns; on-clock lines, non-logs, mentions and old
lines do not; the next clean edit records a heed."""
import json, os, subprocess, sys, tempfile

HOOK = os.environ.get("HHMM_HOOK", os.path.join(os.path.dirname(os.path.abspath(__file__)), "hhmm-drift-post.py"))
tmp = tempfile.mkdtemp(prefix="hhmm-")
WARN = os.path.join(tmp, "warn.jsonl")
passed = failed = 0
if os.path.exists(os.path.expanduser("~/.claude/.no-hhmm-drift-gate")):
    print("mute file present, test would pass vacuously")
    sys.exit(2)

LOG = "09:00 started\n09:10 read the brief\n09:20 wrote the plan\n"


def make(name, text):
    p = os.path.join(tmp, name)
    with open(p, "w") as f:
        f.write(text)
    return p


def run(name, want, tool, ti, sid, now="14:30"):
    global passed, failed
    out = subprocess.run([sys.executable, HOOK], input=json.dumps(
        {"tool_name": tool, "tool_input": ti, "session_id": sid}), capture_output=True, text=True,
        env={**os.environ, "HHMM_DRIFT_NOW": now, "WARN_LOG_STORE": WARN}).stdout
    got = "warn" if "hhmm-drift" in out and "additionalContext" in out else "silent"
    if got == want:
        passed += 1
    else:
        failed += 1
        print(f"FAIL {name}: want {want} got {got} {out[:120]}")
    return out


def edit(path, new, old=""):
    return {"file_path": path, "old_string": old, "new_string": new}


def clean_state(*sids):
    import glob
    for s in sids:
        for f in glob.glob(f"/tmp/claude-hhmm-{s[:8]}-*"):
            os.remove(f)


sids = [f"hh{n:06d}" for n in range(1, 16)]
clean_state(*sids)

p = make("a.md", LOG + "09:05 did the thing\n")
run("six hours fast", "warn", "Edit", edit(p, "09:05 did the thing"), sids[0])

p = make("b.md", LOG + "14:28 on the clock\n")
run("on the clock", "silent", "Edit", edit(p, "14:28 on the clock"), sids[1])

p = make("c.md", LOG + "14:45 edge\n")
run("exactly fifteen minutes", "silent", "Edit", edit(p, "14:45 edge"), sids[2])
p = make("d.md", LOG + "14:46 over\n")
run("sixteen minutes", "warn", "Edit", edit(p, "14:46 over"), sids[3])

p = make("e.md", LOG + "23:58 before midnight\n")
run("wraps midnight, close", "silent", "Edit", edit(p, "23:58 before midnight"), sids[4], now="00:05")
p = make("f.md", LOG + "23:30 before midnight\n")
run("wraps midnight, far", "warn", "Edit", edit(p, "23:30 before midnight"), sids[5], now="00:05")

p = make("g.md", "09:00 standup\n10:00 review\n")
run("two stamped lines is a schedule, not a log", "silent", "Edit", edit(p, "10:00 review"), sids[6])

p = make("h.md", LOG + "see the 09:05 entry above\n")
run("a mention of a time is not an entry", "silent", "Edit", edit(p, "see the 09:05 entry above"), sids[7])

p = make("i.md", LOG + "09:05 moved line\n")
run("a line that was already in old_string is not new", "silent", "Edit", edit(p, "09:05 moved line", old="09:05 moved line"), sids[8])

body = LOG + "09:05 old drifted entry\n" + "".join(f"14:2{n} fine {n}\n" for n in range(6))
p = make("j.md", body)
run("Write: a drifted line early in the file is not checked", "silent", "Write", {"file_path": p, "content": body}, sids[9])
body = LOG + "".join(f"14:2{n} fine {n}\n" for n in range(6)) + "09:05 appended drifted entry\n"
p = make("k.md", body)
run("Write: a drifted line at the end warns", "warn", "Write", {"file_path": p, "content": body}, sids[10])

p = make("l.md", LOG + "2:15 pm afternoon entry\n")
run("pm time on the clock", "silent", "Edit", edit(p, "2:15 pm afternoon entry"), sids[11])

p = make("m.md", LOG + "- [09:05] bullet form\n")
run("bullet and bracket form warns", "warn", "Edit", edit(p, "- [09:05] bullet form"), sids[12])

p = make("n.md", LOG + "09:05 via multiedit\n")
run("MultiEdit warns", "warn", "MultiEdit", {"file_path": p, "edits": [{"old_string": "", "new_string": "09:05 via multiedit"}]}, sids[13])

# Heed: warn, then a clean edit to the same file.
p = make("o.md", LOG + "09:05 drift\n")
run("heed setup warns", "warn", "Edit", edit(p, "09:05 drift"), sids[14])
with open(p, "a") as f:
    f.write("14:29 corrected\n")
run("heed: clean edit is silent", "silent", "Edit", edit(p, "14:29 corrected"), sids[14])
rows = [json.loads(l) for l in open(WARN)] if os.path.exists(WARN) else []
if any(r.get("kind") == "heed" and r.get("heeded") == "true" and r.get("hook_id") == "hhmm-drift" for r in rows):
    passed += 1
else:
    failed += 1
    print("FAIL heed row missing after a corrected edit")

clean_state(*sids)
print(f"{passed} passed, {failed} failed")
sys.exit(1 if failed else 0)
