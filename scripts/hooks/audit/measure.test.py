"""Check the hook audit against a small made-up transcript whose right answers are known."""
import json
import os
os.environ["HOOK_TEST"] = "1"  # keeps real hooks fired here out of the live ledger
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "zrecover"))
from testlib import expect, finish  # noqa: E402

T = tempfile.mkdtemp(prefix="hook-audit-")
ROOT = os.path.join(T, "projects", "p")
os.makedirs(ROOT)
OUT = os.path.join(T, "out")
LEDGER = os.path.join(T, "warn.jsonl")
SECRETS = os.path.join(T, "secrets.jsonl")
TS = "2026-10-26T10:00:%02dZ"


def row(kind, sid, second, **rest):
    return dict({"type": kind, "sessionId": sid, "timestamp": TS % second, "entrypoint": rest.pop("entry", "cli")}, **rest)


def user(sid, second, content, **rest):
    return row("user", sid, second, message={"content": content}, **rest)


def assistant(sid, second, text):
    return row("assistant", sid, second, message={"content": [{"type": "text", "text": text}]})


def attachment(sid, second, atype, event, content):
    return row("attachment", sid, second, attachment={"type": atype, "hookEvent": event, "content": content})


def write(name, rows):
    with open(os.path.join(ROOT, name + ".jsonl"), "w") as f:
        for r in rows:
            f.write(json.dumps(r) + "\n")


write("human", [
    user("h", 1, "fix the report please"),
    attachment("h", 2, "hook_additional_context", "UserPromptSubmit", "- 2026-01-01 [port] dev servers need a port"),
    attachment("h", 2, "hook_additional_context", "UserPromptSubmit", "[better-file-browser memory] This prompt names it"),
    attachment("h", 3, "hook_success", "PostToolUse", "x.md does not read as a doc"),
    attachment("h", 3, "hook_additional_context", "PostToolUse", "x.md does not read as a doc"),
    assistant("h", 4, "warm"),
    user("h", 5, "Stop hook feedback: PR review gate: wait", isMeta=True),
    user("h", 5, "Stop hook feedback: format-gate: re-emit once with all of these fixed. relpath: write the full path once: a.md -> /private/tmp/w/a.md", isMeta=True),
    assistant("h", 6, "ok"),
    row("system", "h", 7, subtype="stop_hook_summary", hookInfos=[], hookErrors=[], hookCount=1),
    user("h", 8, [{"type": "tool_result", "content": "PreToolUse:Bash hook error: [env-dump] Refused: this prints"}]),
    user("h", 9, "<task-notification>done</task-notification>"),
    attachment("h", 9, "hook_additional_context", "UserPromptSubmit", "- 2026-01-01 [finished] a note"),
])
write("critic", [
    user("c", 1, "You enforce a style ledger on this file", entry="sdk-cli"),
    assistant("c", 2, "finding"),
    user("c", 3, "Stop hook feedback: format-gate: re-emit once with all of these fixed. emdash: found"),
    assistant("c", 4, "again"),
])
# Only bookkeeping rows fall inside the window, so this session must not count.
with open(os.path.join(ROOT, "later.jsonl"), "w") as f:
    f.write(json.dumps({"type": "last-prompt", "sessionId": "later"}) + "\n")
    f.write(json.dumps(user("later", 1, "new work", timestamp="2026-12-01T00:00:00Z")) + "\n")
with open(LEDGER, "w") as f:
    f.write(json.dumps({"ts": "2026-10-26T10:00:00Z", "kind": "warn", "hook_id": "guard-env-dump", "sid": "h"}) + "\n")
    f.write(json.dumps({"ts": "2026-10-26T10:00:00Z", "kind": "warn", "hook_id": "review-nudge", "sid": "c"}) + "\n")
    f.write(json.dumps({"ts": "2026-10-26T10:00:00Z", "kind": "warn", "hook_id": "review-nudge", "sid": "gone"}) + "\n")
    f.write(json.dumps({"ts": "2020-01-01T00:00:00Z", "kind": "warn", "hook_id": "guard-env-dump", "sid": "h"}) + "\n")
open(SECRETS, "w").write(json.dumps({"ts": "2026-10-26T10:00:00Z"}) + "\n")

r = subprocess.run([sys.executable, os.path.join(HERE, "scan.py"), "--since", "2026-10-25T00:00:00", "--until", "2026-11-01T00:00:00",
                    "--out", OUT, "--root", os.path.join(T, "projects")], capture_output=True, text=True)
expect("the scan runs", r.returncode == 0)
env = dict(os.environ, HOOK_AUDIT_WARN_LOG=LEDGER, HOOK_AUDIT_SECRET_LOG=SECRETS)
save = os.path.join(T, "base.json")
r = subprocess.run([sys.executable, os.path.join(HERE, "measure.py"), OUT, "--save", save], capture_output=True, text=True, env=env)
expect("the measure runs", r.returncode == 0)
m = json.load(open(save))

expect("a session with no timed row in the window is left out", m["populations"] == {"human": 1, "style-critic": 1})
expect("critic sessions are counted apart", m["H1_critic_sessions"] == 1)
expect("a critic's block counts as headless", m["H2_stop_blocks_in_headless"] == 1)
expect("two gates on one stop are one stacked stop", m["H27_stops_with_2plus_messages"] == 1)
expect("and two messages", m["interactive_block_messages"] == 2)
expect("blocks on a warm reply are counted", m["H3_blocks_on_warm_replies"] == 2)
expect("a keyword inject on an automated prompt is counted", m["H4_keyword_injects_on_automated_prompts"] == 1)
expect("a substring guidance hit is not a real keyword", m["H11_guidance"] == {"fires": 2, "on_real_keyword": 0})
expect("a memory load without the name is false", m["H12_memory_false_loads"] == 1)
expect("a note seen twice in the transcript counts once", m["H17_doc_notes"]["notes"] == 1)
expect("bare relpath items are counted", m["H14_relpath"] == {"bare": 1, "items": 1, "wrong_worktree": 1})
expect("ledger and transcript agree on env-dump", m["H5_guard_env_dump"] == {"ledger": 1, "transcript": 1})
expect("rows outside the window are ignored", m["H10_reconcile"]["guard-env-dump"]["flag"] is False)
expect("a hook logging nothing is flagged", m["H10_reconcile"]["pr-review"] == {"ledger": 0, "transcript": 1, "flag": True})
expect("review-nudge on a critic is counted", m["H6_review_nudge_rows"] == {"total": 2, "on_critics": 1})
expect("an unknown session lowers the share", m["H6_known_session_share"] == round(2 / 3, 3))
expect("the secret log is read", m["H13_secret_rows"] == 1)
expect("missing hooks are listed", "pr-review" in m["H7_hooks_missing_from_ledger"])
r = subprocess.run([sys.executable, os.path.join(HERE, "measure.py"), OUT, "--compare", save], capture_output=True, text=True, env=env)
expect("comparing with itself shows no change", r.stdout.strip() == "")

# A later "fixed" must never come from a window that shrank or a scan that read nothing.
EMPTY = os.path.join(T, "empty")
subprocess.run([sys.executable, os.path.join(HERE, "scan.py"), "--since", "2026-10-25T00:00:00", "--until", "2026-11-01T00:00:00",
                "--out", EMPTY, "--root", os.path.join(T, "nothing")], capture_output=True, text=True)
r = subprocess.run([sys.executable, os.path.join(HERE, "measure.py"), EMPTY, "--compare", save], capture_output=True, text=True, env=env)
expect("an empty scan cannot be compared", r.returncode != 0 and "read no transcripts" in r.stderr)
SHORT = os.path.join(T, "short")
subprocess.run([sys.executable, os.path.join(HERE, "scan.py"), "--since", "2026-10-26T00:00:00", "--until", "2026-10-27T00:00:00",
                "--out", SHORT, "--root", os.path.join(T, "projects")], capture_output=True, text=True)
r = subprocess.run([sys.executable, os.path.join(HERE, "measure.py"), SHORT, "--compare", save], capture_output=True, text=True, env=env)
expect("a shorter window says so", "WINDOWS DIFFER" in r.stdout)
LATER = os.path.join(T, "later-window")
subprocess.run([sys.executable, os.path.join(HERE, "scan.py"), "--since", "2026-10-27T00:00:00", "--until", "2026-11-01T00:00:00",
                "--out", LATER, "--root", os.path.join(T, "projects")], capture_output=True, text=True)
r = subprocess.run([sys.executable, os.path.join(HERE, "measure.py"), LATER, "--save", os.path.join(T, "later.json")], capture_output=True, text=True, env=env)
expect("rows before the window are left out", json.load(open(os.path.join(T, "later.json")))["H1_critic_sessions"] == 0)

# A torn last row, as a killed scan leaves, costs that row and nothing else.
with open(os.path.join(OUT, "stop_blocks.jsonl"), "a") as f:
    f.write('{"ts": "torn')
r = subprocess.run([sys.executable, os.path.join(HERE, "measure.py"), OUT], capture_output=True, text=True, env=env)
expect("a torn row does not crash the measure", r.returncode == 0)
r = subprocess.run([sys.executable, os.path.join(HERE, "measure.py"), os.path.join(T, "projects")], capture_output=True, text=True, env=env)
expect("a folder that is not a scan is refused", r.returncode != 0)
r = subprocess.run([sys.executable, os.path.join(HERE, "scan.py"), "--since", "yesterday", "--until", "2026-11-01T00:00:00", "--out", OUT], capture_output=True, text=True)
expect("a bad time is refused plainly", r.returncode == 2 and "is not a time" in r.stderr)

# Populations the report splits by.
sys.path.insert(0, HERE)
import importlib.util  # noqa: E402
spec = importlib.util.spec_from_file_location("measure_mod", os.path.join(HERE, "measure.py"))
M = importlib.util.module_from_spec(spec)
spec.loader.exec_module(M)
expect("the Python SDK is headless", M.population({"entry": "sdk-py", "first": "x"}) == "other-headless")
expect("sdk-cli is headless", M.population({"entry": "sdk-cli", "first": "x"}) == "other-headless")
expect("the example runs are their own group", M.population({"entry": "sdk-py", "first": "show me examples"}) == "show-me-examples")
expect("cli is a person", M.population({"entry": "cli", "first": "x"}) == "human")

# Every text sign is read from the hook that writes it. A hook that rewords its message
# would otherwise make its row read zero, which looks exactly like a fix.
ROOT_HOOKS = os.path.join(HERE, "..")
SIGNS = [("pr-review-gate.py", "PR review gate"), ("goal-proposal-stop.sh", "/goal paste"), ("format-gate-stop.sh", "format-gate: re-emit once"),
         ("doc-voice-gate.py", "doc check"), ("bare-id-cluster-stop.sh", "bare-id"), ("guard-env-dump.sh", "[env-dump] Refused"),
         ("guard-rg-replace-bundle.sh", "rg -r IS --replace"), ("format-gate-stop.sh", "full paths:"),
         ("format-gate-stop.sh", "terse-reply:"), ("guard-ai-signature.sh", "ai-signature:"), ("queue-stop.sh", "queue drive"),
         ("review-nudge-stop.sh", "review-nudge"), ("subagent-box.sh", "subagent-box")]
for source, sign in SIGNS:
    expect("%s still says %r" % (source, sign), sign in open(os.path.join(ROOT_HOOKS, source), errors="replace").read())
finish()
