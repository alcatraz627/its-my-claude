---
brief: Modular Ghostty tab-title composer — ✻ + mode/intent + base + [:focus] + status/decorators. State-driven, hook-rendered, claude-controllable.
triggers:
  - tool:tab-title
  - tool:set-focus
  - topic:terminal-title
  - topic:ghostty
  - phrase:tab title
  - phrase:set focus
  - phrase:claude mood
  - phrase:claude status
related:
  - scripts/update-tab-title.sh
  - scripts/tab-title/lib.sh
  - scripts/tab-title/decorators.sh
  - scripts/tab-title/tab-title.sh
  - scripts/tab-title/hooks/pre-tool.sh
tier: 2
category: features
updated: 2026-05-12
stale_after_days: 180
---

# Tab title — Ghostty composer

Driver: `~/.claude/scripts/tab-title/tab-title.sh` (run with no args for help).

The Stop hook recomposes the Ghostty tab title at the end of every turn. Title shape (v3):

```
✻ <mode?> <intent?> <base> [:<focus?>]    <status?> <decorators?>
└────────── identifier (left) ──────┘    └──── volatile (right) ────┘
```

Two-space separator between halves so Ghostty's truncation eats the right side first, preserving the identifier.

## TL;DR for Claude — slots at a glance

| Slot | What it conveys | Set via |
|---|---|---|
| `mode` | Action verb (what's happening now) | Auto-derived from tools; override `mode <x>` |
| `intent` | Session noun (what kind of work overall) | `intent <feat\|fix\|refactor\|...>` |
| `base` | Session identifier text | `set base="..."` (stable across turns) |
| `focus` | Current sub-task, 1-3 words | `focus "..."` / `--clear` |
| `status` | Result indicator (ok/warn/err/idle/info/blocked) | `status <name>` |
| `decorators` | Auto-flags (perm, ssh, agents, cost) | Self-set by decorators; glyph configurable |

### Named enums (LLM picks by name — run `--list` for the full table)

- **status** (semantic icons): `ok` ✅ · `warning` ⚠️ · `error` ❌ · `idle` 💤 · `info` ℹ️ · `blocked` 🛑
- **mode** (24 verbs): `think` 🤔 · `search` 🔍 · `read` 📖 · `write` ✏️ · `edit` ✂️ · `build` 🛠️ · `test` 🧪 · `debug` 🐛 · `save` 💾 · `deploy` 🚀 · `network` 🌐 · `clean` 🗑️ · etc.
- **intent** (12 nouns, conventional-commit-flavored): `feature` ✨ · `bugfix` 🐛 · `refactor` 🔄 · `docs` 📝 · `chore` 🧹 · `research` 📚 · `design` 🎨 · `release` 🚀 · `discussion` 💬 · `test` 🧪 · `perf` ⚡ · `security` 🔒

Unknown names are still stored (forward-compat) but render no glyph and emit a dim notice.

## CLI cheat-sheet

```bash
TT=~/.claude/scripts/tab-title/tab-title.sh

$TT                                  # full help
$TT show                             # composed title
$TT get all                          # state dump

# Named-enum slots
$TT status ok                        # ✅ — task succeeded
$TT mode debug                       # 🐛 — investigating
$TT intent feature                   # ✨ — feature work
$TT mode --list                      # show all enum values

# Free-form fields
$TT focus "csrf token validation"    # 1-3 word current sub-task
$TT focus --clear
$TT set base="Auth refactor" focus="login flow"   # multi-field atomic

# Decorator glyph configuration (persisted per-session in state — no env vars)
$TT glyph perm robot                 # 🤖 — perm-mode glyph
$TT glyph ssh 🐢                     # raw emoji also accepted
$TT glyph perm --options             # named alias table
$TT glyph perm --clear               # back to default 🆓

# Inspect / repair
$TT check                            # list issues (exit 0 = clean)
$TT fix                              # auto-repair, idempotent
$TT refresh                          # re-run decorators

# Escape hatch (requires user permission prompt)
$TT raw "literal title"              # dissuade-only without -y
$TT raw -y --reason "OSC test" "..."  # triggers user prompt

# Self-tests (sandboxed; safe to run anytime)
bash ~/.claude/scripts/tab-title/tests.sh
```

## When Claude should set what

| User asks / situation | Set |
|---|---|
| Starting a new logical sub-task | `focus "<sub-task>"` |
| Finished a sub-task | `focus --clear` |
| Build/test passed | `status ok` |
| Hit a warning | `status warning` |
| Build broken / test failing | `status error` |
| Long task, waiting on external | `status blocked` or `status idle` |
| Session is feature/refactor/fix work | `intent <kind>` (set once per session) |
| User specifies a session topic | `set base="<topic>"` |

Don't churn `mode` manually — it's auto-tracked by the PreToolUse hook from tool inspection. Override only when auto-derivation gets it wrong.

## How auto-mode-derivation works

PreToolUse hook (`scripts/tab-title/hooks/pre-tool.sh`) inspects each tool call:

| Tool | Auto-mode |
|---|---|
| `Read` | `read` |
| `Write` / `Edit` | `edit` |
| `Glob` / `Grep` | `search` |
| `Agent` | `think` |
| `TodoWrite` | `target` |
| `Bash` w/ `npm test`/`pytest`/`go test`/`vitest` | `test` |
| `Bash` w/ `npm run build`/`make`/`cargo build`/`tsc` | `build` |
| `Bash` w/ `git commit`/`git push`/`git tag` | `save` |
| `Bash` w/ `git pull`/`git fetch`/`git merge` | `sync` |
| `Bash` w/ `curl`/`wget`/`ssh`/`http` | `network` |
| `Bash` w/ `rg`/`grep`/`find`/`fd` | `search` |
| `Bash` w/ `docker`/`kubectl`/`helm` | `deploy` |
| `Bash` w/ `npm install`/`pip install` | `package` |
| `Bash` w/ `trash`/`rm`/`clean` | `clean` |

No match → mode unchanged.

## Files & responsibilities

| Path | Role |
|---|---|
| `scripts/tab-title/tab-title.sh` | **Unified CLI** — show / get / set / focus / status / mode / intent / glyph / refresh / check / fix / raw |
| `scripts/tab-title/lib.sh` | State I/O, enum maps, normalisation, composition, validation, fixers |
| `scripts/tab-title/decorators.sh` | Active decorators (ssh, perm, agents, cost) + extension point |
| `scripts/tab-title/set-focus.sh` | Back-compat shim → forwards to `tab-title.sh focus` |
| `scripts/tab-title/hooks/pre-tool.sh` | PreToolUse — sets transient focus + auto-derives mode |
| `scripts/tab-title/hooks/post-tool.sh` | PostToolUse — decrements depth, clears transient when settled |
| `scripts/tab-title/hooks/raw-guard.sh` | PreToolUse — prompts user when `raw -y` is invoked |
| `scripts/update-tab-title.sh` | Stop hook entry point — emits compose at end of every turn |
| `scripts/tab-title/tests.sh` | 62 self-tests (sandboxed `TAB_STATE_DIR`; safe to run anytime) |

## Critical environment notes

- **Disable Claude Code's built-in title manager**: set `CLAUDE_CODE_DISABLE_TERMINAL_TITLE=1` in `settings.json` env block. Otherwise Claude Code competes for the title every turn (writes `title` placeholder while generating its own session summary). Already configured in this repo.
- **Visible refresh happens only at Stop hook firing** in this Claude Code build — PreToolUse/PostToolUse `/dev/tty` writes don't reach the visible terminal. Mid-turn state mutations are stored and rendered at the next Stop hook. Don't promise the user mid-turn title changes; they land at end of turn.
- **Tab title font fallback**: if your Ghostty tab strip can't render `✻` it falls back to `*`. Other emoji fall back similarly. Use a Nerd Font / SF Pro variant if you want full coverage.
- **Manual Ghostty override is sticky**: if you (or some past write) set the title to a literal value via the tab's context menu or `/rename`, Ghostty holds it. Clear the manual override (right-click → reset title) and our OSC writes resume.

## SSH transparency (why this just works remotely)

`tab_emit` writes `\033]0;…\007` (OSC 0) to `/dev/tty`. These bytes are interpreted only by the terminal emulator at the far end of the SSH pipe. SSH forwards stdout transparently, so a script running on a remote host updates the *local* Ghostty's tab title with zero extra config.

## Extending — add a new decorator

Edit `scripts/tab-title/decorators.sh`:

```bash
dec_docker() { [[ -f /.dockerenv ]] && printf ''; }
TAB_DECORATORS=(ssh perm agents cost docker)   # add the name
```

Constraints: function must be cheap (no network, no `find` traversals), prints exactly one glyph or empty. Decorators run every Stop hook.

## Extending — add a new named-enum value

Edit `lib.sh`:
1. Add a case to `tab_<slot>_glyph()` — name → printf glyph.
2. Add a row to `tab_<slot>_list()` — for `--list` discoverability.

That's it. CLI picks it up automatically.

## Failure modes

- **No state file** → CLI prints dim notice, exits 0 (non-blocking for Claude).
- **State file corrupted** (non-canonical star, brackets in focus, embedded `[:focus]` in base, NaN depth) → `check` reports each issue; `fix` repairs idempotently.
- **OSC write fails** (Bash-tool subprocess has no `/dev/tty`) → silently no-ops; state still mutates so the next hook firing emits.
- **Multiplexer suppresses OSC** (tmux without passthrough, locked Ghostty title via `--title=`) → not fixable from inside the script; document and move on.

## OSC reference

| Sequence | Sets |
|---|---|
| `\033]0;TITLE\007` | window + tab title (what we use) |
| `\033]1;TITLE\007` | icon / tab title only |
| `\033]2;TITLE\007` | window title only |

Always sanitise input (`LC_ALL=C tr -d '\000-\031\177'`) before emitting — stray ESC in user-controlled text can corrupt the sequence or inject further escapes. `LC_ALL=C` keeps `tr` byte-safe for multi-byte UTF-8 emoji.
