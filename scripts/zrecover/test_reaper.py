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

SCRATCH = tempfile.mkdtemp(prefix="zrecover-test-")
reaper.LOG = os.path.join(SCRATCH, "reaper-test.jsonl")
# Nothing below may read the daemon's grants or write its session files.
reaper.GRANTS = os.path.join(SCRATCH, "grants.json")
reaper.SLOWED = os.path.join(SCRATCH, "slowed.json")

HOG = "import time; b = bytearray(1536 * 1024 * 1024)\nfor i in range(0, len(b), 16384): b[i] = 1\ntime.sleep(120)"
BURN = "import time\nt = time.time()\nwhile time.time() - t < 120: pass"


children = []
_real_alive = reaper.alive


def alive_reaping(pid):
    """The daemon never parents what it kills, but this test does, and an unreaped child
    would read as still alive and so as a failed kill."""
    for p in children:
        if p.pid == pid:
            return p.poll() is None
    return _real_alive(pid)


reaper.alive = alive_reaping


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

        self.frontmost = lambda: -1   # a known frontmost app that is none of the children

    def killable(self, p):
        return p["pid"] in self.children and super().killable(p)

    def can_touch(self, p):
        return p["pid"] in self.children


def cfg(**over):
    # rules=[] so the python test children are judged by the globals under test, not the servers rule
    c = dict(reaper.DEFAULTS, notify=False, warn_proc_gb=0.5, kill_proc_gb=1.0, rules=[],
             cpu_demote_cores=0.5, cpu_demote_after_s=0, cpu_kill_after_s=0, cpu_kill_load_ratio=0.0,
             freeze_warn_s=0, freeze_min_share=0, sessions_every_s=1e12)
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
# A low threshold, because on a busy Mac a demoted process really does fall under a higher one.
r = Confined(cfg(cpu_kill_after_s=1, cpu_demote_cores=0.05), {burn.pid})
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
reaper.ROOT = SCRATCH


def rows(action=None):
    """Log rows written since the file was last cleared, optionally of one action."""
    try:
        with open(reaper.LOG) as f:
            got = [json.loads(ln) for ln in f]
    except OSError:
        return []
    return [x for x in got if action is None or x.get("action") == action]


def clear_log():
    open(reaper.LOG, "w").close()


def hot_scans(r, load=99.0, n=2, gap=1.5):
    """Scan a few times, far enough apart that a burner has a measured rate."""
    for i in range(n):
        if i:
            time.sleep(gap)
        r.scan(time.time(), 1, 0, load)


CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
TAB = ("/Applications/Google Chrome.app/Contents/Frameworks/Google Chrome Framework.framework/Versions/156.0.8078.81/"
       "Helpers/Google Chrome Helper (Renderer).app/Contents/MacOS/Google Chrome Helper (Renderer) --type=renderer")
CLT_PY = ("/Library/Developer/CommandLineTools/Library/Frameworks/Python3.framework/Versions/3.9/Resources/"
          "Python.app/Contents/MacOS/Python server.py")
STEAM = "/Users/x/Library/Application Support/Steam/steamapps/common/G/G.app/Contents/MacOS/G"
QEMU = "/opt/homebrew/share/android-commandlinetools/emulator/qemu/darwin-aarch64/qemu-system-aarch64-headless -avd csync-ui"

# 14. which processes count as a main app, using real command lines from this Mac
expect("Chrome's main process is a main app", reaper.is_main_app(CHROME))
expect("a Chrome tab is not a main app", not reaper.is_main_app(TAB))
expect("a tab belongs to Chrome", reaper.app_root(TAB) == "/Applications/Google Chrome.app")
expect("python inside Python.app is not a main app", not reaper.is_main_app(CLT_PY))
expect("a Steam game is not a main app", not reaper.is_main_app(STEAM))
expect("a plain binary has no app", reaper.app_root(QEMU) is None and not reaper.is_main_app(QEMU))

# 15. the three classes
r = reaper.Reaper(dict(reaper.DEFAULTS, slow_only=["qemu-system-aarch64-headless"]))
expect("the emulator is slow-only", r.process_class({"pid": 5000, "cmd": QEMU}) == "slow-only")
expect("a protected name stays protected", r.process_class({"pid": 5000, "cmd": "claude --resume x"}) == "protected")
expect("a system path stays protected", r.process_class({"pid": 5000, "cmd": "/usr/sbin/cfprefsd"}) == "protected")
expect("anything else is restartable", r.process_class({"pid": 5000, "cmd": TAB}) == "restartable")
expect("slow-only is not killable", not r.killable({"pid": 5000, "cmd": QEMU}))
expect("no slow_only names means no slow-only process",
       reaper.Reaper(dict(reaper.DEFAULTS)).process_class({"pid": 5000, "cmd": "anything"}) == "restartable")

# 16. a slow-only process survives every kill rule, even past the memory cap and under critical pressure
hog = spawn(HOG, "reaper-test-slow")
r = Confined(cfg(slow_only=["reaper-test-slow"], kill_proc_gb=1, critical_min_target_gb=1), {hog.pid})
r.scan(time.time(), 4, 0, 0.0)
expect("slow-only survives the memory cap and critical pressure", not gone(hog, wait=2))
hog.kill(); hog.wait()

# 17. exemptions: main apps always, the frontmost app and its tabs, and everything when frontmost is unknown
r = reaper.Reaper(dict(reaper.DEFAULTS))
other = {"pid": 7000, "root": "/Applications/Zed.app"}
chrome_front = {"pid": 7001, "root": "/Applications/Google Chrome.app"}
expect("a main app is exempt from CPU kills", r.cpu_exempt({"pid": 1, "cmd": CHROME}, other))
expect("a background tab is not exempt", not r.cpu_exempt({"pid": 2, "cmd": TAB}, other))
expect("a tab of the frontmost app is exempt", r.cpu_exempt({"pid": 2, "cmd": TAB}, chrome_front))
expect("a frontmost non-app process is exempt", r.cpu_exempt({"pid": 7000, "cmd": "weird"}, other))
expect("an unknown frontmost app exempts everything", r.cpu_exempt({"pid": 2, "cmd": TAB}, None))
expect("a server is not exempt", not r.cpu_exempt({"pid": 3, "cmd": CLT_PY}, other))

# 18. memory caps still kill an exempt process, because running out of memory is the emergency
hog = spawn(HOG, "reaper-test-hog")
r = Confined(cfg(), {hog.pid})
r.frontmost = lambda: hog.pid
r.scan(time.time(), 1, 0, 0.0)
expect("the memory cap kills even the frontmost app", gone(hog))

# 19. the freeze rule spares the frontmost app, and an unknown frontmost app stops the kill
burn = spawn(BURN, "reaper-test-burn")
r = Confined(cfg(cpu_demote_cores=99, freeze_hold_s=0, freeze_min_cores=0.5), {burn.pid})
r.frontmost = lambda: burn.pid
hot_scans(r)
expect("the freeze rule spares the frontmost app", not gone(burn, wait=1))
r = Confined(cfg(cpu_demote_cores=99, freeze_hold_s=0, freeze_min_cores=0.5), {burn.pid})
r.frontmost = lambda: None
hot_scans(r)
expect("an unknown frontmost app stops the kill", not gone(burn, wait=1))
burn.kill(); burn.wait()

# 20. a burner too small a share of the total CPU survives; one with enough share dies
big = spawn(BURN, "reaper-test-big")
small = spawn("import time\nwhile True:\n    t = time.time()\n    while time.time() - t < 0.2: pass\n    time.sleep(0.8)", "reaper-test-small")
r = Confined(cfg(cpu_demote_cores=99, freeze_hold_s=0, freeze_min_cores=0.1, freeze_min_share=0.9), {small.pid})
hot_scans(r)
expect("a small share is not worth killing", not gone(small, wait=1))
small.kill(); small.wait()
big.kill(); big.wait()
burn = spawn(BURN, "reaper-test-burn")
r = Confined(cfg(cpu_demote_cores=99, freeze_hold_s=0, freeze_min_cores=0.5), {burn.pid})
r.rate_total = lambda: 1.0     # this child is the whole of the machine's CPU
r.cfg["freeze_min_share"] = 0.25
hot_scans(r)
expect("a burner with enough share dies", gone(burn))

# 21. the countdown warns first, kills when it runs out, and is called off if things clear
clear_log()
burn = spawn(BURN, "reaper-test-burn")
r = Confined(cfg(cpu_demote_cores=99, freeze_hold_s=0, freeze_min_cores=0.5, freeze_warn_s=3), {burn.pid})
hot_scans(r)
expect("a freeze kill warns first", burn.poll() is None and len(rows("kill-countdown")) == 1)
time.sleep(3.2)
r.scan(time.time(), 1, 0, 99.0)
expect("and kills when the countdown runs out", gone(burn))
clear_log()
burn = spawn(BURN, "reaper-test-burn")
r = Confined(cfg(cpu_demote_cores=99, freeze_hold_s=0, freeze_min_cores=0.5, freeze_warn_s=3), {burn.pid})
hot_scans(r)
r.scan(time.time(), 1, 0, 0.1)
time.sleep(3.2)
r.scan(time.time(), 1, 0, 0.1)
expect("a countdown is called off when load clears", not gone(burn, wait=1) and len(rows("kill-cancelled")) == 1)
time.sleep(1.5)
r.scan(time.time(), 1, 0, 99.0)
expect("and a later freeze starts a new countdown", burn.pid in r.pending and len(rows("kill-countdown")) == 2)
burn.kill(); burn.wait()

# 22. the post-demotion kill goes through the countdown too
clear_log()
burn = spawn(BURN, "reaper-test-burn")
r = Confined(cfg(cpu_kill_after_s=0, freeze_warn_s=60, cpu_demote_cores=0.05), {burn.pid})
hot_scans(r, load=0.0, n=3)
expect("the ladder warns before it kills", burn.poll() is None and len(rows("kill-countdown")) == 1)
burn.kill(); burn.wait()

# 24. the real sequence from 2026-11-05: repeat kills inside a freeze are held back
first = spawn(BURN, "reaper-test-first")
second = spawn(BURN, "reaper-test-second")
r = Confined(cfg(cpu_demote_cores=99, freeze_hold_s=0, freeze_min_cores=0.5, after_kill_cooldown_s=0,
                 freeze_kill_gap_s=999), {first.pid, second.pid})
hot_scans(r)
killed = [p for p in (first, second) if gone(p, wait=1)]
expect("the first freeze kill happens", len(killed) == 1)
hot_scans(r, n=3)
expect("the second burner waits out the gap", len([p for p in (first, second) if gone(p, wait=1)]) == 1)
first.poll() is None and first.kill()
second.poll() is None and second.kill()

# 25. a freeze slows a slow-only burner for real, and it goes back to normal after load recovers
def is_background(pid):
    # Background priority reads 4. A busy normal process decays, but stays well above this.
    out = subprocess.run(["ps", "-o", "pri=", "-p", str(pid)], capture_output=True, text=True).stdout.strip()
    return int(out) < 10

clear_log()
burn = spawn(BURN, "reaper-test-slow")
r = Confined(cfg(slow_only=["reaper-test-slow"], cpu_demote_cores=0.5, freeze_hold_s=0, restore_after_s=1), {burn.pid})
expect("a burner starts at normal priority", not is_background(burn.pid))
hot_scans(r)
expect("a freeze demotes a slow-only burner, without killing it",
       burn.pid in r.slowed and burn.poll() is None and is_background(burn.pid))
expect("the demotion row names the burners", any(b["pid"] == burn.pid for b in rows("demote")[0]["burners"]))
r.scan(time.time(), 1, 0, 0.1)
time.sleep(1.2)
r.scan(time.time(), 1, 0, 0.1)
expect("load recovering restores it", burn.pid not in r.slowed and not is_background(burn.pid))
hot_scans(r)
r.restore_all()
expect("the daemon leaving restores it too", not is_background(burn.pid) and not r.slowed)
burn.kill(); burn.wait()

# 26. the frontmost app is never demoted, and one that becomes frontmost is restored at once
clear_log()
burn = spawn(BURN, "reaper-test-slow")
r = Confined(cfg(slow_only=["reaper-test-slow"], freeze_hold_s=0), {burn.pid})
r.frontmost = lambda: burn.pid
hot_scans(r)
expect("the frontmost app is not demoted", rows("demote") == [] and burn.pid not in r.slowed and not is_background(burn.pid))
r.frontmost = lambda: -1
time.sleep(1.5)
hot_scans(r, n=1)
expect("once in the background it can be", burn.pid in r.slowed)
r.frontmost = lambda: burn.pid
time.sleep(1.5)
r.scan(time.time(), 1, 0, 99.0)
expect("coming to the front restores it", burn.pid not in r.slowed and not is_background(burn.pid))
burn.kill(); burn.wait()

# 28. a class grant protects for a while and leaves memory grants alone
reaper.GRANTS = os.path.join(tempfile.gettempdir(), "zrecover-test-grants2.json")
reaper.save_grants([{"id": "c1", "match": "reaper-test-class", "class": "slow-only", "until": time.time() + 60},
                    {"id": "c2", "match": "reaper-test-gone", "class": "protected", "until": time.time() + 60}])
r = reaper.Reaper(dict(reaper.DEFAULTS))
r.reload_grants(time.time())
expect("a class grant sets the class", r.process_class({"pid": 5000, "cmd": "reaper-test-class"}) == "slow-only")
expect("a protected class grant protects", r.process_class({"pid": 5000, "cmd": "reaper-test-gone"}) == "protected")
expect("a class grant is not a memory grant", r.grant_for({"pid": 5000, "cmd": "reaper-test-class"}) is None)
expect("a class grant cannot lower a protected name",
       r.process_class({"pid": 5000, "cmd": "claude reaper-test-class"}) == "protected")
reaper.save_grants([{"id": "c1", "match": "reaper-test-class", "class": "slow-only", "until": time.time() - 1}])
time.sleep(0.01)
os.utime(reaper.GRANTS)
r = reaper.Reaper(dict(reaper.DEFAULTS))
r.reload_grants(time.time())
expect("an expired class grant does nothing", r.process_class({"pid": 5000, "cmd": "reaper-test-class"}) == "restartable")
r.grants = [{"id": "c3", "match": "reaper-test-class", "class": "slow-only", "until": time.time() - 1}]
expect("a class grant ends on time, with no change to the file to prompt a reload",
       r.process_class({"pid": 5000, "cmd": "reaper-test-class"}) == "restartable")
os.remove(reaper.GRANTS)

# 29. lateness is logged on a cadence and at once on a stall, and it needs no decision
clear_log()
t = reaper.TickLateness(every_s=300, alert_s=5)
t.add(0.01, 1000.0, 0.5)
t.add(0.03, 1100.0, 0.5)
expect("no row before the cadence", rows("tick-lateness") == [])
t.add(1.5, 1301.0, 1.6)
got = rows("tick-lateness")
expect("a row at the cadence", len(got) == 1 and got[0]["n"] == 3 and got[0]["max_ms"] == 1500 and got[0]["over_1s"] == 1)
t.add(6.0, 1302.0, 2.0)
expect("a stall logs at once", rows("tick-lateness")[-1].get("stall_s") == 6.0)

# 31. a frontmost lookup that blows up does not stop the scan
idle = spawn("import time; time.sleep(60)", "reaper-test-idle")
r = Confined(cfg(freeze_hold_s=0), {idle.pid})
def boom():
    raise OSError("no lsappinfo")
r.frontmost = boom
try:
    hot_scans(r)
    ok = True
except OSError:
    ok = False
expect("a failing frontmost lookup counts as unknown", ok and idle.poll() is None)
idle.kill(); idle.wait()

# 32. the real daemon loop, stopped the way launchd stops it, gives back what it slowed.
# Every path and reading is faked, and it may touch only the test's own child.
DAEMON = r"""
import os, sys, types
sys.path.insert(0, sys.argv[1])
import reaper
target, tmp = int(sys.argv[2]), sys.argv[3]
reaper.LOG = os.path.join(tmp, "daemon.jsonl")
reaper.STATE = os.path.join(tmp, "state.json")
reaper.ROOT = tmp
reaper.SLOWED = os.path.join(tmp, "slowed.json")
reaper.GRANTS = os.path.join(tmp, "grants.json")
reaper.PAUSE_FILE = os.path.join(tmp, "pause")
reaper.other_reaper_running = lambda: False
reaper.write_sessions = lambda procs: []
sys.modules["sessions"] = types.SimpleNamespace(write_bundle=lambda *a: "none")
open(os.path.join(tmp, "up"), "w").close()
reaper.pressure_level = lambda: 1
reaper.swap_used_bytes = lambda: 0
reaper.frontmost_pid = lambda: -1
real = reaper.os.getloadavg
reaper.os.getloadavg = lambda: (99.0, 99.0, 99.0)
reaper.Reaper.killable = lambda self, p: False
reaper.Reaper.can_touch = lambda self, p: p["pid"] == target
reaper.run(dict(reaper.DEFAULTS, notify=False, tick_s=0.2, scan_every_s=0.5, freeze_hold_s=0,
                cpu_demote_cores=0.5, slow_only=["reaper-test-daemon"], rules=[], lateness_log_every_s=0.5,
                lateness_alert_s="not a number"), False, False)
"""
tmp = tempfile.mkdtemp(prefix="zrecover-daemon-")


def wait_for(test, tries=60):
    for _ in range(tries):
        if test():
            return True
        time.sleep(0.25)
    return False


def start_daemon(burn):
    d = subprocess.Popen([sys.executable, "-c", DAEMON, os.path.dirname(os.path.abspath(reaper.__file__)), str(burn.pid), tmp])
    children.append(d)
    return d


burn = spawn(BURN, "reaper-test-daemon")
daemon = start_daemon(burn)
expect("the running daemon slowed its target", wait_for(lambda: is_background(burn.pid)))
expect("a bad lateness setting does not stop the daemon", daemon.poll() is None)


def daemon_log(action):
    with open(os.path.join(tmp, "daemon.jsonl")) as f:
        return [x for x in map(json.loads, f) if x.get("action") == action]


expect("the running loop records real lateness",
       wait_for(lambda: any(x.get("max_ms", 0) > 0 for x in daemon_log("tick-lateness"))))

# Pausing gives it back, which is how the owner says to leave a job alone, and the daemon carries on.
open(os.path.join(tmp, "pause"), "w").close()
expect("pausing restores it", wait_for(lambda: not is_background(burn.pid)))
expect("and it stays restored while paused", (time.sleep(1.5), not is_background(burn.pid))[1])
os.remove(os.path.join(tmp, "pause"))
expect("resuming can slow it again", wait_for(lambda: is_background(burn.pid)))

daemon.terminate()
daemon.wait(timeout=10)
expect("stopping the daemon restores it", not is_background(burn.pid))

# A second stop during the restore must not interrupt it.
daemon = start_daemon(burn)
wait_for(lambda: is_background(burn.pid))
daemon.terminate()
daemon.terminate()
daemon.wait(timeout=10)
expect("two stops in a row still restore it", not is_background(burn.pid))

# Killed outright, it cannot restore anything, so the next daemon does.
daemon = start_daemon(burn)
wait_for(lambda: is_background(burn.pid))
daemon.kill()
daemon.wait(timeout=10)
expect("a daemon killed outright leaves it slowed", is_background(burn.pid))
daemon = start_daemon(burn)
expect("the next daemon gives it back",
       wait_for(lambda: any("left slowed" in x.get("reason", "") and x["pid"] == burn.pid for x in daemon_log("restore"))))
daemon.terminate()
daemon.wait(timeout=10)
burn.kill(); burn.wait()
shutil.rmtree(tmp)

# 33 onward run the real decisions on a made-up clock and process table, so timing and the
# machine's real load cannot change the answer. Nothing real is signalled.
ALL_APPS = "/Applications/Zed.app/Contents/MacOS/Zed"


class Sim(reaper.Reaper):
    """The real scan, fed invented processes: {pid: [cmd, cores]}. Does not model the kernel
    load average (each step states it), memory, the 4 s a real kill can take, scan jitter,
    a slowed process actually slowing, or CPU contention: every process gets its full demand."""

    def __init__(self, table, **over):
        c = dict(reaper.DEFAULTS, notify=False, rules=[], sessions_every_s=1e12, **over)
        super().__init__(c)
        self.table, self.cpu, self.clock, self.front_pid = table, {}, 1000.0, -1
        self.frontmost = lambda: self.front_pid
        self.changes = []

    def step(self, dt=10.0, load=3.0):
        self.clock += dt
        for pid, (_, cores) in self.table.items():
            self.cpu[pid] = self.cpu.get(pid, 0.0) + cores * dt
        real = reaper.snapshot, reaper.kill, reaper.set_background
        reaper.snapshot = lambda: {pid: {"pid": pid, "ppid": 1, "cpu_s": self.cpu[pid], "mem": 0, "cmd": row[0]}
                                   for pid, row in self.table.items()}
        reaper.kill = self.fake_kill
        reaper.set_background = self.fake_background
        try:
            self.scan(self.clock, 1, 0, load)
        finally:
            reaper.snapshot, reaper.kill, reaper.set_background = real

    def fake_kill(self, pid):
        self.table.pop(pid, None)
        return True

    def fake_background(self, pid, on):
        self.changes.append((pid, on))
        return True

    def run_for(self, seconds, **kw):
        for _ in range(int(seconds / 10)):
            self.step(**kw)


def actions(kind):
    return [x["pid"] for x in rows(kind)]


BIG, OTHER = 200, 201
SRV = "bun server.ts"

# 33. the whole sequence for a clear runaway fits inside the 149 s WindowServer watchdog
clear_log()
s = Sim({BIG: [SRV, 8.0], OTHER: ["other", 1.0]}, freeze_min_cores=4.0)
s.step()
start = s.clock
while BIG in s.table and s.clock - start < 300:
    s.step()
expect("a clear runaway dies with time to spare, counted from the freeze starting",
       BIG not in s.table and s.clock - start <= 100)
expect("not before its notice has run", s.clock - start >= s.cfg["freeze_hold_s"] + s.cfg["freeze_warn_s"])
expect("the kill and countdown rows name the burners",
       rows("kill")[0]["burners"] and rows("kill-countdown")[0]["burners"])

# 34. a countdown does not survive a pause or the Mac sleeping
clear_log()
s = Sim({BIG: [SRV, 8.0]}, freeze_hold_s=0)
s.run_for(20)
expect("a countdown is running", actions("kill-countdown") == [BIG])
s.step(dt=3600)
expect("after a long gap there is no kill", BIG in s.table)
expect("and the owner gets a fresh notice", actions("kill-countdown") == [BIG, BIG])
s.on_pause()
expect("pausing drops any countdown", s.pending == {} and s.freeze_since is None)

# A shorter gap can be the stall this rule exists for, so it must not delay the kill.
clear_log()
s = Sim({BIG: [SRV, 8.0]}, freeze_hold_s=0)
s.run_for(20)
s.step(dt=60)
expect("a 60 s stall does not restart the notice", BIG not in s.table and actions("kill-countdown") == [BIG])
clear_log()
s = Sim({BIG: [SRV, 8.0]}, freeze_hold_s=0)
s.run_for(20)
s.step(dt=200)
expect("a gap past the watchdog does", BIG in s.table and actions("kill-countdown") == [BIG, BIG])

# 34b. if it has mostly stopped burning, it has cleared; a mere wobble has not
clear_log()
s = Sim({BIG: [SRV, 8.0], 300: ["protected-load", 4.0]}, protected=["protected-load"],
        freeze_hold_s=0, freeze_min_cores=4.0, freeze_min_share=0.25)
s.run_for(20)
s.table[BIG][1] = 3.0
s.step()
expect("a target down to under half its burn is called off", BIG in s.table and actions("kill-cancelled") == [BIG])
clear_log()
s = Sim({BIG: [SRV, 4.5], 300: ["protected-load", 4.0]}, protected=["protected-load"],
        freeze_hold_s=0, freeze_min_cores=4.0, freeze_min_share=0.25)
s.run_for(20)
s.table[BIG][1] = 2.3
s.step()
expect("one under the eased floor is too", actions("kill-cancelled") == [BIG])
clear_log()
s = Sim({BIG: [SRV, 4.5], 300: ["protected-load", 4.0]}, protected=["protected-load"],
        freeze_hold_s=0, freeze_min_cores=4.0, freeze_min_share=0.25)
s.run_for(20)
s.table[BIG][1] = 3.0
s.run_for(60)
expect("a wobble above both still dies", BIG not in s.table)

# 35. one failed frontmost lookup changes nothing, and unknown never erases progress
s = Sim({BIG: [SRV, 8.0]}, cpu_demote_after_s=0, cpu_kill_after_s=20, freeze_warn_s=0)
s.step(load=1.2)
s.step(load=1.2)
expect("the ladder demoted it", BIG in s.demoted_at)
clear_log()
s.front_pid = None
s.frontmost = lambda: None
s.step(load=1.2)
expect("a failed lookup restores nothing", rows("restore") == [] and BIG in s.demoted_at)
s.cfg["front_stale_s"] = -1    # the last good answer is now too old to reuse
s.step(load=1.2)
s.step(load=1.2)
expect("a long outage kills nothing", BIG in s.table)
expect("and still erases nothing", rows("restore") == [] and BIG in s.demoted_at)
s.frontmost = lambda: -1
s.step(load=1.2)
expect("the kill resumes when the lookup works again", BIG not in s.table)

clear_log()
s = Sim({BIG: [SRV, 8.0]}, freeze_hold_s=0)
s.step()
s.step()
s.frontmost = lambda: None
s.step()
expect("one failed lookup does not call off a countdown", rows("kill-cancelled") == [] and BIG in s.pending)

# The owner may have just switched to this app, so a reused answer can never finish a kill.
s.run_for(50)
expect("a reused answer does not finish the kill", BIG in s.table and s.front_stale)
s.frontmost = lambda: -1
s.step()
expect("a fresh answer does", BIG not in s.table)
clear_log()
s = Sim({BIG: [SRV, 8.0]}, freeze_hold_s=0)
s.run_for(20)
s.cfg["front_stale_s"] = -1
s.frontmost = lambda: None
s.run_for(30)
expect("a countdown waits out a long outage", rows("kill-cancelled") == [] and BIG in s.pending)
s.frontmost = lambda: BIG
s.step()
expect("and spares the app if that is what came to the front", BIG in s.table and rows("kill-cancelled") != [])

# 36. the count limit: spaced kills, at most two in the window, then kills can resume
clear_log()
s = Sim({BIG: [SRV, 8.0], OTHER: [SRV, 7.0], 300: [SRV, 6.0]}, freeze_hold_s=0, freeze_min_cores=4.0, freeze_min_share=0.2)
times = []
for _ in range(58):
    n = len(s.table)
    s.step()
    if len(s.table) < n:
        times.append(s.clock)
expect("two runaways die in the window", len(times) == 2 and len(s.table) == 1)
expect("spaced by the gap", times[1] - times[0] >= s.cfg["freeze_kill_gap_s"])
expect("the second is not held much past the gap", times[1] - times[0] <= s.cfg["freeze_kill_gap_s"] + 20)
expect("the limit is logged once", len(rows("freeze-kill-limit")) == 1)
s.run_for(200)
expect("once the window has passed, kills resume", len(s.table) == 0)

# 36b. the limit cannot be stepped around by load dipping under the freeze line
s = Sim({i: [SRV, 6.0] for i in range(100, 108)}, freeze_hold_s=0, freeze_min_cores=4.0, freeze_min_share=0.1)
for i in range(58):
    s.step(load=1.4 if i % 14 == 13 else 3.0)
expect("a one-scan dip does not reset the count", len(s.table) == 6)

# 36c. five ladder countdowns finishing together, freeze or no freeze, kill one
s = Sim({i: [SRV, 6.0] for i in range(100, 105)}, freeze_min_cores=99, cpu_demote_after_s=0, cpu_kill_after_s=0)
s.run_for(100, load=1.2)
expect("the ladder kills one at a time outside a freeze too", len(s.table) == 4)

# 36d. a small process counting down does not hold up a much bigger runaway
clear_log()
s = Sim({BIG: [SRV, 3.0]}, freeze_hold_s=0, freeze_min_cores=1.0)
s.run_for(20)
expect("the small one is counting down", BIG in s.pending)
s.table[OTHER] = [SRV, 14.0]
s.run_for(70)
expect("the runaway takes its place", OTHER not in s.table and BIG in s.table)
expect("and the small one is told it is off", actions("kill-cancelled") == [BIG])

# 37. a kill that failed uses up nothing, and the process does not block the next target
clear_log()
s = Sim({BIG: [SRV, 8.0], OTHER: [SRV, 5.0]}, freeze_hold_s=0, freeze_warn_s=0, freeze_min_cores=4.0, freeze_min_share=0.25)
s.fake_kill = lambda pid: False
s.step()
s.step()
expect("a failed kill is not counted", rows("kill")[0]["ok"] is False and s.cpu_kills == [])
del s.fake_kill
s.run_for(50)
expect("the next target is not blocked", OTHER not in s.table and BIG in s.table)
expect("and the unkillable one is not retried straight away", len(actions("kill")) == 2)

# 37b. ladder kills count towards the limit
s = Sim({BIG: [SRV, 8.0]}, freeze_min_cores=99, freeze_hold_s=0, cpu_demote_after_s=0, cpu_kill_after_s=0, freeze_warn_s=0)
s.run_for(30)
expect("a ladder kill counts", BIG not in s.table and len(s.cpu_kills) == 1)

# 37c. a held countdown does not outlive its freeze
clear_log()
s = Sim({BIG: [SRV, 8.0]}, freeze_hold_s=0, front_stale_s=-1)
s.run_for(20)
s.frontmost = lambda: None
s.step()
expect("it waits while frozen", BIG in s.pending)
s.step(load=1.0)
expect("and is called off when the freeze ends", s.pending == {} and actions("kill-cancelled") == [BIG])

# 37d. a pause gives priority back with one try, and keeps track of what it could not
clear_log()
s = Sim({10: ["emu --x", 8.0]}, freeze_hold_s=0, slow_only=["emu"])
s.step()
s.step()
real_bg = reaper.set_background
reaper.set_background = lambda pid, on: False
s.on_pause()
s.on_pause()
reaper.set_background = real_bg
expect("one try per pause", len(rows("restore")) == 1)
expect("and a refused restore stays tracked", 10 in s.slowed and json.load(open(reaper.SLOWED)) == [10])

# 37e. a bad slowed file never stops the daemon starting
for junk in ("[" + str(10 ** 30) + "]", "[" * 100000, "not json", '{"a": 1}', "[1, -5, null]"):
    with open(reaper.SLOWED, "w") as f:
        f.write(junk)
    reaper.restore_left_behind()
    expect(f"bad slowed file {junk[:12]!r} is survived and cleared", not os.path.exists(reaper.SLOWED))
clear_log()
reaper.restore_left_behind()
expect("no file, the normal start, logs no error", rows("tick-error") == [])

# 38. a share wobbling around the limit does not restart the countdown
clear_log()
s = Sim({BIG: [SRV, 6.0], 300: ["protected-load", 12.0]},
        protected=["protected-load"], freeze_hold_s=0, freeze_min_cores=4.0, freeze_min_share=0.25)
s.step()
for i in range(12):
    s.table[300][1] = 12.0 if i % 2 else 20.0   # share swings between 33% and 23%
    s.step()
expect("a wobbling share still gets killed on the first countdown",
       BIG not in s.table and len(actions("kill-countdown")) == 1)

# 39. with two burners trading the top spot, the one already counting down still dies
clear_log()
s = Sim({BIG: [SRV, 8.0], OTHER: [SRV, 7.0]}, freeze_hold_s=0, freeze_min_cores=4.0, freeze_min_share=0.25)
s.step()
s.step()
for i in range(6):
    s.table.get(BIG, [0, 0])[1] = 6.0
    s.table.get(OTHER, [0, 0])[1] = 9.0
    s.step()
expect("the counted-down burner dies, not the new top one", BIG not in s.table and OTHER in s.table)

# 40. settings that have to stay in step
d = reaper.DEFAULTS
expect("slowing is given back below the freeze line, so the two cannot flap",
       d["restore_below_ratio"] < d["freeze_load_ratio"])

# 41. slowing: main apps, the frontmost app, and the CPU floor
s = Sim({10: [ALL_APPS, 8.0]}, freeze_hold_s=0)
s.run_for(100)
expect("a main app in the background is slowed, never killed", 10 in s.table and 10 in s.slowed)
s = Sim({10: [ALL_APPS, 8.0]}, freeze_hold_s=0)
s.front_pid = 10
s.run_for(50)
expect("the same app in front is left alone", s.changes == [])
s = Sim({10: ["emu --x", 1.0]}, freeze_hold_s=0, slow_only=["emu"], cpu_demote_cores=3.0)
s.run_for(50)
expect("a slow-only process using little CPU is left alone", s.changes == [])
s = Sim({10: ["emu --x", 8.0]}, freeze_hold_s=0, slow_only=["emu"], restore_after_s=40)
s.step()
s.step()
expect("a slow-only burner is slowed in a freeze", s.changes == [(10, True)])
s.step(load=0.5)
s.step(load=0.5)
s.step(load=2.0)
s.step(load=0.5)
s.step(load=0.5)
s.step(load=0.5)
expect("load rising again restarts the wait to restore", s.changes == [(10, True)])
s.step(load=0.5)
s.step(load=0.5)
s.step(load=0.5)
s.step(load=0.5)
expect("a full calm minute restores it", s.changes == [(10, True), (10, False)])
clear_log()
s = Sim({10: ["emu --x", 8.0]}, freeze_hold_s=0, slow_only=["emu"])
s.fake_background = lambda pid, on: False
s.run_for(100)
expect("taskpolicy failing is tried once, not every scan", len(rows("demote")) == 1 and not s.slowed)
del s.fake_background
s.run_for(300)
expect("and again after a while, not never", 10 not in s.slow_refused or 10 in s.slowed)
expect("so it does get slowed", 10 in s.slowed)

clear_log()
s = Sim({10: ["emu --x", 8.0]}, freeze_hold_s=0, slow_only=["emu"], restore_after_s=20)
s.step()
s.step()
s.fake_background = lambda pid, on: False
for _ in range(4):
    s.step(load=0.5)
expect("a refused restore is kept, not forgotten", 10 in s.slowed)
del s.fake_background
s.run_for(40, load=0.5)
expect("and tried again", 10 not in s.slowed and s.changes[-1] == (10, False))

s = Sim({1000: [ALL_APPS, 8.0]}, freeze_hold_s=0)
s.frontmost = lambda: None
s.run_for(50)
expect("a main app is not slowed when the frontmost app is unknown", s.changes == [])


def stop_mid_demote(pid, on):
    raise SystemExit(0)


s = Sim({10: ["emu --x", 8.0]}, freeze_hold_s=0, slow_only=["emu"])
s.step()
s.fake_background = stop_mid_demote
try:
    s.step()
except SystemExit:
    pass
expect("a stop landing mid-demotion still knows what to give back",
       10 in s.slowed and json.load(open(reaper.SLOWED)) == [10])

# 42. a ladder-demoted process that comes to the front gets its priority back
clear_log()
s = Sim({BIG: [SRV, 8.0]}, cpu_demote_after_s=0, cpu_kill_after_s=9999)
s.step(load=0.5)
s.step(load=0.5)
s.front_pid = BIG
s.step(load=0.5)
expect("the app in use is restored", rows("restore")[0]["pid"] == BIG and BIG not in s.demoted_at)
expect("and that row names the burners", rows("restore")[0]["burners"])

# 43. the limit holds the ladder's kill too
s = Sim({BIG: [SRV, 8.0]}, freeze_min_cores=99, freeze_hold_s=0, cpu_demote_after_s=0, cpu_kill_after_s=0, freeze_warn_s=0)
s.cpu_kills = [s.clock, s.clock]
s.run_for(50)
expect("the ladder does not kill past the limit", BIG in s.table)

# 44. apps in ~/Applications count as main apps
expect("an app in ~/Applications is a main app",
       reaper.is_main_app(os.path.expanduser("~/Applications/Foo.app/Contents/MacOS/Foo")))

# 45. rows carry the burners, protected processes included, once rates exist
clear_log()
s = Sim({i: ["keepme", 2.0] for i in range(400, 407)}, protected=["keepme"], freeze_hold_s=0)
s.run_for(30)
named = [x for x in rows("freeze-no-target") if "burners" in x]
expect("exactly one no-target row in a freeze names the burners", len(named) == 1 and len(rows("freeze-no-target")) == 3)
expect("and they include protected ones", all(b["class"] == "protected" for b in named[0]["burners"]))
expect("capped at five", len(named[0]["burners"]) == 5)

# 46. bad grants and settings are skipped, and the watchdog keeps working
reaper.save_grants([{"id": "x", "match": "(", "gb": 5, "until": 1e12}, {"id": "y", "match": "a"},
                    {"id": "z", "match": "a", "until": "soon", "gb": 1}, "not a row",
                    {"id": "w", "match": "a", "class": "weird", "until": 1e12},
                    {"id": "ok", "match": "bun", "gb": 5, "until": 1e12}])
clear_log()
s = Sim({BIG: [SRV, 8.0]}, freeze_hold_s=0, freeze_warn_s=0)
s.step()
s.step()
expect("bad grant rows are skipped and logged", len(s.grants) == 1 and rows("grants-ignored")[0]["count"] == 5)
expect("and rules keep working", BIG not in s.table)
with open(reaper.GRANTS, "w") as f:
    json.dump({"not": "a list"}, f)
s = Sim({BIG: [SRV, 8.0]})
s.step()
expect("a grants file that is not a list counts as none", s.grants == [])
os.remove(reaper.GRANTS)
for bad in ([5], "emu", None):
    expect(f"slow_only={bad!r} does not stop the watchdog", reaper.Reaper(dict(reaper.DEFAULTS, slow_only=bad)).slow_names is None)

# 47. a memory grant ends on time, with no change to the file to prompt a reload
r = reaper.Reaper(dict(reaper.DEFAULTS))
r.grants = [{"id": "m", "match": "bun", "gb": 5, "until": time.time() - 1}]
expect("an expired memory grant stops applying", r.grant_for({"pid": 5, "cmd": "bun x"}) is None)

shutil.rmtree(SCRATCH)

for p in children:
    if p.poll() is None:
        p.kill()
        p.wait()
finish()
