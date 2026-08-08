# Directive tables: the nine trait families

Loaded by `build-ui` Phase 8. A trait becomes a **directive** when it has all
three of: named classes of use, a rule, and a check. A row with an empty check
cell is not a directive. It is advice, and builders skip advice.

## How to use this file

1. Copy the nine tables into the plan's **Directives** section.
2. Fill the **check** column with a command or measurement **from the target
   repo**, not the generic example given here. A check that names no real
   command is an empty cell.
3. Assign stable IDs (`D-COLOR-01`, `D-TYPE-02`). IDs never get reused or
   renumbered, because regions reference them.
4. Map every region from the skeleton to the IDs it must satisfy.
5. Delete any row that does not apply to this page, and say why in one line.

**Promotion rule.** A directive that must hold on every page belongs in the
repo's permanent gate catalog, not in a per-page plan. Move it there and cite it.

---

## 1. Color

| Class of use | Rule | Example check |
|---|---|---|
| `body` | the default ink token | no raw hex in the file |
| `quiet` | secondary text, one token, not an opacity guess | grep the file for ad-hoc opacity suffixes |
| `signal-success` / `signal-error` / `signal-warn` | status vocabulary only | status colors appear only on status elements |
| `identity` | says WHAT a thing is | never shares a scale with status |

Two hard rules that outrank the table:

- **App tokens read the semantic layer, never the palette layer.** Only the
  semantic layer flips per theme, so a palette-layer reference silently breaks
  one theme.
- **Identity is not status.** Colors saying *what a thing is* are a separate
  vocabulary from colors saying *how it is doing*. Never encode state in an
  identity color, or the reverse.

Check that catches the common failure: a legacy-token census returning zero.

## 2. Typography

| Class of use | Rule | Example check |
|---|---|---|
| `page-title` | one per page, from the shell's title component | the page renders exactly one |
| `section-label` / kicker | the house section-opener, one idiom | no second variant introduced |
| `body` | default scale | |
| `meta` | secondary, smaller | |
| `identifier` | **mono is permitted here and nowhere else** | every `font-mono` hit is an ID, SKU, hash, or code value |

The identifier rule is the one that gets violated silently, because mono looks
deliberate wherever it appears. Grep every mono usage and name what identifier it
carries; if you cannot name one, the usage is wrong.

## 3. Spacing

| Class of use | Rule | Example check |
|---|---|---|
| `page-gutter` | one value, from the container class | not set per element |
| `section-gap` | the house section rhythm | computed-style diff against a sibling |
| `control-gap` | between adjacent controls | |
| `row` | list and table row rhythm | matches the sibling page's row |

**Containers widen; prose never does.** One reading width, one prose cap, applied
by container class rather than per element.

**Carry the hazard.** Named spacing keys are not container widths. A real
instance: custom spacing keys shadowed a framework's container scale, so
`max-w-md` compiled to `max-width:16px`. If the repo's hazard ledger holds an
entry like this, quote it in the plan rather than linking it.

## 4. Categorical arrangement

| Class of use | Rule | Example check |
|---|---|---|
| `grouped-form` | labelled, scannable rows | exactly one arrangement class per region |
| `scanning-grid` | for comparison across items | |
| `single-column-flow` | for reading | |

Rules:

- **Order follows lifecycle or severity, never the alphabet**, unless the set is
  genuinely unordered.
- Sibling controls sit at **one type scale**. Mismatched scale between adjacent
  controls is a defect a human notices instantly and a DOM assertion never will.
- Counts use tabular figures, and **hide until known** rather than showing a zero
  that is really an unknown.

## 5. Hover

| Class of use | Rule | Example check |
|---|---|---|
| `inert` | no change. A legal but **explicit** choice | declared in the plan, not defaulted |
| `actionable` | color or surface transition, from the motion presets | uses a preset, not an ad-hoc transition |

Hover **never reveals essential information**. Anything hover-only is invisible
to touch and to keyboard.

## 6. Tooltip

| Class of use | Rule | Example check |
|---|---|---|
| `disambiguate` | mandatory on any ambiguous control | every icon-only control has one |
| `truncation-reveal` | the full value behind an ellipsis | |
| `forbidden` | where the label already says it | no redundant tooltips |

A tooltip is **never the sole carrier of required information**, and tooltips
carry no actions.

## 7. Interactivity

| Class of use | Rule | Example check |
|---|---|---|
| `immediate` | acts on click | owes trigger, success, and error feedback |
| `confirmed` | modal-gated | the confirm names what will happen |
| `destructive` | confirmed, and visually distinct | |

Rules:

- **Pending lives on the control that was clicked**, never as global dimming and
  never on a status badge.
- Every mutation owes three feedbacks: it started, it worked, it failed.
- A toggle is **one control that flips**, not two controls that swap.

## 8. Theme variants

| Class of use | Rule | Example check |
|---|---|---|
| `dark` / `light` | semantic tokens only, no per-component color logic | render both before calling it done |

**Both themes or neither.** A change verified in one theme is verified in one
theme; say that rather than claiming it works. Dark-only sign-offs that shipped a
broken light theme are a recurring failure in this account.

## 9. Component presets

| Class of use | Rule | Example check |
|---|---|---|
| per component | use the kit component, cited `file:line` from a sibling | no hand-rolled equivalent of an existing kit component |
| deviation | allowed, needs a reason row in the inheritance ledger | |

The whole content of a surface-conversion renovation usually lives here: native
elements become kit components, ad-hoc boxes become the card, hand-rolled buttons
become the button with its tooltip.

---

## The owner's UI law

These are gates, not directives, and they hold regardless of page:

| Law | Check |
|---|---|
| Zero em dashes in rendered UI | grep rendered string literals |
| Mono only for identifiers | every `font-mono` hit names its identifier |
| No generic loaders | every placeholder carries a readiness class |
| Static-first loading | static regions render as themselves in the boot frame |
| Mock copy verbatim | diff plan copy against the mock, where the mock covers the page |

A law breach is a blocking defect, not a finding to weigh.
