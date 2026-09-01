#!/usr/bin/env python3
"""validate-triggers.py — Validate sub-file frontmatter in ~/.claude/{rules,features,conventions}/

Checks:
  - Every .md file has YAML frontmatter with required fields
  - Every trigger uses a known prefix (tool:|topic:|phrase:|skill:|mcp:)
  - No trigger collisions across files (soft warning)
  - tier is 0|1|2|3
  - category matches the directory name
  - updated date is valid YYYY-MM-DD
  - stale_after_days is a number; age beyond threshold emits warning
  - always-loaded rules/ files with a halt directive carry the never-halt anchor

Exit codes:
  0  all files valid
  1  at least one hard error
  2  soft warning only
"""
import sys
import re
from pathlib import Path
from datetime import date, datetime
from collections import defaultdict

HOME_CLAUDE = Path.home() / ".claude"
ROOTS = ("rules", "features", "conventions")
REQUIRED_FIELDS = ("brief", "triggers", "related", "tier", "category", "updated", "stale_after_days")
VALID_PREFIXES = {"tool", "topic", "phrase", "skill", "mcp"}
VALID_TIERS = {"0", "1", "2", "3"}

# A rule that gates an action must name the inaction it could license
# (rules/README.md; applied corpus-wide 2026-09-01, see
# assets/reports/20260901-halt-imbalance/report.md). Any ALWAYS-loaded rule
# whose body directs an owner-gated halt must reference the halt-scope anchor.
HALT_ANCHOR = "never-halt-on-authority-you-hold"
HALT_DIRECTIVE = re.compile(r"""(
    (stop|halt|pause)\b[^.\n]{0,30}\b(and\s+)?(ask|confirm|get\s+confirmation)
  | ask\s+(the\s+(user|owner)\s+)?(first|before)
  | confirm(ation)?\s+(before|first|each)
  | CONFIRM\s+EACH\s+TIME
  | without\s+(explicit|fresh)\s+(user\s+)?(approval|confirmation)
  | without\s+the\s+user'?s?\s+explicit\s+(confirmation|approval)
  | explicit\s+(user|owner)('s)?\s+(confirmation|approval)
  | requires?\s+fresh\s+(user\s+)?(confirmation|approval)
  | put\s+the\s+decision\s+back\s+to\s+the\s+user
  | WITH\s+THE\s+USER\s+before
  | owner\s+approval\s+in\s+this\s+turn
  | push\s+back\s+individually\s+before\s+accepting
  | question\s+comes\s+first
  | ask\s+in\s+one\s+line
  | hand\s+the\s+commit\s+to\s+the\s+user
  | wait\s+for\s+(the\s+)?user
  | only\s+the\s+owner\s+can\s+answer
)""", re.IGNORECASE | re.VERBOSE)

def parse_frontmatter(text):
    """Return dict of {field: raw_value_str} plus list of trigger entries. Minimal YAML-ish parser."""
    if not text.startswith("---\n"):
        return None, None
    end = text.find("\n---\n", 4)
    if end == -1:
        return None, None
    fm = text[4:end]
    fields = {}
    triggers = []
    current_key = None
    in_triggers = False
    for line in fm.splitlines():
        if not line.strip():
            continue
        if in_triggers and line.startswith("  - "):
            triggers.append(line[4:].strip())
            continue
        # Top-level key
        m = re.match(r"^([a-zA-Z_]+):\s*(.*)$", line)
        if m:
            key, val = m.group(1), m.group(2).strip()
            fields[key] = val
            in_triggers = (key == "triggers")
            current_key = key
    fields["triggers"] = triggers
    return fields, fm

def main():
    errors = 0
    warnings = 0
    trigger_map = defaultdict(list)
    today = date.today()
    files_checked = 0

    for root in ROOTS:
        d = HOME_CLAUDE / root
        if not d.is_dir():
            print(f"✗ missing directory: {d}")
            errors += 1
            continue
        for f in sorted(d.glob("*.md")):
            if f.name == "README.md":
                continue  # folder index, not a triggerable sub-file
            files_checked += 1
            rel = f.relative_to(HOME_CLAUDE)
            text = f.read_text()
            fields, fm = parse_frontmatter(text)
            if fields is None:
                print(f"✗ {rel}: no frontmatter")
                errors += 1
                continue
            # Required fields
            for field in REQUIRED_FIELDS:
                if field not in fields:
                    print(f"✗ {rel}: missing field '{field}'")
                    errors += 1
            # Tier
            tier = fields.get("tier", "")
            if tier not in VALID_TIERS:
                print(f"✗ {rel}: invalid tier '{tier}' (want 0|1|2|3)")
                errors += 1
            # Category
            cat = fields.get("category", "")
            if cat != root:
                print(f"✗ {rel}: category '{cat}' != directory '{root}'")
                errors += 1
            # Updated date
            updated_str = fields.get("updated", "")
            try:
                updated_dt = datetime.strptime(updated_str, "%Y-%m-%d").date()
            except ValueError:
                print(f"✗ {rel}: invalid updated '{updated_str}' (want YYYY-MM-DD)")
                errors += 1
                updated_dt = None
            # Stale days
            stale_str = fields.get("stale_after_days", "")
            try:
                stale_days = int(stale_str)
            except ValueError:
                print(f"✗ {rel}: invalid stale_after_days '{stale_str}'")
                errors += 1
                stale_days = None
            if updated_dt and stale_days is not None:
                age = (today - updated_dt).days
                if age > stale_days:
                    print(f"⚠ {rel}: STALE — {age}d since update (threshold {stale_days}d)")
                    warnings += 1
            # Triggers
            for t in fields.get("triggers", []):
                prefix = t.split(":", 1)[0]
                if prefix not in VALID_PREFIXES:
                    print(f"✗ {rel}: trigger '{t}' has invalid prefix (want: {sorted(VALID_PREFIXES)})")
                    errors += 1
                trigger_map[t].append(str(rel))
            # Halt-scope anchor (always-loaded rules only; scoped rules have paths:)
            if root == "rules" and f.stem != HALT_ANCHOR and "paths" not in fields:
                body = text[text.find("\n---\n", 4) + 5:] if text.startswith("---\n") else text
                if HALT_DIRECTIVE.search(body) and HALT_ANCHOR not in text:
                    print(f"✗ {rel}: halt directive without the halt-scope anchor — "
                          f"add the one-line inaction clause referencing "
                          f"`never-halt-on-authority-you-hold.md` "
                          f"(see assets/reports/20260901-halt-imbalance/report.md)")
                    errors += 1

    # Trigger collisions
    print("\n── Trigger collision report ──")
    collisions = 0
    for t in sorted(trigger_map):
        files = trigger_map[t]
        if len(files) > 1:
            print(f"⚠ '{t}' appears in: {', '.join(files)}")
            collisions += 1
            warnings += 1
    if collisions == 0:
        print("  none")

    print("\n── Summary ──")
    print(f"  errors:        {errors}")
    print(f"  warnings:      {warnings}")
    print(f"  files checked: {files_checked}")

    if errors > 0:
        sys.exit(1)
    if warnings > 0:
        sys.exit(2)
    sys.exit(0)

if __name__ == "__main__":
    main()
