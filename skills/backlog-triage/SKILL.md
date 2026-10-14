---
name: backlog-triage
description: Review the triaged gcc improvement backlog (PROMOTE, WATCH, DROP-REVIEW from backlog-consolidate.py) and decide it on one decision page, then apply the promote and reject calls via propose.sh. The one place backlog items change state.
allowed-tools: Read, Write, Bash, Glob
argument-hint: "[--refresh]"
user-invocable: true
---

## Brief

The improvement loop captures and ranks on its own (contribution phases file proposals, `gcc-signal-capture` auto-stubs, `backlog-consolidate.py` clusters and gates them weekly). This skill is the **human decision step**, the only thing that moves a backlog item out of "open". It surfaces the triaged PROMOTE candidates and stale DROP-REVIEW items, and for each you decide: act on it now, hand it off, or reject it. Nothing here is automatic; the corroboration gate already filtered out the noise, so this list is short by design.

## Phase 0: Load the latest triage

The triage file is a derived view; the store is `proposals.jsonl`. One command per Bash call, no chaining.

1. If the argument was `--refresh`, run `python3 ~/.claude/scripts/backlog-consolidate.py --force`.
2. Check the sidecar exists and is non-empty: `test -s ~/.claude/.backlog-triage-latest.json`. If that exits non-zero, run the same `--force` command from step 1.
3. Read `~/.claude/.backlog-triage-latest.json` with the Read tool (never `cat`: a terminal wrapper renders it and corrupts it). Its `report` field is the path of the human report.
4. Read that report path with the Read tool for the full ranked detail (titles, corroboration, links, ids per bucket).

## Phase 1: Present the decision set

Show, in order:

1. **PROMOTE candidates**: each with title, `value`, `corroboration`, linked residue, and proposal `ids`. These cleared the anti-churn gate (corroboration ≥ 2, or atone S3, or recurrence ≥ 3).
2. **DROP-REVIEW**: items open > 45 days with no corroboration. Candidates to reject and clear.

If PROMOTE is empty, say so plainly (the gate promoted nothing, which is the normal, correct state when corroboration has not accrued) and offer to show the WATCH list or the stale DROP-REVIEW items. Do not invent work.

## Phase 2: Decide, on ONE decision page

The whole decision set goes on a single page through `/decision-wizard` (Path B), never one prompt per item and never a separate pass for DROP-REVIEW. Owner rulings: a decision set is one page (`rules/owner-decisions-go-through-a-wizard.md`).

- One `sections[]` card per PROMOTE candidate and per DROP-REVIEW item, grouped as `PROMOTE` and `DROP-REVIEW`. Each card carries your read (title, value, corroboration, links) and a drafted answer.
- Options per PROMOTE card: act now, leave open. Options per DROP-REVIEW card: reject, keep. Exactly one `rec` each; default the ones you hold a confident pick for, and say so in the page intro.
- If the set is three or fewer simple picks, `/decision-wizard` Path A (the inline numbered menu) is enough. A single high-stakes item is one sentence in chat.

Apply the returned answer string in Phase 3. An empty PROMOTE and DROP-REVIEW set needs no page.

## Phase 3: Apply (the only state change)

For each decision, mutate the canonical store. Never edit `proposals.jsonl` by hand:

```bash
# Rejected (dropped): record the reason so the audit trail explains the close.
bash ~/.claude/scripts/propose.sh reject <id> "<why dropped>"

# Promoted AND implemented this session: close it.
bash ~/.claude/scripts/propose.sh done <id>
```

For a promoted item that is **small** and in scope, implement it now (follow the normal plan → change → verify discipline), then mark it `done`. For a **larger** item, do NOT implement inline: leave it `open` in the store, where the next triage run resurfaces it, and name it in the Phase 4 summary. Do not park it in TaskCreate: the owner reads the goal record, not the session task list (`rules/todo-discipline.md`). If the owner wants it driven, offer `gs new` (it files a goal and prints the `/goal` line for them to paste; it never arms it). Promotion is a decision to act, not a license to sprawl (scope-as-ceiling).

A promoted item carries a suggested target in its category (`hooks` → a hook, `skills` → a skill, `rules`/`config` → CLAUDE.md or a rule). Use it as the routing hint.

## Phase 4: Confirm

Print a one-line summary: how many promoted-and-done, promoted-and-deferred (ids left open), and rejected. Re-running `backlog-consolidate.py --force` after a triage pass refreshes the file so the closed items drop off.

## Notes

- **The gate already did the filtering.** If this list feels long, the corroboration bar may be too low. That is a `backlog-consolidate.py` tuning question, not a reason to rush decisions here.
- **Never auto-apply.** Even a PROMOTE candidate is a human call. The skill mutates status only on explicit selection.
- **Cross-links are evidence.** An item's `links:` (atone slug, dream id, other proposals) show why it surfaced. Read them before deciding, especially for atone-S3-linked items (a serious mistake pattern wants a real fix).
