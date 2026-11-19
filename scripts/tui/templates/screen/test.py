#!/usr/bin/python3
"""What __NAME__ promises: trying is not saving, a save needs a yes, and it works as installed.

Every test runs against a temporary folder, so nothing here touches the real state.
Run: /usr/bin/python3 __NAME__.test.py
"""
import json
import os
import re
import subprocess
import tempfile
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
TOOL, HELPER = HERE / "__NAME__", HERE / "__NAME__-helper.py"
ANSI = re.compile(r"\x1b\[[0-9;]*m")


class Screen(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.state = Path(self.tmp.name) / "state"
        self.env = dict(os.environ, __UPPER___HOME=str(self.state))

    def tearDown(self):
        self.tmp.cleanup()

    def helper(self, *args, **kwargs):
        return subprocess.run(["/usr/bin/python3", str(HELPER)] + list(args), capture_output=True, text=True, timeout=60, env=self.env, **kwargs)

    def saved(self):
        path = self.state / "saved.json"
        return json.loads(path.read_text()) if path.exists() else {}

    def keys(self):
        return [r.split("\t")[0] for r in self.helper("rows").stdout.splitlines() if not r.startswith("group:")]

    def test_trying_a_value_saves_nothing(self):
        key = self.keys()[0]
        value = self.helper("values", key).stdout.splitlines()[-1].split("\t")[0]
        self.assertEqual(self.helper("try", key, value).returncode, 0)
        self.assertEqual(self.saved(), {})
        self.assertIn("1 change showing, not saved", self.helper("header").stdout)

    def test_saving_needs_a_yes(self):
        key = self.keys()[0]
        self.helper("try", key, self.helper("values", key).stdout.splitlines()[-1].split("\t")[0])
        self.assertEqual(self.helper("save").returncode, 3)
        self.assertEqual(self.saved(), {})
        self.assertEqual(self.helper("save", "--confirmed").returncode, 0)
        self.assertNotEqual(self.saved(), {})

    def test_a_question_with_nobody_to_answer_it_saves_nothing(self):
        key = self.keys()[0]
        self.helper("try", key, self.helper("values", key).stdout.splitlines()[-1].split("\t")[0])
        asked = self.helper("flow", "save", stdin=subprocess.DEVNULL, start_new_session=True)
        self.assertEqual(asked.stdout.strip(), "refresh")
        self.assertEqual(self.saved(), {})

    def test_the_pane_opens_with_the_same_five_lines_for_every_row(self):
        for key in self.keys():
            top = ANSI.sub("", self.helper("detail", key).stdout).splitlines()[:5]
            self.assertRegex(top[1], r"^─{50,}$", key)
            self.assertEqual([line.split()[0] for line in top[2:]], ["showing", "saved", "starts"], key)

    def test_every_row_and_header_fits_the_list_column(self):
        lines = self.helper("rows").stdout.splitlines() + self.helper("header").stdout.splitlines() + self.helper("keys").stdout.splitlines()
        self.assertLessEqual(max(len(ANSI.sub("", line.split("\t")[-1])) for line in lines), 56)

    def test_the_screen_binds_every_key_it_names(self):
        legend, text = ANSI.sub("", self.helper("keys").stdout), TOOL.read_text()
        # A legend cell is 18 characters: the key in the first five, then what it does.
        named = [line[i:i + 5].strip() for line in legend.splitlines() for i in range(0, len(line), 18)]
        self.assertGreaterEqual(len(named), 3)
        for key in named:
            self.assertTrue(re.search(r'--bind "(?:[^"]*,)?%s:' % re.escape(key), text), "the legend names %s but nothing binds it" % key)

    def test_it_works_when_started_through_a_link_in_another_folder(self):
        link = Path(self.tmp.name) / "bin" / "__NAME__"
        link.parent.mkdir()
        link.symlink_to(TOOL)
        out = subprocess.run([str(link), "list"], capture_output=True, text=True, timeout=60, env=self.env)
        self.assertEqual(out.returncode, 0, out.stderr)
        self.assertNotIn("No such file", out.stdout + out.stderr)


if __name__ == "__main__":
    unittest.main()
