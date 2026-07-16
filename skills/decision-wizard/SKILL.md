---
name: decision-wizard
description: Collect a batch of human decisions with near-zero human effort. When you are about to ask the user more than ~3 related judgments — a design review, a migration go/no-go, config triage, per-item feedback, "which of these should I…" — STOP and use this instead of serializing questions into chat. It routes to one of two surfaces: a tiny inline numbered menu the user answers in one line (for ≤3 simple picks), or a pre-answered HTML decision page served on :5197 where every item carries YOUR drafted answer + recommendation and the user flips only what is wrong, then pastes back one compact string. Supports optional per-question and end-of-form notes. Use when the user says "decision page", "decision wizard", "ask me a batch", "feedback form", "minimize the work I have to do", "answer complex forms", or any time a task would otherwise spray N questions at the user.
allowed-tools: Bash, Read, Write, Edit
user-invokable: true
argument-hint: "[what you need decided]"
---

# /decision-wizard — batch human decisions with one paste back

The trigger is a **count**: the moment you are about to ask the user more than
~3 related judgments, do not serialize them into chat and do not hand over an
empty form. Draft every answer yourself, mark one recommendation each, and let
the user flip only what is wrong. Authoring cost moves to you; the user's cost
drops to one skim and one paste.

Engine: `~/.claude/scripts/decision-page/decision-page.sh` (this skill drives it).
Schema + answer-string shape: `~/.claude/features/decision-pages.md`.

## Step 0 — route: inline menu vs HTML page

Two surfaces, one rule. **When in doubt, use the HTML page** (the user set this
tiebreaker explicitly).

```
              ┌─ ALL of these true? ──────────────────────────────┐
   inline ◄───┤ ≤ 3 questions · each a simple pick-one/either-or · │
   menu       │ no images to look at · options need no "why" blurb │
              │ · answers fit one short line · no notes likely     │
              └───────────────────────────────────────────────────┘
                                   else ▼  (or ANY doubt)
              ┌─ HTML decision page ──────────────────────────────┐
   page   ◄───┤ ≥4 judgments · needs context/recommendation text · │
              │ any screenshot · grouped items, priorities, slots ·│
              │ you want the user to annotate items                │
              └───────────────────────────────────────────────────┘
```

## Path A — inline menu (small, simple, fast)

There is **no widget and no tool call** for this — do NOT use `AskUserQuestion`
or the `mcp__inputs__*` family (they are dead in this user's `/tui` fullscreen
mode). The inline menu is just markdown you print in your reply; the user types
a short answer back. Format:

```
Quick decisions (reply with your picks, e.g. "1b 3a" — silence = all recommended):
  1. <question>?     a) <opt> ✓rec   b) <opt>   c) <opt>
  2. <question>?     a) <opt> ✓rec   b) <opt>
  3. <question>?     a) <opt> ✓rec   b) <opt>
Untouched = my recommendation. Add "1 note: …" for a free-text aside on any row.
```

Rules: exactly one `✓rec` per row; number the rows; keep each option a few
words. Parse the reply leniently — `2b`, `2 b`, `row 2 → b`, and "go"/"lgtm"
(= all recommended) all mean the same. If the reply is ambiguous, ask that one
row again inline, not the whole set.

## Path B — HTML decision page (the default for anything real)

```bash
S=my-slug   # lowercase-kebab, unique
bash ~/.claude/scripts/decision-page/decision-page.sh new "$S" \
  --title "…" --topic "one line: what this page is about" --session "<your session id>"
# → scaffolds assets/decision-pages/$S/{index.html,config.json} with an `origin`
#   block (session/project/topic/date), ensures the :5197 server, prints the TODO.
#   origin is shown on the page + hub so the user can tell YOUR page apart from
#   other concurrent sessions' pages. --session takes your friendly id (e.g. the
#   one you announced at session start); it falls back to $CLAUDE_SESSION_ID.
```

1. **Write the real `config.json`** (`assets/decision-pages/$S/config.json`).
   Start from the skeleton below; full schema in `features/decision-pages.md`.
   The contract:
   - Every `decisions[]` option group has **exactly one** `{"rec": true}`.
   - Every `sections[]` item carries your `read` + drafted `slots` — never an
     empty form.
   - `intro` states the contract: "Everything is pre-answered; untouched =
     agreed."
   - Screenshot first if the decision is visual; reference images by relative
     filename inside the slug folder.
   - **Cluster your items** with `group` on each section, and give each cluster a
     one-line `context` (and optional `color`) via `groups` — it orients the user
     fast. Set a per-page `accent` if you want the page themed.
2. **Notes are optional and default off** — see the Notes section below. Only
   set them up when you actually want the user to annotate.
3. **Verify — do not eyeball:**
   ```bash
   bash ~/.claude/scripts/decision-page/decision-page.sh check "$S"
   ```
   One call lints the schema, confirms every image exists, and checks the page
   renders (HTTP 200). Each failure prints a `fix:` line; it exits non-zero
   until `READY`. Never hand over an unchecked page.
4. **Hand off + mark pending:**
   ```bash
   bash ~/.claude/scripts/decision-page/decision-page.sh pending add "$S"
   ```
   Give the user the URL `http://localhost:5197/$S/` (hub: `:5197/`) and tell them
   to skim, flip what's wrong, then hit **Submit to Claude** (or **Copy answers**
   to paste it themselves). Also set the tab-title (Subsystem links below).
5. **Get the answer back — two paths:**
   - **Submit-to-wake (preferred):** after the handoff, watch for the human's
     Submit with the **Monitor** tool (or poll), keyed on the answer file:
     ```bash
     bash ~/.claude/scripts/decision-page/decision-page.sh answer "$S" --consume --notify
     # exits non-zero (prints "no answer yet") until they Submit; then prints the
     # exact answer string. --consume removes the file (so a re-Submit is a fresh
     # event); --notify pops a macOS banner (titled with origin.session) confirming
     # you read it. Submit also clears the pending marker for you.
     ```
     When it returns the string, apply it. The human never touches chat.
   - **Manual paste (fallback):** if they paste the string into chat instead,
     apply it and clear the marker yourself:
     `decision-page.sh pending clear "$S"`.

The page is keyboard-first (`j`/`k` move, `1`–`9` pick, `a` agree, `n` note,
`m` notes-mode, `f` show-only-changed, `c` copy, `s` submit, `?` help).
"Untouched = agreed", so a full agree is one keystroke.

## Config skeleton (copy, fill, delete what you don't need)

Everything past `title`/`decisions`/`sections` is optional. Lead with a lean page;
add `groups`/`accent`/`notes` only when they earn their place.

```jsonc
{
  "title": "Header + tab title",
  "storageKey": "my-slug",              // unique; usually the slug
  "copyHeader": "rework feedback",      // first line of the pasted/submitted answer
  "intro": "Everything is pre-answered; untouched = agreed.",
  "accent": "#7c3aed",                  // OPTIONAL per-page accent color
  "origin": {                            // OPTIONAL — `new` seeds this; edit topic
    "session": "dec-wiz-7a", "project": "~/proj",
    "topic": "what this is about", "created": "2026-07-16" },
  "groups": {                            // OPTIONAL — per-cluster helper context + color
    "API":  { "context": "land before the v1 freeze", "color": "#52bd8a" },
    "UI":   { "context": "low-stakes niceties",        "color": "#c084fc" } },
  "decisions": [                         // radio groups → answered D1a D2b …
    { "id": "D1", "question": "The call?", "context": "why it matters",
      "options": [ { "code": "a", "label": "recommended", "rec": true },
                   { "code": "b", "label": "alternative" } ] } ],
  "sections": [                          // item cards → answered id: agree/DISAGREE
    { "id": "api-01", "group": "API", "title": "Rename endpoint", "prio": "MUST",
      "read": "my read", "images": ["api-01.png"],
      "slots": { "KEEP": "…", "CHANGE": "…" } } ]
}
```

## Notes (optional — default off, keeps the payload lean)

By default no per-item note fields render and the pasted string stays minimal.
The one always-visible note surface is the end-of-form **"Notes for Claude"**
card at the bottom (the escape hatch for anything the form cannot hold) — it
renders empty and adds nothing to the paste until filled. The user can add a note
to any item on demand (focus it, press `n`, or the header **notes** toggle
reveals a field on every item). Notes only appear in the paste when non-empty.

You rarely need to configure anything. Two optional levers in `config.json`:
- Pre-seed a note on a specific item: add `"note": "…"` to that decision/section
  (renders expanded — use when you want to prompt the user for reasoning there).
- Hard-disable the whole notes surface: top-level `"notes": false` (rare).

Answer-string additions the user may send back: a `D1 note — …` line per noted
decision, a `— note` suffix on a section line, and a trailing `notes:` block for
the end-of-form field. Parse them leniently.

## Subsystem links (do these on handoff — they are cheap and they compound)

- **tab-title** — on handoff, signal you are blocked on the user:
  `~/.claude/scripts/tab-title/tab-title.sh status blocked` and
  `… focus "awaiting your call"`; clear the focus when the answer lands.
- **statusline** — `pending add`/`clear` already feeds the statusline's
  "decision waiting" chip (it reads the ledger directly). Keep the ledger honest
  and the chip stays honest.
- **WAL + workspace** — log the handoff as a `decision` WAL entry
  (`~/.claude/scripts/wal/wal.sh`) and record the page URL + the returned answer
  under the workspace **Decisions** region (`/workspace`), so the call survives
  `/clear`.
- **pin-for-dream** — if a decision revealed a non-obvious tradeoff worth
  propagating, `/pin-for-dream` it (do not derail; just pin).

## When NOT to use

- A single question, or two near-equivalent options → just ask inline in one
  line. Do not scaffold a page for one yes/no.
- The decision is genuinely open-ended discussion (no draftable options) → talk
  it through; a form would force false structure.
- You have not done the work to draft answers yet → draft first. An empty page
  or an un-recommended menu defeats the whole point (it puts the work back on
  the user).

## Efficacy checklist (before you hand anything over)

- [ ] Did I draft an answer + exactly one recommendation for every item?
- [ ] Inline only if ALL the inline conditions held; otherwise the page.
- [ ] For a page: did `check` print `READY`? (not eyeballed)
- [ ] Did I `pending add` and give the exact URL?
- [ ] Is the payload lean (no forced notes) unless notes genuinely help?
