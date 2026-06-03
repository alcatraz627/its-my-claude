#!/usr/bin/env python3
"""Mirror the live Task list into a project's workspace notes.

This keeps a small machine-owned block inside the `## Todos` section of a
project's `_active.md` in step with whatever the Claude session's task list
currently says. The block is fully regenerated each call from the live tasks
(keyed by stable task id, not by the wording of a task), so reordering,
removing, or reprioritising a task is reflected for free — and everything the
human wrote outside the block is left untouched.

Contract:
  argv[1]  path to the workspace `_active.md`
  stdin    JSON list of tasks: [{"id": "30", "subject": "...", "status": "..."}]
           status is one of pending | in_progress | completed.
  stdout   one JSON line: {"changed": bool, "items": int, "reason": str}

Safety:
  - Only the region between the START/END markers is ever rewritten.
  - If the task list is empty but the existing block still holds items, the
    block is left alone (a freshly-revived session starts with an empty task
    dir — wiping the block then would erase real, still-pending work).
  - Writes are atomic (temp file + rename) and skipped entirely when the
    result is byte-identical to what's already on disk.
"""

import sys
import os
import re
import json

START = "<!-- sync:auto:start — mirrors live Task list; edit your own todos below the block, not inside it -->"
END = "<!-- sync:auto:end -->"
START_PREFIX = "<!-- sync:auto:start"
END_PREFIX = "<!-- sync:auto:end"
TODOS_HEADER = re.compile(r"^\s*##\s+Todos\s*$", re.IGNORECASE)
ANY_H2 = re.compile(r"^\s*##\s+\S")
HAS_ITEM = re.compile(r"^\s*[-*]\s*\[[ xX]\]")
# The placeholder line create.sh seeds into a fresh Todos section. Once the
# machine block carries real tasks the placeholder is just noise (and would get
# re-seeded as a literal todo on revival), so we drop it.
PLACEHOLDER = re.compile(r"^\s*[-*]\s*\[\s*\]\s*_no todos yet", re.IGNORECASE)
MAX_SUBJECT = 120
STATUS_ORDER = {"in_progress": 0, "pending": 1, "completed": 2}


def sanitize(subject):
    """Collapse a task subject to a single tidy markdown-safe line."""
    one_line = " ".join(str(subject).split())
    if len(one_line) > MAX_SUBJECT:
        one_line = one_line[: MAX_SUBJECT - 1].rstrip() + "…"
    return one_line


def task_sort_key(task):
    status_rank = STATUS_ORDER.get(task.get("status", "pending"), 1)
    raw_id = str(task.get("id", ""))
    # Numeric ids sort numerically; fall back to string for anything odd.
    id_key = (0, int(raw_id)) if raw_id.isdigit() else (1, raw_id)
    return (status_rank, id_key)


def build_block(tasks):
    """Render the machine-owned block lines (markers included)."""
    lines = [START]
    if tasks:
        for t in sorted(tasks, key=task_sort_key):
            box = "[x]" if t.get("status") == "completed" else "[ ]"
            lines.append(f"- {box} (#{t.get('id', '?')}) {sanitize(t.get('subject', ''))}")
    else:
        lines.append("_no active tasks_")
    lines.append(END)
    return lines


def find_block(lines):
    """Return (start_idx, end_idx) of an existing block, or (None, None)."""
    start = end = None
    for i, line in enumerate(lines):
        if start is None and line.strip().startswith(START_PREFIX):
            start = i
        elif start is not None and line.strip().startswith(END_PREFIX):
            end = i
            break
    if start is not None and end is not None:
        return start, end
    return None, None


def block_has_items(lines, start, end):
    return any(HAS_ITEM.match(lines[i]) for i in range(start + 1, end))


def find_todos_header(lines):
    for i, line in enumerate(lines):
        if TODOS_HEADER.match(line):
            return i
    return None


def splice(lines, tasks):
    """Return the new file lines after refreshing the machine block.

    Raises nothing; returns the original list object only when it decides to
    skip (callers compare identity / content to decide whether to write).
    """
    block = build_block(tasks)
    b_start, b_end = find_block(lines)

    if b_start is not None:
        # Revival guard: never let an empty live task list wipe a block that
        # still carries real items.
        if not tasks and block_has_items(lines, b_start, b_end):
            return lines, "skip-empty-would-wipe"
        return lines[:b_start] + block + lines[b_end + 1 :], "replaced"

    # No block yet — drop one into the Todos section (creating it if needed).
    header = find_todos_header(lines)
    if header is not None:
        insert_at = header + 1
        # Keep a blank line between the header and the block for readability.
        prefix = lines[:insert_at]
        suffix = lines[insert_at:]
        spacer = [""] if (insert_at < len(lines) and lines[insert_at].strip()) else []
        return prefix + [""] + block + spacer + suffix, "inserted"

    # No Todos section at all — append one.
    tail = lines[:]
    if tail and tail[-1].strip():
        tail.append("")
    tail += ["## Todos", "", *block, ""]
    return tail, "created-section"


def main():
    if len(sys.argv) < 2:
        print(json.dumps({"changed": False, "items": 0, "reason": "no-path"}))
        return 0
    # _active.md is a symlink to the session doc; follow it so we update the
    # target and leave the pointer symlink itself intact.
    path = os.path.realpath(sys.argv[1])
    try:
        raw = sys.stdin.read()
        tasks = json.loads(raw) if raw.strip() else []
        if not isinstance(tasks, list):
            tasks = []
    except (ValueError, TypeError):
        print(json.dumps({"changed": False, "items": 0, "reason": "bad-input"}))
        return 0

    try:
        with open(path, "r", encoding="utf-8") as fh:
            original = fh.read()
    except FileNotFoundError:
        print(json.dumps({"changed": False, "items": 0, "reason": "no-file"}))
        return 0

    orig_lines = original.splitlines()
    new_lines, reason = splice(orig_lines, tasks)
    # Once there are real tasks, retire create.sh's placeholder line.
    if tasks:
        new_lines = [ln for ln in new_lines if not PLACEHOLDER.match(ln)]
    new_text = "\n".join(new_lines)
    if original.endswith("\n"):
        new_text += "\n"

    if reason == "skip-empty-would-wipe":
        print(json.dumps({"changed": False, "items": 0, "reason": reason}))
        return 0
    if new_text == original:
        print(json.dumps({"changed": False, "items": len(tasks), "reason": "nochange"}))
        return 0

    tmp = f"{path}.sync.tmp"
    with open(tmp, "w", encoding="utf-8") as fh:
        fh.write(new_text)
    os.replace(tmp, path)
    print(json.dumps({"changed": True, "items": len(tasks), "reason": reason}))
    return 0


if __name__ == "__main__":
    sys.exit(main())
