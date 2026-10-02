#!/usr/bin/env python3
"""List atone slugs that rules/README.md says should become a gate.

The rule: past 20 events a slug is a hook candidate or nothing, because rule
text did not move it. A slug qualifies here when it has more than THRESHOLD
real events (migrated seed rows excluded), its name appears in rules/ or
CLAUDE.md, and no hook under scripts/hooks/ mentions it.

Read-only. Usage: hook-candidates.py [--threshold N]
"""
import json
import sys
from collections import Counter
from pathlib import Path

home = Path.home() / ".claude"
threshold = 20
if "--threshold" in sys.argv:
    threshold = int(sys.argv[sys.argv.index("--threshold") + 1])

counts: Counter = Counter()
for line in (home / "atone/events.jsonl").read_text(errors="replace").splitlines():
    try:
        e = json.loads(line)
    except json.JSONDecodeError:
        continue
    if "[migrated v1" in (e.get("issue") or ""):
        continue
    if e.get("slug"):
        counts[e["slug"]] += 1


def corpus(paths):
    text = []
    for p in paths:
        for f in ([p] if p.is_file() else p.rglob("*")):
            if f.is_file() and f.suffix in {".md", ".sh", ".py", ".json", ""}:
                try:
                    text.append(f.read_text(errors="replace"))
                except OSError:
                    pass
    return "\n".join(text)


rules_text = corpus([home / "rules", home / "CLAUDE.md"])
hooks_text = corpus([home / "scripts/hooks"])

rows = []
for slug, n in counts.most_common():
    if n <= threshold:
        break
    in_rules = slug in rules_text
    gated = slug in hooks_text
    if in_rules and not gated:
        rows.append((slug, n))

print(f"hook candidates (> {threshold} events, rule text, no hook mentions the slug):")
for slug, n in rows:
    print(f"  {n:4d}  {slug}")
if not rows:
    print("  none")
