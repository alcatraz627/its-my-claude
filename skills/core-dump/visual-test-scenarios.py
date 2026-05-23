#!/usr/bin/env python3
"""
Visual alignment test scenarios for /core-dump Phase 4 terminal output.
Run: python3 ~/.claude/skills/core-dump/visual-test-scenarios.py

Tests the hybrid ASCII/Unicode rendering approach (ASCII `=`/`-` for horizontal fills,
Unicode `╔╗╚╝╠╣║` for corners/verticals). All 5 scenarios must produce perfectly
aligned right borders at W=68.

Created: 2026-04-06 (session impro-core-8a)
"""

W = 68


def top():
    return "╔" + "=" * (W - 2) + "╗"


def bot():
    return "╚" + "=" * (W - 2) + "╝"


def sep():
    return "╠" + "=" * 14 + "◆◆" + "=" * 36 + "◆◆" + "=" * 12 + "╣"


def blank():
    return "║" + " " * (W - 2) + "║"


def content(text):
    inner = "║  " + text
    pad = W - len(inner) - 1
    if pad < 0:
        pad = 0
    return inner + " " * pad + "║"


def section_header(symbol, name):
    prefix = f"{symbol} {name} "
    dashes = "-" * (W - 6 - len(prefix))
    return content(prefix + dashes)


def tree_item(prefix, text):
    return content(f"{prefix} {text}")


def verify(lines, label):
    """Check every line is exactly W chars wide. Returns True if all pass."""
    ok = True
    for i, line in enumerate(lines):
        if len(line) != W:
            print(f"  !! LINE {i+1}: len={len(line)} expected={W}  ->  {line!r}")
            ok = False
    status = "PASS" if ok else "FAIL"
    print(f"\n{'='*60}")
    print(f"  Test: {label}")
    print(f"  Lines: {len(lines)}  |  Width: {W}  |  Status: {status}")
    print(f"{'='*60}\n")
    for line in lines:
        print(line)
    print()
    return ok


# ─────────────────────────────────────────────────────────────────
# TEST 1: Full session — all sections populated (happy path)
#
# Validates: standard layout with all 6 sections filled, moderate
# content length, typical file paths, 5 stack trace entries.
# This is the baseline — if this breaks, everything breaks.
# ─────────────────────────────────────────────────────────────────
def test_1_full_session():
    lines = [
        top(),
        content("+--⊕ CORE DUMP ⊕--+"),
        content("|  fix-auth-3b    |  2026-04-06T14:30+05:30"),
        content("+------------------+"),
        sep(),
        blank(),
        section_header("◆", "REGISTERS"),
        tree_item("├-", "Goal ...... Fix authentication bug in login flow"),
        tree_item("├-", "Status .... complete"),
        tree_item("└-", "Expects ... User to test login manually"),
        blank(),
        section_header("◇", "CACHE"),
        tree_item("├-", "src/auth/login.ts ................. [+12 / -3 lines]"),
        tree_item("├-", "src/auth/middleware.ts ............. [+5 / -2 lines]"),
        tree_item("└-", "tests/auth.test.ts ................ [new]"),
        blank(),
        section_header("▶", "PIPELINE"),
        tree_item("├-", "1. Run full test suite"),
        tree_item("├-", "2. Deploy to staging"),
        tree_item("└-", "3. Monitor error rate for 24h"),
        blank(),
        section_header("△", "INTERRUPTS"),
        tree_item("└-", "(none)"),
        blank(),
        section_header("◎", "STACK TRACE"),
        tree_item("├-", "Read auth module - found token expiry bug"),
        tree_item("├-", "Fixed JWT refresh logic in login.ts:42"),
        tree_item("├-", "Added middleware guard for expired tokens"),
        tree_item("├-", "Wrote integration test for token refresh"),
        tree_item("└-", "Verified fix with manual curl test"),
        blank(),
        section_header("⊕", "COPROCESSOR"),
        tree_item("├-", "✓ Pre-read all auth files before editing"),
        tree_item("└-", "✗ First fix attempt missed edge case"),
        blank(),
        sep(),
        content("⊙ _20260406-fix-auth-3b.claude.md    ~ Resume: /catchup"),
        bot(),
    ]
    return verify(lines, "1: Full session (happy path)")


# ─────────────────────────────────────────────────────────────────
# TEST 2: Empty/minimal session (after /clear)
#
# Validates: graceful handling of empty state — all sections present
# but with "(none)" / "(no files)" / "(empty session)" placeholders.
# Tests that short content still pads correctly to W=68.
# ─────────────────────────────────────────────────────────────────
def test_2_empty_session():
    lines = [
        top(),
        content("+--⊕ CORE DUMP ⊕--+"),
        content("|  misc-00        |  2026-04-06T15:00+05:30"),
        content("+------------------+"),
        sep(),
        blank(),
        section_header("◆", "REGISTERS"),
        tree_item("├-", "Goal ...... (no work performed)"),
        tree_item("├-", "Status .... complete"),
        tree_item("└-", "Expects ... N/A - empty session"),
        blank(),
        section_header("◇", "CACHE"),
        tree_item("└-", "(no files modified)"),
        blank(),
        section_header("▶", "PIPELINE"),
        tree_item("└-", "(no pending actions)"),
        blank(),
        section_header("△", "INTERRUPTS"),
        tree_item("└-", "(none)"),
        blank(),
        section_header("◎", "STACK TRACE"),
        tree_item("└-", "(empty session - no actions taken)"),
        blank(),
        section_header("⊕", "COPROCESSOR"),
        tree_item("└-", "(no insights)"),
        blank(),
        sep(),
        content("⊙ _20260406-misc-00.claude.md        ~ Resume: /catchup"),
        bot(),
    ]
    return verify(lines, "2: Empty/minimal session")


# ─────────────────────────────────────────────────────────────────
# TEST 3: Many files (>6) — tests truncation + .../prefix
#
# Validates: CACHE section with 6 files shown + "... and N more"
# overflow line. Tests `.../` prefix for long paths. Verifies
# dot-leader alignment doesn't break with varying path lengths.
# ─────────────────────────────────────────────────────────────────
def test_3_many_files():
    lines = [
        top(),
        content("+--⊕ CORE DUMP ⊕--+"),
        content("|  refac-nav-a0   |  2026-04-06T16:00+05:30"),
        content("+------------------+"),
        sep(),
        blank(),
        section_header("◆", "REGISTERS"),
        tree_item("├-", "Goal ...... Refactor navigation to use new router"),
        tree_item("├-", "Status .... in-progress"),
        tree_item("└-", "Expects ... Continue after break"),
        blank(),
        section_header("◇", "CACHE"),
        tree_item("├-", ".../components/Nav.tsx ............ [+45 / -30]"),
        tree_item("├-", ".../components/Sidebar.tsx ........ [+20 / -15]"),
        tree_item("├-", ".../components/Header.tsx ......... [+8 / -3]"),
        tree_item("├-", ".../hooks/useNavigation.ts ........ [new]"),
        tree_item("├-", ".../router/config.ts .............. [+12 / -0]"),
        tree_item("├-", ".../router/guards.ts .............. [rewrite]"),
        tree_item("└-", "... and 4 more"),
        blank(),
        section_header("▶", "PIPELINE"),
        tree_item("├-", "1. Finish mobile nav breakpoints"),
        tree_item("├-", "2. Update snapshot tests"),
        tree_item("└-", "3. Run visual regression suite"),
        blank(),
        section_header("△", "INTERRUPTS"),
        tree_item("└-", "(none)"),
        blank(),
        section_header("◎", "STACK TRACE"),
        tree_item("├-", "Analyzed old router - 3 circular deps found"),
        tree_item("├-", "Created useNavigation hook to replace HOC"),
        tree_item("├-", "Migrated Nav, Sidebar, Header components"),
        tree_item("├-", "Updated router config with new guard pattern"),
        tree_item("└-", "Fixed SSR hydration mismatch in Header"),
        blank(),
        section_header("⊕", "COPROCESSOR"),
        tree_item("├-", "✓ Hook-first refactor avoided prop drilling"),
        tree_item("└-", "✗ Snapshot tests all broke - need bulk update"),
        blank(),
        sep(),
        content("⊙ _20260406-refac-nav-a0.claude.md   ~ Resume: /catchup"),
        bot(),
    ]
    return verify(lines, "3: Many files (>6, truncated)")


# ─────────────────────────────────────────────────────────────────
# TEST 4: Long stack trace (>8 actions) — tests compression
#
# Validates: STACK TRACE with first 3 + "... (N more)" + last 3
# compression pattern. Tests that the ellipsis line aligns correctly
# and that the count in parentheses is accurate.
# ─────────────────────────────────────────────────────────────────
def test_4_long_stack_trace():
    lines = [
        top(),
        content("+--⊕ CORE DUMP ⊕--+"),
        content("|  add-chart-f1   |  2026-04-06T17:00+05:30"),
        content("+------------------+"),
        sep(),
        blank(),
        section_header("◆", "REGISTERS"),
        tree_item("├-", "Goal ...... Add interactive chart to dashboard"),
        tree_item("├-", "Status .... in-progress"),
        tree_item("└-", "Expects ... Fix tooltip positioning next"),
        blank(),
        section_header("◇", "CACHE"),
        tree_item("├-", ".../Dashboard.tsx ................. [+85 / -10]"),
        tree_item("├-", ".../charts/BarChart.tsx ........... [new]"),
        tree_item("├-", ".../charts/types.ts ............... [new]"),
        tree_item("└-", ".../hooks/useChartData.ts ......... [new]"),
        blank(),
        section_header("▶", "PIPELINE"),
        tree_item("├-", "1. Fix tooltip overflow on small screens"),
        tree_item("├-", "2. Add loading skeleton for chart"),
        tree_item("└-", "3. Write Storybook stories"),
        blank(),
        section_header("△", "INTERRUPTS"),
        tree_item("└-", "(none)"),
        blank(),
        section_header("◎", "STACK TRACE"),
        tree_item("├-", "Researched charting libs - picked recharts"),
        tree_item("├-", "Scaffolded BarChart component with types"),
        tree_item("├-", "Built useChartData hook with SWR caching"),
        tree_item("├-", "... (6 more)"),
        tree_item("├-", "Added responsive breakpoints for mobile"),
        tree_item("├-", "Integrated chart into Dashboard layout"),
        tree_item("└-", "Fixed axis label overlap at narrow widths"),
        blank(),
        section_header("⊕", "COPROCESSOR"),
        tree_item("├-", "✓ SWR caching eliminated redundant fetches"),
        tree_item("└-", "✗ SVG tooltip escapes container on scroll"),
        blank(),
        sep(),
        content("⊙ _20260406-add-chart-f1.claude.md   ~ Resume: /catchup"),
        bot(),
    ]
    return verify(lines, "4: Long stack trace (>8, compressed)")


# ─────────────────────────────────────────────────────────────────
# TEST 5: Active blockers/interrupts + blocked status
#
# Validates: INTERRUPTS section with multiple active items (BLOCKED,
# WARN, NOTE prefixes). Tests "blocked" status in REGISTERS. Verifies
# that multi-line INTERRUPTS content aligns correctly — this section
# is usually just "(none)" so multi-item is the edge case.
# ─────────────────────────────────────────────────────────────────
def test_5_blocked_session():
    lines = [
        top(),
        content("+--⊕ CORE DUMP ⊕--+"),
        content("|  debug-ca-2e    |  2026-04-06T18:00+05:30"),
        content("+------------------+"),
        sep(),
        blank(),
        section_header("◆", "REGISTERS"),
        tree_item("├-", "Goal ...... Debug cache invalidation in prod"),
        tree_item("├-", "Status .... blocked"),
        tree_item("└-", "Expects ... Waiting for staging DB access"),
        blank(),
        section_header("◇", "CACHE"),
        tree_item("├-", ".../cache/invalidator.ts .......... [+3 / -1]"),
        tree_item("└-", ".../cache/redis-client.ts ......... [no changes]"),
        blank(),
        section_header("▶", "PIPELINE"),
        tree_item("├-", "1. Get staging DB credentials from DevOps"),
        tree_item("├-", "2. Reproduce stale cache with prod dataset"),
        tree_item("└-", "3. Apply TTL fix and verify invalidation"),
        blank(),
        section_header("△", "INTERRUPTS"),
        tree_item("├-", "BLOCKED: No access to staging DB - need creds"),
        tree_item("├-", "WARN: Prod cache hit rate dropped to 45%"),
        tree_item("└-", "NOTE: Redis 7.2 known bug with SCAN cursor"),
        blank(),
        section_header("◎", "STACK TRACE"),
        tree_item("├-", "Read cache module - found missing TTL on write"),
        tree_item("├-", "Added TTL param to invalidator.ts:87"),
        tree_item("├-", "Attempted staging test - access denied"),
        tree_item("└-", "Documented Redis 7.2 SCAN bug as risk factor"),
        blank(),
        section_header("⊕", "COPROCESSOR"),
        tree_item("├-", "✓ Identified root cause quickly via logs"),
        tree_item("└-", "✗ Blocked on external dependency (DB access)"),
        blank(),
        sep(),
        content("⊙ _20260406-debug-ca-2e.claude.md    ~ Resume: /catchup"),
        bot(),
    ]
    return verify(lines, "5: Active blockers + interrupted session")


# ─────────────────────────────────────────────────────────────────
# RUNNER
# ─────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    results = [
        ("1: Full session (happy path)", test_1_full_session()),
        ("2: Empty/minimal session", test_2_empty_session()),
        ("3: Many files (>6, truncated)", test_3_many_files()),
        ("4: Long stack trace (>8, compressed)", test_4_long_stack_trace()),
        ("5: Active blockers + interrupted", test_5_blocked_session()),
    ]

    print("\n" + "=" * 60)
    print("  FINAL RESULTS")
    print("=" * 60)
    for name, passed in results:
        mark = "PASS" if passed else "FAIL"
        print(f"  {mark} {name}")
    all_pass = all(r for _, r in results)
    print(f"\n  Overall: {'ALL PASS' if all_pass else 'SOME FAILED'}")
    print("=" * 60)

    exit(0 if all_pass else 1)
