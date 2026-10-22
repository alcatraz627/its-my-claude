# How the weekly reader names what it found

You are reading clusters a deterministic join found across the owner's local signals:
recorded mistakes (atone), affirmed good behaviour (affirm), session pins, gcc
improvement proposals, core-dumps with unfinished items, corrections the owner typed,
hook telemetry and skill use. Each cluster lists its evidence as
`id | domain | provenance | date | project | excerpt`.

For each cluster, decide what it is:
- repeat: the same lesson keeps coming back from independent places.
- structural-need: the evidence says a hook, gate, skill fix, rule reshape or tool
  default is missing. Text reminders have already failed for these; name the
  structural change.
- drift: something is getting worse week over week.
- noise: the join matched on something incidental. Saying so is useful.

The answer's fields and its JSON shape are given after the clusters, in the prompt
itself; follow that schema. The owner-facing fields are written for the person Claude
worked for. `why` is one sentence for the backlog that cites what the evidence shows.
Cite only evidence ids listed under that cluster (or a cluster you merge).
Where a change would help, draft one: `target` is the file, hook id, rule or mute file
it touches, and `change` is one sentence. Do not propose more text injected into
sessions; that lever has been measured and does not move these counts.

If this process itself is missing something you needed, say so in `process_note`;
it is appended to this file and read next week.

## Amendments
- 2026w41 (2026-10-06) CORRECTED 2026-10-13, the premise was false: all four hooks named here have been registered in settings.json since September; the batch now lists registered hooks. Original note: Four stop hooks (declared-ready-stop.sh, named-next-work-stop.sh, dense-briefing-shapes-stop.sh, prose-smell-stop.sh) appear on disk with tests but are absent from settings.json. The weekly reader would be more useful if it diffed the hooks/ directory against the registered Stop/PostToolUse entries in settings.json and surfaced the gap directly as a 'unregistered gate' cluster type — this would have caught all four in one structural row rather than requiring per-cluster grepping.
- 2026w41 (2026-10-06): Three drift clusters (c-64a3694c, c-2eebc431, c-fefb32b0) all show 0/0 heeded with rising fire counts. The 'heeded' denominator is always zero, which is either correct (no tracked heeded events exist) or a sign the heeded-tracking write never runs. The reader would be more useful next week if it could distinguish 'heeded path broken' from 'fires genuinely ignored'; a diagnostic that checks whether the heeded-log writer has ever produced an entry for each hook id would surface this gap directly.
- 2026w42 (2026-10-13, from a dry run): Three of the four highest-count repeats (named-next-work 7, declared-ready 7, dense-briefing 6) all have registered stop hooks. The reader cannot distinguish 'hook exits 1 and pattern persists' from 'hook exits 0 advisory' from 'hook fires but was registered after the session that produced the events'. Adding one diagnostic column next week would resolve this: for each hook id in a repeat cluster, emit the count of exit-1 fires vs exit-0 fires in the last 14 days from hook telemetry. That single column would tell the reader whether to diagnose the hook logic (fires but pattern persists) or the registration state (never fires at all), and would have resolved c-0d4db80b instantly by showing the mute file's effect.
- 2026w42 (2026-10-13): The 2026w41 amendment requested exit-1 vs exit-0 counts per hook. The current data separates block from soft/nudge, which partially satisfies this, but 'soft' conflates exit-0-advisory with exit-0-muted-by-file. Adding a third column (muted) would let the reader distinguish a hook whose logic is wrong (fires exit-0 when it should exit-1) from one the owner deliberately muted — this would have resolved c-0d4db80b's 'declared-ready blocks 23 but pattern persists 7' question directly, because it would show how many of the 41 soft fires were muted vs genuinely advisory.
- 2026w43 (2026-10-21): Nine session-cluster entries this week (c-cb2aacd9 and the eight merged into it) carry no atone row with a named mistake slug — only correction signals and pending items. The reader would be more useful next week if session-cluster joins required at least one atone row with a non-null mistake type to qualify for inclusion; without it the reader cannot tell whether the correction was a real mistake or a preference change, and the cluster adds noise to the output.
