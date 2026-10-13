#!/usr/bin/env bash
# Tests for gather.sh, the one-call fact sheet /core-dump reads before writing.
#
# What goes wrong without it is the model recalling facts at 750k context and
# getting them wrong: the wrong goal, a dump when nothing changed, a caveat diff
# against another session's file. Every row runs against a fake HOME and a fake
# transcript, never the owner's real checkpoints index; the first and last rows
# prove that by comparing the real index before and after.
#
# GATHER=<path> runs the same rows against a mutated copy (mutation proofs).

set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
GATHER="${GATHER:-$HERE/gather.sh}"
FIX="$HERE/ckfixture.py"

pass=0; total=0
ok()  { pass=$((pass+1)); total=$((total+1)); [ -n "${CK_TEST_QUIET:-}" ] || echo "  PASS $1"; }
bad() { total=$((total+1)); echo "  FAIL $1"; }
check() {  # check <label> <haystack> <needle>
  case "$2" in *"$3"*) ok "$1";; *) bad "$1 (wanted: $3)"; printf '       got: %s\n' "$2" | head -c 600; echo;; esac
}
lacks() {  # lacks <label> <haystack> <needle>
  case "$2" in *"$3"*) bad "$1 (should not contain: $3)";; *) ok "$1";; esac
}

REAL_CKDIR="${CK_TEST_REAL_CKDIR:-$HOME/.claude/checkpoints}"

T=$(cd "$(mktemp -d)" && pwd -P)
export HOME="$T/home"
unset CLAUDE_CODE_SESSION_ID
export CK_IPC_CMD="bash $T/fake-ipc.sh"
UUID="aaaaaaaa-1111-2222-3333-444444444444"
SID="fix-auth-3b"
PROJ="$T/proj"
ENC=$(printf '%s' "$PROJ" | sed 's#[/.]#-#g')
mkdir -p "$HOME/.claude/projects/$ENC" "$HOME/.claude/checkpoints" "$HOME/.claude/goals" \
         "$HOME/.claude/atone" "$HOME/.claude/.turn-state" "$HOME/.claude/tasks" "$PROJ/.claude" "$PROJ/sub/dir"
git -C "$PROJ" init -q 2>/dev/null
printf 'a\n' > "$PROJ/one.txt"; printf 'b\n' > "$PROJ/two.txt"

TX="$HOME/.claude/projects/$ENC/$UUID.jsonl"
build() { python3 "$FIX" "$T/spec.json" "$TX"; }

cat > "$T/fake-ipc.sh" <<EOF
printf '{"peers":[{"sessionId":"svc:x","aliases":["x"],"status":"live"},{"sessionId":"$UUID","aliases":["fix-auth-alias"],"status":"live"}]}'
EOF

G() { bash "$GATHER" --uuid "$UUID" --session-id "$SID" --cwd "$PROJ" 2>&1; }
field() { printf '%s\n' "$OUT" | sed -n "s/^$1: //p"; }

# A busy session: four real owner prompts among everything that is NOT the owner.
cat > "$T/spec.json" <<EOF
[
 {"role":"owner","ts":"2026-10-13T08:00:00Z","text":"fix the login bug"},
 {"role":"assistant","ts":"2026-10-13T08:00:05Z","id":"msg_1","text":"on it","writes":["$PROJ/a.py"],"task_subjects":["Write the gather test script","Write the finalize test script"]},
 {"role":"tool_result","ts":"2026-10-13T08:00:06Z"},
 {"role":"owner","ts":"2026-10-13T08:01:00Z","text":"<task-notification>build finished</task-notification>","origin":"task-notification"},
 {"role":"owner","ts":"2026-10-13T08:01:30Z","text":"[keepwarm] wake"},
 {"role":"owner","ts":"2026-10-13T08:01:40Z","text":"hook injected context","meta":true},
 {"role":"owner","ts":"2026-10-13T08:01:50Z","text":"plain looking text from a harness producer","origin":"system"},
 {"role":"owner","ts":"2026-10-13T08:02:00Z","text":"also handle logout"},
 {"role":"assistant","ts":"2026-10-13T08:02:05Z","id":"msg_2","edits":["$PROJ/b.py","$PROJ/a.py"]},
 {"role":"owner","ts":"2026-10-13T08:03:00Z","text":"<command-name>/core-dump</command-name><command-args></command-args>"},
 {"role":"owner","ts":"2026-10-13T08:04:00Z","text":"push it to the branch"},
 {"role":"assistant","ts":"2026-10-13T08:04:05Z","id":"msg_3","text":"pushed","writes":["$PROJ/c.py","$PROJ/d.py"]},
 {"role":"owner","ts":"2026-10-13T08:05:00Z","text":"and write the docs"}
]
EOF
build

echo "== the first and last rows guard the owner's real index =="
check "fake HOME is not the real one" "$HOME" "$T/home"

echo "== a busy session =="
OUT=$(G); rc=$?
[ "$rc" = 0 ] && ok "exits 0" || bad "exit $rc"
for k in session_id uuid now project_root working_surface default_file transcript session_size depth_hint \
         files_touched existing_dump previous_dump_same_stem goal_harness goal_gcc goal_record task_store \
         wake deadline ipc_alias atone_ids pending_codes; do
  printf '%s\n' "$OUT" | rg -q "^$k: " || { bad "field $k missing"; missing=1; }
done
[ -z "${missing:-}" ] && ok "every contract field is printed"
check "project root found" "$(field project_root)" "$PROJ"
check "transcript path" "$(field transcript)" "$TX"
check "default file is _YYYYMMDD-<sid>.claude.md under the root" "$(field default_file)" "$PROJ/_$(date +%Y%m%d)-$SID.claude.md"
check "session id echoed with its source" "$(field session_id)" "fix-auth-3b (from --session-id)"
# 4 real prompts (fix, also, push, docs); the notification, wake, meta line and the /core-dump command are not.
check "owner prompts exclude notifications, wakes, meta lines and the dump command" "$(field session_size)" "4 owner prompts"
check "distinct assistant messages counted" "$(field session_size)" "3 assistant turns"
check "files written or edited are de-duplicated" "$(field session_size)" "4 files written or edited"
check "busy session reads full" "$(field depth_hint)" "full"

echo "== the light threshold =="
cat > "$T/spec.json" <<EOF
[
 {"role":"owner","ts":"2026-10-13T08:00:00Z","text":"rename the variable"},
 {"role":"assistant","ts":"2026-10-13T08:00:05Z","id":"msg_1","edits":["$PROJ/a.py"]},
 {"role":"owner","ts":"2026-10-13T08:01:00Z","text":"thanks"}
]
EOF
build; OUT=$(G)
check "2 prompts and 1 file is light" "$(field depth_hint)" "light"
cat > "$T/spec.json" <<EOF
[
 {"role":"owner","ts":"2026-10-13T08:00:00Z","text":"one"},
 {"role":"assistant","ts":"2026-10-13T08:00:05Z","id":"msg_1","edits":["$PROJ/a.py","$PROJ/b.py","$PROJ/c.py","$PROJ/d.py"]}
]
EOF
build; OUT=$(G)
check "one prompt but 4 files is full" "$(field depth_hint)" "full"
cat > "$T/spec.json" <<EOF
[
 {"role":"owner","ts":"2026-10-13T08:00:00Z","text":"one"},{"role":"owner","ts":"2026-10-13T08:00:01Z","text":"two"},
 {"role":"owner","ts":"2026-10-13T08:00:02Z","text":"three"},{"role":"owner","ts":"2026-10-13T08:00:03Z","text":"four"}
]
EOF
build; OUT=$(G)
check "4 prompts and no files is full" "$(field depth_hint)" "full"

echo "== working surface and project root =="
OUT=$(bash "$GATHER" --uuid "$UUID" --session-id "$SID" --cwd "$PROJ/sub/dir" 2>&1)
check "root found by walking up from a subdirectory" "$(field project_root)" "$PROJ"
check "git toplevel, branch, tracking and dirty count" "$(field working_surface)" "$PROJ · branch "
check "dirty files counted" "$(field working_surface)" "no upstream · 2 dirty files"
OUT=$(bash "$GATHER" --uuid "$UUID" --session-id "$SID" --cwd "$T" 2>&1)
check "a directory that is not a repo degrades, does not fail" "$(field working_surface)" "unknown (not a git repo"

echo "== session id and uuid defaults =="
OUT=$(CLAUDE_CODE_SESSION_ID="$UUID" bash "$GATHER" --cwd "$PROJ" 2>&1)
check "uuid from CLAUDE_CODE_SESSION_ID" "$(field uuid)" "$UUID (from CLAUDE_CODE_SESSION_ID)"
check "with no name and nothing indexed the sid is the uuid's first 8" "$(field session_id)" "aaaaaaaa (from first 8"
printf '%s\n' "$UUID" > "$HOME/.claude/.current-session-id"
OUT=$(bash "$GATHER" --cwd "$PROJ" 2>&1)
check "uuid falls back to the session-id file" "$(field uuid)" "$UUID (from .current-session-id"
printf '{"session_id":"indexed-name-9z","session_uuid":"%s","kind":"core-dump","checkpoint_path":"/none"}\n' "$UUID" > "$HOME/.claude/checkpoints/index.jsonl"
OUT=$(bash "$GATHER" --cwd "$PROJ" 2>&1)
check "sid falls back to the indexed name for this uuid" "$(field session_id)" "indexed-name-9z"
trash "$HOME/.claude/checkpoints/index.jsonl" "$HOME/.claude/.current-session-id"

echo "== existing_dump: only when no owner turn came after it =="
cat > "$T/spec.json" <<EOF
[
 {"role":"owner","ts":"2026-10-13T08:00:00Z","text":"do the thing"},
 {"role":"assistant","ts":"2026-10-13T08:00:05Z","id":"msg_1","writes":["$PROJ/_20261013-$SID.claude.md"]},
 {"role":"owner","ts":"2026-10-13T08:30:00Z","text":"<command-name>/core-dump</command-name><command-args></command-args>"}
]
EOF
build
printf '# Core Dump\n' > "$PROJ/_20261013-$SID.claude.md"
OUT=$(G)
check "a dump written after the last real owner turn is reported" "$(field existing_dump)" "no owner turn since"
check "it names the file" "$(field existing_dump)" "$PROJ/_20261013-$SID.claude.md"
touch -t 202001010000 "$PROJ/_20261013-$SID.claude.md"
OUT=$(G)
check "an owner turn newer than the dump means none" "$(field existing_dump)" "none"
trash "$PROJ/_20261013-$SID.claude.md"
OUT=$(G)
check "no dump file at all is none" "$(field existing_dump)" "none"
# the pointer route: a dump the transcript never shows being written
printf '# Core Dump\n' > "$PROJ/_pointer-dump.claude.md"
printf '{"session_id":"%s","session_uuid":"%s","kind":"core-dump","checkpoint_path":"%s"}\n' "$SID" "$UUID" "$PROJ/_pointer-dump.claude.md" > "$HOME/.claude/checkpoints/index.jsonl"
OUT=$(G)
check "a dump known only from the index is found by uuid" "$(field existing_dump)" "_pointer-dump.claude.md"
printf '{"session_id":"%s","session_uuid":"%s","kind":"precompact","checkpoint_path":"%s"}\n' "$SID" "$UUID" "$PROJ/_pointer-dump.claude.md" > "$HOME/.claude/checkpoints/index.jsonl"
OUT=$(G)
check "a shell-only precompact snapshot is not a dump" "$(field existing_dump)" "none"
trash "$HOME/.claude/checkpoints/index.jsonl" "$PROJ/_pointer-dump.claude.md"

echo "== existing_dump: agent work after the dump means a fresh dump is needed =="
setmt() {  # setmt <file> <UTC time>
  python3 -c 'import os,sys,calendar,time; t=calendar.timegm(time.strptime(sys.argv[2],"%Y-%m-%dT%H:%M:%SZ")); os.utime(sys.argv[1],(t,t))' "$1" "$2"
}
DUMP="$PROJ/_20261013-$SID.claude.md"
work_spec() {  # work_spec <extra events…>: owner asks, agent writes the dump, owner runs /core-dump, then the extras
  local extra=""; [ $# -gt 0 ] && extra=",$*"
  cat > "$T/spec.json" <<EOF
[
 {"role":"owner","ts":"2026-10-13T08:00:00Z","text":"do the thing"},
 {"role":"assistant","ts":"2026-10-13T08:00:05Z","id":"msg_1","writes":["$DUMP"]},
 {"role":"owner","ts":"2026-10-13T08:05:00Z","text":"<command-name>/core-dump</command-name><command-args></command-args>"}$extra
]
EOF
  build
}
printf '# Core Dump\n' > "$DUMP"; setmt "$DUMP" 2026-10-13T08:10:00Z
work_spec
OUT=$(G)
check "no later work: the dump still stands" "$(field existing_dump)" "no owner turn since"
work_spec '{"role":"assistant","ts":"2026-10-13T09:00:00Z","id":"msg_2","edits":["'"$PROJ"'/b.py"]}'
OUT=$(G)
check "an hour of edits after the dump means there is none" "$(field existing_dump)" "none (agent work since the dump)"
work_spec '{"role":"owner","ts":"2026-10-13T09:00:00Z","text":"[keepwarm] wake"},{"role":"assistant","ts":"2026-10-13T09:00:05Z","id":"msg_2","writes":["'"$DUMP"'"]}'
OUT=$(G)
check "tool use that only answers a keep-warm wake is not new work" "$(field existing_dump)" "no owner turn since"
work_spec '{"role":"assistant","ts":"2026-10-13T08:11:00Z","id":"msg_2","edits":["'"$PROJ"'/b.py"]}'
OUT=$(G)
check "a call inside the grace window (finalize right after the Write) is not new work" "$(field existing_dump)" "no owner turn since"
trash "$DUMP"

echo "== previous_dump_same_stem matches the name stem, never the newest of any stem =="
printf '# old\n' > "$PROJ/_20261001-$SID.claude.md"; touch -t 202610010000 "$PROJ/_20261001-$SID.claude.md"
printf '# other\n' > "$PROJ/_20261012-other-stem.claude.md"
printf '# lookalike\n' > "$PROJ/_20261012-not-$SID.claude.md"
OUT=$(G)
check "the same-stem file is chosen over a newer other-stem file" "$(field previous_dump_same_stem)" "$PROJ/_20261001-$SID.claude.md"
lacks "a file that merely ends with the stem is not a match" "$(field previous_dump_same_stem)" "not-$SID"
trash "$PROJ/_20261001-$SID.claude.md"
OUT=$(G)
check "no same-stem file means none" "$(field previous_dump_same_stem)" "none"
printf '# today before overwrite\n' > "$PROJ/_$(date +%Y%m%d)-$SID.claude.md"
OUT=$(G)
SNAP=$(printf '%s' "$(field previous_dump_same_stem)" | sed 's/ (.*//')
check "today's file is copied aside before the Write overwrites it" "$(cat "$SNAP" 2>/dev/null)" "today before overwrite"
check "the field is a bare path, so it can be pasted as is" "$(field previous_dump_same_stem)" "$HOME/.claude/checkpoints/.prev/aaaaaaaa-$SID.md"
[ -f "$(field previous_dump_same_stem)" ] && ok "and that path is a real file" || bad "field is not a file path: $(field previous_dump_same_stem)"
check "the explanation is its own line" "$(field previous_dump_note)" "copy of today's"
printf '# old\n' > "$PROJ/_20261001-$SID.claude.md"; touch -t 202610010000 "$PROJ/_20261001-$SID.claude.md"
trash "$PROJ/_$(date +%Y%m%d)-$SID.claude.md"
OUT=$(G)
lacks "a plain previous dump comes with no note line" "$OUT" "previous_dump_note:"
trash "$PROJ/_20261001-$SID.claude.md"
printf '# today before overwrite\n' > "$PROJ/_$(date +%Y%m%d)-$SID.claude.md"
trash "$PROJ/_$(date +%Y%m%d)-$SID.claude.md" "$PROJ/_20261012-other-stem.claude.md" "$PROJ/_20261012-not-$SID.claude.md"

echo "== goal, goal record, wake, deadline =="
cat > "$HOME/.claude/goals/$UUID.json" <<EOF
{"set": true, "text": "Ship the importer and prove it", "by": "owner", "sid": "$UUID", "set_at": "2026-10-13T09:00:00Z", "goal_id": "abc123def456"}
EOF
printf '{"wake":"in 20m check CI"}\n' > "$HOME/.claude/.turn-state/$UUID.json"
mkdir -p "$HOME/.claude/skills/deadline"
printf '# runtime notes\n\n## deadline: ship importer due Fri 5pm LIVE\n- x\n' > "$HOME/.claude/skills/deadline/runtime-notes.md"
OUT=$(G)
check "gcc goal text is carried" "$(field goal_gcc)" "Ship the importer and prove it"
check "goal record id read from the session pointer" "$(field goal_record)" "abc123def456"
check "wake read from the turn-state file" "$(field wake)" "in 20m check CI"
check "deadline line read from the skill's notes" "$(field deadline)" "ship importer due Fri 5pm LIVE"
trash "$HOME/.claude/goals/$UUID.json" "$HOME/.claude/.turn-state/$UUID.json"
OUT=$(G)
check "no goal pointer says none" "$(field goal_record)" "none"
check "no turn-state file degrades" "$(field wake)" "unknown (no turn-state file"

echo "== task store is resolved by content, not by name =="
mkdir -p "$HOME/.claude/tasks/session-feedface"
printf '{"subject":"Write the gather test script"}\n' > "$HOME/.claude/tasks/session-feedface/1.json"
printf '{"subject":"Write the finalize test script"}\n' > "$HOME/.claude/tasks/session-feedface/2.json"
cat > "$T/spec.json" <<EOF
[
 {"role":"owner","ts":"2026-10-13T08:00:00Z","text":"go"},
 {"role":"assistant","ts":"2026-10-13T08:00:05Z","id":"msg_1","task_subjects":["Write the gather test script","Write the finalize test script"]}
]
EOF
build
OUT=$(G)
check "the store holding this session's task subjects is named" "$(field task_store)" "$HOME/.claude/tasks/session-feedface"

echo "== atone ids come from this session's window =="
cat > "$HOME/.claude/atone/events.jsonl" <<EOF
{"id":"mist-before","ts":"2026-10-13T07:00:00Z","slug":"too-early","severity":"S1","session_id":"$UUID"}
{"id":"mist-mine","ts":"2026-10-13T08:03:00Z","slug":"checkpoint-compression","severity":"S2","session_id":"$UUID"}
{"id":"mist-theirs","ts":"2026-10-13T08:04:00Z","slug":"other-slug","severity":"S3","session_id":"99999999-0000-0000-0000-000000000000"}
{"id":"mist-after","ts":"2026-10-13T08:40:00Z","slug":"later-session","severity":"S3","session_id":"$UUID"}
EOF
OUT=$(G)
check "an event inside the window and this session is listed with slug and severity" "$(field atone_ids)" "mist-mine (checkpoint-compression, S2)"
lacks "an event from before the session started is not" "$(field atone_ids)" "mist-before"
lacks "an event recorded after the session's last message is not listed" "$(field atone_ids)" "mist-after"
lacks "another session's event is not listed" "$(field atone_ids)" "mist-theirs"
check "another session's event is counted, not hidden" "$(field atone_ids)" "1 event(s) from other sessions"
trash "$HOME/.claude/atone/events.jsonl"
OUT=$(G)
check "no event log says none" "$(field atone_ids)" "none"

echo "== pending approval codes =="
printf '{"nonce":"c0ffee11","target":"git push origin main","why":"protected repo","ts":1}\n' > "$HOME/.claude/.push-nonce-$UUID"
mkdir -p "$HOME/.claude/.policy-ask"
printf '{"nonce":"beef0042","key":"deploy.vercel","what":"a Vercel deploy","ts":2}\n' > "$HOME/.claude/.policy-ask/$UUID--deploy.vercel.nonce"
OUT=$(G)
check "push nonce prints target and code" "$(field pending_codes)" "git push origin main · nonce c0ffee11"
check "policy ask prints what and code" "$(field pending_codes)" "a Vercel deploy (policy deploy.vercel) · nonce beef0042"
printf '{"nonce":"zzzz","target":"another session","ts":1}\n' > "$HOME/.claude/.push-nonce-other-session"
OUT=$(G)
lacks "another session's nonce file is never listed" "$(field pending_codes)" "another session"
trash "$HOME/.claude/.push-nonce-$UUID" "$HOME/.claude/.policy-ask/$UUID--deploy.vercel.nonce" "$HOME/.claude/.push-nonce-other-session"
OUT=$(G)
check "no nonce files says none" "$(field pending_codes)" "none"

echo "== ipc alias =="
OUT=$(G)
check "alias found by session uuid in the roster" "$(field ipc_alias)" "fix-auth-alias (live)"
OUT=$(CK_IPC_CMD="bash $T/no-such-script.sh" G)
check "a failing ipc command degrades" "$(field ipc_alias)" "unknown ("
OUT=$(CK_IPC_CMD="/no/such/binary" G)
check "a missing ipc binary degrades" "$(field ipc_alias)" "unknown (command not found"

echo "== one malformed state file costs one field, not the block =="
printf '[1,2,3]\n' > "$HOME/.claude/goals/$UUID.json"
printf '"just a string"\n' > "$HOME/.claude/.turn-state/$UUID.json"
OUT=$(G); rc=$?
[ "$rc" = 0 ] && ok "exit 0 with a goal pointer that is a JSON list" || bad "exit $rc"
check "the broken field says it is unknown" "$(field goal_record)" "unknown ("
check "a neighbouring field is unaffected" "$(field project_root)" "$PROJ"
check "a second malformed file degrades its own field" "$(field wake)" "unknown ("
trash "$HOME/.claude/goals/$UUID.json" "$HOME/.claude/.turn-state/$UUID.json"

echo "== a missing transcript degrades and never fails the dump =="
trash "$TX"
OUT=$(G); rc=$?
[ "$rc" = 0 ] && ok "still exits 0" || bad "exit $rc without a transcript"
check "transcript says why" "$(field transcript)" "unknown (no transcript"
check "session size says why" "$(field session_size)" "unknown ("
check "other fields still print" "$(field project_root)" "$PROJ"

echo "== speed: a large transcript is streamed, not loaded twice =="
python3 - "$T/big.json" "$PROJ" <<'PY'
import json, sys
proj = sys.argv[2]
ev = [{"role": "owner", "ts": "2026-10-13T08:00:00Z", "text": "start"}]
for i in range(400):
    ev.append({"role": "filler", "bytes": 60000})
    ev.append({"role": "tool_result", "ts": "2026-10-13T08:01:00Z", "bytes": 60000})
    ev.append({"role": "assistant", "ts": "2026-10-13T08:02:00Z", "id": "msg_%d" % i, "text": "t" * 500,
               "edits": [proj + "/f%d.py" % (i % 50)]})
json.dump(ev, open(sys.argv[1], "w"))
PY
python3 "$FIX" "$T/big.json" "$TX"
SIZE=$(stat -f %z "$TX")
START=$(date +%s)
OUT=$(G)
SECS=$(( $(date +%s) - START ))
[ "$SECS" -lt 5 ] && ok "$((SIZE/1000000)) MB transcript gathered in ${SECS}s (limit 5)" || bad "took ${SECS}s on $SIZE bytes"
check "and the counts are still right" "$(field session_size)" "1 owner prompts · 400 assistant turns · 50 files"

echo "== the owner's real index was not touched =="
# Other live sessions legitimately write the real index while this runs, so look for
# THIS run's identifiers in it rather than for any change.
LEAK=$(rg -l --hidden --no-ignore -F -e "$UUID" -e "$T" "$REAL_CKDIR" 2>/dev/null | head -3)
[ -z "$LEAK" ] && ok "nothing of this run reached the real checkpoints directory" || bad "leaked into the real directory: $LEAK"

echo "---"; echo "$pass/$total passed"
[ "$pass" -eq "$total" ]
