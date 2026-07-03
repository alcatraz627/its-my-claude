## Mining question: hook feedback

You are auditing real Claude Code transcripts for signal about how the account's
**hooks** are landing with the user. For each turn you are given, decide whether
it contains any of the following, and extract it:

- **Pushback on a hook fire** — the user objecting to, overriding, or expressing
  annoyance at a hook nudge / block / autocorrect (e.g. "why did it block that",
  "that hook is wrong here", "stop nagging me about X").
- **A muted / bypassed nudge** — the user or agent muting a gate (`touch
  ~/.claude/.no-*-gate`, `--no-verify`, `.comment-hygiene-off`, etc.), or the
  agent silently ignoring a surfaced nudge.
- **A false positive** — a hook fired on something it should not have (the nudge
  did not apply, the "smell" was intentional, the block was wrong).
- **A missing gate** — a mistake the user had to catch by hand that a hook could
  have prevented (a candidate for a NEW hook).
- **A hook that worked** — the user or agent crediting a hook with catching a
  real problem (keep these; they justify the hook).

Ignore turns with no hook signal. Do not invent findings — quote the evidence.

## Output schema

Return findings as a JSON array; one object per hook-signal turn:

```json
{
  "transcript": "<path>",
  "turn_index": <int>,
  "session_id": "<8-char>",
  "signal": "pushback|muted|false-positive|missing-gate|worked",
  "hook": "<hook name or id if identifiable, else 'unknown'>",
  "evidence": "<short direct quote from the turn>",
  "suggested_action": "<tune | mute-scope | new-gate | keep | none>"
}
```

If a turn has no hook signal after inspection, omit it. End your written file
with a one-paragraph summary: the top 3 hooks generating friction and the top 3
missing-gate candidates.
