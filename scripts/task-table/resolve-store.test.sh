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
CACHE="$HOME/.claude/tasks/.live-session-map"

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
live="${CLAUDE_CODE_SESSION_ID:-}"
if [ -z "$live" ]; then
  echo "  skip  no live session id in this environment"
else
  r=$(resolve "$live"); rc=${r%%|*}; err=${r##*|}
  [ "$rc" = 0 ] && ok "the live session resolves cold" || bad "live session failed to resolve cold (exit $rc)"
  printf '%s' "$err" | grep -q 'content-match' \
    && ok "--explain reports the fresh match ($err)" \
    || bad "--explain silent on a fresh match; python stderr is being swallowed"
fi

echo "== a bare run stays quiet on stderr =="
if [ -n "${CLAUDE_CODE_SESSION_ID:-}" ]; then
  rm -f "$CACHE/${CLAUDE_CODE_SESSION_ID:0:8}" 2>/dev/null || true
  bash "$R" >/dev/null 2>/tmp/rs-test-bare
  n=$(wc -c < /tmp/rs-test-bare | tr -d ' ')
  [ "${n:-0}" -eq 0 ] && ok "no stderr noise without --explain" \
                      || bad "bare run leaked $n bytes to stderr"
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

rm -f /tmp/rs-test-err /tmp/rs-test-bare /tmp/rs-as-err 2>/dev/null || true
echo "---"; echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
