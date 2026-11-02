"""Checks the leak reaper's judgement on real command lines, and one real kill.

Run: python3 ~/.claude/scripts/dev-servers/reap-leaks.test.py

Does not model a page's network events reaching a real driver; the CPU threshold
for that was reasoned, not measured.
"""
import glob
import importlib.util
import json
import os
import subprocess
import sys
import tempfile
import time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "zrecover"))
from testlib import expect, finish  # noqa: E402

T = tempfile.mkdtemp()
os.environ.update(REAP_DIR=os.path.join(T, "reap"), REAP_LOG=os.path.join(T, "log.jsonl"),
                  REAP_SESSIONS=os.path.join(T, "sessions"))
os.makedirs(os.environ["REAP_SESSIONS"])
PATH = os.path.join(HERE, "reap-leaks.py")
spec = importlib.util.spec_from_file_location("reap_leaks", PATH)
R = importlib.util.module_from_spec(spec)
spec.loader.exec_module(R)

CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
REAL_DIR = os.path.expanduser("~/Library/Application Support/Google/Chrome")
# The Playwright line is the one that blocked the owner's Chrome on 2026-11-02.
PW = CHROME + (" --disable-field-trial-config --enable-automation --headless --no-sandbox --user-data-dir=/var/folders/"
               "t8/T/playwright_chromiumdev_profile-tf2QHr --remote-debugging-pipe --no-startup-window")
HELPER = ("/Applications/Google Chrome.app/Contents/Frameworks/Google Chrome Framework.framework/Versions/156/Helpers/"
          "Google Chrome Helper.app/Contents/MacOS/Google Chrome Helper --type=utility --enable-automation "
          "--user-data-dir=/var/folders/x/playwright")
STEAM = ("/Users/me/Library/Application Support/Steam/Steam.AppBundle/Steam/Contents/Frameworks/Steam Helper.app/"
         "Contents/MacOS/Steam Helper --type=renderer --enable-chrome-runtime --remote-debugging-port=0")

expect("the Playwright browser that blocked Chrome is a testing browser", R.is_testing_browser(PW))
expect("a plain Chrome is the owner's", not R.is_testing_browser(CHROME))
expect("Chrome on the real profile is the owner's even with a debug port",
       not R.is_testing_browser(CHROME + " --remote-debugging-port=9222 --user-data-dir=" + REAL_DIR))
expect("automation with no profile named is left alone", not R.is_testing_browser(CHROME + " --remote-debugging-port=9222"))
expect("a Chrome on a side profile with no automation is still the owner's",
       not R.is_testing_browser(CHROME + " --user-data-dir=/tmp/side-profile"))
expect("a helper process is not a browser", not R.is_testing_browser(HELPER))
expect("Steam's embedded browser is not a testing browser", not R.is_testing_browser(STEAM))
expect("bundled Chromium under automation is a testing browser", R.is_testing_browser(
    "/Users/me/Library/Caches/ms-playwright/chromium-1234/chrome-mac-arm64/Chromium.app/Contents/MacOS/Chromium "
    "--enable-automation --user-data-dir=/tmp/x --remote-debugging-pipe"))
expect("a plain Chrome counts as the real one", R.is_real_chrome(CHROME))
expect("the automated copy does not count as the real one", not R.is_real_chrome(PW))
expect("a helper does not count as the real one", not R.is_real_chrome(HELPER))

PY = "/opt/homebrew/Cellar/python@3.14/3.14.7/Frameworks/Python.framework/Versions/3.14/Resources/Python.app/Contents/MacOS/Python"
expect("the hung vg test is a test run", R.is_test_run(PY + " /var/folders/x/T/vgmut/vg/tests/test_cli.py"))
expect("pytest is a test run", R.is_test_run("/usr/bin/pytest -q"))
expect("python -m pytest is a test run", R.is_test_run("python3 -m pytest -q"))
expect("npm test is a test run", R.is_test_run("npm test"))
expect("a test file named as an editor argument is not", not R.is_test_run("vim test_cli.py"))
expect("a server is not a test run", not R.is_test_run("node server.js --test_mode"))
expect("the scratchpad MCP server is not a test run", not R.is_test_run("node /Users/me/.claude/scratchpad/mcp-server.mjs"))
expect("a runner whose script only mentions test in its folder is not", not R.is_test_run("python3 /x/tests/helpers.py"))

TEMP = "PM2 v7.0.1: God Daemon (/var/folders/t8/k/T/tmp.CoYCHtJ4M3/.pm SILENT=true"
expect("a truncated daemon title from a temp home is found", R.temp_pm2_home(TEMP) is not None)
expect("the real pm2 is never a leak", R.temp_pm2_home("PM2 v7.0.1: God Daemon (/Users/me/.pm2)") is None)
expect("a daemon's app is not a daemon", R.temp_pm2_home("node /var/folders/x/app.js") is None)

expect("idle past the limit is reaped", R.browser_verdict(R.BROWSER_IDLE_S, 9e4, None, False, False)[0] == "REAP")
expect("just under the limit is kept", R.browser_verdict(R.BROWSER_IDLE_S - 1, 9e4, None, False, False)[0] == "active")
expect("a browser whose driver died goes without waiting", R.browser_verdict(0, 9e4, None, True, False)[0] == "REAP")
expect("a just-started unreachable browser gets its grace", R.browser_verdict(0, 1, None, True, False)[0] == "active")
expect("blocking the owner's Chrome shortens the default", R.browser_verdict(R.HIJACK_IDLE_S, 9e4, None, False, True)[0] == "REAP")
expect("blocking the owner's Chrome still needs some idleness", R.browser_verdict(60, 9e4, None, False, True)[0] == "active")
expect("a chosen limit beats the 15 minute default", R.browser_verdict(R.HIJACK_IDLE_S, 9e4, 3600, False, True)[0] == "active")
expect("a chosen limit beats the 2 hour default", R.browser_verdict(R.BROWSER_IDLE_S, 9e4, 3 * 3600, False, False)[0] == "active")
expect("a chosen limit still ends", R.browser_verdict(3600, 9e4, 3600, False, True)[0] == "REAP")
expect("a chosen limit can be shorter than the default", R.browser_verdict(600, 9e4, 300, False, False)[0] == "REAP")
expect("a chosen limit cannot save an unreachable browser", R.browser_verdict(0, 9e4, 3600, True, False)[0] == "REAP")

TTLS = {"session:sid-a": {"minutes": 30}, "pid:42": {"minutes": 90}, "session:sid-big": {"minutes": 9999}}
expect("a session's limit applies to its browser", R.chosen_ttl_s(TTLS, "sid-a", 7) == 1800)
expect("one browser's limit beats its session's", R.chosen_ttl_s(TTLS, "sid-a", 42) == 5400)
expect("another session's limit does not apply", R.chosen_ttl_s(TTLS, "sid-b", 7) is None)
expect("no session and no pid entry means the default", R.chosen_ttl_s(TTLS, None, 7) is None)
expect("a hand-edited limit is still capped at 4 hours", R.chosen_ttl_s(TTLS, "sid-big", 7) == 240 * 60)


def ttl(*args, sid="sid-cli"):
    env = dict(os.environ, CLAUDE_CODE_SESSION_ID=sid) if sid else {k: v for k, v in os.environ.items() if k != "CLAUDE_CODE_SESSION_ID"}
    return subprocess.run([sys.executable, PATH, "ttl"] + list(args), env=env, capture_output=True, text=True)


out = ttl("30", "quick check")
expect("ttl records a choice for the session", out.returncode == 0 and R.load(R.TTLS, {})["session:sid-cli"]["minutes"] == 30)
expect("under 2 hours draws no warning", "warning" not in out.stdout)
out = ttl("180", "long crawl")
expect("over 2 hours is allowed with a warning", "warning" in out.stdout and R.load(R.TTLS, {})["session:sid-cli"]["minutes"] == 180)
out = ttl("600")
expect("over 4 hours is cut to 4", "limited to 240" in out.stdout and R.load(R.TTLS, {})["session:sid-cli"]["minutes"] == 240)
expect("nonsense is refused", ttl("soon").returncode == 2 and ttl("0").returncode == 2)
expect("no session and no pid is refused", ttl("30", sid=None).returncode == 2)
expect("--pid sets one browser", ttl("45", "--pid", "777", sid=None).returncode == 0 and R.load(R.TTLS, {})["pid:777"]["minutes"] == 45)


def browser_procs(cmd, age=9000.0, driver_cpu=10.0, driver_cmd="node /tmp/drive.mjs", driver_ppid=500):
    return {
        500: {"pid": 500, "ppid": 1, "cpu": 1.0, "age": age + 100, "cmd": "claude --model opus"},
        600: {"pid": 600, "ppid": driver_ppid, "cpu": driver_cpu, "age": age + 10, "cmd": driver_cmd},
        700: {"pid": 700, "ppid": 600, "cpu": 50.0, "age": age, "cmd": cmd},
    }


def browser_row(prior, procs, now, listening=None, peers=None):
    rows, state = R.scan_browsers(procs, prior, {}, listening or {}, peers or {}, now)
    return rows[0], state


with open(os.path.join(os.environ["REAP_SESSIONS"], "500.json"), "w") as f:
    json.dump({"sessionId": "sid-live"}, f)

NOW = time.time()
AGE = 3 * 3600.0
PORT = CHROME + " --enable-automation --user-data-dir=/tmp/x --remote-debugging-port=4000 --type-none"
OLD = {"start": NOW - AGE, "last_use": NOW - 3 * 3600, "source": "start", "driver_cpu": 10.0, "endpoints": []}

row, _ = browser_row({"700": dict(OLD)}, browser_procs(PORT, age=AGE), NOW)
expect("a script idling in a live session is reaped past the limit", row["verdict"] == "REAP" and row["source"] == "start")

rows, _ = R.scan_browsers(browser_procs(PORT, age=AGE), {"700": dict(OLD)}, {"session:sid-live": {"minutes": 240}}, {}, {}, NOW)
expect("a whole scan honours the session's chosen limit", rows[0]["verdict"] == "active")

row, _ = browser_row({"700": dict(OLD)}, browser_procs(PORT, age=AGE, driver_cpu=20.0), NOW)
expect("a script working hard keeps its browser mid-use", row["verdict"] == "active" and row["source"] == "driver-working")

row, _ = browser_row({"700": dict(OLD)}, browser_procs(PORT, age=AGE, driver_cpu=11.0), NOW)
expect("a little driver CPU from page traffic does not count as use", row["verdict"] == "REAP")

MCP = "npm exec @playwright/mcp@latest"
row, _ = browser_row({"700": dict(OLD)}, browser_procs(PORT, age=AGE, driver_cmd=MCP, driver_cpu=500.0), NOW)
expect("an MCP server's CPU never counts, however busy its pages are", row["verdict"] == "REAP")

os.makedirs(R.TOUCH_DIR, exist_ok=True)
touch_file = os.path.join(R.TOUCH_DIR, "sid-live")
open(touch_file, "w").close()
row, _ = browser_row({"700": dict(OLD)}, browser_procs(PORT, age=AGE, driver_cmd=MCP), NOW + 1)
expect("an MCP tool call from the owning session keeps the browser", row["verdict"] == "active" and row["source"] == "tool-call")
os.remove(touch_file)

row, _ = browser_row({"700": dict(OLD)}, browser_procs(PORT, age=AGE), NOW, {700: {4000}}, {4000: {"127.0.0.1:5555"}})
expect("a new debugger connection counts as an agent attaching", row["verdict"] == "active" and row["source"] == "debug-attach")

OLD_ATTACHED = dict(OLD, endpoints=["127.0.0.1:5555"])
row, _ = browser_row({"700": OLD_ATTACHED}, browser_procs(PORT, age=AGE), NOW, {700: {4000}}, {4000: {"127.0.0.1:5555"}})
expect("a debugger left connected is not fresh use", row["verdict"] == "REAP")

row, _ = browser_row({"700": dict(OLD, start=NOW - 99999)}, browser_procs(PORT, age=600), NOW)
expect("a reused pid starts its own clock", row["verdict"] == "active")

ORPHAN = browser_procs(PW, age=AGE, driver_ppid=1)
row, _ = browser_row({"700": dict(OLD)}, ORPHAN, NOW)
expect("an orphaned driver script is stopped with its browser", 600 in row["targets"])
row, _ = browser_row({"700": dict(OLD)}, browser_procs(PW, age=AGE), NOW)
expect("a driver still in a live session is left alone", 600 not in row["targets"])

STATE = {"last_pass": NOW - 3 * 3600, "procs": {"700": {"last_use": NOW - 3 * 3600}, "test:1": {"progress_at": NOW - 3 * 3600}}}
R.forgive_sleep(STATE, NOW)
expect("time asleep does not count as idle", abs(STATE["procs"]["700"]["last_use"] - NOW) < 2)
expect("time asleep does not count as hung", abs(STATE["procs"]["test:1"]["progress_at"] - NOW) < 2)
SHORT = {"last_pass": NOW - 300, "procs": {"700": {"last_use": NOW - 3600}}}
R.forgive_sleep(SHORT, NOW)
expect("a normal gap changes nothing", abs(SHORT["procs"]["700"]["last_use"] - (NOW - 3600)) < 2)


def test_rows(prior, cpu, age=9000.0):
    procs = {900: {"pid": 900, "ppid": 500, "cpu": cpu, "age": age, "cmd": "python3 /x/tests/test_cli.py"},
             901: {"pid": 901, "ppid": 900, "cpu": 0.0, "age": age, "cmd": "python3 /x/tests/test_child.py"}}
    return R.scan_tests(procs, prior, {}, NOW)


rows, state = test_rows({}, 1.0)
expect("a run seen first gets a full hung window, not its whole age", rows[0]["verdict"] == "active")
expect("a child test is covered by its parent", len(rows) == 1 and 901 in rows[0]["targets"])
stale = {"test:900": dict(state["test:900"], progress_at=NOW - R.HUNG_S)}
rows, _ = test_rows(stale, 1.0)
expect("a run with no progress for the whole window is reaped", rows[0]["verdict"] == "REAP")
rows, _ = test_rows(stale, 5.0)
expect("any progress resets the window", rows[0]["verdict"] == "active")

# A suite that runs its files one after another: the first burned 400 seconds and left.
peak = {"test:900": dict(state["test:900"], cpu=400.0, progress_at=NOW - 60)}
_, after = test_rows(peak, 2.0)
expect("a finished child lowers the baseline without counting as progress",
       after["test:900"]["cpu"] == 2.0 and abs(after["test:900"]["progress_at"] - (NOW - 60)) < 2)
rows, after = test_rows(after, 30.0)
expect("so the next busy child counts as progress", after["test:900"]["progress_at"] == NOW)

expect("vitest with no run is a watcher", R.is_watcher("node /x/node_modules/.bin/vitest"))
expect("vitest run is not", not R.is_watcher("node /x/node_modules/.bin/vitest run"))
expect("jest --watch is a watcher", R.is_watcher("jest --watch"))
expect("pytest is not", not R.is_watcher("pytest -q"))
watch_procs = {910: {"pid": 910, "ppid": 500, "cpu": 1.0, "age": 9000.0, "cmd": "npm test"},
               911: {"pid": 911, "ppid": 910, "cpu": 1.0, "age": 9000.0, "cmd": "node /x/.bin/vitest"}}
watch_prior = {"test:910": {"start": NOW - 9000.0, "progress_at": NOW - R.HUNG_S, "cpu": 2.0}}
rows, _ = R.scan_tests(watch_procs, watch_prior, {}, NOW)
expect("a silent watcher under npm test is left alone", rows[0]["verdict"] == "active")

expect("a pass never counts its own launchers", os.getppid() not in R.without_self(R.snapshot()))

# A real automated browser, seen through the real ps, stopped by a real signal.
# Bundled Chromium, so the test cannot block the owner's Chrome while it runs.
bundled = sorted(glob.glob(os.path.expanduser(
    "~/Library/Caches/ms-playwright/chromium-*/chrome-mac*/*.app/Contents/MacOS/*")))
if bundled:
    profile = os.path.join(T, "profile")
    chromium = subprocess.Popen([bundled[-1], "--headless", "--enable-automation", "--no-first-run",
                                 "--user-data-dir=" + profile, "--remote-debugging-port=0", "about:blank"],
                                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    time.sleep(3)
    snap = R.snapshot()
    expect("a real automated Chromium is recognised", R.is_testing_browser(snap[chromium.pid]["cmd"]))
    mine = {p: v for p, v in snap.items() if p == chromium.pid or v["ppid"] == chromium.pid}
    real_now = time.time()
    old = {str(chromium.pid): {"start": real_now - snap[chromium.pid]["age"], "last_use": real_now - R.BROWSER_IDLE_S,
                               "source": "start", "driver_cpu": 0, "endpoints": []}}
    rows, fresh = R.scan_browsers(mine, old, {}, {}, {}, real_now)
    only = [r for r in rows if r["pid"] == chromium.pid]
    expect("idle past the limit, it is due a reap", only and only[0]["verdict"] == "REAP")
    expect("its helpers are not judged as browsers", len(rows) == 1)
    R.act(only, fresh, old, False, real_now)
    for _ in range(50):
        if chromium.poll() is not None:
            break
        time.sleep(0.1)
    expect("the real browser stops on the signal", chromium.poll() is not None)
    if chromium.poll() is None:
        chromium.kill()
else:
    print("UNCONFIRMED: no bundled Chromium here, so the real-browser case did not run")

real_chromes = [p for p in R.snapshot().values() if R.is_real_chrome(p["cmd"])]
expect("nothing the owner runs right now reads as a testing browser",
       not any(R.is_testing_browser(p["cmd"]) for p in real_chromes))

# Real processes, the real ps and real signals, scoped to this test's own child.
# Never run a whole pass with a limit of zero: it would stop every test on the machine.
script = os.path.join(T, "test_sleeper.py")
with open(script, "w") as f:
    f.write("import time\ntime.sleep(300)\n")


def real_rows(pid, prior_age, holds=None):
    snap = {pid: R.snapshot()[pid]}
    key = "test:%d" % pid
    prior = {key: {"start": time.time() - snap[pid]["age"], "progress_at": time.time() - prior_age,
                   "cpu": snap[pid]["cpu"]}}
    rows, fresh = R.scan_tests(snap, prior, holds or {}, time.time())
    return rows, fresh, prior


victim = subprocess.Popen([sys.executable, script])
time.sleep(1)
rows, fresh, prior = real_rows(victim.pid, R.HUNG_S + 1)
expect("a dry run reports the reap", "would reap test" in "".join(R.act(rows, fresh, prior, True, time.time())))
time.sleep(0.2)
expect("a dry run stops nothing", victim.poll() is None)
lines = R.act(rows, fresh, prior, False, time.time())
for _ in range(20):
    if victim.poll() is not None:
        break
    time.sleep(0.1)
expect("a real reap stops a real hung test", victim.poll() is not None and "reaped test %d" % victim.pid in "".join(lines))
expect("the reap is logged", "\"kind\": \"test\"" in open(os.environ["REAP_LOG"]).read())

held = subprocess.Popen([sys.executable, script])
time.sleep(1)
subprocess.run([sys.executable, PATH, "hold", str(held.pid), "1", "long run"], capture_output=True, text=True)
rows, fresh, prior = real_rows(held.pid, R.HUNG_S + 1, R.load(R.HOLDS, {}))
R.act(rows, fresh, prior, False, time.time())
time.sleep(0.5)
expect("a held test run survives", held.poll() is None and rows[0]["verdict"] == "held")
held.kill()
finish()
