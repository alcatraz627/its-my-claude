#!/usr/bin/env python3
"""
banner.py — Reusable terminal banner renderer with aligned Unicode borders.

Generates fixed-width box-drawn banners safe for monospace terminals.
Uses hybrid ASCII/Unicode: corners + verticals from Unicode (╔╗╚╝╠╣║),
horizontal fills from ASCII (=, -) to avoid cumulative glyph drift.

Usage as library:
    from banner import Banner, Section, Item

    b = Banner(title="MY TOOL", subtitle="v1.0", timestamp="2026-04-06")
    b.add_section("◆", "STATUS", [
        Item("├-", "State ...... running"),
        Item("└-", "Uptime ..... 3h 42m"),
    ])
    print(b.render())

Usage as CLI:
    python3 banner.py --config banner.json
    python3 banner.py --title "DEPLOY" --subtitle "prod-east" --width 72

See Banner.from_dict() for the JSON/dict schema.
"""

from __future__ import annotations

import argparse
import json
import sys
import unicodedata
from dataclasses import dataclass, field
from typing import Optional


def _display_width(s: str) -> int:
    """Return the terminal display width of s, counting wide/fullwidth chars as 2."""
    w = 0
    for c in s:
        eaw = unicodedata.east_asian_width(c)
        w += 2 if eaw in ("W", "F") else 1
    return w


# ── Theme presets ──────────────────────────────────────────────────
THEMES = {
    "default": {
        "top_left": "╔",
        "top_right": "╗",
        "bot_left": "╚",
        "bot_right": "╝",
        "sep_left": "╠",
        "sep_right": "╣",
        "v_border": "║",
        "h_fill": "=",
        "h_dash": "-",
        "ornament": "◆◆",
        "header_symbol": "⊕",
        "header_corner": "+",
        "header_h": "-",
        "header_v": "|",
        "footer_symbol": "⊙",
    },
    "minimal": {
        "top_left": "+",
        "top_right": "+",
        "bot_left": "+",
        "bot_right": "+",
        "sep_left": "+",
        "sep_right": "+",
        "v_border": "|",
        "h_fill": "-",
        "h_dash": "-",
        "ornament": "--",
        "header_symbol": "*",
        "header_corner": "+",
        "header_h": "-",
        "header_v": "|",
        "footer_symbol": "*",
    },
    "heavy": {
        "top_left": "╔",
        "top_right": "╗",
        "bot_left": "╚",
        "bot_right": "╝",
        "sep_left": "╠",
        "sep_right": "╣",
        "v_border": "║",
        "h_fill": "=",
        "h_dash": "=",
        "ornament": "■■",
        "header_symbol": "●",
        "header_corner": "+",
        "header_h": "=",
        "header_v": "|",
        "footer_symbol": "●",
    },
    "dots": {
        "top_left": "╔",
        "top_right": "╗",
        "bot_left": "╚",
        "bot_right": "╝",
        "sep_left": "╠",
        "sep_right": "╣",
        "v_border": "║",
        "h_fill": "·",
        "h_dash": "·",
        "ornament": "◇◇",
        "header_symbol": "◇",
        "header_corner": "+",
        "header_h": "·",
        "header_v": "|",
        "footer_symbol": "◇",
    },
}


@dataclass
class Item:
    """A single line inside a section."""

    prefix: str  # e.g. "├-", "└-", "  ", ""
    text: str  # content after prefix


@dataclass
class Section:
    """A labeled section with a symbol, title, and items."""

    symbol: str  # e.g. "◆", "◇", "▶"
    title: str  # e.g. "REGISTERS", "CACHE"
    items: list[Item] = field(default_factory=list)


@dataclass
class Banner:
    """
    Fixed-width terminal banner with aligned borders.

    Args:
        width:     Total character width of every line (default 68)
        title:     Main title text (e.g. "CORE DUMP", "DEPLOY STATUS")
        subtitle:  Second line in header box (e.g. session ID, version)
        timestamp: Optional timestamp shown beside the header box
        footer:    Footer text (left-aligned inside bottom bar)
        theme:     Theme name from THEMES dict, or a custom dict
        sections:  List of Section objects
    """

    width: int = 68
    title: str = "BANNER"
    subtitle: str = ""
    timestamp: str = ""
    footer: str = ""
    theme: str | dict = "default"
    sections: list[Section] = field(default_factory=list)

    def _t(self) -> dict:
        """Resolve theme to a dict."""
        if isinstance(self.theme, dict):
            # Merge with default so partial overrides work
            base = dict(THEMES["default"])
            base.update(self.theme)
            return base
        return dict(THEMES.get(self.theme, THEMES["default"]))

    def add_section(self, symbol: str, title: str, items: list[Item]) -> "Banner":
        """Add a section. Returns self for chaining."""
        self.sections.append(Section(symbol=symbol, title=title, items=items))
        return self

    # ── Line builders ──────────────────────────────────────────────

    def _top(self) -> str:
        t = self._t()
        return t["top_left"] + t["h_fill"] * (self.width - 2) + t["top_right"]

    def _bot(self) -> str:
        t = self._t()
        return t["bot_left"] + t["h_fill"] * (self.width - 2) + t["bot_right"]

    def _sep(self) -> str:
        t = self._t()
        orn = t["ornament"]
        inner = self.width - 2
        orn_cost = len(orn) * 2
        if inner <= orn_cost + 4:
            # Too narrow for ornaments — plain fill
            return t["sep_left"] + t["h_fill"] * inner + t["sep_right"]
        # Distribute fill proportionally: ~25% left, ~65% middle, rest right
        available = inner - orn_cost
        left_fill = min(14, available // 4)
        mid_fill = min(36, available - left_fill - max(available - left_fill - 36, 1))
        right_fill = available - left_fill - mid_fill
        return (
            t["sep_left"]
            + t["h_fill"] * left_fill
            + orn
            + t["h_fill"] * mid_fill
            + orn
            + t["h_fill"] * right_fill
            + t["sep_right"]
        )

    def _blank(self) -> str:
        t = self._t()
        return t["v_border"] + " " * (self.width - 2) + t["v_border"]

    def _content(self, text: str) -> str:
        t = self._t()
        inner = t["v_border"] + "  " + text
        pad = self.width - _display_width(inner) - 1
        if pad < 0:
            # Truncate text to fit
            overflow = -pad
            text = text[: len(text) - overflow - 3] + "..."
            inner = t["v_border"] + "  " + text
            pad = self.width - _display_width(inner) - 1
        return inner + " " * pad + t["v_border"]

    def _section_header(self, symbol: str, name: str) -> str:
        t = self._t()
        prefix = f"{symbol} {name} "
        dashes = t["h_dash"] * (self.width - 6 - _display_width(prefix))
        return self._content(prefix + dashes)

    def _tree_item(self, prefix: str, text: str) -> str:
        return self._content(f"{prefix} {text}")

    # ── Header box ─────────────────────────────────────────────────

    def _header_lines(self) -> list[str]:
        t = self._t()
        sym: str = t["header_symbol"]
        c: str = t["header_corner"]
        h: str = t["header_h"]
        v: str = t["header_v"]


        # Build inner box
        inner_title = f"{sym} {self.title} {sym}"
        box_width = max(len(inner_title) + 4, len(self.subtitle) + 4)
        top_line = f"{c}{h*12}{inner_title}{h*12}{c}"
        box_width = len(top_line)
        sub_padded = self.subtitle + " " * (box_width - 4 - len(self.subtitle))
        mid_line = f"{v}  {sub_padded}{v}"
        bot_line = f"{c}{h * (box_width - 2)}{c}"

        lines = []
        if self.timestamp:
            lines.append(self._content(f"{top_line}"))
            lines.append(self._content(f"{mid_line}  {self.timestamp}"))
        else:
            lines.append(self._content(top_line))
            lines.append(self._content(mid_line))
        lines.append(self._content(bot_line))
        return lines

    # ── Footer ─────────────────────────────────────────────────────

    def _footer_line(self) -> str:
        t = self._t()
        return self._content(f"{t['footer_symbol']} {self.footer}")

    # ── Full render ────────────────────────────────────────────────

    def render(self) -> str:
        """Render the complete banner as a string."""
        lines: list[str] = []

        # Top border + header
        lines.append(self._top())
        lines.extend(self._header_lines())

        # Top separator
        lines.append(self._sep())

        # Sections
        for section in self.sections:
            lines.append(self._blank())
            lines.append(self._section_header(section.symbol, section.title))
            for item in section.items:
                lines.append(self._tree_item(item.prefix, item.text))

        # Bottom
        lines.append(self._blank())
        lines.append(self._sep())
        if self.footer:
            lines.append(self._footer_line())
        lines.append(self._bot())

        return "\n".join(lines)

    def verify(self) -> tuple[bool, list[str]]:
        """Check all lines are exactly self.width chars. Returns (ok, errors)."""
        rendered = self.render()
        errors = []
        for i, line in enumerate(rendered.split("\n")):
            if len(line) != self.width:
                errors.append(
                    f"Line {i+1}: len={len(line)} expected={self.width}  {line!r}"
                )
        return (len(errors) == 0, errors)

    # ── Factory from dict/JSON ─────────────────────────────────────

    @classmethod
    def from_dict(cls, d: dict) -> "Banner":
        """
        Create a Banner from a dict. Schema:

        {
            "width": 68,
            "title": "DEPLOY STATUS",
            "subtitle": "prod-east-1",
            "timestamp": "2026-04-06T14:30+05:30",
            "footer": "deploy-id-abc123    ~ kubectl rollout status",
            "theme": "default",   // or a dict of overrides
            "sections": [
                {
                    "symbol": "◆",
                    "title": "STATUS",
                    "items": [
                        {"prefix": "├-", "text": "Cluster .... healthy"},
                        {"prefix": "└-", "text": "Replicas ... 3/3"}
                    ]
                }
            ]
        }
        """
        sections = []
        for s in d.get("sections", []):
            items = [Item(prefix=i["prefix"], text=i["text"]) for i in s.get("items", [])]
            sections.append(Section(symbol=s["symbol"], title=s["title"], items=items))

        return cls(
            width=d.get("width", 68),
            title=d.get("title", "BANNER"),
            subtitle=d.get("subtitle", ""),
            timestamp=d.get("timestamp", ""),
            footer=d.get("footer", ""),
            theme=d.get("theme", "default"),
            sections=sections,
        )


# ── Helpers for common patterns ────────────────────────────────────


def kv_line(key: str, value: str, dots: int = 6) -> str:
    """Format a key-value pair with dot-leaders: 'Key ...... value'"""
    return f"{key} {'.' * dots} {value}"


def tree(items: list[str]) -> list[Item]:
    """Convert a plain list of strings into properly prefixed tree Items."""
    result = []
    for i, text in enumerate(items):
        is_last = i == len(items) - 1
        prefix = "└-" if is_last else "├-"
        result.append(Item(prefix=prefix, text=text))
    return result


def truncate_path(path: str, max_len: int = 35) -> str:
    """Truncate a file path with .../prefix if too long."""
    if len(path) <= max_len:
        return path
    parts = path.split("/")
    while len("/".join(parts)) > max_len - 4 and len(parts) > 1:
        parts.pop(0)
    return ".../" + "/".join(parts)


# ── CLI ────────────────────────────────────────────────────────────


def main():
    parser = argparse.ArgumentParser(
        description="Render a terminal banner from JSON config or CLI args"
    )
    parser.add_argument("--config", help="Path to JSON config file")
    parser.add_argument("--title", default="BANNER", help="Banner title")
    parser.add_argument("--subtitle", default="", help="Subtitle line")
    parser.add_argument("--timestamp", default="", help="Timestamp")
    parser.add_argument("--footer", default="", help="Footer text")
    parser.add_argument("--width", type=int, default=68, help="Banner width")
    parser.add_argument(
        "--theme",
        default="default",
        choices=list(THEMES.keys()),
        help="Visual theme",
    )
    parser.add_argument("--verify", action="store_true", help="Verify alignment")
    parser.add_argument(
        "--demo", action="store_true", help="Print demo banners for all themes"
    )
    args = parser.parse_args()

    if args.demo:
        for theme_name in THEMES:
            b = Banner(
                title="DEMO",
                subtitle=f"theme: {theme_name}",
                timestamp="2026-04-06",
                footer=f"Rendered with --theme {theme_name}",
                theme=theme_name,
            )
            b.add_section(
                "◆",
                "STATUS",
                tree([kv_line("State", "running"), kv_line("Uptime", "3h 42m")]),
            )
            b.add_section("▶", "NEXT", tree(["Step 1", "Step 2"]))
            print(b.render())
            ok, errors = b.verify()
            print(f"  [{theme_name}] {'PASS' if ok else 'FAIL'}")
            for e in errors:
                print(f"    {e}")
            print()
        return

    if args.config:
        with open(args.config) as f:
            data = json.load(f)
        banner = Banner.from_dict(data)
    else:
        banner = Banner(
            title=args.title,
            subtitle=args.subtitle,
            timestamp=args.timestamp,
            footer=args.footer,
            width=args.width,
            theme=args.theme,
        )

    print(banner.render())

    if args.verify:
        ok, errors = banner.verify()
        if ok:
            print(f"\n  VERIFY: PASS (all lines = {banner.width} chars)")
        else:
            print(f"\n  VERIFY: FAIL")
            for e in errors:
                print(f"    {e}")
            sys.exit(1)


if __name__ == "__main__":
    main()
