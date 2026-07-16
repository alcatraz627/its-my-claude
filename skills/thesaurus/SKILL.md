---
name: thesaurus
description: >
  Ten-second capture of a style verdict into the style thesaurus — the ledger of
  how the user wants Claude to write (word choice, comments, prose, report
  structure). One-liner in, classified JSONL entry out, digests regenerated.
  Also runs the weekly review (prune/promote) and digest rebuild. The glossary
  holds the meanings of the USER's words; the thesaurus holds the user's
  verdicts on CLAUDE's words.
user-invokable: true
argument-hint: "<one-line verdict> | review | digest | list"
---

## Brief

Everything routes through `~/.claude/scripts/style/thesaurus.sh` — never
hand-compose JSONL. Consumers (the readers-advocate critic persona, the
style-watch stack) read the capped digests under `~/.claude/style/derived/`,
never the raw ledger, so accumulated entries cannot drown a model's context.

## Dispatch on the argument

- `review` → run `bash ~/.claude/scripts/style/thesaurus.sh review`, present the
  four blocks (counts, top-enforced, prune candidates, agent candidates), and
  collect the user's promote/prune verdicts. Apply them by rewriting the
  affected entries' `status` (via jq on the ledger, under
  `skills/shared/lock-file.sh`), then regenerate digests. This is part of the
  user's existing weekly audit ritual — no cron of its own.
- `digest` → run `... digest`, report which class files were rewritten.
- `list` → run `... list`, show as-is.
- anything else → **capture mode** (the default, below).

## Capture mode

1. Read the one-liner (e.g. "never say 'leverage', use 'use'" or "stop opening
   summaries with restated headers").
2. Classify: `--class` vocab | comment | prose | structure · `--verdict` ban |
   prefer | rewrite-to · `--scope` all | report | docs | comment | chat.
   Extract `--rewrite` when the user named a replacement, `--example` when they
   quoted an offense.
3. Dedupe: `thesaurus.sh list` and check for an existing entry covering the
   same pattern — if one exists, tell the user and stop (or update that entry's
   pattern if theirs is broader). Never add a near-duplicate.
4. Echo the composed entry in one line for a quick eyeball, then append:
   `bash ~/.claude/scripts/style/thesaurus.sh add --pattern "..." --verdict ... [flags]`
   (user captures default `--source user --status active`).
5. Regenerate digests (`thesaurus.sh digest`) and confirm: id, class, digest
   file touched. Done — the whole flow should take seconds, not a conversation.

## Rules for agents (not just this skill)

- A critic/watcher/review agent that notices a recurring style pattern files it
  with `--source critic|watcher` — the CLI forces those to `status=candidate`.
  Candidates bind nothing until the user promotes them at `review`.
- Enforcement telemetry: when a consumer flags a violation of entry X, it calls
  `thesaurus.sh hit <id>` — hit counts drive the weekly keep/prune triage.

## See Also

- `~/.claude/style/scope-map.json` — which artifacts get how much enforcement
- `~/.claude/GLOSSARY.md` §User Shorthand — the sibling ledger (user's words)
- `~/.claude/hinters/01-glossary.sh` — per-prompt activation of shorthand terms
- `~/.claude/migrations/0033-style-thesaurus-subsystem.md` — provenance
