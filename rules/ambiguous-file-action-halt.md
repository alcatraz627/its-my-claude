---
brief: When a write target already holds content you didn't create and the user hasn't said overwrite/append/merge, HALT and confirm — don't guess
triggers:
  - tool:Write
  - topic:overwrite-existing-file
  - phrase:"what to do with the file"
  - phrase:"already exists"
related:
  - rules/communication.md
  - rules/sub-agent-outputs.md
tier: 1
category: rules
updated: 2026-05-31
stale_after_days: 365
---

# Ambiguous action on an occupied file → halt and confirm

When the user names a file path to write to but does NOT say what to do if
something is already there, and the destination turns out to hold content you
did not create (another agent's artifact, a prior response, hand-authored
notes) — **stop and ask** before overwriting. "Save it to `<path>`" is not
permission to clobber whatever already lives at `<path>`.

## The rule

Before a `Write` that replaces an existing file's contents, check:

1. **Did I create this file, or is its content what I expect?** If yes — proceed.
2. **Is the content unfamiliar / owned by someone else / a different document
   than mine?** Then the user's instruction is ambiguous between overwrite,
   append, merge, and write-elsewhere. **Halt.** State what's there in one line,
   offer 2–3 options (overwrite · keep-both-rename · append/merge), wait.

A filename is itself a signal: `HANDOFF-RESPONSE-*`, `*-reply`, `_active.md`,
anything that reads like the other half of a conversation, should raise the
expectation that content is already there and is not yours to replace.

## The parallel Read+Write trap (how this got worse)

A `Write` blocked with *"file has not been read yet"* must be followed by a
**sequential** `Read` — look at the content, *then* decide. Batching the Read
and the Write in the **same** tool block does NOT fix it: parallel tool calls
run concurrently, so the Write still fires blind and the Read can't inform it.
Read first, in its own turn, when a destination's contents are in question.

## What this does NOT mean

- Not for files you just created or have been editing this session — you know
  their contents; proceed.
- Not for empty/absent targets — there's nothing to clobber.
- Not for files the user explicitly said to overwrite/replace.

## Diagnostic signal

You're about to `Write` to a path you did not create this session, its current
contents are unfamiliar, and the user gave a path but no overwrite/append/merge
instruction. Stop and confirm.

## Provenance

2026-05-31: user pointed me at `~/mac-migration/HANDOFF-RESPONSE-i-dream.md` to
save a handoff; the path already held the other agent's 61-line response. I
overwrote it (via a same-block Read+Write race), then restored from the Read
output. User: "I did not tell you what to do with that file — halt and get my
confirmation when the action is ambiguous."
