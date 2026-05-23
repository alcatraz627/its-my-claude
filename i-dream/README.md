# `~/.claude/i-dream/` — data dir for the i-dream system

This is the **runtime data** directory. The source code lives at
`~/Code/Claude/i-dream/`. The full primer lives at:

> **`~/Code/Claude/i-dream/docs/19-quick-primer.md`**

Quick orientation for what's here:

```
~/.claude/i-dream/
├── daily/                  L2 daily digest output
│   ├── YYYY-MM-DD.md       one per day
│   └── latest.md           → symlink to today
├── derived/                shared cross-domain artifacts
│   ├── tldr.union.txt      top-5 across all domains
│   ├── triggers.union.json all domain triggers merged
│   └── associations.cross.jsonl  cross-domain dream-pass output
├── domains/                centralized plugin manifests (currently empty;
│                            atone, affirm, pinned, memory, sessions use
│                            sibling-inline manifests instead)
├── logs/                   launchd cron logs
│   ├── daily.out.log
│   └── daily.err.log
├── audits/                 (B Stage 5+6 — coming)
│   ├── YYYY-MM-DD.md       per-audit log
│   └── _rejections.jsonl   4-week rejection memory
└── _runtime.json           per-domain enable/disable state
```

For the user-facing how-to, read the primer linked above.
For per-stage status, see `~/Code/Claude/i-dream/docs/15-roadmap.md`.
