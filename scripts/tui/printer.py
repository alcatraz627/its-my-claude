#!/usr/bin/env python3
"""A printer for command-line tools: labelled, colored output with one place to change the look.

Copy this file's class into a tool (standard library only), or import it. Every
heading, labelled line, table and command list goes through one Printer, so the
tool looks the same everywhere and a [theme] table can restyle it. Run this file
for a demo. Guide: ~/.claude/conventions/cli-help-design.md, "Structured output".
"""
import os
import re
import shutil
import sys

_ANSI = re.compile(r"\033\[[0-9;]*m")


def color_wanted() -> bool:
    """Color only at a terminal on both streams; --color or CLICOLOR_FORCE asks anyway; NO_COLOR always wins."""
    forced = "--color" in sys.argv or os.environ.get("CLICOLOR_FORCE", "0") != "0"
    return not os.environ.get("NO_COLOR") and (forced or (sys.stdout.isatty() and sys.stderr.isatty()))


class Printer:
    """Prints labelled, colored output, and plain text when color is off.

    Each kind of text has a role, and a role's look is an SGR code such as
    "1;37" for bold white. title_prefix goes in front of every heading.
    """
    THEME = {"title": "1;37", "note": "2", "command": "36", "label": "2", "header": "1", "key": "36",
             "good": "32", "bad": "31", "wait": "33", "mark": "33", "title_prefix": ""}
    STATUS = {"good": "SUCCESS|ENABLED|RUNNING|RUNNABLE|READY|ACTIVE|live",
              "bad": "FAILURE|FAILED|ERROR|CRITICAL|ALERT|EMERGENCY|TIMEOUT|INTERNAL_ERROR|EXPIRED",
              "wait": "WARNING|WORKING|QUEUED|PENDING|PAUSED|STOPPED|TERMINATED|CANCELLED"}
    _HEADER_ROW = re.compile(r"[A-Z][A-Z0-9_]*(?:\s+[A-Z][A-Z0-9_]*)*\s*")
    _YAML_KEY = re.compile(r"^(\s*(?:- )?)([\w./-]+):(?=\s|$)")
    _SGR = re.compile(r"\d+(;\d+)*")

    def __init__(self, color: bool, theme: dict | None = None):
        self.color = color
        self.theme = dict(self.THEME)
        self.status = re.compile("(?<![\\w-])(?:" + "|".join(f"(?P<{k}>{v})" for k, v in self.STATUS.items())
                                 + ")(?![\\w-])")
        self.use(theme or {})

    def use(self, theme: dict) -> list[str]:
        """Apply a theme, leaving out anything unusable, and return what was left out."""
        bad = []
        for role, value in theme.items():
            ok = role in self.THEME and isinstance(value, str) and (
                role == "title_prefix" or self._SGR.fullmatch(value))
            if ok:
                self.theme[role] = value
            else:
                bad.append(role)
        return bad

    def style(self, role: str, text: str) -> str:
        return f"\033[{self.theme[role]}m{text}\033[0m" if self.color and text else text

    def section(self, title: str, note: str = "", to=None) -> None:
        """A heading that starts one part of the output."""
        print(self.style("title", self.theme["title_prefix"] + title) + (f"  {self.style('note', note)}" if note else ""),
              file=to or sys.stdout, flush=True)

    def field(self, label: str, value: str) -> None:
        """One labelled line, for a thing with a few named facts."""
        print(f"  {self.style('label', f'{label:<10}')} {value}")

    def table(self, headers: list[str], rows: list[list[str]]) -> None:
        """Columns under bold headings, lined up even when a cell carries color."""
        width = [max(len(_ANSI.sub("", str(c))) for c in col) for col in zip(headers, *rows)]

        def line(cells: list[str]) -> str:
            pads = [str(c) + " " * (w - len(_ANSI.sub("", str(c)))) for c, w in zip(cells, width)]
            return "  " + "  ".join(pads).rstrip()

        print(self.style("header", line(headers)))
        for row in rows:
            print(line(row))

    def rows(self, rows: list[tuple[str, str, str]], column: int = 0) -> None:
        """Commands and what each does, always one line per command, in one straight column.

        Each row is (command, what it does, an optional mark for the end). At a
        terminal too narrow for a line, the words are cut rather than wrapped.
        """
        column = column or max((len(c) for c, _, _ in rows), default=0) + 4
        room = shutil.get_terminal_size((100, 24)).columns - column if sys.stdout.isatty() else 10_000
        for call, what, mark in rows:
            gap = " " * max(2, column - len(call) - 2)
            over = len(what) + len(mark) + 1 - room
            if over > 0:
                what = what[:max(1, len(what) - over - 1)] + "…"
            print(f"  {self.style('command', call)}{gap}{what}" + (f" {self.style('mark', mark)}" if mark else ""))

    def paint(self, line: str) -> str:
        """Color one line of another tool's output: table headings, YAML keys and status words."""
        if not self.color:
            return line
        body = line.rstrip("\n")
        if self._HEADER_ROW.fullmatch(body):
            return self.style("header", body) + "\n"
        body = self._YAML_KEY.sub(lambda m: m.group(1) + self.style("key", m.group(2)) + ":", body)
        return self.status.sub(lambda m: self.style(m.lastgroup, m.group(0)), body) + "\n"


if __name__ == "__main__":
    ui = Printer(color_wanted(), {"title_prefix": ""})
    ui.section("COMMANDS", "one line each, in one column")
    ui.rows([("tool logs <service>", "read a service's logs", ""), ("tool deploy <name>", "start a deploy; asks first", "(changes)")])
    print()
    ui.section("A THING")
    ui.field("name", "web")
    ui.field("region", "us-west1")
    print()
    ui.section("A TABLE")
    ui.table(["NAME", "STATUS"], [["web", ui.paint("RUNNING\n").strip()], ["db", ui.paint("FAILED\n").strip()]])
