# A machine's token where a person's words belong

Every value crossing from a machine to a screen is written in the machine's
vocabulary, and something has to translate it. Where nothing does, the raw
token ships, and it reaches the person least able to read it.

## Four shapes

| Shape | What ships | What belonged there |
|---|---|---|
| A code | `LOW_CONFIDENCE`, `NO_SUBJECT` | The sentence its own module publishes for it |
| A raw scalar | `0.6523` | `65%`, which the table beside it already showed |
| A value's type | `[object Object]` | `Terminology id: 16059` |
| A sentinel shown as a name | `unconfigured-module` as a heading | "Not named", with the sentinel as a hint |

The fourth teaches the most because it looks least like a bug. A sentinel
exists so an unset value cannot be mistaken for a decision. Showing it as a
heading makes it read as the real value. A placeholder displayed as a value
defeats the placeholder. So the check is not only "is this translated?" but
"is this being presented as an answer?"

## The tell is structural

A surface that formats some fields and passes the rest through is one
unrecognised key away from this, and today's data decides whether you see it.

Example: a `previewCell` function translated the `type` field and sent every
other value through `String()`. Forty lines above it in the same file, the
outcomes table carried a comment promising that a held row's reason never
renders as a bare token, and kept that promise. One table honoured the rule
and its neighbour did not, in one file, and the neighbour was the one people
opened most.

## The check

Before shipping a surface that renders values it did not write:

1. **Name what translates each value.** For every key it can receive, what
   turns it into the reader's words? A surface that cannot answer for its
   default branch already has the defect.
2. **Make the default branch loud.** Prefer one shared formatter over one per
   column. A `switch` whose `default` is `String(value)` is the bug.
3. **Ask whether the value belongs there at all.** Translating a token that
   should not be shown fixes the typography of a defect.

The defect is visible in rendered output and cheap to match, so a project's
existing output checks can catch most of it:

```
/^\[object /                a value's type
/^[A-Z][A-Z0-9_]{4,}$/      a bare SCREAMING_CASE code in a cell
```

## What this does not mean

- Not a ban on showing identifiers. An operator often needs the raw value.
  The rule decides which is the headline and which is the hint.
- Not for agent-facing output. Logs and internal notes may carry raw tokens.
  The trigger is a value reaching a person.

## Diagnostic

You are writing a render function whose fallback is `String(value)`, or you
are adjusting how a token wraps or truncates instead of asking whether it
should be on screen in that form.
