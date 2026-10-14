#!/usr/bin/env python3
"""Tests for the named split_phrase and contrast_list tells in
scripts/style/prose-lint.py. Both are report-only (weight 0): they appear in
the violations and spans but must not move the score, so existing gates keep
their thresholds.

Run:  python3 ~/.claude/scripts/hooks/tests/prose-lint-tells.test.py
"""
import importlib.util, os, subprocess, sys, unittest

PATH = os.environ.get("PROSE_LINT_PATH") or os.path.expanduser("~/.claude/scripts/style/prose-lint.py")
spec = importlib.util.spec_from_file_location("prose_lint", PATH)
pl = importlib.util.module_from_spec(spec)
spec.loader.exec_module(pl)


def tells(text):
    return pl.lint(text).get("violations", {})


class ContrastList(unittest.TestCase):
    def test_not_x_not_y_but_z(self):
        self.assertEqual(tells("This is not a cache problem, not a race, but a stale key in the index.")["contrast_list"], 1)

    def test_not_x_not_y_without_but(self):
        self.assertGreaterEqual(tells("The fix is not a rewrite, not a migration for the whole team.")["contrast_list"], 1)

    def test_semicolon_antithesis(self):
        self.assertGreaterEqual(tells("This isn't about speed; it's about keeping the index honest.")["contrast_list"], 1)

    def test_plain_negation_not_flagged(self):
        self.assertNotIn("contrast_list", tells("The loader does not read the config file before the hook runs."))

    def test_single_not_but_is_left_to_contrastive_scaffold(self):
        v = tells("This is not a cache problem, but a race in the loader.")
        self.assertNotIn("contrast_list", v)
        self.assertEqual(v["contrastive_scaffold"], 1)

    def test_quoted_examples_never_count(self):
        text = "> This is not a cache problem, not a race, but a stale key.\n| not a, not b, but c |\n"
        self.assertNotIn("contrast_list", tells(text))


class SplitPhrase(unittest.TestCase):
    def test_semicolon_splice(self):
        t = "The loader reads the config file and builds the table; the table then feeds every later stage."
        self.assertEqual(tells(t)["split_phrase"], 1)

    def test_colon_splice_with_lowercase_elaboration(self):
        t = "The gate runs on every commit in this repository: it checks each added line against the budget."
        self.assertEqual(tells(t)["split_phrase"], 1)

    def test_list_intro_not_flagged(self):
        t = "The gate covers these directories in the repository: rules, features, conventions, personas."
        self.assertNotIn("split_phrase", tells(t))

    def test_short_label_row_not_flagged(self):
        self.assertNotIn("split_phrase", tells("Mute: touch the file named in the header comment."))

    def test_bullet_and_table_rows_not_flagged(self):
        t = "- The loader reads the config file and builds the table; the table feeds every later stage.\n"
        self.assertNotIn("split_phrase", tells(t))

    def test_clean_sentences_not_flagged(self):
        t = "The loader reads the config file. It builds the table once. Later stages read the table."
        self.assertNotIn("split_phrase", tells(t))


class ScoreUnchanged(unittest.TestCase):
    def test_named_tells_do_not_move_the_score(self):
        self.assertEqual(pl.WEIGHTS["split_phrase"], 0)
        self.assertEqual(pl.WEIGHTS["contrast_list"], 0)

    def test_pinned_score_for_a_text_that_trips_both(self):
        t = ("The loader reads the config file and builds the table; the table then feeds every later stage of the pipeline. "
             "This is not a cache problem, not a race, but a stale key in the index. "
             "The gate runs on commit: it checks each added line against the budget and refuses on a hit. "
             "We use the tool to leverage the data. Short one. Another short one here. " * 3)
        r = pl.lint(t)
        self.assertEqual(r["score"], 5.88)  # same figure as before the tells existed
        self.assertIn("split_phrase", r["violations"])
        self.assertIn("contrast_list", r["violations"])


class CliReport(unittest.TestCase):
    def test_cli_line_names_the_tells(self):
        import tempfile
        with tempfile.NamedTemporaryFile("w", suffix=".md", delete=False) as f:
            f.write("This is not a cache problem, not a race, but a stale key in the index.\n")
        try:
            out = subprocess.run([sys.executable, "-I", PATH, f.name], capture_output=True, text=True).stdout
        finally:
            os.unlink(f.name)
        self.assertIn("tells:", out)
        self.assertIn("contrast_list x1", out)


if __name__ == "__main__":
    unittest.main(verbosity=2)
