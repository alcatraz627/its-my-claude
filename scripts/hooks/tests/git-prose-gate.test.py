#!/usr/bin/env python3
"""Tests for the commit-time prose gate (scripts/hooks/git-prose-gate.py) and
its wiring in git-hooks/pre-commit. Every case runs in a throwaway git repo
under a temp dir; the live ~/.claude repo is never touched.

Run:  python3 ~/.claude/scripts/hooks/tests/git-prose-gate.test.py
Mutation check: point PROSE_GATE_TEST_ROOT at a copy of the tree (it needs
scripts/hooks/git-prose-gate.py, scripts/style/prose-lint.py, git-hooks/pre-commit)
that has one guard weakened, and the matching test must go red.
"""
import os, subprocess, sys, tempfile, unittest

ROOT = os.environ.get("PROSE_GATE_TEST_ROOT") or os.path.expanduser("~/.claude")
GATE = os.path.join(ROOT, "scripts", "hooks", "git-prose-gate.py")
STUB = os.path.join(ROOT, "git-hooks", "pre-commit")
DASH = "—"
CLEAN = "The loader reads the config file. It builds the table once."
DASHED = f"The loader reads the config file {DASH} it builds the table once."


def run(cmd, cwd, env=None):
    e = {**os.environ, "GIT_CONFIG_GLOBAL": "/dev/null", "GIT_CONFIG_SYSTEM": "/dev/null",
         "GIT_AUTHOR_NAME": "t", "GIT_AUTHOR_EMAIL": "t@t", "GIT_COMMITTER_NAME": "t",
         "GIT_COMMITTER_EMAIL": "t@t"}
    if not (env and "PROSE_GATE_BYPASS" in env):
        os.environ.pop("PROSE_GATE_BYPASS", None)
        e.pop("PROSE_GATE_BYPASS", None)
    e.update(env or {})
    return subprocess.run(cmd, cwd=cwd, env=e, capture_output=True, text=True)


def put(repo, rel, text):
    p = os.path.join(repo, rel)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    with open(p, "w") as f:
        f.write(text)


def init(repo, files=None):
    os.makedirs(repo, exist_ok=True)
    run(["git", "init", "-q"], repo)
    for rel, text in (files or {"rules/seed.md": CLEAN + "\n"}).items():
        put(repo, rel, text)
    run(["git", "add", "-A"], repo)
    run(["git", "commit", "-q", "-m", "seed"], repo)


class GateDirect(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.repo = os.path.join(self.tmp.name, "r")
        init(self.repo)

    def tearDown(self):
        self.tmp.cleanup()

    def gate(self, env=None):
        return run([sys.executable, GATE], self.repo, env)

    def stage(self, rel, text):
        put(self.repo, rel, text)
        run(["git", "add", rel], self.repo)

    def test_dashed_added_line_refused(self):
        self.stage("rules/new.md", DASHED + "\n")
        r = self.gate()
        self.assertEqual(r.returncode, 1, r.stderr)
        self.assertIn("rules/new.md", r.stderr)
        self.assertIn("PROSE_GATE_BYPASS=1", r.stderr)

    def test_clean_added_line_passes(self):
        self.stage("rules/new.md", CLEAN + "\n")
        self.assertEqual(self.gate().returncode, 0)

    def test_bypass_env_passes_once(self):
        self.stage("rules/new.md", DASHED + "\n")
        self.assertEqual(self.gate({"PROSE_GATE_BYPASS": "1"}).returncode, 0)
        self.assertEqual(self.gate().returncode, 1)

    def test_en_dash_between_words_refused(self):
        self.stage("conventions/x.md", "The tool reads files–then writes them back.\n")
        self.assertEqual(self.gate().returncode, 1)

    def test_preexisting_dash_not_blamed(self):
        put(self.repo, "rules/old.md", DASHED + "\n")
        run(["git", "add", "-A"], self.repo)
        run(["git", "commit", "-q", "--no-verify", "-m", "old"], self.repo)
        self.stage("rules/old.md", DASHED + "\n" + CLEAN + " More text follows here.\n")
        self.assertEqual(self.gate().returncode, 0)

    def test_moved_dashed_line_not_blamed(self):
        a = "\n".join(f"Plain line number {n} has only plain words in it." for n in range(4))
        put(self.repo, "rules/mv.md", f"{DASHED}\n{a}\n")
        run(["git", "add", "-A"], self.repo)
        run(["git", "commit", "-q", "--no-verify", "-m", "mv"], self.repo)
        self.stage("rules/mv.md", f"{a}\n{DASHED}\n")
        self.assertEqual(self.gate().returncode, 0)

    def test_fence_blockquote_and_table_exempt(self):
        text = f"```\n{DASHED}\n```\n> {DASHED}\n| a | b {DASH} c |\n{CLEAN}\n"
        self.stage("rules/q.md", text)
        self.assertEqual(self.gate().returncode, 0)

    def test_fence_opened_before_hunk_exempt(self):
        self.stage("features/f.md", f"{CLEAN}\n```\ncode\n```\n")
        run(["git", "commit", "-q", "--no-verify", "-m", "f"], self.repo)
        self.stage("features/f.md", f"{CLEAN}\n```\ncode\n{DASHED}\n```\n")
        self.assertEqual(self.gate().returncode, 0)

    def test_out_of_scope_paths_ignored(self):
        for rel in ("notes/n.md", "skills/synced/a/SKILL.md", "style/s.md", "atone/a.md",
                    "i-dream/d.md", "rules/_20261015-x.claude.md", "rules/x.json", "assets/r.md"):
            self.stage(rel, DASHED + "\n")
        self.assertEqual(self.gate().returncode, 0)

    def test_skills_and_claude_md_in_scope(self):
        self.stage("skills/foo/SKILL.md", DASHED + "\n")
        self.assertEqual(self.gate().returncode, 1)
        run(["git", "rm", "-q", "--cached", "-f", "skills/foo/SKILL.md"], self.repo)
        self.stage("CLAUDE.md", DASHED + "\n")
        self.assertEqual(self.gate().returncode, 1)

    def test_verdict_first_opener_refused(self):
        self.stage("personas/p.md", "Done. The loader now reads the config file correctly.\n")
        self.assertEqual(self.gate().returncode, 1)

    def test_contrast_list_refused(self):
        self.stage("rules/r.md", "The fix is not a rule, not a reminder, but a hook that runs at commit time.\n")
        r = self.gate()
        self.assertEqual(r.returncode, 1)
        self.assertIn("contrast list", r.stderr)

    def test_single_negation_passes(self):
        self.stage("rules/r.md", "The hook runs at commit time, not at write time, so shell edits are seen.\n")
        self.assertEqual(self.gate().returncode, 0)


class StubWiring(unittest.TestCase):
    """The real pre-commit stub, run by git, with HOME pointed at a temp dir."""

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        home = self.home = self.tmp.name
        for d in ("scripts/hooks", "scripts/style", "git-hooks"):
            os.makedirs(os.path.join(home, ".claude", d))
        for src, dst in ((GATE, "scripts/hooks/git-prose-gate.py"),
                         (os.path.join(ROOT, "scripts", "style", "prose-lint.py"), "scripts/style/prose-lint.py"),
                         (STUB, "git-hooks/pre-commit")):
            with open(src) as a, open(os.path.join(home, ".claude", dst), "w") as b:
                b.write(a.read())
        self.hooks = os.path.join(home, ".claude", "git-hooks")
        os.chmod(os.path.join(self.hooks, "pre-commit"), 0o755)

    def tearDown(self):
        self.tmp.cleanup()

    def commit(self, repo, text, env=None):
        put(repo, "rules/n.md", text)
        run(["git", "add", "-A"], repo)
        return run(["git", "-c", f"core.hooksPath={self.hooks}", "commit", "-q", "-m", "m"], repo,
                   {"HOME": self.home, **(env or {})})

    def test_live_repo_location_refuses_then_passes(self):
        repo = os.path.join(self.home, ".claude")
        init(repo)
        r = self.commit(repo, DASHED + "\n")
        self.assertNotEqual(r.returncode, 0, r.stderr)
        self.assertIn("PROSE_GATE_BYPASS=1", r.stderr)
        r = self.commit(repo, CLEAN + "\n")
        self.assertEqual(r.returncode, 0, r.stderr)

    def test_bypass_lets_the_commit_through(self):
        repo = os.path.join(self.home, ".claude")
        init(repo)
        r = self.commit(repo, DASHED + "\n", {"PROSE_GATE_BYPASS": "1"})
        self.assertEqual(r.returncode, 0, r.stderr)

    def test_other_repos_pass_through(self):
        repo = os.path.join(self.home, "other")
        init(repo)
        r = self.commit(repo, DASHED + "\n")
        self.assertEqual(r.returncode, 0, r.stderr)


if __name__ == "__main__":
    unittest.main(verbosity=2)
