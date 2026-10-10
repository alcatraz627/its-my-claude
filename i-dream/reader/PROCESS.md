# How the weekly reader names what it found

You are reading clusters a deterministic join found across the owner's local signals:
recorded mistakes (atone), affirmed good behaviour (affirm), session pins, gcc
improvement proposals, core-dumps with unfinished items, corrections the owner typed,
hook telemetry and skill use. Each cluster lists its evidence as
`id | domain | provenance | date | excerpt`.

For each cluster, decide what it is:
- repeat: the same lesson keeps coming back from independent places.
- structural-need: the evidence says a hook, gate, skill fix, rule reshape or tool
  default is missing. Text reminders have already failed for these; name the
  structural change.
- drift: something is getting worse week over week.
- noise: the join matched on something incidental. Saying so is useful.

Give each a title the owner would recognise in five words or so, and a one-sentence why
that cites what the evidence shows. Cite only evidence ids listed under that cluster.
Where a change would help, draft one: `target` is the file, hook id, rule or mute file
it touches, and `change` is one sentence. Do not propose more text injected into
sessions; that lever has been measured and does not move these counts.

If this process itself is missing something you needed, say so in `process_note`;
it is appended to this file and read next week.

Answer with JSON only:
{"items": [{"cluster": "c-…", "kind": "repeat", "title": "…", "why": "…",
  "evidence_ids": ["atone:…"], "proposal": {"target": "…", "change": "…"}}],
 "process_note": null}

## Amendments
- 2026w41 (2026-10-06): Four stop hooks (declared-ready-stop.sh, named-next-work-stop.sh, dense-briefing-shapes-stop.sh, prose-smell-stop.sh) appear on disk with tests but are absent from settings.json. The weekly reader would be more useful if it diffed the hooks/ directory against the registered Stop/PostToolUse entries in settings.json and surfaced the gap directly as a 'unregistered gate' cluster type — this would have caught all four in one structural row rather than requiring per-cluster grepping.
- 2026w41 (2026-10-06): Three drift clusters (c-64a3694c, c-2eebc431, c-fefb32b0) all show 0/0 heeded with rising fire counts. The 'heeded' denominator is always zero, which is either correct (no tracked heeded events exist) or a sign the heeded-tracking write never runs. The reader would be more useful next week if it could distinguish 'heeded path broken' from 'fires genuinely ignored'; a diagnostic that checks whether the heeded-log writer has ever produced an entry for each hook id would surface this gap directly.
