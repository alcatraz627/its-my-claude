"""Checks gcc-cron's due-job logic against hand-built schedules.

Run: python3 ~/.claude/scripts/schedule/gcc-cron.test.py
"""
import datetime as dt
import importlib.machinery
import importlib.util
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "zrecover"))
from testlib import expect, finish  # noqa: E402  (shared pass/fail tally)

loader = importlib.machinery.SourceFileLoader("gcc_cron", os.path.join(HERE, "gcc-cron"))
spec = importlib.util.spec_from_loader("gcc_cron", loader)
gc = importlib.util.module_from_spec(spec)
loader.exec_module(gc)

T = dt.datetime
REG = {
    "nightly": {"kind": "daily", "fire_at": "daily@04:00"},
    "wed11": {"kind": "weekly", "fire_at": "weekly@wed@11:00"},
    "first": {"kind": "monthly", "fire_at": "monthly@day1@10:00"},
    "once": {"kind": "one-shot", "fire_at": "2026-10-14T09:30"},
    "off": {"kind": "daily", "fire_at": "daily@04:00", "enabled": False},
    "svc": {"kind": "custom", "fire_at": "custom-schedule"},
}


def names(since, until):
    return [n for n, _ in gc.due_jobs(REG, since, until)]


# 2026-10-14 is a Wednesday.
expect("a one-minute wake on the exact minute fires that job",
       names(T(2026, 10, 14, 10, 59, 30), T(2026, 10, 14, 11, 0, 5)) == ["wed11"])
expect("the minute before does not fire",
       names(T(2026, 10, 14, 10, 58, 30), T(2026, 10, 14, 10, 59, 30)) == [])
expect("the same minute is not fired twice across two wakes",
       names(T(2026, 10, 14, 11, 0, 5), T(2026, 10, 14, 11, 1, 5)) == [])
window = names(T(2026, 10, 13, 0, 0), T(2026, 10, 15, 0, 0))
expect("a disabled job never fires, a custom one is left to its own agent",
       "off" not in window and "svc" not in window)
expect("sleeping through three nights fires the nightly job once",
       names(T(2026, 10, 10, 23, 0), T(2026, 10, 13, 8, 0)).count("nightly") == 1)
expect("the first-of-month job fires only on the 1st",
       names(T(2026, 10, 30, 0, 0), T(2026, 11, 1, 10, 0, 1)) == ["first", "nightly"])
expect("the one-shot fires inside its minute",
       names(T(2026, 10, 14, 9, 29), T(2026, 10, 14, 9, 31)) == ["once"])
expect("a weekly job does not fire on another weekday",
       "wed11" not in names(T(2026, 10, 15, 10, 0), T(2026, 10, 15, 12, 0)))

# Adopted jobs: the registry holds only the interpreter, the plist holds the command.
real = gc.load_json(gc.REGISTRY, {}).get("log-retention")
if real:
    argv = gc.job_argv(real)
    expect("an adopted job runs its plist's full command, not a bare /bin/bash",
           len(argv) > 1 and argv[0] == "/bin/bash")
expect("a generated job runs its own script",
       gc.job_argv({"script": "/x/script.sh"}) == ["/x/script.sh"])

# Review fixes, 2026-10-10.
reg2 = {"adopt": {"kind": "one-shot", "fire_at": "adopted-one-shot@10-14 09:30"}}
expect("an adopted one-shot fires on its month and day",
       [n for n, _ in gc.due_jobs(reg2, T(2026, 10, 14, 9, 29), T(2026, 10, 14, 9, 31))] == ["adopt"])
if real:
    env = gc.job_env(real)
    expect("a moved job keeps its plist PATH", env.get("PATH", "").startswith("/opt/homebrew/bin"))
expect("registry env_vars reach the job",
       gc.job_env({"env_vars": ["FOO=bar=baz"]}).get("FOO") == "bar=baz")

import json, tempfile  # noqa: E402
tmp = tempfile.mkdtemp()
gc.STATE = os.path.join(tmp, "state.json")
gc.REGISTRY = os.path.join(tmp, "registry.json")
marker = os.path.join(tmp, "good-ran")
now = dt.datetime.now().replace(second=0, microsecond=0)
slot = "daily@%02d:%02d" % (now.hour, now.minute)
with open(gc.REGISTRY, "w") as f:
    json.dump({"a-bad": {"kind": "daily", "fire_at": slot, "script": "/no/such/script"},
               "b-good": {"kind": "daily", "fire_at": slot, "script": "/usr/bin/touch",
                          "plist": "", "adopted": False, "out_log": os.path.join(tmp, "logs", "o.log")}}, f)
gc.job_argv = (lambda job: ["/usr/bin/touch", marker] if job["script"] == "/usr/bin/touch" else [job["script"]])
with open(gc.STATE, "w") as f:
    json.dump({"last_tick": (now - dt.timedelta(minutes=1)).strftime("%Y-%m-%dT%H:%M:%S")}, f)
rc = gc.cmd_tick(False)
import time  # noqa: E402
time.sleep(0.5)
expect("a job that cannot start does not stop the next one", os.path.exists(marker))
expect("the tick reports the failure", rc == 1)
expect("the clock still advances after a failed job",
       gc.load_json(gc.STATE, {}).get("last_tick", "") >= now.strftime("%Y-%m-%dT%H:%M"))
with open(gc.STATE, "w") as f:
    f.write('{"last_tick": "garbage"}')
expect("an unreadable clock restarts instead of failing", gc.cmd_tick(False) == 0
       and gc.load_json(gc.STATE, {}).get("last_tick", "garbage") != "garbage")
finish()
