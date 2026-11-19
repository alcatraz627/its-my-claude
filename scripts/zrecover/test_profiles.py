#!/usr/bin/env python3
"""Profiles decide what a guard may touch, so these pin what each one protects and sheds.
Every process here is made up and every scan is a dry run: nothing real can be killed.

Run: /usr/bin/python3 ~/.claude/scripts/zrecover/test_profiles.py
"""
import json, os, sys, tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import reaper  # noqa: E402
from testlib import expect, finish  # noqa: E402

T = tempfile.mkdtemp()
reaper.CONFIG = os.path.join(T, "config.json")
reaper.LOG = os.path.join(T, "log.jsonl")
reaper.MEMSIZE = 16 * reaper.GB
GB = reaper.GB


def use(**user):
    json.dump(user, open(reaper.CONFIG, "w"))
    return reaper.load_config()


def proc(pid, cmd, mem_gb=1.0):
    return {"pid": pid, "ppid": 1, "cmd": cmd, "mem": int(mem_gb * GB), "cpu": 0.0, "cpu_s": 0.0}


AFFINITY = "/Applications/Affinity.app/Contents/MacOS/Affinity"
AFFINITY2 = "/Applications/Affinity Designer 2.app/Contents/MacOS/Affinity Designer 2"
TOUCH = "/Applications/TouchDesigner.app/Contents/MacOS/TouchDesigner"
CLAUDE_APP = "/Applications/Claude.app/Contents/MacOS/Claude"
CLAUDE_HELPER = "/Applications/Claude.app/Contents/Frameworks/Claude Helper (Renderer).app/Contents/MacOS/Claude Helper (Renderer) --type=renderer"
WHATSAPP = "/Applications/WhatsApp.app/Contents/MacOS/WhatsApp"
MUSIC = "/System/Applications/Music.app/Contents/MacOS/Music"
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
TAB = "/Applications/Google Chrome.app/Contents/Frameworks/Google Chrome Framework.framework/Versions/1/Helpers/Google Chrome Helper (Renderer).app/Contents/MacOS/Google Chrome Helper (Renderer) --type=renderer"
TESTING = "/Users/x/.cache/puppeteer/chrome/mac_arm-150/chrome-mac-arm64/Google Chrome for Testing.app/Contents/MacOS/Google Chrome for Testing --headless"
NODE = "node /Users/x/Code/app/server.js"

# No profile keeps today's behaviour exactly.
cfg = use()
expect("with no profile the built-in caps apply", cfg["kill_proc_gb"] == 24 and len(cfg["rules"]) == 3)

# Sizes follow the machine.
cfg = use(profile="creative")
expect("creative's kill cap is 60% of a 16 GB Mac", cfg["kill_proc_gb"] == 9.6)
expect("its swap warning is 25% of RAM", cfg["swap_warn_gb"] == 4.0)
expect("a rule's cap scales too", cfg["rules"][0]["kill_proc_gb"] == 4.0)
expect("this Mac's own override beats the profile", use(profile="creative", kill_proc_gb=5)["kill_proc_gb"] == 5)

# A broken profile must not stop the guard.
err = sys.stderr
sys.stderr = open(os.devnull, "w")
cfg = use(profile="no-such-profile")
sys.stderr = err
expect("a missing profile falls back to the built-in settings", cfg["kill_proc_gb"] == 24)

# Creative: open work is never a target.
r = reaper.Reaper(use(profile="creative"), dry_run=True)
for label, cmd in (("Affinity", AFFINITY), ("Affinity Designer", AFFINITY2), ("TouchDesigner", TOUCH), ("Claude Desktop", CLAUDE_APP),
                   ("a Claude Desktop helper", CLAUDE_HELPER), ("WhatsApp", WHATSAPP), ("Music", MUSIC)):
    expect("creative never kills %s" % label, not r.killable(proc(1000, cmd)))
expect("creative may close a Chrome tab", r.killable(proc(1001, TAB)))
expect("and knows it as a tab", r.rule_for(proc(1001, TAB))["name"] == "chrome-tab")
expect("Chrome itself is not treated as a tab", r.rule_for(proc(1002, CHROME)) is None)
expect("a project folder named after an app does not protect a process",
       r.killable(proc(1003, "/Users/x/AffinityWork/venv/bin/python server.py")))


def scan(profile, pressure, procs):
    """One dry-run scan over made-up processes, returning what it would do."""
    if os.path.exists(reaper.LOG):
        os.unlink(reaper.LOG)
    rp = reaper.Reaper(use(profile=profile), dry_run=True)
    real = reaper.snapshot, reaper.alive
    reaper.snapshot = lambda: {p["pid"]: p for p in procs}
    reaper.alive = lambda pid: True
    try:
        rp.scan(10000.0, pressure, 0, 0.1)
    finally:
        reaper.snapshot, reaper.alive = real
    if not os.path.exists(reaper.LOG):
        return []
    rows = [json.loads(line) for line in open(reaper.LOG)]
    return [a for a in rows if "pid" in a]


# The case that matters most: critical memory with a huge Affinity document open.
acts = scan("creative", 4, [proc(2001, AFFINITY, 12.0), proc(2002, TAB, 2.0), proc(2003, CHROME, 1.2)])
kills = [a for a in acts if a["action"] == "kill"]
expect("under critical pressure a Chrome tab goes", [a["pid"] for a in kills] == [2002])
expect("Affinity is never in the kill list", not any(a["pid"] == 2001 and a["action"] == "kill" for a in acts))
expect("but its owner hears it has grown",
       any(a["pid"] == 2001 and a["action"] == "warn-size" for a in acts))

acts = scan("creative", 4, [proc(2001, AFFINITY, 12.0), proc(2004, TOUCH, 6.0), proc(2005, WHATSAPP, 2.0)])
expect("with only protected apps running, nothing is killed", not [a for a in acts if a["action"] == "kill"])

acts = scan("creative", 1, [proc(2006, TAB, 5.0)])
expect("a runaway tab is closed with no pressure at all", [a["action"] for a in acts] == ["kill"])

# Engineering: throwaway work goes first.
r = reaper.Reaper(use(profile="engineering"), dry_run=True)
expect("a testing browser is recognised", r.rule_for(proc(3000, TESTING))["name"] == "testing-browser")
expect("Claude Desktop is protected here too", not r.killable(proc(3001, CLAUDE_APP)))
expect("pm2 stays protected", not r.killable(proc(3002, "PM2 v7.0.1: God Daemon (/Users/x/.pm2)")))
acts = scan("engineering", 4, [proc(3003, TESTING, 2.0), proc(3004, "/Applications/Slack.app/Contents/MacOS/Slack", 3.0)])
expect("under pressure a testing browser goes before an ordinary app",
       [a["pid"] for a in acts if a["action"] == "kill"] == [3003])
acts = scan("engineering", 1, [proc(3005, NODE, 9.0)])
expect("a server over its cap is killed", [a["action"] for a in acts] == ["kill"])
expect("no warning for protected apps unless a profile asks",
       not scan("engineering", 1, [proc(3006, CLAUDE_APP, 20.0)]))

finish()
