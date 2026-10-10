#!/usr/bin/env python3
"""Check Codex patches against the owner's write-time gcc rules."""

import importlib.util
import json
import re
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Optional


HEADER = re.compile(r"^\*\*\* (Add File|Update File|Delete File): (.+)$")
MOVE = re.compile(r"^\*\*\* Move to: (.+)$")
CRED = r"(?:ANTHROPIC_API_KEY|ANTHROPIC_AUTH_TOKEN|CLAUDE_API_KEY|ANTHROPIC_BASE_URL)"
SETTING = re.compile(r"(?:^|\b(?:export|setenv|setx)\s+)" + CRED + r"\s*[:=]|(?:process\.env\.|os\.environ\[['\"]?)" + CRED + r"['\"]?\]?\s*=|['\"]" + CRED + r"['\"]\s*:")
ENV = re.compile(r"(?:process\.env\.|import\.meta\.env\.)([A-Z][A-Z0-9_]*)|(?:os\.getenv|Deno\.env\.get)\(['\"]([A-Z][A-Z0-9_]*)")
SYMBOL = re.compile(r"^\s*(?:export\s+(?:async\s+)?function|export\s+class|def|class)\s+([A-Za-z_][A-Za-z0-9_]{4,})\b")
RG_EXCLUDES = ["-g", "!**/node_modules/**", "-g", "!**/.git/**", "-g", "!**/dist/**", "-g", "!**/build/**", "-g", "!**/.next/**"]


def block(reason):
    return {"decision": "block", "reason": reason}


def parse(command, cwd):
    sections = []
    current = None
    for line in command.splitlines():
        match = HEADER.match(line)
        if match:
            raw = Path(match.group(2).strip()).expanduser()
            current = {"action": match.group(1), "path": (raw if raw.is_absolute() else cwd / raw).resolve(), "body": [], "move": None}
            sections.append(current)
        elif current is not None:
            move = MOVE.match(line)
            if move:
                raw = Path(move.group(1).strip()).expanduser()
                current["move"] = (raw if raw.is_absolute() else cwd / raw).resolve()
            elif line != "*** End Patch":
                current["body"].append(line)
    return sections


def added(section):
    return [line[1:] for line in section["body"] if line.startswith("+") and not line.startswith("+++")]


def reconstruct(section):
    if section["action"] == "Add File":
        return "\n".join(added(section)) + "\n"
    if section["action"] != "Update File" or not section["path"].is_file():
        return None
    body = section["body"]
    if not any(line.startswith("@@") for line in body):
        return None
    try:
        text = section["path"].read_text()
    except (OSError, UnicodeError):
        return None
    lines = text.splitlines()
    hunks = []
    current = None
    for line in body:
        if line.startswith("@@"):
            current = [[], []]
            hunks.append(current)
        elif current is not None and line and line[0] in " +-":
            if line[0] in " -":
                current[0].append(line[1:])
            if line[0] in " +":
                current[1].append(line[1:])
        elif not line.startswith("\\ No newline"):
            return None
    for old, new in hunks:
        if not old:
            return None
        starts = [i for i in range(len(lines) - len(old) + 1) if lines[i:i + len(old)] == old]
        if len(starts) != 1:
            return None
        i = starts[0]
        lines[i:i + len(old)] = new
    return "\n".join(lines) + ("\n" if text.endswith("\n") else "")


def settings_kind(path, home):
    if path in {home / ".claude/settings.json", home / ".claude/settings.local.json", home / ".codex/hooks.json", home / ".claude/adapters/codex/hooks.json"}:
        return "hooks"
    return "mcp" if path.name == ".mcp.json" else None


def settings_error(content, kind):
    try:
        data = json.loads(content)
    except ValueError as exc:
        return "invalid JSON: " + str(exc)
    if not isinstance(data, dict):
        return "top-level JSON must be an object"
    if kind == "mcp":
        return None if isinstance(data.get("mcpServers"), dict) else "mcpServers must be an object"
    hooks = data.get("hooks", {})
    if not isinstance(hooks, dict):
        return "hooks must be an object"
    for event, groups in hooks.items():
        if not isinstance(groups, list) or any(not isinstance(group, dict) or not isinstance(group.get("hooks"), list) for group in groups):
            return "hooks." + event + " needs an array of groups with hooks arrays"
    return None


def banned_term(path, text):
    if path.name == "banned-vocab.txt":
        return None
    for folder in (path.parent, *path.parents):
        vocab = folder / ".claude/banned-vocab.txt"
        if not vocab.is_file():
            continue
        try:
            entries = vocab.read_text().splitlines()
        except OSError:
            return None
        for entry in entries:
            entry = entry.strip()
            if not entry or entry.startswith("#"):
                continue
            term, _, replacement = entry.partition("=>")
            term = term.strip()
            if len(term) >= 2 and re.search(r"(?<!\w)" + re.escape(term) + r"(?!\w)", text, re.I):
                return term + ("; use " + replacement.strip() if replacement.strip() else "")
        return None
    return None


def project_root(path):
    for folder in (path.parent, *path.parents):
        if any((folder / marker).exists() for marker in (".git", "package.json", "pyproject.toml", "go.mod")):
            return folder
    return None


def rg_hits(root, pattern):
    try:
        result = subprocess.run(["rg", "-n", "-m", "1", "--hidden", "--no-ignore", *RG_EXCLUDES, pattern, str(root)], capture_output=True, text=True, timeout=1.5)
        return result.stdout.splitlines()[:16]
    except (OSError, subprocess.TimeoutExpired):
        return []


def quality_notes(path, lines, home):
    text = "\n".join(lines)
    notes = []
    if path.suffix in {".md", ".txt"} and not path.name.startswith("_codex-handback"):
        linter = home / ".claude/scripts/style/prose-lint.py"
        if linter.is_file():
            try:
                run = subprocess.run([sys.executable, str(linter), "--json", "-"], input=text, capture_output=True, text=True, timeout=3)
                report = json.loads(run.stdout)
                violations = report.get("violations", {})
                if violations.get("two_split_dash", 0) or violations.get("verdict_first_opener", 0) or float(report.get("score", 0)) > 8:
                    notes.append("new prose triggers the owner's prose linter; review with prose-lint.py")
            except (OSError, ValueError, subprocess.TimeoutExpired):
                pass
    if path.suffix in {".ts", ".tsx", ".js", ".jsx", ".py"}:
        detector = home / ".claude/skills/cleanup-comments/detect.py"
        if detector.is_file():
            try:
                spec = importlib.util.spec_from_file_location("gcc_comment_detector", detector)
                module = importlib.util.module_from_spec(spec)
                spec.loader.exec_module(module)
                with tempfile.TemporaryDirectory() as folder:
                    temp = Path(folder) / ("slice" + path.suffix)
                    temp.write_text(text)
                    findings = module.scan_file(temp)
                found = {item["category"] for item in findings if item["tier"] in {"tier1_strip", "tier2_voice"}}
                if found:
                    notes.append("new comments trigger cleanup-comments: " + ", ".join(sorted(found)[:3]))
            except (OSError, ValueError, AttributeError):
                pass
    root = project_root(path)
    if root is None:
        return notes
    names = {name for line in lines for match in ENV.finditer(line) for name in match.groups() if name}
    if names and path.suffix in {".ts", ".tsx", ".js", ".jsx", ".py", ".go", ".rs"} and not re.search(r"(?:config|settings|env|test|spec)", path.name, re.I):
        notes.append("new env access: check the project's central config accessor")
    existing = "\n".join(rg_hits(root, r"(?:process\.env\.|import\.meta\.env\.|os\.getenv\(['\"])[A-Z][A-Z0-9_]*")) if names else ""
    existing_names = set(re.findall(r"\b[A-Z][A-Z0-9_]{3,}\b", existing))
    synonyms = {"KEY", "TOKEN", "SECRET", "PASSWORD", "PASS", "PWD", "ID", "URL", "URI"}
    for name in sorted(names)[:3]:
        if name in existing_names or "_" not in name:
            continue
        prefix, suffix = name.rsplit("_", 1)
        if any("_" in old and old.rsplit("_", 1)[0] == prefix and old.rsplit("_", 1)[1] in synonyms and suffix in synonyms for old in existing_names):
            notes.append("new env name " + name + " resembles an existing variable")
    for line in lines[:200]:
        match = SYMBOL.match(line)
        if not match:
            continue
        name = match.group(1)
        if any(not hit.startswith(str(path) + ":") for hit in rg_hits(root, r"\b(?:function|class|def)\s+" + re.escape(name) + r"\b")):
            notes.append("possible duplicate symbol " + name + "; search the project before adding it")
    return notes


def decision(payload, home):
    if payload.get("tool_name") != "apply_patch":
        return None
    home = home.resolve()
    tool_input = payload.get("tool_input") or {}
    command = tool_input.get("command") if isinstance(tool_input, dict) else None
    if not isinstance(command, str) or "*** Begin Patch" not in command:
        return block("Cannot inspect apply_patch targets.")
    cwd = Path(payload.get("cwd") or ".").expanduser().resolve()
    sections = parse(command, cwd)
    if not sections:
        return block("Patch has no inspectable file target.")
    gcc = (home / ".claude").resolve()
    agents = (home / ".codex/AGENTS.md").resolve()
    notes = []
    for section in sections:
        path = section["path"]
        new_lines = added(section)
        for target in [path] + ([section["move"]] if section["move"] else []):
            if target == agents:
                return block("Codex AGENTS.md is generated. Edit its sources and regenerate it.")
            if target.name == ".claude.json":
                return block("Claude account and authentication files are owner-managed.")
            if target.is_relative_to(gcc):
                rel = target.relative_to(gcc)
                if rel.parts and rel.parts[0] == ".claude":
                    return block("Nested ~/.claude/.claude writes are forbidden.")
                if "secrets" in rel.parts or rel.name.startswith(".env") or rel.suffix in {".pem", ".key", ".cert"}:
                    return block("Patch targets a credential or secret file.")
                if str(rel) in {"rules/00-index.md", "skills/00-index.md", "mistake-patterns.md"} or rel.parts[:2] == ("atone", "derived"):
                    return block("Patch targets a generated gcc file. Edit its source and regenerate it.")
                notes.append("gcc source changed; inspect the diff and applicable conventions")
                if rel == Path("adapters/codex/hooks.json"):
                    notes.append("Codex hooks.json changed; re-trust the hook definition in /hooks")
        if path.suffix not in {".md", ".mdx", ".txt", ".rst"} and any(SETTING.search(line) for line in new_lines if not line.lstrip().startswith(("#", "//", "*", "'", '"'))):
            return block("Patch sets a global Claude credential. The owner must make that change by hand.")
        kind = settings_kind(path, home)
        if kind:
            if section["action"] == "Delete File":
                return block("Protected settings must not be deleted through apply_patch.")
            result = reconstruct(section)
            if result is not None:
                error = settings_error(result, kind)
                if error:
                    return block(str(path) + " would have " + error)
            else:
                notes.append("could not reconstruct protected settings; validate JSON after this patch")
        if new_lines:
            term = banned_term(path, "\n".join(new_lines))
            if term:
                return block(str(path) + " adds project-banned term '" + term + "'")
            notes.extend(quality_notes(path, new_lines, home))
    if notes:
        return {"hookSpecificOutput": {"hookEventName": "PreToolUse", "additionalContext": "[gcc patch] " + "; ".join(dict.fromkeys(notes))[:700]}}
    return None


def main():
    try:
        result = decision(json.load(sys.stdin), Path.home())
    except (ValueError, TypeError, AttributeError, OSError) as exc:
        result = block("Cannot inspect apply_patch input: " + type(exc).__name__)
    if result:
        print(json.dumps(result))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
