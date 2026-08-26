---
name: router
description: One prefix for the five routers. /router:pick-skill (find the instrument) · /router:plan (how to approach) · /router:ui (any screen) · /router:validate (before calling it done) · /router:intake (model the ask first).
user-invocable: true
---
# /router — the five routing skills, one place

| When | Skill |
|---|---|
| The right instrument is not obvious, or you half-remember one | `/router:pick-skill` |
| A plan is wanted and the right planner is not obvious | `/router:plan` |
| Anything about a page or screen | `/router:ui` |
| A change is about to be called done | `/router:validate` |
| Before non-trivial work, to model what the wording exemplifies vs specifies | `/router:intake` |

Each `/router:<name>` is the same skill as `/<name>` (the directories are links), so
there is one copy to maintain. Bare `/router` prints this table and hands off to
`/router:pick-skill` with your words as its argument.
