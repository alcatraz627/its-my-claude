# Safe Delete Reference

<!-- sessions: safe-del-9c@2026-03-31 -->

> Canonical reference for file deletion in Claude sessions on macOS.
> Referenced by: CLAUDE.md § Shell & Search, GUIDELINES.md § Safety, settings.json PreToolUse hook

---

## Rule

**Never use `rm` to delete files or directories.** Use `trash` instead.

```bash
# ✅ Correct — moves to macOS Trash (recoverable)
trash src/old-component/
trash temp.txt build.log

# ❌ Blocked — PreToolUse hook will reject this
rm -rf src/old-component/
rm temp.txt
```

## Why

`rm` is permanent and unrecoverable. `trash` uses macOS's built-in Trash system (`/usr/bin/trash`), which:
- Preserves the original path for "Put Back" in Finder
- Allows recovery until the user explicitly empties Trash
- Is a system binary — no Homebrew install needed

## Enforcement

A **PreToolUse hook** (`~/.claude/scripts/safe-delete.sh`) runs before every Bash tool call:

1. Parses the command from the hook's JSON stdin
2. Detects standalone `rm` (not `git rm`, `npm rm`, etc.)
3. Blocks the command with `{ "decision": "block" }`
4. Prints a yellow warning with the equivalent `trash` command

### What gets blocked

| Command | Blocked? | Why |
|---------|----------|-----|
| `rm file.txt` | Yes | Direct file deletion |
| `rm -rf dir/` | Yes | Recursive deletion |
| `rm -f *.log` | Yes | Forced deletion |
| `ls && rm old.txt` | Yes | rm in compound command |
| `git rm file.ts` | No | Git staging operation, not file deletion |
| `npm rm lodash` | No | Package manager operation |
| `cargo rm` | No | Not standalone `rm` |

### Hook location

```
~/.claude/settings.json → hooks.PreToolUse[matcher="Bash"] → ~/.claude/scripts/safe-delete.sh
```

## Recovery

If a file was accidentally deleted (before this hook was active, or via another tool):

### From macOS Trash

```bash
# Browse Trash contents
ls ~/.Trash/

# Restore a specific file
mv ~/.Trash/filename.txt /original/path/filename.txt

# Restore via Finder (preserves original location)
# Open Finder → Trash → right-click file → "Put Back"
```

### From git (if committed)

```bash
# Restore a file from the last commit
git checkout HEAD -- path/to/file.txt

# Restore from a specific commit
git checkout abc123 -- path/to/file.txt

# See what was deleted recently
git log --diff-filter=D --summary --since="1 day ago"
```

### From Time Machine (last resort)

1. Open the folder where the file lived
2. Enter Time Machine (menu bar → Time Machine icon)
3. Navigate back to when the file existed
4. Click "Restore"

## Usage in skills and agents

Any skill that needs to remove files must:

1. Use `trash <path>` instead of `rm`
2. Print a yellow notice: `\033[33m🗑️  Moved to Trash: <path>\033[0m`
3. If the file doesn't exist, skip silently (don't error)

```bash
# Pattern for skills
if [[ -e "$filepath" ]]; then
  trash "$filepath"
  printf '\033[33m🗑️  Moved to Trash: %s\033[0m\n' "$filepath" >&2
fi
```

## Integration points

| Location | What it says |
|----------|-------------|
| `CLAUDE.md` § Shell & Search | "Never use `rm`. Use `trash`." + recovery summary |
| `GUIDELINES.md` § Safety | "Use `trash` instead of `rm`" |
| `settings.json` → PreToolUse | Hook registration for `safe-delete.sh` |
| `scripts/safe-delete.sh` | The hook script itself |
| This file (`shared/safe-delete.md`) | Full reference (you are here) |
