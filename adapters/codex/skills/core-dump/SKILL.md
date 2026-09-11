---
name: core-dump
description: Write a resumable handback of this session to disk and register it in the owner's checkpoint index. Use when the owner says core-dump, checkpoint, handback, dump state, or write it down; when finishing any task; and mid-task once losing what you established would be expensive.
---

# core-dump

Write down what happened, in a form someone else can pick up cold.

The reader is not you. It is the owner, or a Claude Code session, or a later
Codex run with none of your context. Assume they know the repository and nothing
about this session.

## When

- At the end of every task, always, without being asked.
- The moment the owner says core-dump, checkpoint, handback, dump state, or
  write it down. Do it immediately, at whatever point you are, then carry on.
- Mid-task when you have established something expensive to rediscover: a root
  cause, a failed approach worth not repeating, a decision and its reason.

A mid-task checkpoint is cheap and is not a sign you are finishing. Write what is
true right now and put in-flight work under **State now** rather than pretending
it is done.

## The file

Timestamped, in the working directory, with a symlink to the newest:

```
_codex-handback-YYYYMMDD-HHMM.claude.md      write this
ln -sf _codex-handback-YYYYMMDD-HHMM.claude.md _codex-handback.claude.md
```

Use the real date and time. Never write the bare `_codex-handback.claude.md`
directly: it is a pointer, and one fixed filename means the next run silently
erases this one. That has already happened once, when a review run that changed
nothing overwrote the record of the run that did the work.

## The sections

Write all seven. An empty one says something; a missing one is a gap the reader
has to fill by guessing.

1. **Goal** as you understood it, in your own words rather than the prompt's.
   Where your reading differed from the literal request, say so.
2. **Changed**, every file, absolute paths, one line each on why.
3. **Verified**, what you ran and the output proving it. If you could not run
   something, write `UNCONFIRMED` and the reason. An honest gap is worth more
   than a checkmark. A type-check, a build, or a test collection is not a run.
   This section is the review packet a Claude reviewer opens first, so it must
   carry, verbatim: the commit sha of your work on the branch (`git rev-parse
   HEAD`), `git diff --stat <base>..HEAD` where `<base>` is the branch's start
   point, and the pasted output (not a summary) of every check the brief
   listed. If you were dispatched with a brief, every "Checks that must pass"
   line appears here with its result.
4. **State now**, what someone opening this repo would find. Half-finished edits,
   a server left running, a file moved aside, a branch not switched back.
5. **Not done**, including what you skipped deliberately and what you were unsure
   about.
6. **Next**, the concrete steps you would take if you continued, in order.
7. **Open questions** for the owner. Decisions you could not make alone.

Sections 4 through 6 are what make this resumable rather than merely a record.
Someone picking this up should not have to reconstruct what you were about to do.

## Register it

```
bash ~/.claude/adapters/codex/bin/gcc checkpoint <handback-path> "<one-line summary>"
```

That writes a pointer into `~/.claude/checkpoints/`, the index the owner's
Claude tooling reads to find checkpoints. Without it your file sits in a
directory nobody thinks to open. Run it once, after the file exists. `gcc`
queues the write if your sandbox refuses it and a hook lands it within seconds;
if it prints a failure, say so in one line and move on; the file is still the
artifact.

The summary is what shows up in a picker. Make it name the work, not the
activity: "renewal cron: anchor-day fix + migration, tests green" beats
"did some work on credits".

## Announce it

```
bash ~/.claude/adapters/codex/bin/gcc ipc send --to-project . --no-reply-expected "codex done: <one line>"
```

Your session was registered on claude-ipc at start (alias `cx-<dir>-<id8>`);
`gcc` fills in `--from`. Never call `claude-ipc` directly: your environment
carries the parent Claude session's id and a direct call would speak as it. Say
who you are and name the files you touched, because a Claude session reading
that mailbox cannot otherwise tell your work from a human's, and it will guess
wrong. It has guessed wrong before.

Best-effort: if it fails, note it in one line and move on. Never retry, and
never work around the sandbox to force it through.

## Reading one back

At the start of a task, read whichever exist: `_codex-handback.claude.md` for
your own last run, and `_checkpoint.claude.md` for the owner's Claude session.
If both exist the Claude one is usually the better briefing, because it was
written by whoever set up the work you are being handed.
