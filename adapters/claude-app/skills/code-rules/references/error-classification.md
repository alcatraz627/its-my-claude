# Branch on error codes, never on error message text

If code decides what to render, which state to show or which retry policy to
use by matching the text of an error message, the branch is fragile. The
information has to travel as a stable field, because a sentence cannot do
that job.

The smell: `/text/.test(err.message)`, `err.message.includes("...")`,
`err.message.startsWith("...")` or `err.message.match(...)` driving a branch.

## What goes wrong

- The producer rephrases the message for clarity, a typo fix, translation or
  a log scrub. The match silently falls through to the generic branch. No
  compile error, no failing test unless one pinned the exact string, no
  runtime signal. Only a worse experience that nobody reports.
- Substrings collide. `"not found"` matches both `"User not found"` and
  `"Template style not found"`.
- The matcher grows: 3 branches today, 12 in two years, each coupled to a
  message nobody remembers to keep stable.

## The fix

The producer attaches a code from a closed set (`code`, `kind`, `reason`,
whatever the envelope calls it). The consumer switches on that field. The
message stays human-readable for logs and fallbacks.

```python
raise SomeError(code=ErrorCode.template_not_found,
                message=f"Template {tpl} not found",
                context={"template_id": tpl})
```

```ts
switch (err.code) {
  case "template_not_found":
    return `Template "${err.context?.template_id}" not found.`;
}
```

Both sides keep the code list in sync, so a new variant is a two-file change.
In TypeScript, widening the union with `(string & {})` keeps the frontend
working when the backend ships a new code first.

## When matching is fine

- **Display only.** Redacting secrets in a log line, or highlighting an error
  in a debug view. The match decides how text looks, not which path runs.
- **A third-party source with no structured errors**, such as an SDK that only
  throws `Error("...")`. Even then, put every matcher behind one helper,
  treat each new match as debt, and ask upstream for codes.

## Auditing for it

```bash
rg -n "(test|match|includes|startsWith)\(.*err\.(message|description)" --type ts --type js --type py
```

Any hit whose result drives a branch is suspect.
