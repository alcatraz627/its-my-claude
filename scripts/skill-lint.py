#!/usr/bin/env python3
"""Lint a SKILL.md against what Claude Code reads and what this house requires.

A skill's frontmatter is parsed by the harness, and a field it does not know is
silently ignored; this house carried a misspelled `user-invokable` in 81 skills
for months without one error. The lint checks the things that fail silently:
the field names, the capped parts (description, argument-hint, Brief), the
stale tool name, the CWD-relative skill path that the nested-gcc guard refuses,
and the two house conventions nothing else enforces (a validation rubric and a
skill-log step). It never judges body length: the owner ruled the body is
unbounded (2026-08-19), the caps are forcing functions on the budgeted parts.

    python3 skill-lint.py SKILL.md [SKILL.md ...]   one line per finding
    python3 skill-lint.py --all                      every ~/.claude/skills/*/SKILL.md
    python3 skill-lint.py --json ...                 machine output

Exit 0 clean, 1 warnings only, 2 errors. Errors are the silent failures (a
misspelled or unknown field, no description, a description over the cap);
warnings are house conventions.
"""
import json
import re
import sys
from pathlib import Path

# The full set Claude Code reads, from the skills docs' frontmatter reference
# (https://code.claude.com/docs/en/skills, confirmed 2026-08-19).
FIELDS = {
    "name", "description", "when_to_use", "argument-hint", "arguments",
    "disable-model-invocation", "user-invocable", "allowed-tools", "disallowed-tools",
    "model", "effort", "context", "agent", "background", "hooks", "paths", "shell",
    "metadata", "license", "compatibility",
}
# Spellings this house or pandoc-style habits have produced; each maps to the real one.
TYPOS = {
    "user-invokable": "user-invocable", "user_invocable": "user-invocable",
    "argument_hint": "argument-hint", "allowed_tools": "allowed-tools",
    "disable_model_invocation": "disable-model-invocation", "disallowed_tools": "disallowed-tools",
}
DESC_MAX = 300
HINT_MAX = 120
BRIEF_MAX_LINES = 8
EMPHASIS_MAX = 5
EMPHASIS = re.compile(r"\b(MUST|MANDATORY|CRITICAL|NEVER|ALWAYS|IMPORTANT)\b")


def frontmatter(text):
    if not text.startswith("---"):
        return None, 0
    end = text.find("\n---", 3)
    if end < 0:
        return None, 0
    raw = text[3:end].strip("\n").split("\n")
    out, key, order = {}, None, []
    for i, line in enumerate(raw, 2):
        m = re.match(r"^([A-Za-z_][\w-]*):\s*(.*)$", line)
        if m:
            key = m.group(1)
            out[key] = m.group(2).strip()
            order.append((key, i))
        elif key and line.startswith((" ", "\t")):
            out[key] = (out[key] + " " + line.strip()).strip()
    return (out, order), end


def lint(path):
    text = Path(path).read_text(encoding="utf-8", errors="replace")
    f = []  # (level, code, line, msg)
    fm, fm_end = frontmatter(text)
    if fm is None:
        f.append(("error", "frontmatter-missing", 1, "no YAML frontmatter block; the harness loads the body with empty metadata"))
        return f
    fields, order = fm
    for key, ln in order:
        if key in TYPOS:
            f.append(("error", "misspelled-field", ln, f"`{key}` is not a field the harness reads; use `{TYPOS[key]}`"))
        elif key not in FIELDS:
            f.append(("error", "unknown-field", ln, f"`{key}` is not a field the harness reads (silently ignored); known: " + ", ".join(sorted(FIELDS))))
    desc = fields.get("description", "").strip().strip('"').strip("'")
    if not desc:
        f.append(("error", "description-missing", 2, "no description; the roster cannot route to this skill"))
    else:
        if len(desc) > DESC_MAX:
            f.append(("error", "description-long", 2, f"description is {len(desc)} chars; cap {DESC_MAX}. The roster drops long descriptions first when its budget overflows"))
    hint = fields.get("argument-hint", "")
    if len(hint) > HINT_MAX:
        f.append(("warn", "argument-hint-long", 2, f"argument-hint is {len(hint)} chars; cap {HINT_MAX}"))
    tools = fields.get("allowed-tools", "")
    if re.search(r"(^|[ ,])Task([ ,]|$)", tools):
        f.append(("warn", "task-tool", 2, "allowed-tools names `Task`; the tool is `Agent` now"))

    body = text[fm_end:]
    lines = body.splitlines()
    # Brief
    m = re.search(r"^## Brief\s*$", body, re.M)
    if not m:
        f.append(("warn", "brief-missing", 1, "no `## Brief` right after the frontmatter"))
    else:
        after = body[m.end():]
        nxt = re.search(r"^#{1,2} ", after, re.M)
        brief = after[: nxt.start() if nxt else None]
        n = len([l for l in brief.splitlines() if l.strip()])
        if n > BRIEF_MAX_LINES:
            f.append(("warn", "brief-long", 1, f"Brief is {n} non-blank lines; cap {BRIEF_MAX_LINES}. It is the summary, not the skill"))
    # Validation rubric and ledger step
    if not re.search(r"^##+ Validation", body, re.M):
        f.append(("warn", "validation-missing", 1, "no `## Validation` rubric (what to check and how, suited to this skill's efficacy)"))
    if "skill-log.sh record" not in body:
        f.append(("warn", "ledger-missing", 1, "no `skill-log.sh record` step; the skill leaves no efficacy trail"))
    # CWD-relative skill path in a fenced block
    in_fence = False
    for i, l in enumerate(lines, 1):
        if l.startswith("```"):
            in_fence = not in_fence
            continue
        if in_fence and re.search(r"(^|[\s\"'(])\.claude/skills/", l) and re.search(r"\b(mkdir|cp|mv|touch|tee|Write|cat\s*>|>>?)\b|>\s*\.claude/", l):
            f.append(("warn", "relative-skill-path", i, "`.claude/skills/...` relative to CWD nests one level too deep from the gcc; use `~/.claude/skills/` or the skill's own root"))
    # Emphasis count (consumption rule: reserve caps for 2-3 load-bearing gates)
    emph = sum(len(EMPHASIS.findall(l)) for l in lines)
    if emph > EMPHASIS_MAX:
        f.append(("warn", "emphasis", 1, f"{emph} ALL-CAPS emphasis words (MUST/CRITICAL/NEVER...); reserve them for the 2-3 load-bearing gates"))
    return f


def main(argv):
    as_json = "--json" in argv
    targets = [a for a in argv if not a.startswith("--")]
    if "--all" in argv:
        targets += sorted(str(p) for p in (Path.home() / ".claude/skills").glob("*/SKILL.md"))
    if not targets:
        print(__doc__)
        return 2
    worst = 0
    out = []
    for t in targets:
        p = Path(t)
        if p.is_dir():
            p = p / "SKILL.md"
        if not p.exists():
            print(f"{p}: not found")
            worst = 2
            continue
        findings = lint(p)
        for level, code, ln, msg in findings:
            worst = max(worst, 2 if level == "error" else 1)
            if as_json:
                out.append({"file": str(p), "line": ln, "level": level, "check": code, "msg": msg})
            else:
                print(f"{p}:{ln}  {level:5} {code:22} {msg}")
        if not findings and not as_json:
            print(f"{p}: clean")
    if as_json:
        print(json.dumps(out))
    return worst


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
