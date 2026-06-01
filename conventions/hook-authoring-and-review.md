---
brief: The formal, actionable checklist for authoring + reviewing gcc hooks — distilled from the Phase-1/2 hook builds, with the agent-visibility rule that those builds discovered the hard way
triggers:
  - topic:hook-authoring
  - topic:hook-review
  - phrase:"write a hook"
  - phrase:"review the hook"
  - skill:hookify
related:
  - rules/shell.md
  - features/env-access-convention-hook.md
  - features/declared-ready-stop-hook.md
tier: 2
category: conventions
updated: 2026-06-01
stale_after_days: 365
---

# Hook authoring + review template

The checklist for building a new gcc hook and for auditing an existing one.
Every item is checkable against the script + a live run — no vibes. Distilled
from the 2026-06-01 Phase-1/2 builds (`guard-env-access`, `guard-subagent-output`,
`guard-comment-hygiene`, the `declared-ready` Stop-hook design), each line earned
by a bug those builds hit.

## A. Does the warning reach the AGENT? (the one most-missed — verify LIVE)

A hook that the model never sees changes nothing. The channel depends on the
event + whether you're blocking:

| Event | Non-blocking advisory (agent reads it) | Blocking (agent reads + tool stops) |
|-------|----------------------------------------|--------------------------------------|
| **PreToolUse** | stdout JSON: `{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"…"}}` + `exit 0` | stdout JSON: `{"hookSpecificOutput":{…,"permissionDecision":"deny","permissionDecisionReason":"…"}}` (or `exit 2` + stderr) |
| **Stop** | `{"systemMessage":"…"}` + `exit 0` | `{"decision":"block","reason":"…"}` + `exit 0` |

- [ ] **`stderr` + `exit 0` is AGENT-INVISIBLE.** A hook meant to change *agent*
      behavior via `cat >&2 …; exit 0` is broken — convert to the table above.
      (The docs claim exit-0 stderr shows in the user transcript; a live test
      2026-06-01 showed it does NOT surface in-UI either — don't rely on stderr
      for ANY audience.)
- [ ] **Verified LIVE in-session** — a real tool call, observing the message
      arrive (e.g. a `PreToolUse:… hook additional context:` reminder). Stdin
      unit-tests do NOT prove this (you read the stderr yourself; the agent can't).

## A2. Does it reach the USER? (only via the agent — no mechanical channel)

**No non-blocking hook output reaches the user's transcript mechanically** —
`stderr`, `systemMessage`, and `/dev/tty` are all invisible or clobbered by the
TUI alternate-screen buffer (verified live 2026-06-01; see `hooks-tui-limits.md`).
The conversation area belongs to the TUI; mechanical user-visible channels exist
only OUTSIDE it (macOS notification, statusline, tab title, log file).

So a per-incident nudge reaches the user's transcript ONLY agent-mediated:

- [ ] Advisory hook appends a **`→→ SURFACE …`** directive to its
      `additionalContext`; `rules/surface-hook-nudges-to-user.md` mandates the
      agent render it as a bordered callout in its reply. The hybrid: hook
      detects (mechanical) → agent surfaces with context (in-transcript).
- [ ] For *aggregate* visibility ("fired N / heeded M"), log firings to a file
      and surface in reflect/the widget — never a per-fire popup.

## B. Safe to fire — never breaks the tool path, never traps

- [ ] **Fail-safe:** `exit 0` on malformed/empty/missing input, missing `jq`,
      missing helper files. A hook must never break the tool it gates.
- [ ] **Mute hatch:** an env var (one-shot) AND a touch-file (persistent).
- [ ] **Stop hooks are loop-safe:** block once per trigger-signature (hash to
      `/tmp/…-<sid8>`), then step aside to a non-blocking `systemMessage`. A
      Stop-hook without this can trap the session.
- [ ] **Bias under-fire over over-fire.** Over-firing → the user mutes it → the
      *whole* guard layer loses trust (guard dilution). When unsure, stay silent.

## C. No duplication · standardized · no dead-wood

- [ ] **Grep the full `scripts/hooks/` tree for the concern BEFORE building.**
      If a hook already covers it, EXTEND it — don't add a second. (env-access
      generalized warn-raw-process-env rather than duplicating it.)
- [ ] **Matches the house shape:** `#!/usr/bin/env bash` · `set -uo pipefail` ·
      header (code-agnostic purpose, atone-slug provenance, advisory-vs-block,
      mute) · `jq`-guarded input parse · tool/file-extension gate.
- [ ] **If it supersedes another hook, retire that one in the same change**
      (unwire from settings.json + remove the script). No unwired dead scripts.
- [ ] **settings.json revalidated** after wiring: `jq empty ~/.claude/settings.json`.
      (A broken settings.json breaks EVERY session.)

## D. Detection precision (the non-happy paths)

- [ ] **Skip-globs tested for OVER-breadth.** `*test*` matches any path
      containing "test" (`mytest-app/`, `latest/`). Use `*.test.*`, `*/tests/*`.
- [ ] **Every target language/case tested.** Don't ship a regex that only
      covers one dialect (the Go `os.Getenv` capital-G miss vs Python `os.getenv`).
- [ ] **Every exclusion justified in a comment** (why em-dash is skipped:
      legitimate prose punctuation → false-positive flood).
- [ ] **Reuse the single-sourced detector** where one exists (comment-hygiene
      reuses `cleanup-comments/detect.py`), so the definition of "finding"
      doesn't drift.

## E. Structure + clarity

- [ ] Header's first sentence is code-agnostic (what it guards, in human terms).
- [ ] Fuzzy heuristics / dense regex carry a one-line rationale.
- [ ] No plan-ref / [claude@] archeology in the hook's own comments.

## Quick audit procedure (Phase 4 / any existing hook)

1. Read the hook. Classify: PreToolUse vs Stop; advisory vs blocking.
2. **A first** — grep it for `>&2` / `cat >&2`. If advisory + stderr → flag
   AGENT-INVISIBLE (highest-priority finding).
3. Walk B→E, citing the line for each failing item.
4. For a flagged hook, the fix is usually mechanical (stderr → additionalContext).
   Flag, don't auto-fix without approval.

## The process-adherence family

Hooks that enforce "the agent should have followed a documented process" share
one shape: **detect the violation → surface to the AGENT (per the §A table) →
loop-safe → mute**. Members: `sub-agent-output`, `env-access`, the `declared-ready`
Stop-hook, a future WAL-adherence hook. New process-adherence hooks should reuse
this shape, not reinvent it.
