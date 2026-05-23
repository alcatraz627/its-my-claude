# Runtime Notes — designer-reviewer

---

## designer-reviewer: reviewed S4 Finalize Changes (iteration 2) — copywriting deep-dive — 2026-04-11 05:40

**Purpose:** Deep copywriting and data presentation critique of scraper-success Step 4 "Finalize Changes" modal, focusing on microcopy, stat formatting, missing context, and jargon elimination.

**Insights:**

1. When a confirmation screen shows two numbers with identical formatting but different semantic weight (count vs cost), the admin cannot distinguish "how many" from "how much" at a glance — differentiate with color, unit suffix, or font weight.
2. At 100% selection, repeating the same number in value and description ("1,597 of 1,597 total") is zero-information text. Conditional descriptions that convey the semantic state ("all parts selected") are more useful.
3. The most impactful missing data on any charge-confirmation screen is the account balance — without it, the admin cannot assess affordability. Always surface this as a prop or async-loaded value.
4. "Advance job state and close modal" is a pattern of developer-speak leaking into admin UIs — always describe outcomes, not implementation mechanics. "Mark job complete and close" says the same thing in user language.
5. Safety disclaimers (no-double-charge guarantees) deserve visual prominence proportional to their importance — floating faint text under a card boundary is easy to miss. Use an Alert component.

---

## designer-reviewer: reviewed S4 Finalize Changes — copy/label focus — 2026-04-11 05:30

**Purpose:** Deep copy/text critique of scraper-success Step 4 "Finalize Changes" modal, focusing on label accuracy, description clarity, and missing information for admin decision-making.

**Insights:**

1. Past-tense labels ("Credits Charged") on pre-confirmation screens are a critical UX bug — they imply the action already happened. Always use future-tense on confirmation screens: "Credits to Charge", "Parts to Add".
2. Raw database identifiers (like `scraper_row`) leaking into stat card descriptions is a common pattern in admin tools built by engineers — add a humanization layer or at minimum a "Key:" prefix.
3. The most impactful missing information on this finalize screen is the team's current credit balance — without it the admin can't assess affordability. The `jobTitle` prop exists but is unused (`_jobTitle`), which is also a gap.
4. Per-sheet "unique parts" label is misleading because it's actually "selected parts from this sheet" — the word "unique" describes the deduplication method, not the semantic meaning for the admin.

---

## designer-reviewer: reviewed Finalize Changes (S4) wizard modal — 2026-04-11 05:20

**Purpose:** Visual critique of scraper-success Step 4 "Finalize Changes" modal — a summary dashboard with stat cards, file/sheets section, credit breakdown, and execution plan timeline.

**Insights:**

1. The modal's biggest weakness is figure-ground separation — white cards on near-white modal on white page creates a flat, low-contrast surface hierarchy. Colored top-borders on stat cards are doing all the differentiation work, which is fragile.
2. bg-slate-50/30 with border-slate-50 produces effectively zero visual contrast in light mode — this pattern only works on dark backgrounds. For light mode, use at least bg-slate-100 border-slate-200.
3. File & Sheets section takes disproportionate vertical space for reference data — compress to 1-2 summary lines or make collapsible. Credit Breakdown (decision-critical) should dominate visually.
4. Execution plan timeline placement at bottom is correct (answers "what happens next" right before CTA), but plain checkboxes read as a static to-do list rather than a pipeline — status indicators (pending/ready) would add the right "mission control" gravity.

---

## designer-reviewer: reviewed pm2-manage navbar — 2026-04-10

**Purpose:** Visual critique of pm2-manage dashboard navbar at http://localhost:5042 in GitHub Light theme

**Insights:**

1. The pm2-manage navbar has excellent token discipline and typography consistency (JetBrains Mono on all elements), but the primary CTA (Save button) has no visual distinction at rest due to a nav-group CSS override that removes the border set by the `.primary` class.
2. Mixed icon encoding (color emoji 💾🔍🔧🎨 vs Unicode symbols ⊞⊟☰▤ vs ASCII ?) is the biggest visual consistency issue — emoji render at OS-controlled sizes while Unicode symbols respect font-size, creating a misaligned icon grid at the same 12px baseline.
3. The `.seg-opt.active` text-shadow uses hardcoded `rgba(99,102,241,0.3)` (indigo), which does not track the active theme's `--accent` token — already diverged in light mode where accent is `#0969da` (blue).
4. When Chrome DevTools MCP takes screenshots with data-theme override, the result may visually appear dark due to screenshot rendering, but computed styles confirm the correct theme token values are applied — verify by inspecting computed backgroundColor, not the screenshot render.

---
