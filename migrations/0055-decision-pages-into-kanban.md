---
migration: 0055
title: Decision pages served by kanban; the :5197 server retired
session: gcc-kanban e1759fbe@2026-08-25
status: complete
date: 2026-08-25
---

# Migration 0055: decision pages into kanban, :5197 retired

## Why

Owner directive 2026-08-25: fold decision pages into kanban visually, server
wise and beyond, then retire the standalone server. Full examination, defect
catalog and parity proof: scripts/kanban/DECISION-PAGES-ADOPTION.md.

## What moved

- Serving: every page renders at `http://localhost:5106/dp/<slug>/` from ONE
  dynamic charter template (scripts/kanban/decision.html). Per-page
  index.html copies are no longer written by `new`.
- Submit: `POST :5106/api/dp-submit/<slug>`, byte-compatible with the old
  `/_submit/<slug>` (same .answer.json shape, pending clear, ipc notify).
- Hub: the kanban Decisions view (`:5106/?view=decisions`), pending first.
- pm2 app `decision-pages` deleted; the 5197 T2 port claim freed.

## What did NOT move

The registry (`assets/decision-pages/<slug>/config.json` + images), the
`.pending.txt` ledger (statusline chip unchanged), `.answer.json` watching,
`decision-page.sh` verbs and the wizard flow, the answer-string format.

## Repointed surfaces (a naive invocation lands correctly)

scripts/decision-page/decision-page.sh (server-ensure now targets kanban,
all URLs), scripts/decision-page/wizard.sh (submit endpoint),
skills/decision-wizard/SKILL.md, skills/kanban/SKILL.md,
features/decision-pages.md, CLAUDE.md feature row,
rules/owner-decisions-go-through-a-wizard.md, conventions/callout-boxes.md,
skills/deadline/SKILL.md.

## Rollback

`pm2 start scripts/decision-page/server.py --name decision-pages
--interpreter python3` (file kept) and revert this commit's repoints. Old
per-page index.html copies still render standalone if re-served.
