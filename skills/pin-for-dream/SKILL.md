---
name: pin-for-dream
description: Pin a structured insight from the current Claude Code session for i-dream's next dream cycle to examine. Auto-gathers session context (cwd, recent files touched, transcript path). Writes one PinEvent JSON to ~/.claude/pinned/events.jsonl via `i-dream pin add --from-json -`. Use when the user (or you) notices something worth dreaming about — a non-obvious pattern, a bug whose root cause spans files, a tradeoff that should propagate to future decisions. Auto-decays after 2 dream cycles (~2 weeks).
allowed-tools: Bash, Read
user-invokable: true
argument-hint: "[brief description of the insight]"
---

# /pin-for-dream — Pin a session insight for i-dream's next dream cycle

## When to invoke

- User asks "pin this", "remember this for next dream", "/pin-for-dream …"
- You notice a non-obvious pattern mid-session that's worth examining
  outside the current scope (don't derail the current task, just pin it).
- A discovery surfaces that would inform future decisions (architectural
  tradeoff, common pitfall, "we keep doing X — should we have a rule?").

If `$ARGUMENTS` is empty, ask the user once: "What's the insight to pin?"
Then proceed.

## Steps

### 1. Gather session context

Collect what you can — none of these are strictly required, but more is
better:

- **Session id**: `$CLAUDE_SESSION_ID` env var, or extract from the
  current transcript path.
- **Transcript path**: `$CLAUDE_TRANSCRIPT_PATH` env var, OR
  `bash` `ls -t ~/.claude/projects/*/<session-id-prefix>*.jsonl | head -1`
  if you know the session id.
- **cwd**: `pwd`.
- **Recent files touched**: scan the project's `.claude/wal.jsonl` (if
  it exists) for the last 10 `action` entries with `target` fields, OR
  use your own memory of which files you Read/Edit/Wrote in this session.

### 2. Decide framing

Default `framing=investigate`. Override only if the user explicitly says:

- "monitor for repeats" → `framing=monitor`
- "this is a graduation candidate" / "promote this to a rule" →
  `framing=graduate`
- "just a note for context" → `framing=note`

### 3. Build the PinEvent JSON

```json
{
  "id": "",
  "ts": "",
  "pinned_from": {
    "session_id": "<session-id-or-null>",
    "transcript_path": "<absolute-path-or-null>",
    "cwd": "<absolute-cwd>"
  },
  "text": "<$ARGUMENTS or asked text>",
  "context": {
    "files": [
      {"path": "<path>", "line_range": [<a>, <b>]}
    ],
    "related_slugs": [],
    "related_paths_at_time": []
  },
  "framing": "investigate",
  "tool_signatures": [],
  "decay": {
    "cycles_remaining": 2,
    "first_seen_cycle": null,
    "archived_at": null
  }
}
```

`id` + `ts` are intentionally empty — the CLI regenerates them. Leave
fields you couldn't gather as `null` or empty arrays.

### 4. Pipe to the CLI

```bash
echo '<json>' | i-dream pin add --from-json
```

Capture stdout — it'll be the assigned pin id (e.g. `pin-20260517170135-6f`).

### 5. Confirm to the user

Print:

```
✓ Pinned as <id>
  Framing: <framing>
  Files: <count> referenced
  Auto-archives after 2 dream cycles (~2 weeks)
  See in tomorrow's: i-dream digest  (section "Pinned from sessions")
```

If anything in steps 1–4 failed gracefully, mention what was missing
(e.g. "couldn't determine transcript path; pinned without it").

## When NOT to invoke

- Routine reminders the user could write to a TODO ("/pin-for-dream:
  finish the lint fix" — too small)
- Things that belong in `/atone` (a mistake just happened) or `/affirm`
  (a good behavior just happened) — those have their own skills with
  proper schemas
- One-off questions ("what does X mean?") — pinning these creates noise
  in tomorrow's digest

## Tone

Single short confirmation, no preamble. The pin event itself is the
artifact — don't summarize it in conversation.
