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
