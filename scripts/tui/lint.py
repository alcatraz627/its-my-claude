#!/usr/bin/python3
"""Read a terminal-UI tool's source for the traps that have broken screens here before.

Each finding names a row in the handbook's trap table (~/.claude/conventions/tui-handbook.md §4),
which says what goes wrong and how to fix it. This reads text, so it finds the shape of a trap,
not proof of a fault: a finding is a place to look. It exits 1 when it finds anything.

# tui_lint FILE... | --scan DIR...: flag known TUI traps in a tool's source; exit 1 on any finding

  lint.py mytool mytool-helper.py      check these files
  lint.py --scan ~/Code ~/.claude      find every fzf screen under these folders and check each
  lint.py --list ~/Code                only list the files --scan would check
"""
from __future__ import annotations

import os
import re
import sys
from pathlib import Path

SKIP_DIRS = {".git", "node_modules", ".venv", "venv", "__pycache__", "dist", "build", "target", ".cache", "retired", "archive"}
# A file is a screen when it runs fzf with a preview or a key bind. A bare `| fzf` picker is not.
SCREEN = re.compile(r"\bfzf\b[^\n]*(--preview|--bind)|--(preview|bind)[^\n]*\n[^\n]*\bfzf\b|\bfzf\b[^\n]*\\\n(?:[^\n]*\\\n)*[^\n]*--(preview|bind)")


def line_of(text, index):
    return text.count("\n", 0, index) + 1


def findings(path):
    """Every trap found in one file, as (line, code, what is wrong)."""
    try:
        text = Path(path).read_text(errors="replace")
    except OSError as e:
        return [(0, "read", str(e))]
    out = []

    def each(pattern, code, words, flags=0):
        for m in re.finditer(pattern, text, flags):
            # A comment that mentions a trap is not the trap.
            start = text.rfind("\n", 0, m.start()) + 1
            if text[start:m.start()].lstrip().startswith("#"):
                continue
            out.append((line_of(text, m.start()), code, words))

    each(r"execute\(\s*(gum|fzf)\b", "A3", "a full-screen program inside execute() blanks the host screen; use become or a box")
    each(r'--(bind|preview)[ =]"[^"\n]*\$(SELF|0)\b', "A4", "the tool's own path goes into a bind unquoted; printf %q it first")
    each(r"\[\s+-r\s+/dev/tty\s+\]", "A9", "/dev/tty can exist and still not open; probe by opening it (tui_have_tty)")
    each(r"--__\w+\)[^\n]*;\s*exit 0\s*;;", "A11", "a callback that always exits 0 hides its failure, and the screen opens blank")
    each(r'--bind[ =]"load:[^"\n]*(transform|execute)', "A15", "load: runs again after every reload; use start: for a once-only action")
    if "stty size" not in text:
        # With stty asked first, tput is the fallback for having no terminal, which is its proper use.
        each(r"\$\(\s*tput (cols|lines)", "A16", "tput answers 80 when its output is captured; ask the terminal with stty size </dev/tty")
    for m in re.finditer(r'--header[ =]"([^"$\n]{56,})"', text):
        out.append((line_of(text, m.start()), "A12", "a %d-character header is cut beside a preview pane; keep it under 56" % len(m.group(1))))

    uses_dirname = re.search(r'dirname\s+"?\$\{?(0|SELF|BASH_SOURCE)', text)
    follows_links = re.search(r"readlink|realpath|cd -P|pwd -P|os\.path\.realpath|\.resolve\(\)", text)
    if uses_dirname and not follows_links:
        out.append((line_of(text, uses_dirname.start()), "A10", "files are looked for beside the script, which breaks when it is installed as a link"))

    is_shell = text.startswith("#!") and re.search(r"^#!.*\b(ba|z)?sh\b", text.splitlines()[0]) is not None
    if is_shell and SCREEN.search(text):
        if "pipefail" not in text:
            out.append((1, "A11", "no pipefail: a list command that fails in a pipe still feeds the screen an empty list"))
        if not re.search(r"screen_ready|--__feed[^\n|]*(>/dev/null)?\s*\|\|", text):
            out.append((1, "A11", "the list command is not run once before fzf opens, so its failure would draw a blank screen"))

    if "tuikit" not in text and re.search(r"^(def (legend|dialog|read_key)\(|key_cell\(\))", text, re.M):
        m = re.search(r"^(def (legend|dialog|read_key)\(|key_cell\(\))", text, re.M)
        out.append((line_of(text, m.start()), "A18", "a screen part is written here that tuikit.py already provides; import it"))
    return sorted(out)


def screens(roots):
    """Every file under these folders that runs an fzf screen."""
    found = []
    for root in roots:
        for folder, dirs, files in os.walk(os.path.expanduser(root)):
            dirs[:] = [d for d in dirs if d not in SKIP_DIRS and not d.startswith(".")]
            for name in files:
                path = os.path.join(folder, name)
                if name.endswith((".md", ".json", ".txt", ".log", ".jsonl", ".lock", ".html")) or os.path.islink(path):
                    continue
                try:
                    if os.path.getsize(path) > 400_000:
                        continue
                    with open(path, errors="replace") as f:
                        text = f.read()
                except OSError:
                    continue
                if "fzf" in text and SCREEN.search(text) and "tui/lint.py" not in path:
                    found.append(path)
    return sorted(found)


def main(argv):
    if not argv or argv[0] in ("-h", "--help"):
        print(__doc__)
        return 0 if argv else 2
    if argv[0] == "--list":
        print("\n".join(screens(argv[1:])))
        return 0
    paths = screens(argv[1:]) if argv[0] == "--scan" else argv
    total = 0
    for path in paths:
        found = findings(path)
        total += len(found)
        for line, code, words in found:
            print("%s:%d  %s  %s" % (path, line, code, words))
    print("%d file%s read, %d finding%s" % (len(paths), "" if len(paths) == 1 else "s", total, "" if total == 1 else "s"))
    return 1 if total else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
