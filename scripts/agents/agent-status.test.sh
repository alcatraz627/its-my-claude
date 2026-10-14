#!/usr/bin/env bash
# agent-status.test.sh: builds fake subagent transcripts and checks each state, the exit codes and the output-path readers.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; S="${AGENT_STATUS_BIN:-$HERE/agent-status}"; pass=0; fail=0
ok(){ pass=$((pass+1)); echo "  ok    $1"; }; ko(){ fail=$((fail+1)); echo "  FAIL  $1"; }
T=$(mktemp -d); export AGENT_STATUS_PROJECTS="$T/projects"
SID=11111111-2222-3333-4444-555555555555
PROJ="$AGENT_STATUS_PROJECTS/-proj"; SUB="$AGENT_STATUS_PROJECTS/-proj/$SID/subagents"; mkdir -p "$SUB"
OLD=202001010000

# mk NAME PROMPT LAST [mtime]   LAST is one of: tool_use, end_turn, attachment
mk(){
  local f="$SUB/agent-$1.jsonl"
  jq -nc --arg p "$2" '{type:"user",timestamp:"2026-10-14T19:41:19.622Z",message:{role:"user",content:$p}}' > "$f"
  case "$3" in
    tool_use) echo '{"type":"assistant","timestamp":"2026-10-14T19:42:00.000Z","message":{"role":"assistant","stop_reason":"tool_use","content":[{"type":"tool_use"}]}}' >> "$f" ;;
    end_turn) echo '{"type":"assistant","timestamp":"2026-10-14T19:42:00.000Z","message":{"role":"assistant","stop_reason":"end_turn","content":[{"type":"text","text":"done"}]}}' >> "$f" ;;
    attachment) echo '{"type":"assistant","timestamp":"2026-10-14T19:42:00.000Z","message":{"role":"assistant","stop_reason":"end_turn","content":[{"type":"text","text":"done"}]}}' >> "$f"
                echo '{"type":"attachment","timestamp":"2026-10-14T19:42:01.000Z","attachment":{"type":"x"}}' >> "$f" ;;
  esac
  [ -n "${4:-}" ] && touch -t "$4" "$f"
  echo "{\"name\":\"$1\"}" > "$SUB/agent-$1.meta.json"
}
st(){ python3 "$S" --project "$PROJ" --session "$SID" "$1" 2>&1 | rg "^[A-Z]+ +$1 " | awk '{print $1}'; }

echo hello > "$T/fresh.md"
: > "$T/empty.md"
echo stale > "$T/stale.md"; touch -t $OLD "$T/stale.md"

mk running   "do work. output=$T/none1.md" tool_use
mk stalled   "do work. output=$T/none2.md" tool_use $OLD
mk deliv     "[seat x] output=$T/fresh.md" end_turn
mk missing   "[seat x] output=$T/never.md" end_turn
mk emptyfile "[seat x] output=$T/empty.md" end_turn
mk stalefile "[seat x] output=$T/stale.md" end_turn
mk idle      "just chat with me, no file named" end_turn
mk attach    "[seat x] output=$T/fresh.md" attachment
mk mate      "$(printf 'You are building things.\nRead %s/ctx.md first, then write the plan.\nOUTPUT: write %s/fresh.md BEFORE returning. Return only a verdict.' "$T" "$T")" end_turn

echo "== states =="
[ "$(st running)" = RUNNING ] && ok "recent write, mid-work: RUNNING" || ko "running: $(st running)"
[ "$(st stalled)" = STALLED ] && ok "old write, mid-work: STALLED" || ko "stalled: $(st stalled)"
[ "$(st deliv)" = DELIVERED ] && ok "turn ended, output file present: DELIVERED" || ko "deliv: $(st deliv)"
[ "$(st missing)" = EMPTY ] && ok "turn ended, output file missing: EMPTY" || ko "missing: $(st missing)"
[ "$(st emptyfile)" = EMPTY ] && ok "turn ended, output file zero bytes: EMPTY" || ko "emptyfile: $(st emptyfile)"
[ "$(st stalefile)" = EMPTY ] && ok "output file older than the dispatch does not count: EMPTY" || ko "stalefile: $(st stalefile)"
[ "$(st idle)" = IDLE ] && ok "turn ended, no output path named: IDLE" || ko "idle: $(st idle)"
[ "$(st attach)" = DELIVERED ] && ok "a trailing attachment record does not hide the end of turn" || ko "attach: $(st attach)"
[ "$(st mate)" = DELIVERED ] && ok "teammate brief: the OUTPUT line path is read, not the Context line" || ko "mate: $(st mate)"

echo "== exit codes =="
python3 "$S" --project "$PROJ" --session "$SID" >/dev/null 2>&1; [ $? = 1 ] && ok "STALLED or EMPTY present: exit 1" || ko "exit with problems"
python3 "$S" --project "$PROJ" --session "$SID" deliv >/dev/null 2>&1; [ $? = 0 ] && ok "only DELIVERED in the filter: exit 0" || ko "exit clean"
python3 "$S" --project "$PROJ" --session nosuch >/dev/null 2>&1; [ $? = 2 ] && ok "unknown session: exit 2" || ko "exit unknown session"
python3 "$S" --project "$PROJ" --session "$SID" --json deliv 2>/dev/null | jq -e '.[0].state=="DELIVERED" and (.[0].output|endswith("fresh.md"))' >/dev/null \
  && ok "--json carries state and output" || ko "--json shape"

echo "== mutations (each fix reverted alone must turn its test red) =="
MUT="$T/agent-status.mut"
mutate(){ cp "$HERE/agent-status" "$MUT"; python3 - "$MUT" "$1" "$2" <<'PY'
import sys; p, a, b = sys.argv[1:4]; s = open(p).read(); assert a in s, "anchor missing: " + a; open(p, "w").write(s.replace(a, b, 1))
PY
}
red(){ # red LABEL NAME EXPECTED  (run mutant, expect the state to differ from EXPECTED)
  local got; got=$(python3 "$MUT" --project "$PROJ" --session "$SID" "$2" 2>&1 | rg "^[A-Z]+ +$2 " | awk '{print $1}')
  [ -n "$got" ] && [ "$got" != "$3" ] && ok "$1 goes red under mutation (got ${got:-nothing})" || ko "FAILED GUARD: $1 stayed green with the fix removed"
}
mutate 'if st.st_size > 0 and (since is None or st.st_mtime >= since):' 'if st.st_size > 0:'
red "newer-than-dispatch check" stalefile EMPTY
mutate 'if st.st_size > 0 and (since' 'if (since'
red "non-empty check" emptyfile EMPTY
mutate 'if rec.get("type") in ("user", "assistant"):' 'if True:'
red "attachment skip" attach DELIVERED
mutate 'state = "STALLED" if age > stale else "RUNNING"' 'state = "RUNNING"'
red "stall threshold" stalled STALLED
mutate 'msg.get("stop_reason") not in (None, "tool_use")' 'msg.get("stop_reason") is not None'
red "end-of-turn read of tool_use" running RUNNING
mutate 'for line in reversed(text.splitlines()):' 'for line in text.splitlines():'
red "last-line-wins path reader" mate DELIVERED
trash "$MUT" 2>/dev/null || true

trash "$T" 2>/dev/null || true
echo "---- pass=$pass fail=$fail"; [ $fail -eq 0 ]
