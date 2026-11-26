#!/usr/bin/env python3
"""What the monthly prune may and may not touch, run against a throwaway home folder.

Run: python3 ~/.claude/scripts/debris/debris-prune.test.py
"""
import json
import os
import pathlib
import subprocess
import sys
import tempfile
import time
import unittest

SCRIPT = pathlib.Path(__file__).resolve().parent / "debris-prune.py"
OLD = time.time() - 200 * 86400


class Prune(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.home = pathlib.Path(os.path.realpath(self.tmp.name))
        self.proj = self.home / "Code" / "app"
        (self.proj / ".claude").mkdir(parents=True)
        (self.home / ".claude" / "checkpoints").mkdir(parents=True)

    def make(self, rel, old=True, text="x"):
        p = self.home / rel
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(text)
        if old:
            os.utime(p, (OLD, OLD))
        return p

    def run_tool(self, *args):
        env = dict(os.environ, HOME=str(self.home))
        return subprocess.run([sys.executable, str(SCRIPT)] + list(args), capture_output=True, text=True, env=env)

    def run_id(self, out):
        return out.split("(run ")[1].split(")")[0]

    def test_an_old_checkpoint_moves_and_catchup_can_still_find_it(self):
        ck = self.make("Code/app/_20260101-old-a1.claude.md")
        ptr = self.make(".claude/checkpoints/s1.json", text=json.dumps({"session_id": "s1", "checkpoint_path": str(ck)}))
        idx = self.home / ".claude/checkpoints/index.jsonl"
        idx.write_text(json.dumps({"session_id": "s1", "checkpoint_path": str(ck), "ts": "x"}) + "\n")
        done = self.run_tool()
        self.assertEqual(done.returncode, 0, done.stderr)
        self.assertFalse(ck.exists())
        new = json.loads(ptr.read_text())["checkpoint_path"]
        self.assertTrue(os.path.exists(new), new)
        self.assertIn("/.claude/assets/checkpoints/", new)
        self.assertEqual(json.loads(idx.read_text())["checkpoint_path"], new)

    def test_a_record_naming_the_latest_link_follows_the_file(self):
        ck = self.make("Code/app/_20260101-old-a1.claude.md")
        link = self.proj / "_checkpoint.claude.md"
        link.symlink_to(ck.name)
        ptr = self.make(".claude/checkpoints/s1.json", text=json.dumps({"checkpoint_path": str(link)}))
        self.run_tool()
        self.assertFalse(os.path.lexists(link))
        self.assertTrue(os.path.exists(json.loads(ptr.read_text())["checkpoint_path"]))

    def test_a_fresh_checkpoint_stays(self):
        ck = self.make("Code/app/_20261103-new-a1.claude.md", old=False)
        self.run_tool()
        self.assertTrue(ck.exists())

    def test_a_tracked_checkpoint_stays(self):
        ck = self.make("Code/app/_20260101-kept-a1.claude.md")
        subprocess.run(["git", "init", "-q", str(self.proj)], check=True)
        subprocess.run(["git", "-C", str(self.proj), "add", "-f", ck.name], check=True)
        self.run_tool()
        self.assertTrue(ck.exists())

    def test_an_env_backup_never_moves(self):
        env_bak = self.make("Code/app/.claude/.env.bak")
        self.run_tool()
        self.assertTrue(env_bak.exists())

    def test_a_backup_outside_a_claude_folder_is_the_owners(self):
        mine = self.make("Code/app/notes.bak")
        ours = self.make("Code/app/.claude/settings.json.bak")
        self.run_tool()
        self.assertTrue(mine.exists())
        self.assertFalse(ours.exists())

    def test_a_hand_named_note_is_not_debris_however_old(self):
        note = self.make("Documents/Claude/Topics/_index.claude.md")
        self.run_tool()
        self.assertTrue(note.exists())

    def test_protected_snapshots_are_left_alone(self):
        snap = self.make(".claude/atone-snapshots/2026-10-15/events.jsonl.pre-promote.bak.1")
        self.run_tool()
        self.assertTrue(snap.exists())

    def test_the_archive_is_not_swept_again(self):
        kept = self.make(".claude/assets/checkpoints/202601/_20260101-a.claude.md")
        self.run_tool()
        self.assertTrue(kept.exists())

    def test_a_dry_run_changes_nothing(self):
        ck = self.make("Code/app/_20260101-old-a1.claude.md")
        ptr = self.make(".claude/checkpoints/s1.json", text=json.dumps({"checkpoint_path": str(ck)}))
        before = ptr.read_text()
        done = self.run_tool("--dry-run")
        self.assertIn("would archive", done.stdout)
        self.assertTrue(ck.exists())
        self.assertEqual(ptr.read_text(), before)
        self.assertFalse((self.home / ".claude/assets/checkpoints/manifest.jsonl").exists())

    def test_undo_puts_a_run_back(self):
        ck = self.make("Code/app/_20260101-old-a1.claude.md", text="original")
        ptr = self.make(".claude/checkpoints/s1.json", text=json.dumps({"checkpoint_path": str(ck)}))
        link = self.proj / "_checkpoint.claude.md"
        link.symlink_to(ck.name)
        os.utime(link, (OLD, OLD), follow_symlinks=False)
        done = self.run_tool()
        self.assertFalse(ck.exists())
        self.assertFalse(os.path.lexists(link))
        undone = self.run_tool("--undo", self.run_id(done.stdout))
        self.assertEqual(undone.returncode, 0, undone.stderr)
        self.assertEqual(ck.read_text(), "original")
        self.assertEqual(json.loads(ptr.read_text())["checkpoint_path"], str(ck))
        self.assertTrue(link.is_symlink())

    def test_a_same_named_file_from_another_folder_does_not_overwrite(self):
        a = self.make("Code/app/_precompact-checkpoint.claude.md", text="a")
        b = self.make("Code/other/_precompact-checkpoint.claude.md", text="b")
        self.run_tool()
        self.assertFalse(a.exists())
        self.assertFalse(b.exists())
        found = list((self.home / ".claude/assets/checkpoints").rglob("_precompact-checkpoint.claude.md"))
        self.assertEqual(sorted(p.read_text() for p in found), ["a", "b"])


if __name__ == "__main__":
    unittest.main()
