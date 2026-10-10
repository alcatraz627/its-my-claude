"""Behavioral canaries for local Codex transcript lookup."""

import importlib.machinery
import json
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).resolve().parents[1] / "bin/transcript-search.py"
search = importlib.machinery.SourceFileLoader("transcript_search", str(SCRIPT)).load_module()


class CodexSearch(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        root = Path(self.temp.name)
        active = root / "sessions"
        archived = root / "archived_sessions"
        active.mkdir()
        archived.mkdir()
        self.previous = search.CODEX_ROOTS
        search.CODEX_ROOTS = (active, archived)
        self.addCleanup(setattr, search, "CODEX_ROOTS", self.previous)
        self.active = active
        self.archived = archived

    def write(self, root, uid, source, marker):
        path = root / f"rollout-2026-09-28T00-00-00-{uid}.jsonl"
        rows = [
            {"timestamp": "2026-09-28T00:00:00Z", "type": "session_meta", "payload": {"id": uid, "cwd": "/repo/demo", "source": source}},
            {"timestamp": "2026-09-28T00:00:01Z", "type": "response_item", "payload": {"type": "message", "role": "user", "content": [{"type": "input_text", "text": "# AGENTS.md instructions\n" + marker}]}},
            {"timestamp": "2026-09-28T00:00:02Z", "type": "response_item", "payload": {"type": "message", "role": "user", "content": [{"type": "input_text", "text": "Please find " + marker}]}},
            {"timestamp": "2026-09-28T00:00:03Z", "type": "response_item", "payload": {"type": "message", "role": "assistant", "content": [{"type": "output_text", "text": "Found " + marker}]}},
        ]
        path.write_text("".join(json.dumps(row) + "\n" for row in rows))
        return path

    def test_primary_roles_project_and_source_location(self):
        path = self.write(self.active, "a-b-c-d-e", "cli", "silver-marker")
        rows = search.codex_query("SILVER-marker", "demo", "user", None, None, True, False)
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0]["line"], 3)
        self.assertEqual(rows[0]["transcript_path"], str(path))
        self.assertEqual(rows[0]["source"], "codex")
        self.assertEqual(search.codex_query("silver-marker", "other", "any", None, None, True, False), [])

    def test_subagents_and_archived_are_opt_in(self):
        self.write(self.active, "a-b-c-d-e", {"subagent": "review"}, "copper-marker")
        self.write(self.archived, "f-g-h-i-j", "exec", "copper-marker")
        self.assertEqual(search.codex_query("copper-marker", None, "user", None, None, False, False), [])
        archived = search.codex_query("copper-marker", None, "user", None, None, True, False)
        self.assertEqual(len(archived), 1)
        all_rows = search.codex_query("copper-marker", None, "user", None, None, True, True)
        self.assertEqual(len(all_rows), 2)

    def test_raw_search_finds_nonmessage_event(self):
        path = self.write(self.active, "a-b-c-d-e", "cli", "ordinary")
        with path.open("a") as stream:
            stream.write(json.dumps({"timestamp": "2026-09-28T00:00:04Z", "type": "response_item", "payload": {"type": "function_call_output", "output": "tool-only-marker"}}) + "\n")
        rows = search.raw_query("tool-only-marker", "codex", None, None, None, True, False)
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0]["line"], 5)
        self.assertEqual(rows[0]["event_type"], "response_item")
        self.assertEqual(search.codex_query("tool-only-marker", None, "any", None, None, True, False), [])

    def test_raw_search_excludes_subagents_by_default(self):
        path = self.write(self.active, "a-b-c-d-e", {"subagent": "guardian"}, "guardian-marker")
        self.assertEqual(search.raw_query("guardian-marker", "codex", None, None, None, True, False), [])
        rows = search.raw_query("guardian-marker", "codex", None, None, None, True, True)
        self.assertEqual(len(rows), 3)
        self.assertEqual(rows[0]["transcript_path"], str(path))


if __name__ == "__main__":
    unittest.main()
