---
name: skeptical-review
description: Independently reviews changed code or documents with a fresh Codex agent that reads surrounding context, callers, sibling conventions, existing alternatives, tests, and owner guidance. Use for ordinary post-change review or when asked whether work is right. Produces grounded findings and never edits the reviewed work.
---

# Skeptical review

Use a fresh agent because an author reviewing its own reasoning tends to defend it. The reviewer receives the artifact, goal, and evidence, without the author's proposed findings.

## Procedure

1. Read `/Users/alcatraz627/.claude/skills/GUIDELINES.md` and any relevant full rule files from the rule index.
2. Resolve the review scope from the user's named files, the current diff, and the session handback. Record the goal and acceptance criteria separately from implementation claims.
3. Run cheap deterministic checks that fit the artifact. Do not call a static check runtime proof.
4. Create a timestamped output path under `<project>/.claude/output/<timestamp>-skeptical-review/`; never use the filename `report.md`.
5. Dispatch one fresh reviewer. Pin the model explicitly, forbid nested agents, tell it to ignore task or board auto-dispatch, require it to write the full report to the absolute output path, and tell it to stop once that scoped report is written. The parent verifies the file exists before using it.
6. Present all findings ranked by severity and confidence. Keep the review read-only. Record later dispositions as fixed, deferred by owner, or rejected with a reason.

## Reviewer contract

Assume the artifact is wrong until the surrounding tree proves otherwise. Read every cited location. Report findings at 40 percent confidence or higher, including lower-severity items; ranking supplies focus. Every finding must cite an absolute `file:line` or a directly executed check.

Check, where relevant:

- the user's original request and standing guidance against the delivered behavior;
- complete surrounding functions or sections, not isolated hunks;
- every caller, importer, reader, or downstream consumer of changed symbols and claims;
- sibling conventions and existing implementations that may make the change inconsistent or redundant;
- both overbuilding and underbuilding against the goal, scope, stated intent, and total cost;
- guards and tests by watching a meaningful negative case fail;
- comments and prose for reader cost, stale claims, and missing caveats;
- verification boundaries, especially claims derived from compilation, lint, collection, or source reading alone.

Use this table:

`| rank | confidence | severity | evidence | file:line | failed check | finding | how to verify |`

Include a short section for attacks that did not produce a finding.

## Boundaries

- The reviewer writes only its report. It does not edit reviewed files, commit, push, deploy, send messages, or mutate live state.
- For an executable probe, use a safe existing test or a copy under `/tmp`.
- A clean review says what was inspected and what was not; it is not a general correctness certificate.
