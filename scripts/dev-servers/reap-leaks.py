#!/usr/bin/env python3
"""Stops what agents leave running after the work is over.

Covers three kinds of leak: testing browsers nobody is driving, test runs that
have stopped making progress, and pm2 daemons started from a temporary home.
The owner's own browser and the real pm2 are never touched. gcc-svc runs a pass
every 5 minutes; policy is in features/dev-servers.md.

Usage: reap-leaks.py run [--dry-run] | status | ttl MINUTES [WHY] [--pid PID]
       reap-leaks.py hold PID HOURS [WHY]   (test runs)
Mute:  touch ~/.claude/.no-reap-leaks
"""
import importlib.util
import json
import os
import re
import signal
import subprocess
import sys
import time

HOME = os.path.expanduser("~")
HERE = os.path.dirname(os.path.abspath(__file__))
DIR = os.environ.get("REAP_DIR", os.path.join(HOME, ".claude", "dev-servers", "reap-leaks"))
STATE = os.path.join(DIR, "state.json")
HOLDS = os.path.join(DIR, "holds.json")
TTLS = os.path.join(DIR, "ttls.json")
# The most an agent may choose for a browser's idle limit, and the point past which
# it is told to think again (owner, 2026-11-02).
MAX_TTL_MIN = 240
WARN_TTL_MIN = 120
TOUCH_DIR = os.path.join(DIR, "browser-touch")
LOG = os.environ.get("REAP_LOG", os.path.join(HOME, ".claude", "logs", "reap-leaks.jsonl"))
SESSIONS = os.environ.get("REAP_SESSIONS", os.path.join(HOME, ".claude", "sessions"))
MUTE = os.path.join(HOME, ".claude", ".no-reap-leaks")


def limit(name, default):
    return float(os.environ.get(name, default)) * 60


BROWSER_IDLE_S = limit("REAP_BROWSER_IDLE_MIN", 120)
# An automated copy of the installed Chrome stops the owner opening Chrome at all
# while it runs, so with no real Chrome up it gets far less patience.
HIJACK_IDLE_S = limit("REAP_HIJACK_IDLE_MIN", 15)
UNREACHABLE_GRACE_S = limit("REAP_UNREACHABLE_GRACE_MIN", 5)
HUNG_S = limit("REAP_HUNG_MIN", 120)
PM2_AGE_S = limit("REAP_PM2_AGE_MIN", 120)
# Longer than this between passes means the machine slept. Nobody could have
# used anything, so that time does not count as idle.
SLEEP_GAP_S = 15 * 60
# CPU in one 5-minute pass that counts as a script really driving its browser.
# A page polling an API costs its driver a fraction of this in network events.
DRIVER_BUSY_CPU_S = float(os.environ.get("REAP_DRIVER_BUSY_CPU_S", 3.0))
# Any progress at all across the whole hung window keeps a test run alive.
TEST_PROGRESS_CPU_S = 1.0

BROWSER_EXE = re.compile(r"(Google Chrome( for Testing| Canary| Beta)?|Chromium|chrome-headless-shell|headless_shell"
                         r"|Microsoft Edge|Brave Browser|/firefox|Playwright\.app|pw_run\.sh)", re.I)
AUTOMATION = ("--enable-automation", "--remote-debugging-pipe", "--remote-debugging-port", "--headless",
              "-juggler", "--inspector-pipe")
REAL_PROFILES = tuple(os.path.join(HOME, "Library", "Application Support", p) for p in (
    "Google/Chrome", "Google/Chrome Canary", "Google/Chrome Beta", "Chromium", "BraveSoftware", "Microsoft Edge",
    "Firefox"))
INSTALLED_CHROME = "/Applications/Google Chrome.app/"
TEST_SCRIPT = re.compile(r"(^test[_-].*|.*[_.-]test)\.(py|sh|bash|mjs|cjs|js|ts|tsx)$")
RUNNER = re.compile(r"(^|/)(python[0-9.]*|Python|node|bun|deno|bash|zsh|sh|tsx|ts-node)$")
TEST_TOOL = re.compile(r"(^|/)(pytest|py\.test|vitest|jest|mocha)$")
TEST_SUBCOMMAND = re.compile(r"(^|/)(go|cargo|npm|pnpm|yarn|bun|playwright)$")
TEMP_ROOTS = ("/var/folders/", "/private/var/folders/", "/tmp/", "/private/tmp/")
PM2_DAEMON = re.compile(r"^PM2 v\S+: God Daemon \((.*?)\)?(\s+\S+=\S+)*$")
MCP_DRIVER = re.compile(r"(@playwright/mcp|playwright-mcp|chrome-devtools-mcp|mcp-server|/mcp\b)")


def duration_s(text):
    """Seconds from ps's etime ([[dd-]hh:]mm:ss) or time (mmm:ss.ss)."""
    days, _, rest = text.rpartition("-")
    total = 0.0
    for part in rest.split(":"):
        total = total * 60 + float(part)
    return total + (int(days) * 86400 if days else 0)


def snapshot():
    """Every process of this user, as a dict keyed by pid."""
    out = subprocess.run(["ps", "-axo", "pid=,ppid=,uid=,time=,etime=,command=", "-ww"],
                         capture_output=True, text=True, timeout=20).stdout
    procs, uid = {}, str(os.getuid())
    for line in out.splitlines():
        parts = line.split(None, 5)
        if len(parts) < 6 or parts[2] != uid:
            continue
        try:
            procs[int(parts[0])] = {"pid": int(parts[0]), "ppid": int(parts[1]), "cpu": duration_s(parts[3]),
                                    "age": duration_s(parts[4]), "cmd": parts[5]}
        except ValueError:
            continue
    return procs


def children_of(procs):
    kids = {}
    for p in procs.values():
        kids.setdefault(p["ppid"], []).append(p["pid"])
    return kids


def tree(kids, root):
    seen, stack = [], [root]
    while stack:
        for child in kids.get(stack.pop(), []):
            seen.append(child)
            stack.append(child)
    return seen


def profile_dir(cmd):
    m = re.search(r"--user-data-dir=(.+?)(?= --|$)", cmd) or re.search(r" -profile (\S+)", cmd)
    return m.group(1).strip("\"'") if m else None


def is_testing_browser(cmd):
    """True only for a browser that automation started on a throwaway profile.

    A browser with no automation flag, with no profile named, or on a real profile
    is the owner's, whatever else is true of it. That also covers Claude's tabs in
    the owner's Chrome, which arrive through an extension and carry no flag.
    """
    exe = cmd.split(" --", 1)[0].split(" -juggler", 1)[0]
    if "--type=" in cmd or "Helper" in exe or not BROWSER_EXE.search(exe):
        return False
    if not any(flag in cmd for flag in AUTOMATION):
        return False
    profile = profile_dir(cmd)
    return bool(profile) and not profile.startswith(REAL_PROFILES)


def is_real_chrome(cmd):
    return cmd.startswith(INSTALLED_CHROME) and "--type=" not in cmd and "chrome_crashpad" not in cmd \
        and "Helper" not in cmd.split(" --", 1)[0] and not is_testing_browser(cmd)


def is_test_run(cmd):
    """True for a process that is itself a test run, judged on its first few words
    so a test file merely named in an argument does not count."""
    words = cmd.split()
    if not words:
        return False
    if TEST_TOOL.search(words[0]):
        return True
    if TEST_SUBCOMMAND.search(words[0]) and len(words) > 1 and words[1] == "test":
        return True
    if RUNNER.search(words[0]):
        script = next((w for w in words[1:4] if not w.startswith("-")), "")
        if script in ("pytest", "vitest", "jest", "mocha"):
            return True
        return bool(TEST_SCRIPT.match(os.path.basename(script)))
    return False


def is_watcher(cmd):
    """A test watcher sits silent between saves on purpose, so silence proves nothing.
    Vitest watches unless told `run`, and its default is what a bare terminal gets."""
    words = cmd.split()
    if any(w in ("--watch", "--watchAll", "--ui", "-w") or w.startswith(("--watch=", "--ui=")) for w in words):
        return True
    return any(os.path.basename(w) in ("vitest", "vitest.mjs") for w in words[:3]) and "run" not in words


def temp_pm2_home(cmd):
    """The temporary home of a leaked pm2 daemon, or None for the real one."""
    m = PM2_DAEMON.match(cmd)
    if not m:
        return None
    home = m.group(1)
    return home if home.startswith(TEMP_ROOTS) else None


def owning_session(procs, pid):
    """The live Claude session a process runs under: (claude pid, session id), or (None, None)."""
    seen = 0
    while pid in procs and seen < 40:
        path = os.path.join(SESSIONS, "%d.json" % pid)
        if os.path.exists(path):
            try:
                with open(path) as f:
                    return pid, json.load(f).get("sessionId")
            except (OSError, ValueError):
                return pid, None
        pid = procs[pid]["ppid"]
        seen += 1
    return None, None


def driven_by_mcp(procs, pid):
    """Does the program driving this browser look like an MCP server?"""
    seen = 0
    pid = procs[pid]["ppid"]
    while pid in procs and seen < 6:
        if MCP_DRIVER.search(procs[pid]["cmd"]):
            return True
        pid = procs[pid]["ppid"]
        seen += 1
    return False


def browser_verdict(idle_s, age_s, ttl_s, unreachable, hijacks_chrome):
    """What to do with one testing browser, given how long no agent has used it.
    A limit the agent chose wins over both defaults, but cannot save a browser
    nothing can reach any more."""
    if unreachable and age_s >= UNREACHABLE_GRACE_S:
        return "REAP", "its driver is gone, so nothing can reach it"
    if ttl_s:
        return ("REAP", "idle past the limit its agent chose") if idle_s >= ttl_s else ("active", "")
    if hijacks_chrome and idle_s >= HIJACK_IDLE_S:
        return "REAP", "idle and blocking the owner from opening Chrome"
    if idle_s >= BROWSER_IDLE_S:
        return "REAP", "no agent has used it within the idle limit"
    return "active", ""


def chosen_ttl_s(ttls, sid, pid):
    """The idle limit an agent picked for this browser, or None for the default."""
    entry = ttls.get("pid:%d" % pid) or (ttls.get("session:%s" % sid) if sid else None)
    return min(float(entry["minutes"]), MAX_TTL_MIN) * 60 if entry else None


def load(path, default):
    try:
        with open(path) as f:
            return json.load(f)
    except (OSError, ValueError):
        return default


def save(path, data):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    tmp = "%s.%d.tmp" % (path, os.getpid())
    with open(tmp, "w") as f:
        json.dump(data, f, indent=1, sort_keys=True)
    os.replace(tmp, path)


def log(**row):
    os.makedirs(os.path.dirname(LOG), exist_ok=True)
    with open(LOG, "a") as f:
        f.write(json.dumps(dict(ts=time.strftime("%Y-%m-%dT%H:%M:%S"), **row)) + "\n")


def sockets():
    """Reuse the dev-server keeper's socket sweep: listening ports and their peers."""
    try:
        spec = importlib.util.spec_from_file_location("svc_sample", os.path.join(HERE, "svc-sample.py"))
        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)
        listening, peers, _ = mod.socket_map()
        return listening, peers
    except Exception:
        return {}, {}


def mtime(path):
    try:
        return os.path.getmtime(path)
    except OSError:
        return 0


def same_process(prior, proc, now):
    """A pid can be reused; a matching start time says this is the same process."""
    return bool(prior) and abs(prior.get("start", 0) - (now - proc["age"])) < 120


def scan_browsers(procs, prior, ttls, listening, peers, now):
    rows, state = [], {}
    real_chrome_up = any(is_real_chrome(p["cmd"]) for p in procs.values())
    kids = children_of(procs)
    for proc in procs.values():
        if not is_testing_browser(proc["cmd"]):
            continue
        pid = proc["pid"]
        key = str(pid)
        old = prior.get(key) if same_process(prior.get(key), proc, now) else None
        start = now - proc["age"]
        # A browser first seen when already old may be mid-use; give it a full window.
        first_use = start if proc["age"] < 300 else now
        last_use, source = (old["last_use"], old["source"]) if old else (first_use, "start")
        driver = procs.get(proc["ppid"])
        mcp = driven_by_mcp(procs, pid)
        _, sid = owning_session(procs, pid)

        # The agent's tool calls are the evidence for an MCP browser. Page traffic
        # reaches the MCP server as events, so its CPU says nothing here.
        if mcp and sid:
            touched = mtime(os.path.join(TOUCH_DIR, sid))
            if touched > last_use:
                last_use, source = touched, "tool-call"

        # A script is using its browser while it keeps working, whoever started it.
        driver_cpu = driver["cpu"] if driver else 0
        if old and driver and not mcp and driver_cpu - old.get("driver_cpu", 0) >= DRIVER_BUSY_CPU_S:
            last_use, source = now, "driver-working"

        # A new connection to the debugging port is an agent attaching. Pages never
        # connect to that port, so their traffic cannot look like this.
        endpoints = set()
        for port in listening.get(pid, set()):
            endpoints |= peers.get(port, set())
        if old and endpoints - set(old.get("endpoints", [])):
            last_use, source = now, "debug-attach"

        unreachable = proc["ppid"] == 1 and "--remote-debugging-pipe" in proc["cmd"]
        hijacks = proc["cmd"].startswith(INSTALLED_CHROME) and not real_chrome_up
        idle = now - last_use
        verdict, why = browser_verdict(idle, proc["age"], chosen_ttl_s(ttls, sid, pid), unreachable, hijacks)
        state[key] = {"start": start, "last_use": last_use, "source": source, "driver_cpu": driver_cpu,
                      "endpoints": sorted(endpoints), "cmd": proc["cmd"][:200],
                      "term_at": (old or {}).get("term_at")}
        # Only the browser itself gets the polite signal, and it shuts down its own
        # helpers. The forced stop on the next pass takes the whole family.
        targets = [pid]
        # A script orphaned from its session has no reason to outlive its browser.
        if driver and driver["ppid"] == 1 and not mcp and driver["pid"] != 1:
            targets.append(driver["pid"])
        rows.append({"kind": "browser", "pid": pid, "verdict": verdict, "why": why, "idle_min": round(idle / 60),
                     "source": source, "targets": targets, "family": tree(kids, pid), "cmd": proc["cmd"][:100], "key": key})
    return rows, state


def scan_tests(procs, prior, holds, now):
    rows, state = [], {}
    kids = children_of(procs)
    tests = {p["pid"] for p in procs.values() if is_test_run(p["cmd"])}
    for pid in tests:
        proc = procs[pid]
        # Judge a run from its top: the parent's verdict already covers its children.
        if proc["ppid"] in tests:
            continue
        key = "test:%d" % pid
        old = prior.get(key) if same_process(prior.get(key), proc, now) else None
        family = [pid] + tree(kids, pid)
        cpu = sum(procs[p]["cpu"] for p in family if p in procs)
        start = now - proc["age"]
        progress_at, progress_cpu = (old["progress_at"], old["cpu"]) if old else (start if proc["age"] < 300 else now, cpu)
        # A finished child takes its CPU out of the sum, so the total can fall. Without
        # following it down, later busy children would look like no progress at all.
        if cpu < progress_cpu:
            progress_cpu = cpu
        if cpu - progress_cpu >= TEST_PROGRESS_CPU_S:
            progress_at, progress_cpu = now, cpu
        hold = holds.get(str(pid)) or {}
        held = (hold.get("until") or 0) > now
        stuck = now - progress_at
        watching = any(p in procs and is_watcher(procs[p]["cmd"]) for p in family)
        verdict = "held" if held else "active" if watching else "REAP" if stuck >= HUNG_S else "active"
        state[key] = {"start": start, "progress_at": progress_at, "cpu": progress_cpu, "cmd": proc["cmd"][:200],
                      "term_at": (old or {}).get("term_at")}
        rows.append({"kind": "test", "pid": pid, "verdict": verdict, "why": "no progress within the hung limit",
                     "idle_min": round(stuck / 60), "source": "cpu", "targets": family,
                     "cmd": proc["cmd"][:100], "key": key})
    return rows, state


def scan_pm2(procs, prior):
    rows = []
    kids = children_of(procs)
    for proc in procs.values():
        home = temp_pm2_home(proc["cmd"])
        if not home:
            continue
        verdict = "REAP" if proc["age"] >= PM2_AGE_S else "active"
        rows.append({"kind": "pm2", "pid": proc["pid"], "verdict": verdict, "why": "pm2 daemon from a temporary home",
                     "idle_min": round(proc["age"] / 60), "source": "age", "targets": [proc["pid"]] + tree(kids, proc["pid"]),
                     "cmd": proc["cmd"][:100], "key": "pm2:%d" % proc["pid"]})
    return rows


def signal_all(pids, sig):
    for pid in pids:
        try:
            os.kill(pid, sig)
        except (ProcessLookupError, PermissionError):
            pass


def act(rows, state, prior, dry, now):
    """Ask each target to stop; anything still there a pass later is killed outright."""
    lines = []
    for row in rows:
        if row["verdict"] != "REAP":
            continue
        if dry:
            lines.append("would reap %s %d (%s, %d min): %s" % (row["kind"], row["pid"], row["why"], row["idle_min"], row["cmd"]))
            continue
        entry = state.setdefault(row["key"], dict(prior.get(row["key"]) or {}))
        escalate = bool(entry.get("term_at"))
        if escalate:
            signal_all(row["targets"] + row.get("family", []), signal.SIGKILL)
        else:
            signal_all(row["targets"], signal.SIGTERM)
        entry["term_at"] = entry.get("term_at") or now
        log(event="reap", kind=row["kind"], pid=row["pid"], why=row["why"], idle_min=row["idle_min"],
            signal="KILL" if escalate else "TERM", cmd=row["cmd"])
        lines.append("reaped %s %d (%s, %d min)" % (row["kind"], row["pid"], row["why"], row["idle_min"]))
    return lines


def without_self(procs):
    """Drop this pass and everything that launched it, so it can never stop its own caller."""
    pid = os.getpid()
    while pid in procs:
        pid = procs.pop(pid)["ppid"]
    return procs


def scan(prior, now):
    procs = without_self(snapshot())
    holds = load(HOLDS, {})
    listening, peers = sockets()
    browsers, browser_state = scan_browsers(procs, prior, load(TTLS, {}), listening, peers, now)
    tests, test_state = scan_tests(procs, prior, holds, now)
    return browsers + tests + scan_pm2(procs, prior), dict(browser_state, **test_state)


def forgive_sleep(state, now):
    """Move every clock forward across a gap when no pass ran, usually a sleeping lid."""
    gap = now - state.get("last_pass", now)
    if gap <= SLEEP_GAP_S:
        return
    for entry in (state.get("procs") or {}).values():
        for field in ("last_use", "progress_at"):
            if field in entry:
                entry[field] += gap


def cmd_run(dry):
    if os.path.exists(MUTE):
        return 0
    now = time.time()
    state = load(STATE, {})
    forgive_sleep(state, now)
    prior = state.get("procs") or {}
    rows, fresh = scan(prior, now)
    lines = act(rows, fresh, prior, dry, now)
    for line in lines:
        print(line)
    if not dry:
        save(STATE, {"last_pass": now, "procs": fresh})
    return 0


def cmd_status():
    now = time.time()
    state = load(STATE, {})
    forgive_sleep(state, now)
    rows, _ = scan(state.get("procs") or {}, now)
    if not rows:
        print("no testing browsers, test runs or temporary pm2 daemons running")
    for r in sorted(rows, key=lambda r: (r["kind"], r["pid"])):
        print("%-8s %-7d %-7s idle %5d min (%s) %s" % (r["kind"], r["pid"], r["verdict"], r["idle_min"], r["source"], r["cmd"]))
    return 0


def cmd_ttl(args):
    """Let an agent choose how long its testing browsers may sit idle."""
    pid = None
    if "--pid" in args:
        at = args.index("--pid")
        pid = args[at + 1] if at + 1 < len(args) else ""
        args = args[:at] + args[at + 2:]
    sid = os.environ.get("CLAUDE_CODE_SESSION_ID")
    try:
        minutes = float(args[0])
    except (IndexError, ValueError):
        minutes = 0
    if minutes <= 0 or pid == "" or not (pid or sid):
        print("usage: reap-leaks.py ttl MINUTES [WHY] [--pid PID]\n"
              "Applies to this session's testing browsers, or to one browser with --pid.", file=sys.stderr)
        return 2
    if minutes > MAX_TTL_MIN:
        print("limited to %d minutes, the most a testing browser may sit idle" % MAX_TTL_MIN)
        minutes = MAX_TTL_MIN
    elif minutes > WARN_TTL_MIN:
        print("warning: over %d minutes. Only keep this if the work really needs it: a copy of the installed "
              "Chrome stops the owner opening Chrome while it runs." % WARN_TTL_MIN)
    week_ago = time.time() - 7 * 86400
    ttls = {k: v for k, v in load(TTLS, {}).items() if v.get("at", 0) > week_ago}
    key = "pid:%s" % pid if pid else "session:%s" % sid
    ttls[key] = {"minutes": minutes, "why": " ".join(args[1:]), "at": time.time()}
    save(TTLS, ttls)
    log(event="ttl", key=key, minutes=minutes, why=" ".join(args[1:]))
    print("idle limit set to %g minutes for %s" % (minutes, "browser %s" % pid if pid else "this session's testing browsers"))
    return 0


def cmd_hold(args):
    if len(args) < 2:
        print("usage: reap-leaks.py hold PID HOURS [WHY]", file=sys.stderr)
        return 2
    holds = load(HOLDS, {})
    holds = {k: v for k, v in holds.items() if (v.get("until") or 0) > time.time()}
    holds[args[0]] = {"until": time.time() + float(args[1]) * 3600, "why": " ".join(args[2:])}
    save(HOLDS, holds)
    print("held %s for %s hours" % (args[0], args[1]))
    return 0


def main(argv):
    cmd = argv[0] if argv else "status"
    if cmd == "run":
        return cmd_run("--dry-run" in argv)
    if cmd == "status":
        return cmd_status()
    if cmd == "hold":
        return cmd_hold(argv[1:])
    if cmd == "ttl":
        return cmd_ttl(argv[1:])
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
