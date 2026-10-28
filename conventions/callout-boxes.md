---
brief: One anatomy for every inline callout, v3. Emoji names the emitter (closed vocab in scripts/box/vocab.tsv), rail weight carries severity, every row starts with a coloured marker, the box is padded and 84 wide, and anything to copy prints bare under it. Render with `box <kind>`; records with `record-box.py <id>`. Box only when action is owed or a record was made, else line-tag.
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

# Callout boxes, one dialect (v3)

Every inline callout the owner sees, whether a hook composed it or the agent
did, wears one anatomy. v1 closed five dialects into one; v2 (owner-ratified
2026-08-14, design record: `assets/reports/20260814-1410-callout-box-ideas/`)
added the emitter vocabulary, severity rails and seals. v3 (owner-ratified
2026-10-28) gives every row a coloured marker, pads the box, widens it to 84,
and moves anything copyable under the box.

## The anatomy, six rules

```
┌─ 💾 core-dump · cdump-kwarm-4e ───────────────────────────────────────── 13:05 ──
│
│  ➡️ next  look at the gcc-mods dumped row after a real /core-dump with /hub on
│  🟠 you   OK to remove snippets/
│  🟡 note  the keep-warm box change is unseen on a real wake
│
└─ 📋 ① after /clear here  ② in a new terminal ─────────────────────────────────────

/catchup at /Users/alcatraz627/.claude/_20261028-polish-cdump-4e.claude.md
clo -n cdump-kwarm-4e "/catchup at /Users/alcatraz627/.claude/_20261028-polish-cdump-4e.claude.md"
```

1. **Emoji names the emitter, rails carry severity.** The title glyph comes
   from the closed vocabulary. Light rails `┌─ │ └` for advisory and
   informational events; heavy rails `┏━ ┃ ┗` when the turn cannot proceed
   as-is (gates). A seal `└─ ✅ <outcome>` closes an event resolved in the
   same turn.
2. **Every row starts with a marker, and a line without one is noise.** The
   owner skips a hunk of text with no indicator, so each row is
   `<marker> <label>  <text>`, labels padded to one column, wrapped text
   indented under its own value. Markers are two-column emoji so the columns
   line up: ➡️ next · 🟠 you (waits on the owner) · 🟢 done · 🟡 note ·
   🔴 blocked · 🔵 info · 🟣 juror · 🔗 ref · ⏳ wait. A row's label can
   differ from its role (`--row blocked:slip`).
3. **A blank rail line pads the top and bottom of the rows.** It makes them
   read as a list rather than a paragraph glued to the rules.
4. **The header's right end carries attributes, the bottom rule carries at
   most a short hint.** Duration, model, cost, severity, recency on the
   right. Hints like "say stop to redirect" are cut; a footer earns its place
   only when it labels the copy lines (`📋 ① … ② …`).
5. **Anything to copy prints bare under the box**, after one blank line:
   commands, `/goal` and `/catchup` lines, mute commands, output paths. No
   rail and no rule around them, so a triple-click takes the whole line and
   Ghostty keeps a path clickable. Paths are absolute.
6. **Width 84, about six rows, one box per event.** Past six rows, digest and
   put the file under the box. Repeats of an identical nudge surface once;
   `×N` in the title is only ever a true count (atone recurrence).

## The emitter vocabulary

Canonical source: `~/.claude/scripts/box/vocab.tsv`, read by both renderers;
`box list` prints the live set. Illustration (drifts lose to the tsv):

🪝 hook · ⛔ gate (heavy) · 🛫/🛬 subagent dispatch/landing · 🛫/🛬 fleet
(three or more seats together) · 📥/📤 ipc in/out · 🙏 atone · 🏅 affirm ·
📝 proposal · 📌 pin · 📏 rule · 🏁 done · 🧭 catchup · 💾 core-dump ·
🎯 goal · seal-only ✅ · tag-tier (never boxed): 🌙 dream · 🌡️ ctx ·
📋 kanban · 💡 insight

Admission is deliberate: a new emoji or kind means a vocab.tsv row, a
Ghostty render-check (emoji are double-width and font-dependent; the open
right edge is what makes their width safe), and a note here.

## Who draws which box

| Box | Drawn by |
|---|---|
| 🙏 atone, 🏅 affirm, 📝 proposal, 📌 pin | `python3 ~/.claude/scripts/box/record-box.py <id>`, from the stored record; a `judg-` id draws the juror-cleared atone |
| 🛫/🛬 subagent and fleet | `scripts/hooks/subagent-box.sh`; three or more dispatches within 20 s share one fleet box, priced by `scripts/box/seat-cost.py` |
| 💾 core-dump, 🧭 catchup | the core-dump and catchup skill recipes, through `box.sh` |
| 🎯 goal | `goal.sh box` |

ipc messages stay one-line tags; they do not get boxes.

## Preferred arrows (owner pick, 2026-10-28)

When a box, tag or terminal UI needs a single-width arrow, use one of these four
families, in any direction:

| Family | Right | Left | Up | Down |
|---|---|---|---|---|
| triangle | ▶ U+25B6 | ◀ U+25C0 | ▲ U+25B2 | ▼ U+25BC |
| arrowhead | ➤ U+27A4 | none | none | none |
| angle | ❯ U+276F | ❮ U+276E | none | none |
| guillemet | » U+00BB | « U+00AB | none | none |

Picked from a Fira Code render of 13 candidates. ▸ (U+25B8) was rejected as
too small next to emoji. A single-width arrow still reads smaller than an emoji
in the same row, so a row of emoji markers uses ➡️ instead.

## Body shapes

- **Marked rows** are the default (`--row <role>[:<label>] "<text>"`).
- **Numbered rows** for a set of like items (a fleet's seats): the label is
  the number and the text carries fixed-width columns.
- **Ledger rows** (`--kv "k:v"`) and unmarked `--body` lines still render
  for older callers; prefer marked rows in anything new.
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
  templates (skill-run and user-goal) prescribe the done box: marked rows
  for the stats, the files that matter printed bare under the box, and a
  ➡️ next or 🟠 you row carrying "what needs the reader".
- **Insights are 💡 tags, not ★ boxes.** An insight owes no action, so it
  gets no rails, even under the Explanatory output style's ★ template; the
  house dialect overrides the style's decoration. It is the one sanctioned
  multi-line tag: continuation lines take a hanging indent.

  **Fenced, two to three lines.** The fence is load-bearing, not decoration:
  markdown collapses leading whitespace, so an unfenced tag loses its hanging
  indent and reflows into the surrounding paragraph as an undifferentiated
  block. The length cap is the other half. A tag owes no action, so it must be
  skippable at a glance; past three lines it stops being an aside and starts
  competing with the prose it sits beside. An insight that needs more room is
  prose, not a tag. Both halves learned the hard way, 2026-08-15.

  ```
  💡 insight · the guard was dead because Bash-tool stdin is never a tty;
     gate on the actual input mode, not tty-ness
  ```

## Decisions route to the wizard

A box never grows its own option menu. When an event needs an owner call,
the 🟠 you row says "decision below" and the decision-wizard surface
follows: an inline numbered menu for up to ~3 simple picks, the decision
page on :5106/dp/ for batches. Dialog tools stay banned in the fullscreen TUI.

## Match the shape to the channel, and route around a bad one

A box is only a box on a channel that renders a block. Before composing one,
name where it lands:

| Channel | Renders | Shape |
|---|---|---|
| a reply you write | markdown block | box, fenced |
| hook `systemMessage` | block | box |
| hook `decision:block` `reason` | ONE clipped line | compact single-line string, never a box |
| `additionalContext` | agent-only text | plain, no rails |

The `reason` row is the one that has actually burned us. The harness prints it
as a one-line `Stop hook error:` and clips it, so a multi-line box arrives cut
mid-word with the actionable half (how to fix, how to mute) past the clip. Two
hooks shipped that way and were fixed 2026-08-15: `prose-smell-stop.sh` and
`guard-ai-signature.sh`. Both now emit one compact line.

**When a channel cannot carry what the reader needs, route around it rather
than truncating into it** (owner ruling, 2026-08-15). Write the full detail to
a file and put the path in the compact line, or let the agent surface it in the
reply. An intermediate artifact is a legitimate answer to a hostile output
shape; a clipped box is not.

The same rule governs a tool's own output. `atone.sh` grew `--payload-file`
because nine prose fields passed as inline shell arguments echo verbatim into
the caller's transcript, which turns recording one event into a wall of text.
The fix was moving the payload into a file, not shortening the fields.

## Who renders what

- **Agent-side: render, do not hand-type.** Emoji widths make hand-typed
  alignment drift, so render with `box <kind> <name> --row <role>[:<label>]
  "<text>"… [--attr …] [--foot …] [--copy …] [--ref <abs-path>] [--count N]
  [--seal …] [--block]` and paste the stdout verbatim in a code fence.
  `box list` shows the kinds and roles; `box <kind> --template` prints a
  fill-in skeleton. Records (atone, affirm, proposal, pin) use
  `record-box.py <id>` instead.
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

## The paste line (owner-ratified 2026-08-18)

Some callouts end in something the owner will paste back into the TUI: `/goal <text>`
after a re-arm or a long planning session, a `/wake …`, a `/deadline …`. That line is
NOT part of the box. It sits under the box after one blank line, with no rail
character and no rule around it (the `═══` rules were dropped 2026-10-28), so a
terminal selection of that single line copies clean text. `box.sh --copy` prints it.
The 🎯 `goal` kind
(`scripts/goal/goal.sh box`) is the reference implementation: light rail when the
harness `/goal` is armed, heavy rail as the warning when only the gcc goal holds.

