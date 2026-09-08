#!/usr/bin/env bash
# Tests for resolve.sh --auto --cwd and list.sh --cwd: the two rungs that let a
# resume be confidently wrong on 2026-09-07 (ledger 4: a killed session's stub
# outranked an 11-hour-old core-dump; ledger 25: six other projects' entries
# filled the picker while the cwd's own seven files sat unlisted).
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
RESOLVE="$HERE/resolve.sh"; LIST="$HERE/list.sh"
T=$(mktemp -d); export HOME="$T"
mkdir -p "$T/.claude/checkpoints" "$T/projA" "$T/projB"
INDEX="$T/.claude/checkpoints/index.jsonl"
A="$T/projA"; B="$T/projB"
pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  ok    $1"; }
bad() { fail=$((fail+1)); echo "  FAIL  $1"; }

fresh() { date -u -v-5M "+%Y-%m-%dT%H:%M:%SZ"; }
old()   { date -u -v-11H "+%Y-%m-%dT%H:%M:%SZ"; }
entry() { # entry <ts> <sid> <project> <path> <name> <kind>
  jq -cn --arg ts "$1" --arg s "$2" --arg p "$3" --arg c "$4" --arg n "$5" --arg k "$6" \
    '{ts:$ts, session_id:$s, session_uuid:"", project_root:$p, checkpoint_path:$c, name:$n, summary:"s", kind:$k}' >> "$INDEX"
}
auto() { bash "$RESOLVE" --auto --cwd "$1" 2>/dev/null; }
reset() { : > "$INDEX"; rm -f "$A"/_*.claude.md "$B"/_*.claude.md; }

echo "== one fresh entry for the cwd resolves =="
reset; entry "$(fresh)" a1 "$A" "$A/_x.claude.md" a-dump core-dump
out=$(auto "$A"); rc=$?
[ "$rc" = 0 ] && printf '%s' "$out" | rg -q '"name": ?"a-dump"' && ok "auto picks the cwd's fresh core-dump" || bad "auto rc=$rc out=$out"

echo "== another project's fresh entry never outranks files on disk here =="
reset; entry "$(fresh)" b1 "$B" "$B/_y.claude.md" b-dump core-dump
touch "$A/_20260905-mine.claude.md"
auto "$A" >/dev/null; rc=$?
[ "$rc" = 2 ] && ok "defers to the picker (rc 2)" || bad "served project B over A's own files (rc=$rc)"
rm -f "$A/_20260905-mine.claude.md"
out=$(auto "$A"); rc=$?
[ "$rc" = 0 ] && ok "with nothing on disk here, the fresh entry still resolves" || bad "rc=$rc with an empty cwd"

echo "== a shell-only snapshot never wins outright over a real dump for that project =="
reset; entry "$(old)" a0 "$A" "$A/_20260906-old.claude.md" old-dump core-dump
entry "$(fresh)" a1 "$A" "$A/_precompact-checkpoint.claude.md" session-end-a1 session-end
auto "$A" >/dev/null; rc=$?
[ "$rc" = 2 ] && ok "session-end stub + 11h-old core-dump: picker (ledger 4)" || bad "the stub won (rc=$rc)"
reset; entry "$(fresh)" a1 "$A" "$A/_precompact-checkpoint.claude.md" precompact-a1 precompact
out=$(auto "$A"); rc=$?
[ "$rc" = 0 ] && ok "a precompact with no dump behind it still auto-resolves" || bad "precompact alone refused (rc=$rc)"

echo "== several fresh, exactly one is ours =="
reset; entry "$(fresh)" a1 "$A" "$A/_a.claude.md" a-dump core-dump
entry "$(fresh)" b1 "$B" "$B/_b.claude.md" b-dump core-dump
out=$(auto "$A"); rc=$?
[ "$rc" = 0 ] && printf '%s' "$out" | rg -q 'a-dump' && ok "the cwd wins the tie" || bad "tie not broken by cwd (rc=$rc)"
auto "$T/projC" >/dev/null; rc=$?
[ "$rc" = 2 ] && ok "a cwd that matches neither still gets the picker" || bad "rc=$rc"

echo "== nothing fresh, nothing indexed, files on disk =="
reset; touch "$A/_20260901-only.claude.md"
auto "$A" >/dev/null; rc=$?
[ "$rc" = 2 ] && ok "unindexed files on disk mean picker, not 'none found'" || bad "rc=$rc"
reset; auto "$A" >/dev/null; rc=$?
[ "$rc" = 3 ] && ok "truly nothing: rc 3" || bad "rc=$rc"

echo "== list --cwd: three blocks, global numbers, on-disk paths =="
reset
entry "$(old)" b1 "$B" "$B/_b.claude.md" b-dump core-dump
entry "$(old)" a1 "$A" "$A/_20260906-a.claude.md" a-dump core-dump
touch "$A/_20260906-a.claude.md" "$A/_20260907-unindexed.claude.md"
out=$(bash "$LIST" --cwd "$A" --limit 8)
printf '%s' "$out" | rg -q 'this project' && ok "this-project block present" || bad "no this-project block"
printf '%s' "$out" | rg -q '^  1 +a-dump' && ok "the cwd's row keeps its global number (1 = newest)" || bad "numbering drifted: $out"
printf '%s' "$out" | rg -q "→ /catchup $A/_20260907-unindexed.claude.md" && ok "unindexed file listed with its absolute path" || bad "unindexed file missing"
printf '%s' "$out" | rg -q '_20260906-a.claude.md.*not indexed' && bad "an indexed file was shown as unindexed" || ok "indexed files are not repeated in the on-disk block"
printf '%s' "$out" | rg -q '^  2 +b-dump' && ok "other projects keep their numbers too" || bad "other-project row missing"
pick=$(bash "$RESOLVE" --pick 1)
printf '%s' "$pick" | rg -q 'a-dump' && ok "--pick 1 returns what row 1 shows" || bad "pick/list disagree"

echo "---- pass=$pass fail=$fail"
trash "$T" 2>/dev/null || true
[ $fail -eq 0 ]
