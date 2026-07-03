## Mining question: corrections

You are auditing real Claude Code transcripts for **user corrections** — moments
where the user pushed back on something the agent did, so the account can learn
from them (the `/atone` pipeline, mistake-patterns, new rules). For each turn you
are given, decide whether it contains a correction, and if so, extract it:

- **Direct correction** — "no", "that's wrong", "revert that", "why did you do
  X", "stop doing Y", "I didn't ask for that".
- **Preference assertion** — the user stating how they want things done, in a way
  that implies the agent got it wrong ("I prefer…", "always…", "never…", "use X
  not Y").
- **Rework demand** — the user asking the agent to redo work it thought was done
  ("that's not what I meant", "start over", "you missed…").
- **Frustration signal** — exasperation, all-caps, repeated re-explaining of the
  same point.

Classify each by the underlying **pattern class** (the reusable category, not the
one-off instance): e.g. "batch verification skip", "overrode user preference",
"scope creep", "declared done without running", "wrong file / wrong surface".

Ignore turns that are ordinary task hand-offs with no correction. Quote evidence.

## Output schema

Return findings as a JSON array; one object per correction turn:

```json
{
  "transcript": "<path>",
  "turn_index": <int>,
  "session_id": "<8-char>",
  "kind": "direct|preference|rework|frustration",
  "pattern_class": "<reusable category, kebab-case>",
  "evidence": "<short direct quote of the user's correction>",
  "already_known": "<yes if it maps to an existing atone slug / rule, else no/unknown>"
}
```

Omit non-correction turns. End your written file with a one-paragraph summary:
the top pattern classes by frequency, and any correction that looks NEW (not
already covered by an existing rule or atone slug).
