---
brief: Never regex-match a string error message to drive selector logic — propagate a structured code instead
triggers:
  - topic:error-handling
  - topic:cause-routing
  - phrase:"err.message.match"
  - phrase:"cause_message"
  - phrase:"includes("
related: []
tier: 1
category: rules
updated: 2026-05-04
stale_after_days: 180
---

# Error classification — flag-driven, not string-driven

When code branches on the content of an error message string to decide what to do (which user-facing message, which UI state, which retry policy), the branch is fragile.

## The rule

If you find yourself writing `/text/.test(err.message)`, `err.message.includes("...")`, `err.message.startsWith("...")`, or `err.message.match(...)` to **decide** what to render or which path to take, stop. The information you're looking for needs to travel as a stable flag — not a sentence.

## What goes wrong without this

- The producer (backend, library, micro-service) rephrases the message — for clarity, a typo fix, i18n, log scrub. The match silently falls through to the generic branch. No compile error, no test failure (unless the test pinned the exact string), no signal at runtime — just a worse user experience that nobody flags.
- Substring collisions: `"not found"` matches both `"User not found"` and `"Template style not found"`.
- The matcher accumulates: 3 branches today, 12 in two years, all coupled to messages no one remembers to keep stable.

## The fix — a stable structured field

The producer attaches a code field — `error.code`, `cause_code`, `kind`, `reason`, whatever the envelope calls it — taken from a closed enum/union. The consumer switches on that field, not on the message. The message stays human-readable for logs and fallbacks.

Backend (Python example):
```python
raise SomeError(code=ErrorCode.template_not_found,
                message=f"Template {tpl} not found",
                context={"template_id": tpl})
```

Frontend (TypeScript example):
```ts
switch (err.code) {
  case "template_not_found": return `Template "${err.context?.template_id}" not found.`;
  // ...
}
```

Both sides keep the code list in sync — a new variant is a two-file change. Adding `(string & {})` to the TS union (or making the enum extensible) keeps forward-compat with backends that ship a new code before the frontend updates.

## When matching IS OK

- **Display-only** transforms (PII redaction in logs, syntax highlighting of an error message in a debug UI). The match decides *how to render text*, not *which code path runs*.
- **Genuine third-party error sources** with no structured envelope — e.g. some SDK that only throws `Error("...")`. Even then: wrap matchers behind one helper, treat each new match as tech debt, and lobby upstream for codes.

## Verify

When auditing a codebase for this anti-pattern:

```bash
rg -n "(test|match|includes|startsWith)\(.*err\.(message|cause_message|description)" --type ts --type js --type py
```

Anything that drives a branch from the result is suspect.

## Related

- Mistake pattern: `string-message-regex-for-flow` in `~/.claude/mistake-patterns.md`
- Project rule (Versable frontend): `frontend/.claude/rules/error-classification.md`
