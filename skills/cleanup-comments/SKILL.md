---
name: cleanup-comments
description: >
  Prune, simplify, and remove low-value comments in changed code (or a path
  you pass) per the repo comment-style rubric. Strips [claude@] tags, plan
  refs (Phase/Tier/Track/Round), decorative banners, and archeology; rewrites
  AI-tell prose (em dashes, emojis, essays, restate-the-code comments) into
  short human comments; flags TODOs and possibly-stale claims. Previews every
  change for confirmation before applying. Never commits.
user-invokable: true
argument-hint: "[path|glob] [--changed [base]] [--all] [--apply]"
---

## Brief

Global comment janitor. Finds comments that violate the voice rules below
(and the repo's own comment-style doc if it has one), shows them grouped by
confidence tier, and applies the cleanup after you confirm. Default scope is
changed files. Covers TS/TSX/JS and Python. Works in any git repo.

The voice rules in this file are the floor. If the repo has its own comment
rubric, that doc is the higher authority and this skill enforces it. When
they disagree, the repo doc wins.

## Step 0: Load context

Find the repo's comment rubric if one exists and read it before judging. Check
these in order, use the first that exists:

- `**/comment-style.md` (e.g. `docs/**/comment-style.md`)
- a "Comment" / "Comments" section in the nearest `CLAUDE.md`
- the project's `.claude/rules/comment*.md`

If none exists, the voice rules below are the whole rubric.

If the repo has a skills harness (`.claude/skills/GUIDELINES.md`), read it and
apply its rules (forbidden paths, lock protocol, no-commit, post-run summary).
Read `.claude/skills/runtime-notes.md` if present. Skip both silently if the
repo has no such harness.

Lock reminder (when a lock script is present): acquire before every Edit,
release right after.

```bash
bash ~/.claude/skills/shared/lock-file.sh acquire "<relative/path>" "cleanup-comments"
# ... edit ...
bash ~/.claude/skills/shared/lock-file.sh release "<relative/path>" "cleanup-comments"
```

---

## The voice (how rewritten comments must read)

When this skill rewrites or shortens a comment, the replacement follows these
rules. They also gate what counts as a violation.

1. No em dashes. Use a comma, period, or parentheses. A spaced en dash reads
   the same way and is also out.
2. Minimal emojis. Zero is the target in source comments. Arrows (`->`, `→`)
   used as "maps to" notation are fine and are not emojis.
3. As short as possible. One line beats two. Two beats a paragraph. If the
   point needs a paragraph, it belongs in a doc with a one line pointer.
4. Right altitude. Do not explain what the code plainly says (the reader is
   not an idiot). Do not assume the reader has the whole system in their head
   either. Say the non-obvious why, name the thing in human terms, stop.
5. Profanity is fine, especially if the user wrote it. Never flag or remove a
   curse word. Zero is also fine. Do not add any.

---

## What gets touched, by tier

The detector (`detect.py`) emits findings in three tiers. This skill never
commits, so a human reviews every change before it lands. Lean toward applying
rather than timid flag-only: over-removing a comment is recoverable in review.
Still, do not be sloppy. Keep substance, drop noise.

### tier1_strip (mechanical, high confidence)

Apply these on confirmation. Strip the offending fragment, keep any human
substance on the line.

- `claude-tag`: `[claude@2026-05-07]` and similar. Remove the tag, keep the
  sentence if it is useful human doc. If the line was only the tag, delete it.
- `plan-ref`: `Phase 2.B8`, `Tier 1`, `Track H`, `Round 3 #1.2`. Remove the
  reference. Keep the surrounding meaning if any.
- `archeology`: `Pre-fix`, `Post-fix`, `used to be`, `See PR #1234`,
  `as discussed on`. Delete. History lives in git and PRs, not source.
- `decorative-banner`: `// ─────`. Delete a pure rule line. For a labelled
  banner (`// --- env loading ---`) keep the label as `// env loading`.

### tier2_voice (AI-tell, fix needs judgment)

Rewrite to the voice rules. Read the line in context first.

- `em-dash`: rephrase without the em dash. `a — b` becomes `a, b` or `a (b)`
  or two sentences.
- `emoji`: drop the emoji, keep the words.
- Essays (>8 lines): cut to the load-bearing why, move the rest to a linked
  doc. Find or confirm the doc target before deleting prose.
- Restate-the-code comments: delete if the code is self evident. Keep only a
  non-obvious constraint or invariant.

`detect.py` only catches em-dash and emoji mechanically. You find the essays
and restate-the-code comments by reading the changed files. If the repo has a
comment rubric, follow its before/after examples.

### tier3_flag (report only, never auto-edit)

List these with file:line. Do not touch them.

- `todo`: TODO/FIXME. Might still be live. The author decides.
- `possibly-stale`: "currently", "for now". Could be true. Cannot verify
  mechanically.

---

## Hard floor (never touch, never flag)

The detector already drops these, but enforce it again when you edit by hand:

- `NOTE(by human)`, `HACK`, `IMPORTANT` comments. Deliberate, tested choices.
- `eslint-disable`, `@ts-expect-error`, `@ts-ignore`, `biome-ignore`,
  `prettier-ignore`, `# noqa`, `# type: ignore`, pragma comments.
- License headers, `SPDX-`, copyright, shebang lines.
- JSDoc tags that tooling reads: `@param`, `@returns`, `@deprecated`, etc.
- Profanity (see voice rule 5).
- Commented-out code. Flag it for the human, do not delete it. The author may
  want it back.

If you are unsure whether a comment is load-bearing, flag it instead of
editing it.

---

## Phase 1: Resolve scope

Parse the argument string.

1. A path or glob token (`src/app/jobs`, `backend/lib/**.py`): scan exactly
   that. Pass the resolved file list to `detect.py`.
2. `--changed [base]`: scan git-changed files. Base auto-detects the repo
   default branch when omitted. This is also the no-argument default.
3. `--all`: scan all tracked source in the repo. Large. Confirm with the user
   before running, and warn that it is a big sweep.
4. `--apply`: skip the confirmation gate for tier1 and tier2 (still never
   touches tier3 or the hard floor). Use only when the user asks for it.

If the argument is ambiguous (a bare word that is neither a flag nor a real
path, or the user clearly wants a subset you cannot infer), ask with
`mcp__inputs__pick_one` or `AskUserQuestion`. Offer: changed files, a path
they type, or whole tree. Do not guess on ambiguity.

With no argument, default to `--changed`.

---

## Phase 2: Detect

Run the detector (it resolves the git repo root itself, so any CWD works):

```bash
python3 ~/.claude/skills/cleanup-comments/detect.py --changed
# or: ... <path> ...   |   ... --all
```

It prints JSON: `files[].findings[]` with `line`, `tier`, `category`,
`action`, `text`, plus `totals`. It resolves the repo root itself, so CWD
does not matter for the `--changed` and `--all` modes.

Then read the changed files yourself to find tier2 essays and
restate-the-code comments that the regex cannot see. Add them to the finding
set as `tier2_voice` / `restate` or `tier2_essay`.

---

## Phase 3: Preview

Show the findings grouped by tier, then by file. Per finding: `file:line`,
category, the current text, and the proposed result (the rewritten or
stripped line, or `[delete]`). Print tier totals at the top.

Keep the preview scannable. For tier1 strips with an obvious result, a
compact `before -> after` is enough. For tier2 rewrites, show the full new
comment so the user can judge the voice.

If `--all` produced hundreds of findings, page it: show tier totals and the
top files, then offer to apply per directory or per tier rather than dumping
everything.

---

## Phase 4: Confirm

Unless `--apply` was passed, ask before editing. Offer granularity:

- apply all tier1, all tier2, leave tier3
- apply tier1 only
- pick specific files or directories
- cancel

Use `mcp__inputs__pick_many` or `AskUserQuestion`. Respect a partial
selection.

---

## Phase 5: Apply

Acquire a lock, then edit the selected files with the `Edit` tool, one finding
at a time so each change is reviewable in the diff. Do the edits yourself; the
detector never writes files. Rules while editing:

- Re-check the hard floor on every line before you change it.
- Strip the noise, keep the human sentence. A `[claude@]` tag on a real doc
  comment loses the tag, not the doc.
- A multi-finding line (tag plus em dash) collapses into one clean rewrite.
- When you remove a whole comment line, remove the line, not just its text,
  so no blank `//` is left behind.
- Never reflow or re-indent surrounding code. Comments only.

Release the lock when done.

---

## Phase 6: Verify and report

Comments should not change behavior, but a botched multi-line edit can. Verify
the touched files still parse:

- TS/TSX/JS: the repo's typecheck if it has one (`npm run ts:build`,
  `npm run typecheck`, or `npx tsc --noEmit`). If too slow for a small change,
  at least confirm the edited files have balanced comment delimiters.
- Python: `python3 -m py_compile <file>` per touched `.py`.

Print a short summary:

- counts: N tier1 stripped, M tier2 rewritten, K tier3 flagged and left
- files modified, relative paths
- the tier3 flags as a list the user can act on
- any files skipped (forbidden path, parse failure)

Do not commit. Do not stage. Tell the user the changes are in the working tree
for their review.

---

## Post-run

Write the entry to a temp file, then prepend it (the script handles its own
lock): scope run, finding counts, any new false-positive pattern worth tuning
in `detect.py`.

```bash
bash ~/.claude/skills/shared/prepend-runtime-note.sh "cleanup-comments" /tmp/cleanup-comments-note.md
```

---

## Notes

- The split is deliberate. `detect.py` is deterministic regex for the
  mechanical tier and the two voice tells. The agent owns the judgment tiers
  by reading code. A blind sed would strip a tag and the useful sentence with
  it.
- Tuning false positives: edit the patterns in `detect.py`. It self-tests via
  `--all` against the whole tree. Eyeball `plan-ref` and `archeology` after
  any change, they are the over-match risks.
- The hard floor lives in `detect.py` (`PROTECTED`) so protected lines never
  reach the finding set. Enforce it again by hand in Phase 5 as defense in
  depth.
