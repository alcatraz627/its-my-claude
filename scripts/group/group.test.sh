#!/usr/bin/env bash
set -uo pipefail; S=$HOME/.claude/scripts/group/group.sh; pass=0; fail=0
ok(){ pass=$((pass+1)); echo "  ok    $1"; }; ko(){ fail=$((fail+1)); echo "  FAIL  $1"; }
export GROUPS_DIR=$(mktemp -d); STUB="$GROUPS_DIR/ipc.log"; cat > "$GROUPS_DIR/ipc" <<EOS
#!/bin/bash
printf '%s\n' "\$*" >> "$STUB"
EOS
chmod +x "$GROUPS_DIR/ipc"; export GROUP_IPC_CMD="$GROUPS_DIR/ipc"
bash $S create g1 --goal "ship it" 2>/dev/null; [ $? -eq 2 ] && ok "create without --authority refused" || ko "authority required"
bash $S create g1 --goal "ship it" --authority "members may push feature branches; deploy needs the owner" >/dev/null && ok "create" || ko "create"
bash $S join g1 aaaa1111-0 --alias lane-a 2>/dev/null; [ $? -eq 2 ] && ok "member join without --store refused" || ko "store required"
bash $S join g1 aaaa1111-0 --alias lane-a --store aaaa1111 >/dev/null && bash $S join g1 bbbb2222-0 --alias lane-b --store bbbb2222 >/dev/null && bash $S join g1 wwww0000-0 --alias watch --watcher >/dev/null && ok "two members + a watcher joined" || ko "join"
[ "$(bash $S members g1 | wc -l | tr -d ' ')" = 2 ] && ok "members lists members only (watcher excluded from the revive roster)" || ko "members"
[ "$(bash $S store g1 bbbb2222-0)" = bbbb2222 ] && ok "store resolves per member" || ko "store"
bash $S store g1 wwww0000-0 >/dev/null 2>&1; [ $? -eq 1 ] && ok "no store -> exit 1 (fail closed)" || ko "store none"
: > "$STUB"; bash $S send g1 --from lane-a --kind request --reply-by 5m "need the schema" >/dev/null; [ "$(rg -c -- '--to' "$STUB")" = 2 ] && rg -q -- '--to lane-b' "$STUB" && rg -q -- '--to watch' "$STUB" && ! rg -q -- '--to lane-a' "$STUB" && ok "send fans out to every other member, sender excluded" || ko "send fanout"
: > "$STUB"; bash $S advise g1 --from lane-a "do X" >/dev/null 2>&1; [ $? -eq 1 ] && [ ! -s "$STUB" ] && ok "a member cannot advise (watcher-only verb)" || ko "advise gate"
: > "$STUB"; bash $S advise g1 --from watch "consider the smaller diff" >/dev/null; rg -q '\[ADVICE from watch\]' "$STUB" && rg -q 'kind inform' "$STUB" && ok "watcher advice is kind=inform with the [ADVICE] head and the refuse instruction" || ko "advise"
: > "$STUB"; bash $S stop g1 --from watch "you are editing the file lane-b owns" >/dev/null; rg -q '\[STOP from watch\]' "$STUB" && ok "watcher stop is [STOP], inform" || ko "stop"
: > "$STUB"; bash $S refuse msg-123 --from lane-b "the smaller diff drops the a11y guard" >/dev/null; rg -q 'reply msg-123 --from lane-b \[REFUSED\]' "$STUB" && jq -e 'select(.act=="refuse")' "$GROUPS_DIR/protocol.jsonl" >/dev/null && ok "refuse replies [REFUSED] and is logged for the owner" || ko "refuse"
! rg -q -- 'kind request' <(bash $S advise g1 --from watch "x" 2>&1; cat "$STUB") && ok "no instruction kind exists for a watcher (only inform via advise/stop)" || ko "no instruction"
trash "$GROUPS_DIR"; echo "---- pass=$pass fail=$fail"; [ $fail -eq 0 ]
