---
brief: The formal, actionable checklist for authoring and reviewing gcc hooks, distilled from the Phase-1/2 hook builds, with the agent-visibility rule that those builds discovered the hard way
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

# Hook authoring and review template

This is the checklist for building a new gcc hook and for auditing an existing one.
Every item is checkable against the script and a live run, so none of it rests on impressions. It is distilled
from the 2026-06-01 Phase-1/2 builds (`guard-env-access`, `guard-subagent-output`,
`guard-comment-hygiene`, the `declared-ready` Stop-hook design), and each line was earned
by a bug those builds hit.

## A. Does the warning reach the AGENT? (the most-missed item, so verify LIVE)

A hook that the model never sees changes nothing. The channel depends on the
event and on whether you are blocking:

| Event | Non-blocking advisory (agent reads it) | Blocking (agent reads + tool stops) |
|-------|----------------------------------------|--------------------------------------|
| **PreToolUse** | stdout JSON: `{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"…"}}` + `exit 0` | stdout JSON: `{"hookSpecificOutput":{…,"permissionDecision":"deny","permissionDecisionReason":"…"}}` (or `exit 2` + stderr) |
| **Stop** | `{"systemMessage":"…"}` + `exit 0` | `{"decision":"block","reason":"…"}` + `exit 0` |

- [ ] **`stderr` + `exit 0` is AGENT-INVISIBLE.** A hook meant to change *agent*
      behavior via `cat >&2 …; exit 0` is broken, so convert it to the table above.
      (The docs claim exit-0 stderr shows in the user transcript, but a live test
      on 2026-06-01 showed it does NOT surface in-UI either. Don't rely on stderr
      for ANY audience.)
- [ ] **Verified LIVE in-session.** Use a real tool call and observe the message
      arrive (for example a `PreToolUse:… hook additional context:` reminder). Stdin
      unit-tests do NOT prove this, because you read the stderr yourself and the agent can't.

## A2. Does it reach the USER? (only via the agent, because no mechanical channel exists)

**No non-blocking hook output reaches the user's transcript mechanically.**
`stderr`, `systemMessage` and `/dev/tty` are all invisible or clobbered by the
TUI alternate-screen buffer (verified live 2026-06-01; see `hooks-tui-limits.md`).
The conversation area belongs to the TUI, and mechanical user-visible channels exist
only OUTSIDE it (macOS notification, statusline, tab title, log file).

So a per-incident nudge reaches the user's transcript ONLY agent-mediated:

- [ ] The advisory hook appends a **`→→ SURFACE …`** directive to its
      `additionalContext`, and `rules/surface-hook-nudges-to-user.md` mandates the
      agent render it as a bordered callout in its reply. This is the hybrid: the hook
      detects (mechanical) and the agent surfaces with context (in-transcript).
- [ ] For *aggregate* visibility ("fired N / heeded M"), log firings to a file
      and surface them in reflect or the widget, and never as a per-fire popup.

## B. Safe to fire: never breaks the tool path, never traps

- [ ] **Fail-safe:** `exit 0` on malformed, empty or missing input, missing `jq`,
      and missing helper files. A hook must never break the tool it gates.
- [ ] **Mute hatch:** an env var (one-shot) AND a touch-file (persistent).
- [ ] **Stop hooks are loop-safe:** block once per trigger-signature (hash to
      `/tmp/…-<sid8>`), then step aside to a non-blocking `systemMessage`. A
      Stop-hook without this can trap the session.
- [ ] **Bias under-fire over over-fire.** Over-firing makes the user mute it, and then the
      *whole* guard layer loses trust (guard dilution). When unsure, stay silent.

## C. No duplication, standardized, no dead-wood

- [ ] **Grep the full `scripts/hooks/` tree for the concern BEFORE building.**
      If a hook already covers it, EXTEND it and don't add a second. (env-access
      generalized warn-raw-process-env rather than duplicating it.)
- [ ] **Matches the house shape:** `#!/usr/bin/env bash`, `set -uo pipefail`, a
      header (code-agnostic purpose, atone-slug provenance, advisory-vs-block,
      mute), a `jq`-guarded input parse, and a tool or file-extension gate.
- [ ] **If it supersedes another hook, retire that one in the same change**
      (unwire from settings.json and remove the script). No unwired dead scripts.
- [ ] **settings.json revalidated** after wiring: `jq empty ~/.claude/settings.json`.
      (A broken settings.json breaks EVERY session.)

## D. Detection precision (the non-happy paths)

- [ ] **Skip-globs tested for OVER-breadth.** `*test*` matches any path
      containing "test" (`mytest-app/`, `latest/`). Use `*.test.*` and `*/tests/*`.
- [ ] **Every target language and case tested.** Don't ship a regex that only
      covers one dialect (the Go `os.Getenv` capital-G miss vs Python `os.getenv`).
- [ ] **Every exclusion justified in a comment** (for example why em-dash is skipped:
      legitimate prose punctuation produced a false-positive flood).
- [ ] **Reuse the single-sourced detector** where one exists (comment-hygiene
      reuses `cleanup-comments/detect.py`), so the definition of "finding"
      doesn't drift.

## E. Structure and clarity

- [ ] The header's first sentence is code-agnostic (what it guards, in human terms).
- [ ] Fuzzy heuristics and dense regex carry a one-line rationale.
- [ ] No plan-ref or [claude@] archeology in the hook's own comments.

## Quick audit procedure (Phase 4 or any existing hook)

1. Read the hook. Classify it: PreToolUse vs Stop, advisory vs blocking.
2. **Section A first.** Grep it for `>&2` and `cat >&2`. If it is advisory and uses stderr, flag
   it AGENT-INVISIBLE (the highest-priority finding).
3. Walk B through E, citing the line for each failing item.
4. For a flagged hook, the fix is usually mechanical (stderr → additionalContext).
   Flag it, and don't auto-fix without approval.

## The process-adherence family

Hooks that enforce "the agent should have followed a documented process" share
one shape: **detect the violation, surface it to the AGENT (per the §A table),
stay loop-safe, and offer a mute**. Members: `sub-agent-output`, `env-access`, the `declared-ready`
Stop-hook, and a future WAL-adherence hook. New process-adherence hooks should reuse
this shape and should not reinvent it.
