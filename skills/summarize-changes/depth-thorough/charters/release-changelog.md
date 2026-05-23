---
name: release-changelog
description: Verifier charter for release-scale diffs (100+ commits, 500+ files)
---

# Verifier charter — release-changelog

Apply these 5 failure modes as independent audit passes:

## FM-1: Coverage gaps in under-reported chunks

For chunks marked under-reported in `_coverage.json`, cross-check chunks.json's file list against themes' file references. Identify dropped files; for structurally important ones (route, schema, public API), read the diff slice and propose a theme. Cap: 5 missing-theme candidates.

## FM-2: Theme-type miscategorization

Each theme must be exactly one of: feature / improvement / fix / perf / infra / breaking. Common bleed:
- "feature" that refactors existing capability → should be "improvement"
- "improvement" that breaks a contract → should also be "breaking"
- "fix" adding capability beyond repair → should be "feature"

Report ≤8 highest-confidence miscategorizations: `<theme>: <current> → <suggested> · reason`.

## FM-3: Missing breaking changes

Scan inventory for breaking-class changes any theme missed:
- Prop signature changes
- Removed exports
- Renamed env vars
- Schema migrations
- Deleted routes/endpoints
- Deleted API methods

Report ≤5 missing-breaking candidates.

## FM-4: Issue confidence calibration

For each DEFINITELY: can you confirm from inventory + a quick diff read?
- If evidence is weak, downgrade to MAYBE.
- If MAYBE can be graduated/removed with a 1-min check, do it.
- If TO-CHECK is actually answerable from code (not ops), reclassify.

Report `<ISS-id>: <current> → <suggested> · reason`.

## FM-5: SHA hygiene + summary accuracy

V2 themes often cite "(...)" or fabricate SHAs not in commits.tsv. For 5 themes spot-check:
- Grep commits.tsv subjects for keywords matching theme name
- List actual SHAs touching theme's representative files (where determinable)

Report 5 themes with concrete SHA-list replacements OR explicit "(post-cutoff)" annotation.

Spot-check 5 random theme `Summary` fields against inventory. Flag any summary that materially misrepresents what shipped (not nits — material).

## Overall verdict

green | yellow | red. Single biggest risk. Ready for render?
