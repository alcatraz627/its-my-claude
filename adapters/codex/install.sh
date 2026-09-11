#!/usr/bin/env bash
# install.sh — wire the gcc into Codex. Idempotent; re-run after any change.
#
# What it does, in order:
#   1. skills   ~/.agents/skills/<name> -> ~/.claude/skills/<name> for each line of
#               skills.list, plus core-dump -> adapters/codex/skills/core-dump.
#               Stale links that point into ~/.claude but are no longer listed are
#               removed; foreign links are left alone.
#   2. hooks    ~/.codex/hooks.json -> adapters/codex/hooks.json (a regular file
#               already there is backed up beside it first).
#   3. rules    ~/.codex/rules/gcc.rules -> adapters/codex/rules/gcc.rules, then
#               proven with `codex execpolicy check` (rm must come back forbidden).
#   4. AGENTS   rules/00-index.md regenerated, then $CODEX_HOME/AGENTS.md rebuilt
#               from preamble.md + the index (scripts/export-agents-md.sh).
#   5. verify   bash -n on every hook, one synthetic rm payload through the
#               PreToolUse guard (must block), an empty outbox drain.
#
# Symlink where Codex follows one (skills, hooks.json, rules); generate where it
# cannot (AGENTS.md is assembled from two sources and byte-capped). Sync model:
# symlinked surfaces are live; AGENTS.md needs this script after a rule or
# preamble edit. Nothing here is automated on a timer, by design.
#
# After install: hooks are TRUSTED per hash. Open `codex`, run /hooks, trust the
# six gcc entries once (again after any edit to hooks.json), or launch through
# bin/codex-gcc, which passes --dangerously-bypass-hook-trust for exec runs.
set -uo pipefail

ROOT="$HOME/.claude"
ADAPTER="$ROOT/adapters/codex"
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
AGENTS_SKILLS="$HOME/.agents/skills"
ok=0; bad=0
pass() { printf '  ok   %s\n' "$1"; ok=$((ok+1)); }
fail() { printf '  FAIL %s\n' "$1" >&2; bad=$((bad+1)); }

[ -d "$CODEX_HOME" ] || { fail "CODEX_HOME missing: $CODEX_HOME (is codex installed?)"; exit 1; }
command -v codex >/dev/null 2>&1 || fail "codex not on PATH; steps that call it will be skipped"
command -v jq >/dev/null 2>&1 || { fail "jq is required"; exit 1; }

link() { # link <target> <linkpath>
  local target="$1" path="$2"
  if [ -L "$path" ] && [ "$(readlink "$path")" = "$target" ]; then pass "link $path"; return; fi
  if [ -e "$path" ] && [ ! -L "$path" ]; then
    local bak="$path.bak-$(date +%Y%m%d-%H%M%S)"
    mv -f "$path" "$bak" && printf '  note backed up %s -> %s\n' "$path" "$bak"
  fi
  ln -sfn "$target" "$path" && pass "link $path -> $target" || fail "link $path"
}

printf '== 1. skills -> %s\n' "$AGENTS_SKILLS"
mkdir -p "$AGENTS_SKILLS"
wanted=()
while IFS= read -r name; do
  case "$name" in ''|'#'*) continue;; esac
  wanted+=("$name")
  if [ -d "$ROOT/skills/$name" ]; then link "$ROOT/skills/$name" "$AGENTS_SKILLS/$name"
  else fail "skills.list names $name but $ROOT/skills/$name does not exist"; fi
done < "$ADAPTER/skills.list"
link "$ADAPTER/skills/core-dump" "$AGENTS_SKILLS/core-dump"; wanted+=(core-dump)
for l in "$AGENTS_SKILLS"/*; do
  [ -L "$l" ] || continue
  case "$(readlink "$l")" in "$ROOT"/*) ;; *) continue;; esac
  keep=0; for w in "${wanted[@]}"; do [ "$(basename "$l")" = "$w" ] && keep=1; done
  [ "$keep" -eq 1 ] || { rm -f "$l" && printf '  note pruned stale link %s\n' "$l"; }
done
if [ -d "$CODEX_HOME/skills/core-dump" ] && [ ! -L "$CODEX_HOME/skills/core-dump" ]; then
  fail "$CODEX_HOME/skills/core-dump is a stale copy; the source is $ADAPTER/skills/core-dump (trash the copy)"
fi

printf '== 2. hooks -> %s/hooks.json\n' "$CODEX_HOME"
for h in "$ADAPTER"/hooks/*.sh "$ADAPTER"/bin/*; do chmod +x "$h"; done
link "$ADAPTER/hooks.json" "$CODEX_HOME/hooks.json"
jq -e '.hooks | keys | length > 0' "$ADAPTER/hooks.json" >/dev/null 2>&1 && pass "hooks.json parses ($(jq -r '.hooks | keys | join(", ")' "$ADAPTER/hooks.json"))" || fail "hooks.json does not parse"

printf '== 3. rules -> %s/rules/gcc.rules\n' "$CODEX_HOME"
mkdir -p "$CODEX_HOME/rules"
link "$ADAPTER/rules/gcc.rules" "$CODEX_HOME/rules/gcc.rules"
if command -v codex >/dev/null 2>&1; then
  dec=$(codex execpolicy check --rules "$CODEX_HOME/rules/gcc.rules" -- rm -rf build 2>/dev/null | jq -r '.decision // empty')
  [ "$dec" = forbidden ] && pass "execpolicy: rm -rf build -> forbidden" || fail "execpolicy: rm -rf build -> '${dec:-no decision}' (rules file rejected?)"
fi

printf '== 4. AGENTS.md\n'
bash "$ROOT/scripts/rules-index.sh" >/dev/null 2>&1 && pass "rules/00-index.md regenerated" || fail "rules-index.sh"
if out=$(bash "$ROOT/scripts/export-agents-md.sh" 2>&1); then pass "$(printf '%s' "$out" | head -1)"; else fail "export-agents-md: $out"; fi

printf '== 5. verify\n'
for h in "$ADAPTER"/hooks/*.sh "$ADAPTER"/bin/gcc "$ADAPTER"/bin/codex-gcc; do
  bash -n "$h" 2>/dev/null && pass "syntax $(basename "$h")" || fail "syntax $(basename "$h")"
done
payload='{"session_id":"00000000-install-check","cwd":"/tmp","hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":"rm -rf /tmp/never"}}'
dec=$(printf '%s' "$payload" | bash "$ADAPTER/hooks/pre-tool-bash.sh" 2>/dev/null | jq -r '.decision // empty')
[ "$dec" = block ] && pass "PreToolUse guard blocks rm" || fail "PreToolUse guard did not block rm (got '${dec:-nothing}')"
payload='{"session_id":"00000000-install-check","cwd":"/tmp","hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":"ls -la"}}'
out=$(printf '%s' "$payload" | bash "$ADAPTER/hooks/pre-tool-bash.sh" 2>/dev/null)
[ -z "$out" ] || [ "$(printf '%s' "$out" | jq -r '.decision // empty')" != block ] && pass "PreToolUse guard passes ls" || fail "PreToolUse guard blocked ls"
bash "$ADAPTER/hooks/drain-outbox.sh" 00000000-install-check >/dev/null 2>&1 && pass "outbox drain (empty) exits 0" || fail "drain-outbox"
python3 "$ADAPTER/bin/codex-status.py" --hours 1 --json >/dev/null 2>&1 && pass "codex-gcc status renders" || fail "codex-status.py"

printf '\n%s ok, %s failed\n' "$ok" "$bad"
printf 'Trust the hooks once: open `codex`, run /hooks, trust the gcc entries (repeat after editing hooks.json).\n'
printf 'Headless runs: bash %s/bin/codex-gcc exec "<task>"  (passes --dangerously-bypass-hook-trust)\n' "$ADAPTER"
[ "$bad" -eq 0 ]
