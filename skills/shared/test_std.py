#!/usr/bin/env python3
"""test_std.py — Automated tests for std::claude Python utilities.

Run: python3 ~/.claude/skills/shared/test_std.py
Exit 0 = all pass, exit 1 = failures
"""

import sys
import os

sys.path.insert(0, os.path.expanduser("~/.claude/skills"))

from shared import Banner, Section, Item, tree, kv_line, truncate_path, THEMES, __version__

passed = 0
failed = 0


def check(name: str, condition: bool, detail: str = ""):
    global passed, failed
    if condition:
        passed += 1
        print(f"  PASS  {name}")
    else:
        failed += 1
        print(f"  FAIL  {name}  {detail}")


# ── __version__ ──────────────────────────────────────────────────

check("version is string", isinstance(__version__, str))
check("version matches semver", len(__version__.split(".")) == 3, f"got {__version__!r}")

# ── THEMES ───────────────────────────────────────────────────────

REQUIRED_KEYS = {
    "top_left", "top_right", "bot_left", "bot_right",
    "sep_left", "sep_right", "v_border", "h_fill", "h_dash",
    "ornament", "header_symbol", "header_corner", "header_h",
    "header_v", "footer_symbol",
}

check("themes has 4 entries", len(THEMES) == 4, f"got {len(THEMES)}: {list(THEMES.keys())}")
for name, theme in THEMES.items():
    missing = REQUIRED_KEYS - set(theme.keys())
    check(f"theme '{name}' has all keys", len(missing) == 0, f"missing: {missing}")

# ── tree() ───────────────────────────────────────────────────────

check("tree empty list", tree([]) == [])

t1 = tree(["only"])
check("tree single item", len(t1) == 1 and t1[0].prefix == "└-" and t1[0].text == "only")

t3 = tree(["a", "b", "c"])
check("tree 3 items prefixes", [i.prefix for i in t3] == ["├-", "├-", "└-"])
check("tree 3 items texts", [i.text for i in t3] == ["a", "b", "c"])

# ── kv_line() ────────────────────────────────────────────────────

check("kv_line default dots", kv_line("State", "running") == "State ...... running")
check("kv_line custom dots", kv_line("X", "Y", dots=3) == "X ... Y")
check("kv_line zero dots", kv_line("A", "B", dots=0) == "A  B")

# ── truncate_path() ──────────────────────────────────────────────

check("truncate short path", truncate_path("/a/b/c", 20) == "/a/b/c")
check("truncate long path", len(truncate_path("/very/long/deeply/nested/project/src/file.ts", 25)) <= 25)
check("truncate has ellipsis", "..." in truncate_path("/a/b/c/d/e/f/g/h/i/j/k.ts", 20))

# ── Item / Section ───────────────────────────────────────────────

item = Item(prefix="├-", text="hello")
check("Item fields", item.prefix == "├-" and item.text == "hello")

sec = Section(symbol="◆", title="TEST", items=[item])
check("Section fields", sec.symbol == "◆" and sec.title == "TEST" and len(sec.items) == 1)

# ── Banner.render() — all themes ────────────────────────────────

for theme_name in THEMES:
    b = Banner(
        title="TEST",
        subtitle="sub",
        timestamp="2026-01-01",
        footer="foot",
        width=68,
        theme=theme_name,
    )
    b.add_section("◆", "STATUS", tree([kv_line("K", "V")]))
    rendered = b.render()
    lines = rendered.split("\n")
    check(f"banner '{theme_name}' renders", len(lines) > 5, f"only {len(lines)} lines")

# ── Banner.verify() — alignment check ───────────────────────────

for theme_name in THEMES:
    b = Banner(
        title="VERIFY",
        subtitle="alignment test",
        width=68,
        theme=theme_name,
    )
    b.add_section("▶", "ITEMS", tree(["one", "two", "three"]))
    ok, errors = b.verify()
    check(f"banner '{theme_name}' verify alignment", ok, "; ".join(errors[:3]))

# ── Banner.verify() with custom width ───────────────────────────

for w in [50, 72, 80]:
    b = Banner(title="WIDTH", subtitle="test", width=w, theme="default")
    b.add_section("◆", "S", tree(["item"]))
    ok, errors = b.verify()
    check(f"banner width={w} alignment", ok, "; ".join(errors[:2]))

# ── Banner.from_dict() round-trip ────────────────────────────────

config = {
    "title": "FROM_DICT",
    "subtitle": "round-trip",
    "timestamp": "2026-04-06",
    "footer": "test footer",
    "width": 68,
    "theme": "minimal",
    "sections": [
        {
            "symbol": "◆",
            "title": "SEC1",
            "items": [
                {"prefix": "├-", "text": "item one"},
                {"prefix": "└-", "text": "item two"},
            ],
        }
    ],
}
b2 = Banner.from_dict(config)
check("from_dict title", b2.title == "FROM_DICT")
check("from_dict subtitle", b2.subtitle == "round-trip")
check("from_dict theme", b2.theme == "minimal")
check("from_dict section count", len(b2.sections) == 1)
check("from_dict item count", len(b2.sections[0].items) == 2)
ok, errors = b2.verify()
check("from_dict verify alignment", ok, "; ".join(errors[:2]))

# ── Banner.from_dict() with custom theme dict ────────────────────

custom_theme_config = {
    "title": "CUSTOM",
    "width": 68,
    "theme": {"h_fill": "*", "ornament": ">>"},
}
b3 = Banner.from_dict(custom_theme_config)
check("from_dict custom theme", isinstance(b3.theme, dict))
rendered = b3.render()
check("custom theme uses override", "*" in rendered.split("\n")[0])

# ── Banner.add_section chaining ──────────────────────────────────

b4 = Banner(title="CHAIN", width=68)
result = b4.add_section("◆", "A", []).add_section("▶", "B", [])
check("add_section returns self", result is b4)
check("chained sections count", len(b4.sections) == 2)

# ── Edge: empty sections ─────────────────────────────────────────

b5 = Banner(title="EMPTY", width=68)
b5.add_section("◆", "EMPTY_SEC", [])
ok, errors = b5.verify()
check("empty section renders", ok, "; ".join(errors[:2]))

# ── Summary ──────────────────────────────────────────────────────

print(f"\n{'='*50}")
print(f"  std::claude test_std.py — {passed} passed, {failed} failed")
print(f"{'='*50}")

sys.exit(1 if failed > 0 else 0)
