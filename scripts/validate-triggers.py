#!/usr/bin/env python3
"""validate-triggers.py: Validate sub-file frontmatter in ~/.claude/{rules,features,conventions}/

Checks:
  - Every .md file has YAML frontmatter with required fields
  - Every trigger uses a known prefix (tool:|topic:|phrase:|skill:|mcp:)
  - No trigger collisions across files (soft warning)
  - tier is 0|1|2|3
  - category matches the directory name
  - updated date is valid YYYY-MM-DD
  - stale_after_days is a number; a doc unchanged for longer emits a warning
    (age counts from its last commit or uncommitted edit, not only `updated:`)
  - always-loaded rules/ files with a halt directive carry the never-halt anchor
  - triggers and related parse in both block and inline-list form (warning on
    an unquoted phrase trigger, and on a related: entry that names no file)
  - every features/ and conventions/ doc has a row in LOOKUP.md (warning)

Shared triggers (a rule and its feature sharing a topic) are normal, so they
print as one info line; --collisions lists them.

Exit codes:
  0  all files valid
  1  at least one hard error
  2  soft warning only
"""
import argparse
import subprocess
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
ALWAYS_RULE_CAP = 2200  # bytes; owner D1a 2026-09-18
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

LIST_KEYS = ("triggers", "related")  # parsed into lists, block or inline form


def split_inline_list(raw):
    """Split the inside of `[a, "b, c", d]` on commas that sit outside double quotes."""
    items, buf, in_quote, escaped = [], [], False, False
    for ch in raw:
        if escaped:
            buf.append(ch)
            escaped = False
        elif ch == "\\" and in_quote:
            buf.append(ch)
            escaped = True
        elif ch == '"':
            in_quote = not in_quote
            buf.append(ch)
        elif ch == "," and not in_quote:
            items.append("".join(buf).strip())
            buf = []
        else:
            buf.append(ch)
    items.append("".join(buf).strip())
    return [i for i in items if i]


def unquote_item(item):
    """Undo YAML quoting around a whole list item: "phrase:\\"x\\"" becomes phrase:"x"."""
    item = item.strip()
    if len(item) >= 2 and item[0] == item[-1] and item[0] in "\"'":
        inner = item[1:-1]
        return inner.replace('\\"', '"') if item[0] == '"' else inner
    return item


def parse_frontmatter(text):
    """Return dict of {field: raw_value_str} with triggers and related as lists. Minimal YAML-ish parser."""
    if not text.startswith("---\n"):
        return None, None
    end = text.find("\n---\n", 4)
    if end == -1:
        return None, None
    fm = text[4:end]
    fields = {}
    lists = {k: [] for k in LIST_KEYS}
    current_list = None
    for line in fm.splitlines():
        if not line.strip():
            continue
        if current_list and re.match(r"^\s+-\s+", line):
            lists[current_list].append(unquote_item(re.sub(r"^\s+-\s+", "", line)))
            continue
        # Top-level key
        m = re.match(r"^([a-zA-Z_]+):\s*(.*)$", line)
        if m:
            key, val = m.group(1), m.group(2).strip()
            fields[key] = val
            current_list = key if key in LIST_KEYS else None
            if current_list and val.startswith("[") and val.endswith("]"):
                lists[key] = [unquote_item(i) for i in split_inline_list(val[1:-1])]
                current_list = None
    fields["triggers"] = lists["triggers"]
    fields["related_list"] = lists["related"]
    return fields, fm


def related_resolves(entry):
    """True when a related: entry names something that exists: a path, a bare rule/feature/convention name, or a ~ path."""
    e = unquote_item(entry)
    e = re.sub(r"^\[\[|\]\]$", "", e).split("#", 1)[0].strip()
    if not e:
        return True
    if e.startswith("~/"):
        return (Path.home() / e[2:]).exists()
    if e.startswith("/"):
        return Path(e).exists()
    candidates = [HOME_CLAUDE / e, HOME_CLAUDE / (e + ".md")]
    for root in ROOTS:
        candidates += [HOME_CLAUDE / root / e, HOME_CLAUDE / root / (e + ".md")]
    return any(c.exists() for c in candidates)


def lookup_rows():
    """Paths named in the first cell of any LOOKUP.md table row (None if the index is absent)."""
    lookup = HOME_CLAUDE / "LOOKUP.md"
    if not lookup.is_file():
        return None
    rows = set()
    for line in lookup.read_text().splitlines():
        if line.startswith("|"):
            cells = line.split("|")
            if len(cells) > 1:
                rows.update(re.findall(r"`([^`]+)`", cells[1]))
    return rows

def last_changed_dates():
    """When each doc last changed on disk, so staleness does not depend on a hand-kept field.

    Nobody bumps `updated:` on an edit, so a doc edited yesterday read as months
    stale. Returns {repo-relative path: date} from the last commit that touched
    the file, or from its mtime when it has uncommitted changes. Empty when git
    is unavailable; the caller then falls back to `updated:` alone.
    """
    def git(*args):
        try:
            r = subprocess.run(["git", "-C", str(HOME_CLAUDE), *args],
                               capture_output=True, text=True, timeout=60)
        except (OSError, subprocess.SubprocessError):
            return ""
        return r.stdout if r.returncode == 0 else ""

    dates = {}
    day = None
    for line in git("log", "--format=@%cs", "--name-only", "--", *ROOTS).splitlines():
        if line.startswith("@"):
            day = line[1:]
        elif line and line not in dates and day:
            dates[line] = datetime.strptime(day, "%Y-%m-%d").date()  # newest commit comes first
    for line in git("status", "--porcelain", "--", *ROOTS).splitlines():
        rel = line[3:].split(" -> ")[-1].strip('"')
        f = HOME_CLAUDE / rel
        if f.is_file():
            dates[rel] = date.fromtimestamp(f.stat().st_mtime)
    return dates


def main():
    parser = argparse.ArgumentParser(description="Validate rules/features/conventions frontmatter.")
    parser.add_argument("--collisions", action="store_true",
                        help="list every trigger shared by more than one file")
    args = parser.parse_args()

    errors = 0
    warnings = 0
    trigger_map = defaultdict(list)
    today = date.today()
    files_checked = 0
    indexed = lookup_rows()
    changed = last_changed_dates()

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
                # The later of the declared date and the last real change.
                touched = max(updated_dt, changed.get(str(rel), updated_dt))
                age = (today - touched).days
                if age > stale_days:
                    print(f"⚠ {rel}: STALE: {age}d since it last changed (threshold {stale_days}d)")
                    warnings += 1
            # Triggers
            for t in fields.get("triggers", []):
                prefix = t.split(":", 1)[0]
                if prefix not in VALID_PREFIXES:
                    print(f"✗ {rel}: trigger '{t}' has invalid prefix (want: {sorted(VALID_PREFIXES)})")
                    errors += 1
                elif prefix == "phrase" and ":" in t:
                    phrase = t.split(":", 1)[1]
                    if not (len(phrase) >= 2 and phrase[0] == '"' and phrase[-1] == '"'):
                        print(f"⚠ {rel}: phrase trigger '{t}' is unquoted (want phrase:\"<exact string>\")")
                        warnings += 1
                trigger_map[t].append(str(rel))
            # related: entries must name something that exists
            for r in fields.get("related_list", []):
                if not related_resolves(r):
                    print(f"⚠ {rel}: related entry '{r}' names no file")
                    warnings += 1
            # Index coverage: every features/ and conventions/ doc has a LOOKUP.md row
            if indexed is not None and root in ("features", "conventions"):
                if f"{root}/{f.name}" not in indexed:
                    print(f"⚠ {rel}: NOT IN LOOKUP (no table row names `{root}/{f.name}`)")
                    warnings += 1
            # Byte cap on always-loaded rules (owner D1a, 2026-09-18); provenance
            # lives in ~/.claude/rules-provenance/<name>.md.
            if root == "rules" and "paths" not in fields and f.stem != "00-index":
                nbytes = len(text.encode("utf-8"))
                if nbytes > ALWAYS_RULE_CAP:
                    print(f"✗ {rel}: {nbytes} bytes; the always-loaded cap is {ALWAYS_RULE_CAP}. "
                          f"Fold provenance into ~/.claude/rules-provenance/{f.stem}.md and keep the directive")
                    errors += 1
            # Halt-scope anchor (always-loaded rules only; scoped rules have paths:)
            if root == "rules" and f.stem != HALT_ANCHOR and "paths" not in fields:
                body = text[text.find("\n---\n", 4) + 5:] if text.startswith("---\n") else text
                if HALT_DIRECTIVE.search(body) and HALT_ANCHOR not in text:
                    print(f"✗ {rel}: halt directive without the halt-scope anchor: "
                          f"add the one-line inaction clause referencing "
                          f"`never-halt-on-authority-you-hold.md` "
                          f"(see assets/reports/20260901-halt-imbalance/report.md)")
                    errors += 1

    # Shared triggers: normal when a rule and its feature share a topic, so
    # they are info, not warnings, and the detail is behind --collisions.
    shared = {t: fs for t, fs in sorted(trigger_map.items()) if len(fs) > 1}
    if args.collisions:
        print("\n── Shared triggers ──")
        for t, fs in shared.items():
            print(f"  '{t}' appears in: {', '.join(fs)}")
        if not shared:
            print("  none")
    elif shared:
        print(f"\nⓘ {len(shared)} triggers are shared by more than one file "
              f"(normal for a rule and its feature); list them with --collisions")

    print("\n── Summary ──")
    print(f"  errors:        {errors}")
    print(f"  warnings:      {warnings}")
    print(f"  shared (info): {len(shared)}")
    print(f"  files checked: {files_checked}")

    if errors > 0:
        sys.exit(1)
    if warnings > 0:
        sys.exit(2)
    sys.exit(0)

if __name__ == "__main__":
    main()
