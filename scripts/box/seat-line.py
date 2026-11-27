#!/usr/bin/env python3
"""The one-line notice the owner sees when a sub-agent is sent out or comes back.

Each event is a header line led by its emoji (🛫 out, 🛬 back) with every field
laid out in spaced columns, then continuation lines that carry their own emoji
(🎯 goal, 📄 out). Nothing is clipped: a long goal wraps under its own column.
A fleet (three or more seats sent together) is a header plus one aligned line
per seat. The hook that calls this is scripts/hooks/subagent-box.sh.

Subcommands:
  goal                  read a dispatch prompt on stdin, print seat<TAB>output<TAB>goal
  dispatch  --type --name --model --est --bg --seat --desc --goal
  landing   --type --desc --dur --cost --status written|missing|none --out
  fleet-out --title --attr --row "model|est|desc"...
  fleet-in  --title --attr --row "state|dur|cost|desc"... --out PATH...
            (state is done, missing or wait)
"""
import argparse
import re
import sys
import textwrap
import unicodedata

WIDTH = 84
GAP = "  "
INDENT = "   "


def dwidth(s):
    """Terminal cells a string takes: emoji and CJK are two wide, joiners zero."""
    w = 0
    for ch in s:
        if unicodedata.combining(ch) or ch in "‍️︎":
            continue
        w += 2 if unicodedata.east_asian_width(ch) in ("W", "F") else 1
    return w


def pad(s, w):
    return s + " " * max(0, w - dwidth(s))


def fields(*parts):
    return GAP.join(p for p in parts if p)


def labelled(emoji, label, text, width):
    """A continuation line: emoji and label, then text that wraps under itself."""
    lead = "%s%s %s  " % (INDENT, emoji, label)
    room = max(20, width - dwidth(lead))
    lines = textwrap.wrap(text, room, break_long_words=False, break_on_hyphens=False) or [""]
    hang = " " * dwidth(lead)
    return [lead + lines[0]] + [hang + ln for ln in lines[1:]]


def columns(rows):
    """Pad every column but the last to its widest cell, so rows line up."""
    if not rows:
        return []
    n = max(len(r) for r in rows)
    rows = [r + [""] * (n - len(r)) for r in rows]
    # A column nobody filled (no estimates yet, say) takes no room at all.
    keep = [i for i in range(n) if any(r[i] for r in rows)]
    rows = [[r[i] for i in keep] for r in rows]
    n = len(keep)
    widths = [max(dwidth(r[i]) for r in rows) for i in range(n)]
    out = []
    for r in rows:
        cells = [pad(c, widths[i]) for i, c in enumerate(r[:-1])] + [r[-1]]
        out.append(GAP.join(cells).rstrip())
    return out


def goal_of(prompt):
    """What a seat was sent to do, in the words of its brief.

    A seated prompt opens with a `[seat …]` metadata line and carries a
    `# The goal` section; that section is the goal. Any other prompt's goal is
    its first paragraph that is not a heading. Whitespace is folded, nothing cut.
    """
    seat, out = "-", "-"
    m = re.match(r"\s*\[seat (s-[0-9a-z-]+)\][^\n]*", prompt)
    if m:
        seat = m.group(1)
        o = re.search(r"\boutput=(\S+)", m.group(0))
        out = o.group(1) if o else "-"
        prompt = prompt[m.end():]
    sec = re.search(r"^#+\s*The goal\s*\n(.*?)(?=^#+\s|\Z)", prompt, re.M | re.S)
    if sec:
        body = sec.group(1)
    else:
        paras = [p for p in re.split(r"\n\s*\n", prompt) if p.strip() and not p.lstrip().startswith("#")]
        body = paras[0] if paras else prompt
    return seat, out, " ".join(body.split())


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("cmd")
    for f in ("type", "name", "model", "est", "seat", "desc", "goal", "dur", "cost",
              "status", "attr", "title"):
        ap.add_argument("--" + f, default="")
    ap.add_argument("--bg", action="store_true")
    ap.add_argument("--row", action="append", default=[])
    ap.add_argument("--out", action="append", default=[])
    ap.add_argument("--width", type=int, default=WIDTH)
    a = ap.parse_args()
    w = a.width

    if a.cmd == "goal":
        print("\t".join(goal_of(sys.stdin.read())))
        return

    if a.cmd == "dispatch":
        print(fields("🛫 " + (a.type or "general-purpose"), a.name, a.model or "inherit",
                     "~$" + a.est if a.est else "", "background" if a.bg else "", a.seat))
        goal = ": ".join(p for p in (a.desc, a.goal) if p)
        if goal:
            print("\n".join(labelled("🎯", "goal", goal, w)))
        return

    if a.cmd == "landing":
        st = {"written": "✅ output written", "missing": "❌ output NOT written"}.get(a.status, "")
        print(fields("🛬 " + (a.type or "unknown"), a.desc, "ran " + a.dur if a.dur else "",
                     "$" + a.cost if a.cost else "", st))
        for o in a.out:
            print("\n".join(labelled("📄", "out ", o, w)))
        return

    if a.cmd in ("fleet-out", "fleet-in"):
        emoji = "🛫" if a.cmd == "fleet-out" else "🛬"
        print(fields(emoji + " fleet", a.title, a.attr))
        marks = {"out": "🔹", "done": "✅", "missing": "❌", "wait": "⏳"}
        rows = []
        for i, r in enumerate(a.row, 1):
            parts = r.split("|")
            state = parts[0] if a.cmd == "fleet-in" else "out"
            cells = parts[1:] if a.cmd == "fleet-in" else parts
            if state == "missing":
                cells[-1] = cells[-1] + " (no output written)"
            rows.append(["%s%s %d" % (INDENT, marks.get(state, "🔹"), i)] + cells)
        for ln in columns(rows):
            print(ln)
        for o in a.out:
            print("\n".join(labelled("📄", "out ", o, w)))
        return

    sys.exit("seat-line: unknown command %r" % a.cmd)


if __name__ == "__main__":
    main()
