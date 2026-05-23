#!/bin/bash
# i-dream: Stop hook — records session end for consolidation timing
SOCKET="/Users/alcatraz627/.claude/subconscious/daemon.sock"
if [ -S "$SOCKET" ]; then
    echo '{"event":"session_end","ts":'$(date +%s)'}' \
        | python3 -c "import sys,socket as S; s=S.socket(S.AF_UNIX); s.connect('$SOCKET'); s.sendall(sys.stdin.buffer.read()); s.close()" 2>/dev/null || true
fi
