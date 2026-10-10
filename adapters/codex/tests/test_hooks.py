"""Behavioral canaries for the Codex patch and completion hooks."""

import importlib.machinery
import json
import os
import tempfile
import unittest
from pathlib import Path


HOOKS = Path(__file__).resolve().parents[1] / "hooks"
patch = importlib.machinery.SourceFileLoader("gcc_patch", str(HOOKS / "pre-tool-patch.py")).load_module()
turn = importlib.machinery.SourceFileLoader("gcc_turn", str(HOOKS / "turn-guard.py")).load_module()


class HookParity(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.home = self.root / "home"
        self.home.mkdir()
        self.repo = self.root / "repo"
        self.repo.mkdir()
        (self.repo / ".git").mkdir()
        turn.STATE = self.root / "state"
        turn.LOCAL_LINK_MUTE = self.home / ".claude/.no-codex-local-link-gate"

    def payload(self, body):
        return {"tool_name": "apply_patch", "cwd": str(self.repo), "tool_input": {"command": "*** Begin Patch\n" + body + "\n*** End Patch"}}

    def test_generated_and_account_paths_block(self):
        result = patch.decision(self.payload("*** Update File: " + str(self.home / ".codex/AGENTS.md") + "\n@@\n-a\n+b"), self.home)
        self.assertEqual(result["decision"], "block")
        result = patch.decision(self.payload("*** Update File: " + str(self.home / ".claude.json") + "\n@@\n-a\n+b"), self.home)
        self.assertEqual(result["decision"], "block")

    def test_credential_assignment_blocks_but_docs_mention_passes(self):
        result = patch.decision(self.payload("*** Update File: " + str(self.home / ".zshrc") + "\n@@\n+export ANTHROPIC_API_KEY=example"), self.home)
        self.assertEqual(result["decision"], "block")
        result = patch.decision(self.payload("*** Add File: guide.md\n+The name ANTHROPIC_API_KEY appears in the docs."), self.home)
        self.assertIsNone(result)

    def test_settings_json_validity_and_update(self):
        target = self.home / ".codex/hooks.json"
        target.parent.mkdir()
        target.write_text('{"hooks": {"Stop": []}}\n')
        bad = self.payload("*** Update File: " + str(target) + '\n@@\n-{"hooks": {"Stop": []}}\n+{"hooks": {"Stop": [42]}}')
        self.assertEqual(patch.decision(bad, self.home)["decision"], "block")
        good = self.payload("*** Update File: " + str(target) + '\n@@\n-{"hooks": {"Stop": []}}\n+{"hooks": {"Stop": [{"hooks": []}]}}')
        self.assertNotEqual((patch.decision(good, self.home) or {}).get("decision"), "block")
        invalid = self.payload("*** Add File: .mcp.json\n+{\"other\": 1}")
        self.assertEqual(patch.decision(invalid, self.home)["decision"], "block")

    def test_project_banned_word_is_opt_in(self):
        folder = self.repo / ".claude"
        folder.mkdir()
        (folder / "banned-vocab.txt").write_text("Impersonation => Access delegation\n")
        blocked = patch.decision(self.payload("*** Add File: notes.md\n+Use impersonation here."), self.home)
        self.assertEqual(blocked["decision"], "block")
        allowed = patch.decision(self.payload("*** Add File: notes.md\n+Use ImpersonationService here."), self.home)
        self.assertIsNone(allowed)

    def test_env_and_symbol_advisories(self):
        (self.repo / "existing.ts").write_text("const x = process.env.SERVICE_TOKEN;\nexport function existingHelper() {}\n")
        result = patch.decision(self.payload("*** Add File: feature.ts\n+const x = process.env.SERVICE_KEY;\n+export function existingHelper() {}"), self.home)
        note = result["hookSpecificOutput"]["additionalContext"]
        self.assertIn("env access", note)
        self.assertIn("resembles", note)
        self.assertIn("duplicate symbol", note)

    def test_comment_and_prose_advisories_use_shared_detectors(self):
        result = patch.decision(self.payload("*** Add File: feature.py\n+# Phase 2: old behavior\n+pass"), Path.home())
        self.assertIn("cleanup-comments", result["hookSpecificOutput"]["additionalContext"])
        result = patch.decision(self.payload("*** Add File: notes.md\n+This is ready — now you can use it."), Path.home())
        self.assertIn("prose linter", result["hookSpecificOutput"]["additionalContext"])

    def post(self, tool, command, response):
        turn.post({"session_id": "session-a", "turn_id": "turn-a", "cwd": str(self.repo), "tool_name": tool, "tool_input": {"command": command}, "tool_response": response})

    def stop(self, message):
        return turn.stop({"session_id": "session-a", "turn_id": "turn-a", "cwd": str(self.repo), "last_assistant_message": message})

    def test_runtime_claim_needs_real_run_or_honest_gap(self):
        command = self.payload("*** Add File: app.py\n+print('hi')")["tool_input"]["command"]
        self.post("apply_patch", command, {"isError": False})
        self.assertEqual(self.stop("Fixed and verified the app.")["decision"], "block")
        self.assertIsNone(self.stop("Updated app.py; runtime UNCONFIRMED."))
        self.post("Bash", "python3 app.py", {"exit_code": 0})
        self.assertIsNone(self.stop("Fixed and verified app.py after running it."))

    def test_static_check_does_not_count_as_runtime(self):
        command = self.payload("*** Add File: app.py\n+print('hi')")["tool_input"]["command"]
        self.post("apply_patch", command, {"isError": False})
        self.post("Bash", "python3 -m py_compile app.py", {"exit_code": 0})
        self.assertEqual(self.stop("Completed and verified app.py.")["decision"], "block")

    def test_next_work_block_once_and_waiting_passes(self):
        message = "## Doing now\n- Finish the tests"
        self.assertEqual(self.stop(message)["decision"], "block")
        self.assertIsNone(self.stop(message))
        next_turn = {"session_id": "session-a", "turn_id": "turn-b", "cwd": str(self.repo), "last_assistant_message": message}
        self.assertEqual(turn.stop(next_turn)["decision"], "block")
        self.assertIsNone(self.stop("## Next steps\nWaiting on owner approval to deploy."))

    def test_relative_deliverable_link_stays_blocked(self):
        relative = "Read [the indictment](.claude/output/indictment.md) for the evidence."
        result = self.stop(relative)
        self.assertEqual(result["decision"], "block")
        self.assertIn("relative deliverable link target", result["reason"])
        self.assertEqual(self.stop(relative)["decision"], "block")

    def test_local_file_link_must_display_full_path(self):
        path = "/Users/me/project/README.md"
        message = f"Read [README.md]({path})"
        result = self.stop(message)
        self.assertEqual(result["decision"], "block")
        self.assertIn("hides its full path", result["reason"])
        self.assertEqual(self.stop(message)["decision"], "block")
        link_only = self.stop(f"Read [{path}]({path})")
        self.assertEqual(link_only["decision"], "block")
        self.assertIn("own plain-text line", link_only["reason"])
        self.assertIsNone(self.stop(f"Read [{path}]({path})\n{path}"))
        self.assertEqual(self.stop(f"Read [{path}]({path})\n`{path}`")["decision"], "block")
        self.assertEqual(self.stop(f"Read [{path}]({path})\n```\n{path}\n```")["decision"], "block")
        nested = "/Users/me/project/report(final).md"
        self.assertEqual(self.stop(f"[report]({nested})")["decision"], "block")
        self.assertEqual(self.stop(f"[report](<{nested}> \"Report\")")["decision"], "block")
        self.assertIsNone(self.stop(f"[{nested}](<{nested}> \"Report\")\n{nested}"))
        elsewhere = "/opt/project/report.txt"
        self.assertEqual(self.stop(f"[report]({elsewhere})")["decision"], "block")
        self.assertIsNone(self.stop(f"[{elsewhere}]({elsewhere})\n{elsewhere}"))

    def test_local_file_links_require_whitespace_before_period(self):
        path = "/Users/me/project/.claude/output/indictment.md"
        result = self.stop(f"Read [{path}]({path}).")
        self.assertEqual(result["decision"], "block")
        self.assertIn("followed immediately by a period", result["reason"])
        self.assertIsNone(self.stop(f"Read [{path}]({path}) .\n{path}"))
        self.assertIsNone(self.stop(f"[{path}]({path})\n{path}"))

    def test_existing_relative_file_in_final_message_blocks(self):
        (self.repo / "README.md").write_text("guide\n")
        self.assertEqual(self.stop("Read README.md for details")["decision"], "block")
        self.assertEqual(self.stop("Read `README.md` for details")["decision"], "block")
        absolute = str(self.repo / "README.md")
        self.assertIsNone(self.stop(f"Read {absolute} for details"))
        self.assertIsNone(self.stop("```sh\ncat README.md\n```"))
        self.assertIsNone(self.stop("Read missing.md for details"))
        self.assertIsNone(self.stop("See https://example.com/README.md for details"))

    def test_link_guard_preserves_normal_markdown_and_examples(self):
        path = "/Users/me/project/report(final).md"
        allowed = [
            "See [documentation](https://example.com/docs).",
            "See [documentation](//example.com/docs).",
            "Use [reference](/docs/reference).",
            f"**[{path}]({path})**\n{path}",
            f"*[{path}]({path})*\n{path}",
            f"|[{path}]({path})|\n{path}",
            f"[{path}]({path}),\n{path}",
            "[home](https://example.com/report.md)",
            "![image](docs/image.png).",
            "[reference][report]",
            "```markdown\n[relative](docs/file.md).\n```",
            "~~~~markdown\n[relative](docs/file.md).\n~~~~",
            "`[relative](docs/file.md).`",
            "``[relative](docs/file.md).``",
            "\\[relative](docs/file.md).",
            "    [relative](docs/file.md).",
            "````markdown\n```\n[relative](docs/file.md).\n```\n````",
        ]
        for index, message in enumerate(allowed):
            with self.subTest(message=message):
                payload = {"session_id": "allowed", "turn_id": str(index), "last_assistant_message": message}
                self.assertIsNone(turn.stop(payload))

    def test_absolute_first_mention_does_not_allow_later_relative_link(self):
        absolute = "/Users/me/project/.claude/output/indictment.md"
        message = f"Read [{absolute}]({absolute}) first, then [the report](.claude/output/indictment.md) again."
        self.assertEqual(self.stop(message)["decision"], "block")

    def test_local_link_guard_mutes(self):
        message = "Read [the report](docs/report.md)."
        turn.LOCAL_LINK_MUTE.parent.mkdir(parents=True, exist_ok=True)
        turn.LOCAL_LINK_MUTE.touch()
        self.assertIsNone(self.stop(message))
        turn.LOCAL_LINK_MUTE.unlink()
        old = os.environ.get("CODEX_GCC_DISABLE_LOCAL_LINK_GUARD")
        os.environ["CODEX_GCC_DISABLE_LOCAL_LINK_GUARD"] = "1"
        try:
            self.assertIsNone(self.stop(message))
        finally:
            if old is None:
                os.environ.pop("CODEX_GCC_DISABLE_LOCAL_LINK_GUARD", None)
            else:
                os.environ["CODEX_GCC_DISABLE_LOCAL_LINK_GUARD"] = old

    def test_owner_callout_gate(self):
        store = self.repo / ".claude/callouts.jsonl"
        store.parent.mkdir()
        store.write_text(json.dumps({"id": "co-1", "status": "open", "surface": "ui-panel", "claimed": "2026-09-22T10:00:00Z", "rechecks": []}) + "\n")
        command = self.payload("*** Add File: ui-panel.tsx\n+export const Panel = () => null")["tool_input"]["command"]
        self.post("apply_patch", command, {"isError": False})
        self.assertEqual(self.stop("ui-panel is complete.")["decision"], "block")
        store.write_text(json.dumps({"id": "co-1", "status": "open", "surface": "ui-panel", "claimed": "2026-09-22T10:00:00Z", "rechecks": [{"result": "pass", "ts": "2026-09-22T11:00:00Z"}]}) + "\n")
        self.post("Bash", "pnpm test", {"exit_code": 0})
        self.assertIsNone(self.stop("ui-panel is complete after a fresh check."))


if __name__ == "__main__":
    unittest.main()
