#!/usr/bin/env python3
"""The smoke gate holds a "done" on a changed screen that was never opened, and nothing else.

Run: python3 ~/.claude/scripts/hooks/tui-smoke-stop.test.py
"""
import json
import os
import subprocess
import sys
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
HOOK = os.path.join(HERE, "tui-smoke-stop.py")
SCREEN = '#!/usr/bin/env bash\nls | fzf --preview "cat {}" --bind "enter:accept"\n'
PLAIN = '#!/usr/bin/env bash\necho hello\n'


def user(text):
    return {"type": "user", "message": {"content": text}}


def tool(name, **args):
    return {"type": "assistant", "message": {"content": [{"type": "tool_use", "name": name, "input": args}]}}


def result():
    return {"type": "user", "message": {"content": [{"type": "tool_result", "content": "ok"}]}}


def said(text):
    return {"type": "assistant", "message": {"content": [{"type": "text", "text": text}]}}


class Gate(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.screen = os.path.join(self.tmp.name, "mytool")
        self.plain = os.path.join(self.tmp.name, "other.sh")
        with open(self.screen, "w") as f:
            f.write(SCREEN)
        with open(self.plain, "w") as f:
            f.write(PLAIN)

    def tearDown(self):
        self.tmp.cleanup()

    def run_hook(self, rows, session="abcd1234"):
        transcript = os.path.join(self.tmp.name, "t-%s.jsonl" % session)
        with open(transcript, "w") as f:
            f.write("\n".join(json.dumps(r) for r in rows) + "\n")
        env = dict(os.environ, TUI_SMOKE_GATE_STATE=os.path.join(self.tmp.name, "state"), HOME=os.environ["HOME"])
        out = subprocess.run([sys.executable, HOOK], input=json.dumps({"session_id": session, "transcript_path": transcript}),
                             capture_output=True, text=True, timeout=30, env=env)
        return json.loads(out.stdout) if out.stdout.strip() else None

    def test_a_done_claim_on_an_unopened_screen_is_held(self):
        verdict = self.run_hook([user("build it"), tool("Edit", file_path=self.screen), result(), said("The screen is built and works.")])
        self.assertEqual(verdict["decision"], "block")
        self.assertIn("mytool", verdict["reason"])
        self.assertIn("smoke.sh", verdict["reason"])

    def test_a_smoke_run_after_the_edit_lets_it_through(self):
        rows = [user("build it"), tool("Edit", file_path=self.screen), result(),
                tool("Bash", command="bash ~/.claude/scripts/tui/smoke.sh -- mytool"), result(), said("Built and working.")]
        self.assertIsNone(self.run_hook(rows))

    def test_a_smoke_run_before_the_last_edit_does_not_count(self):
        rows = [user("build it"), tool("Bash", command="bash ~/.claude/scripts/tui/smoke.sh -- mytool"), result(),
                tool("Edit", file_path=self.screen), result(), said("Fixed, it works now.")]
        self.assertEqual(self.run_hook(rows)["decision"], "block")

    def test_other_files_and_other_turns_are_left_alone(self):
        self.assertIsNone(self.run_hook([user("x"), tool("Edit", file_path=self.plain), result(), said("Done.")]))
        earlier = [user("build it"), tool("Edit", file_path=self.screen), result(), said("Still going."), user("thanks"), said("Done.")]
        self.assertIsNone(self.run_hook(earlier))

    def test_no_claim_or_an_honest_gap_passes(self):
        self.assertIsNone(self.run_hook([user("x"), tool("Edit", file_path=self.screen), result(), said("I changed the header. More to do.")]))
        self.assertIsNone(self.run_hook([user("x"), tool("Edit", file_path=self.screen), result(),
                                         said("The header is fixed. The smoke check was not run, since tmux is missing here.")]))

    def test_an_unrelated_unconfirmed_line_does_not_excuse_it(self):
        # Replay case C13 (bbc94e51, 10 Nov): the reply owned up to load order and reload
        # speed, never to the screen being unopened, and the owner got a blank pane.
        rows = [user("x"), tool("Edit", file_path=self.screen), result(),
                said("The picker is built and works. UNCONFIRMED: how fast Ghostty reloads on a long theme list.")]
        self.assertEqual(self.run_hook(rows, session="c13case1")["decision"], "block")

    def test_an_unconfirmed_line_about_the_smoke_check_or_the_installed_name_passes(self):
        for i, text in enumerate(["The picker is built. UNCONFIRMED: the smoke check, since tmux is missing here.",
                                  "The picker is built. UNCONFIRMED: zterminal run by its installed name."]):
            rows = [user("x"), tool("Edit", file_path=self.screen), result(), said(text)]
            self.assertIsNone(self.run_hook(rows, session="owned%04d" % i), text)

    def test_it_holds_once_then_only_notes(self):
        rows = [user("build it"), tool("Edit", file_path=self.screen), result(), said("Done and working.")]
        self.assertEqual(self.run_hook(rows)["decision"], "block")
        again = self.run_hook(rows)
        self.assertNotIn("decision", again)
        self.assertIn("mytool", again["systemMessage"])

    def test_a_helper_that_draws_with_the_kit_counts_as_a_screen(self):
        helper = os.path.join(self.tmp.name, "mytool-helper.py")
        with open(helper, "w") as f:
            f.write("import sys\nfrom tuikit import dialog\n")
        self.assertEqual(self.run_hook([user("x"), tool("Write", file_path=helper), result(), said("The helper is done.")])["decision"], "block")


if __name__ == "__main__":
    unittest.main()
