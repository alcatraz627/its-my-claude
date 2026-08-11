# ui-gripe — runtime notes

## ui-gripe: kanban gripefix re-audit (20260811-kanban-gripefix-*.png x4), 2026-08-11

**Purpose:** No-args re-audit of the agent-kanban board after a four-finding fix pass.
Target resolved by mtime (newest set in assets/screenshots). Verified the four fixes
in pixels across dark / light / filtered / drawer-min states, then walked the rubric
for new findings.

**Insights:**

1. A "gripefix" shot set taken minutes BEFORE its commit is not stale, it is the
   shoot-then-commit flow. The commit message (9541eb5) enumerated the four findings
   being fixed, which made it the re-audit baseline when no findings doc existed.
   Resolution: verify each named fix in the pixels; if they are present, the capture
   depicts the committed tree and pixel findings write flat. Three of four were
   pixel-verifiable; the fourth (tailPath shortening) had no demo path longer than
   the 26-char threshold, so it stayed code-grounded only. Say which is which.
2. I hit the `rg -rn` REPLACE-flag trap again, mid-run, despite these notes warning
   about it (the warning was read at step 0 and still did not fire at typing time).
   New tell worth keeping: match output where the matched word displays as a single
   letter ("holding the n") means `-r` swallowed your flag as a replacement string.
3. The kanban notes store is pixel ground truth for note text:
   `~/.claude/kanban/boards/<board-slug>/notes.json` holds exact bodies. Reading it
   converted a suspected two-notes-fused-on-one-line finding into an honest
   single-note truncation (the body itself was stack-test gibberish).
4. Reusable check for any UI that highlights command tokens: is the highlight
   registry-gated or shape-gated? board.html:575 chips any `/[a-z][a-z0-9-]{2,}` by
   shape, so a garbage `/skeptical-reviewasadasd` wears the same command styling as
   a real one. Shape-gated highlighting lends authority to typos.
5. Affordance census that generalizes: count pill-silhouette elements, then count
   which are buttons. Here 9 pills, 1 button (the needs-you chip), and the button's
   only distinguishers are hover brightness and a tooltip. One interactive element
   dressed in the inert vocabulary is a finding shape to keep scanning for.

---

## ui-gripe: walmart-mvp Admin ops console (admin-full.png), 2026-08-10

**Purpose:** No-gripe confusion audit of a 1280x2700 full-page light-theme staff ops
console (metric grid, live workers band, external usage, org ledger, status
distribution + recent activity).

**Insights:**

1. Read `<app>/docs/surfaces/<page>.md` before the rubric walk. It paid off in both
   directions on one page. Section 5 revealed the grey outline "Disabled" pills in the
   ledger are real `<Button onClick={toggleLiveSubmit}>` controls, which inverted a weak
   finding ("these look clickable but aren't") into a top-3 one ("the switch deciding
   whether publishes reach Walmart is dressed as an inert chip"). Its Known Gaps section
   separately pre-logged the Time-column clipping, so I reported that as confirmation
   instead of passing a known bug off as a discovery.
2. **Grid-vs-table reconciliation is the highest-yield cheap check on any dashboard**
   where a stat row sits above a per-row table. Sum every numeric table column and match
   it to its card. Here Jobs, Parts, Published and Review matched exactly (17, 242, 9,
   153) and Organizations matched the row count. Those four matches are the control
   group, and they turned "Users 65 vs Members sum 19" from a hunch into a hard finding.
   Without them it is just two unrelated numbers.
3. Root-cause a color finding in the token file, never in the component. The chip bug
   presented as "this app has no red". `index.css:30` showed `--color-signal-warn` is
   `red-600`, and four other pages already use it. The real defect was a naming
   collision: theme `signal-warn` means red, while component key `warn` resolves to
   `text-warning`, the amber. That converts a vague design complaint into a one-line fix
   with an in-file precedent sitting two rows above it.
4. **A human comment can support a finding rather than pre-clear it.** `StatusChip.tsx:7-9`
   explains why `warn` and `mid` are kept as separate keys and names the distinction the
   author wanted ("needs a look" vs "still running"), then renders both identically. Read
   the comment for intent first. Here it was evidence the collapse was unintended, not a
   `NOTE(by human)` blessing.
5. New reusable smell: **`?? []` or `?? 0` on polled data collapses "unreachable" into
   "empty"**, so the error state silently inherits the empty state's calm copy.
   `workers = activity?.workers ?? []` made a dead feed render "All workers idle."
   underneath a hardcoded pulsing green "live" dot. Grep any live dashboard for that
   pattern and ask what the empty branch asserts.
6. `--ui` was materially wrong in both directions on this shot. It invented a "Revenue"
   card, said four metric cards in LAYOUT while listing five in ELEMENTS (real answer:
   six), and hallucinated an identical `2023-04-05` date onto all 13 ledger rows. OCR
   plus native caught all three. Never let `--ui` supply a number, a date, or a count.
7. The staleness gate cleared this shot by 70 seconds (capture 13:03:16, last
   `Admin.tsx` commit 13:02:06, tree clean). Run it even when the shot looks obviously
   fresh. Clearing is what licenses writing pixel findings flat instead of hedged.

---

## ui-gripe: walmart-mvp Settings re-shoot (settings-current.png), 2026-08-10

**Purpose:** Re-audit of the same 1198x727 Settings page the previous entry abandoned as
stale. The re-shoot arrived. This pass validated it, then ran the rubric with the page
source in hand.

**Insights:**

1. The staleness gate paid off in the positive direction this time. Shot at 03:03:47,
   last commit to `Settings.tsx` at 02:30:02, tree clean. That is 33 minutes newer than
   the code, so every pixel finding was safe to write flat. Run the check to CLEAR a
   shot, not only to kill one. It converts hedged findings into confident ones.
2. New trap, and it nearly shipped a false finding. The playwright `page-*.yml` a11y
   snapshot and the PNG share a capture timestamp but are different render moments. The
   yml showed `main` holding only two headings, no member rows and no buttons, which
   reads exactly like "this whole page is invisible to assistive tech". The tell that
   saved it: the yml said `Members` while the PNG said `Members · 2`, and the source
   makes that exact string conditional on data having loaded. Before trusting any
   DOM versus pixel disagreement, find a string that differs between the two artifacts
   and check whether the source makes it state-conditional. The snapshot was mid-load.
3. Highest-damage shape this run, and a reusable check: a destructive action wearing a
   benign universal glyph. Resolve every `Icon=` on a destructive control through the
   kit's icon map to the real vendor glyph, then grep the app for what that glyph
   normally triggers. Here `Icon='SignOut'` resolves to `MdLogout` (`icon-for.ts:121`)
   and sits on "Leave this organization", while the app's actual Sign out
   (`App.tsx:235`) carries no icon at all. The only drawn logout mark in the product
   performs the one action that is not a logout.
4. My own grep bug, worth never repeating. `rg -rn "pattern"` silently returns nothing,
   because `-r` is ripgrep's REPLACE flag and it swallowed the `n`. It almost became a
   false "this app has no logout control" claim, which would have inverted finding 3's
   severity. ripgrep recurses by default, so `-r` never means recursive.
5. A project's own capability list is the cheapest guard against flagging deliberate
   design. `walmart-mvp/.claude/output/20260810-ui-renovation/CAPABILITIES.md` item 21
   pre-cleared the single Remove/Leave control as owner-ruled, so I did not flag it.
   Item 12 named the timestamp column "joined", which turned a vague hunch about a bare
   "2d ago" into a grounded gap between intent and render. Grep for a CAPABILITIES or
   parity doc before the rubric walk.
6. `--ui` failing to identify a control is itself citable evidence. It described the
   leave button only as "Icon (small red/white icon)" and left it out of its row PATTERN
   summary entirely. The enumeration layer's blindness mirrored the first-time user's,
   the same move as the 07-14 misparse insight.

---

## ui-gripe: walmart-mvp Settings page (settings-after.png), 2026-08-10

**Purpose:** General confusion audit (no args) of a 1198x727 light-theme org settings
page. Target resolved by mtime, the newest project PNG by a 2-day margin.

**Insights:**

1. **Check the screenshot's mtime against the source file's git log BEFORE writing any
   pixel finding.** This shot was 2 commits stale (01:56 vs commits at 01:58 and 02:18).
   Two "bugs" I had already confirmed by eye, a missing avatar circle and a missing
   "you" marker on the self row, were features added 22 minutes AFTER the capture.
   `stat -f %Sm` on the image plus `git log -3 -- <source>` is a two-command check that
   killed two false findings. Run it right after locating the source, before the rubric.
2. Corollary: once a shot is known stale, split findings into code-grounded (still true
   at HEAD, safe to report) and pixel-only (needs a re-shoot). Lead the report with the
   staleness. It is worth more to the caller than any single finding.
3. Highest-damage shape on a permission-aware page: a card states a prerequisite
   ("Publishing needs it"), reports it unmet ("Not connected"), then wraps the remedy in
   a role gate (`{canManage && <Button/>}`) with no else branch. The user gets a blocked
   capability, no remedy, and no reason. Grep every `{someCapability && (` that wraps a
   primary action and ask what the false branch renders. Usually nothing.
4. Copy redundancy has a mechanical check on Card components: diff the `subtitle` prop
   against the body's status string. Here both carried "optional" and "anything already
   live/published stays live", so 28 words delivered 2 facts, and the only token that
   varies at runtime ("Not connected") sat at the head of the more redundant sentence.
5. `--ui` again invented elements that were absent ("Avatar +" on both member rows).
   Third run running where it hallucinates plausible but missing visual furniture. Never
   cite an `--ui` element as PRESENT without native confirmation. It is trustworthy for
   layout regions and text, not for the existence of small chrome.
6. When the shot is stale and the dev server is down (all pinned ports returned 000), do
   not start it. That is unprompted side-effecting scope. State the limit and hand the
   re-shoot back to the caller.

---

## ui-gripe: Speedway CG setup re-audit (s2e-final-dark/light.png) — 2026-07-27

**Purpose:** No-args re-audit of the revised CG setup form ("final" pair, minutes old);
diffed against the same-day prior entry's findings before running the full rubric.

**Insights:**

1. Re-audits pay off by diffing the prior entry first: 3 of 5 morning findings were
   verifiably fixed (dark button token — crop-confirmed; composite caption; Min
   placeholder collision), which shrank the fresh pass to the truly-new surface.
2. When the audited app's source is on disk, grep converts UNCONFIRMED pixel claims
   into verdicts. Two resolved here: row-3's scope caption exists below the fold
   (setup.tsx:459 "characters per bullet · N bullets" — killed a false finding), and
   the template button label is a state-switching ternary (setup.tsx:375). The page
   lived in a SIBLING repo (speedway/, not the repo holding the screenshots) — locate
   it by grepping a distinctive caption string across the parent dir.
3. Viewport-fold vs container-clipping disambiguation: crop the bottom strip; a
   control whose border truncates exactly at the image boundary with page background
   continuing beside it is a fold cut, not a UI bug. Don't cite absence of anything
   whose home is below that line.
4. New reusable check: when a button verb disagrees with a sibling placeholder's verb
   ("Update template" beside "New template name"), grep the button's JSX for a
   label ternary — morphing labels are invisible in static shots and change the
   finding from "wrong label" to "undiscoverable state machine".
5. Guard-asymmetry check for actions targeting a default/system entity: grep the
   server lib for delete-guard vs update-guard. Here delete of the default template
   is refused but one-click overwrite is allowed (content-templates.server.ts:147
   vs :132) — a footgun finding grounded in file:line, invisible to pixels alone.

---

## ui-gripe: Speedway CG setup page (s2e-dark.png / s2e-light.png) — 2026-07-27

**Purpose:** General confusion audit (no args) of the Content Generation setup form,
dark + light; target resolved by mtime-sorting project-root PNGs — the s2e pair was
2 days newer than everything else.

**Insights:**

1. Zoom-cropping the SAME button region from both theme shots side by side caught a
   token-level bug a single-theme read would misdiagnose as taste: dark theme rendered
   secondary buttons as white-label-on-light-gray. The tell is MIXED foreground contrast
   within one control — the floppy icon had the correct dark foreground while the text
   label stayed white. Icon-vs-label contrast disagreement inside one button = an
   unadapted color token, not a design choice.
2. OCR lowercased button labels ("cancel", "save" for Cancel/Save) — Apple Vision case
   is not trustworthy; never build a capitalization finding on OCR, only on native read.
3. `--ui` invented "Bell icon + Bell with dot icon" for what is natively one stamp-like
   icon plus one bell. Icon-glyph identity claims from `--ui` need native confirmation
   before citing — it hallucinates plausible glyph pairs.
4. New recurring shape: a composite caption decoding multiple unlabeled inputs
   ("per line + line count" under three bare number boxes). Scan any form table for
   captions that name N concepts over M unlabeled inputs with N != M.
5. A placeholder ("Min") sitting beside a filled sibling value ("65") at identical
   visual weight reads as a value at a glance. Check number-input groups for
   placeholder/value weight collisions.

---

## ui-gripe: claude-ipc kanban v2 ledger (kanban-v2-ledger-dark.png) — 2026-07-24

**Purpose:** General confusion audit (no args) of the 1200x806 v2 ledger view, dark +
light; target resolved from newest screenshot pair + the active kanban-prosecutor agent.

**Insights:**

1. Mid-sentence truncation with no ellipsis was the top finding and the OCR pass is the
   cheap detector: scan row endings for a trailing comma, preposition, or article
   ("Talk to the", "spawn only at"). `--ui` re-flows text and hides where lines end;
   only `--ocr` + native show the actual cut points.
2. New scan worth keeping: count the DISTINCT numbering systems per row (ordinal, #id
   badge, source-line ref = 3 here). More than two numbers on a row with no visual
   role separation is a finding by itself.
3. Badge-slot semantic overload has a mechanical check: list every badge value from
   ELEMENTS and type them (id vs word). `#3…#9` + `USER` in the same visual slot = one
   slot, two meanings. Also check the same word rendered multiple ways ("USER" appeared
   as badge, `USER —` prefix, and `USER:` prefix on one screen).
4. Spec/annotation copy shipped in the UI ("one bar = the whole board, segments jump")
   reads exactly like a designer note. Any status-bar clause that describes the UI's
   own behavior instead of the data is suspect — OCR-verify then flag.
5. Light-theme pass earned its cost again: `DONE 4` bar label was fine in dark,
   near-invisible in light. One native Read of the sibling theme is cheap; keep doing it.

---

## ui-gripe: claude-ipc kanban board (kanban-board-real-dark.png) — 2026-07-22

**Purpose:** General confusion audit (no args passed) of a 1200x862 dark-theme kanban
board; target disambiguated from newest screenshots + the active kanban-prosecutor agent.

**Insights:**

1. A full-width `--crop` (1200x50+0+812 on a 1200px image) silently returned the FULL
   frame, same failure shape as `--region`. Inset the geometry (1100x50+50+800 worked).
   Verify every crop by reading the artifact's source.png before citing it.
2. The constant-column scan generalizes from table columns to card footers: every card
   carried the character-identical truncated chip ".claude/session-notes/0..." — zero
   information at a line of height per card. Compare card footers across cards on any
   board/list shot.
3. Unthemed native scrollbars were the single most visually dominant element on the dark
   board (near-white full-height bar) and are INVISIBLE to `--ui` — no mention in
   ELEMENTS or PALETTE. Always natively eyeball the chrome (scrollbars, viewport edges),
   not just content.
4. Column-header counts are a cheap taxonomy-truth check: INBOX 0 / BACKLOG 0 /
   BLOCKED 0 vs ACTIVE 43 / DONE 97 exposed a dead five-stage workflow in one glance.
   On any kanban/pipeline UI, read the counts row as a claim and test it.

---

## ui-gripe: Versable Speedway Review page (review-gripe.png) — 2026-07-14

**Purpose:** General confusion audit (no gripe text passed) of a 1500x900 light-theme
screenshot: review queue table with per-row inline fix inputs.

**Insights:**

1. `--region bottom` silently returned a FULL-FRAME read (it described the left sidebar) — the named-region crop did NOT crop. `--crop WxH+X+Y` does crop for real, and its artifact folder's `source.png` IS the cropped image. Reliable zoom path: `see <img> --crop WxH+X+Y --ocr` (fast, no model) → `see open -1` → `Read` the source.png. Do not trust `--region`.
2. Highest-damage finding was a **contract mismatch between a column label and its input**: col 2 declared "SMI vocabulary" (a controlled vocab) while the Fix control was free text with no chevron — while the page's OWN filter bar used chevrons for pick-from-list. Checking a form control against the page's other controls for convention consistency is cheap and high-yield; the internal pattern break IS the evidence.
3. A constant-column scan generalizes the redundancy check from the two prior runs: compare each column's values ACROSS rows. Here 4 of 6 columns were character-identical on every row, so a wide 6-col table carried one varying field. Worth doing on any list/table shot.
4. Pixel-level clipping (card border slicing a Save button in half, empty page bg below) is INVISIBLE to `--ui` — it happily enumerated all 4 rows with their Save buttons. The enumeration layer reports presence, not visual truncation. Always crop and eyeball the bottom edge of a height-capped container; a count badge that disagrees with the visible row count is the tell.
5. `prepend-runtime-note.sh <skill>` writes to the GLOBAL `~/.claude/skills/runtime-notes.md`, not `skills/ui-gripe/runtime-notes.md` — which is the file this SKILL.md tells you to read at Step 0. Entries written via the script are invisible to the next ui-gripe run. Prepend to this file directly (lock → Edit → unlock).
6. No PIL, no ImageMagick on this machine. `see --crop` is the crop tool; don't waste calls discovering that again.

---

## ui-gripe: Versable Speedway products list + peek panel (ucc-peek-open.png) — 2026-07-14

**Purpose:** General confusion audit (no gripe given) of a 1500x900 full-app screenshot: products table with a slide-out peek panel open.

**Insights:**

1. When `--ui` binds a stray token to the wrong element (it read "...Bushing Kits 95%" as one string), that misparse is itself evidence of visual ambiguity — the enumeration layer failing to associate a value mirrors the first-time user failing the same way. Worth citing in the finding, not just correcting.
2. Detail/peek panels with sections named by pipeline stage (PART DETAILS / ATTRIBUTES / DERIVED BY MODULE) reliably duplicate values across sections; the cheap check from the pricing-card run (compare ELEMENTS against itself for repeated values) generalizes and found the top finding here.
3. `--ui` produced three near-miss strings on this shot (`parts_.master.csv`, "Untyped/Unclassified", "DERIVED FROM MODULE"); `--ocr` corrected all three. On dense app UIs, run OCR before quoting ANY panel label, not just the suspicious ones.
4. Full-frame reads sufficed at 1500x900; no `--region` crop needed even for the 25%-width panel.

---

## ui-gripe: pricing-card confusion audit (Langfuse-style "Core" plan) — 2026-07-10

**Purpose:** General confusion audit (no gripe given) of a 275x593 crop of a single pricing card.

**Insights:**

1. On pricing cards the highest-damage rubric item is label opacity in the usage-price line, not hierarchy — `see --ui` HIERARCHY was clean while the cost string was unparseable.
2. `see --ui` reproduced the odd string "$8-6/100k" verbatim; `--ocr` confirmed it is real UI copy, not an OCR near-miss. Always run `--ocr` before calling a weird string a bug in the UI vs a bug in the read.
3. Narrow single-card crops don't need `--region` passes; the full-frame `--ui` + `--ocr` pair was sufficient evidence.
4. Redundancy detection (paragraph repeating bullet content) falls out of comparing the ELEMENTS list against itself — cheap check worth doing on marketing/pricing surfaces.

---
