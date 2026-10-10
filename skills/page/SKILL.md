---
name: page
description: Routes anything that has to be shown to the surface that fits it (a markdown file, a local HTML page, a decision page, an Artifact, a deck) and makes sure an HTML page is built on the shared kit and passes the page check. Use when something needs showing and the form is not obvious, such as "make me a report", "show me a preview", "write it up", "I need a page for this", "share this with the team". Not a designer. It picks the surface, hands off, and checks the result.
allowed-tools: Read, Grep, Glob, Bash, Write, Edit
argument-hint: "<what needs showing, and to whom>"
user-invocable: true
---

## Brief

The front door for showing something. It names the surface, builds or hands off, and runs the check. The rule, the kit and the check are described once, in `~/.claude/conventions/pages.md`. Read that file first, every run.

## Usage

```
/page <what needs showing, and to whom>
/router:page <the same>
```

## Phase 1: Name the surface

Ask two things: who opens it, and does it need an answer back. Pick the first row that fits.

| Who opens it | Needs | Surface | Goes to |
|---|---|---|---|
| Only the owner | Plain reading | A markdown file | Write the `.md`, and give its absolute path |
| Only the owner | Layout, tabs, or something to click | A local HTML page | Phase 2 |
| The owner must answer something | Picks, rulings, notes | A decision page | `/decision-wizard` |
| Someone else | Anything | An Artifact | Phase 2, then Phase 4 |
| A room, from a screen | Slides | A deck | `/deck` |
| A Word or Google document is asked for by name | | | `/word-doc` or `/gdoc` |

Say the surface in one line before doing anything, so a wrong pick costs one sentence.

When the ask is about how an existing screen of a product looks or behaves, this is the wrong door. Use `/router:ui`.

## Phase 2: Build on the kit

1. Write the content as markdown first. It is the source, and the page is made from it.
2. Build the page:
   ```
   uv run --with markdown python3 ~/.claude/scripts/pages/pagekit.py <in.md> <out.html>
   ```
   A page that needs tabs or its own behaviour imports `pagekit` and calls `page()`.
3. Put the output in the project, under `.claude/output/<date>-<slug>/`, unless the owner named a place.

Never write colours on an element, and never write a page without the theme switch. The kit carries both.

## Phase 3: Check

```
uv run --with playwright python3 ~/.claude/scripts/pages/check_page.py <out.html> --out <folder>
```

- On FAIL, fix the page and run it again. Report the failing line if it cannot be fixed.
- On PASS, read both screenshots it saved. A pass means the page works, not that it reads well.

## Phase 4: Publish, only when asked

A local page and an Artifact are the same file. Publishing needs the owner's own words asking for a hosted page in this conversation (`rules/no-unasked-artifact-publish.md`). Without them, give the local path and offer the page in one sentence.

## Boundaries

- It does not design. For a visual direction, use `/ui-direction`.
- It does not publish unasked.
- It does not replace `/deck`, `/decision-wizard`, `/word-doc` or `/gdoc`. It sends work to them.

## Validation

A run is good when all of these hold:

| Check | How |
|---|---|
| The surface was named before any file was written | It is in the reply |
| An HTML page was built through `pagekit` | The file carries `kit-page` |
| The page check passed | The PASS line is quoted in the reply |
| Both theme screenshots were read | Their paths are cited |
| Nothing was published without being asked for | No Artifact call without the owner's words |
