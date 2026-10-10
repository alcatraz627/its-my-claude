---
name: adversarial-review
description: Prosecutes work already presented as complete by giving a fresh Codex agent a claims ledger, owner-value dossier, and permission to execute safe hostile probes. Use when asked for an adversarial review, to tear work apart, or before relying on a high-stakes done claim. Produces an evidence-tagged indictment or an honest held-under-attack verdict; never edits the reviewed work.
---

# Adversarial review

This is the prosecution lane. It tries to prove that the author's completion verdict is false. A fresh agent attacks skipped paths, narrowed requirements, unsupported structural claims, and accepted surfaces that were never exercised. It wins by finding consequential defects and loses by padding.

## Procedure

1. Read `/Users/alcatraz627/.claude/skills/GUIDELINES.md`, `/Users/alcatraz627/.claude/mistake-patterns.md`, relevant owner guidance, the project's goal documents, and any applicable full rule files.
2. Build a claims ledger: `claim | evidence actually produced | gap`. Include every statement such as done, works, safe, complete, passing, parity, or verified. Treat compilation, lint, source reading, and API existence as limited evidence.
3. Build a relevance dossier from the user's verbatim request, recorded preferences, acceptance criteria, past corrections, and the affected system's own contract. These are attack anchors, not endorsements.
4. Create an absolute output path under `<project>/.claude/output/<timestamp>-adversarial-review/indictment.md`.
5. Dispatch one fresh reviewer. Use the strongest judgment model available unless the user chose another model. Pin the model and effort explicitly. For code that needs mutation, give it an isolated worktree or copies under `/tmp`; for document and architecture review, keep it read-only. Forbid nested agents and external side effects, tell it to ignore task or board auto-dispatch, require the full report at the assigned path, and tell it to stop after writing it.
6. Verify the report exists and read it in full. Present the findings table without softening or dropping rows. Parent annotations go below it as the defendant's response. Do not fix findings until the user asks or the current task already authorizes fixes.

## Prosecutor contract

Presume acceptance was premature. Attack the work against its own goal and the user's recorded values. Widen into the actual blast radius when the author may have narrowed the frame, but do not invent a different project or relitigate settled direction.

Every main finding has:

- an evidence tag: `EXECUTED`, `CITED`, or `REASONED`;
- a concrete anchor explaining why this user or system cares;
- the claim it refutes;
- proof: an exact command and observed output, an absolute `file:line`, or a verbatim acceptance criterion;
- a severity ranked by cost to the user.

Allow at most two `REASONED` findings in the main table. Unanchored generic advice belongs in a five-line appendix at most.

Required output:

```markdown
# Adversarial review: <scope>

**Prior:** acceptance presumed premature. **Verdict:** <indicted on N counts | held under N attacks>
**Claims ledger:** <M claims, K unsupported, J broken>

## Findings
| rank | evidence | severity | anchor | claim refuted | what is broken | proof |

## Failed attacks
- <attack and the evidence it survived>

## Unanchored observations

## Verdict
<evidence-bound paragraph, without praise or padding>
```

## Execution and safety

- The reviewer may run builds, tests, parsers, or hostile inputs in the workspace when they are read-only, or in an isolated worktree or `/tmp` when mutation is required.
- It never changes live data, global config, ledgers, credentials, or the reviewed artifact. It never commits, pushes, deploys, installs packages, or sends external messages.
- It kills any process it starts.
- It logs every attack that did not land. A clean result is `held under N attacks`, not approval.
- It flags and stops. The parent verifies the artifact and reports honest limitations.
