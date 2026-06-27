# Ledger Format Reference

A gcc **event-ledger** is a durable, append-only JSONL stream of low-volume,
human-meaningful events that a subsystem records about its own work — the kind a
human or an agent would ever read, cite, or act on one line at a time (a mistake,
an affirmation, a proposal, a pinned insight). Ledgers are the **system of
record**; they are NOT the high-volume operational exhaust (per-tool-call
telemetry, rolling session WALs, daemon firehoses) that belongs to `::logs`.

This doc is the canonical contract. It is what the manifest references but never
defined, and what every writer (`ledger-common.sh`, Phase 1) and reader
(`ledger.sh`, Phase 4) implements against. Sibling spec shape: `wal-format.md`.

> Status: canonical contract (Phase 0). The shared writer/reader scripts that
> implement it land in later phases; this doc defines the shape they must honor.

---

## The canonical event line

One JSON object per line, JSONL. Every line shares a small envelope; the rest is
**domain payload, flat at top level** (not nested). **Omit empty fields** — the
`| with_entries(select(.value != "" and .value != null))` rule (already used by
`propose.sh`, `wal.sh`, `emit-event.sh`); JSONL compresses well when sparse.

### Required — every ledger line carries these three

| Field | Type | Description |
|---|---|---|
| `id` | string | `<prefix>-<datestamp>-<seq>`. Stable, unique, **time-sortable**, **citable** as a deep-link anchor (e.g. `atone/events.jsonl#mist-20260626-...`). See id format below. |
| `ts` | ISO-8601 string | UTC, `date -u '+%Y-%m-%dT%H:%M:%SZ'`. Byte-identical across every existing writer — the highest-coverage field. |
| *classifier* | string | At least one **domain-named** categorical field saying *what kind of thing this is* (atone `slug`+`severity`; proposals `category`+`status`; persona `persona`+`mode`). A **role**, not a fixed name — the manifest declares which field is the classifier, and **its vocabulary is the domain's, not global**. There is deliberately NO global `kind` enum. |

### Recommended — include when present, omit when empty

| Field | Type | Description |
|---|---|---|
| `session_id` | string | The `<keyword>-<keyword>-<2hex>` session id. Provenance + the join key for a cross-domain session timeline. |
| `project` | string | Project root / cwd, so the same event reads loud in a real repo and quiet in a throwaway (stakes-scoping). |
| `tags` | string[] | Free-form cross-cutting labels — the high-cardinality field readers group by at query time. |
| *summary* | string | One human-readable line, scannable without expanding the record (atone `issue`, pinned `text`, proposal `title`). Strongly encouraged — a machine-only line fails the family test. |

### Reserved — present only when earned

- `v` (integer schema version). **Absent ⇒ v1.** Stamped only after a domain ships a
  breaking shape change AND its reader gains an upcast seam. Never pre-stamped.

Everything else is **domain payload** — the per-ledger object, owned by the
subsystem and deliberately not standardized.

---

## The id format

```
  <prefix> - <datestamp> - <seq>
     │          │             └── collision-breaker within the same second
     │          └── UTC time, embedded so the id sorts chronologically
     └── short domain tag (mist, aff, prop, puse, pin, alert, …)
```

A valid id MUST be **prefixed** (what makes ids unique across a union view),
**time-sortable** (datestamp embedded), and **collision-broken** by a `<seq>` tail.
Two datestamp renderings are both legal and in live use — keep both, don't flatten:

- `YYYYMMDD-HHMMSS` + `-<2hex>` (atone / affirm / proposals — the default)
- `YYYYMMDDTHHMMSSZ` + `-$RANDOM` (persona-log — deliberate)

**Synthetic domains** (regenerated wholesale from an upstream truth) key by
`content-hash + epoch` (`mem-<hash>-<epoch>`) so re-extraction is idempotent — a
legitimate third style for that sub-family.

---

## The family boundary — what is a ledger event, and what is not

Both ledgers and firehoses are append JSONL — the line is **not** "JSONL vs not."
It is **system of record vs operational exhaust.**

> **The ledger test:** a line belongs to the ledger family iff a human or an agent
> would ever want to **read, cite, or act on that single line on its own.**

An atone event is cited by slug, carries an RCA, drives a hint — it passes. A
metacog `{tool, hook_ts}` activity line is meaningless alone; only the aggregate of
tens of thousands means anything — it fails.

**Four backstops (any ONE disqualifies):**

| # | Backstop | IN (ledger) | OUT (logs) |
|---|---|---|---|
| 1 | **Volume / cadence** | deliberate, low (≲100/day; human- or skill-initiated) | firehose, per-tool-call / per-hook-fire |
| 2 | **Durability** | append-only-forever, or regenerated deterministically | rolling window, rewritten-in-place, rotated |
| 3 | **Provenance / writer** | a deliberate CLI/skill or a synthetic extractor | fire-and-forget from a hook bus / daemon socket |
| 4 | **Self-contained meaning** | carries a human-readable classifier + summary | only `{tool, ts}` — needs siblings to mean anything |

### Value-neutral events — actionability is downstream

The raw event stays **value-neutral**: it carries *evidence* (classifier + summary
+ payload), **not** an alert level or `actionable:true`. Whether an event matters is
decided in a separate derived layer (the alert model, Phase 3) that scores events
against a `goals.toml` value-system. Keeping the line value-neutral is what lets the
same event read loud in one repo and silent in another **without rewriting it**.
(atone's own `severity` is the *atone domain's* declared classifier, not a global
red-line.)

### Two lifecycle sub-families (both IN)

- **A. Appended judgment ledgers** (atone, affirm, pinned, proposals, persona-usage)
  — each line written once by a deliberate CLI/skill under a flock-serialized append.
  `proposals` is **append-mostly**: `done`/`reject` mutate `status` via
  `jq … > tmp && mv`, so it is IN the family but **opts out of the kernel seal** (a
  `chflags uappnd` would break its `mv`). Documented exception, not tech debt.
- **B. Synthetic projection domains** (memory-domain, sessions-domain) — regenerated
  wholesale from an upstream truth, capped, content-hashed ids; no hand-authored
  `add`. The durability backstop reads as "regenerated deterministically."

---

## Registration — how a domain joins (the corrected mechanism)

A domain joins the i-dream pipeline (consolidate → dream-pass → hinter union) by
dropping a manifest in the **centralized registry dir**:

```
~/.claude/i-dream/domains/<name>.toml
```

This is discovered without recompiling, and a centrally-registered domain gets the
**full** pipeline, identical to the built-in domains — verified empirically:
`claude-audit` (a centrally-registered, non-sibling domain) appears in the live
`i-dream/derived/tldr.union.txt` with a dream-generated summary.

> **Do NOT** rely on "drop a `.i-dream-domain.toml` in the store's own root." Root
> discovery only works for a **hardcoded** five-element `sibling_roots` array
> (`atone`, `affirm`, `memory-domain`, `sessions-domain`, `pinned`) in
> `~/Code/Claude/i-dream/src/modules/registry.rs:171-177`; adding to it requires
> rebuilding the Rust binary. New domains use the centralized dir
> (`registry.rs:152-168`), full stop. (This corrects the original design's single
> load-bearing error.)

The manifest declares the `[event_stream]` binding (`id_field`, `ts_field`, the
classifier field) plus, later, `[[detector]]` blocks (Phase 3). i-dream's manifest
parser ignores unknown sections (no `deny_unknown_fields`), so a `[[detector]]`
block does not break i-dream — but that also means a malformed one is silently
ignored, which is why the evaluator (Phase 3) must lint detector specs loudly.

---

## The writer contract (`scripts/ledger/ledger-common.sh`, Phase 1)

A writer signs this contract (each step opt-in, not all-or-nothing):

1. Source `ledger-common.sh` (or get it transitively via `atone-common.sh`).
2. Make ids with `ledger_id <prefix>`, timestamps with `ledger_ts`.
3. Build its own `{…}` line with `jq -cn`, ending in `LEDGER_STRIP_EMPTY`.
4. Persist with `ledger_append` **iff** it wants the flock append.
5. Optionally `ledger_commit` and/or `ledger_seal_append` for durable ledgers.

A new *single-shape* ledger gets a full schema-driven CLI for free (Layer 2,
deferred until a real second caller); a complex existing writer (atone, propose)
takes **Layer-1 primitives only** and keeps its bespoke CLI.

---

## Schema evolution

1. **Additive by default.** Add fields freely; readers default missing ones
   (`.field // <default>`).
2. **Never rename, retype, or reuse a retired name in place.** A field's name+type
   is a contract once shipped. Want a different shape? Add a new field; leave the old.
3. **`v` only on a genuine breaking change** — absent ⇒ v1; never pre-stamp.
4. **Read-time upcast when forced** — a tiny per-domain `upcast(event)->event` in
   that domain's reader normalizes old lines; stored events stay immutable.
5. **Retention via archive, not compaction** — rotate the tail to a dated archive;
   never compact/delete in place (hard deletion reserved for a leaked secret).

---

## Reading

```bash
L=~/.claude/atone/events.jsonl

# Recent events of one classifier value
jq -c 'select(.severity == "S3")' "$L" | tail -10

# Everything in one session across a domain (the cross-domain join key)
jq -c 'select(.session_id == "rightsize-rev")' "$L"

# Group by a tag
jq -r '.tags[]?' "$L" | sort | uniq -c
```

The sanctioned reader `scripts/ledger/ledger.sh` (Phase 4) generalizes these over
the registered domain set (`list / search / show / stats / timeline / sources` for
humans; `ask / status` for agents), keyed on `id / ts / session_id / tags / the
domain-declared classifier` — never a global `--kind/--severity`.

---

## Cross-references

- `assets/reports/20260626-ledger-design/04-P2-PROPOSALS-RUNBOOK.md` — a worked
  registration (proposals) + the **registration runbook**: the gotchas every new
  domain hits (required `[consolidation]`, unknown-key rejection, the `{root}`
  symlink, the top-5 weight cap) and the failure/recovery procedures.

- `~/.claude/skills/shared/wal-format.md` — the sibling spec this mirrors (and the
  `::logs` side of the boundary: WAL is rolling, OUT of the ledger family).
- `~/.claude/assets/reports/20260626-ledger-design/00-DESIGN.md` — the full design.
- `~/.claude/assets/reports/20260626-ledger-design/03-PLAN-REVISED.md` — the phased
  build plan this contract is Phase 0 of.
- `~/Code/Claude/i-dream/src/modules/registry.rs` — the discovery mechanism
  (`discover_external_manifests`, the centralized dir + the hardcoded sibling roots).
