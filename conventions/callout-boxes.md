---
brief: One anatomy for every inline callout, v2. Emoji names the emitter (closed vocab in scripts/box/vocab.tsv), rail weight carries severity, the seal carries lifecycle, refs stay clickable. Compose by hand per the anatomy; `box list` when unsure; `box <kind>` for ledger/thread/multi-ref shapes. Box only when action is owed, else line-tag.
triggers:
  - topic:callout-boxes
  - topic:hook-output
  - phrase:"pretty box"
  - phrase:"surface this box"
  - tool:hook_box
  - tool:box
related:
  - rules/surface-hook-nudges-to-user.md
  - features/hooks-tui-limits.md
  - features/hook-design.md
tier: 2
category: conventions
updated: 2026-08-14
stale_after_days: 180
---

# Callout boxes, one dialect (v2)

Every inline callout the owner sees, whether a hook composed it or the agent
did, wears one anatomy. v1 closed five dialects into one; v2 (owner-ratified
2026-08-14, design record: `assets/reports/20260814-1410-callout-box-ideas/`)
adds the emitter vocabulary, severity rails, lifecycle seals, and refs.

## The anatomy, five rules

```
┌─ 🛬 subagent · review-seat ─────────────────────── landed 4m12s ──
│ report    412 lines      found   23 (4 high · 11 med · 8 low)
│ ▸ /abs/path/to/review.md
│ → relaying the 4 high verbatim below
└─ ✅ report read before trusting ──────────────────────────────────
```

1. **Emoji names the emitter, rails carry severity, seal carries lifecycle.**
   The glyph slot is a colored emitter emoji from the closed vocabulary.
   Light rails `┌─ │ └` for advisory and informational events; heavy rails
   `┏━ ┃ ┗` when the turn cannot proceed as-is (gates). The seal stays plain
   while the event is open; when it resolves in the same turn the agent
   rewrites it as `└─ ✅ <outcome> ──…`. Agent-side only: a hook composes
   its box before the outcome exists.
2. **The `→` line is still the point.** A box exists because someone must act
   or decide; the arrow line says who is doing what. No arrow, no box: that
   content is a line-tag.
3. **The header's right end carries attributes.** Reply-by, duration,
   model · effort, severity and recency. One composed line is cheap to pad;
   a closed right edge stays rejected (every body line would need exact
   padding, and emoji make bash's width math a lie).
4. **Machine payloads ride `▸` ref lines** between body and arrow: paths
   absolute, one per line, never wrapped, nothing after the path (Ghostty
   auto-links it; the filename-dot rule extends into boxes). Ref lines are
   the only lines allowed past width 72. Body prose caps at ~6 lines; past
   that, digest + `▸` the artifact. A box is a surface, not storage.
5. **Width 72, one box per event, dedup at source.** Repeats of an identical
   nudge surface once; re-firing emitters carry a parked-once marker the way
   subagent-box.sh absorbs SubagentStop re-fires. `×N` in the title is only
   ever a true count (atone recurrence, deduped re-fires).

## The emitter vocabulary

Canonical source: `~/.claude/scripts/box/vocab.tsv`, read by both renderers;
`box list` prints the live set. Illustration (drifts lose to the tsv):

🪝 hook · ⛔ gate (heavy) · 🛫/🛬 subagent dispatch/landing · 📥/📤 ipc
in/out · 🙏 atone · 🏅 affirm · 📏 rule · 🏁 done · seal-only ✅ ·
tag-tier (never boxed): 🌙 dream · 🌡️ ctx · 📋 kanban · 💡 insight

Admission is deliberate: a new emoji or kind means a vocab.tsv row, a
Ghostty render-check (emoji are double-width and font-dependent; the open
right edge is what makes their width safe), and a note here.

## Body shapes

- **Prose** is the default.
- **Ledger rows** for tabular payloads (subagent stats, verification
  bundles): aligned key columns, two max. `box <kind> … --kv "k:v"` aligns
  them for you.
- **Thread** when the whole arc completed inside one turn: event, steps,
  outcome on one spine. Never forced; an open event gets a full box.

  ```
  ⛔ gate · declared-ready
  │ "done" claimed with no run signal this turn
  ├ → ran the changed path: zsh suite 79/79 green
  └ ✅ re-claimed; gate satisfied
  ```

## Two absorbed dialects (owner ruling 2026-08-14, same day)

- **Completion blocks are 🏁 done boxes.** The GUIDELINES.md §Output
  templates (skill-run and user-goal) now prescribe the v2 shape: ledger
  body for the stats, `▸` refs for the files that matter, and the arrow
  line carrying "what needs the reader", which used to float in prose.
- **Insights are 💡 tags, not ★ boxes.** An insight owes no action, so it
  gets no rails, even under the Explanatory output style's ★ template; the
  house dialect overrides the style's decoration. It is the one sanctioned
  multi-line tag: continuation lines take a hanging indent.

  ```
  💡 insight · the guard was dead because Bash-tool stdin is never a tty;
     gate on the actual input mode, not tty-ness
  ```

## Decisions route to the wizard

A box never grows its own option menu. When an event needs an owner call,
the arrow line says "decision below" and the decision-wizard surface
follows: an inline numbered menu for up to ~3 simple picks, the decision
page on :5197 for batches. Dialog tools stay banned in the fullscreen TUI.

## Who renders what

- **Agent-side, the default: compose by hand.** A box is plain text in the
  reply; typing it is the whole interface. When unsure what exists, run
  `box list`. For the hard shapes (ledger alignment, threads, many refs,
  heavy rails), render with `box <kind> <name> --body … --action … [--ref
  …] [--attr …] [--kv k:v] [--count N] [--seal …] [--block]` and paste the
  stdout verbatim. `box <kind> --template` prints a fill-in skeleton.
- **Hook-side:** compose through `hook_box_kind <kind> <name> [attr]` in
  `scripts/hooks/hook-common.sh`; it reads the same vocabulary via box.sh
  and falls back to plain `hook_box` on a half-installed tree. Never
  hand-roll the rails. The box travels as additionalContext with a
  surface-verbatim instruction, because no hook channel reaches the
  transcript directly (features/hooks-tui-limits.md).
- **Box or tag?** Needs an action or a decision: box. Ambient context the
  reader may ignore (ctx-pressure, dream lessons, ipc informs with no reply
  owed): line-tag, optionally via `box tag <kind> "<text>"`. Tags never
  grow rails.

## Out of scope

The ceremonial records (trace.sh dump/catchup renders) are their own
owner-ruled design and never use this anatomy. gum-tui skill panels are
interactive TUI output, also separate.

## Migration notes

subagent-box.sh and prose-smell-stop.sh moved to the v2 vocabulary on
2026-08-14 (hook-common.test.sh pins both), and the two GUIDELINES.md
completion-block templates were rewritten to the 🏁 shape the same day. Remaining boxless gate prose
(rg-replace guard, review-gate, declared-ready Stop feedback) adopts
`hook_box_kind` opportunistically, when each file is next edited for cause;
no sweep commit.
