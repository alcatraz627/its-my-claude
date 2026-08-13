#!/usr/bin/env bash
# skills-index.sh — regenerate skills/00-index.md, the one-line-per-skill retrieval
# menu. DERIVED from each SKILL.md's frontmatter; never hand-edit the generated
# table (fix the skill's `description:` and re-run instead).
#
# Why an index exists: the owner's skill lookups are recall-shaped ("I faintly
# remember something exists"), and answering that means scanning 90 frontmatters.
# This menu is the cheap surface both /pick-skill and a human eyeball can search.
# Regenerating is fast enough (<1s) that consumers run this script first and never
# worry about staleness.
#
# Scope: gcc-local skills (~/.claude/skills/*/SKILL.md) only. Plugin skills live
# in their plugin caches and are already listed in the session skill roster.
set -uo pipefail

SKILLS="$HOME/.claude/skills"
OUT="$SKILLS/00-index.md"
today=$(date '+%Y-%m-%d')
stamp=$(date '+%Y-%m-%d %H:%M')

{
  cat <<EOF
---
brief: One-line-per-skill retrieval menu (name + invoke mode + gist), DERIVED from each SKILL.md's frontmatter via scripts/skills-index.sh. The search surface for "I half-remember a skill exists".
triggers:
  - topic:skills-index
  - phrase:"which skill"
  - phrase:"is there a skill"
  - skill:pick-skill
related:
  - skills/pick-skill/SKILL.md
  - rules/00-index.md
tier: 2
category: skills
updated: $today
stale_after_days: 365
---

# Skills index

One line per skill in \`~/.claude/skills/\`. Scan or \`rg\` this menu, then read the
full \`skills/<name>/SKILL.md\` before invoking. DERIVED from frontmatter;
regenerate with \`bash ~/.claude/scripts/skills-index.sh\` (fast; run it first,
then read).

The **Invoke** column: \`yes\` = user \`/name\` and model auto-invoke both allowed ·
\`user-only\` = \`disable-model-invocation: true\`, the user must type it ·
\`bg\` = \`user-invokable: false\`, background knowledge, not in the \`/\` menu.

Regenerated $stamp.

| Skill | Invoke | Gist |
|-------|--------|------|
EOF

  python3 - "$SKILLS" <<'PY'
import os, re, sys

root = sys.argv[1]

def frontmatter(text):
    if not text.startswith("---"):
        return {}
    end = text.find("\n---", 3)
    if end < 0:
        return {}
    fm, out, key = text[3:end].split("\n"), {}, None
    for line in fm:
        m = re.match(r"^([A-Za-z_-]+):\s*(.*)$", line)
        if m:
            key, val = m.group(1), m.group(2).strip()
            out[key] = val
        elif key and line.startswith((" ", "\t")):
            # folded/indented continuation ("description: >" style)
            out[key] = (out[key] + " " + line.strip()).strip()
    return out

def gist(desc, limit=170):
    d = re.sub(r"\s+", " ", desc).strip().lstrip(">|").strip()
    if len(d) <= limit:
        return d
    return d[:limit].rsplit(" ", 1)[0] + " …"

rows = []
for name in sorted(os.listdir(root)):
    path = os.path.join(root, name, "SKILL.md")
    if not os.path.isfile(path):
        continue
    fm = frontmatter(open(path, encoding="utf-8", errors="replace").read())
    desc = fm.get("description", "")
    invoke = "yes"
    if fm.get("user-invokable", "").lower() == "false":
        invoke = "bg"
    elif fm.get("disable-model-invocation", "").lower() == "true":
        invoke = "user-only"
    g = gist(desc) if desc else "(no description; add frontmatter)"
    rows.append((name, invoke, g.replace("|", "\\|")))

for name, invoke, g in rows:
    print(f"| `{name}` | {invoke} | {g} |")
PY
} >"$OUT"

echo "skills index regenerated: $OUT ($(grep -c '^| `' "$OUT") skills)"
