---
brief: Where to file odd system behaviour seen once and not explained, signed by the session that looked into it.
triggers:
  - tool:observed
  - topic:one-off-bug
  - phrase:"seen once"
tier: 2
category: features
updated: 2026-11-02
stale_after_days: 180
---

# One-off bugs: the observed log

When something odd happens once and nobody can explain it, file it with
`~/.claude/scripts/observed/observed new`. A second sighting then starts from what
the first one learned, not from nothing.

| Kind of thing | Where it goes |
|---|---|
| Something the machine or the gcc did, cause unknown | `observed` |
| A mistake an agent made | `/atone` |
| An idea for making things better | `/gcc-proposal` |
| An incident with a known cause and a write-up | `conventions/rca-template.md` |

```bash
observed new "Short title" --what "what was seen, with times and numbers" \
  --tried "what was checked" --ruled-out "what it is not, and the evidence" \
  --open "what would settle it next time"
observed note SLUG "text"     # annotate
observed again SLUG "text"    # another sighting, which raises the count
observed close SLUG "cause"   # explained
observed list [--all]
```

Each entry is one markdown file in `~/.claude/assets/observed/`, signed with the
session's name and id so a reader can open the transcript. Annotations are
appended, also signed. Keep what was ruled out: it is usually the most useful part
of a one-off.
