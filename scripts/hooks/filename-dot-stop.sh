#!/usr/bin/env bash
# filename-dot-stop.sh — Stop hook: refuse to end a turn whose final message puts
# a period IMMEDIATELY after a file path / filename.
#
# Why: Ghostty (the user's terminal) auto-links file paths so they're clickable.
# A trailing "." right after the path gets swallowed into the link / breaks it,
# so the path is no longer clickable and the user has to ask for the full path
# again. Small, persistent, very annoying papercut the user asked to hard-stop.
#
# Rule enforced: a filename ending in a known extension must NEVER be immediately
# followed by a period — in backticks (`foo.md`.) or bare (foo.md.). Follow the
# path with a space / word / comma, or restructure so it is not sentence-final.
#
# Mirrors declared-ready-stop.sh: a DIRECT settings.json Stop hook.
#   block:   {"decision":"block","reason":…}  → reason fed to agent, turn stays open
#   surface: {"systemMessage":…}              → non-blocking note
#   silent:  exit 0
# Loop-safe: blocks once per offending-message signature, then steps aside.
# Checks ONLY the final assistant message, with fenced code blocks stripped.
# Mute: touch ~/.claude/.no-filename-dot-gate

set -uo pipefail
[ -f "$HOME/.claude/.no-filename-dot-gate" ] && exit 0

input=$(cat 2>/dev/null) || exit 0
command -v jq >/dev/null 2>&1 || exit 0
command -v rg >/dev/null 2>&1 || exit 0

sid=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)
tp=$(printf '%s' "$input" | jq -r '.transcript_path // empty' 2>/dev/null)
[ -n "$sid" ] && [ -n "$tp" ] && [ -f "$tp" ] || exit 0
sid8="${sid:0:8}"

# Last assistant message text (precise — not the whole tail).
tail_json=$(tail -n 400 "$tp" 2>/dev/null) || exit 0
last_asst=$(printf '%s\n' "$tail_json" | jq -rc 'select(.type=="assistant")' 2>/dev/null | tail -n 1)
[ -n "$last_asst" ] || exit 0
text=$(printf '%s' "$last_asst" | jq -r '.message.content[]? | select(.type=="text") | .text' 2>/dev/null)
[ -n "$text" ] || exit 0

# Strip fenced code blocks so legit code paths inside ``` ``` don't trip it.
prose=$(printf '%s\n' "$text" | awk 'BEGIN{f=0} /^[[:space:]]*```/{f=!f; next} !f{print}')
[ -n "$prose" ] || exit 0

EXT='md|markdown|py|sh|bash|ts|tsx|js|jsx|mjs|cjs|html|htm|css|scss|json|jsonl|ya?ml|toml|swift|go|rs|rb|c|h|hpp|cpp|cc|java|kt|sql|txt|log|plist|xml|svg|conf|cfg|ini|env'
# Two offending forms (backticks are literal inside single quotes; $ is literal):
bt='`[^`]*\.('"$EXT"')`\.'                                                    # `path/foo.md`.
bare='(?<![A-Za-z0-9])[A-Za-z0-9_./@~-]*\.('"$EXT"')\.(\s|$|[)\]"])'          # path/foo.md.
PAT="($bt)|($bare)"

hit=$(printf '%s\n' "$prose" | rg -nP "$PAT" 2>/dev/null | head -3)
[ -n "$hit" ] || exit 0

# Loop-safe: don't re-block the identical message.
MARK="/tmp/claude-filename-dot-${sid8}"
sig=$(printf '%s' "$prose" | shasum 2>/dev/null | awk '{print $1}')
prev=""; [ -f "$MARK" ] && prev=$(cat "$MARK" 2>/dev/null)
if [ "$sig" = "$prev" ] && [ -n "$sig" ]; then
  jq -cn '{systemMessage:"⚠ filename-dot (not re-blocking the identical message): a file path is still immediately followed by a period, so Ghostty cannot link it. Mute: touch ~/.claude/.no-filename-dot-gate"}' 2>/dev/null || true
  exit 0
fi
printf '%s' "$sig" > "$MARK" 2>/dev/null || true

reason="⛔ FILE PATH FOLLOWED BY A PERIOD — Ghostty auto-links file paths in the terminal, and a period right after the path gets swallowed into the link, so the path is NOT clickable and the user has to ask for it again.

Offending line(s):
$hit

Fix: re-emit the message so NO file path is immediately followed by a period. Follow every path with a space, a word, or a comma, or end the path mid-sentence. Examples:
  bad:   The brief is \`docs/foo.md\`.
  good:  Paste \`docs/foo.md\` to claude design.
  good:  The brief is at \`docs/foo.md\`, ready to hand off.
  good:  See \`docs/foo.md\` for the full brief.

The user asked for hard enforcement of this. Mute: touch ~/.claude/.no-filename-dot-gate"
jq -cn --arg r "$reason" '{decision:"block", reason:$r}' 2>/dev/null || true
exit 0
