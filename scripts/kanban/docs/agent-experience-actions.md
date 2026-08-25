# Kanban agent-experience action script

**What this is.** A repeatable, narrated action script that exercises every verb,
HTTP route, and lifecycle rule of the kanban board system
(`~/.claude/scripts/kanban/{cli.ts,lib.ts,harvest.ts,server.ts,board.html,hub.html}`,
driven via `kanban.sh`). It plays out a realistic scenario — building a todo app,
managed on the board — so coverage reads as a story, not a checklist. It doubles as
the system's standing agent-UX regression test: re-run it after any change to the
kanban scripts to confirm nothing in the agent-facing contract silently broke.

**How to re-run.** Every action is parameterized on `$PROJECT` (the fixture
project root) and `$SLUG` (the board's slug, captured from `init`'s own output —
never hardcoded, since it's a content hash). Phase 0 sets sane defaults. For a
fully clean repeat run, run Phase 10 (teardown) first, or export a fresh
`PROJECT` path (e.g. suffix it with `$(date +%s)`) before starting — reusing the
same `$PROJECT` without teardown is safe for the file-scaffolding steps
(everything gets overwritten) but leaves prior notes/acks/overrides in place,
which will throw off the exact-count assertions in Phase 2 and Phase 7.

**Ground truth.** Every expected outcome below was derived by reading the actual
source (not guessed): `cli.ts` verb handlers, `lib.ts` (`mergeSync`, `cardId`,
`canonicalRoot`, `withBoardLock`), `harvest.ts` (`laneForHeading`, `splitTag`,
`parseCheckboxFile`, the dedupe-by-title pass, the 14-day checkpoint decay), and
`server.ts` (`/api/note` validation order, `/doc` allowlist + traversal checks).
Design decisions D1a–D7a referenced below are from
`~/.claude/assets/reports/20260721-kanban-board-design/DESIGN.md`.

**Execution note (for whoever authored this file):** read-only grounding only —
these commands are written to be run by a *simulation agent*, not executed here.

---

## Phase 0 — Variables, helpers, prerequisites

```bash
# Fixture project root. Override via env if you want a fresh run without
# tearing down a previous one.
PROJECT="${PROJECT:-$HOME/.claude/scratchpad/kanban-uxtest-todo-app}"
mkdir -p "$PROJECT"
REALROOT="$(cd "$PROJECT" && pwd -P)"   # canonical realpath — checkpoint pointers must match this exactly
CKROOT="$HOME/.claude/checkpoints"
mkdir -p "$CKROOT"

KSH() { bash "$HOME/.claude/scripts/kanban/kanban.sh" "$@"; }   # function, not a string: survives zsh's no-word-split

# Card-id lookup by exact title (ids are content-hash — never hardcode them).
# Assumes no fixture title contains the literal substrings "] " or " (".
id_for() {
  KSH status --project "$PROJECT" --cards | grep -F "] $1 (" | awk '{print $1}'
}

# URL-encode a query param (path may contain slashes/spaces).
urlenc() { python3 -c "import urllib.parse,sys;print(urllib.parse.quote(sys.argv[1]))" "$1"; }

# Kanban server port, read live via the CLI (not by reading server.json by hand).
KPORT="$(KSH status --project "$PROJECT" | head -1 | grep -oE 'port [0-9]+' | grep -oE '[0-9]+')"   # no 2>/dev/null: a broken helper must fail loudly, not read as "server down"
if [ -z "$KPORT" ]; then
  echo "kanban server not configured/running — run: KSH check   (it prints the exact fix)"
  exit 1
fi
```

- **Exercises:** none directly — this is scaffolding for every phase below.
- **Expect:** `$KPORT` is a nonempty port number (the pm2 `kanban` service is a
  standing tier-2 hub per D1a — it should already be running before this script
  starts; this script does not start it).

---

## Phase 1 — Scaffold the todo-app fixture project

Every file below is read by a specific harvester code path in `harvest.ts`. Each
action names which one.

**1.1 — `docs/plan.md`: heading→lane rules, tags, markdown-stripping, checked-overrides-heading, auto doc-link, unrecognized heading**

```bash
mkdir -p "$PROJECT/docs"
cat > "$PROJECT/docs/plan.md" <<'EOF'
# Todo App — Plan

## In Progress
- [ ] Build task list UI component
- [x] Initialize repo and CI

## Blocked
- [ ] (#7) Fix **login** redirect loop in `AuthGuard`

## Backlog
- [ ] OWNER REVIEW: confirm signup copy
- [ ] Update onboarding flow copy — see [content brief](./onboarding-content-brief.md)

## Parking Lot
- [ ] Investigate GraphQL vs REST for API layer
EOF
```

- **Exercises:** `laneForHeading` (In Progress→active, Blocked→blocked,
  Backlog→backlog, unrecognized "Parking Lot"→inbox — never guess);
  checked-checkbox-overrides-heading (`Initialize repo and CI` is checked under
  "In Progress" but must land in **done**, not active); `splitTag`'s two tag
  grammars (`(#7)` → tag `#7`; `OWNER REVIEW:` → tag `OWNER REVIEW`);
  markdown-emphasis stripping (`**login**` and `` `AuthGuard` `` must not appear
  literally in the card title); `docLinks` auto-extraction of an inline markdown
  link to an existing sibling `.md` file.
- **Expect:** 6 cards from this file at next sync (2 In Progress → 1 active + 1
  done, 1 Blocked → blocked, 2 Backlog → backlog, 1 Parking Lot → inbox).

**1.2 — reference docs (prose-only, prove the harvester scans-but-skips non-checkbox `.md` files)**

```bash
cat > "$PROJECT/docs/onboarding-content-brief.md" <<'EOF'
# Onboarding content brief

Copy direction for the onboarding flow. Plain reference doc, no checkboxes —
exists to prove the harvester scans every docs/*.md file even when a file
contributes zero cards.
EOF

cat > "$PROJECT/docs/login-notes.md" <<'EOF'
# Login redirect investigation notes

Repro steps and findings for the (#7) redirect-loop bug live here. Plain
reference doc, deliberately no checkboxes.
EOF
```

- **Exercises:** `globDocs` picking up every `.md` under `docs/`, not just
  `plan.md`.
- **Expect:** both files appear in the sync digest's "scanned" count but produce
  zero cards. `login-notes.md` is also the target for the explicit `link` verb
  test in Phase 3.

**1.3 — `TODO.md`: nested sub-checkboxes (card + 2-level subs)**

```bash
cat > "$PROJECT/TODO.md" <<'EOF'
# TODO

## Now
- [ ] Wire up drag-and-drop reordering
  - [ ] Add drag handles to task rows
  - [x] Persist new order to backend
EOF
```

- **Exercises:** `parseCheckboxFile`'s indent-stack nesting — the two indented
  checkboxes become `subs[]` entries on the parent card, not their own cards;
  "Now" matches the active-lane keyword regex.
- **Expect:** 1 card ("Wire up drag-and-drop reordering", lane active) with
  `subs: [{title:"Add drag handles to task rows", done:false}, {title:"Persist
  new order to backend", done:true}]` — a `1/2` progress chip in the UI.

**1.4 — `package.json`: doubles as the `/doc` 415 (non-md) fixture later**

```bash
cat > "$PROJECT/package.json" <<'EOF'
{
  "name": "todo-app",
  "private": true,
  "version": "0.1.0"
}
EOF
```

- **Exercises:** nothing at harvest time (not a target file for any harvester
  path) — it exists purely so Phase 8 has a real, allowlisted, non-`.md` file to
  hit the doc-viewer's extension check with.

**1.5 — `.claude/session-notes/_active.md`: the `## Todos` block, checked items, dedupe target**

```bash
mkdir -p "$PROJECT/.claude/session-notes"
cat > "$PROJECT/.claude/session-notes/_active.md" <<'EOF'
# Session workspace

## Todos
- [x] Set up local dev environment
- [x] Wire the signup email verification flow

## Notes

## Doc Links

## Decisions
EOF
```

- **Exercises:** session-notes harvesting only counts checkboxes under a heading
  literally starting with "Todos" (`/^todos\b/i`) — the empty Notes/Doc
  Links/Decisions headings that follow must NOT contribute cards; session-notes
  lane rule is binary (checked→done, unchecked→active), heading text is ignored
  for lane purposes.
- **Expect:** 2 cards, both done. "Wire the signup email verification flow" is
  the freshest copy of a title that also exists (unchecked) in checkpoint A
  below — this is the cross-file dedupe-by-recency fixture, verified in Phase 7.

**1.6 — checkpoint A: recent (3 days old), dedupe-losing pending item**

```bash
cat > "$PROJECT/_checkpoint-A.claude.md" <<'EOF'
# Checkpoint — sprint 1 handoff

## Pending Items
- [ ] Wire the signup email verification flow
EOF
touch -t "$(date -v-3d +%Y%m%d%H%M)" "$PROJECT/_checkpoint-A.claude.md"

cat > "$CKROOT/kanban-agentux-ckpt-A.json" <<EOF
{
  "session_id":      "$(uuidgen)",
  "session_uuid":    "",
  "project_root":    "$REALROOT",
  "checkpoint_path": "$REALROOT/_checkpoint-A.claude.md",
  "name":            "kanban-agentux-sprint1-handoff",
  "summary":         "Sprint 1 handoff -- fixture for the kanban dedupe-recency test",
  "kind":            "manual",
  "ts":              "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
```

- **Exercises:** `parseCheckpointFile` (heading matches `/pending|next step|open
  item|todo/i`, unchecked bullet → active-lane card); the checkpoint-pointer
  scan in `harvest()` (`project_root` must equal the canonical realpath of
  `$PROJECT` exactly, or the pointer is silently ignored — the `touch -t`
  3-days-ago mtime keeps this file *older* than `_active.md`, so it's the one
  that loses the freshness tiebreak in Phase 7's dedupe check).
- **Expect:** absorbed into the "Wire the signup email verification flow" card
  from 1.5 at sync time — contributes 0 *net* new cards (dedupe merges it away),
  but its file is counted in the "scanned" total.

**1.7 — checkpoint B: age-decayed (>14 days), must be skipped entirely**

```bash
cat > "$PROJECT/_checkpoint-B-stale.claude.md" <<'EOF'
# Checkpoint — early spike (frozen)

## Pending Items
- [ ] Old spike: evaluate websocket library for live sync
EOF
touch -t "$(date -v-20d +%Y%m%d%H%M)" "$PROJECT/_checkpoint-B-stale.claude.md"

cat > "$CKROOT/kanban-agentux-ckpt-B.json" <<EOF
{
  "session_id":      "$(uuidgen)",
  "session_uuid":    "",
  "project_root":    "$REALROOT",
  "checkpoint_path": "$REALROOT/_checkpoint-B-stale.claude.md",
  "name":            "kanban-agentux-early-spike",
  "summary":         "Early spike checkpoint -- fixture for the >14d age-decay skip",
  "kind":            "manual",
  "ts":              "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
```

- **Exercises:** the `ageDays > 14` skip in `harvest()` — this checkpoint must
  never produce a card, in this sync or any later one, as long as its mtime
  stays >14 days old.
- **Expect:** appears in the sync digest's `SKIPPED` list annotated
  `(20d old, age-decayed)`; "Old spike: evaluate websocket library..." never
  appears anywhere on the board. Verified explicitly in Phase 7.

---

## Phase 2 — Init the board, verify idempotent re-sync

**2.1 — `init`**

```bash
INIT_OUT="$($KSH init --project "$PROJECT")"
echo "$INIT_OUT"
SLUG="$(echo "$INIT_OUT" | grep -oE 'board ready: [a-z0-9-]+' | awk '{print $3}')"
echo "SLUG=$SLUG"
```

- **Exercises:** `registerBoard` (registry.json write, slug = `sha1(canonical
  root)[:12]`-derived per `slugFor`), the first `mergeSync`, and the full
  harvest pipeline from Phase 1 in one pass.
- **Expect:** `SLUG` is nonempty. The digest line reads (counts derived from
  Phase 1's fixtures): `9 new, 0 moved, 0 unchanged, 0 gone, 0 kept-as-stale ·
  notes preserved: 0 · scanned 6 files · SKIPPED 1: .../_checkpoint-B-stale...
  (20d old, age-decayed)`. 9 = 6 (plan.md) + 1 (TODO.md) + 2 (_active.md); the
  1 pending item from checkpoint A is absorbed into the dedupe, contributing 0
  net.

**2.2 — idempotent re-sync (no fixture changes)**

```bash
$KSH sync --project "$PROJECT"
```

- **Exercises:** `mergeSync`'s stability — running sync twice with no source
  changes must not create, move, or drop anything.
- **Expect:** `0 new, 0 moved, 9 unchanged, 0 gone, 0 kept-as-stale · notes preserved: 0 ·
  scanned 6 files · SKIPPED 1: ...`. Same skip line reappears every sync since
  checkpoint B's mtime doesn't change.

---

## Phase 3 — Sprint 1: build the initial backlog

**3.1 — `add` without `--lane` (defaults to inbox)**

```bash
$KSH add "Write integration tests for task CRUD API" --project "$PROJECT"
```
- **Exercises:** `add`'s default lane when `--lane` is omitted.
- **Expect:** `added <id> to inbox on $SLUG`.

**3.2 — `add` with `--lane`**

```bash
$KSH add "Add task due-date picker" --lane backlog --project "$PROJECT"
$KSH add "Investigate CI flakiness" --lane backlog --project "$PROJECT"
```
- **Exercises:** `add --lane`, and `cardId("manual", title)` — manual-card ids
  hash on `"manual#" + normalized title`, distinct from any doc-sourced id even
  for an identical title.
- **Expect:** both added to backlog. These plus 3.1 are the 3 manually-created
  tasks; combined with the 8 doc/session/checkpoint-harvested cards from Phase
  1, the board now carries ~11 real tasks (UI: task list, drag-and-drop,
  due-date picker; backend: login redirect fix, signup email verification,
  CRUD integration tests, CI flakiness, onboarding copy, signup copy review).

**3.3 — duplicate `add` error**

```bash
$KSH add "Investigate CI flakiness" --lane backlog --project "$PROJECT"
echo "exit=$?"
```
- **Exercises:** the `cardId` collision check in `add` — two manual cards with
  the same normalized title collide (same hash), independent of `--lane`.
- **Expect:** `kanban: card <id> already exists\n  fix: kanban.sh move <id>
  <lane>`, `exit=1`. No second card created.

**3.4 — `link` (explicit doc attach)**

```bash
FIX7_ID="$(id_for "Fix login redirect loop in AuthGuard")"
$KSH link "$FIX7_ID" docs/login-notes.md --project "$PROJECT"
```
- **Exercises:** the `link` verb's root-relative path handling (distinct from
  `docLinks`' automatic in-checkbox-line extraction, which Phase 1.1 already
  covers on a different card).
- **Expect:** `linked docs/login-notes.md to <id>`; `docs: []` → `docs:
  ["docs/login-notes.md"]` on that card.

**3.5 — `status` (all boards) and `status --cards` (this board)**

```bash
$KSH status
$KSH status --project "$PROJECT" --cards
```
- **Exercises:** `status`'s two modes — the bare form lists every registered
  board machine-wide (will include unrelated real boards already in the
  registry, not just this fixture); `--cards` requires `--project` to resolve
  which board, and lists every card's id/lane/title/source.
- **Expect:** bare `status` shows `boards: N` with N ≥ 1 (this fixture plus
  whatever else is registered); `--cards` lists 11 lines for this board.

---

## Phase 4 — User feedback arrives, agent triages

Every `POST /api/note` below is the sim agent **wearing the [user] hat**
(standing in for the human, who would normally do this from the browser
drawer's textarea). Every CLI action that follows is the sim agent **wearing
the [agent] hat**, per D5a: notes are pull-only, never injected — the agent
only acts on them when it looks.

**4.1 — [user hat] positive note on a UI card**

```bash
UI_ID="$(id_for "Build task list UI component")"
curl -s -X POST "http://localhost:$KPORT/api/note" \
  -H 'content-type: application/json' \
  -d "{\"slug\":\"$SLUG\",\"cardId\":\"$UI_ID\",\"note\":\"Looks great in the demo -- ship it.\"}"
```
- **Exercises:** `POST /api/note` happy path (create).
- **Expect:** `{"ok":true,"savedAt":"..."}`. `notes.json` gains an entry keyed
  by `$UI_ID`.

**4.2 — [user hat] prioritization request on a blocked bug**

```bash
FIX7_ID="$(id_for "Fix login redirect loop in AuthGuard")"
curl -s -X POST "http://localhost:$KPORT/api/note" \
  -H 'content-type: application/json' \
  -d "{\"slug\":\"$SLUG\",\"cardId\":\"$FIX7_ID\",\"note\":\"Customers are hitting this in prod, please bump priority.\"}"
```
- **Exercises:** same route, second independent note.
- **Expect:** `{"ok":true,...}`.

**4.3 — [agent hat] pull unread notes, act, ack**

```bash
$KSH notes --unread --project "$PROJECT"
```
- **Exercises:** `notes --unread` filtering by `ack.lastAckTs` (0 initially, so
  both notes are unread).
- **Expect:** both 4.1 and 4.2's notes printed, each as `[<id>] <title>\n
  <note text> (<timestamp>)`.

```bash
$KSH move "$FIX7_ID" active --project "$PROJECT"
```
- **Exercises:** `move` valid-lane happy path; this is the task-shaped-note
  case from D4a ("a note can request a card change and the agent applies it").
- **Expect:** `moved <id> → active (override recorded; survives sync)`;
  `board.overrides[$FIX7_ID] = {lane:"active"}` persists.

```bash
$KSH notes --unread --ack --project "$PROJECT"
```
- **Exercises:** the `--ack` write path.
- **Expect:** prints the same 2 notes, then `acked 2 unread`; `ack.json`'s
  `lastAckTs` advances to now.

```bash
$KSH notes --unread --project "$PROJECT"
```
- **Expect:** `no unread notes on $SLUG` (both notes are now older than
  `lastAckTs`).

**4.4 — [user hat] deprioritization note + [agent hat] move → override-survives-sync check**

```bash
DND_ID="$(id_for "Wire up drag-and-drop reordering")"
curl -s -X POST "http://localhost:$KPORT/api/note" \
  -H 'content-type: application/json' \
  -d "{\"slug\":\"$SLUG\",\"cardId\":\"$DND_ID\",\"note\":\"Nice to have -- push this to next quarter, not urgent.\"}"

$KSH notes --unread --ack --project "$PROJECT"
$KSH move "$DND_ID" backlog --project "$PROJECT"
$KSH sync --project "$PROJECT"
$KSH status --project "$PROJECT" --cards | grep "$DND_ID"
```
- **Exercises:** the **override-survives-sync** lifecycle rule (`mergeSync`:
  `lane = prev.overrides[id]?.lane ?? h.lane`). `TODO.md`'s "## Now" heading
  still computes to **active** at harvest time — the stored override must beat
  that every sync, unconditionally, per the design's "overrides win" contract.
- **Expect:** the `grep` line shows `[backlog]`, not `[active]`, confirming the
  override held through the `sync` call.

---

## Phase 5 — Rework, regression, and a task split

**5.1 — ship, then a regression report**

```bash
DUE_ID="$(id_for "Add task due-date picker")"
$KSH move "$DUE_ID" done --project "$PROJECT"

curl -s -X POST "http://localhost:$KPORT/api/note" \
  -H 'content-type: application/json' \
  -d "{\"slug\":\"$SLUG\",\"cardId\":\"$DUE_ID\",\"note\":\"REGRESSION: the date picker breaks form submission on Safari 17, worked fine before Tuesday'\''s deploy.\"}"
```
- **Exercises:** a realistic regression-report-shaped note landing on an
  already-`done` card.
- **Expect:** note saved; card still shows `done` until the agent reopens it.

```bash
$KSH notes --unread --ack --project "$PROJECT"
$KSH move "$DUE_ID" active --project "$PROJECT"
```
- **Exercises:** [agent hat] reopening work in response to a note — `move`
  from `done` back to `active`.
- **Expect:** `moved <id> → active (override recorded; survives sync)`.

**5.2 — task split (no delete verb exists, so the original is marked stale — see Phase 10's known gap)**

```bash
TESTS_ID="$(id_for "Write integration tests for task CRUD API")"
$KSH move "$TESTS_ID" stale --project "$PROJECT"
$KSH add "Write integration tests: create & update task" --lane backlog --project "$PROJECT"
$KSH add "Write integration tests: delete & reorder task" --lane backlog --project "$PROJECT"
```
- **Exercises:** `move` to the `stale` lane as a manual "superseded" marker
  (the system has no card-delete verb, so this is the realistic agent
  workaround for D4a's "a task may get deprioritized / split / merged /
  deferred" framing); two fresh manual `add`s as the split children.
- **Expect:** original card lane=`stale`; two new backlog cards exist.

---

## Phase 6 — Sprint 2: new doc heading, re-sync

```bash
cat >> "$PROJECT/docs/plan.md" <<'EOF'

## Sprint 2 — In Progress
- [ ] Add CSV export for tasks
- [ ] Add keyboard shortcuts to task list
EOF

$KSH sync --project "$PROJECT"
$KSH status --project "$PROJECT" --cards | grep -E "CSV export|keyboard shortcuts"
```
- **Exercises:** sprint grouping via a fresh doc heading appended mid-project
  (the "In Progress" substring inside "Sprint 2 — In Progress" still matches
  the active-lane keyword regex — headings aren't matched by equality, just a
  substring/word-boundary test); manual and overridden cards must be
  unaffected by this sync (they don't appear in the delta math at all —
  `mergeSync`'s manual/override carry-forward branches don't increment
  `new`/`moved`/`unchanged`/`gone`/`kept-as-stale`).
- **Expect:** digest's `new` count includes exactly these 2 additions (plus 0
  from everything else, since nothing else in the source docs changed); both
  grepped lines show `[active]`.

---

## Phase 7 — Lifecycle deep-checks

**7.1 — stale-with-note kept, then dropped when the note clears**

```bash
GQL_ID="$(id_for "Investigate GraphQL vs REST for API layer")"
curl -s -X POST "http://localhost:$KPORT/api/note" \
  -H 'content-type: application/json' \
  -d "{\"slug\":\"$SLUG\",\"cardId\":\"$GQL_ID\",\"note\":\"Kill this -- we already decided on REST.\"}"

# Remove the source line entirely.
python3 - "$PROJECT/docs/plan.md" <<'PY'
import sys, re
p = sys.argv[1]
s = open(p).read()
s = s.replace("- [ ] Investigate GraphQL vs REST for API layer\n", "")
open(p, "w").write(s)
PY

$KSH sync --project "$PROJECT"
$KSH status --project "$PROJECT" --cards | grep "$GQL_ID"
```
- **Exercises:** the **stale-with-note-kept** rule — a card whose source line
  vanished is NOT dropped while a human note exists on it; instead `mergeSync`
  re-adds it with `lane:"stale", staleReason:"source item no longer found"`.
- **Expect:** the grep line shows `[stale]` (card still present, note intact).

```bash
curl -s -X POST "http://localhost:$KPORT/api/note" \
  -H 'content-type: application/json' \
  -d "{\"slug\":\"$SLUG\",\"cardId\":\"$GQL_ID\",\"note\":\"\"}"

$KSH sync --project "$PROJECT"
$KSH status --project "$PROJECT" --cards | grep -c "$GQL_ID"
```
- **Exercises:** the **empty-note deletes the note** rule on the server, then
  the **stale-card-dropped-once-note-clears** rule on the next sync (`if
  (notes[old.id]?.note)` is now falsy → `delta.gone++`, card not re-added).
- **Expect:** POST returns `{"ok":true,...}` (note deleted, not an error);
  `grep -c` returns `0` — the card is gone from the board entirely.

**7.2 — manual card persists across sync regardless of doc state**

```bash
CI_ID="$(id_for "Investigate CI flakiness")"
$KSH status --project "$PROJECT" --cards | grep "$CI_ID"
```
- **Exercises:** the manual-card-always-carried-forward branch in `mergeSync`
  — this card has never existed in any doc, so harvest never "sees" it, yet it
  must survive every sync run so far (Phase 2.2 through Phase 6).
- **Expect:** still present, lane `backlog` (unless Phase 3–6 moved it — it
  wasn't), `(manual)` as its source.

**7.3 — cross-file dedupe with recency**

```bash
curl -s "http://localhost:$KPORT/api/board?slug=$SLUG" | python3 -c '
import json, sys
d = json.load(sys.stdin)
c = next(x for x in d["board"]["cards"] if x["title"] == "Wire the signup email verification flow")
print("lane:", c["lane"], "source.kind:", c["source"]["kind"])
assert c["lane"] == "done" and c["source"]["kind"] == "session-notes", "dedupe picked the wrong source"
print("OK: freshest source (session-notes, checked=done) won over the older unchecked checkpoint copy")
'
```
- **Exercises:** the title-dedupe pass in `harvest()` — same normalized title
  in `_active.md` (checked, fresh mtime) and checkpoint A (unchecked, 3-days-
  older mtime); the freshest file's version must win.
- **Expect:** `lane: done`, `source.kind: session-notes`; script asserts and
  prints OK.

**7.4 — age-decay: the >14-day checkpoint never surfaces**

```bash
curl -s "http://localhost:$KPORT/api/board?slug=$SLUG" | grep -c "Old spike: evaluate websocket library" || true
```
- **Exercises:** confirms checkpoint B (Phase 1.7) has never produced a card,
  across every sync run in this script.
- **Expect:** `0`.

**7.5 — sub-items, tags, markdown-stripping, label chips — one consolidated API check**

```bash
curl -s "http://localhost:$KPORT/api/board?slug=$SLUG" | python3 -c '
import json, sys
cards = json.load(sys.stdin)["board"]["cards"]
by_title = {c["title"]: c for c in cards}

dnd = by_title["Wire up drag-and-drop reordering"]
assert len(dnd["subs"]) == 2, "sub-items not harvested"
assert dnd["subs"][1]["done"] is True and dnd["subs"][0]["done"] is False
print("OK sub-items:", dnd["subs"])

fix7 = by_title["Fix login redirect loop in AuthGuard"]
assert fix7["tag"] == "#7", f"tag extraction failed: {fix7.get(\"tag\")}"
assert "**" not in fix7["title"] and "`" not in fix7["title"], "markdown not stripped"
print("OK tag + markdown-strip:", fix7["tag"], "|", fix7["title"])

owner = by_title["confirm signup copy"]
assert owner["tag"] == "OWNER REVIEW"
print("OK UPPERCASE: tag:", owner["tag"])

ui = by_title["Build task list UI component"]
assert ui.get("heading") == "In Progress", f"heading not carried: {ui.get(\"heading\")}"
print("OK label/heading chip source:", ui["heading"])
'
```
- **Exercises:** in one pass — `subs[]` shape and done-flags; both `splitTag`
  tag grammars; markdown-emphasis stripping; the `heading` field that drives
  the UI's hue-hashed label chip (`board.html`'s `labelHue`/`.lh0`–`.lh5`
  classes).
- **Expect:** all four `assert` blocks pass silently through to their `print`.

---

## Phase 8 — Exhaustive edge-case sweep

CLI errors already covered inline above: duplicate `add` (3.3). Remaining ones:

**8.1 — `move`: invalid lane, unknown id**

```bash
UI_ID="$(id_for "Build task list UI component")"
$KSH move "$UI_ID" urgent --project "$PROJECT"; echo "exit=$?"
$KSH move 0000deadbeef active --project "$PROJECT"; echo "exit=$?"
```
- **Expect:** first: `usage\n  fix: kanban.sh move <card-id> <inbox|backlog|...>`,
  exit 1, `$UI_ID`'s lane unchanged. Second: `no card 0000deadbeef on $SLUG\n
  fix: kanban.sh status --project ... lists ids`, exit 1.

**8.2 — HTTP GET surfaces**

```bash
curl -s "http://localhost:$KPORT/api/boards" | python3 -c 'import json,sys; d=json.load(sys.stdin); print([b["slug"] for b in d["boards"]])'
curl -s -o /dev/null -w '%{http_code}\n' "http://localhost:$KPORT/api/board?slug=$SLUG"          # expect 200
curl -s -o /dev/null -w '%{http_code}\n' "http://localhost:$KPORT/api/board?slug=does-not-exist"  # expect 404
curl -s -o /dev/null -w '%{http_code}\n' "http://localhost:$KPORT/b/$SLUG"                        # expect 200
curl -s -o /dev/null -w '%{http_code}\n' "http://localhost:$KPORT/b/does-not-exist"                # expect 404
```
- **Exercises:** `/api/boards` list shape, `/api/board?slug=` happy+404,
  `/b/<slug>` happy+404.
- **Expect:** `$SLUG` present in the first list; status codes exactly as
  annotated per line.

**8.3 — `POST /api/note` validation ladder**

```bash
UI_ID="$(id_for "Build task list UI component")"

# unknown board -> 404
curl -s -o /dev/null -w '%{http_code}\n' -X POST "http://localhost:$KPORT/api/note" \
  -H 'content-type: application/json' -d '{"slug":"does-not-exist-000000","cardId":"0123456789ab","note":"x"}'

# malformed cardId (not 12-hex) -> 400
curl -s -o /dev/null -w '%{http_code}\n' -X POST "http://localhost:$KPORT/api/note" \
  -H 'content-type: application/json' -d "{\"slug\":\"$SLUG\",\"cardId\":\"not-a-hex-id\",\"note\":\"x\"}"

# well-formed but non-member cardId -> 404
curl -s -o /dev/null -w '%{http_code}\n' -X POST "http://localhost:$KPORT/api/note" \
  -H 'content-type: application/json' -d "{\"slug\":\"$SLUG\",\"cardId\":\"0123456789ab\",\"note\":\"x\"}"

# note over 10k chars -> 413
BIGNOTE="$(python3 -c "print('a'*10001)")"
curl -s -o /dev/null -w '%{http_code}\n' -X POST "http://localhost:$KPORT/api/note" \
  -H 'content-type: application/json' -d "{\"slug\":\"$SLUG\",\"cardId\":\"$UI_ID\",\"note\":\"$BIGNOTE\"}"

# empty note on an existing note -> 200, deletes
curl -s -X POST "http://localhost:$KPORT/api/note" \
  -H 'content-type: application/json' -d "{\"slug\":\"$SLUG\",\"cardId\":\"$UI_ID\",\"note\":\"\"}"
$KSH notes --project "$PROJECT" | grep -c "Build task list UI component" || true
```
- **Exercises:** the full validation order in `server.ts`'s `POST /api/note`
  handler (board existence → cardId regex → card membership → length cap), plus
  the empty-string-deletes convention.
- **Expect:** status codes `404, 400, 404, 413` on the four probes, in order;
  the final delete returns `{"ok":true,...}` and the `grep -c` afterward is `0`
  (4.1's note on this card is gone).

**8.4 — `/doc` allowlist, private-path, traversal, non-md**

```bash
# allowlisted .md inside the registered project root -> 200
curl -s -o /dev/null -w '%{http_code}\n' "http://localhost:$KPORT/doc?path=$(urlenc "$REALROOT/docs/plan.md")"

# a real file that exists but was never inside the allowlist -> 403
curl -s -o /dev/null -w '%{http_code}\n' "http://localhost:$KPORT/doc?path=$(urlenc "$HOME/.claude/CLAUDE.md")"

# traversal attempt starting INSIDE the project root, escaping it -> refusal
# (403 when the escaped path exists, 404 when the ../ count overshoots at this
# PROJECT depth and the target doesn't exist — BOTH are refusals; accept either)
curl -s -o /dev/null -w '%{http_code}\n' "http://localhost:$KPORT/doc?path=$(urlenc "$REALROOT/../journal.md")"

# allowlisted but wrong extension -> 415
curl -s -o /dev/null -w '%{http_code}\n' "http://localhost:$KPORT/doc?path=$(urlenc "$REALROOT/package.json")"
```
- **Exercises:** `docResponse`'s check order — existence (404, not probed here
  since all 4 paths exist) → allowlist membership (403) → extension (415).
  Roots are: every registered board's project root, `~/.claude/assets/reports/`,
  `~/.claude/scratchpad/` (owner-ratified scope F6a) — never the whole
  `~/.claude/` tree, which is why `CLAUDE.md` 403s despite being a real `.md`
  file.
- **Expect:** `200, 403, 403-or-404, 415` in order (line 3: any non-200 refusal
  passes; use a real file just outside the project root for a guaranteed 403).

**8.5 — `check`: happy path, then an induced FAIL**

```bash
$KSH check; echo "exit=$?"
```
- **Expect:** ends with `READY`, exit 0 (assuming the shared pm2 `kanban`
  service is healthy going in — this script neither starts nor stops it).

```bash
BOARD_DIR="$HOME/.claude/kanban/boards/$SLUG"
bun -e "
  const fs = require('fs');
  const p = '$BOARD_DIR/board.json';
  const b = JSON.parse(fs.readFileSync(p, 'utf8'));
  b.cards[0].lane = 'URGENT';
  fs.writeFileSync(p, JSON.stringify(b, null, 2) + '\n');
  console.log('corrupted card', b.cards[0].id, '-> lane URGENT');
"
$KSH check; echo "exit=$?"
$KSH sync --project "$PROJECT"   # restore: sync recomputes every lane fresh, discarding the corruption
$KSH check; echo "exit=$?"
```
- **Exercises:** `check`'s schema-lint branch (`LANES.includes(c.lane)`). This
  step deliberately violates the CLI-owns-board.json single-writer rule
  (SKILL.md) to prove the guard actually fires — never hand-edit `board.json`
  in normal operation.
- **Expect:** first `check` after corruption: `FAIL $SLUG: card <id> has
  unknown lane URGENT`, `N problem(s)`, exit 1. After `sync`, `check` is
  `READY` again, exit 0 (the corrupted lane is discarded because `mergeSync`
  always recomputes `lane` from the fresh harvest + overrides, never trusting
  what was on disk).

  *(Optional, NOT run by default — disruptive to the shared pm2 service other
  registered boards depend on: stopping `pm2 stop kanban` and re-running `check`
  exercises the "server not answering on :$KPORT" FAIL branch. If you do this,
  `pm2 restart kanban` immediately after and re-verify `check` is READY before
  moving on.)*

**8.6 — `open` (skip headless)**

```bash
$KSH open --project "$PROJECT"
```
- **Exercises:** `open`'s `execFileSync("open", [url])` — the real macOS `open`
  command.
- **Expect:** in an interactive session with a GUI, opens `http://localhost:
  $KPORT/b/$SLUG` in the default browser and prints the URL. **Skip this step
  in headless/CI runs** — there's no GUI session for `open` to hand off to, so
  it either no-ops or errors depending on the sandbox; it exercises nothing
  that Phase 8.2's `/b/$SLUG` 200 check hasn't already proven.

---

## Phase 9 — Wrap-up

```bash
$KSH sync --project "$PROJECT"
$KSH status --project "$PROJECT" --cards
$KSH notes --project "$PROJECT"
$KSH check; echo "exit=$?"
```
- **Exercises:** a final full pass — nothing here should surprise, given every
  phase above already exercised the individual mechanisms.
- **Expect:** `sync` reports mostly `unchanged` (no source changes since Phase 6);
  `--cards` shows the final lane distribution (roughly: 1 blocked→active moved
  card, 2 done, 1 stale-superseded original + 2 split children in backlog, 1
  dropped GraphQL card no longer listed, 2 Sprint-2 actives, the rest
  backlog/inbox); `notes` shows 0 unread (everything was acked in Phase 4/8);
  `check` is `READY`, exit 0.

---

## Phase 10 — Teardown, and the known gap

```bash
trash "$PROJECT"
trash "$HOME/.claude/kanban/boards/$SLUG"
trash "$CKROOT/kanban-agentux-ckpt-A.json"
trash "$CKROOT/kanban-agentux-ckpt-B.json"
```

- **Exercises:** the throwaway guarantee claimed in DESIGN.md ("trash
  `~/.claude/kanban/boards/<slug>/` and nothing else in the system notices").
- **Expect — and this is the known gap the sim agent should hit and report:**
  `~/.claude/kanban/registry.json` still carries an entry for `$SLUG` after
  this teardown. **There is no `kanban.sh unregister` / `remove` verb** — every
  verb in `cli.ts` (`init sync add move link notes status open check`) either
  creates, mutates, or reads; none deregisters a board. Post-teardown:
  - `$KSH status` still lists `$SLUG` with `root: $REALROOT` (a path that no
    longer exists) and 0 cards forever (`loadBoard` falls back to an empty
    board on the now-missing `board.json`).
  - the hub page (`GET /`) still lists it as a dead tile.
  - `GET /b/$SLUG` still 200s (board existence is checked via the registry, not
    the filesystem), rendering an empty board.
  - The only recovery is hand-editing `registry.json`, which contradicts the
    system's own single-writer/CLI-owns-the-registry principle — flag this to
    the user rather than doing it silently. Report this gap; do not route
    around it.

---

## Phase 8.1b — lock-release-on-error probes (added with the P0 fix, 2026-07-27)

The three assertions that pin the throw-based `die` + sweep retune. The TIME
BOUND is load-bearing: the mutation (an exit-based `die` inside the lock) shows
up as the follow-up write stalling ~10s, not as a nonzero exit.

```bash
KSH add "probe card" --project "$PROJECT"; KSH add "probe card" --project "$PROJECT"
# expect: second add exit 1 with the fix-proposing message, verbatim:
#   kanban: card <id> already exists
#     fix: kanban.sh move <id> <lane>
PID=$(id_for "probe card")
time KSH move "$PID" backlog --project "$PROJECT"   # expect: exit 0 in < 2s
KSH move 0000deadbeef active --project "$PROJECT"   # expect: exit 1 (no card)
time KSH link "$PID" TODO.md --project "$PROJECT"   # expect: exit 0 in < 2s
BD="$HOME/.claude/kanban/boards/$SLUG"; mkdir "$BD/.lock-board"
touch -t "$(date -v-11S +%Y%m%d%H%M.%S)" "$BD/.lock-board"
time KSH move "$PID" active --project "$PROJECT"    # expect: exit 0 in < 2s, lock dir gone after
```

Mutation re-check (run on a /tmp copy with HOME isolation, never the live tree):
revert `die` to `process.exit` in the copy → the follow-up-move probe must go
red (≥9s stall); restore → green. If the mutant stays green, the probe is the
bug (this caught a real one on 2026-07-27: a redundant pre-lock check masked the
throw path and had to be removed to make the guard pinnable).

---

## Phase 11 — P1/P2 fix-plan probes (added 2026-07-27)

```bash
# drop: manual gone-for-good; doc-sourced tombstones (sync won't resurrect); --undo returns it
# noted card refuses without --force; --force deletes the note VIA THE SERVER first
# unregister <slug>: status 0 matches · registry 0 · /api/boards 0 · /b/<slug> 404
# status --project "$PROJECT": exactly 1 board line, zero other-board leakage
# sync after a move: digest contains "overrides held: N"
# stderr split: `KSH sync ... 2>/dev/null | wc -l` == 1
# json: status/show/notes/add --json all parse via python3 json.load; add --json returns {id}
# zero-grep: the add→link→show→drop flow runs with grep/rg/awk shadowed to fail
```

All verified green 2026-07-27 (P0 8.1b probes + mutation test also green same day).

## Phase 12 — P4 session-start line probes (added 2026-07-27)

```bash
# injector: registered in scripts/session-mgmt/sessionstart-inject.sh INJECTORS;
# pure file reads (registry/notes/ack), no server dependency
SSL="$HOME/.claude/scripts/kanban/session-start-line.sh"
echo '{"cwd":"'"$PROJECT"'"}' | bash "$SSL"        # expect: {additionalContext:"[kanban] board …"}
echo '{"cwd":"'"$PROJECT"'/sub"}' | bash "$SSL"    # expect: same line (subdir matches by prefix)
echo '{"cwd":"/private/tmp"}' | bash "$SSL"        # expect: no output, exit 0
# unread branch (copy-based ack rollback, restore after):
# set boards/<slug>/ack.json lastAckTs:0 → line says "N unread human note(s)"; restore → "no unread"
# integration: pipe the same payload through sessionstart-inject.sh → merged context contains "[kanban]"
```

All verified green 2026-07-27 (incl. forced-unread branch + lane integration).

## Phase 13 — terminal skin + usability bundle + tagged notes v1 probes (added 2026-07-27)

```bash
# three-way unread consistency (@me excluded everywhere): these MUST agree —
KSH notes --unread --json --project "$PROJECT" | jq '[.notes[] | select(.unread)] | length'
curl -s localhost:5106/api/boards | jq '.boards[] | select(.slug=="'$SLUG'") | .unread'
echo '{"cwd":"'"$PROJECT"'"}' | bash ~/.claude/scripts/kanban/session-start-line.sh  # count in the line
# tag parse: note "!now /skeptical-review x >active #risk" → notes --unread prints
#   [!now /skeptical-review >active] marks + a "directives:" line + the tag legend footer
# @me note → absent from --unread, present in plain notes
# board UI (browser): tag chips render on cards; drawer shows live tag preview + legend +
#   "mirror: harvested from docs, synced …" provenance line; note save round-trips via the button
# stale banner: force data.board.syncedAt to now-3d + render() → banner block; restore → hidden
# delta strip: set localStorage kanban-visit-<slug> to now-4d + reload → "since your last visit"
#   strip with new/moved/review counts + dismiss clears halos
# copy digest: press c (or ⧉ digest) → clipboard gets plain-text standup paragraph
# hub: /api/boards carries unread+reviewMe; attention rows sort first with amber stripe;
#   >24h sync shows "⚠ Nd stale" on the row
```

All verified green 2026-07-27 (bun parse rc=0 ×3, live server, browser dark+light,
forced stale + forced delta, UI note round-trip). NOT yet run: /ui-categorical-check
on the rebuilt board — deferred to next pickup, run it against the live fixture board.

## Phase 14 — data increment probes: verify grades · docs survival · via (added 2026-07-27)

```bash
# P1 verify lifecycle (grades: executed|cited|reasoned; board.json is CLI-owned)
KSH verify "$ID" executed --note "probes green" --project "$PROJECT"   # sets
KSH show "$ID" --json --project "$PROJECT" | jq -r '.card.verify.grade' # "executed"
KSH sync --project "$PROJECT"                                           # …
KSH show "$ID" --json --project "$PROJECT" | jq -r '.card.verify.grade' # STILL "executed"
KSH verify "$ID" --clear --project "$PROJECT"                           # removes (null)
# P2 agent-linked docs survive sync (latent loss bug fixed in mergeSync: old.docs union)
KSH link "$ID" TODO.md --project "$PROJECT"; KSH sync --project "$PROJECT"
KSH show "$ID" --json --project "$PROJECT" | jq -c '.card.docs'         # contains TODO.md
# P3 via attribution: "$PROJECT"/.claude/session-notes/_active.md symlinked to <uuid>.md
# with a "## Todos" checkbox → sync → card carries via:<uuid8>; drawer "via session …"
# board render: ✓ executed / ✓ cited chips + amber needs-you; archive rows suppress chips
# EXCEPT the needs-you marker (M3: it matters most on done)
```

All verified green 2026-07-27 (incl. --clear null check, post-sync survival of BOTH
grade and linked doc, deadbeef via probe, archive needs-you render). Plan + reasoning:
assets/reports/20260727-kanban-data-increment/PLAN.md

## Phase 15: notes as a first-class entity (added 2026-08-11)

A card holds `notes[]` (many notes, each with id/body/updatedAt); the legacy
`note` string is a derived join that EXCLUDES `@me` bodies. Per-note ack lives
in `ack.json` as `{lastAckTs, notes: {<ackKey>: ts}}`; `lastAckTs` stays the
floor for notes the map has never seen. The automated sweep for the reader-level
guarantees is `bash test-readers.sh` (spins a fixture board, isolated from the
real registry, and SKIPs its write checks silently if the server is down).

```bash
bash ~/.claude/scripts/kanban/test-readers.sh    # expect: 9 passed, 0 failed
# POST /api/note ladder for the multi-note fields (server.ts:306-337):
#   noteId:"new" + blank body        -> 400 (no phantom id)
#   noteId not in notes[]            -> 409 (deleted under the client; never appends a duplicate)
#   no noteId while notes[] > 1      -> 409 pre-multi-note client guard
#   blank body, no noteId, 1 note    -> 200 legacy clear; wiping a MULTI-note card
#                                       needs an explicit all:true (only drop sends it)
# GET /api/notes -> every note across every board: {board, slug, cardId, noteId, ...};
#   the hub Notes view filters it and deep-links /b/<slug>?card=<id>&note=<noteId>
# CLI: notes --unread counts per-note via noteSeen(), not per-card; @me excluded
# sync tombstones doc-gone cards off notes[] (the array), never the derived join
```

Reader sweep green 2026-08-11 (9/9, mutation-tested per guard); the API ladder,
hub deep link, and drawer note stack were exercised live 2026-08-10 in the
notes-entity build (commits abc6e01..980d16c, gate report:
assets/reports/20260810-kanban-notes-entity/stage2-validation.md). Known
unclosed edge: the 409 guard reads `existing` outside the enqueue chain, so two
sub-millisecond POSTs can both pass it (reasoned, never reproduced; the write
itself stays serialised).

## Phase 16: board provenance + the proactive offer (added 2026-08-11)

Boards record who made them and what they sit on: `via` (creating session),
`stack` (detected from manifest files, lib.ts projectFacts), `branch`, `repo`.
`sync` backfills these on boards that predate the fields. The session-start
injector offers a board only where the project has already outlived a session
(a prior checkpoint pointer for this cwd), and never where one was declined.

```bash
KSH show "$ID" --json --project "$PROJECT" | jq '.card.via'      # creating session id8
curl -s localhost:$KPORT/api/boards | jq '.boards[0] | {stack, branch}'
# offer: no board + prior checkpoint for cwd -> "[kanban] No board here, and <why>…"
# suppression: touch "$PROJECT/.claude/kanban-declined" -> injector stays silent
# machine-wide off switch: ~/.claude/kanban/.no-offer
KSH unregister "$SLUG"   # closes Phase 10's known gap: registry + hub + /b/<slug> all clear
```

Verified green 2026-08-10 (commit 2c6c726). The unregister verb landed
2026-07-27 (Phase 11) and is the teardown Phase 10 said didn't exist; use it
instead of hand-editing registry.json.

## Phase 17: ui-gripe closure probes (added 2026-08-11)

The four findings left open from the 2026-08-10 ui-gripe pass, fixed in commit
9541eb5. All are board.html render behavior; probe from the browser or via a
headless page eval.

```bash
# needs-you handoff: header leads with an amber "<N> needs you" button when any
#   card has verify.needsHuman; clicking sets the filter to the literal token
#   "needs-you" (matchFilter special-cases it); Esc in the filter clears
# lane-echo pill: a heading that names the card's own column (LANE_ECHO map,
#   e.g. "TODO" in inbox, "In progress" in active) renders no label pill on the
#   card face; the stripe keeps the hue and the drawer keeps the name. A
#   non-echo pair ("In progress" heading on a done card) keeps its pill.
# source path: tailPath() shortens from the head ("…/docs/plan.md:15"), title
#   holds the full path; never direction:rtl (it relocates a leading slash)
# composer: empty + unfocused + no conflict -> .composer.min (one-line dock);
#   focus, text, a restored draft, or a conflict expands it; blur collapse is
#   delayed 150ms so clicks on dock controls land
# contrast: the needs-you chip tint rides on var(--card), not the canvas;
#   measured 6.62:1 dark / 5.11:1 light from source tokens
```

Verified green 2026-08-11: live board dark+light screenshots, filter click
scoping 1/2-per-column counts, all composer transitions asserted headless,
contrast computed from the token set, reader sweep 9/9 after the change.
