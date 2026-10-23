#!/usr/bin/env python3
"""Puts the memory a session needs in front of it, whatever directory it started in.

Two gaps this closes. The global memory index (~/.claude/memory/global/MEMORY.md)
was never loaded by anything, so cross-project facts written there were invisible.
And a project's own memory loads only when the session starts in that project, so a
session in versable-foundry working on Speedway never saw Speedway's test logins
(owner, 2026-10-24).

  memory-reach.py session-start   SessionStart: inject the global index
  memory-reach.py prompt          UserPromptSubmit: when the prompt names another
                                  project that has memory, inject that project's
                                  index once per session

Only indexes are injected, never memory bodies: the agent reads a file when its
line applies. Mute: touch ~/.claude/.no-memory-reach · Test: memory-reach.test.sh
"""
import glob
import json
import os
import re
import sys

HOME = os.path.expanduser("~")
GLOBAL = os.environ.get("MEMORY_REACH_GLOBAL", os.path.join(HOME, ".claude/memory/global/MEMORY.md"))
PROJECTS = os.environ.get("MEMORY_REACH_PROJECTS", os.path.join(HOME, ".claude/projects"))
STATE = os.environ.get("MEMORY_REACH_STATE", "/tmp")
MUTE = os.path.join(HOME, ".claude/.no-memory-reach")
# Directory names too generic to stand for one project in a prompt.
GENERIC = {"claude", "code", "versable", "users", "home", "work", "src", "app", "test", "tests", "docs",
           "automation", "scripts", "codex", "private-tmp", "resumes", "portfolio"}
MAX_PROJECTS = 3


def index_text(path):
    try:
        with open(path) as f:
            lines = [l.rstrip() for l in f if not l.lstrip().startswith("<!--")]
    except OSError:
        return ""
    return "\n".join(l for l in lines if l.strip())


def slug_of(cwd):
    return re.sub(r"[^A-Za-z0-9]", "-", cwd or "")


def project_names():
    """Project name -> its memory index, for every project that has one."""
    out = {}
    for idx in glob.glob(os.path.join(PROJECTS, "*", "memory", "MEMORY.md")):
        slug = os.path.basename(os.path.dirname(os.path.dirname(idx)))
        # "-Users-alcatraz627-Code-Versable-speedway" -> "speedway"
        name = slug[len(slug_of(HOME)):] if slug.startswith(slug_of(HOME)) else slug
        for prefix in ("-Code-", "Versable-", "Claude-", "Documents-"):
            if name.startswith(prefix):
                name = name[len(prefix):]
        name = name.strip("-").lower()
        if len(name) >= 4 and name not in GENERIC:
            out[name] = (slug, idx)
    return out


def mentioned(prompt, name):
    """A project is named when its name, or its first word for a hyphenated name, appears whole."""
    p = prompt.lower()
    forms = {name, name.replace("-", " ")}
    head = name.split("-")[0]
    if "-" in name and len(head) >= 5 and head not in GENERIC:
        forms.add(head)
    return any(re.search(r"(?<![\w-])" + re.escape(f) + r"(?![\w-])", p) for f in forms)


def session_start(inp):
    text = index_text(GLOBAL)
    if text:
        emit("SessionStart", "[global memory] Cross-project memory index; read a file when its line applies ("
             + os.path.dirname(GLOBAL) + "):\n" + text)


def emit(event, text):
    print(json.dumps({"hookSpecificOutput": {"hookEventName": event, "additionalContext": text}}))


def prompt(inp):
    text = inp.get("prompt") or ""
    own = slug_of(inp.get("cwd"))
    sid = str(inp.get("session_id") or "nosid")[:8]
    seen_path = os.path.join(STATE, f"memory-reach-{sid}.json")
    try:
        seen = set(json.load(open(seen_path)))
    except (OSError, ValueError):
        seen = set()
    blocks = []
    for name, (slug, idx) in sorted(project_names().items()):
        if slug == own or slug in seen or not mentioned(text, name):
            continue
        body = index_text(idx)
        if body:
            blocks.append(f"[{name} memory] This prompt names {name}, whose memory loads only in its own directory. "
                          f"Index ({os.path.dirname(idx)}):\n{body}")
            seen.add(slug)
        if len(blocks) >= MAX_PROJECTS:
            break
    if blocks:
        try:
            json.dump(sorted(seen), open(seen_path, "w"))
        except OSError:
            pass
        emit("UserPromptSubmit", "\n\n".join(blocks))


def main():
    if os.path.exists(MUTE):
        return
    try:
        inp = json.load(sys.stdin)
    except ValueError:
        inp = {}
    mode = sys.argv[1] if len(sys.argv) > 1 else ""
    try:
        {"session-start": session_start, "prompt": prompt}.get(mode, lambda _: None)(inp)
    except Exception as e:  # a context injector must never break the session
        print(f"memory-reach: {e}", file=sys.stderr)


if __name__ == "__main__":
    main()
