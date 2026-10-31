# Cleaning up comments

A pass over changed code (or a path the user names) that strips noise from
comments, rewrites AI-sounding ones into short human ones, and flags claims
that may have gone stale. Run it before a commit. It never commits.

## 1. Load the rubric

Look for the repo's own comment rules first: a `comment-style.md`, a
"Comments" section in the nearest `CLAUDE.md` or CONTRIBUTING file, or a
project rule file about comments. If one exists it outranks this file. If none
exists, `comments.md` plus the voice rules below are the whole rubric.

## 2. Resolve scope

Default to the files changed on this branch or in this diff. A path or glob
the user names means exactly that. The whole tree is a big sweep, so confirm
before doing it. If the scope is ambiguous, ask.

## 3. The voice for rewritten comments

1. No em dashes, and no spaced en dashes either. Use a comma, period or
   parentheses.
2. Zero emojis in source. Arrows used as "maps to" notation are fine.
3. As short as possible. One line beats two. If the point needs a paragraph,
   it belongs in a doc with a one-line pointer.
4. Right altitude. Do not explain what the code plainly says, and do not
   assume the reader holds the whole system in their head. Say the non-obvious
   why, name the thing in human terms, stop.
5. Profanity is fine, especially when the user wrote it. Never remove it, and
   never add any.

## 4. Sort findings into three tiers

| Tier | What it is | Action |
|---|---|---|
| Strip | Agent tags, plan refs, history ("pre-fix", "see PR #"), decorative banners | Remove the fragment, keep any real sentence on the line |
| Rewrite | A real fact wrapped in em dashes, emojis, an essay, or a restatement of the code | Rewrite to the voice, keep the fact, delete pure restatements |
| Flag | TODO, FIXME, "currently", "for now" | List with `file:line`, never edit. Only the author knows if it still holds |

```
// [claude@2026-05-07] retry uses backoff per Phase 2.B8  ->  // retry uses backoff
// ──────────────────────────────                        ->  [delete the line]
// 🚀 fast path for warm cache                            ->  // fast path for warm cache
```

## 5. Hard floor: never touch

- `NOTE(by human)`, `HACK`, `IMPORTANT`. These mark deliberate, tested choices.
- Tool pragmas: `eslint-disable`, `@ts-expect-error`, `@ts-ignore`,
  `# noqa`, `# type: ignore`, `prettier-ignore` and the like.
- License headers, copyright, `SPDX-`, shebangs.
- Doc tags that tooling reads: `@param`, `@returns`, `@deprecated`.
- Commented-out code. Flag it, do not delete it. The author may want it back.

If you cannot tell whether a comment is load-bearing, flag it instead.

## 6. Preview, confirm, apply

Show findings grouped by tier, then by file, with the current text and the
proposed result. Lean toward applying rather than flag-only, because a human
reviews the diff. Ask before editing unless the user said to apply. Edit
comments only, never reflow code, and remove an emptied comment line entirely
so no blank `//` is left.

## 7. Verify and report

A botched multi-line edit can break parsing. Run the typecheck, or
`python -m py_compile` on touched Python files. Report counts per tier, files
changed, and the flag list. Leave the changes unstaged for the user to review.
