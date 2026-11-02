#!/bin/bash
# i-dream's own background claude calls carry I_DREAM_CHILD=1; their hooks must
# not feed the daemon (it was downvoting its own intentions, 2026-10-06).
[ -n "${I_DREAM_CHILD:-}" ] && exit 0
# i-dream: PostToolUse hook — captures tool execution metadata
SOCKET="/Users/alcatraz627/.claude/subconscious/daemon.sock"
if [ -S "$SOCKET" ]; then
    # The tool name arrives in the hook's stdin JSON; the harness sets no TOOL_NAME.
    # This fires on every tool call, so it spawns one interpreter and no more.
    python3 -c "import sys,json,time,socket as S; raw=sys.stdin.read()
try: d=json.loads(raw)
except Exception: d={}
n=(d.get('tool_name') or sys.argv[1] or '')
s=S.socket(S.AF_UNIX); s.connect(sys.argv[2]); s.sendall(json.dumps({'event':'tool_use','tool':n,'ts':int(time.time())}).encode()); s.close()" "${TOOL_NAME:-}" "$SOCKET" 2>/dev/null || true
fi
# Touch activity signal
touch "/Users/alcatraz627/.claude/subconscious/.last-activity"
