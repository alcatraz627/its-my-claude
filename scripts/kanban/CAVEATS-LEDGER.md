# Carried caveats, exercised (#60)

Each row is one of the caveats the 2026-08-23 checkpoint carried forward. A row
retires when something was actually RUN and a positive assertion held, not when
it was reasoned about.

## Exercised 2026-08-24

### Composite control states (charter §7) — EXERCISED, and it found something

§7: "hover, focus-visible, active, on and disabled are five different
appearances. A control with only two of them is unfinished."

Audited by reading every selector in `board.html` and `shared.css` (370 of
them) rather than by poking the CSSOM, which kept misreporting. Per-class
counts overstate the problem, because most of these controls ARE `<button>`
and inherit `button:focus-visible` and `button[disabled]` from the base.

**The real finding: `:active` is absent.** Two declarations exist in the whole
tree — `.notestack .nrow:active` sets a grab cursor and `.bprow:active` sets a
background. No button, chip, tab, card, view row or radio option has a pressed
appearance anywhere on any page.

So by §7's own sentence every one of them is unfinished, and it is the same
state missing every time. That is a one-rule fix in `shared.css` rather than
ten, which is the useful shape of the answer:

```
button:active,.chip:active{transform:translateY(.5px);filter:brightness(.97)}
```

Not applied here: it is a look change on every control at once, which belongs
in a pass the owner sees (#16's §17 round), not in a caveats sweep.

## Still carried, with the reason

| caveat | why it is still open |
|---|---|
| `prefers-reduced-motion` | The browser tool exposes no reduced-motion emulation (`emulate` offers colour scheme, CPU, network, viewport, UA, geolocation). Verified instead that exactly ONE rule survives, in `shared.css`, with `!important` on both durations, and that board.html's seven local copies are gone. The media query itself has still never fired. |
| concurrent edits to one note body | Needs two clients writing the same note. One browser context was available; setting up a genuine race is a fixture, not an observation, and a fixture that cannot race proves nothing. |
| doc viewer after `renderMd` | `renderMd` has not changed yet — that is #13 step 5. Nothing to re-check until it does. |
| light-theme sweep | Every change this session was read back in both themes, but that is per-change, not the per-element sweep §17 asks for. It retires with #16, not before. |
| nudge to a live peer | Needs a second session alive to receive it. `claude-ipc peers` showed none all session. |

## The instrument note

Two probes lied this session before the grep told the truth: the CSSOM walk
returned 3 rules for a page with 370, and an earlier one measured a stylesheet
I had mutated during my own debugging. When a probe disagrees with something
you can read directly, read it directly.
