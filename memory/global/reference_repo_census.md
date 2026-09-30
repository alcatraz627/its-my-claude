---
name: reference-repo-census
description: Dated census of every versable-git and alcatraz627 repo (category, usage, evidence); reuse before surveying the owner's repos
metadata:
  type: reference
---

A classified inventory of the owner's repos lives at `~/.claude/assets/reports/20260930-repo-census/` (README.md is the index). It covers the versable-git org (47 repos) and the alcatraz627 account (90 repos), each tagged product / client build / platform-internal service / internal tool / personal tool / MVP-POC / dormant / archived, with a usage level and the commit, author and deploy evidence behind it. Evidence is dated 2026-09-30.

**Why:** the owner asked (2026-09-30) that this homework be kept so the next agent looking through their repos, versable or personal, can reuse it instead of re-deriving it.

**How to apply:** read it first for any task that surveys, picks from or describes the owner's repos. Check the date; if it is more than about two weeks old or the task hinges on current activity, re-run `gather.py <owner>` from that folder and write a new dated folder rather than editing the old one. Borderline calls are listed under "Judgment calls" in each `.md`.
