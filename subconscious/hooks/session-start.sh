#!/bin/bash
# i-dream: SessionStart hook — injects subconscious signals
SOCKET="/Users/alcatraz627/.claude/subconscious/daemon.sock"
# D6: send the working directory so the daemon can inject a per-project brief.
# jq escapes the path for safe JSON; falls back to no-cwd payload if jq is missing.
if command -v jq >/dev/null 2>&1; then
    PAYLOAD=$(jq -nc --arg cwd "$PWD" --argjson ts "$(date +%s)" \
        '{event:"session_start",ts:$ts,cwd:$cwd}')
else
    PAYLOAD='{"event":"session_start","ts":'$(date +%s)'}'
fi
if [ -S "$SOCKET" ]; then
    RESPONSE=$(printf '%s' "$PAYLOAD" \
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
    if [ -n "$RESPONSE" ]; then
        echo "$RESPONSE"
    fi
fi
# Touch activity signal
touch "/Users/alcatraz627/.claude/subconscious/.last-activity"
