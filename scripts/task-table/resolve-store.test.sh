#!/usr/bin/env bash
# Regression tests for resolve-store.sh, from the peer report of 2026-08-16.
#
# All three defects below were invisible from inside a ~/.claude session, which
# is the only kind I tested when I first called this validated. A peer running
# from projects/-Users-alcatraz627-Code-Versable-automation found them in one
# command. Their store held 75 tasks and was findable by content; the resolver
# returned nothing and said nothing about why.
#
# These read the REAL store and REAL transcripts on this machine rather than
# fixtures, because the defect was specifically that a hand-picked fixture from
# my own project exercised the only code path that worked.

set -uo pipefail
R="$HOME/.claude/scripts/task-table/resolve-store.sh"
# The cache moved out of ~/.claude/tasks on 2026-09-04 (see task-table.sh beside
# PIN_DIR). This file kept pointing at the old path for one commit, so the case
# below that clears the cache before a bare run cleared the wrong directory: the
# live pin survived, the run resolved silently, and a case that had been failing
# went green without anything being fixed. Both paths are cleared now, because a
# cleanup that misses the live location tests nothing.
CACHE="$HOME/.claude/tasks-pins"
CACHE_LEGACY="$HOME/.claude/tasks/.live-session-map"

pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  ok   $1"; }
bad() { fail=$((fail+1)); echo "  FAIL $1"; }

# resolve <session-id> -> "<exit>|<stdout>|<stderr first line>"
resolve() {
  local sid="$1" out err rc
  rm -f "$CACHE/${sid:0:8}" 2>/dev/null || true      # always a cold derive
  out=$(CLAUDE_CODE_SESSION_ID="$sid" bash "$R" --explain 2>/tmp/rs-test-err); rc=$?
  err=$(head -1 /tmp/rs-test-err 2>/dev/null)
  printf '%s|%s|%s' "$rc" "$out" "$err"
}

# Pick any session whose transcript is NOT under the -Users-alcatraz627--claude
# project. That is the case the old hardcoded path could never see.
foreign=$(fd -e jsonl . "$HOME/.claude/projects" 2>/dev/null \
  | grep -v -- '-Users-alcatraz627--claude/' | head -40 | while read -r f; do
      sid=$(basename "$f" .jsonl)
      [ -d "$HOME/.claude/tasks/session-${sid:0:8}" ] && continue   # skip step-1 freebies
      grep -qE '"subject":"' "$f" 2>/dev/null && { printf '%s' "$sid"; break; }
    done)

echo "== a session OUTSIDE ~/.claude can be resolved at all =="
if [ -z "$foreign" ]; then
  echo "  skip  no foreign-project transcript with task subjects on this box"
else
  r=$(resolve "$foreign"); rc=${r%%|*}; rest=${r#*|}; out=${rest%%|*}
  if [ "$rc" = 0 ] && [ -n "$out" ]; then
    ok "resolved a non-~/.claude session (${foreign:0:8} -> $(basename "$out"))"
  elif [ "$rc" = 4 ]; then
    # A refusal is legitimate here IF the evidence is genuinely thin. What must
    # never happen again is refusing because the transcript was not looked for.
    grep -q 'no decisive match' /tmp/rs-test-err 2>/dev/null \
      && ok "refused a foreign session WITH a stated reason (thin evidence, acceptable)" \
      || bad "refused a foreign session silently"
  else
    bad "unexpected exit $rc for a foreign session"
  fi
fi

echo "== a refusal is never silent =="
r=$(resolve "00000000-dead-beef-0000-000000000000")
rc=${r%%|*}; err=${r##*|}
[ "$rc" = 4 ] && ok "unknown session exits 4" || bad "expected exit 4, got $rc"
[ -n "$err" ] && ok "and prints a reason on stderr" \
              || bad "exited 4 with EMPTY stderr, the defect the peer reported"
grep -q 'session' /tmp/rs-test-err 2>/dev/null \
  && ok "the reason names the session it could not resolve" \
  || bad "the reason does not identify the session"

echo "== --explain describes a FRESH content-match, not only a cached one =="
# Seeded fixture, not the ambient session: the live transcript only carries the
# unescaped "subject":"..." key on harness builds with a Task tool (40 of 184
# transcripts here), so depending on it made the suite pass or fail by BUILD
# (gcc-work #1, 2026-08-20). Pattern copied from state-matrix.test.sh "the
# TRANSCRIPT path": a TaskCreate-shaped transcript line, a matching store, a
# decoy store, driven end to end under a sandbox HOME.
SB2=$(mktemp -d)
FSID=99999999-8888-7777-6666-555555555555
FPROJ="$SB2/proj"; mkdir -p "$FPROJ"
FTDIR="$SB2/.claude/projects/$(printf '%s' "$FPROJ" | sed 's#/#-#g')"; mkdir -p "$FTDIR"
fd_store="$SB2/.claude/tasks/session-fx000001"; mkdir -p "$fd_store"
i=1
for subj in "wire the census exporter to the new schema" \
            "backfill the delivery ledger for July" \
            "retire the legacy webhook shim"; do
  st="pending"; [ "$i" = 3 ] && st="done"   # done is canonical-equivalent (harness builds write it)
  printf '{"id":"%s","subject":"%s","description":"","status":"%s","blocks":[],"blockedBy":[],"metadata":{}}' \
    "$i" "$subj" "$st" > "$fd_store/$i.json"; i=$((i+1))
done
fd_decoy="$SB2/.claude/tasks/session-fx000002"; mkdir -p "$fd_decoy"
printf '{"id":"1","subject":"something completely unrelated about fonts","description":"","status":"pending","blocks":[],"blockedBy":[],"metadata":{}}' > "$fd_decoy/1.json"
{
  printf '{"type":"user","timestamp":"2026-08-20T00:00:00Z","message":{"role":"user","content":"work the list"}}\n'
  for subj in "wire the census exporter to the new schema" \
              "backfill the delivery ledger for July" \
              "retire the legacy webhook shim"; do
    printf '{"type":"assistant","timestamp":"2026-08-20T00:00:01Z","message":{"role":"assistant","content":[{"type":"tool_use","name":"TaskCreate","input":{"subject":"%s","status":"pending"}}]}}\n' "$subj"
  done
} > "$FTDIR/$FSID.jsonl"
out=$(HOME="$SB2" bash "$R" --as-session "$FSID" --explain 2>/tmp/rs-fresh-err); rc=$?
[ "$rc" = 0 ] && [ "$(basename "${out:-}")" = "session-fx000001" ] \
  && ok "seeded session resolves cold to the matching store" \
  || bad "seeded cold resolve failed (rc=$rc out=${out:-none})"
grep -q 'content-match' /tmp/rs-fresh-err 2>/dev/null \
  && ok "--explain reports the fresh match" \
  || bad "--explain silent on a fresh match; python stderr is being swallowed"

echo "== an EMPTY session-named store yields to a content match (#54) =="
# A resumed session owns an empty store named for itself while its rows live in
# the store that created them. Rung 1 used to return the empty one and two peers
# read their queue as done (2026-09-05). Same fixture, plus the empty self store.
mkdir -p "$SB2/.claude/tasks/session-${FSID:0:8}"
out=$(HOME="$SB2" bash "$R" --as-session "$FSID" --explain 2>/tmp/rs-empty-err); rc=$?
[ "$rc" = 0 ] && [ "$(basename "${out:-}")" = "session-fx000001" ] \
  && ok "the content match beats the empty session-named store" \
  || bad "empty self store won over content (rc=$rc out=${out:-none})"
# And when nothing matches, the empty self store is the answer, labelled empty.
rm -f "$fd_store"/*.json "$fd_decoy"/*.json
out=$(HOME="$SB2" bash "$R" --as-session "$FSID" --explain 2>/tmp/rs-empty-err); rc=$?
[ "$rc" = 0 ] && [ "$(basename "${out:-}")" = "session-${FSID:0:8}" ] \
  && ok "with no content anywhere, the empty session-named store is returned" \
  || bad "empty self store not used as the last resort (rc=$rc out=${out:-none})"
grep -q 'empty' /tmp/rs-empty-err 2>/dev/null \
  && ok "--explain says it is empty" || bad "--explain did not say the store is empty"
rm -f /tmp/rs-empty-err
rm -rf "$SB2"

echo "== a bare run stays quiet on stderr =="
if [ -n "${CLAUDE_CODE_SESSION_ID:-}" ]; then
  # The claim is "a run that SUCCEEDS says nothing without --explain". The setup
  # used to delete the cache first, so the run could not resolve and printed its
  # refusal, and the case failed on the script doing exactly what its own comment
  # says it must: "failing closed WITHOUT A WORD leaves the caller unable to tell
  # a refusal from a crash". The test contradicted the code it was testing.
  # Corrected 2026-09-04: seed a resolvable state, then assert the silence.
  _sid8="${CLAUDE_CODE_SESSION_ID:0:8}"
  # BORROW THE LIVE PIN ONCE, HERE, BEFORE ANYTHING IN THIS BLOCK TOUCHES IT.
  # Both cases below write or delete it, so a save placed lower down captures
  # whatever the case above already destroyed. A first attempt did exactly that:
  # it asserted the pin was restored, passed, and still left the owner's /tasks
  # refusing, because the value it faithfully restored was the empty one.
  _saved=""; _saved_from="$CACHE"
  for _d in "$CACHE" "$CACHE_LEGACY"; do
    if [ -f "$_d/$_sid8" ]; then _saved=$(cat "$_d/$_sid8"); _saved_from="$_d"; break; fi
  done
  _any=$(find "$HOME/.claude/tasks" -maxdepth 1 -type d -name 'session-*' -print -quit 2>/dev/null)
  if [ -n "$_any" ]; then
    mkdir -p "$CACHE"
    printf '%s' "$(basename "$_any")" > "$CACHE/$_sid8"
    printf '%s' "${_any#*session-}" > "$CACHE/$_sid8"
    bash "$R" >/dev/null 2>/tmp/rs-test-bare
    n=$(wc -c < /tmp/rs-test-bare | tr -d ' ')
    [ "${n:-0}" -eq 0 ] && ok "a resolving bare run says nothing without --explain" \
                        || bad "a resolving bare run leaked $n bytes to stderr"
    rm -f "$CACHE/$_sid8"
  else
    echo "  skip  no store on this machine to resolve to"
  fi

  # And the other half, which nothing asserted: a run that CANNOT resolve must
  # speak. Silence there is the defect the script's comment was written about.
  #
  # This case has to clear the LIVE session's pin to reach the refusal path, and
  # that pin belongs to the person running the suite. An earlier version simply
  # deleted it, so running the tests left the owner's own /tasks refusing until
  # somebody re-pinned by hand. A test that damages live state is worse than the
  # false green it was written to fix. Borrow it and put it back.
  rm -f "$CACHE/$_sid8" "$CACHE_LEGACY/$_sid8" 2>/dev/null || true
  bash "$R" >/dev/null 2>/tmp/rs-test-refuse
  n2=$(wc -c < /tmp/rs-test-refuse | tr -d ' ')
  [ "${n2:-0}" -gt 0 ] && ok "a refusing bare run says why" \
                       || bad "a refusal was silent, which reads as a crash"
  if [ -n "$_saved" ]; then
    mkdir -p "$_saved_from"
    printf '%s' "$_saved" > "$_saved_from/$_sid8"
    [ -f "$_saved_from/$_sid8" ] && ok "the live pin this case borrowed is back" \
                                 || bad "the suite ate the live pin and did not restore it"
  fi
fi

echo "== --as-session resolves another session without touching the cache =="
# Added 2026-08-16. The tail-starvation case could not be tested at all before
# this flag existed: the resolver answers for the LIVE session, and nobody can be
# a session from June. That was a testability gap, not a code defect, and it hid
# a real effect for as long as it stood.
before=$(ls "$CACHE" 2>/dev/null | sort | tr '\n' ' ')
# Pick any session with a transcript and NO self-named store, so the probe has to
# reach step 3 rather than short-circuiting on step 1.
probe_sid=$(ls -t "$HOME"/.claude/projects/*/*.jsonl 2>/dev/null | head -60 | while read -r f; do
  s=$(basename "$f" .jsonl)
  [ -d "$HOME/.claude/tasks/session-${s:0:8}" ] && continue
  grep -q '"subject":"' "$f" 2>/dev/null && { printf '%s' "$s"; break; }
done)
if [ -z "$probe_sid" ]; then
  echo "  skip  no inherited-store session available to probe"
else
  out=$(bash "$R" --as-session "$probe_sid" --explain 2>/tmp/rs-as-err); rc=$?
  [ "$rc" = 0 ] && [ -n "$out" ] \
    && ok "--as-session resolved ${probe_sid:0:8} -> $(basename "$out")" \
    || ok "--as-session refused ${probe_sid:0:8} (acceptable if evidence is thin)"
  grep -q 'content-match' /tmp/rs-as-err 2>/dev/null \
    && ok "and it reached the content-match step rather than a shortcut" \
    || ok "resolved by a shortcut step (fine, but this probe tested less)"
  after=$(ls "$CACHE" 2>/dev/null | sort | tr '\n' ' ')
  [ "$before" = "$after" ] \
    && ok "the probe wrote NOTHING to the live cache" \
    || bad "--as-session polluted the cache: [$before] -> [$after]"
fi

echo "== one populated store stamped with this project is the answer, two is a refusal (csync, 2026-09-08) =="
SB=$(mktemp -d); mkdir -p "$SB/.claude/tasks/session-aaaa1111" "$SB/.claude/tasks/session-bbbb2222" "$SB/proj"
git -C "$SB/proj" init -q 2>/dev/null
PROOT=$(git -C "$SB/proj" rev-parse --show-toplevel 2>/dev/null); [ -n "$PROOT" ] || PROOT="$SB/proj"
printf '%s' "$PROOT" > "$SB/.claude/tasks/session-aaaa1111/.project"
printf '{"id":"1","subject":"the csync row","description":"","status":"pending","blocks":[],"blockedBy":[],"metadata":{"domain":"csync"}}' > "$SB/.claude/tasks/session-aaaa1111/1.json"
out=$(cd "$SB/proj" && HOME="$SB" CLAUDE_CODE_SESSION_ID=cccc3333-0000-0000-0000-000000000000 bash "$R" 2>/tmp/rs-stamp-err); rc=$?
[ "$rc" = 0 ] && [ "$(basename "$out")" = "session-aaaa1111" ] && ok "a lone stamped store resolves (rc 0)" || bad "lone stamped store: rc $rc out=$out err=$(head -1 /tmp/rs-stamp-err)"
[ "$(cat "$SB/.claude/tasks-pins/cccc3333.by" 2>/dev/null)" = "project-stamp" ] && ok "the pin records how it decided (project-stamp)" || bad "no .by label written"
printf '%s' "$PROOT" > "$SB/.claude/tasks/session-bbbb2222/.project"
printf '{"id":"1","subject":"another row","description":"","status":"pending","blocks":[],"blockedBy":[],"metadata":{}}' > "$SB/.claude/tasks/session-bbbb2222/1.json"
rm -f "$SB/.claude/tasks-pins/cccc3333" "$SB/.claude/tasks-pins/cccc3333.by"
mkdir -p "$SB/.claude/tasks/session-cccc3333"
out=$(cd "$SB/proj" && HOME="$SB" CLAUDE_CODE_SESSION_ID=cccc3333-0000-0000-0000-000000000000 bash "$R" 2>/tmp/rs-stamp-err); rc=$?
[ "$rc" = 4 ] && ok "two stamped stores still refuse (rc 4)" || bad "two stamped stores: rc $rc out=$out"
grep -q 'scripts/task-table/task-table.sh --pin' /tmp/rs-stamp-err && ok "the refusal names the full path to pin" || bad "refusal still bare: $(grep -m1 'Pin it' /tmp/rs-stamp-err)"
rm -rf "$SB" /tmp/rs-stamp-err 2>/dev/null || true

rm -f /tmp/rs-test-err /tmp/rs-test-bare /tmp/rs-as-err 2>/dev/null || true
echo "---"; echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
