#!/bin/bash
# i-dream's own background claude calls carry I_DREAM_CHILD=1; their hooks must
# not feed the daemon (it was downvoting its own intentions, 2026-10-06).
[ -n "${I_DREAM_CHILD:-}" ] && exit 0
# i-dream: Stop hook — records session end for consolidation timing
SOCKET="/Users/alcatraz627/.claude/subconscious/daemon.sock"
if [ -S "$SOCKET" ]; then
    echo '{"event":"session_end","ts":'$(date +%s)'}' \
        | python3 -c "import sys,socket as S; s=S.socket(S.AF_UNIX); s.connect('$SOCKET'); s.sendall(sys.stdin.buffer.read()); s.close()" 2>/dev/null || true
fi
