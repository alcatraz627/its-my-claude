#!/usr/bin/env python3
"""Reports any API token that shows up in a tool's input or output, so the owner knows to rotate it.

PostToolUse on every tool. It cannot un-print anything (the output is already in the
transcript by the time this runs); its job is that a leak never goes unnoticed. It names
the kind of token and the tool, never the value, and logs one line per hit to
~/.claude/logs/secret-leaks.jsonl with a short fingerprint so repeats of the same token
can be told apart from new ones.

Mute: touch ~/.claude/.no-secret-scan
"""
import datetime
import hashlib
import json
import os
import re
import subprocess
import sys

HOME = os.path.expanduser("~")
MUTE = os.path.join(HOME, ".claude", ".no-secret-scan")
LOG = os.path.join(HOME, ".claude", "logs", "secret-leaks.jsonl")
SESSION = datetime.date.today().isoformat()  # replaced by the hook's session_id once input parses

# Shapes of real tokens. Masked forms like gho_**** never match: each needs a long run of real characters.
KINDS = [
    ("GitHub token", re.compile(r"\b(?:gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{40,})")),
    ("Slack token", re.compile(r"\bxox[abposre]-[A-Za-z0-9-]{20,}")),
    ("Linear API key", re.compile(r"\blin_api_[A-Za-z0-9]{20,}")),
    ("Render API key", re.compile(r"\brnd_[A-Za-z0-9]{20,}")),
    ("Anthropic API key", re.compile(r"\bsk-ant-[A-Za-z0-9_-]{20,}")),
    ("OpenAI API key", re.compile(r"\bsk-(?:proj-)?[A-Za-z0-9_-]{32,}")),
    ("Google API key", re.compile(r"\bAIza[A-Za-z0-9_-]{35}")),
    ("AWS access key", re.compile(r"\bAKIA[0-9A-Z]{16}\b")),
    ("private key", re.compile(r"-----BEGIN [A-Z ]*PRIVATE KEY-----")),
]


# Tools whose response echoes the file they changed. For these the scan reads only what the
# call added, so a token already sitting in a file does not re-alert on every later edit.
EDIT_TOOLS = {"Edit", "Write", "MultiEdit", "NotebookEdit"}
ADDED_KEYS = ("new_string", "content", "new_source")

# Fingerprints of known fake tokens (test fixtures), one per line, beside this script.
ALLOWLIST = os.path.join(os.path.dirname(os.path.abspath(__file__)), "secret-leak-scan.allow")


def find(text):
    """Every (kind, fingerprint) found in the text, one per fingerprint.

    The fingerprint is 8 hex chars of a sha256. A value that fits two key shapes (an
    sk-ant key also fits the OpenAI shape) is reported once, under the first kind listed.
    """
    seen = {}
    for kind, rx in KINDS:
        for m in rx.finditer(text):
            seen.setdefault(hashlib.sha256(m.group(0).encode()).hexdigest()[:8], kind)
    return sorted((kind, fp) for fp, kind in seen.items())


def added_text(tool_input):
    """The text an edit or write puts into a file: new strings and content, never the old text."""
    parts = []
    if isinstance(tool_input, dict):
        for key in ADDED_KEYS:
            if isinstance(tool_input.get(key), str):
                parts.append(tool_input[key])
        for edit in tool_input.get("edits") or []:
            if isinstance(edit, dict) and isinstance(edit.get("new_string"), str):
                parts.append(edit["new_string"])
    return "\n".join(parts)


def scan_text(tool, data):
    """The text worth scanning for this tool call."""
    tool_input = data.get("tool_input", "")
    if tool in EDIT_TOOLS:
        return added_text(tool_input)
    return json.dumps(tool_input, ensure_ascii=False) + "\n" + json.dumps(data.get("tool_response", ""), ensure_ascii=False)


def allowed():
    """Fingerprints of known fake tokens; a missing or unreadable file means none."""
    try:
        with open(ALLOWLIST, encoding="utf-8") as f:
            return {line.split("#")[0].strip() for line in f if line.split("#")[0].strip()}
    except OSError:
        return set()


def new_for_session(hits):
    """Drop fingerprints already reported in this session and remember the rest.

    A token that stays in view (a fixture file read again and again) alerts once, so the
    one alert that is real is not buried under repeats.
    """
    path = os.path.join(HOME, ".claude", "logs", ".secret-scan-seen", SESSION)
    try:
        with open(path, encoding="utf-8") as f:
            seen = set(f.read().split())
    except OSError:
        seen = set()
    fresh = [h for h in hits if h[1] not in seen]
    if fresh:
        try:
            os.makedirs(os.path.dirname(path), exist_ok=True)
            with open(path, "a", encoding="utf-8") as f:
                f.write("".join(fp + "\n" for _, fp in fresh))
        except OSError:
            pass
    return fresh


def main():
    if os.path.exists(MUTE):
        return 0
    global SESSION
    try:
        data = json.load(sys.stdin)
    except Exception:
        return 0
    if isinstance(data, dict) and data.get("session_id"):
        SESSION = re.sub(r"[^\w-]", "", str(data["session_id"]))[:64] or SESSION
    tool = data.get("tool_name", "?")
    fakes = allowed()
    hits = [h for h in find(scan_text(tool, data)) if h[1] not in fakes]
    if hits:
        hits = new_for_session(hits)
    if not hits:
        return 0
    report(tool, hits)
    try:  # the report is already out; a failed log write must not print a second message
        os.makedirs(os.path.dirname(LOG), exist_ok=True)
        now = datetime.datetime.now(datetime.timezone.utc).isoformat(timespec="seconds")
        with open(LOG, "a", encoding="utf-8") as f:
            for kind, fp in hits:
                f.write(json.dumps({"ts": now, "session": data.get("session_id"), "tool": tool,
                                    "kind": kind, "fingerprint": fp, "cwd": data.get("cwd")}) + "\n")
    except OSError:
        pass
    return 0


def warn_log(action):
    """Record this fire in the hook ledger. Telemetry never gets to break the hook."""
    try:
        subprocess.run(["bash", os.path.expanduser("~/.claude/scripts/hooks/warn-log.sh"), "--hook", "secret-scan", "--action", action],
                       capture_output=True, timeout=5)
    except (OSError, subprocess.SubprocessError):
        pass


def report(tool, hits):
    """Tell the owner and the agent, before anything else can fail."""
    kinds = ", ".join(sorted({k for k, _ in hits}))
    owner = (f"secret-scan: a {kinds} appeared in this {tool} call's input or output and is now in the transcript. "
             f"Rotate it, then store the new value with token-set. Log: {LOG}")
    agent = (f"[secret-scan] A {kinds} just appeared in the {tool} call's input or output. Tell the owner in your "
             "next reply, in one line, which kind leaked and that it needs rotating. Never quote, repeat or "
             "partially print it. Find what printed it and stop that path (a stub recording env, a debug dump, a "
             "verbose flag) before running it again.")
    warn_log("nudge")
    print(json.dumps({"systemMessage": owner,
                      "hookSpecificOutput": {"hookEventName": "PostToolUse", "additionalContext": agent}}))
    return 0


def broken(err):
    """The scanner itself failed: warn the owner once per session, never block or slow the work."""
    try:
        mark = os.path.join(HOME, ".claude", "logs", f".secret-scan-broken-{SESSION}")
        if os.path.exists(mark):
            return
        os.makedirs(os.path.dirname(mark), exist_ok=True)
        open(mark, "w").close()
        print(json.dumps({"systemMessage": f"secret-scan is not working ({type(err).__name__}: {err}); "
                                           "tool output is not being checked for leaked tokens this session. "
                                           f"Script: {__file__}"}))
    except Exception:
        pass


if __name__ == "__main__":
    # A reporter must never get in the way: every failure exits 0 with at most one warning.
    try:
        main()
    except Exception as e:
        broken(e)
    sys.exit(0)
