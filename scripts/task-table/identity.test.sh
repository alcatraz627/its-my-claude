#!/usr/bin/env bash
# identity.test.sh — adversarial tests for the /tasks project-identity contract
# (~/.claude/assets/reports/20260922-tasks-identity-fix/contract.md, I1-I6).
#
# RED-FIRST BY DESIGN. task.sh has no --project flag and task-table.sh has no
# --project filter yet, so most assertions below are expected to FAIL against
# today's code (unknown flag / unknown arg). That is the correct state: these
# tests encode the invariant the fix must satisfy, not what the code does now.
# Do not weaken an assertion to make it pass early.
#
# Sandbox HOME per real-store.test.sh's pattern: a mktemp HOME, the three
# scripts copied in, trash on EXIT. Never touches the live ~/.claude/tasks.
set -uo pipefail
SRC="$HOME/.claude/scripts/task-table"
REAL="$HOME"
SB=$(mktemp -d "${TMPDIR:-/tmp}/identity-home-XXXXXX")
mkdir -p "$SB/.claude/tasks" "$SB/.claude/scripts/task-table"
cp -f "$SRC/task.sh" "$SRC/task-table.sh" "$SRC/resolve-store.sh" "$SB/.claude/scripts/task-table/"
export HOME="$SB"
TS="$HOME/.claude/scripts/task-table/task.sh"
TT="$HOME/.claude/scripts/task-table/task-table.sh"
TASKS="$HOME/.claude/tasks"

# A working area for git repos OUTSIDE the sandbox HOME, normalized to its
# physical path up front (macOS's mktemp path itself hangs off a symlink,
# /tmp -> /private/tmp, and letting that noise leak into path comparisons
# would make the dedicated symlink scenario meaningless).
ROOT=$(mktemp -d "${TMPDIR:-/tmp}/identity-repos-XXXXXX")
ROOT=$(cd "$ROOT" && pwd -P)

pass=0; fail=0
ok(){ echo "  ok    $1"; pass=$((pass+1)); }
bad(){ echo "  FAIL  $1"; fail=$((fail+1)); }

trap 'export HOME="$REAL"; trash "$ROOT" "$SB" 2>/dev/null || true' EXIT

# ---- helpers ---------------------------------------------------------------
newrepo(){ mkdir -p "$1" && git -C "$1" init -q; }               # newrepo <dir>
# A brand-new repo dir, never reused anywhere else in this file. This matters:
# resolve-store.sh's own fallback (rung "the one populated store stamped with
# this project") means a SECOND session whose first write happens to share an
# earlier session's CWD gets silently redirected into that earlier session's
# store instead of getting its own — the exact identity-lying behaviour this
# contract is about. Reusing a repo path across two "first write" scenarios in
# this suite would corrupt the suite's own isolation, not just be untidy. Any
# CWD used to establish a store's FIRST row must come from here.
REPO_N=0
freshrepo(){  # freshrepo <label> -> prints the new dir
  REPO_N=$((REPO_N+1))
  local d="$ROOT/repo${REPO_N}-$1"
  newrepo "$d"
  printf '%s' "$d"
}
store_dir(){ printf '%s' "$TASKS/session-${1:0:8}"; }             # store_dir <sid>
proj_stamp(){ cat "$(store_dir "$1")/.project" 2>/dev/null; }      # proj_stamp <sid>
row_field(){ jq -r "$3 // \"MISSING\"" "$(store_dir "$1")/$2.json" 2>/dev/null; }  # row_field <sid> <id> <jqpath>

# Runs task.sh with the given CWD and session id. Always passes --new so a
# brand-new sid gets its store created; harmless once the store exists (the
# live-session-dir rung wins before --new is even consulted).
task_run(){  # task_run <cwd> <sid> <args...>
  local cwd="$1" sid="$2"; shift 2
  ( cd "$cwd" 2>/dev/null && CLAUDE_CODE_SESSION_ID="$sid" "$TS" --new "$@" )
}
add_json(){  # add_json <cwd> <sid> <subject> <extra args...> -> prints the row json, or nothing on failure
  local cwd="$1" sid="$2" subj="$3"; shift 3
  task_run "$cwd" "$sid" --json add "$subj" "$@" 2>"$ROOT/last-add.err"
}
add_id(){  # add_id <cwd> <sid> <subject> <extra args...> -> prints the new id, or empty
  add_json "$@" | jq -r '.id // empty' 2>/dev/null
}
table_json(){  # table_json <sid> <extra args...> -> stdout is the --json render; rc kept via $?
  local sid="$1"; shift
  ( cd "$ROOT" && CLAUDE_CODE_SESSION_ID="$sid" "$TT" --session "${sid:0:8}" --json "$@" )
}
table_human(){  # table_human <sid> <extra args...>
  local sid="$1"; shift
  ( cd "$ROOT" && CLAUDE_CODE_SESSION_ID="$sid" "$TT" --session "${sid:0:8}" "$@" )
}
# Every id the JSON render actually shows (grouped, gated, or deferred),
# regardless of how the fix ends up shaping the JSON's grouping keys.
ids_shown(){  # reads a table_json blob from stdin; strips the aggregate store tag
  # (an id in a cross-store project view is "<n>·<store6>"; the bare id is before
  # the dot) so a same-store presence check still works. Cross-store leak checks
  # use subj_shown instead, because bare ids collide across stores.
  jq -r '[(.groups // {} | to_entries[] | .value[]), (.gates // [])[], (.later // [])[]] | map(tostring | sub("·.*$";"")) | unique | sort | .[]' 2>/dev/null
}
subj_shown(){  # reads a table_json blob from stdin -> one subject per line
  jq -r '[.tasks[]?.subject] | .[]' 2>/dev/null
}
# A hand-written legacy row: no metadata.project at all, the shape do_add
# writes but crafted directly so the absence is guaranteed regardless of
# whatever task.sh does today or after the fix.
write_legacy_row(){  # write_legacy_row <sid> <id> <subject> <domain>
  local sid="$1" id="$2" subj="$3" dom="$4" d
  d=$(store_dir "$sid"); mkdir -p "$d"
  jq -n --arg id "$id" --arg s "$subj" --arg dom "$dom" \
    '{id:$id,subject:$s,description:"",status:"pending",activeForm:null,blocks:[],blockedBy:[],metadata:{domain:$dom}}' \
    > "$d/$id.json"
}

echo "== I1/I5: project is a per-task attribute, and the default says it is inferred =="

R1=$(freshrepo repoA)
S1="id100001-0000-0000-0000-000000000001"
J1=$(add_json "$R1" "$S1" "explicit project task" --project "$R1")
id1=$(printf '%s' "$J1" | jq -r '.id // empty' 2>/dev/null)
if [ -n "$id1" ]; then
  [ "$(row_field "$S1" "$id1" .metadata.project)" = "$R1" ] && ok "[I1] explicit --project lands on the row verbatim" || bad "[I1] explicit --project not recorded on the row"
else
  bad "[I1] task.sh add --project <path> was refused (flag not implemented): $(cat "$ROOT/last-add.err" 2>/dev/null)"
fi

R2=$(freshrepo repoB)
S2="id100002-0000-0000-0000-000000000002"
J2=$(add_json "$R2" "$S2" "default project task")
id2=$(printf '%s' "$J2" | jq -r '.id // empty' 2>/dev/null)
if [ -n "$id2" ]; then
  [ "$(row_field "$S2" "$id2" .metadata.project)" = "$R2" ] && ok "[I1] no --project defaults to the CWD git-root" || bad "[I1] default project not recorded as the CWD git-root"
else
  bad "[I1] default add produced no row to check (task.sh add is broken today): $(cat "$ROOT/last-add.err" 2>/dev/null)"
fi

# I5: an explicit project and an inferred one must be tellable apart on the
# row. We do not assume the exact key name the fix will use, only that SOME
# metadata field naming project origin/explicitness disagrees between the two
# rows above (one explicit, one inferred).
if [ -n "$id1" ] && [ -n "$id2" ]; then
  m1=$(jq -c '.metadata' "$(store_dir "$S1")/$id1.json" 2>/dev/null)
  m2=$(jq -c '.metadata' "$(store_dir "$S2")/$id2.json" 2>/dev/null)
  d1=$(printf '%s' "$m1" | jq -r 'to_entries[] | select(.key|test("project";"i")) | select(.key!="project") | "\(.key)=\(.value)"' 2>/dev/null | rg -m1 .)
  d2=$(printf '%s' "$m2" | jq -r 'to_entries[] | select(.key|test("project";"i")) | select(.key!="project") | "\(.key)=\(.value)"' 2>/dev/null | rg -m1 .)
  if [ -n "$d1" ] && [ -n "$d2" ] && [ "$d1" != "$d2" ]; then
    ok "[I5] explicit vs inferred project carries a distinguishing marker ($d1 vs $d2)"
  else
    bad "[I5] no marker distinguishes explicit project from inferred (explicit: '${d1:-none}', inferred: '${d2:-none}')"
  fi
else
  bad "[I5] cannot compare explicit vs inferred markers, one or both rows above did not write"
fi

echo "== I2/I3/I4: reader drift, filter correctness, and loud disagreement in one store =="

AR=$(freshrepo projA)   # this store's first write, so this MUST be a fresh repo
BR=$(freshrepo projB)   # the second project this same store will end up holding

S3="id100003-0000-0000-0000-000000000003"
J3=$(add_json "$AR" "$S3" "drift target")
id3=$(printf '%s' "$J3" | jq -r '.id // empty' 2>/dev/null)
before3=$(row_field "$S3" "$id3" .metadata.project)
# Same store (same sid, already non-empty so rung3 owns resolution), different
# CWD, plain update: must not relabel.
task_run "$BR" "$S3" update "${id3:-0}" --desc "touched from projB" >/dev/null 2>&1
after3=$(row_field "$S3" "$id3" .metadata.project)
if [ -n "$id3" ] && [ "$before3" = "$AR" ] && [ "$after3" = "$AR" ]; then
  ok "[I2] update from a different CWD does not relabel an existing row's project"
else
  bad "[I2] reader drift: before='$before3' after='$after3' (expected '$AR' both times)"
fi

# Same probe via task.sh start, the other write path that touches a row.
task_run "$BR" "$S3" start "${id3:-0}" >/dev/null 2>&1
after3b=$(row_field "$S3" "$id3" .metadata.project)
[ -n "$id3" ] && [ "$after3b" = "$AR" ] && ok "[I2] start from a different CWD does not relabel either" || bad "[I2] start from projB changed project to '$after3b'"

# I3 setup: a SECOND row, explicitly attributed to projB, planted into the
# SAME store (already non-empty, so this lands there regardless of CWD).
idB=$(add_id "$BR" "$S3" "B's row in A's store" --project "$BR")
if [ -n "$idB" ]; then
  outA=$(table_json "$S3" --project "$AR"); rcA=$?
  shownA=$(printf '%s' "$outA" | ids_shown)
  outB=$(table_json "$S3" --project "$BR"); rcB=$?
  shownB=$(printf '%s' "$outB" | ids_shown)
  if [ "$rcA" -eq 0 ] && printf '%s\n' "$shownA" | rg -qx "$id3" && ! printf '%s\n' "$shownA" | rg -qx "$idB"; then
    ok "[I3] --project A returns A's row and not B's"
  else
    bad "[I3] --project A (rc=$rcA) shown='$shownA', expected {$id3} only"
  fi
  if [ "$rcB" -eq 0 ] && printf '%s\n' "$shownB" | rg -qx "$idB" && ! printf '%s\n' "$shownB" | rg -qx "$id3"; then
    ok "[I3] --project B returns B's row and not A's"
  else
    bad "[I3] --project B (rc=$rcB) shown='$shownB', expected {$idB} only"
  fi
  union=$(printf '%s\n%s\n' "$shownA" "$shownB" | sort -u)
  if printf '%s\n' "$union" | rg -qx "$id3" && printf '%s\n' "$union" | rg -qx "$idB"; then
    ok "[I3] the disjoint union of A's and B's filtered views covers both planted rows"
  else
    bad "[I3] filtered union missing a planted row: union='$union'"
  fi
  base=$(basename "$AR")
  outBase=$(table_json "$S3" --project "$base")
  shownBase=$(printf '%s' "$outBase" | ids_shown)
  if printf '%s\n' "$shownBase" | rg -qx "$id3"; then
    ok "[I3] --project <basename> matches the same rows as the full path"
  else
    bad "[I3] --project '$base' (basename of $AR) did not match id $id3: shown='$shownBase'"
  fi
else
  bad "[I3] setup failed: could not plant B's row into A's store (task.sh add --project not implemented): $(cat "$ROOT/last-add.err" 2>/dev/null)"
fi

# I4: this store is stamped with A (first write there) and now also holds a
# B-attributed row, the exact cross-cutting-write shape the contract's
# root-cause section describes.
mismatch_re='(mismatch|disagree|conflict|inconsistent|mixed[- ]project|does not match|other project|not purely|foreign)'
humanOut=$(table_human "$S3" 2>&1)
if printf '%s' "$humanOut" | rg -qi "$mismatch_re"; then
  ok "[I4] human render flags the stamp/attribute conflict"
else
  bad "[I4] human render says nothing about the stamp ($AR) vs the planted row's project ($BR)"
fi
jsonOut=$(table_json "$S3" 2>&1)
if printf '%s' "$jsonOut" | jq -e 'keys[] | test("mismatch|conflict|warn|mixed";"i")' >/dev/null 2>&1 || printf '%s' "$jsonOut" | rg -qi "$mismatch_re"; then
  ok "[I4] --json render also carries the conflict (machine callers aren't left blind)"
else
  bad "[I4] --json render carries no conflict signal a caller could detect"
fi

echo "== I6: back-compatible with rows that predate metadata.project =="

LR=$(freshrepo legacy)
S6="id100006-0000-0000-0000-000000000006"
task_run "$LR" "$S6" store >/dev/null 2>&1   # force-create the store via a real invocation, stamped LR
write_legacy_row "$S6" 1 "legacy row, no project field" gcc
legacyOut=$(table_human "$S6" 2>&1)
if printf '%s' "$legacyOut" | rg -q "legacy row, no project field"; then
  ok "[I6] a row with no metadata.project still renders"
else
  bad "[I6] legacy row vanished from the render instead of falling back to the store stamp"
fi
stamp6=$(proj_stamp "$S6")
outFallback=$(table_json "$S6" --project "$stamp6")
if printf '%s' "$outFallback" | ids_shown | rg -qx "1"; then
  ok "[I6] --project <store stamp> finds the legacy row via the fallback"
else
  bad "[I6] legacy row not found by filtering on its store's own stamp ($stamp6)"
fi
# The back-compat row alone (matching the stamp) must not itself trip the I4
# guard: a false alarm on every pre-fix store would drown the real ones.
if printf '%s' "$legacyOut" | rg -qi "$mismatch_re"; then
  bad "[I6] a lone legacy row, consistent with its store stamp, falsely tripped the I4 conflict guard"
else
  ok "[I6] a lone legacy row does not falsely trigger the I4 conflict guard"
fi

echo "== edge: symlinked and subdirectory CWDs resolve stably =="

REALP=$(freshrepo symreal)
LINKP="$ROOT/symlink-to-real"; ln -s "$REALP" "$LINKP"
S7="id100007-0000-0000-0000-000000000007"
id7a=$(add_id "$LINKP" "$S7" "via symlink, first")
proj7a=$(row_field "$S7" "$id7a" .metadata.project)
if [ -n "$id7a" ] && [ "$proj7a" = "$REALP" ]; then
  ok "[edge] project through a symlinked CWD resolves to the real repo root"
else
  bad "[edge] symlinked CWD resolved to '$proj7a', expected the real root '$REALP'"
fi
id7b=$(add_id "$LINKP" "$S7" "via symlink, second")
proj7b=$(row_field "$S7" "$id7b" .metadata.project)
[ -n "$id7b" ] && [ "$proj7b" = "$proj7a" ] && ok "[edge] the symlink resolution is stable across calls" || bad "[edge] symlink resolution drifted: '$proj7a' then '$proj7b'"

REPOSUB=$(freshrepo repoSub); DEEP="$REPOSUB/a/b/c"; mkdir -p "$DEEP"
S8="id100008-0000-0000-0000-000000000008"
id8=$(add_id "$DEEP" "$S8" "from a deep subdir")
proj8=$(row_field "$S8" "$id8" .metadata.project)
[ -n "$id8" ] && [ "$proj8" = "$REPOSUB" ] && ok "[edge] a deep subdirectory CWD resolves to the repo toplevel" || bad "[edge] subdir CWD resolved to '$proj8', expected toplevel '$REPOSUB'"

echo "== edge: ~/.claude as CWD is never mistaken for a project's queue =="

S9="id100009-0000-0000-0000-000000000009"
id9=$(add_id "$HOME/.claude" "$S9" "filed from the gcc config dir itself")
if [ -n "$id9" ]; then
  gccsubj="filed from the gcc config dir itself"
  outOther=$(table_json "$S9" --project "$R1")
  if printf '%s' "$outOther" | subj_shown | rg -qF "$gccsubj"; then
    bad "[edge] a row filed from ~/.claude leaked into an unrelated project's --project filter"
  else
    ok "[edge] a row filed from ~/.claude never leaks into another project's filter"
  fi
  proj9=$(row_field "$S9" "$id9" .metadata.project)
  outSelf=$(table_json "$S9" --project "$proj9")
  printf '%s' "$outSelf" | subj_shown | rg -qF "$gccsubj" && ok "[edge] the ~/.claude row is still findable by its own true project value" || bad "[edge] the ~/.claude row cannot be found by filtering on its own recorded project ('$proj9')"
else
  bad "[edge] task.sh add from ~/.claude produced no row at all"
fi

echo "== edge: unicode and spaces in a repo path survive the round trip =="

ODD="$ROOT/my proj é 名前"; newrepo "$ODD"
S10="id100010-0000-0000-0000-000000000010"
id10=$(add_id "$ODD" "$S10" "unicode path task")
proj10=$(row_field "$S10" "$id10" .metadata.project)
[ -n "$id10" ] && [ "$proj10" = "$ODD" ] && ok "[edge] a repo path with spaces and unicode round-trips exactly" || bad "[edge] odd path mangled: got '$proj10', expected '$ODD'"
if [ -n "$id10" ]; then
  outOdd=$(table_json "$S10" --project "$ODD")
  printf '%s' "$outOdd" | ids_shown | rg -qx "$id10" && ok "[edge] --project with spaces/unicode still filters correctly" || bad "[edge] filtering by the odd path found nothing"
fi

echo "== edge: a project name that is a substring of another =="

APPA=$(freshrepo app); APPB="$ROOT/$(basename "$APPA")-v2"; newrepo "$APPB"
S11="id100011-0000-0000-0000-000000000011"
idA=$(add_id "$APPA" "$S11" "app's own row" --project "$APPA")
idBv2=$(add_id "$APPA" "$S11" "app-v2's row filed from app's CWD" --project "$APPB")
if [ -n "$idA" ] && [ -n "$idBv2" ]; then
  outApp=$(table_json "$S11" --project "$APPA")
  shownApp=$(printf '%s' "$outApp" | ids_shown)
  if printf '%s\n' "$shownApp" | rg -qx "$idA" && ! printf '%s\n' "$shownApp" | rg -qx "$idBv2"; then
    ok "[edge] --project app does not accidentally sweep in app-v2's row"
  else
    bad "[edge] substring collision: --project app shown='$shownApp' (idA=$idA idBv2=$idBv2)"
  fi
  outAppV2=$(table_json "$S11" --project "$APPB")
  shownAppV2=$(printf '%s' "$outAppV2" | ids_shown)
  if printf '%s\n' "$shownAppV2" | rg -qx "$idBv2" && ! printf '%s\n' "$shownAppV2" | rg -qx "$idA"; then
    ok "[edge] --project app-v2 does not accidentally sweep in app's row"
  else
    bad "[edge] substring collision: --project app-v2 shown='$shownAppV2' (idA=$idA idBv2=$idBv2)"
  fi
else
  bad "[edge] substring-collision setup failed to write both rows: $(cat "$ROOT/last-add.err" 2>/dev/null)"
fi

echo "== edge: concurrent writers from two projects into one store =="

CA=$(freshrepo concA)
CB=$(freshrepo concB)
S12="id100012-0000-0000-0000-000000000012"
task_run "$CA" "$S12" store >/dev/null 2>&1   # stamp the store before racing two writers into it
( task_run "$CA" "$S12" add "concurrent from A" --project "$CA" >"$ROOT/conc-a.out" 2>"$ROOT/conc-a.err" ) &
pidA=$!
( task_run "$CB" "$S12" add "concurrent from B" --project "$CB" >"$ROOT/conc-b.out" 2>"$ROOT/conc-b.err" ) &
pidB=$!
wait "$pidA" "$pidB" 2>/dev/null
badjson=0
for f in "$(store_dir "$S12")"/*.json; do
  [ -e "$f" ] || continue
  jq -e . "$f" >/dev/null 2>&1 || badjson=$((badjson+1))
done
[ "$badjson" -eq 0 ] && ok "[edge] concurrent writers leave only valid JSON (the store-level lock held)" || bad "[edge] $badjson corrupted/truncated row(s) after concurrent writes"
concIds=$(jq -rs '[.[] | select(.subject|test("^concurrent from "))] | .[].id' "$(store_dir "$S12")"/*.json 2>/dev/null)
nConc=$(printf '%s\n' "$concIds" | rg -c . 2>/dev/null || echo 0)
if [ "$nConc" = "2" ]; then
  ok "[edge] both concurrent rows landed (no write silently lost)"
  a_ok=1; b_ok=1
  for cid in $concIds; do
    subj=$(jq -r '.subject' "$(store_dir "$S12")/$cid.json" 2>/dev/null)
    pr=$(row_field "$S12" "$cid" .metadata.project)
    case "$subj" in
      "concurrent from A") [ "$pr" = "$CA" ] || a_ok=0 ;;
      "concurrent from B") [ "$pr" = "$CB" ] || b_ok=0 ;;
    esac
  done
  { [ "$a_ok" = 1 ] && [ "$b_ok" = 1 ]; } && ok "[edge] each concurrent row kept its own project, not the other writer's" || bad "[edge] concurrent writes cross-attributed a project"
else
  bad "[edge] concurrent writers: expected 2 rows, found $nConc (ids: $concIds)"
fi

echo "== edge: filter behaves on empty and non-matching stores =="

EM=$(freshrepo empty)
S13="id100013-0000-0000-0000-000000000013"
task_run "$EM" "$S13" store >/dev/null 2>&1
rm -f "$(store_dir "$S13")"/*.json 2>/dev/null
outEmpty=$(table_json "$S13" --project "$EM"); rcEmpty=$?
[ "$rcEmpty" -eq 0 ] && ok "[edge] --project against an empty store exits cleanly" || bad "[edge] --project against an empty store exited $rcEmpty"

UM=$(freshrepo unmatched)
S14="id100014-0000-0000-0000-000000000014"
idOnly=$(add_id "$UM" "$S14" "the only row" --project "$UM")
if [ -n "$idOnly" ]; then
  outNoMatch=$(table_json "$S14" --project "$ROOT/no-such-project"); rcNoMatch=$?
  shownNoMatch=$(printf '%s' "$outNoMatch" | ids_shown)
  if [ "$rcNoMatch" -eq 0 ] && [ -z "$shownNoMatch" ]; then
    ok "[edge] an unmatched --project returns zero rows, not a silent fallback to the whole store"
  else
    bad "[edge] unmatched --project rc=$rcNoMatch shown='$shownNoMatch' (expected empty)"
  fi
else
  bad "[edge] setup for the unmatched-filter case failed to add a row"
fi

echo "== core: a project view gathers its rows across MANY stores =="
# The behavioral goal (owner, 2026-09-22): name a project, see its work wherever
# it lives, not one session's slice. Two stores, same project, one --project.
AGP=$(freshrepo multi)          # the logical project both rows serve
cwdA=$(freshrepo multi-a)       # two DIFFERENT first-write CWDs, so two stores
cwdB=$(freshrepo multi-b)       # (a shared CWD would collide into one store)
idM1=$(add_id "$cwdA" "id100015-0000-0000-0000-000000000015" "multi row one, store A" --project "$AGP")
idM2=$(add_id "$cwdB" "id100016-0000-0000-0000-000000000016" "multi row two, store B" --project "$AGP")
# A row for a DIFFERENT project, to prove the gather is scoped.
oth=$(freshrepo other)
idO=$(add_id "$oth" "id100017-0000-0000-0000-000000000017" "unrelated row, other project" --project "$oth")
aggOut=$(table_json "id100015" --project "$AGP")
aggSubj=$(printf '%s' "$aggOut" | subj_shown)
if printf '%s\n' "$aggSubj" | rg -qF "multi row one, store A" && printf '%s\n' "$aggSubj" | rg -qF "multi row two, store B"; then
  ok "[core] --project gathers a project's rows across two separate stores"
else
  bad "[core] --project did not gather across stores: subjects='$aggSubj'"
fi
if printf '%s\n' "$aggSubj" | rg -qF "unrelated row, other project"; then
  bad "[core] the cross-store gather pulled in another project's row"
else
  ok "[core] the cross-store gather stays scoped to the asked project"
fi
aggIds=$(printf '%s' "$aggOut" | jq -r '[.tasks[]?.id] | .[]' 2>/dev/null)
if printf '%s\n' "$aggIds" | rg -q "·"; then
  ok "[core] cross-store ids are store-qualified, so same-numbered rows stay distinct"
else
  bad "[core] cross-store ids are not qualified (collision risk): '$aggIds'"
fi

echo "== canary: the harness itself still runs today's baseline render =="
# Expected GREEN even before the fix: proves a failure above is the
# invariant failing, not a broken sandbox.
canaryOut=$(table_human "$S1" 2>&1); canaryRc=$?
{ [ "$canaryRc" -eq 0 ] || [ -n "$canaryOut" ]; } && ok "[canary] task-table.sh renders without --project at all" || bad "[canary] the baseline (no --project) render itself is broken"

echo "---- pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
