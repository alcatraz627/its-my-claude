# The goal that would not stay armed
kicker: gcc-work-78 · 2026-08-18
sub: what /goal is, why it died on every /clear, and what now keeps it alive
> notes: Open with the pain: the owner re-typed the goal on every resume. Then the mechanism.

## The problem
sub: one claim, one slide
`/goal <text>` is a Claude Code built-in. It installs a session-scoped Stop hook and lives in memory only.
:::callout warn It dies on /clear, nothing writes it to disk, and no tool lets an agent run it.
> notes: Say the three facts slowly. Each one is verified from transcripts, not recalled.

## How it shows up in the transcript
kicker: evidence
| shape | where | since |
|---|---|---|
| command block | `<command-name>/goal</command-name>` | day one |
| Stop-hook injection | "session-scoped Stop hook is now active" | day one |
| mid-turn queue-operation | `Goal set: …` enqueue | found by gcp-fable |
| local-command stdout | `Goal set: …` / `Goal cleared` | today |
> notes: The third row is the one the first parser missed. A peer found it within hours.

## Two sources, kept apart
:::cards
harness
- what /goal is actually armed right now
- read from the transcript, mechanically
- only the owner changes it, only in the TUI
---
gcc
- a file the agent may write: ~/.claude/goals/<sid>.json
- what /catchup re-arms into after /clear
- carries no Stop-hook force; it is memory
:::

## The numbers
:::stat 588 | "Stop hook is now active" injections across all transcripts
:::open ~/.claude/scripts/goal/goal.sh | run `goal.sh show` for both sources
> notes: The 588 counts every set, boundary and mid-turn. 255 of them left a "Goal set:" line.

## What is verified and what is not
| item | ruling | note |
|---|---|---|
| goal.sh reads all four shapes | holds | 20/20 tests |
| hinter re-injects every 8 prompts | holds | 7/7 |
| harness auto-clear is detectable | no | no transcript marker exists |
| paste line copies clean | caveat | verified in Ghostty only |

## The flow
```text
/goal set ──▶ transcript ──▶ goal.sh harness ──▶ core-dump: Live commitments + Re-arm block
                                   │
                          catchup: goal.sh set ──▶ goals/<sid>.json ──▶ 37-goal-standing hinter
```

## Voices
:::callout quote
No one armed a /goal this time.
-- the owner, 2026-08-18
:::
:::callout tip The paste line lives OUTSIDE the box: a rail character in the selection breaks copy.
:::callout note Neutral note, hairline only.
:::callout aside An aside, dim and small.
:::callout term
Re-arm
Writing the goal into the gcc store and printing the paste line; never re-authorising anything.
:::

## Status callouts
:::callout ok The observation window is armed: 21:00, 23:30, 09:00.
:::callout bad Auto-clear on completion leaves no marker.
:::callout info Peers were told; three replied within the hour.
:::callout stat 4 | transcript shapes a /goal can arrive in

## The ask
1. Rule on #81: skeleton advisory (ruled: yes)
2. Baseline the reviewer on the three peer decks (ruled: yes)
3. Use it for a month, then judge
:::open ~/.claude/assets/reports/20260818-deck-spec/spec.md | the spec, v2
> notes: Close on the month-long usage window. No promises about what changes after it.

leave: One line the room takes home.
