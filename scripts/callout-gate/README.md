# callout-gate — the owner's own sentences, as checks that fail by themselves

Parked sketch, not wired into anything. Owner ruling 2026-09-01: "keep it as
something to reuse later".

## What it is

`callout-gate.mjs` reads a project's `.claude/callouts.jsonl` (the ledger of
review findings the owner has raised) and runs the subset of those findings a
DOM can settle, against a live page. It does not judge whether a surface is
good. It judges whether the specific things he already objected to have come
back, which is the one question a script can answer honestly about work it did
not do.

## Why it is here rather than in the project

Two reasons, and the second is the one worth remembering.

It came from a reading of a task the owner overturned: that row asked for an
independent audit by a lane that did not build the panel, and a script is not
that. So it should not sit in a project's `scripts/` where it reads as part of
the gate chain.

And `versable-forge-v6/.gitignore:17` ignores `.claude/`, so parking it in the
project's own `.claude/` would have made it a laptop-only file. That is the
orphan shape this estate keeps rediscovering. Here it is version controlled.

## Status

Never run. Syntax-checked only. Treat every claim in it as unverified until
someone points it at a live page and watches a known-bad case fail.

## The idea worth reusing

The ledger holds the owner's words plus a prose `check`. Most of those checks
are prose because they need eyes. Some are not, and those can be made to fail
on their own rather than waiting for him to notice the same thing twice. That
split, prose-check versus machine-check, is the reusable part.
