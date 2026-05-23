# Asset Management Reference

<!-- sessions: asset-mgr-b2@2026-03-31 -->

> Canonical reference for how agents create, track, find, and clean up non-source files.
> Referenced by: CLAUDE.md, GUIDELINES.md § Safety, LOOKUP.md

---

## Rule

**Non-source files agents create (screenshots, reports, PDFs, data exports, debug artifacts) go in `~/.claude/assets/<type>/`.**

Preferred: use `asset.sh register` (handles naming, manifest, and placement in one call).
Acceptable: copy the file directly to the right subdirectory — the file is still findable by type, just won't appear in MANIFEST.md. A bit of manifest inconsistency is fine; what matters is files land in the right directory, not the `~/.claude/` root.

## Directory structure

```
~/.claude/assets/
  MANIFEST.md       # Asset registry (optional tracking layer)
  asset.sh          # CLI helper
  static/           # Permanent (no expiry): icons, reference docs
  docs/             # Reports, audits, PDFs, todos
  images/           # Screenshots, downloaded media
  data/             # JSON, CSV, structured exports
  tmp/              # Short-lived intermediates (expires naturally)
```

## Two ways to store an asset

### Option A: `asset.sh register` (preferred)

One call — moves file, adds datestamp prefix, updates MANIFEST.

```bash
bash ~/.claude/assets/asset.sh register screenshot.png \
  --session "fix-auth-3b" \
  --tags "debug,login" \
  --description "Login page screenshot" \
  --lifetime 30d
# → ~/.claude/assets/images/20260331-screenshot.png
```

Type is auto-inferred from extension. `--session`, `--tags`, `--description` are all optional.

**Minimal call** (everything optional except the file):
```bash
bash ~/.claude/assets/asset.sh register screenshot.png
```

### Option B: Direct copy (acceptable)

Just put the file in the right subdirectory. Follow naming convention manually.

```bash
cp screenshot.png ~/.claude/assets/images/20260331-screenshot.png
```

No manifest entry — file is still findable by browsing `assets/images/`. Use this when speed matters more than tracking.

## Finding assets

```bash
# Via manifest (if registered)
bash ~/.claude/assets/asset.sh find --session "fix-auth-3b"
bash ~/.claude/assets/asset.sh find --tag report
bash ~/.claude/assets/asset.sh find --type docs

# Via filesystem (always works)
ls ~/.claude/assets/images/
ls ~/.claude/assets/docs/*cleanup*

# Get absolute path to a known asset
bash ~/.claude/assets/asset.sh path static/ghostty-icon.png
```

## What goes where

| File type | Directory | Example |
|-----------|-----------|---------|
| Screenshots, PNGs, JPGs | `images/` | `20260331-login-debug.png` |
| Reports, audits, PDFs, markdown output | `docs/` | `20260331-route-audit.pdf` |
| Icons, permanent reference docs | `static/` | `ghostty-icon.png` (no datestamp) |
| JSON, CSV, data exports | `data/` | `20260331-user-export.json` |
| Temp intermediates, working files | `tmp/` | `20260331-processing.tmp` |

## What does NOT go in assets/

- **Source code** — stays in project directories
- **Plugin artifacts** — managed by Claude Code (`vercel-plugin-*`, `stats-cache.json`)
- **Image cache** — managed by Claude Code (`~/.claude/image-cache/`)
- **Config files** — `settings.json`, `CLAUDE.md`, etc. stay at `~/.claude/` root
- **WAL/checkpoints** — stay in `.claude/` per existing conventions
- **Scratchpad entries** — stay in `.claude/scratchpad/`

## Naming convention

- **Ephemeral files**: `YYYYMMDD-<descriptive-slug>.<ext>` (same as doc-naming.md)
- **Static files**: plain descriptive name, no datestamp
- **Session tag**: handled by MANIFEST if registered; not embedded in filename

## Cleanup

`asset.sh cleanup` runs automatically during auto-compaction. Files registered with a lifetime get trashed (via `trash`) after expiry. Unregistered files in `tmp/` should be cleaned manually or will accumulate — this is an acceptable tradeoff.

```bash
# Manual cleanup
bash ~/.claude/assets/asset.sh cleanup           # trash all expired
bash ~/.claude/assets/asset.sh cleanup --dry-run  # preview what would go
```

## Integration points

| Location | What it says |
|----------|-------------|
| `CLAUDE.md` § Asset Management | Core rule + pointer here |
| `GUIDELINES.md` § Safety | "File output goes in assets/" |
| `GUIDELINES.md` § Helper Scripts | `asset.sh` + `asset-management.md` in table |
| `LOOKUP.md` | Rows for MANIFEST.md, asset.sh, and this file |
| `scripts/session-mgmt/pre-compact-checkpoint.sh` | Auto-cleanup trigger |
