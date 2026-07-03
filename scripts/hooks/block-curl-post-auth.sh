#!/usr/bin/env bash
# block-curl-post-auth.sh — PreToolUse[Bash] HARD BLOCK.
# Blocks `curl -X POST` (or similar mutating method) with Authorization header.
# These leave no audit trail; use mcp__file-tools__http_request instead.
#
# Allows: plain GET curl, curl without auth, curl piping local files (-T <file> for upload
# is still flagged; that's intentional — uploads need audit too).
#
# Mute: touch ~/.claude/.no-curl-auth-block (use with care — this is a
# security/auditability guardrail, not a convenience nudge).

set -uo pipefail

# Mute is applied AFTER detection (below), not at the top: a muted run that WOULD
# have fired is logged action:"muted", so the silence is dated and visible rather
# than an early exit that leaves no trace.
MUTED=0
[[ -f "$HOME/.claude/.no-curl-auth-block" ]] && MUTED=1

INPUT=$(cat 2>/dev/null || true)
[[ -z "$INPUT" ]] && exit 0
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
[[ -z "$CMD" ]] && exit 0

# Need: curl + mutating method (POST/PUT/PATCH/DELETE) + Authorization header
echo "$CMD" | rg -q '\bcurl\b' 2>/dev/null || exit 0
echo "$CMD" | rg -q "\-X\s+(POST|PUT|PATCH|DELETE)\b|--request\s+(POST|PUT|PATCH|DELETE)\b|--(data|data-raw|data-binary|data-urlencode|json|form)\b" 2>/dev/null || exit 0
echo "$CMD" | rg -q "Authorization\s*:|-u\s+\S+:|--user\s+\S+:" 2>/dev/null || exit 0

if [ "$MUTED" = 1 ]; then
  bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook block-curl-post-auth --action muted --heeded unknown >/dev/null 2>&1 || true
  exit 0
fi
bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook block-curl-post-auth --action block --heeded unknown >/dev/null 2>&1 || true

cat >&2 <<'EOF'
[BLOCK] curl with mutating method + auth header has no audit trail.
Use the file-tools MCP instead:
  mcp__file-tools__http_request {
    "method": "POST",
    "url": "...",
    "headers": {"Authorization": "..."},
    "body": {...}
  }
Wins: audited, structured response, consistent error handling.
For a quick GET (no auth), curl is still fine — this only blocks
mutating + authenticated.
Override (use with caution): touch ~/.claude/.no-curl-auth-block
EOF
exit 2
