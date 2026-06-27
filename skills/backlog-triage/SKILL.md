---
name: backlog-triage
description: Review the triaged gcc improvement backlog and act on it. Reads the ranked triage file produced by backlog-consolidate.py (PROMOTE / WATCH / DROP-REVIEW), presents the PROMOTE candidates and the stale DROP-REVIEW items, and drives a human PROMOTE/DROP decision per item — implementing or handing off the promoted ones and rejecting the dropped ones via propose.sh. The one place where backlog items change state.
allowed-tools: Read, Bash, Glob, mcp__inputs__pick_many, mcp__inputs__confirm
argument-hint: "[--refresh]"
user-invokable: true
---

## Brief

The improvement loop captures and ranks on its own (contribution phases file proposals, `gcc-signal-capture` auto-stubs, `backlog-consolidate.py` clusters and gates them weekly). This skill is the **human decision step** — the only thing that moves a backlog item out of "open". It surfaces the triaged PROMOTE candidates and stale DROP-REVIEW items, and for each you decide: act on it now, hand it off, or reject it. Nothing here is automatic; the corroboration gate already filtered out the noise, so this list is short by design.

## Phase 0 — Load the latest triage

The triage file is a derived view; the store is `proposals.jsonl`. Read both the machine sidecar and the human report.

```bash
# Refresh first if asked, or if the sidecar is stale / missing.
[ "$1" = "--refresh" ] && python3 ~/.claude/scripts/backlog-consolidate.py --force
SIDECAR="$HOME/.claude/.backlog-triage-latest.json"
test -s "$SIDECAR" || python3 ~/.claude/scripts/backlog-consolidate.py --force
REPORT=$(python3 -c "import json;print(json.load(open('$SIDECAR'))['report'])" 2>/dev/null)
```

Read the sidecar with a JSON parser (NOT `cat` — a terminal wrapper renders it and corrupts pipes). Use Read on `$REPORT` for the full ranked detail (titles, corroboration, links, ids per bucket).

## Phase 1 — Present the decision set

Show, in order:

1. **PROMOTE candidates** — each with title, `value`, `corroboration`, linked residue, and proposal `ids`. These cleared the anti-churn gate (corroboration ≥ 2, or atone S3, or recurrence ≥ 3, or a human contribution ≤ medium effort).
2. **DROP-REVIEW** — items open > 45 days with no corroboration. Candidates to reject and clear.

If PROMOTE is empty, say so plainly (the gate promoted nothing — that is the normal, correct state when corroboration has not accrued) and offer to show the WATCH list or the stale DROP-REVIEW items. Do not invent work.

## Phase 2 — Decide per item

Use `mcp__inputs__pick_many` to let the user select, from the PROMOTE set, which to **act on now** vs **defer** (leave open). Then, separately, present DROP-REVIEW for **reject** selection. For an ambiguous single high-stakes item, use `mcp__inputs__confirm` instead.

## Phase 3 — Apply (the only state change)

For each decision, mutate the canonical store — never edit `proposals.jsonl` by hand:

```bash
# Rejected (dropped): record the reason so the audit trail explains the close.
bash ~/.claude/scripts/propose.sh reject <id> "<why dropped>"

# Promoted AND implemented this session: close it.
bash ~/.claude/scripts/propose.sh done <id>
```

For a promoted item that is **small** and in scope, implement it now (follow the normal plan → change → verify discipline), then mark it `done`. For a **larger** item, do NOT implement inline — leave it `open`, and create a Task (TaskCreate) or a short plan so it is picked up deliberately in a focused session. Promotion is a decision to act, not a license to sprawl (scope-as-ceiling).

A promoted item carries a suggested target in its category (`hooks` → a hook, `skills` → a skill, `rules`/`config` → CLAUDE.md or a rule). Use it as the routing hint.

## Phase 4 — Confirm

Print a one-line summary: how many promoted-and-done, promoted-and-deferred (with their new Tasks), and rejected. Re-running `backlog-consolidate.py --force` after a triage pass refreshes the file so the closed items drop off.

## Notes

- **The gate already did the filtering.** If this list feels long, the corroboration bar may be too low — that is a `backlog-consolidate.py` tuning question, not a reason to rush decisions here.
- **Never auto-apply.** Even a PROMOTE candidate is a human call. The skill mutates status only on explicit selection.
- **Cross-links are evidence.** An item's `links:` (atone slug, dream id, other proposals) show why it surfaced — read them before deciding, especially for atone-S3-linked items (a serious mistake pattern wants a real fix).
