# 0044: chat prose-smell gate promoted to enforce; JSON string copy gated

## Summary

Two stringency moves on the language-gate stack, both requested by the owner
("more stringent anti-slop, every aspect of output", 2026-08-08). First, the
chat-reply Stop hook (prose-smell-stop.sh) is promoted from measure-first
dry-run to a real block: `PROSE_SMELL_ENFORCE=1` now lives in the
settings.json `env` block, so every session enforces it. The block condition
is unchanged (two or more block-tier tells co-occurring; loop-safe; single
tells stay visible notes). Second, guard-prose-quality routes user-facing-copy
`.json` classes (decision-page paths, locale/i18n/lang dirs, *strings.json,
*copy.json) through code-copy-lint, closing the coverage map's last named gap.
The first cut gated ALL .json; the validation gate proved that blocks
mcp-catalog.json edits that add-mcp itself mandates and create-report's
data.json cache, so the scope was narrowed to the copy classes. Other .json
stays ungated by choice. `.jsonl` ledgers stay exempt, as do the existing
test/fixture and style-system path exclusions. code-copy-lint's string cap was
raised 300 to 2000 chars in the same pass; an over-cap literal evaded
silently, and real decision-page copy exceeds 300.

## Why

The 2026-07-10 review (assets/reports/20260710-queue-reviews/1.5a-prose-smell.md)
made promotion conditional on fire-rate telemetry. 29 days of dry-run recorded
57 would-blocks (about 2 per day) and 104 single-tell nudges, with no
false-fire complaints in the ledger. The JSON gap was the smallest surviving
surface in the mig 0042 coverage map. Recount at ship time: 57 would-blocks,
106 single-tell nudges.

## Behavior notes

- Enforce path exercised synthetically: a two-tell transcript produced a real
  `decision:block` on first fire and the loop-safe step-aside note on the
  identical retry.
- JSON routing exercised: dash+jargon copy in a probe .json blocked; clean
  config values, command paths, env strings, and classNames stayed silent;
  a `.jsonl` write stayed exempt.
- Chat replies rendered under the Explanatory output style keep their ★ boxes
  (warn-tier by design, never counted toward the block threshold).

## Rollback

Remove `PROSE_SMELL_ENFORCE` from settings.json env (reverts chat to dry-run
telemetry mode), and drop the `*.json)` case line from
guard-prose-quality.sh. Mute files are unchanged:
`~/.claude/.no-prose-smell-gate` and `~/.claude/.no-prose-quality-gate`
mute machine-wide without unregistering.
