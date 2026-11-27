#!/usr/bin/env python3
"""Tests for the weekly friction audit: who counts as the owner, and whether the scheduled entry point runs.

Record shapes below are copied from real transcripts (field names and combinations), with invented text.
Run: python3 ~/.claude/scripts/style/friction-extract.test.py
"""
import importlib.util, json, os, shutil, stat, subprocess, sys, tempfile, unittest

HERE = os.path.dirname(os.path.abspath(__file__))
LONG = "Here is a long reply. " * 30  # over the 400-character floor for an agent message


def load_extractor(path=None):
    spec = importlib.util.spec_from_file_location("friction_extract_under_test", path or os.path.join(HERE, "friction-extract.py"))
    mod = importlib.util.module_from_spec(spec)
    sys.path.insert(0, os.path.dirname(path or HERE))
    spec.loader.exec_module(mod)
    return mod


def assistant(text=LONG):
    return {"type": "assistant", "timestamp": "2026-11-20T10:00:00.000Z", "sessionId": "s1",
            "message": {"role": "assistant", "model": "m", "content": [{"type": "text", "text": text}]}}


def user(text, **fields):
    return {"type": "user", "isSidechain": False, "timestamp": "2026-11-20T10:01:00.000Z",
            "message": {"role": "user", "content": text}, **fields}


OWNER = dict(turnOrigin="human", origin={"kind": "human"}, promptSource="typed")
# Machine-written records that carry no scaffolding wording, so only the origin fields give them away.
HOOK_NOTE = user("Plain status note with no marker words.", isMeta=True)
PEER_MSG = user("Hello from another session, plain words.", turnOrigin="peer")
TASK_NOTE = user("Build finished, plain words.", turnOrigin="task_notification", origin={"kind": "task-notification"})
KEEPWARM = user("Time to check in, plain words.", isMeta=True, turnOrigin="scheduled", promptSource="system")


def write_transcript(directory, records, name="t.jsonl"):
    p = os.path.join(directory, name)
    with open(p, "w") as f:
        for r in records: f.write(json.dumps(r) + "\n")
    return p


def run_extract(mod, path):
    manifest = path + ".manifest"
    with open(manifest, "w") as f: f.write(json.dumps({"path": path, "project": "p"}) + "\n")
    out = path + ".pairs"
    with open(out, "w") as f: mod.extract(manifest, f)
    with open(out) as f: return [json.loads(l) for l in f]


class OwnerOnlyTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.mod = load_extractor()

    def tearDown(self): shutil.rmtree(self.tmp, ignore_errors=True)

    def pairs(self, *records):
        return run_extract(self.mod, write_transcript(self.tmp, list(records)))

    def test_owner_reply_is_a_pair_and_points_at_its_line(self):
        rows = self.pairs(assistant(), user("why did you restate the file again", **OWNER))
        self.assertEqual(len(rows), 1)
        self.assertEqual((rows[0]["origin"], rows[0]["line"], rows[0]["markers"]), ("human", 2, True))

    def test_machine_written_records_never_count(self):
        for rec in (HOOK_NOTE, PEER_MSG, TASK_NOTE, KEEPWARM):
            with self.subTest(rec=rec.get("turnOrigin") or "isMeta"):
                self.assertEqual(self.pairs(assistant(), rec), [])

    def test_machine_record_between_agent_and_owner_does_not_steal_the_pair(self):
        rows = self.pairs(assistant(), HOOK_NOTE, PEER_MSG, user("ok, do the second one", **OWNER))
        self.assertEqual([r["owner_text"] for r in rows], ["ok, do the second one"])
        self.assertEqual(rows[0]["line"], 4)

    def test_queued_owner_message_counts(self):
        queued = {"type": "attachment", "timestamp": "2026-11-20T10:01:00.000Z", "isSidechain": False,
                  "attachment": {"type": "queued_command", "prompt": "also fix the footer", "origin": {"kind": "human"}}}
        rows = self.pairs(assistant(), queued)
        self.assertEqual([r["owner_text"] for r in rows], ["also fix the footer"])

    def test_queued_task_notification_does_not_count(self):
        queued = {"type": "attachment", "attachment": {"type": "queued_command", "prompt": "bg job done", "origin": {"kind": "task-notification"}}}
        self.assertEqual(self.pairs(assistant(), queued), [])

    def test_slash_command_counts_through_its_arguments_only(self):
        wrapped = ("<command-message>gcc-proposal</command-message>\n<command-name>/gcc-proposal</command-name>\n"
                   "<command-args>file the thing about the extractor</command-args>")
        rows = self.pairs(assistant(), user(wrapped, turnOrigin="human", origin={"kind": "human"}))
        self.assertEqual((rows[0]["via_command"], rows[0]["owner_text"]), ("gcc-proposal", "file the thing about the extractor"))
        bare = "<command-name>/clear</command-name><command-args></command-args>"
        self.assertEqual(self.pairs(assistant(), user(bare, turnOrigin="human", origin={"kind": "human"})), [])

    def test_sidechain_and_sdk_prompts_do_not_count(self):
        self.assertEqual(self.pairs(assistant(), user("sub-agent task text", isSidechain=True, **OWNER)), [])
        self.assertEqual(self.pairs(assistant(), user("headless probe", turnOrigin="human", promptSource="sdk")), [])

    def test_short_agent_message_makes_no_pair(self):
        self.assertEqual(self.pairs(assistant("short"), user("thanks", **OWNER)), [])

    def test_old_record_without_origin_fields_falls_back_to_wording(self):
        self.assertEqual(len(self.pairs(assistant(), user("an old plain owner message"))), 1)
        self.assertEqual(self.pairs(assistant(), user("<system-reminder>old scaffold</system-reminder>")), [])


class MutationTest(unittest.TestCase):
    """The guard needs the opposite proof: with the origin classification reverted, a machine record is taken for the owner."""

    def test_reverting_origin_classification_lets_machine_text_through(self):
        tmp = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, tmp, ignore_errors=True)
        records = [assistant(), HOOK_NOTE, user("the real owner words", **OWNER)]
        real = run_extract(load_extractor(), write_transcript(tmp, records))
        self.assertEqual([r["owner_text"] for r in real], ["the real owner words"])

        mutant_dir = os.path.join(tmp, "mutant"); os.mkdir(mutant_dir)
        shutil.copy(os.path.join(HERE, "friction-extract.py"), mutant_dir)
        with open(os.path.join(mutant_dir, "transcript_origin.py"), "w") as f:
            f.write("def classify(d):\n"
                    "    c = (d.get('message') or {}).get('content')\n"
                    "    return ('legacy_human', c.strip(), False) if d.get('type') == 'user' and isinstance(c, str) else (None, '', False)\n")
        sys.modules.pop("transcript_origin", None)
        try:
            mutant = run_extract(load_extractor(os.path.join(mutant_dir, "friction-extract.py")), write_transcript(tmp, records, "m.jsonl"))
        finally:
            sys.modules.pop("transcript_origin", None)
        self.assertEqual([r["owner_text"] for r in mutant], ["Plain status note with no marker words."])


class ScheduledEntryPointTests(unittest.TestCase):
    """Runs friction-audit.sh the way gcc-cron does: `bash -c 'bash ~/.claude/scripts/style/friction-audit.sh'` under launchd's bare PATH."""

    BARE_PATH = "/usr/bin:/bin:/usr/sbin:/sbin"

    def make_home(self, with_lm=True, strip_path_fix=False):
        home = tempfile.mkdtemp(); self.addCleanup(shutil.rmtree, home, ignore_errors=True)
        style = os.path.join(home, ".claude", "scripts", "style"); os.makedirs(style)
        for name in ("friction-extract.py", "transcript_origin.py"):
            shutil.copy(os.path.join(HERE, name), style)
        with open(os.path.join(HERE, "friction-audit.sh")) as f: script = f.read()
        if strip_path_fix:
            script = "\n".join(l for l in script.splitlines() if not l.startswith('PATH="$PATH:'))
        with open(os.path.join(style, "friction-audit.sh"), "w") as f: f.write(script)
        prompt = os.path.join(home, ".claude", "style", "sweep", "20260820-regfric-fc30", "scripts"); os.makedirs(prompt)
        with open(os.path.join(prompt, "l1-prompt.txt"), "w") as f: f.write("classify")
        proj = os.path.join(home, ".claude", "projects", "proj"); os.makedirs(proj)
        write_transcript(proj, [assistant(LONG * 20), user("why is this so dense", **OWNER)], "s.jsonl")  # over the 10 KB floor
        if with_lm:
            os.makedirs(os.path.join(home, ".local", "bin"))
            lm = os.path.join(home, ".local", "bin", "lm")
            with open(lm, "w") as f:
                f.write('#!/usr/bin/env python3\nimport json, sys\n'
                        'rows = [json.loads(l) for l in sys.stdin if l.strip()]\n'
                        'text = "\\n".join(json.dumps({"id": r["id"], "label": "explicit-feedback"}) for r in rows)\n'
                        'print(json.dumps({"ok": True, "text": text}))\n')
            os.chmod(lm, os.stat(lm).st_mode | stat.S_IXUSR)
        return home

    def run_job(self, home):
        env = {"HOME": home, "PATH": self.BARE_PATH, "USER": "test"}
        return subprocess.run(["/bin/bash", "-c", "bash ~/.claude/scripts/style/friction-audit.sh"], env=env,
                              capture_output=True, text=True, timeout=120)

    def ledger(self, home):
        p = os.path.join(home, ".claude", "style", "friction-ledger.jsonl")
        if not os.path.exists(p): return []
        with open(p) as f: return [json.loads(l) for l in f]

    def test_job_classifies_and_records_pairs_under_the_bare_scheduler_path(self):
        home = self.make_home()
        r = self.run_job(home)
        self.assertEqual(r.returncode, 0, r.stderr)
        row = self.ledger(home)[-1]
        self.assertEqual((row["extracted"], row["pairs"], row["status"], row["labels"]), (1, 1, "ok", {"explicit-feedback": 1}))

    def test_missing_classifier_fails_loudly_and_writes_no_ledger_row(self):
        home = self.make_home(with_lm=False)
        r = self.run_job(home)
        self.assertEqual(r.returncode, 1)
        self.assertIn("lm not found", r.stderr)
        self.assertEqual(self.ledger(home), [])

    def test_mutation_dropping_the_path_fix_breaks_the_job(self):
        home = self.make_home(strip_path_fix=True)
        r = self.run_job(home)
        self.assertEqual(r.returncode, 1, "without the PATH line the stub lm in ~/.local/bin must not be found")


if __name__ == "__main__":
    unittest.main(verbosity=2)
