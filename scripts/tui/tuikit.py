#!/usr/bin/python3
"""The parts a list-and-preview screen needs besides fzf itself, for tools written in Python.

Import it (`sys.path.insert(0, "~/.claude/scripts/tui")`, then `import tuikit`) or run it from a
shell script. Everything here writes ANSI unconditionally: it draws screens, and a screen is
always a terminal. Guide and worked examples: ~/.claude/conventions/tui-handbook.md §11.

# tui_dialog TITLE --line TEXT... --key "y:save:green"...: a box over the live screen; prints the key pressed
# tui_legend --per-row N "enter:change:cyan"...: an aligned, colour-coded key legend for --footer
# tui_title TEXT / tui_section TEXT: the two rules a preview pane is built from (Python: tuikit.title, tuikit.section)

  tuikit.py dialog "Save this?" --line "font size: 15, was 13" --key "y:save:green" --key "n:keep trying:cyan"
  tuikit.py legend --per-row 3 "enter:change:cyan" "u:put back:amber" "s:save:green"
  tuikit.py title "font size"        tuikit.py section "what it changes"
"""
from __future__ import annotations

import os
import re
import sys

GREEN, AMBER, CYAN, RED, BLUE, MAGENTA = "\033[32m", "\033[33m", "\033[36m", "\033[31m", "\033[34m", "\033[35m"
DIM, BOLD, PLAIN = "\033[2m", "\033[1m", "\033[0m"
TONES = {"green": GREEN, "amber": AMBER, "cyan": CYAN, "red": RED, "blue": BLUE, "magenta": MAGENTA}
ANSI = re.compile(r"\x1b\[[0-9;]*m")
# The width a preview pane is drawn to. A side pane beside a list is rarely narrower than this.
PANE = 58


def bare(text):
    """Text without its colour codes, for measuring."""
    return ANSI.sub("", text)


def title(text, width=PANE):
    """A pane's first two lines: what is being looked at, and a rule under it."""
    return [BOLD + text + PLAIN, DIM + "─" * width + PLAIN]


def section(text, width=PANE):
    """A blank line, then a divider with the section's name set into it. The same width for every section."""
    return ["", DIM + "── " + PLAIN + text.upper() + " " + DIM + "─" * max(0, width - len(text) - 4) + PLAIN]


def legend(rows, key_width=5, words_width=11):
    """A key legend as aligned columns: the key in colour, what it does beside it.

    `rows` is a list of rows, each a list of (key, words, tone). By convention green marks the key
    that keeps something, amber the keys that drop or undo, cyan the rest. Three cells fit a 55-column list.
    """
    out = []
    for row in rows:
        cells = []
        for n, (key, words, tone) in enumerate(row):
            # The last cell is not padded: trailing blanks inside colour codes would make the line read as too wide.
            width = words_width if n < len(row) - 1 else 0
            cells.append("%s%s%-*s%s %s%-*s%s" % (BOLD, tone, key_width, key, PLAIN, DIM, width, words, PLAIN))
        out.append(" ".join(cells))
    return "\n".join(out)


def choice(*pairs):
    """The line of keys a dialog offers, coloured like the legend. Each pair is (key, words, tone)."""
    return "   ".join("%s%s%s%s %s" % (BOLD, tone, key, PLAIN, words) for key, words, tone in pairs)


def read_key(tty):
    """One key from the terminal, without waiting for enter.

    fzf hands the terminal back to line-at-a-time typing a moment after it starts a command with
    `transform` or `execute-silent`. A key pressed then would sit unread until enter. So the mode is
    checked while waiting and set back to one-key-at-a-time whenever it has been changed.
    """
    import select
    import termios
    import tty as ttymod
    outer = termios.tcgetattr(tty)
    try:
        ttymod.setcbreak(tty, termios.TCSANOW)
        while True:
            ready, _w, _x = select.select([tty], [], [], 0.05)
            if ready:
                return os.read(tty, 1).decode("utf-8", "replace")
            now = termios.tcgetattr(tty)
            if now[3] & termios.ICANON:
                # Remember what the screen set, so that is what it gets back.
                outer = now
                ttymod.setcbreak(tty, termios.TCSANOW)
    finally:
        termios.tcsetattr(tty, termios.TCSADRAIN, outer)


def dialog(heading, lines, choices):
    """Draw a box in the middle of the screen, over whatever is there, and wait for one key.

    The screen underneath is left as it is, so the caller has it redrawn afterwards (fzf: `clear-screen`).
    Returns the key pressed, or "" when there is no terminal to ask on, which a caller must treat as "no".
    """
    try:
        tty = os.open("/dev/tty", os.O_RDWR)
    except OSError:
        return ""
    try:
        cols, rows = os.get_terminal_size(tty)
        body = [""] + list(lines) + ["", choices]
        plain = [bare(line) for line in body]
        inner = min(cols - 6, max([len(heading) + 4] + [len(p) for p in plain]) + 2)
        top, left = max(1, (rows - len(body) - 2) // 2), max(1, (cols - inner - 2) // 2)
        out = []

        def put(row, text):
            out.append("\033[%d;%dH%s" % (top + row, left, text))

        put(0, AMBER + "╭─ " + PLAIN + BOLD + heading + PLAIN + AMBER + " " + "─" * max(0, inner - len(heading) - 3) + "╮" + PLAIN)
        for n, (line, text) in enumerate(zip(body, plain)):
            put(n + 1, AMBER + "│" + PLAIN + " " + line + " " * max(0, inner - len(text) - 1) + AMBER + "│" + PLAIN)
        put(len(body) + 1, AMBER + "╰" + "─" * inner + "╯" + PLAIN)
        os.write(tty, "".join(out).encode())
        return read_key(tty)
    finally:
        os.close(tty)


def notice(heading, lines):
    """A box that only tells, and closes on any key."""
    dialog(heading, lines, choice(("any key", "back", CYAN)))


def _cells(specs):
    """Turn "key:words:tone" strings from a command line into (key, words, tone)."""
    out = []
    for spec in specs:
        key, words, tone = (spec.split(":") + ["", "cyan"])[:3]
        out.append((key, words, TONES.get(tone, CYAN)))
    return out


def main(argv):
    word, rest = (argv[0] if argv else ""), argv[1:]
    if word == "title" and rest:
        print("\n".join(title(" ".join(rest))))
    elif word == "section" and rest:
        print("\n".join(section(" ".join(rest))))
    elif word == "legend":
        per_row = 3
        if rest[:1] == ["--per-row"]:
            per_row, rest = int(rest[1]), rest[2:]
        cells = _cells(rest)
        print(legend([cells[i:i + per_row] for i in range(0, len(cells), per_row)]))
    elif word == "dialog" and rest:
        heading, lines, keys, rest = rest[0], [], [], rest[1:]
        while rest:
            flag, value, rest = rest[0], rest[1] if len(rest) > 1 else "", rest[2:]
            (lines if flag == "--line" else keys).append(value)
        print(dialog(heading, lines, choice(*_cells(keys))))
    else:
        print(__doc__)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
