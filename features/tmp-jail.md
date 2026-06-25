---
brief: Session-scoped "/tmp jail" — confine all writes to /tmp for the current session (and its sub-agents). Hook-gated, off only by the user.
triggers:
  - topic:tmp-jail
  - topic:confine-to-tmp
  - topic:restrict-writes
  - topic:sandbox-session
  - phrase:"jail to tmp"
  - phrase:"only write to tmp"
related:
  - rules/shell.md
  - conventions/hook-authoring-and-review.md
tier: 2
category: features
updated: 2026-06-25
stale_after_days: 180
---

# tmp-jail — session-scoped /tmp write jail

A toggle that confines this session's writes to `/tmp` (and its macOS real path
`/private/tmp`). Reads are never affected. Use it when a stretch of work should
not be able to touch the real filesystem — a risky or experimental edit, or a
sub-agent fleet you want kept off the tree. It is **rare-use**: off by default,
zero friction when off. Do not enable it eagerly; enable it when the user asks,
or when you judge a specific operation genuinely warrants the guardrail.

## Properties

- **Session-local.** The marker is keyed by the session id, so enabling it in one
  session never affects your other running sessions.
- **Does not survive a restart.** A new session starts clean. Re-enable manually
  if the work continues.
- **Sub-agents are covered.** PreToolUse hooks fire inside sub-agent tool calls
  (verified), so one jail covers a whole fleet.
- **No mute file** (deliberate, by user decision). There is no `.no-tmp-jail`
  escape hatch — that would be a silent one-touch bypass.

## Enable

Run `tmp-jail on`. The PreToolUse hook creates the session marker and confirms
with `✅ /tmp JAIL ENABLED for this session (<id>)`. From then on every write
outside `/tmp` is blocked until the jail is lifted.

(If you do not see the confirmation, the hook is not active in this session yet —
hooks load at session start, so a session that began before the hook was installed
needs a restart. Then `tmp-jail on` again.)

## Lifting it — ask the user (do not self-lift)

The off-switch is **by instruction, enforced best-effort.** The marker lives outside
`/tmp`, and the gate blocks the common self-lift paths: the `tmp-jail off` command
(including path-qualified `~/.local/bin/tmp-jail off`), marker deletion via
`rm`/`trash`/`unlink`/`truncate`/`find -delete`, settings edits, and `..` traversal.
It is NOT a hard guarantee — a determined agent with arbitrary Bash can still escape
(see Limits). So the rule is behavioural: **do not try to lift the jail or work
around it.** When you are jailed and need to write outside `/tmp`, surface the block
and ask the user to run, in their own terminal:

> `tmp-jail off <session_id>`

The hook puts the real session id in every block message — relay that command
verbatim. The user running it is the explicit confirmation. Continue once they have.

## Off (user only)

`tmp-jail off <session_id>` removes the marker. Only the user runs it (their shell
has no agent hooks). `tmp-jail status` lists active jails.

## Limits — it is a guardrail, not a sandbox

A PreToolUse hook cannot mechanically confine a Bash-enabled agent against its will;
the agent has arbitrary shell. So this is a **guardrail**. The file-tool gate
(Write/Edit/MultiEdit/NotebookEdit) is exact. The Bash gate blocks the common write
and self-lift forms (redirects, `cp`/`mv`/`tee`/`dd`/`install`/`rsync`/`ln`/`sed -i`/
`mkdir`/`touch`/`trash`/`unlink`/`truncate`/`find -delete`, `..` traversal) but:

- **Interpreter writes still escape** — `python -c "open('/x','w')"`, `node -e
  fs.writeFileSync`, `perl -e`. This is the one remaining open vector. It can be
  closed inside the hook by also gating interpreter-eval while jailed (block
  `python -c` / `node -e` / `perl -e` carrying write hints); a conservative add, not
  yet enabled.
- The Bash gate conservatively over-blocks (a `cp /Users/x /tmp/y` that only reads
  from outside /tmp is still blocked — a false block just routes you to ask the user).
- The default Bash sandbox does **not** block filesystem writes (verified), so the
  Bash gate is load-bearing, not backed by the OS.

What it is good for: stopping casual and accidental out-of-/tmp writes across the file
tools and common Bash, plus covering sub-agent fleets, with a session-local toggle.
It is not built to defeat a determined adversary. (For a hard, whole-session,
write-nothing lock, Claude's **plan mode** already exists — this is the different,
`/tmp`-writable, toggleable niche.)

## Artifacts

| File | Role |
|------|------|
| `~/.claude/scripts/hooks/tmp-jail-guard.sh` | PreToolUse gate (the enforcement) |
| `~/.claude/scripts/hooks/tmp-jail-cleanup.sh` | SessionEnd marker cleanup (tidy) |
| `~/.claude/scripts/tmp-jail` (→ `~/.local/bin/tmp-jail`) | CLI: `on` / `off <id>` / `status` |
| `~/.claude/run/tmpjail/<session_id>` | the per-session marker (presence = jailed) |

Registered in `~/.claude/settings.json` under `hooks.PreToolUse` (matcher
`Write|Edit|MultiEdit|NotebookEdit|Bash`) and `hooks.SessionEnd`.
