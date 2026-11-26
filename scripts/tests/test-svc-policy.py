#!/usr/bin/env python3
"""The rules for what counts as a person using a service, and what stops one.

Run: python3 ~/.claude/scripts/tests/test-svc-policy.py
"""

import importlib.util
import json
import os
import pathlib
import subprocess
import sys
import tempfile
import unittest

HERE = pathlib.Path(__file__).resolve().parent.parent / "dev-servers"


def load(name, file):
    spec = importlib.util.spec_from_file_location(name, HERE / file)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


sample = load("svc_sample", "svc-sample.py")
holds = load("svc_holds", "svc-holds.py")
NOW = 1_000_000.0
STALE = NOW - sample.TAB_REPORT_STALE_S - 1


class WhoIsConnecting(unittest.TestCase):
    def test_background_programs_on_this_machine(self):
        for client in ("curl", "python3", "node", "Switchboard", None):
            self.assertEqual(sample.peer_kind("127.0.0.1:55000", client), "background", client)

    def test_browsers(self):
        self.assertEqual(sample.peer_kind("127.0.0.1:55000", "Google\\x20Chrome\\x20Helper"), "browser")
        self.assertEqual(sample.peer_kind("[::1]:55000", "Safari"), "browser")

    def test_an_agents_test_browser_is_not_a_person(self):
        self.assertEqual(sample.peer_kind("127.0.0.1:55000", "Google\\x20Chrome\\x20for\\x20Testing"), "background")

    def test_other_devices(self):
        self.assertEqual(sample.peer_kind("100.64.0.3:55000", None), "remote")
        self.assertEqual(sample.peer_kind("127.0.0.1:55000", "tailscaled"), "remote")


class WhatCountsAsUse(unittest.TestCase):
    def use(self, kinds=(), touch=0, tab=STALE, idle=0):
        return sample.person_use(set(kinds), touch, tab, idle, NOW)

    def test_a_health_check_is_not_use(self):
        self.assertEqual(self.use(["background"]), (0, ""))

    def test_a_touch_is_use(self):
        self.assertEqual(self.use(touch=NOW - 5), (NOW - 5, "touch"))

    def test_another_device_is_use(self):
        self.assertEqual(self.use(["remote"], idle=9999), (NOW, "remote"))

    def test_browser_counts_only_when_tabs_are_not_reported_and_someone_is_here(self):
        self.assertEqual(self.use(["browser"]), (NOW, "browser"))
        self.assertEqual(self.use(["browser"], idle=sample.PRESENT_S + 1), (0, ""), "nobody at the machine")
        self.assertEqual(self.use(["browser"], tab=NOW - 30), (0, ""), "bfb reports tabs, so a parked tab is nothing")


class TheVerdict(unittest.TestCase):
    def verdict(self, online=True, keep=False, ports=(5100,), age=999, idle=999, limit=120, held=False):
        return sample.reap_verdict(online, keep, list(ports), age, idle, 30, limit, held)

    def test_order(self):
        self.assertEqual(self.verdict(), "REAP")
        self.assertEqual(self.verdict(online=False), "stopped")
        self.assertEqual(self.verdict(keep=True), "protected")
        self.assertEqual(self.verdict(held=True), "held")
        self.assertEqual(self.verdict(ports=()), "no-port(skip)")
        self.assertEqual(self.verdict(age=5), "grace")
        self.assertEqual(self.verdict(idle=60), "active")

    def test_a_service_has_its_own_limit(self):
        self.assertEqual(self.verdict(idle=10, limit=5), "REAP")
        self.assertEqual(self.verdict(idle=10, limit=60), "active")

    def test_a_limit_shorter_than_the_grace_period_still_applies(self):
        self.assertEqual(self.verdict(age=6, idle=6, limit=5), "REAP")
        self.assertEqual(self.verdict(age=3, idle=3, limit=5), "grace", "a fresh start still gets its limit")
        self.assertEqual(self.verdict(age=6, idle=6, limit=120), "grace", "a long limit keeps the full grace")
        self.assertEqual(self.verdict(age=31, idle=31, limit=120), "active", "the grace still ends at 30 minutes")

    def test_the_edges_of_each_window(self):
        self.assertEqual(self.verdict(age=30, idle=30, limit=120), "active", "30 minutes old is out of grace")
        self.assertEqual(self.verdict(age=200, idle=120, limit=120), "REAP", "exactly at the limit stops")

    def test_policy_overrides_defaults(self):
        policy = {"default": {"idle_min": 120}, "services": {"a": {"idle_min": 5}}}
        self.assertEqual(sample.service_policy(policy, "a")["idle_min"], 5)
        self.assertEqual(sample.service_policy(policy, "b")["idle_min"], 120)
        self.assertEqual(sample.service_policy({}, "b"), {})


class Holds(unittest.TestCase):
    def setUp(self):
        self.dir = tempfile.TemporaryDirectory()
        self.path = os.path.join(self.dir.name, "x.json")

    def tearDown(self):
        self.dir.cleanup()

    def read(self):
        with open(self.path) as fh:
            return json.load(fh)

    def test_a_hold_needs_a_length_and_a_reason(self):
        self.assertIn("length", holds.hold(self.path, "a", "soon", "why", "me"))
        self.assertIn("reason", holds.hold(self.path, "a", "4h", "  ", "me"))
        self.assertIn("7d", holds.hold(self.path, "a", "30d", "why", "me"))
        self.assertFalse(os.path.exists(self.path))

    def test_a_hold_ends_and_finished_ones_are_dropped(self):
        self.assertIsNone(holds.hold(self.path, "a", "1h", "load test", "me", now=NOW))
        self.assertEqual(self.read()["a"]["until"], NOW + 3600)
        self.assertIsNone(holds.hold(self.path, "b", "1h", "x", "me", now=NOW + 7200))
        self.assertEqual(list(self.read()), ["b"])

    def test_release(self):
        holds.hold(self.path, "a", "1h", "x", "me")
        holds.release(self.path, "a")
        self.assertEqual(self.read(), {})

    def test_policy_commands(self):
        self.assertIn("reason", holds.set_policy(self.path, "a", ["keep"]))
        self.assertIn("minutes", holds.set_policy(self.path, "a", ["idle", "soon"]))
        self.assertIsNone(holds.set_policy(self.path, "a", ["keep", "the board"]))
        self.assertEqual(self.read()["services"]["a"], {"class": "keep", "why": "the board"})
        self.assertIsNone(holds.set_policy(self.path, "a", ["idle", "5"]))
        self.assertEqual(self.read()["services"]["a"]["idle_min"], 5)
        self.assertIsNone(holds.set_policy(self.path, "a", ["default"]))
        self.assertEqual(self.read()["services"], {})


class ASlowMachine(unittest.TestCase):
    """The socket sweep can run past its limit on a busy machine. That must read as
    "do not know", never as "no service has a port"."""

    PID = 4242

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        root = pathlib.Path(self.tmp.name)
        self.state = root / "state.json"
        self.state.write_text(json.dumps({"app": {
            "ports": [5106], "known_ports": [5106], "endpoints": ["127.0.0.1:1"],
            "lastseen": 1000, "started": 1000, "source": "touch", "status": "online"}}))
        self.bin = root / "bin"
        self.bin.mkdir()

    def lsof(self, body):
        shim = self.bin / "lsof"
        shim.write_text("#!/bin/bash\n" + body + "\n")
        shim.chmod(0o755)

    def run_sample(self):
        apps = [{"name": "app", "pid": self.PID,
                 "pm2_env": {"status": "online", "pm_uptime": 1000 * 1000}}]
        env = dict(os.environ, PATH="%s:%s" % (self.bin, os.environ["PATH"]))
        done = subprocess.run(
            [sys.executable, str(HERE / "svc-sample.py"), "--state", str(self.state), "--mode", "watch",
             "--sweep-timeout", "0.5"],
            input=json.dumps(apps), capture_output=True, text=True, env=env)
        return done.returncode, json.loads(done.stdout)[0], json.loads(self.state.read_text())["app"]

    def test_a_sweep_that_times_out_reaps_nothing_and_forgets_nothing(self):
        self.lsof("sleep 5")
        rc, row, kept = self.run_sample()
        self.assertEqual(rc, 4)
        self.assertEqual(row["verdict"], "unknown(no sweep)")
        self.assertEqual(kept["ports"], [5106])
        self.assertEqual(kept["endpoints"], ["127.0.0.1:1"])

    def test_a_sweep_that_finishes_still_reaps_an_idle_service(self):
        self.lsof('echo "COMMAND PID USER FD TYPE DEVICE SIZE NODE NAME"\n'
                  'echo "bun %d me 5u IPv4 0x1 0t0 TCP 127.0.0.1:5106 (LISTEN)"' % self.PID)
        rc, row, kept = self.run_sample()
        self.assertEqual(rc, 0)
        self.assertEqual(row["verdict"], "REAP")
        self.assertEqual(kept["ports"], [5106])


class TheReapPass(unittest.TestCase):
    def test_a_failed_sample_shows_red_to_launchd(self):
        with tempfile.TemporaryDirectory() as home:
            env = dict(os.environ, HOME=home, PM2_BIN="/bin/false")
            done = subprocess.run(["bash", str(HERE / "svc.sh"), "reap", "--dry-run"],
                                  capture_output=True, text=True, env=env)
        self.assertEqual(done.returncode, 3, done.stderr)
        self.assertIn("nothing reaped", done.stderr)


if __name__ == "__main__":
    unittest.main()
