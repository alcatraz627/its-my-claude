#!/bin/bash
# i-dream: PostToolUse hook — captures tool execution metadata
SOCKET="/Users/alcatraz627/.claude/subconscious/daemon.sock"
if [ -S "$SOCKET" ]; then
    echo '{"event":"tool_use","tool":"'$TOOL_NAME'","ts":'$(date +%s)'}' \
        | python3 -c "import sys,socket as S; s=S.socket(S.AF_UNIX); s.connect('$SOCKET'); s.sendall(sys.stdin.buffer.read()); s.close()" 2>/dev/null || true
fi
# Touch activity signal
touch "/Users/alcatraz627/.claude/subconscious/.last-activity"
