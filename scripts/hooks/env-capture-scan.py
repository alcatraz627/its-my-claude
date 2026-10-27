#!/usr/bin/env python3
"""Find test code that keeps the whole process environment where a failure can print it.

Reads the text of a test file on stdin and prints one line per finding. The
environment of the owner's shell holds live API tokens, so a test that copies
all of it (or stores the keyword arguments of a stubbed subprocess call, which
carry `env=`) and then prints or asserts on that value writes the tokens into
the transcript the first time the assertion fails.

Two shapes count, each only when the stored value is also shown somewhere:

  1. A variable assigned the whole environment (`os.environ.copy()`,
     `dict(os.environ, ...)`, `{**os.environ}`, `{...process.env}`, ...) that
     is later printed, stringified, put in a log call or an f-string, or
     asserted on as a whole.
  2. A container that a stub fills with whole `**kw` / `kwargs` dicts, shown
     the same way.

Using a copied environment only to pass it on (`env=env`) or reading single
keys (`env["HOME"]`) is not a finding.
"""

import json
import re
import sys

NAME = r"[A-Za-z_][\w.]*"

ENV_COPY = [
    # Python
    rf"^\s*(?P<v>{NAME})\s*=\s*os\.environ\.copy\(\)",
    rf"^\s*(?P<v>{NAME})\s*=\s*(?:copy\.(?:deep)?copy|dict)\(\s*os\.environ\b",
    rf"^\s*(?P<v>{NAME})\s*=\s*\{{\s*\*\*\s*os\.environ\b",
    # JavaScript and TypeScript
    rf"^\s*(?:(?:const|let|var)\s+)?(?P<v>{NAME})\s*=\s*\{{\s*\.\.\.\s*process\.env\b",
    rf"^\s*(?:(?:const|let|var)\s+)?(?P<v>{NAME})\s*=\s*Object\.assign\(\s*\{{\s*\}}\s*,\s*process\.env\b",
    rf"^\s*(?:(?:const|let|var)\s+)?(?P<v>{NAME})\s*=\s*structuredClone\(\s*process\.env\b",
]

# Containers that a stub fills with whole keyword-argument dicts.
KW_STORE = re.compile(
    rf"(?P<v>{NAME})\.(?:append|add|extend|push)\(\s*(?:\(\s*[^()]*,\s*|\[\s*[^\[\]]*,\s*)?"
    r"(?:\*\*)?(?:kw|kws|kwargs|opts|options)\s*[)\]]"
)

# Showing the whole environment directly.
DIRECT = [
    re.compile(r"\b(?:print|pprint|pp|str|repr|json\.dumps)\(\s*(?:dict\()?os\.environ\s*\)"),
    re.compile(r"(?:console\.\w+|JSON\.stringify)\(\s*process\.env\s*[,)]"),
]


def shown(var: str, text: str) -> bool:
    """True when `var` as a whole value is printed, formatted or asserted on."""
    v = re.escape(var)
    patterns = [
        # print(var), str(var), repr(var), log calls, json dumps
        rf"\b(?:print|pprint|pp|str|repr|format|json\.dumps|JSON\.stringify|console\.\w+|logging\.\w+|log\.\w+|logger\.\w+)\(\s*(?:[^()\n]*,\s*)?{v}\s*[,)]",
        # f-string and template-literal interpolation
        rf"\{{\s*{v}\s*(?:![rsa])?(?::[^}}\n]*)?\}}",
        # assert on the whole value: `assert env == ...`, `assert "K" in env`
        rf"\bassert\b[^\n]*(?<=\s){v}(?![\w.\[(])",
        rf"\bexpect\(\s*{v}\s*\)",
        # comparison helpers that print both sides on failure
        rf"\b(?:assertEqual|assertIn|assertDictEqual|assert_called_with|assert_called_once_with)\([^\n]*(?<=\s){v}(?![\w.\[(])",
    ]
    for p in patterns:
        if re.search(p, text, re.M):
            return True
    return False


def live_lines(text: str) -> str:
    out = []
    for line in text.splitlines():
        s = line.lstrip()
        if s.startswith("#") or s.startswith("//"):
            continue
        out.append(line)
    return "\n".join(out)


def findings(text: str) -> set:
    text = live_lines(text)
    found = set()
    for pattern in ENV_COPY:
        for m in re.finditer(pattern, text, re.M):
            var = m.group("v")
            if shown(var, text):
                found.add(f"the whole environment is stored in `{var}` and shown")
    for m in KW_STORE.finditer(text):
        var = m.group("v")
        if shown(var, text):
            found.add(f"whole keyword arguments (which carry env=) are stored in `{var}` and shown")
    for p in DIRECT:
        if p.search(text):
            found.add("the whole environment is printed directly")
    return found


def after_text(tool: str, ti: dict, before: str) -> str:
    """The file as it would read once the tool call is applied."""
    if tool == "Write":
        return ti.get("content", "")
    edits = ti.get("edits") if tool == "MultiEdit" else [ti]
    text = before
    for e in edits or []:
        old, new = e.get("old_string", ""), e.get("new_string", "")
        if old and old in text:
            text = text.replace(old, new, 1) if not e.get("replace_all") else text.replace(old, new)
        else:
            text += "\n" + new
    return text


def main() -> int:
    """Hook mode: stdin is a PreToolUse payload. Prints findings the change adds."""
    try:
        payload = json.loads(sys.stdin.read())
        tool = payload.get("tool_name", "")
        ti = payload.get("tool_input", {})
        try:
            with open(ti.get("file_path", ""), encoding="utf-8", errors="replace") as fh:
                before = fh.read()
        except OSError:
            before = ""
        added = findings(after_text(tool, ti, before)) - findings(before)
        for f in sorted(added):
            print(f)
    except Exception:
        return 0
    return 0


if __name__ == "__main__":
    sys.exit(main())
