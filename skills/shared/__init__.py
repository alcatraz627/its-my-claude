"""std::claude — shared utility library for Claude skills.

Standard library at ~/.claude/skills/shared/. Provides terminal banner
rendering, file locking, runtime note management, and reference docs.

Usage:
    import sys, os
    sys.path.insert(0, os.path.expanduser("~/.claude/skills"))
    from shared import Banner, Section, Item, tree, kv_line, truncate_path
"""

from pathlib import Path

__version__ = (Path(__file__).parent / "VERSION").read_text().strip()

from .banner import Banner, Section, Item, tree, kv_line, truncate_path, THEMES

__all__ = [
    "Banner", "Section", "Item",
    "tree", "kv_line", "truncate_path",
    "THEMES", "__version__",
]
