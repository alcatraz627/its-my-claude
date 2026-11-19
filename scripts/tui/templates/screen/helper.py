#!/usr/bin/python3
"""Everything __NAME__ knows and does, one word per step, so each step runs without a screen.

The screen in `__NAME__` only draws and asks; this holds the rows, what is saved, what is being
tried, and the questions. Trying a value is never saving it: the saved values and the draft are
separate files, and the saved one changes only on a yes.

  rows | header | keys | picker-keys | detail KEY | values KEY | changes
  try KEY VALUE | undo KEY | discard | save --confirmed | flow STEP [KEY]
"""
from __future__ import annotations

import json
import os
import sys
import tempfile
from pathlib import Path

HOME = Path.home()
# Tests point this at a temporary folder, so they never touch the real state.
STATE = Path(os.environ.get("__UPPER___HOME") or HOME / ".config" / "__NAME__")

sys.path.insert(0, str(HOME / ".claude" / "scripts" / "tui"))
from tuikit import AMBER, CYAN, DIM, GREEN, PLAIN  # noqa: E402
from tuikit import choice, dialog, legend, notice, section, title  # noqa: E402

# The rows in the order the screen lists them, under their headings.
# Each one: its key, the words a person reads, the value it starts with, and the values offered.
GROUPS = [
    ("first group", [
        ("greeting", "greeting", "hello", ["hello", "good day", "hey"]),
        ("volume", "volume", "5", [str(n) for n in range(0, 11)]),
    ]),
    ("second group", [
        ("mode", "mode", "calm", ["calm", "busy"]),
    ]),
]
ROWS = [row for _group, members in GROUPS for row in members]
LABEL = {key: label for key, label, _d, _v in ROWS}
START = {key: start for key, _l, start, _v in ROWS}
HEADING = "group:"


def read_json(name):
    try:
        return json.loads((STATE / name).read_text())
    except (OSError, ValueError):
        return None


def write_whole(name, value):
    """Replace a file in one step, so a reader never finds half of one."""
    STATE.mkdir(parents=True, exist_ok=True)
    fd, tmp = tempfile.mkstemp(dir=str(STATE))
    with os.fdopen(fd, "w") as f:
        json.dump(value, f, indent=2)
    os.replace(tmp, STATE / name)


def saved():
    return read_json("saved.json") or {}


def draft():
    tried = read_json("draft.json")
    return tried if isinstance(tried, dict) else saved()


def showing(values, key):
    return values.get(key, START[key])


def changes():
    was, now = saved(), draft()
    return ["%s: %s, was %s" % (LABEL[k], showing(now, k), showing(was, k)) for k, _l, _d, _v in ROWS if showing(now, k) != showing(was, k)]


def rows():
    was, now = saved(), draft()
    out = []
    for group, members in GROUPS:
        out.append("%s%s\t%s%s%s" % (HEADING, group, DIM, group.upper(), PLAIN))
        for key, label, _d, _v in members:
            line = "  %s%-24s%s %s" % (CYAN, label, PLAIN, showing(now, key))
            if showing(now, key) != showing(was, key):
                line += "  %snot saved%s" % (AMBER, PLAIN)
            out.append("%s\t%s" % (key, line))
    return out


def header():
    count = len(changes())
    return "%d change%s showing, not saved." % (count, "" if count == 1 else "s") if count else "This is what is saved. Nothing to save."


def keys():
    return legend([[("enter", "change", CYAN), ("u", "put back", AMBER), ("s", "save", GREEN)],
                   [("x", "drop all", AMBER), ("q", "quit", CYAN)]])


def picker_keys():
    return legend([[("enter", "keep trying", GREEN), ("esc", "put it back", AMBER)]])


def detail(key):
    """The right-hand pane: the same five lines for every row, then sections in the same order."""
    was, now = saved(), draft()
    if key.startswith(HEADING):
        group = key[len(HEADING):]
        return title(group.upper()) + ["%-24s %s" % (label, showing(now, k)) for k, label, _d, _v in dict(GROUPS)[group]]
    differs = showing(now, key) != showing(was, key)
    out = title(LABEL[key]) + [
        "showing   %s" % showing(now, key),
        "%ssaved     %s%s" % (AMBER if differs else DIM, showing(was, key), PLAIN),
        "%sstarts as %s%s" % (DIM, START[key], PLAIN)]
    return out + section("what it changes") + ["Say here, or draw, what this row changes."]


def values(key):
    now = showing(draft(), key)
    offered = {k: v for k, _l, _d, v in ROWS}[key]
    return ["%s\t%s  %s" % (value, GREEN + "●" + PLAIN if value == now else " ", value) for value in offered]


def try_value(key, value):
    if key not in LABEL:
        return "no row called %s" % key
    if value not in {k: v for k, _l, _d, v in ROWS}[key]:
        return "%s is not a value for %s" % (value, LABEL[key])
    now = dict(draft())
    now[key] = value
    write_whole("draft.json", now)
    return ""


def undo(key):
    now, was = dict(draft()), saved()
    if key in was:
        now[key] = was[key]
    else:
        now.pop(key, None)
    write_whole("draft.json", now)
    return ""


def discard():
    write_whole("draft.json", saved())
    return ""


def save():
    write_whole("saved.json", draft())
    return ""


def flow(step, key=""):
    """One question the screen asks. Answers with what the screen does next: refresh, redraw, abort or edit KEY."""
    listed = changes()
    if step == "enter":
        return "" if key.startswith(HEADING) else "edit %s" % key
    if step == "save":
        if not listed:
            notice("Nothing to save", ["What you see is already saved."])
        elif dialog("Save these?", listed, choice(("y", "save", GREEN), ("n", "keep trying", CYAN))) in ("y", "Y"):
            save()
        return "refresh"
    if step == "discard":
        if listed and dialog("Drop these changes?", listed, choice(("y", "drop them", AMBER), ("n", "keep trying", CYAN))) in ("y", "Y"):
            discard()
        return "refresh"
    if step == "quit":
        if not listed:
            return "abort"
        pressed = dialog("Leave with changes showing?", listed,
                         choice(("y", "save and leave", GREEN), ("n", "drop and leave", AMBER), ("esc", "stay", CYAN)))
        if pressed in ("y", "Y"):
            save()
            return "abort"
        if pressed in ("n", "N"):
            discard()
            return "abort"
    return "redraw"


def main(argv):
    word, rest = (argv[0] if argv else ""), argv[1:]
    listing = {"rows": rows, "header": lambda: [header()], "keys": lambda: [keys()], "picker-keys": lambda: [picker_keys()], "changes": changes}
    if word in listing:
        print("\n".join(listing[word]()))
        return 0
    if word in ("detail", "values") and rest:
        print("\n".join({"detail": detail, "values": values}[word](" ".join(rest))))
        return 0
    if word == "flow" and rest:
        # The yes these steps need is a key pressed in the box they draw.
        print(flow(rest[0], " ".join(rest[1:])))
        return 0
    if word == "save":
        # This writes something lasting, so it runs only when the person has just said yes.
        if rest != ["--confirmed"]:
            print("save needs a yes from you first", file=sys.stderr)
            return 3
        problem = save()
    elif word == "try" and len(rest) >= 2:
        problem = try_value(rest[0], " ".join(rest[1:]))
    elif word == "undo" and rest:
        problem = undo(rest[0])
    elif word == "discard":
        problem = discard()
    else:
        print(__doc__)
        return 2
    if problem:
        print(problem, file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
