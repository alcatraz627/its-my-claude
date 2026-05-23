#!/usr/bin/env python3
"""
ascii-art-library.py — ASCII art pieces for session-banner.py

PRNG selector: select(model, hour) -> (artwork_dict, tip_str)
  Seed = MD5(f"{model}:{hour}") — stable within the same hour, changes each hour.

Adding new art:
  1. Add a dict to ARTWORKS with keys: name (str), lines (list[str]), delay (float)
  2. Keep each line <= 64 chars (banner W=72, border+indent = 8 chars overhead)
  3. Keep height <= 12 lines for compact display
  4. Use plain ASCII only — no Unicode art (breaks width calculations)
  5. Avoid trailing backslashes on lines — use double backslash \\ or redesign
  6. Test: python3 ~/.claude/scripts/ascii-art-library.py --preview <name>

Adding announcements:
  1. Add a string to ANNOUNCEMENTS (keep <= 44 chars to fit in banner Tip field)
  2. Claude Code tips, shortcuts, or workflow reminders work best
  3. Test rotation: python3 ~/.claude/scripts/ascii-art-library.py --list
"""

from __future__ import annotations

import argparse
import hashlib
import sys


# ── ASCII Art Library ──────────────────────────────────────────────────────

ARTWORKS: list[dict] = [
    {
        "name": "robot",
        "lines": [
            "   .------.",
            "  / o    o \\",
            " |   ----   |",
            "  \\  ____  /",
            "   '------'",
            "   [______]",
            "   |  ||  |",
            "  _|__|  |_",
        ],
        "delay": 0.04,
    },
    {
        "name": "rocket",
        "lines": [
            "      *  *",
            "     /|\\",
            "    / | \\",
            "   /  *  \\",
            "  | CLAUDE |",
            "  |  CODE  |",
            "  |_______|",
            "    | | |",
            "   /|_|_|\\",
            "  ~ ~ ~ ~ ~",
        ],
        "delay": 0.05,
    },
    {
        "name": "cat",
        "lines": [
            "  /\\_____/\\",
            " (  >   <  )",
            "  \\  ___  /",
            "  (  (_)  )",
            "   \\     /",
            "    )   (",
            "   (_)-(_)",
        ],
        "delay": 0.03,
    },
    {
        "name": "coffee",
        "lines": [
            "    ) ) )",
            "   ( ( (",
            "    ) ) )",
            "  .------.",
            "  |      |]",
            "  | ~~~  |",
            "  |      |",
            "  '------'",
        ],
        "delay": 0.04,
    },
    {
        "name": "mountains",
        "lines": [
            "     /\\         /\\",
            "    /  \\   /\\  /  \\",
            "   /    \\ /  \\/    \\",
            "  /      X    X     \\",
            " /______/ \\  / \\____\\",
            "/          \\/        \\",
        ],
        "delay": 0.05,
    },
    {
        "name": "terminal",
        "lines": [
            " .------------.",
            " | > claude_  |",
            " |            |",
            " | $ git log  |",
            " | $ npm run  |",
            " '------------'",
            "  [__________]",
        ],
        "delay": 0.04,
    },
    {
        "name": "diamond",
        "lines": [
            "        *",
            "       ***",
            "      *****",
            "     *******",
            "    *********",
            "     *******",
            "      *****",
            "       ***",
            "        *",
        ],
        "delay": 0.03,
    },
    {
        "name": "tree",
        "lines": [
            "       *",
            "      ***",
            "     *****",
            "    *******",
            "   *********",
            "  ***********",
            "      |||",
            "      |||",
            "   ---------",
        ],
        "delay": 0.04,
    },
    {
        "name": "snake",
        "lines": [
            "  /\\/\\/\\/\\/\\",
            " ( 0        )",
            "  \\________/~",
            "      ~~~~~~",
            "    ~~~~",
            "  ~~~~",
        ],
        "delay": 0.06,
    },
    {
        "name": "space",
        "lines": [
            " *   .  *     .   *",
            "   .       *",
            " .    .-------.   *",
            "  *  /  o   o  \\",
            "    | ~ rings ~ |  .",
            "  *  \\ _______ /",
            "    .       *    .",
        ],
        "delay": 0.04,
    },
    {
        "name": "dragon",
        "lines": [
            "   __     __",
            "  /  \\___/  \\",
            " ( O       O )",
            "  \\  ~~~~~  /",
            "   |  | |  |",
            "  (  \\ | /  )",
            " / /  \\ /  \\ \\",
        ],
        "delay": 0.04,
    },
    {
        "name": "eye",
        "lines": [
            "    _________",
            "  /           \\",
            " /   (( (0) )) \\",
            "|  ((( ( 0 ) )))  |",
            " \\   (( (0) )) /",
            "  \\_________/",
        ],
        "delay": 0.04,
    },
]


# ── Rotating announcements (max 44 chars each) ────────────────────────────

ANNOUNCEMENTS: list[str] = [
    "! <cmd> runs shell inline in session",
    "/compact before big tasks saves context",
    "/core-dump snapshots session for recovery",
    "Shift+Tab cycles permission modes fast",
    "Use Plan mode before risky refactors",
    "/loop runs a skill on a repeating timer",
    "Add .claude/CLAUDE.md for project rules",
    "Hooks auto-fire on tool events in settings",
    "@filename attaches file content as context",
    "Double-Esc opens the interrupt/cancel menu",
    "WAL tracks every action for /catchup use",
    "/session-stats shows cost + token usage",
]


# ── PRNG selector ──────────────────────────────────────────────────────────


def select(model: str, hour: int) -> tuple[dict, str]:
    """
    Deterministically select an artwork and tip based on model name + hour.

    Same model + hour always returns the same pair. Changes each new hour.
    Uses two independent offsets from one MD5 hash to avoid correlation.
    """
    seed_str = f"{model}:{hour}"
    h = int(hashlib.md5(seed_str.encode()).hexdigest(), 16)
    artwork = ARTWORKS[h % len(ARTWORKS)]
    tip = ANNOUNCEMENTS[(h >> 8) % len(ANNOUNCEMENTS)]
    return artwork, tip


# ── Width helper ───────────────────────────────────────────────────────────


def art_width(artwork: dict) -> int:
    """Return the maximum line length of an artwork."""
    return max(len(line) for line in artwork["lines"])


# ── CLI (for testing) ──────────────────────────────────────────────────────


def _gallery_separator(name: str, width: int, idx: int, total: int) -> str:
    """Render a separator line between gallery items."""
    tag = f"  [{idx}/{total}] {name}  "
    dashes = "-" * max(0, width - len(tag))
    return tag + dashes


def main() -> None:
    parser = argparse.ArgumentParser(
        description="ASCII art library for session-banner.py"
    )
    parser.add_argument("--preview", metavar="NAME", help="Preview a specific artwork")
    parser.add_argument(
        "--list", action="store_true", help="List all artworks with widths"
    )
    parser.add_argument(
        "--gallery", action="store_true",
        help="Print all artworks in sequence (catalog view)",
    )
    parser.add_argument(
        "--select",
        nargs=2,
        metavar=("MODEL", "HOUR"),
        help="Show PRNG selection for model + hour",
    )
    args = parser.parse_args()

    if args.list:
        print(f"{'Name':<12}  {'Lines':>5}  {'Width':>5}  {'Delay':>6}")
        print("-" * 35)
        for art in ARTWORKS:
            w = art_width(art)
            print(
                f"{art['name']:<12}  {len(art['lines']):>5}  {w:>5}  {art['delay']:>6.2f}s"
            )
        print(f"\nAnnouncements: {len(ANNOUNCEMENTS)}")
        for i, tip in enumerate(ANNOUNCEMENTS):
            print(f"  [{i:2d}] {tip}")
        return

    if args.gallery:
        GALLERY_W = 40
        total = len(ARTWORKS)
        print()
        print(f"  ASCII Art Catalog  ({total} pieces)")
        print("  " + "=" * (GALLERY_W - 2))
        for i, art in enumerate(ARTWORKS, 1):
            w = art_width(art)
            pad = max(0, (GALLERY_W - w) // 2)
            indent = " " * (pad + 2)
            print()
            print(_gallery_separator(art["name"], GALLERY_W, i, total))
            for line in art["lines"]:
                print(indent + line)
        print()
        print("  " + "=" * (GALLERY_W - 2))
        print(f"\n  Tips ({len(ANNOUNCEMENTS)} total):")
        for i, tip in enumerate(ANNOUNCEMENTS, 1):
            print(f"    [{i:2d}] {tip}")
        print()
        print("  Commands:")
        print("    --preview <name>          show one piece")
        print("    --select <model> <hour>   test PRNG pick")
        print("    --list                    table of all pieces")
        return

    if args.preview:
        name = args.preview
        art = next((a for a in ARTWORKS if a["name"] == name), None)
        if not art:
            names = [a["name"] for a in ARTWORKS]
            print(f"Unknown artwork '{name}'. Available: {', '.join(names)}")
            sys.exit(1)
        print(f"\n  Art: {name}  (width={art_width(art)}, lines={len(art['lines'])}, delay={art['delay']}s)\n")
        for line in art["lines"]:
            print("  " + line)
        print()
        return

    if args.select:
        model, hour_str = args.select
        hour = int(hour_str)
        art, tip = select(model, hour)
        print(f"Model: {model}  Hour: {hour}")
        print(f"Art:   {art['name']}  (width={art_width(art)})")
        print(f"Tip:   {tip}")
        print()
        for line in art["lines"]:
            print("  " + line)
        return

    # Default: show summary
    print(f"ascii-art-library: {len(ARTWORKS)} artworks, {len(ANNOUNCEMENTS)} tips")
    print("Usage:")
    print("  --gallery                 browse all art pieces")
    print("  --list                    table of names, sizes, delays")
    print("  --preview <name>          show one artwork")
    print("  --select <model> <hour>   test PRNG pick for given hour")


if __name__ == "__main__":
    main()
