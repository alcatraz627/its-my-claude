---
brief: The map of every prose, voice and reader-annoyance capability in the gcc (rules, conventions, personas, skills, hooks, lints, style data), which surface each one guards, where they overlap or disagree, and the consolidation options on the table. Start here before adding any new writing rule or prose gate.
triggers:
  - topic:prose-quality
  - topic:voice
  - topic:ai-smell
  - topic:em-dash
  - phrase:"prose gate"
  - phrase:"writing rule"
  - phrase:"anti slop"
related:
  - rules/audience-aware-writing.md
  - conventions/doc-writing.md
  - conventions/language-quality.md
  - scripts/hooks/format-gate-stop.sh
  - scripts/style/prose-lint.py
tier: 2
category: features
updated: 2026-10-27
stale_after_days: 90
---

# Prose and voice: what guards the writing

The gcc has about 110 separate pieces that shape how the agent writes: rules it reads, standards it follows, reviewers it can hand drafts to, and hooks that send a reply or a file back when it reads badly. They grew one incident at a time, so the same tell is often defined in several places with different thresholds. This page lists them by the surface they guard, then names the overlaps, the contradictions and the stale references, and ends with the ways they could be pulled together.

Row-level detail, with file and line for every claim, is in the two survey reports this page was built from:

- `~/.claude/assets/reports/20261027-prose-capability-scour/docs-side.md` (57 rows: rules, conventions, personas, skills, indices)
- `~/.claude/assets/reports/20261027-prose-capability-scour/enforcement-side.md` (56 rows: hooks, lints, hinters, style data)

## How the layers fit

```
  instruction (read, ~70% adherence)        enforcement (mechanical)
  ─────────────────────────────────        ──────────────────────────────
  CLAUDE.md, rules/, conventions/   ──┐    PreToolUse  guard-prose-quality (files)
  personas (doc-writer,               │                guard-gh-prose (GitHub text)
    readers-advocate, greybeard)      │                guard-commit-signature, ai-signature
  skills (ste-writing, pr-description,│                guard-comment-hygiene
    cleanup-comments, write-docs,     │    PostToolUse doc-voice-gate, comment-verbosity
    deck, word-doc)                   │    Stop        format-gate (6 chat checks in one)
                                      │                bare-id, named-next-work, owner-ask,
                                      │                hand-rendered-tasks, doc-voice-gate
                                      │    git         pre-commit prose gate, commit-msg
                                      └──▶ shared engines: prose-lint.py, prose_readability.py
                                                       style/thesaurus.jsonl (22 owner verdicts)
  offline: style-watch worker, friction audit (weekly), thesaurus review, sweeps
```

Instructions say what good writing is. Hooks catch the tells that kept slipping through anyway. `PLACEMENT.md` states the split: a rule that must always hold becomes a hook.

## By surface

### The agent's chat replies

| Capability | Kind | What it does | File |
| --- | --- | --- | --- |
| Reply is the answer | always-loaded rule | First line is the one thing the owner must decide; no "what I did" opener | `rules/dense-briefing-direct-answer.md` |
| Terse in, terse out | always-loaded rule | Match length to the message | `rules/communication.md` |
| Absolute paths | always-loaded rule | Paths in a reply start with `/` or `~` | `rules/absolute-paths-at-the-reader-boundary.md` |
| No period after a path | CLAUDE.md core | Ghostty swallows the period into the link | `CLAUDE.md` |
| Evidence before agreement | always-loaded rule | No "you're absolutely right" without a check | `rules/pushback-and-self-criticism.md` |
| Questions go to a wizard | always-loaded rule | More than one owner question becomes a decision page | `rules/owner-decisions-go-through-a-wizard.md` |
| format-gate | Stop hook, blocks once | Six checks in one pass: path-dot, em-dash, length cap (2600 chars), relative path, prose-smell (blocks on 2+ tells under policy `enforce`), dense-briefing (advisory) | `scripts/hooks/format-gate-stop.sh` |
| format reminder | prompt hinter | Reminds the next two turns which format class tripped | `scripts/hooks/format-reminder-ups.sh` |
| Bare-id clusters | Stop hook, blocks | `#123`, `VER-12`, hashes with no words saying what they are | `scripts/hooks/bare-id-cluster-stop.sh` |
| Named next work | Stop hook, blocks | "Next I will..." with the work undone | `scripts/hooks/named-next-work-stop.sh` |
| Unanswerable ask | Stop hook, blocks | An ask the owner can't answer without opening something | `scripts/hooks/owner-ask-content-stop.py` |
| Hand-drawn task lists | Stop hook, warns | Task table painted by hand instead of `/tasks` | `scripts/hooks/hand-rendered-tasks-stop.sh` |
| Context claims | Stop hook, warns | "Running low on context" with no measurement | `scripts/hooks/ctx-claim-stop.sh` |
| Credential asks | Stop hook, blocks | Asking the owner to mint a token without checking first | `scripts/hooks/credential-ask-stop.sh` |
| Lazy questions | PreToolUse nudge | `AskUserQuestion` with no code read this turn | `scripts/hooks/guard-lazy-question.sh` |
| Reply telemetry | Stop hook, records | Length, bare ids, completion verbs per reply, for the weekly friction audit | `scripts/hooks/counter-gate-stop.sh` |

### Documents the agent writes

| Capability | Kind | What it does | File |
| --- | --- | --- | --- |
| Name the reader | scoped rule | Meaning first, zero em-dashes, no Label:fragment rows, fresh reviewer for the final voice pass | `rules/audience-aware-writing.md` |
| Doc guidelines | convention | About 33 AI-voice tells, a find-and-flag `rg` list, sentence cap of 25 words | `conventions/doc-writing.md` |
| Defect taxonomy | convention | Structure, verdict-first, contrast scaffolds, bare ids, option menus, overclaims | `conventions/language-quality.md` |
| Report genre | convention | Symptom, impact, path, detail; Dispositions table | `conventions/doc-writing.md` §16 |
| RCA, README shapes | conventions | Section order and callout budget | `conventions/rca-template.md`, `conventions/readme-template.md` |
| Slots aren't quotas | always-loaded rule | Don't fill a template slot the case doesn't have | `rules/examples-as-quotas.md` |
| guard-prose-quality | PreToolUse hook, blocks | Added lines in md/html/txt: em-dash, verdict opener, prose-lint score over 8 | `scripts/hooks/guard-prose-quality.sh` |
| doc-voice-gate | PostToolUse note, Stop block | Docs for people that read like the agent's ledger or a wall of text | `scripts/hooks/doc-voice-gate.py` |
| style watch | Stop collector + worker + hinter | Screens edited files, spends one sonnet call on a hit, delivers the verdict next turn | `scripts/hooks/style-watch-stop.sh`, `scripts/style/style-watch-worker.sh`, `hinters/02-style-watch.sh` |
| doc-writer | dispatch persona | Copywriter voice pass with a size delta | `personas/doc-writer.md` |
| readers-advocate | dispatch persona | Thesaurus-bound review of heavy reports | `personas/readers-advocate.md` |
| technical-doc-writer, greybeard, translator, pager-holder | personas | Authoring and three reader lenses | `personas/` |
| ste-writing, write-docs, feature-doc-set | skills | Plain-English rewrite, codebase docs, four-doc feature sets | `skills/` |

### Code comments

| Capability | Kind | What it does | File |
| --- | --- | --- | --- |
| Comments rule | scoped rule | Human first sentence, no plan refs or archeology, `[claude@]` notes kept separate | `rules/comments.md` |
| guard-comment-hygiene | PreToolUse, warns or blocks | Tags, plan refs, banners, emoji; blocks only in high-stakes repos | `scripts/hooks/guard-comment-hygiene.sh` |
| guard-comment-verbosity | PostToolUse, warns | Comment blocks over about 10 lines | `scripts/hooks/guard-comment-verbosity.sh` |
| cleanup-comments nudge | Stop, warns | Runs the cleanup detector on edited code at turn end | `scripts/hooks/cleanup-comments-nudge.sh` |
| /cleanup-comments | skill | Previews and applies comment pruning | `skills/cleanup-comments/` |

### Commits, PRs and GitHub text

| Capability | Kind | What it does | File |
| --- | --- | --- | --- |
| Commit style | always-loaded rule | Under 72 chars, imperative, why over what, no Claude signatures | `rules/git.md` |
| Agent marker | scoped rule + hook | Every `gh` comment carries the owner's marker | `rules/github-agent-marker.md` |
| guard-gh-prose | PreToolUse, blocks twice | Walls of text bound for GitHub | `scripts/hooks/guard-gh-prose.py` |
| Signature guards | PreToolUse + git hook, block | Claude trailers in files, commit commands and commit messages | `guard-ai-signature.sh`, `guard-commit-signature.sh`, `git-hooks/commit-msg` |
| pre-commit prose gate | git hook, blocks | Same checks as guard-prose-quality on rules, features, conventions, personas, skills and CLAUDE.md, catching text written by sed or heredoc | `git-hooks/pre-commit`, `scripts/hooks/git-prose-gate.py` |
| /pr-description | skill | PR body from the diff, no em-dashes | `skills/pr-description/` |

### Decks, Word docs and UI copy

| Capability | Kind | What it does | File |
| --- | --- | --- | --- |
| Deck and Word lints | lint CLIs in skill loops | Em-dash, triads, weasel words, walls; sentence cap 25 (deck) and 30 (Word) | `scripts/deck/lint.py`, `scripts/word-doc/lint.py` |
| Machine tokens | scoped rule | No raw codes or `[object Object]` on screen | `rules/machine-token-where-human-words-belong.md` |
| UI words | convention | No em-dashes in UI text, monospace only for code | `conventions/visual-design.md` |
| code-copy-lint | lint, via guard-prose-quality | Banned tells in user-facing string literals | `scripts/style/code-copy-lint.py` |

### Shared engines and data

| Piece | What it is | File |
| --- | --- | --- |
| prose-lint | Scoring engine behind the file and commit gates; reports, never decides | `scripts/style/prose-lint.py` |
| prose_readability | Wall and density checks shared by doc-voice-gate and guard-gh-prose | `scripts/hooks/prose_readability.py` |
| Thesaurus | 22 owner verdicts (the em-dash ban has 1,724 recorded hits) plus capped digests | `style/thesaurus.jsonl`, `style/derived/` |
| Scope map | Which artifacts get which review tier | `style/scope-map.json` |
| Glossary hints | The owner's shorthand, injected when a prompt uses it | `style/glossary-hints.tsv`, `hinters/01-glossary.sh` |
| Friction audit | Weekly pairing of agent output with the owner's reaction | `scripts/style/friction-audit.sh`, `style/friction-ledger.jsonl` |
| i-dream interventions | About ten prose-class nudges keyed to atone slugs | `i-dream/interventions.json` |
| Manual tools | struct-lint, size-delta, sweep and measure scripts; nothing calls them automatically | `scripts/style/` |

## Where they overlap

The same tell is defined in many places, each with its own wording and sometimes its own threshold:

- **Em-dash:** stated in 9 docs and checked by about 12 mechanisms (chat, files, commits, GitHub text, decks, Word, UI strings, comments, the thesaurus, an i-dream nudge).
- **"You can't see your own voice":** 8 docs, naming three different fresh reviewers with no rule for which one fires when.
- **Reply shape:** six chat rules and two index files describe checks that now live in one hook.
- **Tell catalogs:** `doc-writing.md` §3–4, `language-quality.md`, `ste-writing`, the thesaurus and the prose-lint lexicons each keep a list. `language-quality.md` says the banned-word tier merged into the thesaurus, yet `doc-writing.md` §4 still carries its own regex.
- **Comment noise:** three hooks (Pre, Post, Stop) judge the same edit with two different detectors.
- **Sentence length:** 25 words (doc-writing, deck lint), 20 or 25 (ste-writing), 30 (Word lint), tiered 25/35/50 (language-quality).

## Where they disagree

| # | Disagreement | Evidence | Likely resolution |
| --- | --- | --- | --- |
| 1 | Does chat prose-smell block? | audience-aware-writing says dry-run; language-quality says hard block; agent-policy says policy default enforce; format-gate's own header says advisory, but its code blocks on 2+ tells under `enforce`, which is the live value | Code is the truth; fix the three docs and the header |
| 2 | Em-dash budget | audience-aware-writing and pr-description: zero; doc-writing: "one per page is fine" | Zero, per the thesaurus verdict; fix doc-writing |
| 3 | Greybeard on em-dashes | Same persona calls density "not the point" and also an AI tell | Drop the first line |
| 4 | Decoration emoji | audience-aware-writing bans it; callout-boxes requires an emoji vocabulary for emitters | Say emitter emoji in boxes are exempt |
| 5 | Fresh reviewer for decks and Word | audience-aware-writing: always; deck and word-doc skills: the lint is the whole gate (owner, 2026-08-18) | Add the carve-out to the rule |
| 6 | Default register | audience-aware-writing: proper sentences (owner, 2026-10-22); write-docs: terse-technical | Rule wins; update write-docs |
| 7 | Sentence caps | Five different limits (see above) | One table of caps by surface |
| 8 | doc-writing's scope | It excludes READMEs and changelogs, yet write-docs, feature-doc-set and technical-doc-writer apply it to those | State scope once |
| 9 | "Human-first, warm" style | write-docs and technical-doc-writer say doc-writing.md defines it; doc-writing.md says no such thing | Fix the two citers |
| 10 | Filename-dot scope | CLAUDE.md: any filename; format-gate (ruling D7): only paths containing a slash | Narrow CLAUDE.md's wording |
| 11 | Em-dash in comments | guard-comment-hygiene deliberately skips it; cleanup-comments nudge flags it at turn end | Pick one |
| 12 | Same tell, different weight | A verdict opener blocks in a file but is advisory in chat | Decide per surface on purpose, in one table |

## Stale or dangling references

- `rules/audience-aware-writing.md`, `rules/dense-briefing-direct-answer.md`, `conventions/language-quality.md` and `rules-provenance/absolute-paths-at-the-reader-boundary.md` still name the six retired Stop scripts as live.
- Those six scripts (`filename-dot-stop.sh`, `emdash-stop.sh`, `relpath-stop.sh`, `prose-smell-stop.sh`, `terse-reply-stop.sh`, `dense-briefing-shapes-stop.sh`) are on disk and unregistered. The dense-briefing `.py` detector is still live through format-gate.
- `NAMESPACE.md` points to `skills/thesaurus/`; the skill is parked in `skills-parked/thesaurus/`, while readers-advocate and language-quality treat it as live.
- `skills/ste-writing/SKILL.md` cites `rules/testing.md:67`, which doesn't exist; the text is in `rules/testing-patterns.md`.
- `skills/pr-description/SKILL.md` cites stale line numbers in audience-aware-writing.
- `conventions/doc-writing.md` has two sections numbered 7, and other docs cite "§7" for the voice rule.
- `GLOSSARY.md` points "intent" at a communication.md section that moved, and points "essays / flowery" at `rules/comments.md`, which only loads for source files.
- `LOOKUP.md` has no rows for audience-aware-writing, dense-briefing, absolute-paths, language-quality or rca-template.
- `guard-banned-vocab.sh` is bound but inert: no project has a `.claude/banned-vocab.txt`.
- `style/scope-map.json` and the watcher's `tier_for` function both define review tiers, so they can drift.
- No test asserts that the prose gates stay registered in `settings.json`.

## Ways to consolidate

Status 2026-10-27: option 1 shipped for disagreements 1 to 6, 9 and 10 and every stale reference except the parked thesaurus and `guard-banned-vocab.sh` (both in option 5). Option 6 shipped: `scripts/hooks/settings-registration.test.sh` now fails if any of 11 prose gates is unbound. The owner ruled on the rest the same day (D1a D2a D3a D4a D5c, recorded in `~/.claude/assets/reports/20261027-prose-capability-scour/consolidation-plan.md`), which settles disagreements 7, 8, 11 and 12. Shipped from those rulings: `style/profiles.json` (per-surface treatment and caps), `conventions/doc-writing.md` as the standard for every human-facing doc with the old report contract as its §16, em-dash findings in `guard-comment-hygiene.sh`, and a zero-budget sweep (`scripts/style/emdash-sweep.py`) of all tracked markdown prose and code comments. The rest of the plan shipped later the same day:

- Em-dashes are gone from code strings, code examples and data too. Only ledgers, migrations and past run records keep theirs.
- `scripts/style/prose-lint.py` is now the shared engine. It reads `style/profiles.json` per surface.
- Five gates ask the engine: guard-prose-quality, git-prose-gate, guard-gh-prose, doc-voice-gate and format-gate. Parity evidence is in `~/.claude/assets/reports/20261027-prose-capability-scour/engine-build-report.md`.
- The six Stop scripts that format-gate replaced now live in `scripts/hooks/retired/`.
- `guard-banned-vocab.sh` stays bound as an opt-in list per project.
- The thesaurus skill stays parked. Its ledger stays live through `scripts/style/thesaurus.sh`.

These are options for the owner to rule on, roughly from cheapest to largest.

1. **Fix the stale and contradicting text.** The 12 disagreements and the stale references above, with no behaviour change. About 15 small doc edits.
2. **One canon for tells and thresholds.** Keep each tell's definition and threshold in one place (the thesaurus for vocabulary and patterns, plus one "caps by surface" table on this page). Every rule, convention, persona and skill links to it instead of restating it. This removes most of the overlap list.
3. **One detector library with surface profiles.** Move the regexes now split across format-gate's bash, prose-lint, prose_readability, and the deck and Word lints into one engine. Each surface (chat, doc, commit, GitHub, deck, Word, comment, UI string) gets a profile saying which tells block, warn or are ignored. The hooks become thin callers, and disagreement 12 becomes a deliberate table entry.
4. **Fold the comment trio.** One comment profile run at write time, with the Stop nudge reading its results instead of re-detecting.
5. **Retire dead weight.** Archive the six unregistered Stop scripts (their tests can stay as replay fixtures), settle the thesaurus skill's parked or live status, and drop or seed `guard-banned-vocab.sh`.
6. **Guard the wiring.** Add the prose gates to `settings-registration.test.sh` so a settings edit can't silently unbind them.
