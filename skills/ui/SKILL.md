---
name: ui
description: Routes a UI request to the one instrument that fits it, and refuses to start until an existing surface has a written capability list. The account holds a whole cluster of UI skills whose cross-references are patchy and one-directional, so the cost of getting UI help is remembering which name to type. This is the front door. Use it when the ask is about a screen and the right tool is not obvious: "make this page better", "what should this look like", "is this done", "this is confusing", "build a new settings page". Not a doer: it classifies, enforces two preconditions, and hands off.
allowed-tools: Read, Grep, Glob, Bash
argument-hint: "<what you want done, in your own words> [surface or url]"
user-invokable: true
---

## Brief

The front door to the UI toolbox. Reads an ask, names the intent, enforces two
preconditions that the account's own failure history demands, and invokes the
one skill that fits. It routes; it never designs, plans, or edits.

## Step 0: Load shared guidelines

Read `~/.claude/skills/GUIDELINES.md` and apply it for the run. Also read
`~/.claude/skills/ui/runtime-notes.md` if present; continue without it if not.

## Phase 1: Name the intent

Five intents. Pick exactly one. When two seem to fit, the tie-break is what the
user leaves with, not what they typed.

| The ask sounds like | Intent | Goes to |
|---|---|---|
| "renovate / restyle / bring X up to the design language", "X feels dated", "make this page better" | **convert** an existing surface | `/build-ui` |
| "what should it look like", "explore directions", "I don't know what I want yet" | **direct**: find a visual direction | `/ui-direction` |
| "new page", "new surface", nothing like it exists yet | **greenfield** | `/ui-direction` first, then `frontend-design` to execute |
| "make this a shared component", "every page hand-rolls this", "promote it into the kit" | **promote** a primitive | `/build-ui` (its primitive-promotion class) |
| "this is confusing", "why is this stupid", "it annoys me" | **diagnose** confusion | `/ui-gripe` |
| "is this done", "check it", "did I break anything" | **verify** | `/ui-categorical-check`, plus `/vis-compare` when a reference image exists, plus `/visual-regression` when a stored baseline exists |

Say the intent and the target out loud in one line before invoking anything, so
a wrong read costs one sentence instead of a whole run.

**Precedence, for the collision that actually happens.** Convert and direct
both claim "this feels dated and I don't know what it should look like", and
both target skills claim it in their own descriptions. The rule: **unsettled
taste goes direct first; a settled change goes convert.** If the user can name
what should be different, it is a conversion. If they can only name that
something is wrong, they need a direction before anyone plans one.

**Greenfield executes through `frontend-design`, not `web-design page`.** The
template route generates from a fixed pattern table; its `landing` row is
literally hero, features, social proof, CTA, footer, which is the templated
default the direction phase exists to defeat. The narrower truth, since the
table also holds dashboard, form, settings, auth and pricing rows that are less
generic than that: the objection is to generating a layout from a pattern table
at all when a direction memo already says what this surface should be.
`web-design page` stays the right call when the user explicitly wants a
conventional layout fast, and only then.

**One ask can hold two intents.** "Redesign this and tell me if it's broken" is
a convert followed by a verify. Route them in sequence, never blended: their
done-conditions are different and a blended run satisfies neither.

## Phase 2: The two preconditions

Both come from recorded failures in this account. Neither is skippable, and
either one failing stops the route rather than warning about it.

### 2.1 Parity: an existing surface gets a capability list first

If the target already exists and works, write the capability list BEFORE
handing off: one line per user-visible behaviour the surface has today. The
receiving skill carries it as a mandatory section, and "done" means every line
was checked against the result.

This is the account's most frequent recent failure. The atone slug is
`rebuild-replaced-accumulated-ux-without-parity-audit`, seven events in total,
four of them in the eight days before this router was written, one of those
four an S3. Sortable columns vanishing in a rewrite is one of them
(`mist-20260806-204730-d1`, S2), noticed only by the owner. Re-derive the
numbers rather than trusting this sentence:

```bash
bash ~/.claude/scripts/atone.sh search rebuild-replaced
```

A direction applied to a live surface is exactly that path.

Where to get the list: the surface's own docs or handoff, a DOM walk of the
running page, and the code. Where one already exists (a research sheet, a prior
plan), cite it instead of rewriting it.

### 2.2 Claim: detect work you did not do

Nothing on this machine attaches a session identity to an uncommitted change,
so this step cannot name who holds a file. What it can do is tell you that
somebody else is in there:

```bash
git -C <repo> status --short -- <paths>          # uncommitted work; is any of it yours?
git -C <repo> log --oneline -3 -- <paths>        # who has been committing here
```

If the diff holds work you do not recognise, the route carries two constraints
into the hand-off: targeted edits only, never a whole-file write, and a scoped
`git add` naming your own files.

**Both constraints bind only your session, and the pilot's actual loss came
from the other one.** Another session's `git add -A` swept an entire colour
conversion into a commit whose message never mentioned it. No pre-flight check
can prevent that; it is a property of the other agent's commit. So this step
buys two real things and not a third: your edits will not clobber theirs, and
your commit will not anonymise theirs. Yours can still be swept. If that
matters for this change, commit your own work early and narrowly rather than
leaving it uncommitted in a shared tree.

## Phase 3: Hand off

Invoke the chosen skill with: the intent, the target, the capability list (or
the reason there is none), the file-claim state, and the user's own words
verbatim. The verbatim ask travels with every hop, because a five-stage
pipeline drifts from the original request one paraphrase at a time.

Then stop. This skill produces no plan, no direction, and no code.

## When NOT to use

- You already know the instrument. Type it. This router exists to remove a
  recall tax, not to add a hop.
- A one-line copy or single-component fix. Just do it.
- Anything that is not a user interface.

## Done-condition

- [ ] Exactly one intent named out loud, with its target
- [ ] Existing surface: a capability list exists and travels with the hand-off
- [ ] File claim checked, and its constraints written into the hand-off when
      another session holds the files
- [ ] The user's verbatim ask travels with the hand-off
- [ ] Exactly one skill invoked, and this one wrote nothing

## See also

- `/build-ui` conversion planning · `/ui-direction` research and direction
- `/ui-gripe` confusion forensics · `/ui-categorical-check` bug classes
- `/vis-compare` fidelity against a reference · `/visual-regression` baselines
- `frontend-design` (plugin) greenfield execution · `/designer-reviewer` scored
  aesthetic critique, human-invoked by design
