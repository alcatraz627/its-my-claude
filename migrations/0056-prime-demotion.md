---
migration: 0056
title: 13 always-on rules demoted to on-demand; testing and shell split into core + scoped catalog
session: gcc-audit 0fb48af0@2026-09-01
status: complete
date: 2026-09-01
---

# Migration 0056: the context prime sheds a third of its rule weight

## Why

Owner ruling 2026-09-01, decision page `prime-demotion-0901` (D1a, D2a, all 13
cards agreed). The 46 always-on rules cost ~41.6k tokens per session; the 30-day
survival data (assets/reports/20260901-30day-patterns) shows rule text alone
lands 1/12 while mechanical rungs land 17/17, so rules whose binding moment has
a mechanical prompt moved out of the prime.

## What moved

- **13 rules demoted** via the `api-error-recovery` opt-out shape (a `paths:`
  block with the never-matching sentinel `zz-on-demand--never-autoloads`):
  read-the-comments-on-a-pr-you-raised · pr-nobot-noslack-codex-review ·
  github-agent-marker · ambiguous-file-action-halt · right-sized-code ·
  rename-without-grepping-readers · size-the-change-in-the-target-vocabulary ·
  audit-file-character-before-applying-global-rule ·
  speculative-abstractions-without-a-load-bearing-caller ·
  helper-return-type-assumption · trusted-linter-reminder · corrections ·
  surface-hook-nudges-to-user. Each keeps its one-line gist in rules/00-index.md.
- **rules/testing.md split**: the 17-tag pattern catalog now lives in
  `rules/testing-patterns.md` (scoped to test-file paths). Corpus `§ [tag]`
  readers updated (exercise-based-verification, rename-without-grepping-readers,
  machine-token, browser-mcp-async-eval, skills probe + skeptical-review).
- **rules/shell.md split**: macOS gotchas, dedicated-tools table, rg cheatsheet,
  prefer-existing-scripts now live in `rules/shell-reference.md` (scoped to
  *.sh/*.bash/*.zsh). The rg mandate and safety law stay always-on.
- Owner note rulings integrated into read-the-comments: a failed review is
  flagged with its why and work continues; the review = a comment; no review +
  no action running = rule not applicable; versable-git projects always reply
  via /claude-bot.

## Numbers

46 rules / 30,783 words before → 33 rules / 20,538 words after
(~13.8k tokens saved, measured by wc -w × 1.35).

## Revert

Delete the `paths:` block from any demoted rule; re-join the split files from
git history; re-run `scripts/rules-index.sh`.

## Companion mechanical prompts (proposed, not built)

Three backlog proposals (src:prime-demotion): pr-create nudge, trusted-linter
hinter, SURFACE-suffix annotation for older hooks.
