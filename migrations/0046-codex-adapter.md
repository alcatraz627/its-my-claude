# 0046: codex adapter, and `adapters/` as a new top level

**Date:** 2026-08-14
**Type:** structural (new top-level directory)
**Sessions:** codex-setup-95

## What changed

New top-level directory `~/.claude/adapters/`, holding the per-foreign-agent
translation layer. First and only occupant is `adapters/codex/`.

```
adapters/codex/preamble.md                   hand-authored working agreement
adapters/codex/checkpoint-register.sh        writes a Codex handback pointer into ~/.claude/checkpoints/
adapters/codex/hooks/guard-destructive.sh    WITHDRAWN gate, kept as the worked example behind the verdict
scripts/export-agents-md.sh                  generator: preamble + rules/00-index.md -> $CODEX_HOME/AGENTS.md
features/codex-adapter.md                    tier 2 doc
```

`checkpoint-register.sh` writes into the existing `~/.claude/checkpoints/` index
with `kind: "codex"`, alongside the `core-dump` and `precompact` kinds already
there. No new ledger, no new schema: a Codex handback is a checkpoint, and the
`kind` field is what lets a reader tell it was produced by an agent running
without a WAL, atone, or hooks.

Outside the gcc, two files in `$CODEX_HOME` (`~/.codex`):
`AGENTS.md` (generated, never hand-edited) and `hooks.json` (registers the guard).

## Why `adapters/` rather than an existing directory

`features/` documents how this config's own subsystems work. `conventions/`
governs output shape. Neither owns source material compiled for a different
runtime, which is what `preamble.md` is. Claude Code never reads it. Only the
generator does.

Per `PLACEMENT.md`, a new top-level directory needs a reason an existing one
cannot absorb. The reason is audience. Everything under `adapters/<x>/` is
written for `<x>` to read rather than for Claude, and that distinction holds for
any future adapter.

## Reader impact

None for existing Claude Code sessions. Nothing in `adapters/` autoloads, nothing
references it from an always-on path, and `features/codex-adapter.md` is tier 2
(pointer only). The always-on budget is unchanged.

## Rollback

Remove `adapters/`, `scripts/export-agents-md.sh`, `features/codex-adapter.md`,
and this entry. In `$CODEX_HOME`, remove `AGENTS.md` and `hooks.json`. No other
file references them, so nothing else breaks.

## Follow-ups deliberately not done

- **Sync is manual.** `export-agents-md.sh` runs by hand after the preamble or
  the rule index changes. A PostToolUse trigger on `rules/` writes would automate
  it. Deferred because staleness degrades gracefully and unprompted automation
  needs its own decision.
- **Only one hook ported.** Codex supports 11 of this config's 13 hook lanes,
  including `stop`, so `declared-ready-stop.sh` and the structural-claim guards
  could follow. Deferred pending evidence that Codex gets used often enough to
  earn the porting cost.
- **No atone write path.** Recorded as known blindness in the feature doc. Not a
  gap to close.
