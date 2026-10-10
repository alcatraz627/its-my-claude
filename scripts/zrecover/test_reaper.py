#!/usr/bin/env python3
"""Exercises the reaper against real child processes: a memory hog, a CPU burner,
and a simulated critical-pressure scan. Kills are confined to this test's own
children, so a run can never touch anything else on the machine.

Run: /usr/bin/python3 ~/.claude/scripts/reaper/test_reaper.py
"""
import json, os, shutil, subprocess, sys, tempfile, time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import reaper  # noqa: E402
from testlib import expect, finish  # noqa: E402

reaper.LOG = os.path.join(tempfile.gettempdir(), "reaper-test.jsonl")

HOG = "import time; b = bytearray(1536 * 1024 * 1024)\nfor i in range(0, len(b), 16384): b[i] = 1\ntime.sleep(120)"
BURN = "import time\nt = time.time()\nwhile time.time() - t < 120: pass"


children = []


def spawn(code, tag):
    # argv[1] is a marker so the protected-name guard can be pointed at it
    p = subprocess.Popen([sys.executable, "-c", code, tag])
    children.append(p)
    time.sleep(2.5)
    return p


class Confined(reaper.Reaper):
    """The real reaper, except only this test's children count as killable."""
    def __init__(self, cfg, children):
        super().__init__(cfg)
        self.children = children

    def killable(self, p):
        return p["pid"] in self.children and super().killable(p)


def cfg(**over):
    # rules=[] so the python test children are judged by the globals under test, not the servers rule
    c = dict(reaper.DEFAULTS, notify=False, warn_proc_gb=0.5, kill_proc_gb=1.0, rules=[],
             cpu_demote_cores=0.5, cpu_demote_after_s=0, cpu_kill_after_s=0, cpu_kill_load_ratio=0.0)
    c.update(over)
    return c


def gone(p, wait=6):
    for _ in range(int(wait / 0.2)):
        if p.poll() is not None:
            return True
        time.sleep(0.2)
    return False






# 1. a process past the per-process memory cap is killed
hog = spawn(HOG, "reaper-test-hog")
r = Confined(cfg(), {hog.pid})
r.scan(time.time(), 1, 0, 0.0)
expect("memory cap kills a 1.5 GB hog at a 1 GB cap", gone(hog))

# 2. guard: the same hog under a protected name survives the same scan
hog = spawn(HOG, "reaper-test-hog")
r = Confined(cfg(protected=["reaper-test-hog"]), {hog.pid})
r.scan(time.time(), 1, 0, 0.0)
expect("protected name survives the memory cap", not gone(hog, wait=2))
hog.kill(); hog.wait()

# 3. critical pressure sheds the largest killable process even under the cap
hog = spawn(HOG, "reaper-test-hog")
r = Confined(cfg(kill_proc_gb=99, critical_min_target_gb=1), {hog.pid})
r.scan(time.time(), 4, 0, 0.0)
expect("critical pressure kills the largest killable process", gone(hog))

# 4. normal pressure, under the cap: nothing is killed
hog = spawn(HOG, "reaper-test-hog")
r = Confined(cfg(kill_proc_gb=99), {hog.pid})
r.scan(time.time(), 1, 0, 0.0)
expect("normal pressure under the cap leaves it alone", not gone(hog, wait=2))
hog.kill(); hog.wait()

# 5. a CPU hog is demoted first, then killed on a later scan
burn = spawn(BURN, "reaper-test-burn")
r = Confined(cfg(cpu_kill_after_s=1), {burn.pid})
r.scan(time.time(), 1, 0, 0.0)      # first sample
time.sleep(1.5)
r.scan(time.time(), 1, 0, 0.0)      # hot -> demote
expect("cpu hog is demoted, not killed, on first detection",
       burn.pid in r.demoted_at and burn.poll() is None)
time.sleep(1.5)
r.scan(time.time(), 1, 0, 0.0)      # still hot after cpu_kill_after_s -> kill
expect("cpu hog is killed when it stays hot after demotion", gone(burn))

# 6. the same CPU hog is spared when the machine is not saturated
burn = spawn(BURN, "reaper-test-burn")
r = Confined(cfg(cpu_kill_after_s=1, cpu_kill_load_ratio=99), {burn.pid})
r.scan(time.time(), 1, 0, 0.0)
time.sleep(1.5)
r.scan(time.time(), 1, 0, 0.0)
time.sleep(1.5)
r.scan(time.time(), 1, 0, 0.0)
expect("cpu hog survives when load is below the kill ratio", not gone(burn, wait=2))
burn.kill(); burn.wait()

# 7. a per-app rule overrides the global cap for its match only
hog = spawn(HOG, "reaper-test-hog")
r = Confined(cfg(kill_proc_gb=99, rules=[{"name": "t", "match": "reaper-test-hog", "kill_proc_gb": 1}]), {hog.pid})
r.scan(time.time(), 1, 0, 0.0)
expect("rule cap kills a matching process under a 99 GB global cap", gone(hog))

# 8. freeze: a pinned machine kills the top burner with no demote step
burn = spawn(BURN, "reaper-test-burn")
r = Confined(cfg(cpu_demote_cores=99, freeze_hold_s=0, freeze_min_cores=0.5), {burn.pid})
r.scan(time.time(), 1, 0, 99.0)
time.sleep(1.5)
r.scan(time.time(), 1, 0, 99.0)
expect("freeze kills the top burner outright", gone(burn) and burn.pid not in r.demoted_at)

# 9. freeze with no process burning: nothing is killed
idle = spawn("import time; time.sleep(60)", "reaper-test-idle")
r = Confined(cfg(freeze_hold_s=0), {idle.pid})
r.scan(time.time(), 1, 0, 99.0)
time.sleep(1.5)
r.scan(time.time(), 1, 0, 99.0)
expect("freeze leaves an idle process alone", not gone(idle, wait=2))

# 10. a rule matches on the full path, so a Steam game under steamapps/ is caught
fake = {"pid": 1, "cmd": "/Users/x/Library/Application Support/Steam/steamapps/common/G/G.app/Contents/MacOS/G",
        "mem": 0, "cpu_s": 0}
expect("steam rule matches a game by its steamapps path",
       (reaper.Reaper(reaper.DEFAULTS).rule_for(fake) or {}).get("name") == "steam")

# 11. a grant lifts the cap for its match, and it is capped by grant_max_gb
reaper.GRANTS = os.path.join(tempfile.gettempdir(), "zrecover-test-grants.json")
reaper.save_grants([{"id": "t1", "match": "reaper-test-hog", "gb": 3, "until": time.time() + 60}])
hog = spawn(HOG, "reaper-test-hog")
r = Confined(cfg(kill_proc_gb=1, grant_max_gb=48), {hog.pid})
r.scan(time.time(), 1, 0, 0.0)
expect("grant lets a 1.5 GB hog live under a 1 GB cap", not gone(hog, wait=2))
r = Confined(cfg(kill_proc_gb=1, grant_max_gb=1), {hog.pid})
r.scan(time.time(), 1, 0, 0.0)
expect("grant_max_gb still caps a grant", gone(hog))

# 12. critical pressure still kills a granted process when it is the only target
reaper.save_grants([{"id": "t2", "match": "reaper-test-hog", "gb": 40, "until": time.time() + 60}])
hog = spawn(HOG, "reaper-test-hog")
r = Confined(cfg(kill_proc_gb=99, critical_min_target_gb=1), {hog.pid})
r.scan(time.time(), 4, 0, 0.0)
expect("critical pressure overrides a grant", gone(hog))
os.remove(reaper.GRANTS)

# 13. the session snapshot lists claude sessions and rolls over on a new boot
reaper.ROOT = os.path.join(tempfile.gettempdir(), "zrecover-test-root")
reaper.SESSIONS = os.path.join(reaper.ROOT, "sessions.json")
reaper.LAST_BOOT = os.path.join(reaper.ROOT, "last-boot.json")
reaper.WRAPS = os.path.join(reaper.ROOT, "wraps")
os.makedirs(reaper.WRAPS, exist_ok=True)
fake_procs = {
    4242: {"pid": 4242, "cmd": "claude --resume abc", "mem": 0, "cpu_s": 0},
    4243: {"pid": 4243, "cmd": "claude -p --resume x core-dump", "mem": 0, "cpu_s": 0},
    4244: {"pid": 4244, "cmd": "node something", "mem": 0, "cpu_s": 0},
}
with open(os.path.join(reaper.WRAPS, "4242.json"), "w") as f:
    json.dump({"pid": 4242, "screen": "/tmp/x.txt", "cwd": "/tmp/proj", "started": 1}, f)
reaper.write_sessions(fake_procs)
snap = json.load(open(reaper.SESSIONS))
pids = [s["pid"] for s in snap["sessions"]]
expect("snapshot keeps interactive claude, drops -p runs and non-claude", pids == [4242])
expect("snapshot joins the wrap record", snap["sessions"][0].get("wrapped") and snap["sessions"][0]["cwd"] == "/tmp/proj")
with open(reaper.SESSIONS, "w") as f:
    json.dump({"boot": snap["boot"] - 1, "ts": 0, "sessions": [{"pid": 1, "cmd": "old"}]}, f)
reaper.write_sessions(fake_procs)
old = json.load(open(reaper.LAST_BOOT))
expect("a snapshot from an earlier boot is kept as last-boot", old["sessions"][0]["cmd"] == "old")
shutil.rmtree(reaper.ROOT)

for p in children:
    if p.poll() is None:
        p.kill()
        p.wait()
finish()
