#!/usr/bin/env python3
"""Drives the zrecover CLI as a subprocess: exit codes, --json shapes, colour
gating, help size, error hints. Nothing here kills or pauses anything; state
writes go to a scratch copy of the suite's files.

Run: /usr/bin/python3 ~/.claude/scripts/zrecover/test_cli.py
"""
import json, os, subprocess, sys, tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from testlib import expect, finish  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
CLI = os.path.join(HERE, "zrecover.py")
PY = "/usr/bin/python3"


def run(*args, env=None):
    e = {**os.environ, "NO_COLOR": "", **(env or {})}
    e.pop("NO_COLOR", None)
    if env and "NO_COLOR" in env:
        e["NO_COLOR"] = env["NO_COLOR"]
    return subprocess.run([PY, CLI, *args], capture_output=True, text=True, env=e)


# help and version
r = run()
expect("bare invocation prints help, exit 0", r.returncode == 0 and "USAGE" in r.stdout and "EXAMPLES" in r.stdout)
expect("help fits in 60 lines", len(r.stdout.splitlines()) <= 60)
expect("help has no ANSI when piped", "\033[" not in r.stdout)
r = run("--version")
expect("--version prints name and version", r.returncode == 0 and r.stdout.startswith("zrecover "))
r = run("help", "crash")
expect("help topic works", r.returncode == 0 and "restore" in r.stdout)
r = run("help", "nope")
expect("unknown help topic: exit 2 with the topic list", r.returncode == 2 and "topics:" in r.stderr)

# errors propose the fix
r = run("bogus")
expect("unknown command: exit 2 and a hint", r.returncode == 2 and "zrecover" in r.stderr)
r = run("stat")
expect("near-miss suggests the command", r.returncode == 2 and "status" in r.stderr)
r = run("explain")
expect("explain without args: usage, exit 2", r.returncode == 2 and "usage" in r.stderr)
r = run("explain", "zzz-no-such-process-zzz")
expect("explain with no match: exit 1 and a pointer", r.returncode == 1 and "zrecover top" in r.stderr)
r = run("revoke", "nope")
expect("revoke unknown id: exit 1, points at grants", r.returncode == 1 and "zrecover grants" in r.stderr)
r = run("top", "--by", "disk")
expect("bad --by value: exit 2", r.returncode == 2)

# --json shapes
r = run("status", "--json")
d = json.loads(r.stdout)
expect("status --json has readings, daemon, grants, top lists",
       all(k in d for k in ("readings", "daemon", "grants", "top_mem", "top_cpu")))
expect("status --json readings carry pressure and load_ratio", "pressure_name" in d["readings"] and "load_ratio" in d["readings"])
r = run("top", "--json", "-n", "3")
d = json.loads(r.stdout)
expect("top --json -n 3 returns 3 rows with verdicts", len(d) == 3 and all("class" in p for p in d))
r = run("rules", "--json")
d = json.loads(r.stdout)
expect("rules --json has globals, rules, protected", all(k in d for k in ("globals", "rules", "protected")))
r = run("plan", "--json")
expect("plan --json has a would list", isinstance(json.loads(r.stdout).get("would"), list))
child = subprocess.Popen([PY, "-c", "import time; time.sleep(30)", "zrecover-cli-test-child"])
r = run("explain", str(child.pid), "--json")
d = json.loads(r.stdout)
expect("explain --json on a python child: the servers rule with limits",
       d and d[0]["class"] == "rule" and d[0]["rule"] == "servers" and d[0]["limits"]["kill_proc_gb"] == 8)
r = run("explain", "zrecover-cli-test-child", "--json")
expect("explain by name finds the child and not the CLI itself", r.returncode == 0 and [x["pid"] for x in json.loads(r.stdout)] == [child.pid])
child.kill()
child.wait()
r = run("explain", "reaper.py", "--json")
expect("explain --json: the daemon is protected", r.returncode == 0 and all(x["class"] == "protected" for x in json.loads(r.stdout)))
r = run("sessions", "--json")
expect("sessions --json has a sessions list", isinstance(json.loads(r.stdout).get("sessions"), list))
r = run("screens", "--json")
expect("screens --json is a list", isinstance(json.loads(r.stdout), list))
r = run("config", "show", "--json")
d = json.loads(r.stdout)
expect("config show --json has effective + overrides + path", all(k in d for k in ("effective", "overrides", "path")))
r = run("daemon", "status", "--json")
expect("daemon status --json has loaded/alive/fresh", all(k in json.loads(r.stdout) for k in ("loaded", "alive", "fresh")))
r = run("doctor", "--json")
d = json.loads(r.stdout)
expect("doctor --json lists checks with fix hints", d["checks"] and all("fix" in c for c in d["checks"]))
expect("doctor exit code mirrors ok", (r.returncode == 0) == d["ok"])

# config set/unset round-trip on a scratch config file
scratch = tempfile.mkdtemp(prefix="zrecover-cli-")
cfgpath = os.path.join(scratch, "config.json")
# point the CLI at the scratch config by running reaper with a patched CONFIG via env? There is no env knob on purpose,
# so exercise the validators through the module directly.
import reaper  # noqa: E402
reaper.CONFIG = cfgpath
import zrecover  # noqa: E402
try:
    zrecover.cmd_config(["set", "kill_proc_gb", "20"])
    expect("config set writes the override", json.load(open(cfgpath))["kill_proc_gb"] == 20)
    try:
        zrecover.cmd_config(["set", "kill_proc_gb", "lots"])
        expect("config set rejects a wrong type", False)
    except SystemExit as e:
        expect("config set rejects a wrong type (exit 2)", e.code == 2)
    try:
        zrecover.cmd_config(["set", "no_such_key", "1"])
        expect("config set rejects an unknown key", False)
    except SystemExit as e:
        expect("config set rejects an unknown key (exit 2)", e.code == 2)
    zrecover.cmd_config(["unset", "kill_proc_gb"])
    expect("config unset removes the override", "kill_proc_gb" not in json.load(open(cfgpath)))
    zrecover.cmd_protect(["add", "TestApp"])
    expect("protect add lands in the override file", "TestApp" in json.load(open(cfgpath))["protected"])
    zrecover.cmd_protect(["rm", "TestApp"])
    expect("protect rm removes it", "TestApp" not in json.load(open(cfgpath))["protected"])
finally:
    for n in os.listdir(scratch):
        os.remove(os.path.join(scratch, n))
    os.rmdir(scratch)

# pause file with expiry, on a scratch path
reaper.PAUSE_FILE = os.path.join(tempfile.gettempdir(), "zrecover-cli-pause")
zrecover.cmd_pause(["--for", "1h"])
expect("pause --for writes an expiry", reaper.paused_until() is not None and reaper.paused_until() != float("inf"))
zrecover.cmd_resume([])
expect("resume clears it", reaper.paused_until() is None)
with open(reaper.PAUSE_FILE, "w") as f:
    f.write("1")
expect("an expired pause file reads as not paused and is removed",
       reaper.paused_until() is None and not os.path.exists(reaper.PAUSE_FILE))

finish()
