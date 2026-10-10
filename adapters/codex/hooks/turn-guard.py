#!/usr/bin/env python3
"""Record Codex turn evidence and check narrow owner-facing Stop claims."""

import hashlib
import json
import os
import re
import sys
from pathlib import Path


STATE = Path(os.environ.get("CODEX_GCC_TURN_STATE", "/tmp/codex-gcc/turn-evidence"))
CLAIM = re.compile(r"\b(done|fixed|complete|completed|ready|shipped|verified|passing|passed|works|working now)\b", re.I)
UNCERTAIN = re.compile(r"\b(UNCONFIRMED|not (?:done|complete|run|tested|verified|confirmed|passing)|incomplete|failed|failing|unable to (?:run|test|verify)|could not (?:run|test|verify))\b", re.I)
NEXT = re.compile(r"^\s*(?:#{1,6}\s*|\*\*|__)?\s*(?:doing now|doing next|next i will|next i.ll|next steps?|up next|what i.ll do next)\s*(?:\*\*|__)?\s*:?\s*$", re.I | re.M)
WAITING = re.compile(r"^\s*(?:#{1,6}\s*|\*\*|__)?\s*(?:waiting on|blocked on|blocked_on|waits on)", re.I | re.M)
UI = re.compile(r"\.(?:tsx|jsx|css|scss|sass|less|vue|svelte|html)$|/(?:app|components|pages)/.*\.(?:ts|js)$", re.I)
CODE = {".ts", ".tsx", ".js", ".jsx", ".py", ".go", ".rs", ".sh", ".rb", ".java", ".swift", ".vue", ".svelte", ".html", ".css", ".scss"}
RUN = re.compile(r"(?:^|[;&|]\s*|\s)(?:pytest|vitest|jest|playwright|go\s+test|cargo\s+test|npm\s+test|pnpm\s+test|yarn\s+test|node\s+\S+|python(?:3)?\s+\S+|bash\s+\S+|curl\s+\S+|npm\s+run\s+(?:dev|start)|pnpm\s+(?:dev|start))\b", re.I)
STATIC = re.compile(r"(?:--collect-only|--list-tests|(?:^|\s)(?:lint|typecheck|tsc|build|check-syntax|py_compile)(?:\s|$))", re.I)
MARKDOWN_LINK = re.compile(r"(?<![!\\])\[([^\]\n]+)\]\((<[^>\n]+>(?:\s+\"[^\"\n]*\")?|(?:[^()\n]|\([^()\n]*\))+?)\)")
URI_SCHEME = re.compile(r"^[A-Za-z][A-Za-z0-9+.-]*:")
DELIVERABLE_ROOT = re.compile(r"^(?:\./)?(?:\.claude/output|docs|assets)/")
LOCAL_PREFIX = ("/", "~/")
FILE_END = re.compile(r"\.[A-Za-z0-9]{1,12}(?::[0-9]+(?::[0-9]+)?)?$")
RELATIVE_FILE = re.compile(r"(?<![/~\w.-])(?:\./)?(?:[\w@.-]+/)*[\w@.-]+\.[A-Za-z0-9]{1,12}(?::[0-9]+(?::[0-9]+)?)?(?!\w)")
LOCAL_LINK_MUTE = Path.home() / ".claude/.no-codex-local-link-gate"


def key(value):
    return hashlib.sha256(str(value).encode()).hexdigest()[:16]


def journal(payload):
    sid = payload.get("session_id") or ""
    turn = payload.get("turn_id") or ""
    if not sid or not turn:
        return None
    return STATE / (key(sid) + "-" + key(turn) + ".jsonl")


def success(response):
    if isinstance(response, dict):
        if response.get("isError") is True:
            return False
        for name in ("exit_code", "exitCode"):
            if name in response:
                return response[name] == 0
        return None
    if isinstance(response, str):
        match = re.search(r'"exit_code"\s*:\s*(-?\d+)', response)
        return int(match.group(1)) == 0 if match else None
    return None


def post(payload):
    path = journal(payload)
    if path is None:
        return
    tool = payload.get("tool_name")
    args = payload.get("tool_input") or {}
    if not isinstance(args, dict):
        return
    command = args.get("command") or ""
    response = payload.get("tool_response")
    ok = success(response)
    events = []
    if tool == "apply_patch" and ok is not False:
        from importlib.machinery import SourceFileLoader
        patch = SourceFileLoader("gcc_patch_parser", str(Path(__file__).with_name("pre-tool-patch.py"))).load_module()
        cwd = Path(payload.get("cwd") or ".").resolve()
        for section in patch.parse(command, cwd):
            if section["action"] != "Delete File":
                events.append({"kind": "edit", "path": str(section["move"] or section["path"])})
    elif tool == "Bash":
        if ok is True and RUN.search(command) and not STATIC.search(command):
            events.append({"kind": "run"})
        elif RUN.search(command) and not STATIC.search(command):
            events.append({"kind": "attempt"})
    if not events:
        return
    try:
        path.parent.mkdir(parents=True, exist_ok=True)
        line = "".join(json.dumps(event, separators=(",", ":")) + "\n" for event in events)
        fd = os.open(str(path), os.O_WRONLY | os.O_CREAT | os.O_APPEND, 0o600)
        try:
            os.write(fd, line.encode())
        finally:
            os.close(fd)
    except OSError:
        pass


def read_events(path):
    if path is None or not path.is_file():
        return []
    try:
        return [json.loads(line) for line in path.read_text().splitlines() if line]
    except (OSError, ValueError):
        return []


def open_callouts(edited, message):
    unmet = []
    stores = {}
    for path in edited:
        if not UI.search(path):
            continue
        p = Path(path)
        for root in (p.parent, *p.parents):
            store = root / ".claude/callouts.jsonl"
            if not store.is_file():
                continue
            stores.setdefault(store, []).append(path)
            break
    for store, paths in stores.items():
        try:
            rows = [json.loads(line) for line in store.read_text().splitlines() if line]
        except (OSError, ValueError):
            continue
        for row in rows:
            surface = row.get("surface") or ""
            if row.get("status") != "open" or not surface:
                continue
            if surface.lower() not in (" ".join(paths) + " " + message).lower():
                continue
            passes = [check for check in row.get("rechecks", []) if check.get("result") == "pass"]
            latest = passes[-1].get("ts") if passes else None
            claimed = row.get("claimed")
            if latest is None or (claimed and latest <= claimed):
                unmet.append(surface + " (" + str(row.get("id", "row")) + ")")
    return unmet


def once(payload, category, message):
    sid = payload.get("session_id") or ""
    if not sid:
        return None
    marker = STATE / (key(sid) + "-" + key(payload.get("turn_id") or "") + "-" + key(category + message) + ".once")
    try:
        marker.parent.mkdir(parents=True, exist_ok=True)
        fd = os.open(str(marker), os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
        os.close(fd)
    except FileExistsError:
        return None
    except OSError:
        return None
    return {"decision": "block", "reason": message}


def prose_without_fences(message, strip_inline=True):
    lines = []
    fence = None
    for line in message.splitlines(keepends=True):
        marker = re.match(r"^\s{0,3}(`{3,}|~{3,})", line)
        if fence:
            lines.append("".join("\n" if char == "\n" else " " for char in line))
            if marker and marker.group(1)[0] == fence[0] and len(marker.group(1)) >= len(fence):
                fence = None
            continue
        if marker:
            fence = marker.group(1)
            lines.append("".join("\n" if char == "\n" else " " for char in line))
            continue
        if line.startswith(("    ", "\t")):
            lines.append("".join("\n" if char == "\n" else " " for char in line))
            continue
        lines.append(line)
    prose = "".join(lines)
    if strip_inline:
        return re.sub(r"(`+)[^`\n]*\1", lambda match: " " * len(match.group(0)), prose)
    return prose


def local_link_violations(message):
    violations = []
    prose = prose_without_fences(message)
    linkless = MARKDOWN_LINK.sub("", prose_without_fences(message, strip_inline=False))
    plain_path_lines = {line.strip() for line in linkless.splitlines()}
    for match in MARKDOWN_LINK.finditer(prose):
        raw_target = match.group(2).strip()
        if raw_target.startswith("<"):
            target = raw_target[1:raw_target.find(">")]
        else:
            target = re.sub(r'\s+"[^"\n]*"$', "", raw_target)
        if target.startswith(("#", "//")) or URI_SCHEME.match(target):
            continue
        label = match.group(1).strip()
        if target.startswith(LOCAL_PREFIX) and FILE_END.search(target) and target not in label:
            violations.append(f"local-file link hides its full path: {match.group(0)}")
        if target.startswith(LOCAL_PREFIX) and FILE_END.search(target) and target not in plain_path_lines:
            violations.append(f"local-file path needs its own plain-text line: {target}")
        if DELIVERABLE_ROOT.match(target):
            violations.append(f"relative deliverable link target: {raw_target}")
        following = prose[match.end():match.end() + 1]
        if (target.startswith(LOCAL_PREFIX) or DELIVERABLE_ROOT.match(target)) and FILE_END.search(target) and following == ".":
            violations.append(f"local-file link followed immediately by a period: {match.group(0)}")
    return violations


def relative_file_violations(message, cwd):
    if not cwd:
        return []
    prose = prose_without_fences(message, strip_inline=False)
    root = Path(cwd)
    violations = []
    for match in RELATIVE_FILE.finditer(prose):
        relative = re.sub(r":[0-9]+(?::[0-9]+)?$", "", match.group())
        if (root / relative).is_file():
            violations.append(f"relative local file path: {match.group()}")
    return violations


def stop(payload):
    message = payload.get("last_assistant_message") or ""
    if not isinstance(message, str) or not message.strip():
        return None
    disabled = os.environ.get("CODEX_GCC_DISABLE_LOCAL_LINK_GUARD") == "1" or LOCAL_LINK_MUTE.exists()
    link_errors = [] if disabled else local_link_violations(message) + relative_file_violations(message, payload.get("cwd"))
    if link_errors:
        listed = "\n".join("- " + item for item in link_errors[:6])
        reason = (
            "Show every local file link's full absolute path on its own plain-text line, as well as in the link label and target. "
            "Put a space between a local link and a following period.\n" + listed
        )
        return {"decision": "block", "reason": reason}
    if not (Path.home() / ".claude/.no-named-next-work-gate").exists() and NEXT.search(message) and not WAITING.search(message):
        reason = "A 'Doing now' or 'Next' section promises work while this turn ends. Do the work now, or name the missing input under 'Waiting on'."
        return once(payload, "next:" + key(message), reason)
    if not CLAIM.search(message):
        return None
    events = read_events(journal(payload))
    edited = list(dict.fromkeys(event.get("path") for event in events if event.get("kind") == "edit" and event.get("path")))
    if not edited:
        return None
    if not (Path.home() / ".claude/.no-ui-callouts-gate").exists():
        unmet = open_callouts(edited, message)
        if unmet:
            reason = "Open owner callouts need a fresh pass before this done claim: " + ", ".join(unmet[:4]) + ". Run each row's check and record the result."
            return once(payload, "callouts:" + key(message), reason)
    code_edited = any(Path(p).suffix in CODE for p in edited)
    if code_edited and not UNCERTAIN.search(message) and not (Path.home() / ".claude/.no-declared-ready-gate").exists():
        kinds = {event.get("kind") for event in events}
        if "run" not in kinds:
            reason = "This turn edits executable or UI files and claims success without a recorded successful runtime exercise. Run the changed path, or state the verification gap as UNCONFIRMED."
            return once(payload, "runtime:" + key(message), reason)
    return None


def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else ""
    try:
        payload = json.load(sys.stdin)
        if mode == "post":
            post(payload)
            return 0
        if mode == "stop":
            result = stop(payload)
            if result:
                print(json.dumps(result))
            return 0
    except (OSError, TypeError, ValueError):
        return 0
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
