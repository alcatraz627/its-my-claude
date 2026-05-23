# Bash Script Gotchas & Patterns

<!-- sessions: shell-obs-4c@2026-04-03, sl-open-4e@2026-04-14 -->

> Pitfalls and reusable patterns for shell scripts in Claude Code.
> Referenced by: LOOKUP.md § Shared References

---

## 1. `cat file | jq` hangs indefinitely

**Symptom:** A command like `cat ~/.claude/.mcp.json | jq 'keys'` runs as a background task and never completes, even with `2>/dev/null`.

**Root cause:** `jq` reads from stdin via the pipe. If the pipe doesn't close cleanly (e.g. due to operator precedence issues or the shell environment), `jq` blocks waiting for more input. Adding `2>/dev/null` only suppresses stderr — it does not fix stdin blocking.

**Fix:** Use the `Read` tool instead of `cat` for any file inspection task. Reserve `Bash` for commands that genuinely need shell execution.

```bash
# ❌ Can hang — jq blocks on stdin
cat ~/.claude/.mcp.json 2>/dev/null | jq 'keys' 2>/dev/null

# ✅ Use Read tool instead — no shell, no pipe, no hang
# Read: /Users/alcatraz627/.claude/.mcp.json
```

**Occurred:** 2026-04-03 session `shell-obs-4c`. The command ran as background task `bj52hny00` and timed out at 15s with status `running`.

---

## 2. Shell operator precedence with `||` / `&&` / `|`

**Symptom:** A chain like `A || echo "NOT FOUND" && B | C` behaves unexpectedly — `C` may receive stdin from an earlier part of the pipeline rather than just `B`.

**Root cause:** In bash, `|` (pipe) has higher precedence than `&&` and `||`. The expression `A || B && C | D` is parsed as `A || B && (C | D)` — not `(A || B) && (C | D)`. Mixed chains are error-prone.

**Fix:** Use explicit subshells or `{ ... }` grouping, or break into separate commands.

```bash
# ❌ Ambiguous — pipe and logical operators mixed
cat file 2>/dev/null || echo "NOT FOUND" && echo "---" && cat other 2>/dev/null | jq 'keys'

# ✅ Break into separate steps
FILE=$(cat ~/.claude/.mcp.json 2>/dev/null || echo "NOT FOUND")
KEYS=$(cat ~/.claude/mcp-catalog.json 2>/dev/null | jq 'keys' 2>/dev/null || echo "catalog not found")
echo "$FILE"
echo "---"
echo "$KEYS"
```

---

## 3. Use the Read tool, not `cat`, for file inspection

**Rule:** Prefer the `Read` tool over `cat`/`head`/`tail` for reading any file. The Read tool:
- Never hangs
- Produces line-numbered output
- Is tracked and reviewable by the user
- Does not consume a shell process

Only fall back to `cat` in a Bash command if you need output to pipe into another command that itself requires shell execution (e.g. `cat file | wc -l`).

---

## 4. Interactive user prompts in shell scripts — the `/dev/tty` pattern

**Use case:** You want a script to ask the user a question (pick a program, confirm an action,
enter a value) even when it's called from a pipeline, a skill, or another script that may
have stdin redirected.

**Why it works:** When stdin (`fd 0`) is piped or redirected, `read` silently gets EOF and
returns an empty string — the prompt never appears and no input is received. Reading
explicitly from `/dev/tty` bypasses stdin entirely and connects directly to the controlling
terminal. This always works as long as a terminal is attached (i.e. the user is present).

```bash
# ❌ Breaks when stdin is piped or redirected
read -r choice
echo "Got: $choice"    # always empty when called as: echo "" | ./script.sh

# ✅ Read from /dev/tty — always gets real user input
read -r choice </dev/tty
echo "Got: $choice"
```

**Full numbered-menu pattern** (copy-paste ready):

```bash
bold=$'\033[1m'; dim=$'\033[2m'; rst=$'\033[0m'; cyn=$'\033[36m'

prompt_choice() {
  local file_path="$1"

  # Line 1: the resolved path (useful even without opening)
  printf "%s\n" "$file_path"

  # Line 2: inline options
  printf "${dim}Open with: ${rst}${cyn}[1]${rst} code  ${cyn}[2]${rst} nano  ${cyn}[3]${rst} open  ${dim}[Enter] path only${rst}\n"
  printf "${dim}> ${rst}"

  local choice
  read -r choice </dev/tty 2>/dev/null
  choice="${choice:-}"   # default to empty = "do nothing"

  case "$choice" in
    1|code)   code  "$file_path" ;;
    2|nano)   nano  "$file_path" ;;
    3|open)   open  "$file_path" 2>/dev/null ;;
    "")       : ;;   # Enter = already printed path, no open
    *)        "$choice" "$file_path" 2>/dev/null ;;  # raw command name
  esac
}
```

**Companion tips:**

- Add `2>/dev/null` after `read </dev/tty` so non-interactive CI environments don't see
  "bad file descriptor" errors — they'll just get an empty string and fall through to the
  default case.
- Detect optional tools at runtime with `command -v <tool> &>/dev/null` — shell aliases
  (like a `.zprofile` `glow=cat`) are **not** available in `bash` subprocesses. Check for
  the actual binary.
- Print the file path **before** prompting, not after — that way the path is visible
  even if the user Ctrl-C's out of the prompt.
- If you want a `y/n` confirm, same pattern applies:
  ```bash
  printf "Proceed? [y/N] "
  read -r yn </dev/tty 2>/dev/null
  [[ "${yn,,}" == "y" ]] || { echo "Aborted."; exit 0; }
  ```

**Real-world use:** `~/.claude/scripts/statusline/sl-open.sh` — prompts for program choice
(code / nano / google-chrome / glow / open) after resolving a statusline file alias.
Added 2026-04-14.
