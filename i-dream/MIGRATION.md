# i-dream migration — bring the dreaming layer + accumulated data to a new Mac

> Handoff for the `mac-migration` agent. i-dream is a Rust CLI+daemon + a macOS
> widget. The **code** lives in a git repo (clone it); the **value** is ~142 MB
> of accumulated dreaming data under `~/.claude/` that must NOT be re-started.
>
> **Principle:** COPY the data verbatim · REGENERATE anything that embeds an
> absolute path (binary, launchd plists, widget app) · FIX the one config with a
> hardcoded home · SKIP transient files.

---

## 1. COPY verbatim — the accumulated data (the whole point)

Copy these `~/.claude/` subtrees to the **same paths** on the new Mac (home-
relative discovery depends on the same `~/.claude/<name>` locations). Each
domain's `dream/cursor.json` travels *with* its `events.jsonl`, so dreaming
resumes where it left off instead of re-dreaming everything.

| Path | ~size | What's in it (why it's precious) |
|------|-------|----------------------------------|
| `~/.claude/subconscious/` | 137M | Native dreaming engine: `dreams/{patterns,associations,journal,insight-digest}`, metacog, valence, intentions. The bulk. |
| `~/.claude/atone/` | 4.4M | Mistake events + dream insights + cluster-map + RCAs. High value. |
| `~/.claude/affirm/` | 256K | Affirmed-behavior events + dream. |
| `~/.claude/memory-domain/` `~/.claude/sessions-domain/` | 140K | Synthesized-domain manifests + extract scripts + cursors. |
| `~/.claude/pinned/` | 32K | Pinned-insight events. |
| `~/.claude/hooks-feedback-domain/` + `~/.claude/hooks/feedback.jsonl` | 36K | claude-audit hook-feedback events + dream. |
| `~/.claude/i-dream/` | 172K | derived/ (tldr.union, associations.cross), daily/ digests, audits/, **domains/*.toml** (centralized manifests incl claude-audit), threads.json, injections.jsonl, _runtime.json, integration-requests/, this file. |

Each domain dir also carries its sibling `.i-dream-domain.toml` manifest — copying
the dir wholesale brings it. Discovery (`registry.rs`) scans the same well-known
roots, so same-path = it just works.

## 2. SKIP — transient / regenerable (don't bother copying)

`subconscious/logs/`, `subconscious/dreams/locks/`, `subconscious/dreams/ingest-queue/`,
`i-dream/logs/`, `i-dream/.review-pending`, any `*.tmp`. (Harmless if copied, just noise.)

## 3. FIX — the one config with an absolute home

`~/.claude/subconscious/config.toml` contains hardcoded `/Users/alcatraz627/...`
paths. After copying, either:
- `sed -i '' 's#/Users/alcatraz627#/Users/<newuser>#g' ~/.claude/subconscious/config.toml`, or
- regenerate defaults with `i-dream config > ~/.claude/subconscious/config.toml`
  (loses any hand-tuned budgets/sample-rates — prefer the sed if you tuned it).

Everything else uses `~/`/`{root}` (home-relative) — no other path edits needed.

## 4. REGENERATE on the new Mac — never copy these

- **Binary:** `git clone <repo> && cd i-dream && cargo install --path .` (then
  the dup at `~/.local/bin/i-dream` if you keep one). Do NOT copy the Mach-O.
- **launchd jobs** (these embed the old absolute binary path — regenerating
  rewrites them for the new home): `i-dream cron install` (dreampass/daily/
  audit/review) and `i-dream service install` (the daemon). Do NOT copy the 6
  `~/Library/LaunchAgents/{com.alcatraz.i-dream-*,dev.i-dream.*}.plist`.
- **Widget app:** rebuild from `tools/menubar/build.sh` (compiles + signs +
  installs `i-dream-bar.app`). Do NOT copy the `.app`.

## 5. SECRET — API key

No API key in i-dream's config (it runs in Claude Code CLI / subscription mode).
If you switched to direct-API mode, the key is `ANTHROPIC_API_KEY` in your global
env / `~/.claude/subconscious/.env` (absent here) — handle it with the rest of
your secrets migration, never in git or plaintext transit.

## 6. Order of operations (new Mac)

1. `git clone` the i-dream repo · `cargo install --path .`.
2. Copy the §1 subtrees to the same `~/.claude/<name>` paths.
3. Apply the §3 `config.toml` home fix.
4. `i-dream cron install` · `i-dream service install` · `bash tools/menubar/build.sh`.
5. Verify (§7).

## 7. Verify the migration landed

- `i-dream domain list` → all domains present (atone/affirm/memory/sessions/
  pinned/claude-audit + natives).
- `i-dream reflect` → shows your accumulated mistake-recurrence history (proves
  the atone data + cursors came across).
- `i-dream board` → renders today/week/sources.
- Start a Claude session → the SessionStart injection carries your top patterns
  (proves `dream-insights.sh` + the data are wired).
- `i-dream cron status` → 4 jobs loaded.

If `reflect` shows history and `domain list` shows every domain, the
accumulated dreaming carried over — you did not start from zero.
