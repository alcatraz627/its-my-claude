---
brief: A value crossing from a machine to a person's screen is written in the machine's vocabulary, and something has to translate it. Where nothing does, the raw token ships to the reader least able to read it. Four shapes (a code, a raw scalar, a value's type, a sentinel rendered as a name); the tell is a surface that formats SOME fields and passes the rest through.
triggers:
  - topic:ui
  - topic:rendering
  - topic:error-messages
  - phrase:"object Object"
  - phrase:"renders as"
  - phrase:"shows the code"
related:
  - rules/audience-aware-writing.md
  - rules/testing.md
  - conventions/visual-design.md
  - features/hook-design.md
paths:
  - "**/*.tsx"
  - "**/*.jsx"
  - "**/*.vue"
  - "**/*.svelte"
  - "**/components/**"
  - "**/templates/**"
  - "**/*.hbs"
tier: 2
category: rules
updated: 2026-08-25
stale_after_days: 365
---

# The machine's token where a person's words belong

Every value crossing from a machine to a screen is written in the machine's
vocabulary, and something has to translate it. Where nothing does, the raw token
ships, and it always ships to the person least able to read it.

The owner's phrasing, 2026-08-25, on catching the fourth instance in one sitting.

## The four shapes

| shape | what ships | what belonged there |
|---|---|---|
| **a code** | `LOW_CONFIDENCE`, `NO_SUBJECT` | the sentence its own module publishes for it |
| **a raw scalar** | `0.6523` | `65%`, which the table beside it already showed |
| **a value's type** | `[object Object]` | `Terminology id: 16059` |
| **a sentinel rendered as a name** | `unconfigured-module` at heading size | "Not named", sentinel demoted to the hint |

## The fourth is the one to learn from

It is the least like a bug. A sentinel is chosen *precisely* so an unset value
cannot be mistaken for a decision. Rendering it at heading size does the one
thing the sentinel exists to prevent: it reads as the real value. **A placeholder
displayed as a value defeats the placeholder.**

So the check is not only "is this token translated" but "is this token being
presented as though it were an answer".

## The tell is structural, which is why review keeps missing it

Not "does this look wrong". A surface that formats *some* fields and passes the
rest through is one unrecognised key away from this, forever, and today's data
decides whether you see it.

The worked case: `previewCell` translated `type` and sent everything else
through `String()`. Forty lines above it in the same file, the outcomes table
carried a comment promising that a held row's reason never renders as a bare
token, and kept that promise. **One table honoured the rule and its neighbour
did not, in one file, and the neighbour was the one a reviewer opens 84 times.**

## The check

Before shipping a surface that renders values it did not author:

1. **Name what translates each value.** For every key this surface can receive,
   what turns it into the reader's words? A surface that cannot answer for its
   *default branch* already has the defect, whether or not today's data reveals it.
2. **Make the default branch the loud one.** Prefer one shared formatter over a
   per-column one. A `switch` whose `default` is `String(value)` is the bug.
3. **Ask whether the value belongs there at all.** Translating a token you should
   not be displaying is fixing the typography of a defect.

## Prose is not the enforcement, and should not pretend to be

`PLACEMENT.md`'s mechanism table is blunt: a thing that must hold every time is a
hook, not a prompt. This rule is the judgment half. The mechanical half belongs
in whatever gate the project already runs over its rendered output, because the
defect is visible in the DOM and cheap to match:

```
/^\[object /        a value's type
/^[A-Z][A-Z0-9_]{4,}$/   a bare SCREAMING_CASE code in a cell
```

Three of the four instances would have failed that check before a person looked.
A gate that claims to catch "machine data rendered as prose" and catches none of
these is a check that has never been watched failing
(`rules/testing-patterns.md` § `[mutation-test-the-guard]`).

## What this rule does NOT mean

- Not a ban on showing an identifier. An operator often needs the raw value;
  the rule is about which one is the *headline* and which is the hint.
- Not applicable to agent-facing surfaces. A log, a WAL entry, an internal note
  may carry raw tokens; the trigger is a value reaching a **person**.

## Diagnostic signal

You are writing a render function whose fallback is `String(value)`, or you are
adjusting how a machine token *wraps, truncates or aligns* rather than asking
whether it should be on screen in that form.

## Related

- [[audience-aware-writing]] owns the **prose** half of this doctrine (identify
  the reader, write meaning-first). This owns the **data** half.
- `rules/testing-patterns.md` § `[render-before-judge]`, § `[mutation-test-the-guard]`
- Worked instances and the project-side standard: `contract/v6/console-presentation.md`
  axis 20, in `~/Code/Versable/gcp`.
