#!/usr/bin/env bash
# regress.sh — compare a fresh thorough-run against a pinned baseline.
#
# Usage:
#   regress.sh <baseline-dir> <candidate-dir>
#
# Pass criteria (per FINAL-PLAN.md §6 success criteria):
#   - theme count within ±10% of baseline
#   - every baseline DEFINITELY issue title appears in candidate (any tier)
#   - candidate ops-checklist covers >=80% of baseline ops-checklist line items
#
# Exits 0 on pass, 1 on regression. Prints a diff summary either way.
# Does NOT re-run the LLM phases — validates already-produced artifacts.

set -euo pipefail
BASE="${1:?usage: regress.sh <baseline-dir> <candidate-dir>}"
CAND="${2:?usage: regress.sh <baseline-dir> <candidate-dir>}"

python3 - "$BASE" "$CAND" <<'PY'
import sys, os, re, glob

base, cand = sys.argv[1], sys.argv[2]

def find(root, *names):
    """Find the first existing file among candidate relative paths."""
    for n in names:
        p = os.path.join(root, n)
        if os.path.exists(p):
            return p
    # glob fallback
    for n in names:
        hits = glob.glob(os.path.join(root, "**", os.path.basename(n)), recursive=True)
        if hits:
            return hits[0]
    return None

def read(p):
    return open(p).read() if p and os.path.exists(p) else ""

# Themes file: old layout v2/THEMES.md, new layout themes/THEMES.md
base_themes = read(find(base, "themes/THEMES.md", "v2/THEMES.md"))
cand_themes = read(find(cand, "themes/THEMES.md", "v2/THEMES.md"))

def count_themes(txt):
    return len(re.findall(r"(?m)^##\s+Theme:", txt))

bt, ct = count_themes(base_themes), count_themes(cand_themes)

# DEFINITELY issues: old v3/ISSUES.md or themes/ISSUES.md
def definitely_titles(txt):
    titles = []
    in_def = False
    for line in txt.split("\n"):
        if re.match(r"^##\s+DEFINITELY", line, re.I): in_def = True; continue
        if re.match(r"^##\s+(MAYBE|TO-CHECK|CLOSED)", line, re.I): in_def = False; continue
        if in_def:
            m = re.search(r"\[ISS-\d+\]\s*(?:\[\w+\]\s*)?(.+?)(?:·|$)", line)
            if m: titles.append(m.group(1).strip().lower())
    return titles

base_issues = read(find(base, "themes/ISSUES.md", "v3/ISSUES.md", "v2/ISSUES.md"))
cand_issues = read(find(cand, "themes/ISSUES.md", "v3/ISSUES.md", "v2/ISSUES.md"))
base_def = definitely_titles(base_issues)
cand_all = cand_issues.lower()

# Fuzzy presence: at least 2 significant words of the title appear in candidate issues
def present(title, hay):
    words = [w for w in re.findall(r"[a-z_]{4,}", title)]
    if not words: return True
    hits = sum(1 for w in words if w in hay)
    return hits >= max(1, len(words)//3)

missing_def = [t for t in base_def if not present(t, cand_all)]

# Ops checklist coverage
def checklist_items(txt):
    return [l.strip() for l in txt.split("\n") if re.match(r"^\s*-\s*\[\s*\]", l)]

base_ops = read(find(base, "render/OPS-CHECKLIST.md"))
cand_ops = read(find(cand, "render/OPS-CHECKLIST.md"))
base_ops_items = checklist_items(base_ops)
cand_ops_text = cand_ops.lower()
def ops_present(item):
    words = [w for w in re.findall(r"[a-z_]{4,}", item.lower())]
    if not words: return True
    return sum(1 for w in words if w in cand_ops_text) >= max(1, len(words)//4)
ops_covered = sum(1 for i in base_ops_items if ops_present(i)) if base_ops_items else 0
ops_pct = (ops_covered / len(base_ops_items) * 100) if base_ops_items else 100.0

# Verdicts
theme_ok = bt == 0 or abs(ct - bt) <= 0.10 * bt
def_ok = len(missing_def) == 0
ops_ok = ops_pct >= 80.0 or not base_ops_items

print("=== regression: baseline vs candidate ===")
print(f"themes:        baseline={bt}  candidate={ct}  {'OK' if theme_ok else 'REGRESSION (>10% drift)'}")
print(f"DEFINITELY:    baseline={len(base_def)}  missing in candidate={len(missing_def)}  {'OK' if def_ok else 'REGRESSION'}")
for t in missing_def:
    print(f"  MISSING: {t}")
print(f"ops coverage:  {ops_covered}/{len(base_ops_items)} = {ops_pct:.0f}%  {'OK' if ops_ok else 'REGRESSION (<80%)'}")

if theme_ok and def_ok and ops_ok:
    print("\nPASS")
    sys.exit(0)
else:
    print("\nFAIL — see regressions above")
    sys.exit(1)
PY
