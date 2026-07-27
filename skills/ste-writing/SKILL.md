---
name: ste-writing
description: Rewrite prose (docs, READMEs, error messages, runbooks, hook text — never code, never chat) into Simplified Technical English adapted to this account's rules. Use when asked to make writing plain, de-slop a doc, or write docs/error text that reads human. Strict mode for procedures/errors/hook text; flavored mode for READMEs/docs. Chat replies are out of scope (audience-aware-writing governs them).
---

# ste-writing

Rewrite prose into ASD-STE100-derived plain technical English, adapted to this
account (the upstream skill is vendored at the 2026-07 language-quality sweep's
`scratchpad`; spec: asd-ste100.org — copyrighted, do not paste). Applies to
documentation, READMEs, error messages, release notes, runbooks, and hook
user-text. It does NOT apply to code, identifiers, command syntax, or chat
replies — chat keeps a voice and `rules/audience-aware-writing.md` is its
router. STE strips voice on purpose.

## Rules

WORDS
- One name for one thing; never two names for the same item.
- The short common word: use (not utilize), start (not initiate), help (not
  facilitate), before (not prior to), about (not regarding), get (not obtain),
  show (not demonstrate), also (not additionally/furthermore).
- No marketing adjectives (seamless, robust, powerful, effortless, elegant,
  production-ready) — the full banned list lives in the thesaurus and
  `scripts/style/prose-lint.py`.

VERBS
- Active voice; name the actor. "The parser reads the file."
- A verb for an action: "analyze the log", not "perform an analysis of the log".
- No stacked auxiliaries, no "-ing" main verb where a simple tense works.

SENTENCES
- One instruction per sentence. Max 20 words (instruction), 25 (descriptive).
- No contractions in strict mode. Keep articles: a, an, the.

PUNCTUATION (house amendment — stricter than STE)
- No semicolons: write two sentences.
- No connective em-dashes, and no two-split pattern in any punctuation
  (clause — elaboration). The thesaurus bans it account-wide; STE itself does
  not ban the em-dash, this account does.

STRUCTURE (house amendment — verdict-last)
- Facts before conclusions, always: what is done, what is not, what needs
  review, then any assessment, clearly advisory. Never open with a verdict
  word (Done, Perfect, complete, live). The done-verdict belongs to the user
  (`memory: feedback_verdict-last-status-reports`).
- One topic per paragraph, max six sentences. Steps go in a numbered list,
  one action per item, imperative form, condition before command.

Write only the requested text. No preamble, no closing remarks.

## Modes

- **strict** — procedures, runbooks, error messages, hook user-text: every rule
  plus both length caps.
- **flavored** — READMEs, PR descriptions, general docs: sentence, paragraph,
  active-voice, verdict-last, and no-two-split discipline; the ~900-word STE
  dictionary lockdown is relaxed so the text reads naturally.

## Self-lint before returning text

Run `python3 ~/.claude/scripts/style/prose-lint.py` on the draft (stdin works).
Then check by hand: any sentence over the cap → split. Any verdict-opener →
move the verdict to the end. Any two-split chain → restructure. Any thing named
two ways → pick one name. The linter fixes the measurable form; it cannot make
a hollow paragraph true — that part stays yours.
