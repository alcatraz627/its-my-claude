"""Behavior checks for the bounded Codex canonical-write bridge."""
import hashlib
import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).resolve().parents[1] / "bin/gcc-canon.py"


class CanonBridgeTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.home = Path(self.tmp.name)
        self.canon = self.home / ".claude"
        (self.canon / "rules").mkdir(parents=True)
        self.target = self.canon / "rules/example.md"
        self.target.write_text("---\nbrief: old\n---\nOld.\n")

    def manifest(self, path="rules/example.md", content="---\nbrief: new\n---\nNew.\n", expected=None):
        if expected is None:
            expected = hashlib.sha256(self.target.read_bytes()).hexdigest()
        m = self.home / "change.json"
        m.write_text(json.dumps({"schema_version": 1, "changes": [
            {"path": path, "expected_sha256": expected, "content": content}]}))
        return m, hashlib.sha256(m.read_bytes()).hexdigest()

    def call(self, mode, manifest, sha):
        return subprocess.run(["python3", str(SCRIPT), mode, str(manifest), sha],
                              env={**os.environ, "HOME": str(self.home), "GCC_CODEX_SID": "test-codex"},
                              text=True, capture_output=True)

    def test_preview_apply_and_stale_base(self):
        m, sha = self.manifest()
        preview = self.call("check", m, sha)
        self.assertEqual(preview.returncode, 0, preview.stderr)
        self.assertIn("+New.", preview.stdout)
        self.assertEqual(self.target.read_text(), "---\nbrief: old\n---\nOld.\n")
        applied = self.call("apply", m, sha)
        self.assertEqual(applied.returncode, 0, applied.stderr)
        self.assertIn("New.", self.target.read_text())
        self.assertEqual(self.call("apply", m, sha).returncode, 2)
        receipt = json.loads((self.canon / "adapters/codex/state/canon-applies.jsonl").read_text())
        self.assertEqual(receipt["session"], "test-codex")
        self.assertTrue(Path(receipt["backup"]).is_dir())

    def test_manifest_change_and_traversal_rejected(self):
        m, sha = self.manifest()
        m.write_text(m.read_text() + " ")
        self.assertEqual(self.call("apply", m, sha).returncode, 2)
        m, sha = self.manifest(path="../outside.md")
        self.assertEqual(self.call("apply", m, sha).returncode, 2)

    def test_symlink_and_derived_rejected(self):
        (self.canon / "features").symlink_to(self.home)
        m, sha = self.manifest(path="features/escape.md", expected="0" * 64)
        self.assertEqual(self.call("apply", m, sha).returncode, 2)
        self.target.write_text("<!-- DERIVED FILE. NEVER hand-edit. -->\n")
        m, sha = self.manifest()
        self.assertEqual(self.call("apply", m, sha).returncode, 2)


if __name__ == "__main__":
    unittest.main()
