---
brief: Proactive Unicode box-drawing diagrams for architecture/flows; 78-char max; /diagram for complex layouts
triggers:
  - skill:diagram
  - topic:diagrams
  - topic:architecture-explanation
  - phrase:"box drawing"
related: []
tier: 2
category: conventions
updated: 2026-04-24
stale_after_days: 90
---

# Ascii Diagrams
When explaining architecture, data flows, state machines, request lifecycles, directory structures, or multi-step processes, **proactively include ASCII diagrams** alongside text.

## Rules

- Use Unicode box-drawing characters: `┌─┐│└─┘├┤┬┴┼──▶`
- Place the diagram **before** the text explanation
- Max width: **78 chars**
- Wrap in code blocks so rendering is monospaced
- Use `/diagram` skill for complex layouts

## Do NOT diagram

- Simple lists
- Single functions
- Config examples
- Error messages

## Example — when useful

```
┌─────────────┐     write       ┌──────────────┐
│   Client    │ ───────────────▶│  API server  │
└─────────────┘                 └──────┬───────┘
                                       │ enqueue
                                       ▼
                                ┌──────────────┐
                                │  job queue   │
                                └──────────────┘
```

## Complex layouts

For multi-box architecture diagrams, dashboards, or anything with tables + boxes side-by-side, use the `/diagram` skill — it invokes `gum-tui.sh` for box-accurate rendering.

## Using `gum-tui.sh` directly

When you need a single styled block without invoking `/diagram`, source `gum-tui.sh` and use its helpers. They guarantee alignment under varying terminal widths and respect `NO_COLOR` / non-TTY.

```bash
source ~/.claude/skills/shared/gum-tui.sh
```

**Example 1 — bordered status panel:**

```bash
gum_panel "Deploy Status" \
  "frontend  ✓ 3042 live (build: 4s ago)" \
  "backend   ✓ 5042 live (build: 4s ago)" \
  "nginx     ⚠ reload needed"
```

**Example 2 — table (column alignment for free):**

```bash
gum_table "Skill,Tier,Updated" \
  "wal,1,2026-04-24" \
  "llm-mini,2,2026-04-24" \
  "desktop-automation,2,2026-04-24"
```

**Example 3 — header + completion block at task end:**

```bash
gum_header "Migration 0007 — Scripts cleanup"
# ...work...
gum_complete "scripts-cleanup" \
  "files moved=27" \
  "refs updated=14" \
  "backups trashed=15"
```

For every other `gum_*` helper (`gum_success`, `gum_warn`, `gum_error`, `gum_kv`, `gum_join_h`, `gum_join_v`), run `bash ~/.claude/skills/shared/gum-tui.sh` with no args for the help listing, or `demo` to see every helper rendered.

## Full gallery

Read [`~/.claude/assets/docs/gum-rendering-examples.md`](../assets/docs/gum-rendering-examples.md) when composing multi-box layouts, dashboards, or choosing border styles — it has box-accurate examples of every pattern with exact `gum style` / `gum join` / `gum table` invocations.
