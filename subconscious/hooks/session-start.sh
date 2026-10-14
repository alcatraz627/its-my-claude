#!/bin/bash
# i-dream's own background claude calls carry I_DREAM_CHILD=1; their hooks must
# not feed the daemon (it was downvoting its own intentions, 2026-10-06).
[ -n "${I_DREAM_CHILD:-}" ] && exit 0
# i-dream: SessionStart hook — injects subconscious signals
SOCKET="${IDREAM_SOCKET:-/Users/alcatraz627/.claude/subconscious/daemon.sock}"
# D6: send the working directory so the daemon can inject a per-project brief,
# and the session id so a later correction blames only this session's rules.
# jq escapes both for safe JSON; falls back to a bare payload if jq is missing.
HOOK_INPUT=$(cat 2>/dev/null)
if command -v jq >/dev/null 2>&1; then
    SID=$(printf '%s' "$HOOK_INPUT" | jq -r '.session_id // empty' 2>/dev/null)
    PAYLOAD=$(jq -nc --arg cwd "$PWD" --arg sid "$SID" --arg ep "${CLAUDE_CODE_ENTRYPOINT:-}" --argjson ts "$(date +%s)" \
        '{event:"session_start",ts:$ts,cwd:$cwd} + (if $sid == "" then {} else {session_id:$sid} end) + (if $ep == "" then {} else {entrypoint:$ep} end)')
else
    PAYLOAD='{"event":"session_start","ts":'$(date +%s)'}'
fi
if [ -S "$SOCKET" ]; then
    # The daemon reads with read_line: the trailing newline is what lets it
    # parse BEFORE this client's 2s recv timeout, instead of only at EOF —
    # without it every briefing died as a broken pipe (root-caused 2026-07-18).
    RESPONSE=$(printf '%s\n' "$PAYLOAD" \
        | python3 -c "
import sys, socket as S
s = S.socket(S.AF_UNIX)
s.connect('$SOCKET')
s.sendall(sys.stdin.buffer.read())
s.settimeout(2)
try:
    data = b''
    while True:
        chunk = s.recv(4096)
        if not chunk: break
        data += chunk
    sys.stdout.buffer.write(data)
except Exception: pass
s.close()
" 2>/dev/null)
    # Only the text that enters the model's context is capped (700 chars, the
    # other 500 of the 1,200 go to the atone block in dream-insights.sh); the
    # daemon keeps the full brief. IDREAM_BRIEF_CAP=0 turns the cap off.
    case "$RESPONSE" in
        "{"*) ;;
        *)
            if [ "${IDREAM_BRIEF_CAP:-700}" != "0" ] && [ -n "$RESPONSE" ]; then
                CAPPED=$(printf '%s' "$RESPONSE" | python3 "$HOME/.claude/scripts/dream/brief-cap.py" "${IDREAM_BRIEF_CAP:-700}" 2>/dev/null)
                [ -n "$CAPPED" ] && RESPONSE="$CAPPED"
            fi ;;
    esac
    if [ -n "$RESPONSE" ]; then
        echo "$RESPONSE"
    fi
fi
# Touch activity signal
touch "$(dirname "$SOCKET")/.last-activity"
