---
name: mock-app
description: Builds a checked, clickable HTML mock of an app before native or production work, and renders N variants of a taste call as a gallery on one decision page. Use when a screen or visual choice needs the owner's eye. Not for a page that already exists (use /ui) or a plain question.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
user-invocable: true
argument-hint: "<mock | variants> <app or element> [--out DIR]"
---

## Brief

`/mock-app` gives the owner something to look at instead of something to read. It has two modes. `mock` builds a clickable HTML model of a whole app, with every screen drawn by one shared kit, so the owner can walk it before any native or production code exists. `variants` renders three to six candidate looks for one taste call as images on a decision page, so the owner picks or composes by looking. Prose is a poor surface for taste: nobody can judge "11px uppercase tracked" from a sentence, but six rendered cards decide at once.

## Step 0

Read `~/.claude/skills/GUIDELINES.md` and the `## mock-app:` entries in `~/.claude/skills/runtime-notes.md`. Read `~/.claude/features/decision-pages.md` for the config schema, and `~/.claude/skills/decision-wizard/SKILL.md` for the page flow this skill reuses. If a mock for this app already exists, read it before adding to it.

## Usage

```
/mock-app mock <app>              build the whole-app mock, review shell and checks
/mock-app variants <element>      render N variants of one visual call and put them on a decision page
/mock-app variants <element> --out DIR   keep the variant sources and renders under DIR
```

Default output is `<project>/assets/<app>-mock/` for a mock and `~/.claude/assets/decision-pages/<slug>/` for variants. Use absolute paths in every reply.

## Picking the mode

A whole app or flow with several screens means `mock`. One element, one screen, or one style question means `variants`. A visual question that comes up inside a mock round is a `variants` run, and its ruling goes back into the mock's decisions doc.

## Building the mock

The worked example is the csync Android mock at `/Users/alcatraz627/Code/Claude/csync/assets/android-ui-mock/` (when present). Reproduce its contract, not its files.

1. **A place map.** One model file lists every place in the app. Every breadcrumb, Back target and nav highlight is derived from it, never typed on a screen.
2. **One kit.** Parts and screens may only call the kit. A source audit fails any screen line that carries its own tag, class or inline style. The audit is a script that runs, not a guideline.
3. **A review shell around the device frame.** A rail listing every place, state toggles, the sheets each screen opens, a wall showing every frame at once, and a design-system view drawn by the parts themselves.
4. **Checks over every frame.** One `runChecks()` pass covers every frame in both themes and three text sizes: tap size, overflow, vocabulary, dead taps, the filled-button rule. Prove each check by mutation: plant the defect, watch the check go red, restore, watch it go green.
5. **A tap crawl.** A breadth-first walk over the tappable elements, run on state snapshots, finds the dead ends the checks cannot.
6. **Contact sheets.** Screenshot the wall in dark and light with headless Chrome, read each image back, and describe what is on screen before judging it. Cite the image paths. A passing check is not a look.
7. **Taste calls go to variants.** A choice between looks is a `variants` run, and the ruling is written into a decisions doc beside the mock.

Document the place model, the kit and the decisions in short docs next to the mock, so the next agent extends the same system.

## Rendering variants

1. **Name the channels.** Write down the visual channels the call can vary (size, weight, case, color, position, marker, density). Each variant changes a stated set of channels and the card says which. Two elements read as the same kind of thing when they differ on one channel, and as different kinds at three or more, so choose variants to land on the side the owner intends.
2. **Draw a reference card first.** It reproduces the current look with MEASURED computed values (read from the live page, not remembered), so every variant is judged against what exists.
3. **Render three to six variants** as self-contained HTML with a dark and light toggle, one file per variant. Screenshot each in both themes with headless Chrome and read the images back before showing anyone.
4. **Put them on one decision page.** Use the decision wizard's gallery: an option with `images` becomes a tile and the group becomes a visual pick-one-of-N. Mark exactly one `rec`, include the built-in "none of these" option, and add a notes field. No new server is needed.
5. **Let the owner compose.** The owner may name parts across variants ("variant 4's marker with variant 2's rail"). Accept that as a ruling, render the composition as one more image, and confirm it before building.
6. **Record the ruling** in the artifact it binds, not only in chat.

## Boundaries

- Do not publish the mock or the gallery to a hosted page. The decision page is local.
- Do not mock a page that already exists. Write its current behaviour down and use `/ui`.
- Do not scaffold a generator or a build pipeline for the mock. Plain files the owner can open are the deliverable.
- Variants that differ on every channel at once teach the owner nothing. Vary named channels.

## Validation

Efficacy is whether the owner decides by looking and the decision survives into the build. Checks: (1) every variant image exists, was read back by you, and appears in both themes, listed by path in the reply; (2) the decision page passes `decision-page.sh check <slug>` and shows a reference card with measured values; (3) for `mock`, the source audit and `runChecks()` each have a recorded mutation that turned them red, and the contact sheets were read in dark and light.

## Runtime notes and ledger

Prepend a `## mock-app:` entry with `bash ~/.claude/skills/shared/prepend-runtime-note.sh mock-app <entry.md>` when the run taught something. Then `bash ~/.claude/scripts/skill-log.sh record mock-app --task "<what was mocked>" --outcome unknown --corrections 0 --note "mode=<mock|variants> variants=<n>"`.
