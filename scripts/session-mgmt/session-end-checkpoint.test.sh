#!/usr/bin/env bash
# Tests the session-end journal: session-journal.py (what it keeps and what it
# refuses to quote) and the SessionEnd wrapper (append, ingest, never block).
#
# Everything runs against temp fixtures and a throwaway HOME, so the owner's real
# checkpoint index and dream queue are never touched.
#
#   session-end-checkpoint.test.sh              run the suite
#   session-end-checkpoint.test.sh --mutations  break each guard in a copy and
#                                               require the suite to go red
#
# SJ_HELPER / SJ_WRAPPER point the suite at a mutated copy of either script.

set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REAL="$HOME/.claude"
HELPER_SRC="${SJ_HELPER:-$HERE/session-journal.py}"
WRAPPER_SRC="${SJ_WRAPPER:-$HERE/session-end-checkpoint.sh}"

if [[ "${1:-}" == "--mutations" ]]; then
  W="$(mktemp -d)"
  killed=0; total=0
  # name | script | python expression that breaks one guard (old => new)
  mutate() {
    local name="$1" kind="$2" old="$3" new="$4" src copy rc
    total=$((total+1))
    if [[ "$kind" == helper ]]; then src="$HERE/session-journal.py"; copy="$W/m$total.py"
    else src="$HERE/session-end-checkpoint.sh"; copy="$W/m$total.sh"; fi
    python3 -I - "$src" "$copy" "$old" "$new" <<'PY'
import sys
s = open(sys.argv[1]).read()
assert sys.argv[3] in s, "mutation target not found: " + sys.argv[3]
open(sys.argv[2], "w").write(s.replace(sys.argv[3], sys.argv[4], 1))
PY
    [[ $? -eq 0 ]] || { echo "  BAD MUTATION $name (target text missing)"; return; }
    if [[ "$kind" == helper ]]; then SJ_HELPER="$copy" bash "$0" >"$W/out$total" 2>&1; rc=$?
    else SJ_WRAPPER="$copy" bash "$0" >"$W/out$total" 2>&1; rc=$?; fi
    if [[ $rc -ne 0 ]]; then
      killed=$((killed+1)); echo "  killed   $name  ($(rg -c '^  FAIL' "$W/out$total") failing checks)"
    else echo "  SURVIVED $name"; fi
  }
  mutate "skip tool results"            helper 'b.get("type") == "tool_result" for b in c' 'b.get("type") == "tool_result_x" for b in c'
  mutate "strip hook injections"        helper '_REMINDER.sub("", c)' 'c'
  mutate "skip [keepwarm] as owner"     helper '"Caveat:", "[keepwarm]",' '"Caveat:",'
  mutate "drop wake replies"            helper ' and not in_wake' ''
  mutate "skip task notifications"      helper '"<task-notification", ' ''
  mutate "skip command stdout"          helper '"<local-command-stdout", ' ''
  mutate "skip Caveat scaffolding"      helper '"Caveat:", "[keepwarm]"' '"[keepwarm]"'
  mutate "skip isMeta"                  helper 'or e.get("isMeta")' ''
  mutate "dedupe cost by message id"    helper 'mid not in seen' 'True'
  mutate "owner clip length"            helper 'OWNER_KEEP, OWNER_CLIP = 40, 600' 'OWNER_KEEP, OWNER_CLIP = 40, 6000'
  mutate "keep only last 40 owner"      helper 'for ts, t in r["owner"][-OWNER_KEEP:]:' 'for ts, t in r["owner"]:'
  mutate "price table"                  helper '"sonnet": (2, 10, 0.20, 4)' '"sonnet": (0, 0, 0, 0)'
  mutate "skip ingest after core-dump"  wrapper '[[ -n "$dumped" ]]' '[[ -n "" ]]'
  mutate "prompt_input_exit bail"       wrapper '[[ "$reason" == "prompt_input_exit" ]] && exit 0' ':'
  mutate "no double journal on rerun"   wrapper "awk '/^## Session Journal\$/{f=1} END{exit !f}' \"\$dump_file\" && return 0" ":"
  echo "mutations killed: $killed/$total"
  trash "$W" 2>/dev/null || true
  [[ $killed -eq $total ]]; exit $?
fi

pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  ok   $1"; }
bad() { fail=$((fail+1)); echo "  FAIL $1"; }
check() { if eval "$2"; then ok "$1"; else bad "$1"; fi; }

T="$(mktemp -d)"
trap 'trash "$T" 2>/dev/null || true' EXIT

# ── fixture transcript ────────────────────────────────────────────────────────
python3 -I - "$T" <<'PY'
import json, sys, datetime as d
T = sys.argv[1]
now = d.datetime.now(d.timezone.utc)
n = [0]
def ts():
    n[0] += 1
    return (now - d.timedelta(seconds=120) + d.timedelta(seconds=10 * n[0])).strftime("%Y-%m-%dT%H:%M:%S.000Z")
L = []
def user(c, **kw): L.append({"type": "user", "timestamp": ts(), "message": {"role": "user", "content": c}, **kw})
def asst(blocks, mid, model="claude-sonnet-5-5", out=1000):
    L.append({"type": "assistant", "timestamp": ts(), "message": {"id": mid, "model": model, "role": "assistant",
              "content": blocks, "usage": {"input_tokens": 1000000, "output_tokens": out,
              "cache_read_input_tokens": 0, "cache_creation_input_tokens": 0}}})
user("OWNER_ONE please build the thing")
# One model message streamed as two entries sharing an id and a usage block.
asst([{"type": "text", "text": "thinking aloud MID_ONE"}], "m1", out=0)
asst([{"type": "tool_use", "name": "Write", "input": {"file_path": "/tmp/fx/a.txt", "content": "x"}},
      {"type": "tool_use", "name": "Edit", "input": {"file_path": "/tmp/fx/b.txt"}}], "m1", out=0)
user([{"type": "tool_result", "tool_use_id": "t1", "content": "ok"}, {"type": "text", "text": "TOOLRESULT_LEAK"}])
asst([{"type": "text", "text": "FINAL_ONE done"}], "m2", out=0)
user("<system-reminder>HOOKLEAK_ALONE</system-reminder>")
user("<system-reminder>HOOKLEAK_EMBEDDED</system-reminder>OWNER_TWO second ask")
user("[keepwarm] wake 3 of 5")
asst([{"type": "text", "text": "WAKE_REPLY chatter"}], "m3", out=0)
user("<task-notification><task-id>1</task-id>TASKLEAK</task-notification>")
user("<local-command-stdout>STDOUTLEAK</local-command-stdout>")
user("Caveat: CAVEATLEAK the messages below were generated")
user("<command-message>catchup</command-message>\n<command-name>/catchup</command-name>\n<command-args>CMDARG</command-args>")
user("META_LEAK", isMeta=True)
asst([{"type": "text", "text": "FINAL_TWO wrapped up"}], "m4", out=0)
user("LONG_START " + "w" * 1500 + " LONG_END")
asst([{"type": "text", "text": "FINAL_THREE"}], "m5", out=1000000)
def dump(name):
    with open(T + "/" + name, "w") as f:
        for e in L:
            f.write(json.dumps(e) + "\n")
dump("rich.jsonl")
# A separate long session for the keep-last-N limits.
L.clear()
for i in range(45):
    user(f"MANY_{i:02d} filler")
    asst([{"type": "text", "text": f"MANYREPLY_{i:02d}"}], f"x{i}", out=0)
dump("many.jsonl")
PY

# A git repo whose commit lands inside the fixture's time window.
R="$T/repo"; mkdir -p "$R"
git -C "$R" init -q
git -C "$R" -c user.name=t -c user.email=t@t commit -q --allow-empty -m "COMMIT_IN_WINDOW fix the thing"

run_helper() { python3 "$HELPER_SRC" --transcript "$T/rich.jsonl" --cwd "$R" "$@" 2>/dev/null; }
J="$(run_helper)"

echo "== journal content =="
check "owner message kept"                  '[[ "$J" == *OWNER_ONE* ]]'
check "owner message with embedded hook text keeps the owner part" '[[ "$J" == *"OWNER_TWO second ask"* ]]'
check "slash command shows with its args"   '[[ "$J" == *"/catchup CMDARG"* ]]'
check "final reply of a turn kept"          '[[ "$J" == *FINAL_ONE* && "$J" == *FINAL_TWO* && "$J" == *FINAL_THREE* ]]'
check "mid-turn chatter is not a final reply" '[[ "$J" != *MID_ONE* ]]'
check "commit in the window listed"         '[[ "$J" == *COMMIT_IN_WINDOW* ]]'
check "files written and edited listed"     '[[ "$J" == *"/tmp/fx/a.txt"* && "$J" == *"/tmp/fx/b.txt"* ]]'

echo "== what it must not quote =="
check "tool results skipped"                '[[ "$J" != *TOOLRESULT_LEAK* ]]'
check "hook injections skipped (alone)"     '[[ "$J" != *HOOKLEAK_ALONE* ]]'
check "hook injections skipped (embedded)"  '[[ "$J" != *HOOKLEAK_EMBEDDED* ]]'
check "[keepwarm] wakes skipped"            '[[ "$J" != *"wake 3 of 5"* ]]'
check "replies to a wake skipped"           '[[ "$J" != *WAKE_REPLY* ]]'
check "task notifications skipped"          '[[ "$J" != *TASKLEAK* ]]'
check "command stdout skipped"              '[[ "$J" != *STDOUTLEAK* ]]'
check "Caveat scaffolding skipped"          '[[ "$J" != *CAVEATLEAK* ]]'
check "isMeta skipped"                      '[[ "$J" != *META_LEAK* ]]'

echo "== limits and cost =="
check "owner message clipped to 600"        '[[ "$J" != *LONG_END* ]]'
M="$(python3 "$HELPER_SRC" --transcript "$T/many.jsonl" 2>/dev/null)"
check "owner messages: last 40 of 45 kept"  '[[ "$M" == *"## Owner Messages (40 of 45)"* && "$M" == *MANY_44* && "$M" == *MANY_05* && "$M" != *MANY_04* ]]'
check "final replies: last 15 of 45 kept"   '[[ "$M" == *"## Final Replies (15 of 45)"* && "$M" == *MANYREPLY_44* && "$M" == *MANYREPLY_30* && "$M" != *MANYREPLY_29* ]]'
# Distinct billed messages: m1 (streamed twice, billed once), m2..m5 = 5.
# Sonnet: 1M input = $2 each -> $10, plus m5's 1M output = $10.
check "cost is deduped by message id and priced" '[[ "$J" == *"\$20.00 API-price equivalent over 5 model calls"* ]]'
check "ingester headings present"           '[[ "$J" == *"## Session Insights"* && "$J" == *"**User feedback received:**"* && "$J" == *"**Notes for future agents:**"* ]]'

echo "== never fails the exit =="
python3 "$HELPER_SRC" --transcript "$T/nope.jsonl" >/dev/null 2>&1; rc=$?
check "missing transcript exits 0"          '[[ $rc -eq 0 ]]'
printf 'not json\n{"type":"user"\n' > "$T/junk.jsonl"
python3 "$HELPER_SRC" --transcript "$T/junk.jsonl" >/dev/null 2>&1; rc=$?
check "garbage transcript exits 0"          '[[ $rc -eq 0 ]]'
check "a spent budget stops the scan and exits 0" 'python3 "$HELPER_SRC" --transcript "$T/rich.jsonl" --budget 0 >/dev/null 2>&1'

# ── the wrapper, in a throwaway HOME ──────────────────────────────────────────
mkhome() {
  local h="$1"
  mkdir -p "$h/.claude/scripts/session-mgmt" "$h/.claude/scripts/checkpoint" "$h/.claude/subconscious/scripts" "$h/.claude/logs"
  cp -f "$WRAPPER_SRC" "$h/.claude/scripts/session-mgmt/session-end-checkpoint.sh"
  cp -f "$HELPER_SRC" "$h/.claude/scripts/session-mgmt/session-journal.py"
  cp -f "$HERE/pre-compact-checkpoint.sh" "$h/.claude/scripts/session-mgmt/"
  cp -f "$REAL/scripts/checkpoint/write.sh" "$h/.claude/scripts/checkpoint/"
  cp -f "$REAL/subconscious/scripts/ingest-checkpoint.sh" "$h/.claude/subconscious/scripts/"
}
fire() { # home sid reason transcript cwd
  jq -cn --arg s "$2" --arg r "$3" --arg t "$4" --arg c "$5" \
    '{session_id:$s,reason:$r,transcript_path:$t,cwd:$c}' \
    | HOME="$1" bash "$1/.claude/scripts/session-mgmt/session-end-checkpoint.sh" >/dev/null 2>&1
}
queue_count() { ls "$1/.claude/subconscious/dreams/ingest-queue" 2>/dev/null | wc -l | tr -d ' '; }
wait_queue() { local i; for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do [[ "$(queue_count "$1")" -ge 1 ]] && return 0; sleep 0.25; done; return 1; }

SID="aaaa1111-2222-3333-4444-555566667777"

echo "== wrapper: journal appended, ingested, snapshot intact =="
H1="$T/home1"; mkhome "$H1"; P1="$T/proj1"; mkdir -p "$P1"
fire "$H1" "$SID" other "$T/rich.jsonl" "$P1"; rc=$?
D1="$P1/_precompact-checkpoint.claude.md"
check "exits 0"                              '[[ $rc -eq 0 ]]'
check "snapshot file written"                '[[ -f "$D1" ]]'
check "existing snapshot headings intact"    'for h in "Initial Goal" "Agent Actions" "Current Expectation" "Pending Items"; do rg -q "^## $h\$" "$D1" || exit 1; done'
check "journal sections appended"            'rg -q "^## Session Journal\$" "$D1" && rg -q "^## Owner Messages" "$D1" && rg -q "^## Final Replies" "$D1" && rg -q "^## Session Commits" "$D1" && rg -q "^## Files Touched" "$D1" && rg -q "^## Session Cost" "$D1"'
check "journal carries the owner words"      'rg -q OWNER_ONE "$D1"'
check "index entry is still kind session-end" 'jq -e "select(.kind==\"session-end\" and .session_id==\"$SID\")" "$H1/.claude/checkpoints/index.jsonl" >/dev/null'
check "snapshot reaches the dream ingester"  'wait_queue "$H1"'
check "queue entry carries the owner words"  'rg -q OWNER_ONE "$H1"/.claude/subconscious/dreams/ingest-queue/*.json'
check "queue entry keyed by the transcript uuid" 'jq -e ".id==\"$SID\"" "$H1"/.claude/subconscious/dreams/ingest-queue/*.json >/dev/null'

echo "== wrapper: a real /core-dump already ran, no second ingest =="
H2="$T/home2"; mkhome "$H2"; P2="$T/proj2"; mkdir -p "$P2" "$H2/.claude/checkpoints"
printf '%s\n' "{\"ts\":\"2026-10-13T00:00:00Z\",\"session_id\":\"friendly-slug-ab\",\"session_uuid\":\"$SID\",\"kind\":\"core-dump\",\"checkpoint_path\":\"/x\"}" > "$H2/.claude/checkpoints/index.jsonl"
fire "$H2" "$SID" other "$T/rich.jsonl" "$P2"
sleep 1.5
check "journal still appended"               'rg -q "^## Session Journal\$" "$P2/_precompact-checkpoint.claude.md"'
check "nothing queued for the dream ingester" '[[ "$(queue_count "$H2")" -eq 0 ]]'

echo "== wrapper: rerun over a snapshot that already holds a journal =="
H3="$T/home3"; mkhome "$H3"; P3="$T/proj3"; mkdir -p "$P3"
fire "$H3" "$SID" other "$T/rich.jsonl" "$P3"
# A delegate that leaves the file alone, as when the snapshot step fails.
printf '#!/usr/bin/env bash\nexit 0\n' > "$H3/.claude/scripts/session-mgmt/pre-compact-checkpoint.sh"
fire "$H3" "$SID" other "$T/rich.jsonl" "$P3"
check "journal not stacked twice"            '[[ "$(rg -c "^## Session Journal\$" "$P3/_precompact-checkpoint.claude.md")" == 1 ]]'

echo "== wrapper: exits that must not journal or block =="
H4="$T/home4"; mkhome "$H4"; P4="$T/proj4"; mkdir -p "$P4"
fire "$H4" "$SID" prompt_input_exit "$T/rich.jsonl" "$P4"; rc=$?
check "ctrl-c at an empty prompt: exit 0, nothing written" '[[ $rc -eq 0 && ! -e "$P4/_precompact-checkpoint.claude.md" ]]'
fire "$H4" "$SID" other "$T/nope.jsonl" "$P4"; rc=$?
check "missing transcript: exit 0, snapshot kept, no journal" '[[ $rc -eq 0 && -f "$P4/_precompact-checkpoint.claude.md" ]] && ! rg -q "^## Session Journal\$" "$P4/_precompact-checkpoint.claude.md"'
printf '#!/usr/bin/env bash\nexit 3\n' > "$H4/.claude/scripts/session-mgmt/session-journal.py"
fire "$H4" "$SID" other "$T/rich.jsonl" "$P4"; rc=$?
check "a crashing helper still exits 0"      '[[ $rc -eq 0 ]]'
printf '' > /dev/null

echo "== speed =="
python3 -I - "$T" <<'PY'
import json, sys
T = sys.argv[1]
base = open(T + "/rich.jsonl").read()
pad = json.dumps({"type": "attachment", "attachment": {"blob": "z" * 4000}}) + "\n"
with open(T + "/big.jsonl", "w") as f:
    for _ in range(4):
        f.write(base)
    for _ in range(12000):
        f.write(pad)
PY
t0=$SECONDS
python3 "$HELPER_SRC" --transcript "$T/big.jsonl" --cwd "$R" >/dev/null 2>&1
dt=$((SECONDS - t0))
check "a ~50 MB transcript journals in under 5 s (${dt}s)" '[[ $dt -lt 5 ]]'

echo
echo "$pass/$((pass+fail)) passed"
[[ $fail -eq 0 ]]
