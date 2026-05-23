#!/usr/bin/env python3
"""
session-banner.py — SessionStart hook: rich startup banner with animated ASCII art.

Reads Claude Code hook JSON from stdin, gathers git/project context,
and renders a styled banner to stderr (visible in terminal).

Usage (as hook command):
    python3 ~/.claude/scripts/statusline/session-banner.py

Hook input fields used:
    cwd         — working directory
    type        — "startup" | "resume" | "clear" | "compact"
    session_id  — Claude session ID (may be absent)
    model       — model name (may be absent; falls back to CLAUDE_MODEL env)

Environment:
    NO_ANIMATE=1    — skip animation delays (useful in CI or fast sessions)
    CLAUDE_MODEL    — model name fallback if not in hook input
"""

from __future__ import annotations

import json
import os
import subprocess
import sys
from datetime import datetime
from pathlib import Path

# ── Library imports ────────────────────────────────────────────────────────

_scripts_dir = str(Path(__file__).parent)
_shared_dir = str(Path.home() / ".claude" / "skills" / "shared")

sys.path.insert(0, _scripts_dir)
sys.path.insert(0, _shared_dir)

from banner import Banner, Item, kv_line  # noqa: E402
from ascii_art_library import select as select_art, art_width  # noqa: E402


# ── Helpers ────────────────────────────────────────────────────────────────


def _run(cmd: list[str], cwd: str) -> str:
    """Run a command, return stripped stdout, empty string on failure."""
    try:
        result = subprocess.run(
            cmd, cwd=cwd, capture_output=True, text=True, timeout=2
        )
        return result.stdout.strip()
    except Exception:
        return ""


def _git_branch(cwd: str) -> str:
    return _run(
        ["git", "-c", "core.useBuiltinFSMonitor=false", "branch", "--show-current"],
        cwd,
    )


def _git_dirty_count(cwd: str) -> int:
    out = _run(["git", "status", "--porcelain"], cwd)
    if not out:
        return 0
    return len([l for l in out.splitlines() if l.strip()])


def _git_ahead_behind(cwd: str) -> str:
    """Returns e.g. '+2/-1', '+3', '-1', or 'in sync'."""
    out = _run(
        ["git", "rev-list", "--left-right", "--count", "HEAD...@{upstream}"],
        cwd,
    )
    if not out:
        return ""
    parts = out.split()
    if len(parts) != 2:
        return ""
    ahead, behind = int(parts[0]), int(parts[1])
    if ahead == 0 and behind == 0:
        return "in sync"
    tokens = []
    if ahead:
        tokens.append(f"+{ahead}")
    if behind:
        tokens.append(f"-{behind}")
    return "/".join(tokens)


def _count_daily_sessions() -> int:
    """Count sessions started today from the global WAL file."""
    wal = Path.home() / ".claude" / "wal.md"
    if not wal.exists():
        return 0
    today = datetime.now().strftime("%Y-%m-%d")
    try:
        return sum(
            1
            for line in wal.read_text(errors="replace").splitlines()
            if line.startswith("## SESSION") and today in line
        )
    except Exception:
        return 0


# ── ASCII art rendering ────────────────────────────────────────────────────


def _render_art(artwork: dict, total_width: int = 72) -> str:
    """
    Return ASCII art as a string, centered in total_width.
    No delays — the full block is collected into a buffer and printed
    atomically with the banner to avoid race conditions with Claude Code's
    own terminal renderer (spinner, UI) which writes concurrently when the
    hook uses /dev/tty.
    """
    w = art_width(artwork)
    lines = [""]
    for line in artwork["lines"]:
        pad = max(0, (total_width - w) // 2)
        lines.append(" " * pad + line)
    lines.append("")
    return "\n".join(lines)


# ── Session type display ───────────────────────────────────────────────────

SESSION_META: dict[str, tuple[str, str]] = {
    "startup": ("●", "NEW SESSION"),
    "resume": ("▶", "RESUMED"),
    "clear": ("○", "CLEARED"),
    "compact": ("■", "COMPACTED"),
}


# ── Main ───────────────────────────────────────────────────────────────────


def main() -> None:
    raw = sys.stdin.read().strip()
    hook_input: dict = {}
    if raw:
        try:
            hook_input = json.loads(raw)
        except json.JSONDecodeError:
            pass

    cwd = hook_input.get("cwd") or "."
    session_type = hook_input.get("type") or "startup"
    model = (
        hook_input.get("model")
        or os.environ.get("CLAUDE_MODEL", "sonnet")
    )

    project = Path(cwd).name
    now = datetime.now()
    timestamp = now.strftime("%Y-%m-%d  %H:%M")

    # ── Art selection via PRNG ─────────────────────────────────────────────
    artwork, tip = select_art(model, now.hour)

    icon, label = SESSION_META.get(session_type, ("●", session_type.upper()))
    subtitle = f"{icon} {label}  -  {project}"

    # ── Git info ───────────────────────────────────────────────────────────
    branch = _git_branch(cwd)
    dirty = _git_dirty_count(cwd) if branch else 0
    sync = _git_ahead_behind(cwd) if branch else ""

    # ── Build banner sections ──────────────────────────────────────────────
    session_items: list[Item] = []
    if branch:
        session_items.append(Item("├-", kv_line("Branch", branch, dots=6)))
        dirty_str = f"{dirty} file{'s' if dirty != 1 else ''}" if dirty else "clean"
        session_items.append(Item("├-", kv_line("Status", dirty_str, dots=6)))
        if sync:
            session_items.append(Item("├-", kv_line("Remote", sync, dots=6)))
    session_items.append(Item("└-", kv_line("CWD   ", cwd, dots=6)))

    # ── Usage section ──────────────────────────────────────────────────────
    daily = _count_daily_sessions()
    session_str = f"{daily} today" if daily else "first today"
    tip_display = tip[:44]

    usage_items: list[Item] = [
        Item("├-", kv_line("Sessions", session_str, dots=4)),
        Item("└-", kv_line("Tip     ", tip_display, dots=4)),
    ]

    b = Banner(
        title="CLAUDE CODE",
        subtitle=subtitle,
        timestamp=timestamp,
        theme="heavy",
        footer=f"~ {cwd}",
        width=72,
    )
    b.add_section("●", "PROJECT", session_items)
    b.add_section("■", "USAGE", usage_items)

    output = "\n" + _render_art(artwork, total_width=72)
    try:
        with open("/dev/tty", "w") as tty:
            tty.write(output + "\n")
            tty.flush()
    except OSError:
        print(output, file=sys.stderr)


if __name__ == "__main__":
    import traceback
    log = "/tmp/hook-debug.log"
    try:
        with open(log, "a") as f:
            f.write("[session-banner] started\n")
        main()
        with open(log, "a") as f:
            f.write("[session-banner] EXIT 0\n")
    except Exception as e:
        with open(log, "a") as f:
            f.write(f"[session-banner] ERROR: {e}\n{traceback.format_exc()}\n")
        print(f"session-banner error: {e}", file=sys.stderr)
    sys.exit(0)
