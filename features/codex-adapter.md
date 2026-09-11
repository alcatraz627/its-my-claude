---
brief: How OpenAI Codex CLI runs under this gcc. Rules, conventions, skills, guard hooks, execpolicy rules, claude-ipc identity and the ledgers reach Codex by symlink where its config follows one and by a generated file where it does not; `gcc` (adapters/codex/bin/gcc) is Codex's one write path into the owner's records, queued through an outbox that Codex's own hooks drain. Carries the constraint ledger (every Codex limit and its workaround) and the keep-it-current procedure.
triggers:
  - tool:codex
  - tool:codex-gcc
  - tool:export-agents-md.sh
  - tool:install.sh
  - topic:codex
  - topic:agents-md
  - topic:adapters
  - phrase:"codex adapter"
related:
  - rules/00-index.md
  - conventions/gcc-hygiene.md
  - migrations/0046-codex-adapter.md
  - migrations/0060-codex-adapter-v2.md
  - skills/ipc/SKILL.md
tier: 2
category: features
updated: 2026-09-10
stale_after_days: 120
---

# Codex adapter

Codex (OpenAI's coding agent CLI, `codex 0.153.4` at the time of writing) runs on
the same disk as `~/.claude/`, so the gcc is never copied into its world. Where
Codex follows a symlink, the surface is linked. Where it needs a file of its own
shape, the file is generated from gcc sources by one script. Where its sandbox
blocks a write, a small command queues the write and Codex's own hooks land it.

```
                ~/.claude (source of truth)                 Codex reads
  ┌──────────────────────────────────────────┐   ┌───────────────────────────┐
  │ rules/*.md, conventions, GLOSSARY,       │──▶│ read on demand (same disk) │
  │ mistake-patterns, memory/global          │   └───────────────────────────┘
  │ adapters/codex/preamble.md ─┐            │   ┌───────────────────────────┐
  │ rules/00-index.md ──────────┴─ export ──▶│ ~/.codex/AGENTS.md (generated)│
  │ skills/<10 names> ──────────── symlink ─▶│ ~/.agents/skills/<name>       │
  │ adapters/codex/hooks.json ─── symlink ─▶│ ~/.codex/hooks.json            │
  │ adapters/codex/rules/gcc.rules  symlink ▶│ ~/.codex/rules/gcc.rules       │
  │ adapters/codex/hooks/*.sh                │   run by Codex, outside sandbox │
  │ scripts/{safe-delete,guard-*}.sh ────────┼──▶ wrapped unchanged            │
  │ ledgers, checkpoints, claude-ipc  ◀──────┼── drain-outbox.sh ◀── /tmp/... │
  │                                          │        ▲  gcc <verb> (queued)  │
  └──────────────────────────────────────────┘   └────┴──────────────────────┘
```

One script wires and verifies all of it: `bash ~/.claude/adapters/codex/install.sh`.

## Every transferred surface, and how it stays current

| Surface | Mechanism | Source of truth | Stays current by | Proven by |
|---|---|---|---|---|
| Behavioral rules (all of `rules/`) | read on demand; AGENTS.md carries the one-line index as a router | `rules/*.md` | live (same files) | canary 2026-08-15 (Codex read a rule file when the gist matched) |
| Rule index + working agreement | generated `~/.codex/AGENTS.md`, re-sent every turn | `adapters/codex/preamble.md` + `rules/00-index.md` | `install.sh` (or `scripts/export-agents-md.sh`) after a preamble edit or any rule add/rename | generator asserts row count and the 32 KiB cap; 28.2 KB now |
| Conventions, GLOSSARY, mistake-patterns, `memory/global/` | read on demand, addressed from the preamble | those files | live | preamble read protocol |
| Skills (10 gcc skills + the codex `core-dump`) | symlink `~/.agents/skills/<name>` | `adapters/codex/skills.list`; `adapters/codex/skills/core-dump` | `install.sh` after editing the list; edits to a skill body are live | e2e 2026-09-10: `gcc-proposal` listed with its Claude frontmatter intact |
| Guard hooks (rm, push, protected commits, commit trailers, credentials, secret reads, system dirs, credentialed POSTs, gh marker) | symlink `~/.codex/hooks.json`; `hooks/pre-tool-bash.sh` runs the gcc scripts unchanged | `adapters/codex/hooks.json`, the guard list in `pre-tool-bash.sh`, the scripts under `scripts/` | live, but every edit to `hooks.json` changes the hash Codex trusts: re-trust in `/hooks` | e2e: `rm` blocked by safe-delete; probe: force-push and credential export blocked, `git status` passed |
| Execpolicy rules (rm, force push, reset --hard, clean, repo delete forbidden; push, amend, rebase prompt) | symlink `~/.codex/rules/gcc.rules` | `adapters/codex/rules/gcc.rules` | live; `codex execpolicy check` in `install.sh` | `rm -rf build` → forbidden |
| claude-ipc identity (`cx-<dir>-<id8>`), inbox injection, turn-end nudge | SessionStart / UserPromptSubmit / Stop hooks run claude-ipc's own compiled hook binaries with the env re-keyed | `~/Code/Claude/claude-ipc/dist/ipc-*` | live | e2e: message from `cx-codex-01a08bff` arrived in this session's inbox |
| Ledger writes (proposals, atone, affirm, pins), checkpoint index, IPC sends | `gcc <verb>` → direct, or outbox → `drain-outbox.sh` from PostToolUse (async), Stop, SessionEnd, UserPromptSubmit | `adapters/codex/bin/gcc`, `hooks/drain-outbox.sh` | live | e2e: pin, checkpoint pointer, proposal `prop-20260910-154423-79` all landed; receipts shown mid-turn |
| Session briefing (identity, how to write, top mistake patterns, handback pointers) | SessionStart `additionalContext` | `hooks/session-start.sh` reads `atone/derived/_tldr.txt` | live | e2e step 1 quoted the alias |
| i-dream | domain `codex-sessions`, registered 2026-09-10 (owner ruling) | `adapters/codex/i-dream/`; live copy of the manifest at `~/.claude/i-dream/domains/codex-sessions.toml` | edit the source manifest, re-copy; the extractor runs daily inside i-dream's consolidation | extractor: 71 events from 70 rollouts; `i-dream domain list` shows it |
| Claude → Codex dispatch | the `openai-codex` plugin (`codex:codex-rescue`), unchanged | plugin | n/a | AGENTS.md, skills and rules reach those seats too; hooks only once trusted (below) |

**Symlink versus generate.** Codex follows symlinked skill folders (documented),
and reads `hooks.json` and `rules/*.rules` through a symlink (verified by the
e2e runs above). `AGENTS.md` cannot be a symlink to anything that exists: it is
two sources joined under a byte cap, and Codex TRUNCATES an oversized
instruction file rather than erroring, so the generator refuses to write past
32 KiB. Codex re-sends it every turn, which is why the rule corpus (176k chars)
ships as a 13k index and the full rules are read on demand.

## The constraint ledger

Each Codex limit that shaped the design, with the workaround chosen and its
status. "Verified" means run and observed this session (2026-09-10).

| # | Codex constraint | Workaround | Status |
|---|---|---|---|
| 1 | Hooks run only after the exact hook definition is trusted (per hash) in the TUI's `/hooks`; a headless `codex exec` has no way to answer that prompt, and an untrusted hook is skipped **silently** | `bin/codex-gcc exec` passes `--dangerously-bypass-hook-trust` (the hooks it trusts are ours). Interactive use: open `codex`, `/hooks`, trust the six gcc entries once, again after any `hooks.json` edit. Trust is stored as `[hooks.state."<path>:<event>:<i>:<j>"] trusted_hash = "sha256:..."` rows in `~/.codex/config.toml`; the owner trusted all six on 2026-09-10 | verified both ways (run2 without the flag: hook silent); trusted by the owner |
| 2 | `-c bypass_hook_trust=true` as a config override does not do what the flag does | flag only; never in config.toml | verified (run4) |
| 3 | Hook schema is PascalCase event → matcher group → handlers, same as Claude Code's. The Aug-14 `pre_tool_use` file parsed and never fired | `hooks.json` rewritten in the documented shape | verified |
| 4 | A `version` top-level key makes Codex reject the whole hooks file with one warning that scrolls past | none; keep to `description` + `hooks` | documented |
| 5 | Two config layers holding the same hook fire it twice | one layer only: the user layer symlink; never a project `.codex/hooks.json` copy | observed (canary double-fire) |
| 6 | `PreToolUse` cannot `ask`; only deny, allow, rewrite, add context | Guards that would ask under Claude (the push gate's `approve push <nonce>`) become hard blocks; the preamble forbids pushes anyway | accepted |
| 7 | The shell sandbox writes only under the workspace and `/tmp`, and cannot reach the claude-ipc unix socket without `network_access` (full egress) | `gcc` queues to `/tmp/codex-gcc/outbox/<sid>.jsonl`; hooks run OUTSIDE the sandbox and drain it (PostToolUse async lands it within seconds; Stop, SessionEnd and UserPromptSubmit catch the rest); receipts are injected back | verified, no network grant needed |
| 8 | Codex inherits the launching Claude session's `CLAUDE_CODE_SESSION_ID`, so a direct `claude-ipc register` would rebind the parent's mailbox and a ledger write would carry the parent's id | `hooks/lib.sh` and `gcc` re-key the env to `CODEX_THREAD_ID` (== the hook `session_id`), set `CLAUDE_IPC_ALIAS=cx-<dir>-<id8>`, and unset the parent's messaging socket | verified (attribution correct end to end) |
| 9 | `claude-ipc register` (the CLI) refuses without `CLAUDE_CODE_SESSION_ID` | registration happens in the SessionStart hook with the re-keyed env; the drainer re-registers and retries once on `not_registered` | verified; native `CODEX_THREAD_ID` support filed as `prop-20260910-154423-79` |
| 10 | `transcript_path` is `null` under `codex exec` (and the rollout format is not Claude's JSONL) | Stop hooks that read the transcript (declared-ready, structural-claim, absence-claim, filename-dot, relpath ...) are not ported; their rules bind as text in the preamble | not ported, by design |
| 11 | File edits arrive as `apply_patch` with the patch text in `tool_input.command`, not `file_path` + `content` | Edit/Write gcc guards (prose quality, comment hygiene, banned vocab, settings write) are not ported | not ported; candidate: a patch-target guard for `~/.claude` |
| 12 | The initial skills list is budgeted at 2% of the context window (about 5k chars); past that descriptions are shortened, then skills dropped | `skills.list` is curated (10 + core-dump); add a line, re-run install | verified discovery |
| 13 | Skill bodies name Claude tools and `$ARGUMENTS`; some call `propose.sh` or `claude-ipc` directly | preamble instructs substitution and routes writes through `gcc`; `context: fork` skills are excluded from the list | advisory |
| 14 | No `context: fork`; Codex has its own sub-agents (`~/.codex/agents/*.toml`, `multi_agent` stable) | not ported; a custom-agent file per forked gcc skill is the candidate if Codex use grows | open |
| 15 | AGENTS.md is truncated past `project_doc_max_bytes` (32 KiB) | generator refuses over the cap; 28,249 bytes today, so ~12 more rule rows of headroom before the preamble must shrink or the cap rises | watch |
| 16 | `codex execpolicy check` does not split `bash -lc "a && b"`; the runtime splits only plain chains | rules are the second layer; the PreToolUse guards see the raw command string first | verified (check tool) |
| 17 | Codex writes a `trust_level = "trusted"` row into `config.toml` for every project it runs in | trash the rows for scratch dirs when done | cleaned up this session |
| 18 | `--ephemeral` skips the rollout file | those sessions never reach the staged i-dream domain | accepted |
| 19 | Codex's local memories feature is off; `/import` copies Claude setup rather than linking it | not used; the gcc is read live instead | by design |
| 20 | Codex `/goal` is its own store (`goals_1.sqlite`), unrelated to `goal.sh` | not linked | open |
| 21 | The Aug-14 ruling kept Codex out of the atone/affirm/proposal corpora because they are calibrated to Claude | reversed by the owner's 2026-09-10 ask; every event a seat files carries `src:codex` and `codex:<id8>` tags so a dream lane or a query can filter | default applied, silence means agreement |
| 22 | SessionEnd was not observed in the exec runs' stderr (it is documented for TUI close and 30-minute idle) | the outbox is also drained at Stop and at the next UserPromptSubmit, so nothing depends on it | UNCONFIRMED under exec |
| 24 | The outbox queue lives in `/tmp`, which the seat's sandbox can write, so a seat could append arbitrary argv and have the unsandboxed drainer run it | `drain-outbox.sh` replays only the exact commands `gcc` maps (claude-ipc, propose.sh, atone.sh, affirm.sh, ledger.sh, i-dream pin, checkpoint-register.sh) and writes a refusal receipt for anything else; stale `.inflight` files are folded back onto the queue after five minutes | found by the codex adversarial review 2026-09-11; both fixes proven with a rogue line and a back-dated inflight file |
| 23 | Nothing tells a Claude session or the owner where a Codex seat IS: the claude-ipc heartbeat fires only at turn end, `codex agents` needs the app-server daemon, and the rollout file is the only live record | `codex-gcc status` reads the four instruments at once (processes, rollouts with turn state and last command/message, cx- ipc rows, outbox) and names its basis; the owner raised this as part of the pain point on 2026-09-10 | verified on this session's three seats |

The "no event loop" worry in the original ask turned out to be a trust gate,
not a missing loop: Codex has SessionStart, UserPromptSubmit, PreToolUse,
PostToolUse (sync or async), Stop and SessionEnd, with the same stdin payload as
Claude Code. The one thing hooks cannot do is run inside the sandbox, which is
exactly what makes them the right place to land sandboxed writes.

## Install, update, trust

```
bash ~/.claude/adapters/codex/install.sh      # idempotent; 31 checks; run after any change
```

Then, once per hook definition: open `codex`, type `/hooks`, trust the gcc
entries. Repeat after editing `adapters/codex/hooks.json` (the hash changes).
Headless runs skip this through the launcher:

```
bash ~/.claude/adapters/codex/bin/codex-gcc exec "<task>"
```

which adds `--dangerously-bypass-hook-trust --sandbox workspace-write
--skip-git-repo-check` and nothing else. Never
`--dangerously-bypass-approvals-and-sandbox`: the sandbox is the enforcement
layer and `gcc` exists so it can stay on.

When to re-run `install.sh`: after editing the preamble, adding or renaming a
rule (the index is regenerated inside), changing `skills.list`, or editing
`hooks.json` or `gcc.rules`. Edits to a skill body, a guard script, a hook
script, or the rules text are live through the links. Nothing watches for you;
the staleness that matters (a stale AGENTS.md menu) degrades to a failed read,
never a wrong action.

## `gcc`, the write path

```
bash ~/.claude/adapters/codex/bin/gcc <ipc|propose|atone|affirm|pin|checkpoint|ledger> <args>
```

Same argv as the underlying tool, so its own help applies. `gcc` re-keys the
env, adds `--from cx-...` to ipc sends and `--tags "src:codex codex:<id8>"`
to `add` verbs, tries the call, and on a sandbox refusal appends
`{n, ts, sid, cwd, verb, argv}` to `/tmp/codex-gcc/outbox/<sid>.jsonl`.
`hooks/drain-outbox.sh` renames the file to `.inflight` (so a concurrent `gcc`
starts a fresh queue), replays each argv in the session's cwd, and appends
`{n, verb, exit, out}` to `<sid>.receipts.jsonl`; `hooks/receipts.sh` shows
each receipt once. Read-only verbs (`ledger`, `list`, `show`, `peers` ...)
never queue; an IPC read fails inside the sandbox with a one-line explanation
(the inbox is injected each turn instead).

`GCC_FORCE_QUEUE=1` skips the direct attempt so the queue path can be exercised
from an unsandboxed shell; it exists for tests only.

## What is deliberately not ported

The 40 PreToolUse and 20 Stop registrations in `settings.json` are not mirrored.
Most tune a teammate (ripgrep preference, comment hygiene, WAL, tab title,
command chaining, which under Codex is not even the problem it is under Claude
Code's permission model) and a contractor's output is reviewed anyway. The nine
guards in `pre-tool-bash.sh` are the verbs where review comes after the damage.
Add one by adding a line there; the payload and output contracts match, and
the probe in `install.sh` is the place to prove it blocks.

`adapters/codex/hooks/guard-destructive.sh` is the withdrawn Aug-14 regex gate,
kept as the worked example behind the verdict that regexes over raw shell text
cannot gate a shell (53-case review, 36 mismatches). The gcc guards it was
trying to imitate now run directly instead.

## The hands loop: dispatch grunt work, get it back reviewable

Built 2026-09-11 from the plan at
`~/.claude/assets/reports/20260910-codex-hands-plan/PLAN.md` (its dispositions
table records what the Codex adversarial review changed).

1. **Gate first.** `bash ~/.claude/adapters/codex/bin/codex-gcc gate` reads
   Codex's own limits over the app-server RPC `account/rateLimits/read` (cached
   ten minutes at `adapters/codex/state/limits.json`); GATED at 75% used
   (owner default: stand down at 25% remaining). `hooks/session-start.sh` runs
   the same gate for every lane-dispatched seat (`GCC_DISPATCH` from the
   launcher, `CODEX_COMPANION_SESSION_ID` from the plugin) and caps seats at
   three per project per day (`state/dispatch-<date>.jsonl`; `CODEX_SEAT_CAP`
   overrides). A refused seat gets `continue:false` and never runs its task.
   Owner mute, listed by muted-gates: `~/.claude/.no-codex-usage-gate`.
2. **Brief as a committed file.** Copy `adapters/codex/BRIEF.template.md` to
   `codex-briefs/<ts>-<slug>.md` in the target repo, commit it on the work
   branch, then `codex-gcc exec --brief <path> "<task>"`. The launcher refuses
   an untracked or dirty brief (a worktree checks out HEAD, so an untracked
   brief never reaches it). `GCC_BRIEF` rides into the hooks, and
   `post-tool-bash.sh` tells the seat mid-run when the brief's mtime moves.
3. **The seat commits on the branch and hands back** through its `core-dump`
   skill: sha, `git diff --stat`, pasted output of every brief check.
4. **Claude reviews with `/codex-handback`**: packet checks it re-runs itself,
   then `/skeptical-review` over the range; PASS, PASS-WITH-NOTES, or a second
   brief on the same branch. A second ISSUES-FOUND returns to the owner.

First real run, 2026-09-11: two rounds on the extractor outcome fields; the
rework was a brief defect the reviewer's own run exposed. Report at
`/Users/alcatraz627/Code/Claude/codex/.claude/output/20260911-codex-handback-review/report.md`.

## Where is Codex right now

```
bash ~/.claude/adapters/codex/bin/codex-gcc status            # last 24h
bash ~/.claude/adapters/codex/bin/codex-gcc status --hours 2 --json
```

One screen: alive `codex` processes with their cwd; every seat whose rollout
changed in the window, with its state (`in a turn` when a `task_started` has no
`task_complete` yet, else `finished`), last activity age, launch source and
originator (`exec/Claude Code` is a plugin-dispatched seat, `cli/codex-tui` is
you), cwd, claude-ipc alias and heartbeat, outbox counts, tool-call count, the
last command it ran and the last thing it said. The basis line at the bottom
says what was measured. Read this before asking a seat what it is doing.

## Troubleshooting

- **A hook does nothing and nothing warns.** It is untrusted (constraint 1) or
  the file did not parse (constraint 4). `codex exec` prints
  `hook: PreToolUse` lines on stderr when hooks run; their absence is the
  signal. Canary: a hook that denies a unique string, then a prompt that runs
  it, through `codex-gcc exec`.
- **A hook fires twice.** Two layers hold the same file (constraint 5).
- **Receipts never arrive.** Check `/tmp/codex-gcc/outbox/<sid>.receipts.jsonl`.
  A crashed drain leaves an `.inflight` file; the next drain folds it back onto
  the queue once it is five minutes old. A receipt with exit 126 means the
  drainer refused a queue line that `gcc` did not write.
- **`not_registered` in a receipt.** The alias was pruned while the session
  idled; the drainer re-registers and retries once. A second failure means the
  broker is down (`claude-ipc daemon status`).
- **AGENTS.md refused.** The generator prints bytes over the cap; shorten the
  preamble or raise `project_doc_max_bytes` in `config.toml` and export with
  `CODEX_DOC_MAX_BYTES` to match.

## Provenance

Aug-14/15 (migration 0046): router design, the `version`-key failure, the
handback contract, checkpoint registration, the IPC doorbell finding
(attribution of a Codex fix to the owner). 2026-09-10 (migration 0060): hooks
proven to fire under 0.153.4 with the PascalCase schema and trust bypass;
skills symlinked; guards wrapped; `gcc` and the outbox; identity re-keying;
staged i-dream domain. Both e2e runs' transcripts are Codex rollouts in
`~/.codex/sessions/2026/09/10/`.
